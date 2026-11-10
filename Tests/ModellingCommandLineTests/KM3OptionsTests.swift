//
// KM3OptionsTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingCommandLine
import Testing

/// Tests for `--km3-primitives`, its configuration key, and the formats of metamodel files.
@Suite("KM3 options")
struct KM3OptionsTests {
    /// A KM3 metamodel with two packages, the second of which declares primitive types.
    static let library = """
        package Library {
            class Book {
                attribute title : String;
                attribute pages : Integer;
            }
        }

        package PrimitiveTypes {
            datatype String;
            datatype Integer;
        }

        """

    /// Writes a file to a new temporary directory.
    ///
    /// - Parameters:
    ///   - text: The contents of the file.
    ///   - name: The name of the file.
    /// - Returns: The path of the file.
    /// - Throws: Any error writing the file.
    static func write(_ text: String, named name: String) throws -> String {
        let url = try ScratchDirectory().url.appendingPathComponent(name)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url.path
    }

    /// Settings whose configuration file holds a text.
    static func settings(_ text: String) throws -> SemanticsSettings {
        SemanticsSettings(
            configuration: try ModellingConfiguration(
                data: Data(text.utf8), url: URL(fileURLWithPath: "/projects/example/.swift-modelling.json")))
    }

    // MARK: - Option

    @Test("names the option once and lists the mappings of the reader")
    func names() {
        #expect(KM3Options.optionName == "km3-primitives")
        #expect(KM3Options.valueList == KM3PrimitiveTypeMapping.allCases.map(\.rawValue).joined(separator: "|"))
        #expect(KM3Options.valueList == "ecore|declared")
        #expect(KM3Options.defaultMapping == .ecore)
    }

    @Test("parses each mapping by its name", arguments: KM3PrimitiveTypeMapping.allCases)
    func parses(mapping: KM3PrimitiveTypeMapping) throws {
        let options = try KM3Options.parse(["--km3-primitives", mapping.rawValue])
        #expect(options.explicitPrimitiveTypes == mapping)
        #expect(options.readOptions == KM3ReadOptions(primitiveTypes: mapping))
        #expect(options.ecoreLoadOptions == EcoreLoadOptions(km3Options: KM3ReadOptions(primitiveTypes: mapping)))
    }

    @Test("rejects an unknown mapping")
    func rejectsUnknown() {
        #expect(throws: (any Error).self) { try KM3Options.parse(["--km3-primitives", "java"]) }
    }

    @Test("takes the mapping of the configuration file, which the command line overrides")
    func precedence() throws {
        let none = try KM3Options.parse([])
        let explicit = try KM3Options.parse(["--km3-primitives", "ecore"])
        let configured = try Self.settings(#"{ "km3-primitives": "declared" }"#)
        #expect(none.readOptions(settings: try Self.settings("{}")) == .standard)
        #expect(none.readOptions(settings: configured) == .declaredDataTypes)
        #expect(explicit.readOptions(settings: configured) == .standard)
        #expect(none.ecoreLoadOptions(settings: configured).km3Options == .declaredDataTypes)
        #expect(configured.configuration.km3PrimitiveTypes == .declared)
    }

    @Test("rejects an unknown mapping in the configuration file")
    func invalidConfiguration() {
        let file = URL(fileURLWithPath: "/projects/example/.swift-modelling.json")
        let error = configurationError { () throws(ModellingConfigurationError) in
            try ModellingConfiguration(data: Data(#"{ "km3-primitives": "java" }"#.utf8), url: file)
        }
        #expect(error == .invalidValue("java", key: "km3-primitives", accepted: ["ecore", "declared"], path: file.path))
    }

    // MARK: - Formats

    @Test("tells metamodel files from files that may hold one")
    func formats() {
        #expect(MetamodelRegistration.isMetamodelFile("a/Library.km3"))
        #expect(MetamodelRegistration.isMetamodelFile("a/Library.ECORE"))
        #expect(!MetamodelRegistration.isMetamodelFile("a/library.json"))
        #expect(!MetamodelRegistration.isMetamodelFile("a/library.xmi"))
        #expect(!MetamodelRegistration.isMetamodelFile("a/library"))
        #expect(MetamodelRegistration.mayHoldMetamodel("a/library.json"))
        #expect(MetamodelRegistration.mayHoldMetamodel("a/Library.km3"))
        #expect(!MetamodelRegistration.mayHoldMetamodel("a/library.xmi"))
        #expect(!MetamodelRegistration.mayHoldMetamodel("a/notes.txt"))
    }
}

/// Tests for the registration of metamodels in KM3 and JSON.
///
/// They redirect standard output and standard error, so they belong to the serialised suite
/// of ``MetamodelRegistrationTests``.
extension MetamodelRegistrationTests {
    // MARK: - Registration

    @Test("registers a KM3 package under its name, warning on standard error")
    @MainActor
    func registersUnderName() async throws {
        let path = try KM3OptionsTests.write(KM3OptionsTests.library, named: "Library.km3")
        let resourceSet = ResourceSet()
        var packages: [EPackage] = []
        var output = ""
        let errors = try await StandardOutputCapture.captureError {
            output = try await StandardOutputCapture.capture {
                packages = try await MetamodelRegistration.registerMetamodels(at: path, into: resourceSet, verbose: true)
            }
        }
        #expect(packages.map(\.name) == ["Library"])
        #expect(await resourceSet.getMetamodelURIs() == ["Library"])
        let book = await resourceSet.getMetamodel(uri: "Library")?.getClassifier("Book") as? EClass
        #expect(book?.eAttributes.map(\.eType.name) == ["EString", "EInt"])
        #expect(errors.contains("warning: \(path): The package 'Library'"), "\(errors)")
        #expect(errors.contains("registered under its name"), "\(errors)")
        #expect(output.contains("Registered metamodel 'Library' with URI: Library"), "\(output)")
    }

    @Test("reads the declared data types of KM3 as the options say")
    @MainActor
    func declaredDataTypes() async throws {
        let path = try KM3OptionsTests.write(KM3OptionsTests.library, named: "Library.km3")
        let resourceSet = ResourceSet()
        _ = try await StandardOutputCapture.captureError {
            let packages = try await MetamodelRegistration.registerMetamodels(
                at: path, into: resourceSet, options: EcoreLoadOptions(km3Options: .declaredDataTypes))
            #expect(packages.map(\.name) == ["Library", "PrimitiveTypes"])
        }
        #expect(Set(await resourceSet.getMetamodelURIs()) == ["Library", "PrimitiveTypes"])
        let book = await resourceSet.getMetamodel(uri: "Library")?.getClassifier("Book") as? EClass
        #expect(book?.eAttributes.map(\.eType.name) == ["String", "Integer"])
    }

    @Test("reports a syntax error of KM3 on standard error with its place")
    @MainActor
    func syntaxError() async throws {
        let path = try KM3OptionsTests.write("package Broken {\n  class X {\n    attribute a : ;\n  }\n}\n", named: "Broken.km3")
        let errors = try await StandardOutputCapture.captureError {
            _ = try await MetamodelRegistration.loadPackages(at: path)
        }
        #expect(errors.contains("error: \(path): line 3, column "), "\(errors)")
    }

    @Test("the metamodel option reads KM3 and JSON metamodels")
    @MainActor
    func metamodelOptionFormats() async throws {
        let km3 = try KM3OptionsTests.write(KM3OptionsTests.library, named: "Library.km3")
        let json = try KM3OptionsTests.write(
            #"{ "eClass": "http://www.eclipse.org/emf/2002/Ecore#//EPackage", "name": "shop", "nsURI": "http://example.org/shop", "nsPrefix": "shop" }"#,
            named: "shop.json")
        let options = try MetamodelOptions.parse(["--metamodel", km3, "--metamodel", json])
        var resourceSet: ResourceSet?
        _ = try await StandardOutputCapture.captureError { resourceSet = try await options.resourceSet() }
        #expect(Set(await resourceSet?.getMetamodelURIs() ?? []) == ["Library", "http://example.org/shop"])
    }
}
