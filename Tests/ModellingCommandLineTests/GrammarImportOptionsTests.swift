//
// GrammarImportOptionsTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingCommandLine
import Testing

/// Tests for the options of grammar imports, their configuration keys, and their combination
/// with the KM3 options.
@Suite("Grammar import options")
struct GrammarImportOptionsTests {
    /// Settings whose configuration file holds a text.
    ///
    /// - Parameter text: The JSON text of the configuration file.
    /// - Returns: The settings.
    /// - Throws: The error of the configuration file.
    static func settings(_ text: String) throws -> SemanticsSettings {
        SemanticsSettings(
            configuration: try ModellingConfiguration(
                data: Data(text.utf8), url: URL(fileURLWithPath: "/projects/example/.swift-modelling.json")))
    }

    @Test("names the options once")
    func names() {
        #expect(GrammarImportOptions.OptionName.packageName == "package-name")
        #expect(GrammarImportOptions.OptionName.nsURI == "ns-uri")
        #expect(GrammarImportOptions.OptionName.nsPrefix == "ns-prefix")
        #expect(GrammarImportOptions.OptionName.asdlEnumerations == "asdl-enumerations")
        #expect(GrammarImportOptions.OptionName.langiumTypes == "langium-types")
        #expect(GrammarImportOptions.OptionName.sdf3Labels == "sdf3-labels")
        #expect(GrammarImportOptions.asdlEnumerationsValueList == "all-nullary|never")
        #expect(GrammarImportOptions.langiumTypesValueList == "normal|strict")
    }

    @Test("leaves the load options at their defaults when nothing is given")
    func defaults() throws {
        let options = try MetamodelFormatOptions.parse([])
        #expect(options.ecoreLoadOptions == EcoreLoadOptions())
        #expect(options.ecoreLoadOptions(settings: try Self.settings("{}")) == EcoreLoadOptions())
    }

    @Test("gives the package of every grammar import the names of the command line")
    func packageNames() throws {
        let options = try GrammarImportOptions.parse([
            "--package-name", "Calc", "--ns-uri", "http://example.org/calc", "--ns-prefix", "calc",
        ])
        var load = EcoreLoadOptions()
        options.apply(to: &load)
        #expect(load.asdlOptions.packageName == "Calc")
        #expect(load.langiumOptions.nsURI == "http://example.org/calc")
        #expect(load.xtextOptions.nsPrefix == "calc")
        #expect(load.sdf3Options.packageName == "Calc")
        #expect(load.sdf3Options.nsURI == "http://example.org/calc")
        #expect(load.km3Options == .standard)
    }

    @Test("maps the ASDL enumeration spellings to the styles of the importer", arguments: ASDLEnumerationsOption.allCases)
    func asdlEnumerations(option: ASDLEnumerationsOption) throws {
        let options = try MetamodelFormatOptions.parse(["--asdl-enumerations", option.rawValue])
        let expected: ASDLEnumerationStyle = option == .never ? .never : .allNullarySums
        #expect(options.ecoreLoadOptions.asdlOptions.enumerations == expected)
    }

    @Test("parses the Langium type modes and the SDF3 label flag")
    func langiumAndSDF3() throws {
        let strict = try MetamodelFormatOptions.parse(["--langium-types", "strict", "--sdf3-labels"])
        let unlabelled = try MetamodelFormatOptions.parse(["--no-sdf3-labels"])
        #expect(strict.ecoreLoadOptions.langiumOptions.typeMode == .strict)
        #expect(strict.ecoreLoadOptions.sdf3Options.useLabels)
        #expect(!unlabelled.ecoreLoadOptions.sdf3Options.useLabels)
        #expect(unlabelled.grammar.explicitSDF3Labels == false)
    }

    @Test("rejects unknown spellings")
    func rejectsUnknown() {
        #expect(throws: (any Error).self) { try GrammarImportOptions.parse(["--asdl-enumerations", "always"]) }
        #expect(throws: (any Error).self) { try GrammarImportOptions.parse(["--langium-types", "loose"]) }
    }

    @Test("combines the KM3 and the grammar options")
    func combination() throws {
        let options = try MetamodelFormatOptions.parse(["--km3-primitives", "declared", "--ns-prefix", "x"])
        #expect(options.ecoreLoadOptions.km3Options == .declaredDataTypes)
        #expect(options.ecoreLoadOptions.asdlOptions.nsPrefix == "x")
    }

    @Test("takes the values of the configuration file, which the command line overrides")
    func precedence() throws {
        let configured = try Self.settings(
            """
            { "package-name": "Configured", "ns-uri": "urn:configured", "ns-prefix": "cfg",
              "asdl-enumerations": "never", "langium-types": "strict", "sdf3-labels": true,
              "km3-primitives": "declared" }
            """)
        let none = try MetamodelFormatOptions.parse([])
        let explicit = try MetamodelFormatOptions.parse([
            "--package-name", "Given", "--asdl-enumerations", "all-nullary", "--langium-types", "normal",
            "--no-sdf3-labels",
        ])
        let fromFile = none.ecoreLoadOptions(settings: configured)
        #expect(fromFile.asdlOptions.packageName == "Configured")
        #expect(fromFile.xtextOptions.nsURI == "urn:configured")
        #expect(fromFile.langiumOptions.nsPrefix == "cfg")
        #expect(fromFile.asdlOptions.enumerations == .never)
        #expect(fromFile.langiumOptions.typeMode == .strict)
        #expect(fromFile.sdf3Options.useLabels)
        #expect(fromFile.km3Options == .declaredDataTypes)
        let overridden = explicit.ecoreLoadOptions(settings: configured)
        #expect(overridden.sdf3Options.packageName == "Given")
        #expect(overridden.sdf3Options.nsURI == "urn:configured")
        #expect(overridden.asdlOptions.enumerations == .allNullarySums)
        #expect(overridden.langiumOptions.typeMode == .normal)
        #expect(!overridden.sdf3Options.useLabels)
        #expect(configured.configuration.packageName == "Configured")
        #expect(configured.configuration.asdlEnumerations == .never)
        #expect(configured.configuration.langiumTypes == .strict)
        #expect(configured.configuration.sdf3Labels == true)
    }

    @Test("rejects values of the wrong kind in the configuration file")
    func invalidConfiguration() {
        let file = URL(fileURLWithPath: "/projects/example/.swift-modelling.json")
        func error(_ text: String) -> ModellingConfigurationError? {
            do {
                _ = try ModellingConfiguration(data: Data(text.utf8), url: file)
                return nil
            } catch {
                return error
            }
        }
        #expect(error(#"{ "package-name": 3 }"#) == .wrongType(key: "package-name", expected: .string, path: file.path))
        #expect(error(#"{ "sdf3-labels": "yes" }"#) == .wrongType(key: "sdf3-labels", expected: .boolean, path: file.path))
        #expect(
            error(#"{ "asdl-enumerations": "always" }"#)
                == .invalidValue("always", key: "asdl-enumerations", accepted: ["all-nullary", "never"], path: file.path))
        #expect(
            error(#"{ "langium-types": "loose" }"#)
                == .invalidValue("loose", key: "langium-types", accepted: ["normal", "strict"], path: file.path))
    }
}
