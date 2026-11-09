//
// ConfigurationFileOptionsTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingCommandLine
import Testing

/// Tests for `--config` and `--no-config` without a preset, and for the metamodel load options
/// that the configuration file gives.
@Suite("Configuration file options")
struct ConfigurationFileOptionsTests {
    /// The settings whose configuration file holds a text.
    ///
    /// - Parameter text: The contents of the file.
    /// - Returns: The settings.
    /// - Throws: ``ModellingConfigurationError`` if the text is not a valid configuration.
    static func settings(_ text: String) throws -> SemanticsSettings {
        SemanticsSettings(
            configuration: try ModellingConfiguration(
                data: Data(text.utf8), url: URL(fileURLWithPath: "/projects/example/.swift-modelling.json")))
    }

    // MARK: - Options

    @Test("names the options as the semantics options name them")
    func names() throws {
        let explicit = try ConfigurationFileOptions.parse(["--\(SemanticsOptions.OptionName.config)", "a.json"])
        let ignored = try ConfigurationFileOptions.parse(["--\(SemanticsOptions.OptionName.noConfig)"])
        let none = try ConfigurationFileOptions.parse([])

        #expect(explicit.configurationPath == "a.json")
        #expect(!explicit.ignoresConfiguration)
        #expect(ignored.configurationPath == nil)
        #expect(ignored.ignoresConfiguration)
        #expect(none.configurationPath == nil)
        #expect(!none.ignoresConfiguration)
    }

    @Test("rejects --config together with --no-config")
    func conflict() {
        #expect(throws: (any Error).self) {
            try ConfigurationFileOptions.parse(["--config", "a.json", "--no-config"])
        }
        #expect(throws: (any Error).self) {
            try SemanticsOptions.parse(["--config", "a.json", "--no-config"])
        }
    }

    @Test("rejects the preset and the container scope, which it does not offer")
    func noPreset() {
        #expect(throws: (any Error).self) { try ConfigurationFileOptions.parse(["--semantics", "legacy"]) }
        #expect(throws: (any Error).self) {
            try ConfigurationFileOptions.parse(["--container-scope", "this-resource"])
        }
    }

    @Test("describes the options as the semantics options describe them")
    func help() {
        let help = ConfigurationFileOptions.helpMessage()
        for text in ["--config <file>", "--no-config", ModellingConfiguration.fileName] {
            #expect(help.contains(text), "\(text) is missing from: \(help)")
        }
    }

    // MARK: - Reading the file

    @Test("finds the configuration file from the current directory")
    func discovers() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()
        try scratch.writeConfiguration(#"{ "encoding": "latin1" }"#)
        let nested = try scratch.directory("work/nested")

        let configuration = try ConfigurationFileOptions.parse([]).configuration(currentDirectory: nested)

        #expect(configuration.encoding == .isoLatin1)
        #expect(samePath(configuration.url, scratch.url.appendingPathComponent(ModellingConfiguration.fileName)))
    }

    @Test("reads exactly the file that --config names, relative to the current directory")
    func explicitFile() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()
        try scratch.writeConfiguration(#"{ "encoding": "latin1" }"#)
        try scratch.write(#"{ "km3-primitives": "declared" }"#, to: "settings/custom.json")

        let configuration = try ConfigurationFileOptions.parse(["--config", "settings/custom.json"])
            .configuration(currentDirectory: scratch.url)

        #expect(configuration.encoding == nil)
        #expect(configuration.km3PrimitiveTypes == .declared)
    }

    @Test("reads no file with --no-config, and none where there is none")
    func ignores() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()
        let empty = try ConfigurationFileOptions.parse([]).configuration(currentDirectory: scratch.url)
        try scratch.writeConfiguration(#"{ "encoding": "latin1" }"#)

        let ignored = try ConfigurationFileOptions.parse(["--no-config"]).configuration(currentDirectory: scratch.url)

        #expect(empty == ModellingConfiguration())
        #expect(ignored == ModellingConfiguration())
    }

    @Test("gives settings with the default preset and the configuration of the file")
    func settingsOfRun() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()
        try scratch.writeConfiguration(#"{ "semantics": "legacy", "km3-primitives": "declared" }"#)

        let settings = try ConfigurationFileOptions.parse([]).settings(currentDirectory: scratch.url)

        #expect(settings.preset == SemanticsSettings.defaultPreset)
        #expect(settings.configuration.km3PrimitiveTypes == .declared)
    }

    @Test("reports an invalid value of the file, naming the file, the key and the value")
    func invalidValue() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()
        let file = try scratch.writeConfiguration(#"{ "encoding": "klingon" }"#)
        let options = try ConfigurationFileOptions.parse([])

        let error = configurationError { () throws(ModellingConfigurationError) in
            try options.configuration(currentDirectory: scratch.url)
        }

        guard case .invalidValue(let value, let key, _, let path) = error else {
            Issue.record("expected an invalid value, got \(String(describing: error))")
            return
        }
        #expect(value == "klingon")
        #expect(key == SourceEncodingOptions.optionName)
        #expect(samePath(URL(fileURLWithPath: path), file))
    }

    @Test("reads the same file as the semantics options")
    func sameAsSemanticsOptions() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()
        try scratch.writeConfiguration(#"{ "encoding": "latin1", "ns-prefix": "lib" }"#)
        try scratch.write(#"{ "ns-uri": "http://example.org/lib" }"#, to: "other.json")

        for arguments in [[], ["--no-config"], ["--config", "other.json"]] {
            let plain = try ConfigurationFileOptions.parse(arguments).configuration(currentDirectory: scratch.url)
            let semantics = try SemanticsOptions.parse(arguments).configuration(currentDirectory: scratch.url)
            #expect(plain == semantics, "\(arguments)")
        }
    }

    // MARK: - Metamodel load options

    @Test("loads metamodels as the command line alone does when the file sets nothing")
    func unchangedWithoutFile() throws {
        for arguments in [[], ["--km3-primitives", "declared", "--ns-uri", "http://example.org/x", "--sdf3-labels"]] {
            let format = try MetamodelFormatOptions.parse(arguments)
            for encodingArguments in [[], ["--encoding", "latin1"]] {
                let encoding = try SourceEncodingOptions.parse(encodingArguments)
                let configured = format.ecoreLoadOptions(settings: SemanticsSettings(), encodingOptions: encoding)
                let commandLine = format.ecoreLoadOptions(encoding: encoding.explicitEncoding)
                #expect(configured == commandLine, "\(arguments) \(encodingArguments)")
            }
        }
    }

    @Test("takes the encoding, KM3 and grammar options of the file")
    func fromFile() throws {
        let settings = try Self.settings(
            """
            { "encoding": "latin1", "km3-primitives": "declared", "package-name": "calc",
              "ns-uri": "http://example.org/calc", "ns-prefix": "c", "asdl-enumerations": "never",
              "langium-types": "strict", "sdf3-labels": true }
            """)

        let options = try MetamodelFormatOptions.parse([])
            .ecoreLoadOptions(settings: settings, encodingOptions: try SourceEncodingOptions.parse([]))

        #expect(options.textEncoding == .isoLatin1)
        #expect(options.km3Options == .declaredDataTypes)
        #expect(options.asdlOptions.packageName == "calc")
        #expect(options.asdlOptions.nsURI == "http://example.org/calc")
        #expect(options.asdlOptions.nsPrefix == "c")
        #expect(options.asdlOptions.enumerations == .never)
        #expect(options.langiumOptions.typeMode == .strict)
        #expect(options.sdf3Options.useLabels)
    }

    @Test("lets the command line override the encoding, KM3 and grammar options of the file")
    func commandLineOverrides() throws {
        let settings = try Self.settings(
            """
            { "encoding": "latin1", "km3-primitives": "declared", "ns-uri": "http://example.org/file",
              "asdl-enumerations": "never", "sdf3-labels": true }
            """)
        let format = try MetamodelFormatOptions.parse([
            "--km3-primitives", "ecore", "--ns-uri", "http://example.org/cli", "--asdl-enumerations", "all-nullary",
            "--no-sdf3-labels",
        ])

        let options = format.ecoreLoadOptions(
            settings: settings, encodingOptions: try SourceEncodingOptions.parse(["--encoding", "UTF-8"]))

        #expect(options.textEncoding == .utf8)
        #expect(options.km3Options == .standard)
        #expect(options.asdlOptions.nsURI == "http://example.org/cli")
        #expect(options.asdlOptions.enumerations == .allNullarySums)
        #expect(!options.sdf3Options.useLabels)
    }

    // MARK: - Level crossing

    @Test("reads each level crossing mode from the file", arguments: LevelCrossingMode.allCases)
    func levelCrossingKey(mode: LevelCrossingMode) throws {
        let settings = try Self.settings(#"{ "level-crossing": "\#(mode.rawValue)" }"#)
        #expect(settings.configuration.levelCrossing == mode)
        #expect(try LevelCrossingOptions.parse([]).mode(settings: settings) == mode)
    }

    @Test("takes the default level crossing without the key, and lets the command line override the file")
    func levelCrossingPrecedence() throws {
        let configured = try Self.settings(#"{ "level-crossing": "strict" }"#)
        let none = try LevelCrossingOptions.parse([])
        let explicit = try LevelCrossingOptions.parse(["--level-crossing", "non-strict"])

        #expect(none.mode(settings: SemanticsSettings()) == LevelCrossingOptions.defaultMode)
        #expect(none.mode == LevelCrossingOptions.defaultMode)
        #expect(explicit.mode(settings: configured) == .nonStrict)
        #expect(explicit.mode == .nonStrict)
    }

    @Test("rejects a level crossing that is not a mode, naming the accepted modes")
    func levelCrossingInvalid() {
        let file = URL(fileURLWithPath: "/projects/example/.swift-modelling.json")
        let error = configurationError { () throws(ModellingConfigurationError) in
            try ModellingConfiguration(data: Data(#"{ "level-crossing": "loose" }"#.utf8), url: file)
        }
        #expect(
            error == .invalidValue(
                "loose", key: "level-crossing", accepted: LevelCrossingMode.allCases.map(\.rawValue), path: file.path))
    }

    // MARK: - Complete OCL documents

    @Test("resolves the Complete OCL documents of the file against its directory, keeping absolute paths")
    func oclKey() throws {
        let settings = try Self.settings(#"{ "ocl": ["rules/shop.ocl", "/shared/base.ocl", "../common.ocl"] }"#)
        #expect(
            settings.configuration.completeOCLDocuments == [
                "/projects/example/rules/shop.ocl", "/shared/base.ocl", "/projects/common.ocl",
            ])
    }

    @Test("takes the Complete OCL documents of the file unless the command line names any")
    func oclPrecedence() throws {
        let configured = try Self.settings(#"{ "ocl": ["shop.ocl"] }"#)
        let none = try CompleteOCLOptions.parse([])
        let explicit = try CompleteOCLOptions.parse(["--ocl", "a.ocl", "--ocl", "b.ocl"])

        #expect(none.documents(settings: configured) == ["/projects/example/shop.ocl"])
        #expect(none.documents(settings: SemanticsSettings()) == [])
        #expect(explicit.documents(settings: configured) == ["a.ocl", "b.ocl"])
        #expect(try Self.settings(#"{ "ocl": [] }"#).configuration.completeOCLDocuments == [])
    }

    @Test(
        "rejects Complete OCL documents that are not a list of strings, naming the key",
        arguments: [#"{ "ocl": "shop.ocl" }"#, #"{ "ocl": [1] }"#, #"{ "ocl": ["a.ocl", null] }"#, #"{ "ocl": {} }"#])
    func oclWrongType(text: String) {
        let file = URL(fileURLWithPath: "/projects/example/.swift-modelling.json")
        let error = configurationError { () throws(ModellingConfigurationError) in
            try ModellingConfiguration(data: Data(text.utf8), url: file)
        }
        #expect(error == .wrongType(key: "ocl", expected: .stringList, path: file.path))
        #expect(error?.description.contains("a list of strings") == true)
    }

    // MARK: - Directories of Complete OCL documents

    @Test("replaces a directory by the documents directly in it, sorted by name, keeping files and their order")
    func oclDirectories() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        let rules = try scratch.directory("rules")
        for name in ["b.ocl", "a.OCL", "notes.txt", "nested/c.ocl"] { try scratch.write("", to: "rules/\(name)") }
        try scratch.directory("rules/folder.ocl")
        let single = try scratch.write("", to: "single.ocl").path
        var warnings: [String] = []

        let options = try CompleteOCLOptions.parse(["--ocl", single, "--ocl", rules.path, "--ocl", "missing.ocl"])
        let documents = options.documents(settings: SemanticsSettings()) { warnings.append($0) }

        #expect(
            documents == [
                single, rules.appendingPathComponent("a.OCL").path, rules.appendingPathComponent("b.ocl").path,
                "missing.ocl",
            ])
        #expect(warnings.isEmpty)
    }

    @Test("expands the directories of the configuration file")
    func oclDirectoriesFromFile() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write("", to: "rules/z.ocl")
        try scratch.write("", to: "rules/m.ocl")
        try scratch.write("", to: "extra.ocl")
        let file = try scratch.writeConfiguration(#"{ "ocl": ["extra.ocl", "rules"] }"#)
        let settings = SemanticsSettings(configuration: try ModellingConfiguration(contentsOf: file))

        let documents = try CompleteOCLOptions.parse([]).documents(settings: settings) { _ in }

        let root = scratch.url.standardizedFileURL
        #expect(
            documents == [
                root.appendingPathComponent("extra.ocl").path, root.appendingPathComponent("rules/m.ocl").path,
                root.appendingPathComponent("rules/z.ocl").path,
            ])
    }

    @Test("warns about a directory without documents, which contributes none")
    func oclEmptyDirectory() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        let empty = try scratch.directory("empty")
        try scratch.write("", to: "empty/readme.txt")
        var warnings: [String] = []

        let documents = try CompleteOCLOptions.parse(["--ocl", empty.path])
            .documents(settings: SemanticsSettings()) { warnings.append($0) }

        #expect(documents.isEmpty)
        #expect(warnings.count == 1)
        #expect(warnings.first?.hasPrefix("warning: \(empty.path): ") == true, "\(warnings)")
    }
}
