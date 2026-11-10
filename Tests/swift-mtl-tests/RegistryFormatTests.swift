//
// RegistryFormatTests.swift
// swift-mtl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for metamodels that the format registry recognises by their contents, and for the
/// options of grammar imports, with `swift-mtl generate`.
@Suite("swift-mtl generate - registry formats", .serialized)
struct RegistryFormatTests {
    /// An EMOF metamodel of a small shop, in an `.xmi` file.
    static let shop = """
        <?xml version="1.0" encoding="UTF-8"?>
        <xmi:XMI xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:emof="http://schema.omg.org/spec/MOF/2.0/emof.xml">
          <emof:Package xmi:id="shop" name="shop" uri="http://example.org/shop">
            <xmi:Extension extender="http://www.eclipse.org/emf/2002/Ecore">
              <nsPrefix>shop</nsPrefix>
            </xmi:Extension>
            <ownedType xmi:type="emof:Class" xmi:id="shop.Product" name="Product">
              <ownedAttribute xmi:id="shop.Product.price" name="price" isOrdered="true" lower="0">
                <type xmi:type="emof:PrimitiveType" href="http://schema.omg.org/spec/MOF/2.0/emof.xml#Integer"/>
              </ownedAttribute>
            </ownedType>
          </emof:Package>
        </xmi:XMI>

        """

    /// A product of the shop.
    static let product = """
        <?xml version="1.0" encoding="UTF-8"?>
        <shop:Product xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:shop="http://example.org/shop" price="41"/>

        """

    /// A module that writes the price after the current one.
    static let template = """
        [module Prices('http://example.org/shop')]

        [template public main(p : shop::Product)]
        [file ('price.txt', 'overwrite', 'UTF-8')]
        [p.price + 1/]
        [/file]
        [/template]

        """

    /// A module that writes the name and namespace URI of a package.
    static let names = """
        [module Names('http://www.eclipse.org/emf/2002/Ecore')]

        [template public main(p : ecore::EPackage)]
        [file ('name.txt', 'overwrite', 'UTF-8')]
        [p.name/] [p.nsURI/]
        [/file]
        [/template]

        """

    /// Writes the files of a test into a new directory.
    ///
    /// - Returns: The directory.
    /// - Throws: Any error writing the files.
    static func directory() throws -> URL {
        let directory = try createTemporaryDirectory()
        try FileManager.default.createDirectory(at: directory.appendingPathComponent(".git"), withIntermediateDirectories: true)
        let files = [(shop, "shop.xmi"), (product, "product.xmi"), (template, "Prices.mtl"), (names, "Names.mtl")]
        for (text, name) in files {
            try text.write(to: directory.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }
        return directory
    }

    @Test("reads a model with an EMOF metamodel in an .xmi file given with --metamodel")
    @MainActor
    func emofMetamodel() async throws {
        let directory = try Self.directory()
        defer { cleanupTemporaryDirectory(directory) }
        let output = directory.appendingPathComponent("out")

        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                directory.appendingPathComponent("Prices.mtl").path,
                "--metamodel", directory.appendingPathComponent("shop.xmi").path,
                "--model", directory.appendingPathComponent("product.xmi").path, "--output", output.path,
            ],
            workingDirectory: directory)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let text = try? String(contentsOf: output.appendingPathComponent("price.txt"), encoding: .utf8)
        #expect(text == "42\n")
    }

    @Test("passes an EMOF metamodel in an .xmi file given with --model as its package")
    @MainActor
    func emofModel() async throws {
        let directory = try Self.directory()
        defer { cleanupTemporaryDirectory(directory) }
        let output = directory.appendingPathComponent("out")

        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                directory.appendingPathComponent("Names.mtl").path,
                "--model", directory.appendingPathComponent("shop.xmi").path, "--output", output.path,
            ],
            workingDirectory: directory)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let text = try? String(contentsOf: output.appendingPathComponent("name.txt"), encoding: .utf8)
        #expect(text == "shop http://example.org/shop\n")
    }

    /// A three-level model of products, in the MetaDepth notation.
    static let products = """
        Model Commerce@2 {
          Node ProductType {
            vat@1 : double = 7.5;
            price : double = 10.0;
          }
        }

        Commerce BookStore {
          ProductType Book {
            vat = 4.0;
          }
        }

        BookStore Shop {
          Book patterns {
            price = 35.0;
          }
          Book draft {}
        }

        """

    /// A module over the deep view of the bottom level of ``products``.
    static let deepTemplate = """
        [module deep('urn:swift-ecore:multilevel:view:Commerce:Shop:deep')]

        [template public main(any : BookStore::ProductType)]
        [file ('products.txt', 'overwrite', 'UTF-8')]
        [for (p | BookStore::ProductType.allInstances()->sortedBy(x | x.clabjectName())) separator(',')][p.clabjectName()/][/for]
        [/file]
        [/template]

        """

    @Test("generates from the deep view of a multi-level model given with --deep-view")
    @MainActor
    func deepView() async throws {
        let directory = try Self.directory()
        defer { cleanupTemporaryDirectory(directory) }
        for (text, name) in [(Self.products, "shop.mdepth"), (Self.deepTemplate, "Deep.mtl")] {
            try text.write(to: directory.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }
        let output = directory.appendingPathComponent("out")

        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                directory.appendingPathComponent("Deep.mtl").path,
                "--model", directory.appendingPathComponent("shop.mdepth").path, "--deep-view", "0",
                "--output", output.path,
            ],
            workingDirectory: directory)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let text = try? String(contentsOf: output.appendingPathComponent("products.txt"), encoding: .utf8)
        #expect(text == "draft,patterns\n")
    }
}
