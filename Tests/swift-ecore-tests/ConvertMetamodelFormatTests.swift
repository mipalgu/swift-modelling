//
// ConvertMetamodelFormatTests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import Testing

@Suite("swift-ecore convert - Metamodel formats")
struct ConvertMetamodelFormatTests {
    /// The metamodel that refers to another metamodel file.
    static let metamodel = "catalogue.ecore"

    /// The metamodel file that the other one refers to.
    static let base = "catalogue-base.ecore"

    /// The reference to the class of the other metamodel file, as the converted documents keep it.
    static let externalReference = "catalogue-base.ecore#//Named"

    /// The class of an Ecore package in a JSON metamodel.
    static let packageClass = "http://www.eclipse.org/emf/2002/Ecore#//EPackage"

    /// Copies the two catalogue metamodels into a new directory.
    ///
    /// - Returns: The directory.
    private func copyMetamodels() throws -> URL {
        let directory = try createTemporaryDirectory()
        for name in [Self.metamodel, Self.base] {
            try FileManager.default.copyItem(
                at: try loadTestResource(named: name, subdirectory: "ecore"),
                to: directory.appendingPathComponent(name))
        }
        return directory
    }

    /// Converts a file with the command.
    ///
    /// - Parameters:
    ///   - input: The file to convert.
    ///   - output: The file to write.
    ///   - options: Further arguments.
    /// - Returns: The result of the command.
    private func convert(_ input: URL, _ output: URL, _ options: [String] = []) async throws -> SubprocessResult {
        try await executeSwiftEcore(command: "convert", arguments: [input.path, output.path] + options)
    }

    /// The text of a metamodel file as JSON, written as if it were in a given directory.
    ///
    /// Two metamodels with the same text hold the same packages, classes, features, literals,
    /// supertypes, opposites and references to other documents.
    ///
    /// - Parameters:
    ///   - url: The metamodel file, in either format.
    ///   - directory: The directory against which references to other documents are written.
    /// - Returns: The JSON text.
    @MainActor
    private func canonicalText(of url: URL, in directory: URL) async throws -> String {
        let loaded = try await ModelIO.load(url: url, resourceSet: ResourceSet())
        #expect(!loaded.packages.isEmpty, "\(url.lastPathComponent) is not a metamodel")
        return JSONSerializer().serialize(loaded.packages, relativeTo: directory.appendingPathComponent("canonical.json"))
    }

    @Test("converts an Ecore metamodel to a JSON metamodel that keeps the file name of a reference")
    @MainActor
    func ecoreToJSON() async throws {
        let directory = try copyMetamodels()
        defer { cleanupTemporaryDirectory(directory) }
        let json = directory.appendingPathComponent("catalogue.json")

        let result = try await convert(directory.appendingPathComponent(Self.metamodel), json)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.contains("Conversion completed: \(json.path)"))
        let text = try String(contentsOf: json, encoding: .utf8)
        let root = try #require(try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any])
        #expect(root["eClass"] as? String == Self.packageClass)
        #expect(root["name"] as? String == "catalogue")
        let classifiers = root["eClassifiers"] as? [[String: Any]] ?? []
        #expect(classifiers.compactMap { $0["name"] as? String } == ["Catalogue", "Item", "Maker", "Gadget", "Kind"])
        #expect(text.contains("\"\(Self.externalReference)\""), "\(text)")
    }

    @Test("converts a metamodel with enumerations, opposites, supertypes and a reference to another file there and back")
    @MainActor
    func roundTrip() async throws {
        let directory = try copyMetamodels()
        defer { cleanupTemporaryDirectory(directory) }
        let original = directory.appendingPathComponent(Self.metamodel)
        let json = directory.appendingPathComponent("catalogue.json")
        let copy = directory.appendingPathComponent("catalogue-copy.ecore")

        let toJSON = try await convert(original, json)
        let back = try await convert(json, copy)

        #expect(toJSON.succeeded, "\(toJSON.stdout)\(toJSON.stderr)")
        #expect(back.succeeded, "\(back.stdout)\(back.stderr)")
        let ecore = try String(contentsOf: copy, encoding: .utf8)
        #expect(ecore.contains("eSuperTypes=\"\(Self.externalReference)\""), "\(ecore)")
        #expect(ecore.contains("eSuperTypes=\"#//Item\""), "\(ecore)")
        #expect(ecore.contains("eOpposite=\"#//Maker/items\""), "\(ecore)")
        #expect(ecore.contains("eOpposite=\"#//Item/maker\""), "\(ecore)")
        #expect(ecore.contains("xsi:type=\"ecore:EEnum\" name=\"Kind\""), "\(ecore)")
        #expect(ecore.contains("literal=\"Book\""), "\(ecore)")
        #expect(ecore.contains("defaultValueLiteral=\"tool\""), "\(ecore)")
        let expected = try await canonicalText(of: original, in: directory)
        #expect(try await canonicalText(of: json, in: directory) == expected)
        #expect(try await canonicalText(of: copy, in: directory) == expected)
    }

    @Test("reads a JSON metamodel by its contents, whatever the name of the file")
    @MainActor
    func detectsJSONMetamodelByContents() async throws {
        let directory = try copyMetamodels()
        defer { cleanupTemporaryDirectory(directory) }
        let json = directory.appendingPathComponent("catalogue.json")
        let renamed = directory.appendingPathComponent("catalogue.data")
        let copy = directory.appendingPathComponent("catalogue-copy.ecore")
        _ = try await convert(directory.appendingPathComponent(Self.metamodel), json)
        try FileManager.default.moveItem(at: json, to: renamed)

        let result = try await convert(renamed, copy, ["--input-format", "json"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(try await canonicalText(of: copy, in: directory)
            == (try await canonicalText(of: directory.appendingPathComponent(Self.metamodel), in: directory)))
    }

    @Test("converts a set of metamodels whose references are renamed to the JSON files")
    @MainActor
    func convertsSet() async throws {
        let directory = try copyMetamodels()
        defer { cleanupTemporaryDirectory(directory) }
        let baseJSON = directory.appendingPathComponent("catalogue-base.json")
        let json = directory.appendingPathComponent("catalogue.json")
        let copy = directory.appendingPathComponent("catalogue-copy.ecore")
        for (input, output) in [(Self.base, baseJSON), (Self.metamodel, json)] {
            let result = try await convert(directory.appendingPathComponent(input), output)
            #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        }
        let renamed = try String(contentsOf: json, encoding: .utf8)
            .replacingOccurrences(of: "catalogue-base.ecore#", with: "catalogue-base.json#")
        try renamed.write(to: json, atomically: true, encoding: .utf8)
        for name in [Self.metamodel, Self.base] {
            try FileManager.default.removeItem(at: directory.appendingPathComponent(name))
        }

        let result = try await convert(json, copy)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let ecore = try String(contentsOf: copy, encoding: .utf8)
        #expect(ecore.contains("eSuperTypes=\"catalogue-base.json#//Named\""), "\(ecore)")
    }

    @Test("rejects a metamodel output in a model format, writing nothing", arguments: ["xmi"])
    @MainActor
    func metamodelToModelFormat(format: String) async throws {
        let directory = try copyMetamodels()
        defer { cleanupTemporaryDirectory(directory) }
        let output = directory.appendingPathComponent("catalogue.\(format)")

        let result = try await convert(directory.appendingPathComponent(Self.metamodel), output)

        #expect(!result.succeeded)
        #expect(result.stderr.contains("catalogue.ecore is a metamodel"), "\(result.stderr)")
        #expect(result.stderr.contains("convert it to one of: ecore, json"), "\(result.stderr)")
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test("rejects a model written as an Ecore metamodel, writing nothing", arguments: ["xmi/valid-model.xmi", "json/valid-model.json"])
    @MainActor
    func modelToEcore(path: String) async throws {
        let parts = path.split(separator: "/").map(String.init)
        let model = try loadTestResource(named: parts[1], subdirectory: parts[0])
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let output = directory.appendingPathComponent("model.ecore")

        let result = try await convert(model, output)

        #expect(!result.succeeded)
        #expect(result.stderr.contains("\(parts[1]) is a model"), "\(result.stderr)")
        #expect(result.stderr.contains("convert it to one of: xmi, json"), "\(result.stderr)")
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test("reads a JSON document that mixes a package with other objects as a model, not a metamodel")
    @MainActor
    func mixedJSON() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let input = directory.appendingPathComponent("mixed.json")
        let output = directory.appendingPathComponent("mixed.ecore")
        try """
            [
              { "eClass": "\(Self.packageClass)", "name": "p", "nsURI": "http://www.example.org/p", "nsPrefix": "p" },
              { "eClass": "http://www.example.org/p#//Thing", "name": "x" }
            ]
            """.write(to: input, atomically: true, encoding: .utf8)

        let result = try await convert(input, output)

        #expect(!result.succeeded)
        #expect(result.stderr.contains("mixed.json is a model"), "\(result.stderr)")
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test("rejects an input whose format is unknown")
    @MainActor
    func unsupportedInput() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let input = directory.appendingPathComponent("catalogue.txt")
        try "catalogue".write(to: input, atomically: true, encoding: .utf8)

        let result = try await convert(input, directory.appendingPathComponent("catalogue.json"))

        #expect(!result.succeeded)
        #expect(result.stderr.contains("Unsupported input format: txt"), "\(result.stderr)")
    }

    @Test("validates a metamodel before converting it with --validate")
    @MainActor
    func validatesMetamodel() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let output = directory.appendingPathComponent("bounds.json")

        let result = try await convert(try loadTestResource(named: "bounds.ecore", subdirectory: "ecore"), output, ["--validate"])

        #expect(!result.succeeded)
        #expect(result.stdout.contains("The lower bound 2 must not exceed the upper bound 1."), "\(result.stdout)")
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test("explains in the help that references to other metamodel files keep their file names")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftEcore(command: "convert", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("keep their file names"), "\(result.stdout)")
    }
}
