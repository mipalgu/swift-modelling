//
// FormatCommandTests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for the metamodel formats of the format registry, Complete OCL documents and the
/// options of grammar imports on the command line of swift-ecore.
@Suite("swift-ecore - formats, Complete OCL and grammar imports", .serialized)
struct FormatCommandTests {
    /// An EMOF metamodel of a small shop, in an `.xmi` file.
    static let shop = """
        <?xml version="1.0" encoding="UTF-8"?>
        <xmi:XMI xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:emof="http://schema.omg.org/spec/MOF/2.0/emof.xml">
          <emof:Package xmi:id="shop" name="shop" uri="http://example.org/shop">
            <xmi:Extension extender="http://www.eclipse.org/emf/2002/Ecore">
              <nsPrefix>shop</nsPrefix>
            </xmi:Extension>
            <ownedType xmi:type="emof:Class" xmi:id="shop.Product" name="Product">
              <ownedAttribute xmi:id="shop.Product.name" name="name" isOrdered="true" lower="0">
                <type xmi:type="emof:PrimitiveType" href="http://schema.omg.org/spec/MOF/2.0/emof.xml#String"/>
              </ownedAttribute>
              <ownedAttribute xmi:id="shop.Product.price" name="price" isOrdered="true" lower="0">
                <type xmi:type="emof:PrimitiveType" href="http://schema.omg.org/spec/MOF/2.0/emof.xml#Integer"/>
              </ownedAttribute>
            </ownedType>
          </emof:Package>
        </xmi:XMI>

        """

    /// A product with a price that the constraints reject.
    static let product = """
        <?xml version="1.0" encoding="UTF-8"?>
        <shop:Product xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:shop="http://example.org/shop"
            name="Tea" price="-3"/>

        """

    /// A Complete OCL document that requires positive prices.
    static let constraints = """
        package shop
        context Product
        inv PositivePrice: price > 0
        endpackage

        """

    /// An ASDL description of arithmetic expressions with an enumerable sum type.
    static let arithmetic = """
        module Arith {
            expr = Num(int value) | BinOp(expr left, op operator, expr right)
            op = Add | Sub
        }

        """

    /// A KM3 metamodel of the shop.
    static let km3Shop = """
        package shop {
            class Product {
                attribute name : String;
            }
        }

        package PrimitiveTypes {
            datatype String;
        }

        """

    /// A directory with the files of the tests.
    struct Files {
        /// The directory.
        let directory: URL

        /// The EMOF metamodel.
        var metamodel: URL { file("shop.xmi") }

        /// The model.
        var model: URL { file("product.xmi") }

        /// The Complete OCL document.
        var constraints: URL { file("shop.ocl") }

        /// The ASDL description.
        var arithmetic: URL { file("arith.asdl") }

        /// Creates the files.
        init() throws {
            directory = try createTemporaryDirectory()
            try FormatCommandTests.shop.write(to: metamodel, atomically: true, encoding: .utf8)
            try FormatCommandTests.product.write(to: model, atomically: true, encoding: .utf8)
            try FormatCommandTests.constraints.write(to: constraints, atomically: true, encoding: .utf8)
            try FormatCommandTests.arithmetic.write(to: arithmetic, atomically: true, encoding: .utf8)
        }

        /// A file in the directory.
        func file(_ name: String) -> URL { directory.appendingPathComponent(name) }

        /// Removes the directory.
        func remove() { cleanupTemporaryDirectory(directory) }
    }

    // MARK: - EMOF in XMI

    @Test("inspects an EMOF metamodel in an .xmi file as a metamodel")
    @MainActor
    func inspectEMOF() async throws {
        let files = try Files()
        defer { files.remove() }

        let result = try await executeSwiftEcore(command: "inspect", arguments: [files.metamodel.path])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.hasPrefix("Metamodel: shop.xmi (EMOF)\n"), "\(result.stdout)")
        #expect(result.stdout.contains("Namespace URI: http://example.org/shop"), "\(result.stdout)")
    }

    @Test("validates a model against an EMOF metamodel in an .xmi file given with --metamodel")
    @MainActor
    func validateWithEMOF() async throws {
        let files = try Files()
        defer { files.remove() }

        let result = try await executeSwiftEcore(
            command: "validate", arguments: [files.model.path, "--metamodel", files.metamodel.path])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
    }

    // MARK: - Complete OCL

    @Test("validates a model against the invariants of a Complete OCL document")
    @MainActor
    func validateWithCompleteOCL() async throws {
        let files = try Files()
        defer { files.remove() }

        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [files.model.path, "--metamodel", files.metamodel.path, "--ocl", files.constraints.path])

        #expect(!result.succeeded)
        #expect(result.stdout.contains("PositivePrice"), "\(result.stdout)")
        #expect(result.stdout.contains("violated"), "\(result.stdout)")
    }

    @Test("writes the constraints of a Complete OCL document into a converted metamodel")
    @MainActor
    func convertWithCompleteOCL() async throws {
        let files = try Files()
        defer { files.remove() }
        let output = files.file("shop.ecore")

        let result = try await executeSwiftEcore(
            command: "convert", arguments: [files.metamodel.path, output.path, "--ocl", files.constraints.path])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let text = try String(contentsOf: output, encoding: .utf8)
        #expect(text.contains("PositivePrice"), "\(text)")
        #expect(text.contains("value=\"price > 0\""), "\(text)")
    }

    @Test("rejects a Complete OCL document without a metamodel to constrain")
    @MainActor
    func completeOCLWithoutMetamodel() async throws {
        let files = try Files()
        defer { files.remove() }

        let result = try await executeSwiftEcore(
            command: "inspect", arguments: [files.model.path, "--ocl", files.constraints.path])
        let missing = try await executeSwiftEcore(
            command: "inspect",
            arguments: [files.model.path, "--metamodel", files.metamodel.path, "--ocl", files.file("none.ocl").path])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("No metamodel to constrain with"), "\(result.stderr)")
        #expect(!missing.succeeded)
        #expect(missing.stderr.contains("File not found"), "\(missing.stderr)")
    }

    // MARK: - Grammar imports

    @Test("imports an ASDL description with the options of the command line")
    @MainActor
    func asdlOptions() async throws {
        let files = try Files()
        defer { files.remove() }

        let standard = try await executeSwiftEcore(command: "inspect", arguments: [files.arithmetic.path])
        let configured = try await executeSwiftEcore(
            command: "inspect",
            arguments: [
                files.arithmetic.path, "--asdl-enumerations", "never", "--ns-uri", "http://example.org/calc",
                "--ns-prefix", "calc",
            ])

        #expect(standard.succeeded, "\(standard.stdout)\(standard.stderr)")
        #expect(standard.stdout.contains("Enumerations: 1"), "\(standard.stdout)")
        #expect(configured.succeeded, "\(configured.stdout)\(configured.stderr)")
        #expect(configured.stdout.contains("Enumerations: 0"), "\(configured.stdout)")
        #expect(configured.stdout.contains("Namespace URI: http://example.org/calc"), "\(configured.stdout)")
        #expect(configured.stdout.contains("Namespace prefix: calc"), "\(configured.stdout)")
    }

    // MARK: - Output formats

    @Test("explains that a format that is only read cannot be written")
    @MainActor
    func readOnlyOutput() async throws {
        let files = try Files()
        defer { files.remove() }
        let output = files.file("arith.langium")

        let result = try await executeSwiftEcore(command: "convert", arguments: [files.arithmetic.path, output.path])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("Langium documents are only read, not written"), "\(result.stderr)")
        #expect(result.stderr.contains("convert it to one of: ecore, json, km3, emof, emf (Emfatic)"), "\(result.stderr)")
        #expect(!result.stderr.contains("langium,"), "\(result.stderr)")
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test("lists the model formats when a model is to be written in a metamodel format")
    @MainActor
    func modelOutput() async throws {
        let files = try Files()
        defer { files.remove() }

        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [files.model.path, files.file("product.emf").path, "--metamodel", files.metamodel.path])

        #expect(!result.succeeded)
        #expect(
            result.stderr.contains("product.xmi is a model, which cannot be written as emf: convert it to one of: xmi, json, uml"),
            "\(result.stderr)")
    }

    @Test("refuses to create a model in a metamodel format")
    @MainActor
    func createInMetamodelFormat() async throws {
        let files = try Files()
        defer { files.remove() }
        let output = files.file("product.km3")

        let result = try await executeSwiftEcore(
            command: "create",
            arguments: ["--metamodel", files.metamodel.path, "--root-class", "Product", "-o", output.path])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("Unsupported output format: km3"), "\(result.stderr)")
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test("compares metamodels in different metamodel formats")
    @MainActor
    func compareMetamodelFormats() async throws {
        let files = try Files()
        defer { files.remove() }
        let km3 = files.file("shop.km3")
        try Self.km3Shop.write(to: km3, atomically: true, encoding: .utf8)

        let result = try await executeSwiftEcore(command: "compare", arguments: [km3.path, files.metamodel.path])

        #expect(!result.stderr.contains("is a metamodel"), "\(result.stderr)")
        #expect(result.stdout.contains("price"), "\(result.stdout)")
    }
}
