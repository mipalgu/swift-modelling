//
// SiblingRuleConflictOptionsTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import Foundation
import ModellingCommandLine
import Testing

/// Tests for the option that chooses what a source element that two sub-rules of the same rule
/// both match gives.
@Suite("Sibling rule conflicts option")
struct SiblingRuleConflictOptionsTests {
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

    @Test("names the option and the key, and takes its values from the engine")
    func names() {
        #expect(SiblingRuleConflictOptions.optionName == "sibling-rule-conflicts")
        #expect(SiblingRuleConflictOptions.valueList == "warning|error")
        #expect(ModellingConfiguration.keys.contains(SiblingRuleConflictOptions.optionName))
    }

    @Test("reports a conflict with a warning when neither the command line nor the file chooses", arguments: SemanticsPreset.allCases)
    func warningByDefault(preset: SemanticsPreset) throws {
        let options = try SiblingRuleConflictOptions.parse([])
        #expect(options.explicitConflicts == nil)
        let settings = SemanticsSettings(preset: preset)
        #expect(options.conflicts(settings: settings) == .warning)
        var atlOptions = settings.preset.atlOptions
        options.apply(to: &atlOptions, settings: settings)
        #expect(atlOptions == settings.preset.atlOptions)
    }

    @Test("reads each value from the command line", arguments: ATLSiblingRuleConflicts.allCases)
    func parses(conflicts: ATLSiblingRuleConflicts) throws {
        let options = try SiblingRuleConflictOptions.parse(["--sibling-rule-conflicts", conflicts.rawValue])
        #expect(options.explicitConflicts == conflicts)
        #expect(options.conflicts(settings: SemanticsSettings()) == conflicts)
    }

    @Test("rejects a value that is not one of the engine")
    func rejects() {
        #expect(throws: (any Error).self) {
            try SiblingRuleConflictOptions.parse(["--sibling-rule-conflicts", "ignore"])
        }
    }

    @Test("reads each value from the configuration file", arguments: ATLSiblingRuleConflicts.allCases)
    func readsKey(conflicts: ATLSiblingRuleConflicts) throws {
        let settings = try Self.settings(#"{ "sibling-rule-conflicts": "\#(conflicts.rawValue)" }"#)
        #expect(settings.configuration.siblingRuleConflicts == conflicts)
        #expect(try SiblingRuleConflictOptions.parse([]).conflicts(settings: settings) == conflicts)
    }

    @Test(
        "lets the command line override the key of the file",
        arguments: ATLSiblingRuleConflicts.allCases, ATLSiblingRuleConflicts.allCases)
    func precedence(inFile: ATLSiblingRuleConflicts, onCommandLine: ATLSiblingRuleConflicts) throws {
        let settings = try Self.settings(#"{ "sibling-rule-conflicts": "\#(inFile.rawValue)" }"#)
        let options = try SiblingRuleConflictOptions.parse(["--sibling-rule-conflicts", onCommandLine.rawValue])
        #expect(options.conflicts(settings: settings) == onCommandLine)
    }

    @Test("applies the value of a run and leaves the other behaviours alone", arguments: SemanticsPreset.allCases)
    func applies(preset: SemanticsPreset) throws {
        let settings = try Self.settings(#"{ "sibling-rule-conflicts": "error" }"#, preset: preset)
        var atlOptions = preset.atlOptions
        try SiblingRuleConflictOptions.parse([]).apply(to: &atlOptions, settings: settings)
        #expect(atlOptions.siblingRuleConflicts == .error)
        atlOptions.siblingRuleConflicts = preset.atlOptions.siblingRuleConflicts
        #expect(atlOptions == preset.atlOptions)
    }

    @Test("rejects a value of the key that is not one of the engine, naming the accepted values")
    func invalidKey() {
        #expect(
            Self.error(#"{ "sibling-rule-conflicts": "ignore" }"#)
                == .invalidValue("ignore", key: "sibling-rule-conflicts", accepted: ["warning", "error"], path: Self.file.path))
    }

    @Test("rejects a value of the key that is not a string")
    func wrongTypeKey() {
        #expect(
            Self.error(#"{ "sibling-rule-conflicts": false }"#)
                == .wrongType(key: "sibling-rule-conflicts", expected: .string, path: Self.file.path))
    }

    @Test("describes the option for the discussion of a command")
    func discussion() {
        let text = SiblingRuleConflictOptions.discussion(reader: "the transformation")
        #expect(text.contains("--sibling-rule-conflicts"))
        #expect(text.contains("the transformation"))
        for conflicts in ATLSiblingRuleConflicts.allCases {
            #expect(text.contains(conflicts.rawValue))
        }
    }
}
