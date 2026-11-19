//
// SubRulePrecedenceOptionsTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import Foundation
import ModellingCommandLine
import Testing

/// Tests for the option that chooses which rule transforms a source element that a rule and a
/// rule extending it both match.
@Suite("Sub-rule precedence option")
struct SubRulePrecedenceOptionsTests {
    /// The location that the parsed text pretends to come from.
    private static let file = URL(fileURLWithPath: "/projects/example/.swift-modelling.json")

    /// The settings whose configuration file holds a text.
    ///
    /// - Parameters:
    ///   - text: The contents of the file.
    ///   - preset: The preset of the settings (default: the default preset).
    /// - Returns: The settings.
    /// - Throws: ``ModellingConfigurationError`` if the text is not a valid configuration.
    private static func settings(
        _ text: String, preset: SemanticsPreset = SemanticsSettings.defaultPreset
    ) throws -> SemanticsSettings {
        SemanticsSettings(preset: preset, configuration: try ModellingConfiguration(data: Data(text.utf8), url: file))
    }

    /// The error that reading a text throws, if any.
    ///
    /// - Parameter text: The contents of the file.
    /// - Returns: The error, or `nil` if the text is a valid configuration.
    private static func error(_ text: String) -> ModellingConfigurationError? {
        configurationError { () throws(ModellingConfigurationError) in
            try ModellingConfiguration(data: Data(text.utf8), url: file)
        }
    }

    @Test("the presets differ in the precedence, which only legacy gives the extending rule")
    func presets() {
        #expect(SemanticsPreset.standard.atlOptions.subRulePrecedence == .eclipse)
        #expect(SemanticsPreset.legacy.atlOptions.subRulePrecedence == .extendingRule)
    }

    @Test("names the option and the key, and takes its values from the engine")
    func names() {
        #expect(SubRulePrecedenceOptions.optionName == "sub-rule-precedence")
        #expect(SubRulePrecedenceOptions.valueList == "eclipse|extending-rule")
        #expect(ModellingConfiguration.keys.contains(SubRulePrecedenceOptions.optionName))
    }

    @Test("follows the preset when neither the command line nor the file chooses", arguments: SemanticsPreset.allCases)
    func followsPreset(preset: SemanticsPreset) throws {
        let options = try SubRulePrecedenceOptions.parse([])
        #expect(options.explicitPrecedence == nil)
        let settings = SemanticsSettings(preset: preset)
        #expect(options.precedence(settings: settings) == preset.atlOptions.subRulePrecedence)
        var atlOptions = settings.preset.atlOptions
        options.apply(to: &atlOptions, settings: settings)
        #expect(atlOptions == settings.preset.atlOptions)
    }

    @Test("reads each value from the command line", arguments: ATLSubRulePrecedence.allCases)
    func parses(precedence: ATLSubRulePrecedence) throws {
        let options = try SubRulePrecedenceOptions.parse(["--sub-rule-precedence", precedence.rawValue])
        #expect(options.explicitPrecedence == precedence)
        #expect(options.precedence(settings: SemanticsSettings()) == precedence)
    }

    @Test("rejects a value that is not one of the engine")
    func rejects() {
        #expect(throws: (any Error).self) {
            try SubRulePrecedenceOptions.parse(["--sub-rule-precedence", "overriding"])
        }
    }

    @Test("reads each value from the configuration file", arguments: ATLSubRulePrecedence.allCases)
    func readsKey(precedence: ATLSubRulePrecedence) throws {
        let settings = try Self.settings(#"{ "sub-rule-precedence": "\#(precedence.rawValue)" }"#)
        #expect(settings.configuration.subRulePrecedence == precedence)
        #expect(try SubRulePrecedenceOptions.parse([]).precedence(settings: settings) == precedence)
    }

    @Test(
        "lets the command line override the key of the file",
        arguments: ATLSubRulePrecedence.allCases, ATLSubRulePrecedence.allCases)
    func precedence(inFile: ATLSubRulePrecedence, onCommandLine: ATLSubRulePrecedence) throws {
        let settings = try Self.settings(#"{ "sub-rule-precedence": "\#(inFile.rawValue)" }"#)
        let options = try SubRulePrecedenceOptions.parse(["--sub-rule-precedence", onCommandLine.rawValue])
        #expect(options.precedence(settings: settings) == onCommandLine)
    }

    @Test("applies the value of a run and leaves the other behaviours alone", arguments: SemanticsPreset.allCases)
    func applies(preset: SemanticsPreset) throws {
        let other: ATLSubRulePrecedence = preset.atlOptions.subRulePrecedence == .eclipse ? .extendingRule : .eclipse
        let settings = try Self.settings(#"{ "sub-rule-precedence": "\#(other.rawValue)" }"#, preset: preset)
        var atlOptions = preset.atlOptions
        try SubRulePrecedenceOptions.parse([]).apply(to: &atlOptions, settings: settings)
        #expect(atlOptions.subRulePrecedence == other)
        atlOptions.subRulePrecedence = preset.atlOptions.subRulePrecedence
        #expect(atlOptions == preset.atlOptions)
    }

    @Test("rejects a value of the key that is not one of the engine, naming the accepted values")
    func invalidKey() {
        #expect(
            Self.error(#"{ "sub-rule-precedence": "overriding" }"#)
                == .invalidValue("overriding", key: "sub-rule-precedence", accepted: ["eclipse", "extending-rule"], path: Self.file.path))
    }

    @Test("rejects a value of the key that is not a string")
    func wrongTypeKey() {
        #expect(
            Self.error(#"{ "sub-rule-precedence": false }"#)
                == .wrongType(key: "sub-rule-precedence", expected: .string, path: Self.file.path))
    }

    @Test("describes the option for the discussion of a command")
    func discussion() {
        let text = SubRulePrecedenceOptions.discussion(reader: "the transformation")
        #expect(text.contains("--sub-rule-precedence"))
        #expect(text.contains("the transformation"))
        for precedence in ATLSubRulePrecedence.allCases {
            #expect(text.contains(precedence.rawValue))
        }
    }
}
