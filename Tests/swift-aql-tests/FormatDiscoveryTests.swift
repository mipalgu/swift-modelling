//
// FormatDiscoveryTests.swift
// swift-aql-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import Testing

@testable import swift_aql

/// Tests for metamodels that the format registry recognises by their contents, and for the
/// options of grammar imports, in discovery and on the command line of swift-aql.
@Suite("swift-aql - registry formats and grammar imports", .serialized)
struct FormatDiscoveryTests {
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

    /// An ASDL description of arithmetic expressions.
    static let arithmetic = """
        module Arith {
            expr = Num(int value) | Neg(expr operand)
        }

        """

    /// Creates a directory with the shop metamodel and model.
    ///
    /// - Returns: The directory.
    /// - Throws: Any error writing the files.
    static func directory() throws -> URL {
        let directory = try Fixture.temporaryDirectory()
        try FileManager.default.createDirectory(at: directory.appendingPathComponent(".git"), withIntermediateDirectories: true)
        try shop.write(to: directory.appendingPathComponent("shop.xmi"), atomically: true, encoding: .utf8)
        try product.write(to: directory.appendingPathComponent("product.xmi"), atomically: true, encoding: .utf8)
        try arithmetic.write(to: directory.appendingPathComponent("arith.asdl"), atomically: true, encoding: .utf8)
        return directory
    }

    @Test("An EMOF metamodel in an .xmi file beside a model is discovered")
    func discoversEMOF() async throws {
        let directory = try Self.directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let discovery = MetamodelDiscovery()

        let files = await discovery.metamodelFiles(in: directory).map(\.lastPathComponent)
        let namespaces = await discovery.namespaces(ofMetamodelAt: directory.appendingPathComponent("shop.xmi"))
        let found = try await discovery.metamodels(for: [directory.appendingPathComponent("product.xmi").path])

        #expect(files == ["arith.asdl", "shop.xmi"])
        #expect(namespaces == [.init(uri: "http://example.org/shop", isName: false)])
        #expect(found.map { URL(fileURLWithPath: $0).lastPathComponent } == ["shop.xmi"])
    }

    @Test("A grammar import declares the namespace URI that the options give")
    func grammarNamespaces() async throws {
        let directory = try Self.directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        var options = EcoreLoadOptions()
        options.asdlOptions.nsURI = "urn:example:arith"
        let asdl = directory.appendingPathComponent("arith.asdl")

        let configured = await MetamodelDiscovery(options: options).namespaces(ofMetamodelAt: asdl)

        #expect(configured == [.init(uri: "urn:example:arith", isName: false)])
    }

    @Test("A model is read with the EMOF metamodel beside it")
    func evaluatesWithEMOF() async throws {
        let directory = try Self.directory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let run = try await runSwiftAQL(["query", "product.xmi", "self.price + 1"], in: directory)

        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == "42\n")
    }

    @Test("The configuration file gives the options of grammar imports, which the command line overrides")
    func configuredGrammarOptions() async throws {
        let directory = try Self.directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try #"{ "ns-uri": "urn:example:configured" }"#.write(
            to: directory.appendingPathComponent(".swift-modelling.json"), atomically: true, encoding: .utf8)

        let configured = try await runSwiftAQL(["query", "arith.asdl", "self.nsURI"], in: directory)
        let explicit = try await runSwiftAQL(
            ["query", "arith.asdl", "self.nsURI", "--ns-uri", "urn:example:given"], in: directory)

        #expect(configured.succeeded, "\(configured.error)")
        #expect(configured.output == "\"urn:example:configured\"\n")
        #expect(explicit.succeeded, "\(explicit.error)")
        #expect(explicit.output == "\"urn:example:given\"\n")
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

    @Test("A multi-level model is queried through the deep view of a level")
    func deepView() async throws {
        let directory = try Self.directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Self.products.write(to: directory.appendingPathComponent("shop.mdepth"), atomically: true, encoding: .utf8)

        let deep = try await runSwiftAQL(
            [
                "query", "shop.mdepth",
                "BookStore::ProductType.allInstances()->collect(p | p.clabjectName())->sortedBy(n | n)",
                "--deep-view", "0",
            ], in: directory)
        let linguistic = try await runSwiftAQL(["query", "shop.mdepth", "self.name"], in: directory)
        let missing = try await runSwiftAQL(["query", "shop.mdepth", "self", "--deep-view", "9"], in: directory)

        #expect(deep.succeeded, "\(deep.error)")
        #expect(deep.output == "[\"draft\", \"patterns\"]\n")
        #expect(linguistic.succeeded, "\(linguistic.error)")
        #expect(linguistic.output == "\"Commerce\"\n")
        #expect(!missing.succeeded)
    }
}
