//
// AbstractLeafRulesOptionsTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import Foundation
import ModellingCommandLine
import Testing

/// Tests for the option that chooses what a source element gives that an abstract rule matches
/// when no rule extends that abstract rule.
@Suite("Abstract leaf rules option")
struct AbstractLeafRulesOptionsTests {
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

    @Test("the presets differ in the leaf rules, which only legacy gives the ignoring of abstract rules")
    func presets() {
        #expect(SemanticsPreset.standard.atlOptions.abstractLeafRules == .error)
        #expect(SemanticsPreset.legacy.atlOptions.abstractLeafRules == .ignore)
    }

    @Test("names the option and the key, and takes its values from the engine")
    func names() {
        #expect(AbstractLeafRulesOptions.optionName == "abstract-leaf-rules")
        #expect(AbstractLeafRulesOptions.valueList == "error|ignore")
        #expect(ModellingConfiguration.keys.contains(AbstractLeafRulesOptions.optionName))
    }

    @Test("follows the preset when neither the command line nor the file chooses", arguments: SemanticsPreset.allCases)
    func followsPreset(preset: SemanticsPreset) throws {
        let options = try AbstractLeafRulesOptions.parse([])
        #expect(options.explicitLeafRules == nil)
        let settings = SemanticsSettings(preset: preset)
        #expect(options.leafRules(settings: settings) == preset.atlOptions.abstractLeafRules)
        var atlOptions = settings.preset.atlOptions
        options.apply(to: &atlOptions, settings: settings)
        #expect(atlOptions == settings.preset.atlOptions)
    }

    @Test("reads each value from the command line", arguments: ATLAbstractLeafRules.allCases)
    func parses(leafRules: ATLAbstractLeafRules) throws {
        let options = try AbstractLeafRulesOptions.parse(["--abstract-leaf-rules", leafRules.rawValue])
        #expect(options.explicitLeafRules == leafRules)
        #expect(options.leafRules(settings: SemanticsSettings()) == leafRules)
    }

    @Test("rejects a value that is not one of the engine")
    func rejects() {
        #expect(throws: (any Error).self) {
            try AbstractLeafRulesOptions.parse(["--abstract-leaf-rules", "skip"])
        }
    }

    @Test("reads each value from the configuration file", arguments: ATLAbstractLeafRules.allCases)
    func readsKey(leafRules: ATLAbstractLeafRules) throws {
        let settings = try Self.settings(#"{ "abstract-leaf-rules": "\#(leafRules.rawValue)" }"#)
        #expect(settings.configuration.abstractLeafRules == leafRules)
        #expect(try AbstractLeafRulesOptions.parse([]).leafRules(settings: settings) == leafRules)
    }

    @Test(
        "lets the command line override the key of the file",
        arguments: ATLAbstractLeafRules.allCases, ATLAbstractLeafRules.allCases)
    func precedence(inFile: ATLAbstractLeafRules, onCommandLine: ATLAbstractLeafRules) throws {
        let settings = try Self.settings(#"{ "abstract-leaf-rules": "\#(inFile.rawValue)" }"#)
        let options = try AbstractLeafRulesOptions.parse(["--abstract-leaf-rules", onCommandLine.rawValue])
        #expect(options.leafRules(settings: settings) == onCommandLine)
    }

    @Test(
        "lets the key of the file override the preset",
        arguments: SemanticsPreset.allCases, ATLAbstractLeafRules.allCases)
    func fileOverridesPreset(preset: SemanticsPreset, inFile: ATLAbstractLeafRules) throws {
        let settings = try Self.settings(#"{ "abstract-leaf-rules": "\#(inFile.rawValue)" }"#, preset: preset)
        #expect(try AbstractLeafRulesOptions.parse([]).leafRules(settings: settings) == inFile)
    }

    @Test(
        "lets the command line override the preset",
        arguments: SemanticsPreset.allCases, ATLAbstractLeafRules.allCases)
    func commandLineOverridesPreset(preset: SemanticsPreset, onCommandLine: ATLAbstractLeafRules) throws {
        let options = try AbstractLeafRulesOptions.parse(["--abstract-leaf-rules", onCommandLine.rawValue])
        #expect(options.leafRules(settings: SemanticsSettings(preset: preset)) == onCommandLine)
    }

    @Test("applies the value of a run and leaves the other behaviours alone", arguments: SemanticsPreset.allCases)
    func applies(preset: SemanticsPreset) throws {
        let other: ATLAbstractLeafRules = preset.atlOptions.abstractLeafRules == .error ? .ignore : .error
        let settings = try Self.settings(#"{ "abstract-leaf-rules": "\#(other.rawValue)" }"#, preset: preset)
        var atlOptions = preset.atlOptions
        try AbstractLeafRulesOptions.parse([]).apply(to: &atlOptions, settings: settings)
        #expect(atlOptions.abstractLeafRules == other)
        atlOptions.abstractLeafRules = preset.atlOptions.abstractLeafRules
        #expect(atlOptions == preset.atlOptions)
    }

    @Test("rejects a value of the key that is not one of the engine, naming the accepted values")
    func invalidKey() {
        #expect(
            Self.error(#"{ "abstract-leaf-rules": "skip" }"#)
                == .invalidValue(
                    "skip", key: "abstract-leaf-rules",
                    accepted: ATLAbstractLeafRules.allCases.map(\.rawValue), path: Self.file.path))
    }

    @Test("rejects a value of the key that is not a string")
    func wrongTypeKey() {
        #expect(
            Self.error(#"{ "abstract-leaf-rules": false }"#)
                == .wrongType(key: "abstract-leaf-rules", expected: .string, path: Self.file.path))
    }

    @Test("describes the option for the discussion of a command")
    func discussion() {
        let text = AbstractLeafRulesOptions.discussion(reader: "the transformation")
        #expect(text.contains("--abstract-leaf-rules"))
        #expect(text.contains("the transformation"))
        for leafRules in ATLAbstractLeafRules.allCases {
            #expect(text.contains(leafRules.rawValue))
        }
    }
}
