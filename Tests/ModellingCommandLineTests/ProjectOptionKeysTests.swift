//
// ProjectOptionKeysTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import ModellingCommandLine
import ModellingGenerators
import Testing

/// Tests for the configuration keys of the project-wide options: the reference style, the code
/// style, the generator model settings, the strictness of validation and the matching of graph
/// transformation rules.
@Suite("Configuration keys of project-wide options")
struct ProjectOptionKeysTests {
    /// The location that the parsed text pretends to come from.
    static let file = URL(fileURLWithPath: "/projects/example/.swift-modelling.json")

    /// Reads a configuration from text.
    ///
    /// - Parameter text: The contents of the file.
    /// - Returns: The configuration.
    /// - Throws: ``ModellingConfigurationError`` if the text is not a valid configuration.
    static func configuration(_ text: String) throws(ModellingConfigurationError) -> ModellingConfiguration {
        try ModellingConfiguration(data: Data(text.utf8), url: file)
    }

    /// The settings whose configuration file holds a text.
    ///
    /// - Parameter text: The contents of the file.
    /// - Returns: The settings.
    /// - Throws: ``ModellingConfigurationError`` if the text is not a valid configuration.
    static func settings(_ text: String) throws -> SemanticsSettings {
        SemanticsSettings(configuration: try configuration(text))
    }

    /// The error that reading a text throws, if any.
    ///
    /// - Parameter text: The contents of the file.
    /// - Returns: The error, or `nil` if the text is a valid configuration.
    static func error(_ text: String) -> ModellingConfigurationError? {
        configurationError { () throws(ModellingConfigurationError) in try configuration(text) }
    }

    // MARK: - Names and values

    @Test("names each key after its option")
    func names() {
        #expect(ReferenceStyleOptions.optionName == "reference-style")
        #expect(CodeStyleOptions.optionName == "code-style")
        #expect(GenModelDefaultsOptions.OptionName.defaults == "defaults")
        #expect(GenModelDefaultsOptions.OptionName.rootExtendsClass == "root-extends-class")
        #expect(GenModelDefaultsOptions.OptionName.operationReflection == "operation-reflection")
        #expect(GenModelDefaultsOptions.OptionName.importOrganizing == "import-organizing")
        #expect(GenModelDefaultsOptions.OptionName.basePackage == "base-package")
        #expect(GenModelDefaultsOptions.OptionName.prefix == "prefix")
        #expect(GenModelDefaultsOptions.OptionName.jdkLevel == "jdk-level")
        #expect(ValidationOptionName.strict == "strict")
        #expect(ValidationOptionName.requireExplicitValues == "require-explicit-values")
        #expect(MatchingOptionName.checkDangling == "check-dangling")
        #expect(MatchingOptionName.injective == "injective")
        for key in [
            "reference-style", "code-style", "defaults", "root-extends-class", "operation-reflection",
            "import-organizing", "base-package", "prefix", "jdk-level", "strict", "require-explicit-values",
            "check-dangling", "injective",
        ] {
            #expect(ModellingConfiguration.keys.contains(key), "\(key)")
        }
    }

    @Test("reads every project-wide key")
    func everyKey() throws {
        let configuration = try Self.configuration(
            """
            {
              "reference-style": "plain", "code-style": "emf", "defaults": "wizard",
              "root-extends-class": "org.example.Base", "operation-reflection": false,
              "import-organizing": true, "base-package": "org.example", "prefix": ["Lib", "books=Book"],
              "jdk-level": "21.0", "strict": true, "require-explicit-values": false,
              "check-dangling": false, "injective": true
            }
            """)
        #expect(configuration.referenceStyle == .plain)
        #expect(configuration.codeStyle == "emf")
        #expect(configuration.genModelDefaults == .wizard)
        #expect(configuration.rootExtendsClass == "org.example.Base")
        #expect(configuration.operationReflection == false)
        #expect(configuration.importOrganizing == true)
        #expect(configuration.basePackage == "org.example")
        #expect(configuration.prefixes == ["Lib", "books=Book"])
        #expect(configuration.complianceLevel == "21.0")
        #expect(configuration.strict == true)
        #expect(configuration.requiresExplicitValues == false)
        #expect(configuration.checksDangling == false)
        #expect(configuration.injectiveMatching == true)
    }

    @Test("leaves every project-wide setting open without its key")
    func absent() throws {
        let configuration = try Self.configuration("{}")
        #expect(configuration.referenceStyle == nil)
        #expect(configuration.codeStyle == nil)
        #expect(configuration.genModelDefaults == nil)
        #expect(configuration.prefixes == nil)
        #expect(configuration.strict == nil)
        #expect(configuration.checksDangling == nil)
        #expect(configuration.injectiveMatching == nil)
    }

    @Test(
        "rejects a value that is not a spelling of its option, naming the accepted values",
        arguments: [
            (#"{ "reference-style": "fancy" }"#, "reference-style", "fancy", ["encoded", "plain"]),
            (#"{ "defaults": "eclipse" }"#, "defaults", "eclipse", ["headless", "wizard"]),
        ])
    func invalidValue(text: String, key: String, value: String, accepted: [String]) {
        #expect(Self.error(text) == .invalidValue(value, key: key, accepted: accepted, path: Self.file.path))
    }

    @Test(
        "rejects a value of the wrong type, naming the key and the expected kind",
        arguments: [
            (#"{ "strict": "yes" }"#, "strict", ModellingConfiguration.ValueKind.boolean),
            (#"{ "require-explicit-values": 1 }"#, "require-explicit-values", .boolean),
            (#"{ "check-dangling": "true" }"#, "check-dangling", .boolean),
            (#"{ "injective": null }"#, "injective", .boolean),
            (#"{ "operation-reflection": "on" }"#, "operation-reflection", .boolean),
            (#"{ "import-organizing": 0 }"#, "import-organizing", .boolean),
            (#"{ "prefix": "Lib" }"#, "prefix", .stringList),
            (#"{ "prefix": ["Lib", 2] }"#, "prefix", .stringList),
            (#"{ "code-style": true }"#, "code-style", .string),
            (#"{ "base-package": [] }"#, "base-package", .string),
            (#"{ "jdk-level": 17 }"#, "jdk-level", .string),
            (#"{ "root-extends-class": false }"#, "root-extends-class", .string),
        ])
    func wrongType(text: String, key: String, kind: ModellingConfiguration.ValueKind) {
        #expect(Self.error(text) == .wrongType(key: key, expected: kind, path: Self.file.path))
    }

    // MARK: - Reference style

    @Test("writes as without the option when neither the command line nor the file names a style")
    func referenceStyleDefault() throws {
        let options = try ReferenceStyleOptions.parse([])
        #expect(options.serializationOptions(settings: SemanticsSettings()) == options.serializationOptions)
        #expect(options.serializationOptions == .legacy)
        #expect(options.referenceStyle == .encoded)
    }

    @Test("takes the reference style of the file, which the command line overrides")
    func referenceStylePrecedence() throws {
        let configured = try Self.settings(#"{ "reference-style": "plain" }"#)
        let plain = try ReferenceStyleOptions.parse(["--reference-style", "plain"])
        let encoded = try ReferenceStyleOptions.parse(["--reference-style", "encoded"])

        #expect(try ReferenceStyleOptions.parse([]).serializationOptions(settings: configured) == plain.serializationOptions)
        #expect(encoded.serializationOptions(settings: configured) == .legacy)
    }

    // MARK: - Code style

    @Test("takes the code style of the file, which the command line overrides")
    func codeStylePrecedence() throws {
        let configured = try Self.settings(#"{ "code-style": "emf" }"#)
        let none = try CodeStyleOptions.parse([])
        let explicit = try CodeStyleOptions.parse(["--code-style", "eclipse"])

        #expect(none.codeStyle(settings: SemanticsSettings()) == nil)
        #expect(none.codeStyle(settings: configured) == "emf")
        #expect(explicit.codeStyle(settings: configured) == "eclipse")
        var options = GenerationOptions(mtlOptions: .standard)
        none.apply(to: &options, settings: configured)
        #expect(options.codeStyle == "emf")
    }

    @Test("marks a code style of the file as configured, and one of the command line as explicit")
    func codeStyleSource() throws {
        let configured = try Self.settings(#"{ "code-style": "emf" }"#)
        let none = try CodeStyleOptions.parse([])
        let explicit = try CodeStyleOptions.parse(["--code-style", "eclipse"])

        #expect(!none.codeStyleIsConfigured(settings: SemanticsSettings()))
        #expect(none.codeStyleIsConfigured(settings: configured))
        #expect(!explicit.codeStyleIsConfigured(settings: configured))
        #expect(!explicit.codeStyleIsConfigured(settings: SemanticsSettings()))

        var fromFile = GenerationOptions(mtlOptions: .standard)
        var fromCommandLine = GenerationOptions(mtlOptions: .standard)
        var unset = GenerationOptions(mtlOptions: .standard)
        none.apply(to: &fromFile, settings: configured)
        explicit.apply(to: &fromCommandLine, settings: configured)
        none.apply(to: &unset, settings: SemanticsSettings())

        #expect(fromFile.codeStyleIsConfigured)
        #expect(fromCommandLine.codeStyle == "eclipse")
        #expect(!fromCommandLine.codeStyleIsConfigured)
        #expect(unset.codeStyle == nil)
        #expect(!unset.codeStyleIsConfigured)
    }

    // MARK: - Generator model settings

    @Test("applies the generator model settings of the file, which the command line overrides")
    func genModelDefaultsPrecedence() throws {
        let configured = try Self.settings(
            """
            { "defaults": "wizard", "root-extends-class": "org.example.Base", "operation-reflection": false,
              "import-organizing": false }
            """)
        let explicit = try GenModelDefaultsOptions.parse([
            "--defaults", "headless", "--root-extends-class", "org.example.Other", "--operation-reflection",
        ])
        var fromFile = GenModelImportOptions(atlOptions: .standard)
        var overridden = GenModelImportOptions(atlOptions: .standard)

        try GenModelDefaultsOptions.parse([]).apply(to: &fromFile, settings: configured)
        explicit.apply(to: &overridden, settings: configured)

        #expect(fromFile.defaults == .wizard)
        #expect(fromFile.rootExtendsClass == "org.example.Base")
        #expect(fromFile.operationReflection == false)
        #expect(fromFile.importOrganizing == false)
        #expect(overridden.defaults == .headless)
        #expect(overridden.rootExtendsClass == "org.example.Other")
        #expect(overridden.operationReflection == true)
        #expect(overridden.importOrganizing == false)
    }

    @Test("leaves the import options unchanged without the command line or the file")
    func genModelDefaultsUnchanged() throws {
        var plain = GenModelImportOptions(atlOptions: .standard)
        var configured = GenModelImportOptions(atlOptions: .standard)
        let options = try GenModelDefaultsOptions.parse([])

        options.apply(to: &plain)
        options.apply(to: &configured, settings: SemanticsSettings())
        GenModelDefaultsOptions.applyProjectSettings(
            basePackage: nil, prefixes: [], complianceLevel: nil, settings: SemanticsSettings(), to: &configured)

        #expect(plain.defaults == configured.defaults)
        #expect(configured.basePackage == nil)
        #expect(configured.prefix == nil)
        #expect(configured.packagePrefixes.isEmpty)
        #expect(configured.complianceLevel == nil)
    }

    @Test("applies the base package, prefixes and compliance level of the file, which the command line overrides")
    func projectSettingsPrecedence() throws {
        let configured = try Self.settings(
            #"{ "base-package": "org.example", "prefix": ["Lib", "books=Book"], "jdk-level": "21.0" }"#)
        var fromFile = GenModelImportOptions(atlOptions: .standard)
        var overridden = GenModelImportOptions(atlOptions: .standard)

        GenModelDefaultsOptions.applyProjectSettings(
            basePackage: nil, prefixes: [], complianceLevel: nil, settings: configured, to: &fromFile)
        GenModelDefaultsOptions.applyProjectSettings(
            basePackage: "com.example", prefixes: ["Shelf"], complianceLevel: "17.0", settings: configured,
            to: &overridden)

        #expect(fromFile.basePackage == "org.example")
        #expect(fromFile.prefix == "Lib")
        #expect(fromFile.packagePrefixes == ["books": "Book"])
        #expect(fromFile.complianceLevel == "21.0")
        #expect(overridden.basePackage == "com.example")
        #expect(overridden.prefix == "Shelf")
        #expect(overridden.packagePrefixes.isEmpty)
        #expect(overridden.complianceLevel == "17.0")
    }
}
