//
// AbstractRuleMatchingOptionsTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import Foundation
import ModellingCommandLine
import Testing

/// Tests for the option that chooses what a source element gives that an abstract rule matches
/// but none of the rules extending it match.
@Suite("Abstract rule matching option")
struct AbstractRuleMatchingOptionsTests {
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

    @Test("the presets differ in the matching, which only legacy gives the skipping of abstract rules")
    func presets() {
        #expect(SemanticsPreset.standard.atlOptions.abstractRuleMatching == .eclipse)
        #expect(SemanticsPreset.legacy.atlOptions.abstractRuleMatching == .skip)
    }

    @Test("names the option and the key, and takes its values from the engine")
    func names() {
        #expect(AbstractRuleMatchingOptions.optionName == "abstract-rule-matching")
        #expect(AbstractRuleMatchingOptions.valueList == "eclipse|skip")
        #expect(ModellingConfiguration.keys.contains(AbstractRuleMatchingOptions.optionName))
    }

    @Test("follows the preset when neither the command line nor the file chooses", arguments: SemanticsPreset.allCases)
    func followsPreset(preset: SemanticsPreset) throws {
        let options = try AbstractRuleMatchingOptions.parse([])
        #expect(options.explicitMatching == nil)
        let settings = SemanticsSettings(preset: preset)
        #expect(options.matching(settings: settings) == preset.atlOptions.abstractRuleMatching)
        var atlOptions = settings.preset.atlOptions
        options.apply(to: &atlOptions, settings: settings)
        #expect(atlOptions == settings.preset.atlOptions)
    }

    @Test("reads each value from the command line", arguments: ATLAbstractRuleMatching.allCases)
    func parses(matching: ATLAbstractRuleMatching) throws {
        let options = try AbstractRuleMatchingOptions.parse(["--abstract-rule-matching", matching.rawValue])
        #expect(options.explicitMatching == matching)
        #expect(options.matching(settings: SemanticsSettings()) == matching)
    }

    @Test("rejects a value that is not one of the engine")
    func rejects() {
        #expect(throws: (any Error).self) {
            try AbstractRuleMatchingOptions.parse(["--abstract-rule-matching", "ignore"])
        }
    }

    @Test("reads each value from the configuration file", arguments: ATLAbstractRuleMatching.allCases)
    func readsKey(matching: ATLAbstractRuleMatching) throws {
        let settings = try Self.settings(#"{ "abstract-rule-matching": "\#(matching.rawValue)" }"#)
        #expect(settings.configuration.abstractRuleMatching == matching)
        #expect(try AbstractRuleMatchingOptions.parse([]).matching(settings: settings) == matching)
    }

    @Test(
        "lets the command line override the key of the file",
        arguments: ATLAbstractRuleMatching.allCases, ATLAbstractRuleMatching.allCases)
    func precedence(inFile: ATLAbstractRuleMatching, onCommandLine: ATLAbstractRuleMatching) throws {
        let settings = try Self.settings(#"{ "abstract-rule-matching": "\#(inFile.rawValue)" }"#)
        let options = try AbstractRuleMatchingOptions.parse(["--abstract-rule-matching", onCommandLine.rawValue])
        #expect(options.matching(settings: settings) == onCommandLine)
    }

    @Test(
        "lets the key of the file override the preset",
        arguments: SemanticsPreset.allCases, ATLAbstractRuleMatching.allCases)
    func fileOverridesPreset(preset: SemanticsPreset, inFile: ATLAbstractRuleMatching) throws {
        let settings = try Self.settings(#"{ "abstract-rule-matching": "\#(inFile.rawValue)" }"#, preset: preset)
        #expect(try AbstractRuleMatchingOptions.parse([]).matching(settings: settings) == inFile)
    }

    @Test(
        "lets the command line override the preset",
        arguments: SemanticsPreset.allCases, ATLAbstractRuleMatching.allCases)
    func commandLineOverridesPreset(preset: SemanticsPreset, onCommandLine: ATLAbstractRuleMatching) throws {
        let options = try AbstractRuleMatchingOptions.parse(["--abstract-rule-matching", onCommandLine.rawValue])
        #expect(options.matching(settings: SemanticsSettings(preset: preset)) == onCommandLine)
    }

    @Test("applies the value of a run and leaves the other behaviours alone", arguments: SemanticsPreset.allCases)
    func applies(preset: SemanticsPreset) throws {
        let other: ATLAbstractRuleMatching = preset.atlOptions.abstractRuleMatching == .eclipse ? .skip : .eclipse
        let settings = try Self.settings(#"{ "abstract-rule-matching": "\#(other.rawValue)" }"#, preset: preset)
        var atlOptions = preset.atlOptions
        try AbstractRuleMatchingOptions.parse([]).apply(to: &atlOptions, settings: settings)
        #expect(atlOptions.abstractRuleMatching == other)
        atlOptions.abstractRuleMatching = preset.atlOptions.abstractRuleMatching
        #expect(atlOptions == preset.atlOptions)
    }

    @Test("rejects a value of the key that is not one of the engine, naming the accepted values")
    func invalidKey() {
        #expect(
            Self.error(#"{ "abstract-rule-matching": "ignore" }"#)
                == .invalidValue(
                    "ignore", key: "abstract-rule-matching",
                    accepted: ATLAbstractRuleMatching.allCases.map(\.rawValue), path: Self.file.path))
    }

    @Test("rejects a value of the key that is not a string")
    func wrongTypeKey() {
        #expect(
            Self.error(#"{ "abstract-rule-matching": false }"#)
                == .wrongType(key: "abstract-rule-matching", expected: .string, path: Self.file.path))
    }

    @Test("describes the option for the discussion of a command")
    func discussion() {
        let text = AbstractRuleMatchingOptions.discussion(reader: "the transformation")
        #expect(text.contains("--abstract-rule-matching"))
        #expect(text.contains("the transformation"))
        for matching in ATLAbstractRuleMatching.allCases {
            #expect(text.contains(matching.rawValue))
        }
    }
}
