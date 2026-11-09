//
// DeepViewTests.swift
// swift-atl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Checks that `swift-atl transform` and `swift-atl query` read multi-level source models through
/// the deep view of a level given with `--deep-view`.
@Suite("swift-atl - deep views of multi-level source models")
struct DeepViewTests {
    /// A product catalogue of three levels in the MetaDepth notation.
    static let products = """
        Model Catalogue@2 {
          Node ProductType {
            gst@1 : double = 10.0;
            price : double = 0.0;
          }
        }

        Catalogue Bookshop {
          ProductType Book {
            gst = 0.0;
          }
          ProductType Magazine {}
        }

        Bookshop Shelf {
          Book manual {
            price = 35.0;
          }
          Magazine monthly {
            price = 9.5;
          }
        }

        """

    /// The metamodel of a price list.
    static let priceListMetamodel = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="PriceList"
            nsURI="http://example.org/pricelist" nsPrefix="pricelist">
          <eClassifiers xsi:type="ecore:EClass" name="Entry">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="product" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="kind" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="price" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EDouble"/>
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="gst" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EDouble"/>
          </eClassifiers>
        </ecore:EPackage>

        """

    /// A transformation from the products on the shelf to the entries of a price list.
    ///
    /// - Parameter header: The directives that precede the module header.
    /// - Returns: The text of the transformation.
    static func shelf2PriceList(header: String = "-- @path PriceList=PriceList.ecore") -> String {
        """
        \(header)
        module Shelf2PriceList;
        create OUT : PriceList from IN : Bookshop;

        rule Product2Entry {
          from p : Bookshop!ProductType
          to e : PriceList!Entry (
            product <- p.clabjectName(),
            kind <- p.ontologicalType().name,
            price <- p.price,
            gst <- p.gst
          )
        }

        """
    }

    /// The entries that ``shelf2PriceList(header:)`` writes for ``products``.
    static let entries = [
        #"<pricelist:Entry product="manual" kind="Book" price="35.0" gst="0.0"/>"#,
        #"<pricelist:Entry product="monthly" kind="Magazine" price="9.5" gst="10.0"/>"#,
    ]

    /// Creates a scratch directory with the products, the price list metamodel and the transformation.
    ///
    /// - Returns: The scratch directory.
    /// - Throws: An error if a file cannot be written.
    static func project() throws -> URL {
        let directory = try createTemporaryDirectory()
        for (text, name) in [
            (products, "shop.mdepth"), (priceListMetamodel, "PriceList.ecore"),
            (shelf2PriceList(), "Shelf2PriceList.atl"),
        ] {
            try text.write(to: directory.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }
        return directory
    }

    /// The combined output of a run.
    static func output(_ result: SubprocessResult) -> String { result.stdout + result.stderr }

    @Test("transforms the deep view of the bottom level of a MetaDepth document")
    @MainActor
    func transformsDeepView() async throws {
        let directory = try Self.project()
        defer { cleanupTemporaryDirectory(directory) }

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                "Shelf2PriceList.atl", "--source", "shop.mdepth", "--target", "prices.xmi", "--deep-view", "0",
                "--quiet",
            ],
            workingDirectory: directory)

        #expect(result.succeeded, "\(Self.output(result))")
        #expect(result.stdout.isEmpty)
        let text = try String(contentsOf: directory.appendingPathComponent("prices.xmi"), encoding: .utf8)
        let lines = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        #expect(lines.filter { $0.hasPrefix("<pricelist:Entry") } == Self.entries, "\(text)")
    }

    @Test("binds a metamodel named by the namespace URI of the view")
    @MainActor
    func bindsNamespaceURI() async throws {
        let directory = try Self.project()
        defer { cleanupTemporaryDirectory(directory) }
        let header = """
            -- @path PriceList=PriceList.ecore
            -- @nsURI Bookshop=urn:swift-ecore:multilevel:view:Catalogue:Shelf:deep
            """
        try Self.shelf2PriceList(header: header).write(
            to: directory.appendingPathComponent("NS.atl"), atomically: true, encoding: .utf8)

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: ["NS.atl", "--source", "IN=shop.mdepth", "--target", "OUT=prices.xmi", "--deep-view", "0"],
            workingDirectory: directory)

        #expect(result.succeeded, "\(Self.output(result))")
        let text = try String(contentsOf: directory.appendingPathComponent("prices.xmi"), encoding: .utf8)
        #expect(Self.entries.allSatisfy { text.contains($0) }, "\(text)")
    }

    @Test("binds the deep view by source model, whatever name the header gives its metamodel")
    @MainActor
    func bindsAnyMetamodelName() async throws {
        let directory = try Self.project()
        defer { cleanupTemporaryDirectory(directory) }
        let renamed = Self.shelf2PriceList().replacingOccurrences(of: "Bookshop", with: "Products")
        try renamed.write(to: directory.appendingPathComponent("Renamed.atl"), atomically: true, encoding: .utf8)

        let positional = try await executeSwiftATL(
            command: "transform",
            arguments: ["Renamed.atl", "--source", "shop.mdepth", "--target", "prices.xmi", "--deep-view", "0"],
            workingDirectory: directory)
        let named = try await executeSwiftATL(
            command: "transform",
            arguments: [
                "Renamed.atl", "--source", "IN=shop.mdepth", "--target", "OUT=named.xmi", "--deep-view", "0",
            ],
            workingDirectory: directory)
        let checked = try await executeSwiftATL(
            command: "transform",
            arguments: ["Renamed.atl", "--source", "shop.mdepth", "--validate-only", "--deep-view", "0"],
            workingDirectory: directory)

        for (result, file) in [(positional, "prices.xmi"), (named, "named.xmi")] {
            #expect(result.succeeded, "\(Self.output(result))")
            let text = try String(contentsOf: directory.appendingPathComponent(file), encoding: .utf8)
            #expect(Self.entries.allSatisfy { text.contains($0) }, "\(text)")
        }
        #expect(checked.succeeded, "\(Self.output(checked))")
        #expect(
            checked.stdout.contains("Products (urn:swift-ecore:multilevel:view:Catalogue:Shelf:deep)"),
            "\(checked.stdout)")
    }

    @Test("refines the deep view under another metamodel name")
    @MainActor
    func refinesUnderAnotherName() async throws {
        let directory = try Self.project()
        defer { cleanupTemporaryDirectory(directory) }
        try """
            module Copy;
            create OUT : Products refining IN : Products;

            """.write(to: directory.appendingPathComponent("Copy.atl"), atomically: true, encoding: .utf8)

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: ["Copy.atl", "--source", "shop.mdepth", "--target", "copy.xmi", "--deep-view", "0"],
            workingDirectory: directory)

        #expect(result.succeeded, "\(Self.output(result))")
        let text = try String(contentsOf: directory.appendingPathComponent("copy.xmi"), encoding: .utf8)
        #expect(text.contains(#"<bookshop:Book gst="0.0" price="35.0"/>"#), "\(text)")
        #expect(text.contains(#"<bookshop:Magazine gst="10.0" price="9.5"/>"#), "\(text)")
    }

    @Test("offers the deep services on objects and types to a transformation")
    @MainActor
    func deepServices() async throws {
        let directory = try Self.project()
        defer { cleanupTemporaryDirectory(directory) }
        try """
            query Services = Sequence{
              Bookshop!ProductType.deepInstances()->collect(p | p.clabjectName()),
              Bookshop!ProductType.instancesAtLevel(1)->collect(p | p.clabjectName()),
              -- collect flattens the deep types of the two products into one sequence
              Bookshop!ProductType.allInstances()->collect(p | p.deepTypes()->collect(t | t.name)),
              Bookshop!ProductType.allInstances()->collect(p | p.typeAtLevel(1).clabjectName()),
              Bookshop!ProductType.allInstances()->collect(p | p.slotValue('gst')),
              Bookshop!ProductType.allInstances()
                ->select(p | p.isDeepInstanceOf(Bookshop!Book))->collect(p | p.clabjectName()),
              Bookshop!ProductType.allInstances()->collect(p | p.potency())
            };

            """.write(to: directory.appendingPathComponent("Services.atl"), atomically: true, encoding: .utf8)

        let result = try await executeSwiftATL(
            command: "query", arguments: ["Services.atl", "--source", "shop.mdepth", "--deep-view", "0"],
            workingDirectory: directory)

        #expect(result.succeeded, "\(Self.output(result))")
        #expect(
            result.stdout
                == consoleText(
                    "Sequence{Sequence{'Book', 'Magazine', 'manual', 'monthly'}, Sequence{'Book', 'Magazine'}, "
                        + "Sequence{'Book', 'ProductType', 'Magazine', 'ProductType'}, "
                        + "Sequence{'Book', 'Magazine'}, Sequence{0.0, 10.0}, Sequence{'manual'}, Sequence{0, 0}}\n"),
            "\(result.stdout)")
    }

    @Test("applies the deep view only to the multi-level source models")
    @MainActor
    func mixedSources() async throws {
        let directory = try Self.project()
        defer { cleanupTemporaryDirectory(directory) }
        try """
            <?xml version="1.0" encoding="UTF-8"?>
            <xmi:XMI xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:pricelist="http://example.org/pricelist">
              <pricelist:Entry product="old" price="1.0"/>
            </xmi:XMI>

            """.write(to: directory.appendingPathComponent("old.xmi"), atomically: true, encoding: .utf8)
        try """
            -- @path PriceList=PriceList.ecore
            module Merge;
            create OUT : PriceList from IN : Bookshop, OLD : PriceList;

            rule Product2Entry {
              from p : Bookshop!ProductType
              to e : PriceList!Entry (
                product <- p.clabjectName(),
                kind <- PriceList!Entry.allInstancesFrom('OLD')->first().product
              )
            }

            """.write(to: directory.appendingPathComponent("Merge.atl"), atomically: true, encoding: .utf8)

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                "Merge.atl", "--source", "shop.mdepth", "--source", "old.xmi", "--target", "merged.xmi",
                "--deep-view", "0",
            ],
            workingDirectory: directory)

        #expect(result.succeeded, "\(Self.output(result))")
        let text = try String(contentsOf: directory.appendingPathComponent("merged.xmi"), encoding: .utf8)
        #expect(text.contains(#"product="manual" kind="old""#), "\(text)")
        #expect(text.contains(#"product="monthly" kind="old""#), "\(text)")
    }

    @Test("reports a level that the multi-level model does not have")
    @MainActor
    func missingLevel() async throws {
        let directory = try Self.project()
        defer { cleanupTemporaryDirectory(directory) }

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: ["Shelf2PriceList.atl", "--source", "shop.mdepth", "--target", "prices.xmi", "--deep-view", "9"],
            workingDirectory: directory)

        #expect(!result.succeeded)
        #expect(
            Self.output(result).contains(
                "--deep-view: shop.mdepth: Invalid value in a multi-level model: level 9 does not exist"),
            "\(Self.output(result))")
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("prices.xmi").path))
    }

    @Test("reports source models that hold no multi-level model")
    @MainActor
    func noMultiLevelSource() async throws {
        let directory = try Self.project()
        defer { cleanupTemporaryDirectory(directory) }

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                "Shelf2PriceList.atl", "--source", "PriceList.ecore", "--target", "prices.xmi", "--deep-view", "0",
            ],
            workingDirectory: directory)

        #expect(!result.succeeded)
        #expect(
            Self.output(result).contains(
                "--deep-view 0 needs a multi-level source model, such as a MetaDepth document (.mdepth): PriceList.ecore holds no multi-level model"
            ), "\(Self.output(result))")
    }

    @Test("reports two multi-level source models whose views present packages of the same name")
    @MainActor
    func ambiguousViews() async throws {
        let directory = try Self.project()
        defer { cleanupTemporaryDirectory(directory) }
        try Self.products.write(to: directory.appendingPathComponent("copy.mdepth"), atomically: true, encoding: .utf8)
        try """
            module Both;
            create OUT : Bookshop from IN : Bookshop, OTHER : Bookshop;

            """.write(to: directory.appendingPathComponent("Both.atl"), atomically: true, encoding: .utf8)

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                "Both.atl", "--source", "shop.mdepth", "--source", "copy.mdepth", "--target", "both.xmi",
                "--deep-view", "0",
            ],
            workingDirectory: directory)

        #expect(!result.succeeded)
        #expect(
            Self.output(result).contains(
                "the deep views of shop.mdepth and copy.mdepth both present the package 'Bookshop'"),
            "\(Self.output(result))")
    }

    @Test("validates a transformation against the package of the deep view")
    @MainActor
    func validatesOnly() async throws {
        let directory = try Self.project()
        defer { cleanupTemporaryDirectory(directory) }

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: ["Shelf2PriceList.atl", "--source", "shop.mdepth", "--validate-only", "--deep-view", "0"],
            workingDirectory: directory)

        #expect(result.succeeded, "\(Self.output(result))")
        #expect(
            result.stdout.contains("Bookshop (urn:swift-ecore:multilevel:view:Catalogue:Shelf:deep)"),
            "\(result.stdout)")
        #expect(result.stdout.contains("Source models loaded: 1"), "\(result.stdout)")
    }

    @Test("evaluates a query over the deep view of a level, bound by position or by model name")
    @MainActor
    func queriesDeepView() async throws {
        let directory = try Self.project()
        defer { cleanupTemporaryDirectory(directory) }
        try """
            query Products = Bookshop!ProductType.allInstances()
              ->collect(p | p.clabjectName() + ':' + p.level().toString() + ':' + p.linguisticType())
              ->sortedBy(n | n);

            """.write(to: directory.appendingPathComponent("Products.atl"), atomically: true, encoding: .utf8)

        let deep = try await executeSwiftATL(
            command: "query", arguments: ["Products.atl", "--source", "shop.mdepth", "--deep-view", "0"],
            workingDirectory: directory)
        let types = try await executeSwiftATL(
            command: "query",
            arguments: ["Products.atl", "--source", "IN:Bookshop=shop.mdepth", "--deep-view", "1"],
            workingDirectory: directory)
        try String(contentsOf: directory.appendingPathComponent("Products.atl"), encoding: .utf8)
            .replacingOccurrences(of: "Bookshop", with: "Goods")
            .write(to: directory.appendingPathComponent("Goods.atl"), atomically: true, encoding: .utf8)
        let renamed = try await executeSwiftATL(
            command: "query",
            arguments: ["Goods.atl", "--source", "IN:Goods=shop.mdepth", "--deep-view", "0"],
            workingDirectory: directory)

        #expect(deep.succeeded, "\(Self.output(deep))")
        #expect(deep.stdout == consoleText("Sequence{'manual:0:Node', 'monthly:0:Node'}\n"))
        #expect(types.succeeded, "\(Self.output(types))")
        #expect(types.stdout == consoleText("Sequence{'Book:1:Node', 'Magazine:1:Node'}\n"))
        #expect(renamed.succeeded, "\(Self.output(renamed))")
        #expect(renamed.stdout == deep.stdout)
    }

    @Test("lists the option in the help of transform and query")
    @MainActor
    func help() async throws {
        for command in ["transform", "query"] {
            let result = try await executeSwiftATL(command: command, arguments: ["--help"])
            #expect(result.stdout.contains("--deep-view <level>"), "\(command): \(result.stdout)")
        }
    }
}
