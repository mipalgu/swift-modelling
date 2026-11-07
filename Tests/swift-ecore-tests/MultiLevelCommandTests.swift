//
// MultiLevelCommandTests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for multi-level models in the MetaDepth notation, UML class models as metamodels and
/// the translation of OCL invariants on the command line of swift-ecore.
@Suite("swift-ecore - multi-level models, UML metamodels and OCL translation", .serialized)
struct MultiLevelCommandTests {
    /// A three-level model of products.
    static let shop = """
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
        }

        """

    /// A model whose bottom level refers to a clabject one level up without declaring it.
    static let crossing = """
        Model Cycling@2 {
          Node BicycleType {
            alternative : BicycleType[0..1];
          }
        }
        Cycling Catalogue {
          BicycleType Racer {}
        }
        Catalogue Inventory {
          Racer bike {
            alternative = Racer;
          }
        }

        """

    /// A UML class model.
    static let garden = """
        <?xml version="1.0" encoding="UTF-8"?>
        <uml:Model xmi:version="20131001" xmlns:xmi="http://www.omg.org/spec/XMI/20131001" \
        xmlns:uml="http://www.eclipse.org/uml2/5.0.0/UML" xmi:id="m" name="garden">
          <packagedElement xmi:type="uml:Class" xmi:id="Plant" name="Plant">
            <ownedAttribute xmi:id="Plant-height" name="height">\
        <type xmi:type="uml:PrimitiveType" href="pathmap://UML_LIBRARIES/UMLPrimitiveTypes.library.uml#Integer"/>\
        </ownedAttribute>
          </packagedElement>
        </uml:Model>

        """

    /// A plant of the garden.
    static let rose = """
        <?xml version="1.0" encoding="UTF-8"?>
        <garden:Plant xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:garden="http:///garden.ecore" height="7"/>

        """

    /// Constraints on plants: one whose OCL division differs from AQL, and one without an AQL
    /// translation.
    static let constraints = """
        package garden
        context Plant
        inv Half: height / 2 > 3.4
        inv Sum: Sequence{1, 2}->iterate(x; acc : Integer = 0 | acc + x) = 3
        endpackage

        """

    /// A directory with the files of the tests.
    struct Files {
        /// The directory.
        let directory: URL

        /// Creates the files.
        init() throws {
            directory = try createTemporaryDirectory()
            let files = [
                (MultiLevelCommandTests.shop, "shop.mdepth"), (MultiLevelCommandTests.crossing, "crossing.mdepth"),
                (MultiLevelCommandTests.garden, "garden.uml"), (MultiLevelCommandTests.rose, "rose.xmi"),
                (MultiLevelCommandTests.constraints, "garden.ocl"),
            ]
            for (text, name) in files {
                try text.write(to: file(name), atomically: true, encoding: .utf8)
            }
        }

        /// A file in the directory.
        func file(_ name: String) -> URL { directory.appendingPathComponent(name) }

        /// Removes the directory.
        func remove() { cleanupTemporaryDirectory(directory) }
    }

    // MARK: - Multi-level models

    @Test("inspects the levels of a MetaDepth model")
    @MainActor
    func inspect() async throws {
        let files = try Files()
        defer { files.remove() }

        let result = try await executeSwiftEcore(command: "inspect", arguments: [files.file("shop.mdepth").path])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.hasPrefix("Multi-level model: shop.mdepth (MetaDepth)\n"), "\(result.stdout)")
        #expect(result.stdout.contains("Level crossing: declared"), "\(result.stdout)")
        #expect(result.stdout.contains("Level 1: BookStore (instance of Commerce)\n  Book : ProductType @1"), "\(result.stdout)")
        #expect(result.stdout.contains("Level 0: Shop (instance of BookStore)\n  patterns : Book @0"), "\(result.stdout)")
    }

    @Test("validates level crossings as --level-crossing says")
    @MainActor
    func levelCrossing() async throws {
        let files = try Files()
        defer { files.remove() }
        let crossing = files.file("crossing.mdepth")
        let declared = files.file("declared.mdepth")
        try Self.crossing.replacingOccurrences(of: "[0..1];", with: "[0..1] {level=1};")
            .write(to: declared, atomically: true, encoding: .utf8)

        let standard = try await executeSwiftEcore(command: "validate", arguments: [crossing.path])
        let nonStrict = try await executeSwiftEcore(
            command: "validate", arguments: [crossing.path, "--level-crossing", "non-strict"])
        let declaredStandard = try await executeSwiftEcore(command: "validate", arguments: [declared.path])
        let declaredStrict = try await executeSwiftEcore(
            command: "validate", arguments: [declared.path, "--level-crossing", "strict"])

        #expect(!standard.succeeded)
        #expect(standard.stdout.contains("refers to 'Catalogue.Racer' at level 1"), "\(standard.stdout)")
        #expect(nonStrict.succeeded, "\(nonStrict.stdout)\(nonStrict.stderr)")
        #expect(declaredStandard.succeeded, "\(declaredStandard.stdout)\(declaredStandard.stderr)")
        #expect(!declaredStrict.succeeded)
        #expect(declaredStrict.stdout.contains("is declared to refer to level 1"), "\(declaredStrict.stdout)")
    }

    @Test("converts a MetaDepth model to XMI and JSON and back without loss")
    @MainActor
    func roundTrip() async throws {
        let files = try Files()
        defer { files.remove() }
        let source = files.file("shop.mdepth")

        let toXMI = try await executeSwiftEcore(command: "convert", arguments: [source.path, files.file("shop.xmi").path])
        let toJSON = try await executeSwiftEcore(command: "convert", arguments: [source.path, files.file("shop.json").path])
        let fromXMI = try await executeSwiftEcore(
            command: "convert", arguments: [files.file("shop.xmi").path, files.file("from-xmi.mdepth").path])
        let fromJSON = try await executeSwiftEcore(
            command: "convert", arguments: [files.file("shop.json").path, files.file("from-json.mdepth").path])

        for result in [toXMI, toJSON, fromXMI, fromJSON] {
            #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
            #expect(!result.stderr.contains("hint:"), "\(result.stderr)")
        }
        let original = try String(contentsOf: source, encoding: .utf8)
        #expect(try String(contentsOf: files.file("from-xmi.mdepth"), encoding: .utf8) == original)
        #expect(try String(contentsOf: files.file("from-json.mdepth"), encoding: .utf8) == original)
        let inspection = try await executeSwiftEcore(command: "inspect", arguments: [files.file("shop.xmi").path])
        #expect(inspection.stdout.hasPrefix("Multi-level model: shop.xmi (XMI)\n"), "\(inspection.stdout)")
    }

    @Test("writes the Ecore metamodel of one level of a multi-level model")
    @MainActor
    func levelExport() async throws {
        let files = try Files()
        defer { files.remove() }
        let source = files.file("shop.mdepth")
        let output = files.file("bookstore.ecore")

        let withoutLevel = try await executeSwiftEcore(command: "convert", arguments: [source.path, output.path])
        let missingLevel = try await executeSwiftEcore(
            command: "convert", arguments: [source.path, output.path, "--level", "7"])
        let exported = try await executeSwiftEcore(
            command: "convert", arguments: [source.path, output.path, "--level", "1"])
        let notDeep = try await executeSwiftEcore(
            command: "convert", arguments: [files.file("rose.xmi").path, files.file("rose.ecore").path, "--level", "0"])

        #expect(!withoutLevel.succeeded)
        #expect(withoutLevel.stderr.contains("give --level <level>"), "\(withoutLevel.stderr)")
        #expect(withoutLevel.stderr.contains("(levels: 2, 1, 0)"), "\(withoutLevel.stderr)")
        #expect(!missingLevel.succeeded)
        #expect(missingLevel.stderr.contains("has no level 7"), "\(missingLevel.stderr)")
        #expect(exported.succeeded, "\(exported.stdout)\(exported.stderr)")
        let text = try String(contentsOf: output, encoding: .utf8)
        #expect(text.contains("name=\"ProductType\""), "\(text)")
        #expect(text.contains("<details key=\"level\" value=\"2\"/>"), "\(text)")
        #expect(!notDeep.succeeded)
        #expect(notDeep.stderr.contains("holds no multi-level model"), "\(notDeep.stderr)")
    }

    // MARK: - UML class models as metamodels

    @Test("reads a UML class model as a metamodel with --metamodel, and converts it to Ecore")
    @MainActor
    func umlMetamodel() async throws {
        let files = try Files()
        defer { files.remove() }
        let output = files.file("garden.ecore")

        let validation = try await executeSwiftEcore(
            command: "validate", arguments: [files.file("rose.xmi").path, "--metamodel", files.file("garden.uml").path])
        let conversion = try await executeSwiftEcore(
            command: "convert", arguments: [files.file("garden.uml").path, output.path])

        #expect(validation.succeeded, "\(validation.stdout)\(validation.stderr)")
        #expect(conversion.succeeded, "\(conversion.stdout)\(conversion.stderr)")
        let text = try String(contentsOf: output, encoding: .utf8)
        #expect(text.contains("nsURI=\"http:///garden.ecore\""), "\(text)")
        #expect(text.contains("name=\"height\""), "\(text)")
    }

    // MARK: - OCL translation

    @Test("evaluates OCL invariants through their AQL translation and warns about untranslatable ones")
    @MainActor
    func oclTranslation() async throws {
        let files = try Files()
        defer { files.remove() }
        let arguments = [
            files.file("rose.xmi").path, "--metamodel", files.file("garden.uml").path, "--ocl", files.file("garden.ocl").path,
        ]

        let result = try await executeSwiftEcore(command: "validate", arguments: arguments + ["--verbose"])
        let strict = try await executeSwiftEcore(command: "validate", arguments: arguments + ["--strict"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.contains("Checking constraint: Half (Plant, /) ... satisfied"), "\(result.stdout)")
        #expect(result.stdout.contains("Checking constraint: Sum (Plant, /) ... untranslated"), "\(result.stdout)")
        #expect(result.stdout.contains("'iterate'"), "\(result.stdout)")
        #expect(!strict.succeeded)
    }
}
