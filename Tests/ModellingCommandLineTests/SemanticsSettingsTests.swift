//
// SemanticsSettingsTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ATL
import ArgumentParser
import ECore
import Foundation
import MTL
import ModellingCommandLine
import ModellingGenerators
import Testing

/// The option groups of a command that runs templates and transformations.
private struct ResolvingCommand: ParsableArguments {
    @OptionGroup var semantics: SemanticsOptions
    @OptionGroup var mtl: MTLSemanticsOptions
    @OptionGroup var atl: ATLSemanticsOptions
    @OptionGroup var lets: LetTypeMismatchOptions
    @OptionGroup var unset: UnsetFeatureOptions
}

/// A source of a behaviour, from the highest precedence to the lowest above the built-in default.
enum Level: Int, CaseIterable, Sendable {
    /// The option of the behaviour on the command line.
    case flag

    /// The option of the behaviour in the configuration file.
    case configurationOption

    /// `--semantics` on the command line.
    case semanticsFlag

    /// The `SWIFT_MODELLING_SEMANTICS` environment variable.
    case environment

    /// `"semantics"` in the configuration file.
    case configurationSemantics
}

/// A behaviour whose value can come from every level.
enum Behaviour: CaseIterable, Sendable {
    case blockLineBreaks, checksLetTypes, collectionArguments, collectionRangeSyntax, containerScope

    /// The command-line arguments that select the standard or the legacy value.
    func flag(legacy: Bool) -> [String] {
        switch self {
        case .blockLineBreaks:
            return ["--\(MTLSemanticsOptions.OptionName.blockLineBreaks)", legacy ? "kept" : "acceleo"]
        case .checksLetTypes:
            return [legacy ? "--no-check-let-types" : "--check-let-types"]
        case .collectionArguments:
            return ["--\(MTLSemanticsOptions.OptionName.collectionArguments)", legacy ? "first-element" : "whole"]
        case .collectionRangeSyntax:
            return ["--\(ATLSemanticsOptions.OptionName.collectionRangeSyntax)", legacy ? "eclipse" : "ocl"]
        case .containerScope:
            return ["--\(SemanticsOptions.OptionName.containerScope)", legacy ? "this-resource" : "any-resource"]
        }
    }

    /// Sets the standard or the legacy value in a configuration.
    func configure(_ configuration: inout ModellingConfiguration, legacy: Bool) {
        switch self {
        case .blockLineBreaks: configuration.blockLineBreaks = legacy ? .kept : .acceleo
        case .checksLetTypes: configuration.checksLetTypes = !legacy
        case .collectionArguments: configuration.collectionArguments = legacy ? .firstElement : .whole
        case .collectionRangeSyntax: configuration.collectionRangeSyntax = legacy ? .eclipse : .ocl
        case .containerScope: configuration.containerLookupScope = legacy ? .thisResource : .anyResource
        }
    }

    /// Whether a command with settings selects the legacy value.
    fileprivate func isLegacy(_ command: ResolvingCommand, _ settings: SemanticsSettings) -> Bool {
        switch self {
        case .blockLineBreaks: return command.mtl.mtlOptions(settings: settings).blockLineBreaks == .kept
        case .checksLetTypes: return !command.mtl.mtlOptions(settings: settings).checksLetTypes
        case .collectionArguments:
            let aql = command.mtl.aqlOptions(settings: settings)
            #expect(command.mtl.mtlOptions(settings: settings).aql == aql)
            return aql.collectionArguments == .firstElement
        case .collectionRangeSyntax: return command.atl.atlOptions(settings: settings).collectionRangeSyntax == .eclipse
        case .containerScope: return settings.containerLookupScope == .thisResource
        }
    }
}

@Suite("Semantics settings")
struct SemanticsSettingsTests {
    /// The name of the environment variable.
    private static let variable = ModellingSemantics.environmentVariable

    // MARK: - Precedence

    /// Resolves a behaviour with some levels set.
    ///
    /// The level of highest precedence among `levels` gets the legacy value if `legacyWins`,
    /// and the standard value otherwise; every other level in `levels` gets the other value.
    ///
    /// - Returns: Whether the resolved behaviour is the legacy one.
    private func resolve(_ behaviour: Behaviour, levels: Set<Level>, legacyWins: Bool) throws -> Bool {
        let top = levels.min { $0.rawValue < $1.rawValue }
        func legacy(_ level: Level) -> Bool { (level == top) == legacyWins }
        func preset(_ level: Level) -> SemanticsPreset { legacy(level) ? .legacy : .standard }
        var arguments: [String] = []
        var configuration = ModellingConfiguration()
        var environment: [String: String] = ["UNRELATED": "legacy"]
        for level in levels {
            switch level {
            case .flag: arguments += behaviour.flag(legacy: legacy(level))
            case .configurationOption: behaviour.configure(&configuration, legacy: legacy(level))
            case .semanticsFlag: arguments += ["--\(SemanticsOptions.optionName)", preset(level).rawValue]
            case .environment: environment[Self.variable] = preset(level).rawValue
            case .configurationSemantics: configuration.semantics = preset(level)
            }
        }
        let command = try ResolvingCommand.parse(arguments)
        let settings = try SemanticsSettings.resolve(
            semantics: command.semantics.explicitSemantics,
            containerLookupScope: command.semantics.containerLookupScope,
            environment: environment, configuration: configuration)
        return behaviour.isLegacy(command, settings)
    }

    @Test(
        "takes each behaviour from the level of highest precedence",
        arguments: Behaviour.allCases, 0..<(1 << Level.allCases.count))
    func precedence(behaviour: Behaviour, mask: Int) throws {
        let levels = Set(Level.allCases.filter { mask & (1 << $0.rawValue) != 0 })
        for legacyWins in [false, true] {
            let expected = levels.isEmpty ? false : legacyWins
            #expect(
                try resolve(behaviour, levels: levels, legacyWins: legacyWins) == expected,
                "\(behaviour) with \(levels.sorted { $0.rawValue < $1.rawValue }), legacy wins: \(legacyWins)")
        }
    }

    @Test("selects the preset from --semantics, then the environment, then the file, then standard")
    func presetPrecedence() throws {
        func preset(_ flag: SemanticsPreset?, _ environment: SemanticsPreset?, _ file: SemanticsPreset?) throws
            -> SemanticsPreset
        {
            var configuration = ModellingConfiguration()
            configuration.semantics = file
            let variables = environment.map { [Self.variable: $0.rawValue] } ?? [:]
            return try SemanticsSettings.resolve(
                semantics: flag, containerLookupScope: nil, environment: variables, configuration: configuration
            ).preset
        }
        #expect(try preset(nil, nil, nil) == .standard)
        #expect(try preset(nil, nil, .legacy) == .legacy)
        #expect(try preset(nil, .legacy, .standard) == .legacy)
        #expect(try preset(nil, .standard, .legacy) == .standard)
        #expect(try preset(.legacy, .standard, .standard) == .legacy)
        #expect(try preset(.standard, .legacy, .legacy) == .standard)
    }

    @Test("treats an empty environment variable as unset")
    func emptyEnvironment() throws {
        var configuration = ModellingConfiguration()
        configuration.semantics = .legacy
        let settings = try SemanticsSettings.resolve(
            semantics: nil, containerLookupScope: nil, environment: [Self.variable: ""],
            configuration: configuration)
        #expect(settings.preset == .legacy)
    }

    @Test("rejects an invalid environment variable, naming it, its value and the accepted values")
    func invalidEnvironment() throws {
        for flag in [nil, SemanticsPreset.standard] {
            do {
                _ = try SemanticsSettings.resolve(
                    semantics: flag, containerLookupScope: nil, environment: [Self.variable: "0.6"],
                    configuration: ModellingConfiguration())
                Issue.record("an invalid value was accepted with \(String(describing: flag))")
            } catch {
                #expect(error == .invalidValue("0.6", variable: Self.variable))
                for text in [Self.variable, "0.6", "standard", "legacy"] {
                    #expect(error.description.contains(text), "\(text) is missing from: \(error.description)")
                }
            }
        }
    }

    @Test("takes the mode of typed let mismatches from the flag, then the file, then the default")
    func letTypeMismatches() throws {
        for (arguments, file, expected) in [
            ([], nil, MTLLetTypeMismatches.error),
            ([], .skip, .skip),
            (["--let-type-mismatches", "skip"], nil, .skip),
            (["--let-type-mismatches", "skip"], .error, .skip),
            (["--let-type-mismatches", "error"], .skip, .error),
        ] as [([String], MTLLetTypeMismatches?, MTLLetTypeMismatches)] {
            var configuration = ModellingConfiguration()
            configuration.letTypeMismatches = file
            configuration.semantics = .legacy
            let command = try ResolvingCommand.parse(arguments)
            let settings = try SemanticsSettings.resolve(
                semantics: .legacy, containerLookupScope: nil, environment: [Self.variable: "legacy"],
                configuration: configuration)
            #expect(command.lets.letTypeMismatches(settings: settings) == expected, "\(arguments) \(String(describing: file))")
            var generation = GenerationOptions(mtlOptions: .standard)
            command.lets.apply(to: &generation, settings: settings)
            #expect(generation.mtlOptions.letTypeMismatches == expected)
        }
    }

    @Test("takes the reading of unset features from the flag, then the file, then the default")
    func unsetFeatures() throws {
        for (arguments, file, expected) in [
            ([], nil, UnsetFeatureReads.defaults),
            ([], .undefined, .undefined),
            (["--unset-features", "undefined"], nil, .undefined),
            (["--unset-features", "undefined"], .defaults, .undefined),
            (["--unset-features", "defaults"], .undefined, .defaults),
        ] as [([String], UnsetFeatureReads?, UnsetFeatureReads)] {
            var configuration = ModellingConfiguration()
            configuration.unsetFeatures = file
            let command = try ResolvingCommand.parse(arguments)
            let settings = try SemanticsSettings.resolve(
                semantics: .legacy, containerLookupScope: nil, environment: [:], configuration: configuration)
            #expect(command.unset.unsetFeatures(settings: settings) == expected, "\(arguments) \(String(describing: file))")
            var generation = GenerationOptions(mtlOptions: .standard)
            command.unset.apply(to: &generation, settings: settings)
            #expect(generation.unsetFeatureReads == expected)
            var imports = GenModelImportOptions(atlOptions: .standard)
            command.unset.apply(to: &imports, settings: settings)
            #expect(imports.unsetFeatureReads == expected)
        }
    }

    // MARK: - Defaults

    @Test("keeps the behaviour of this release without a flag, a variable or a file")
    func unchangedDefaults() throws {
        let command = try ResolvingCommand.parse([])
        let settings = try SemanticsSettings.resolve(
            semantics: nil, containerLookupScope: nil, environment: [:], configuration: ModellingConfiguration())
        #expect(settings.preset == .standard)
        #expect(settings.containerLookupScope == .anyResource)
        #expect(settings == SemanticsSettings())
        #expect(command.mtl.mtlOptions(settings: settings) == .standard)
        #expect(command.mtl.mtlOptions(settings: settings) == command.mtl.mtlOptions(preset: .standard))
        #expect(command.atl.atlOptions(settings: settings) == .standard)
        #expect(command.lets.letTypeMismatches(settings: settings) == .error)
        #expect(command.unset.unsetFeatures(settings: settings) == .defaults)
        #expect(command.semantics.semantics == .standard)
        #expect(command.semantics.explicitSemantics == nil)
        #expect(command.semantics.containerLookupScope == nil)
        #expect(command.lets.letTypeMismatches == .error)
        #expect(command.unset.unsetFeatures == .defaults)
    }

    @Test("keeps the preset of a settings value created from a preset", arguments: SemanticsPreset.allCases)
    func presetSettings(preset: SemanticsPreset) throws {
        let settings = SemanticsSettings(preset: preset)
        let command = try ResolvingCommand.parse([])
        #expect(settings.containerLookupScope == preset.containerLookupScope)
        #expect(command.mtl.mtlOptions(settings: settings) == preset.mtlOptions)
        #expect(command.atl.atlOptions(settings: settings) == preset.atlOptions)
    }

    @Test("lets the stored options still be set directly")
    func settableOptions() {
        var options = SemanticsOptions()
        options.semantics = .legacy
        #expect(options.explicitSemantics == .legacy)
        var lets = LetTypeMismatchOptions()
        lets.letTypeMismatches = .skip
        #expect(lets.letTypeMismatches(settings: SemanticsSettings()) == .skip)
        var unset = UnsetFeatureOptions()
        unset.unsetFeatures = .undefined
        #expect(unset.unsetFeatures(settings: SemanticsSettings()) == .undefined)
    }

    // MARK: - Presets and scopes

    @Test("maps each preset to the semantics of the libraries and its container scope")
    func presetMapping() {
        #expect(SemanticsPreset(ModellingSemantics.standard) == .standard)
        #expect(SemanticsPreset(ModellingSemantics.legacy) == .legacy)
        for preset in SemanticsPreset.allCases {
            #expect(SemanticsPreset(preset.modellingSemantics) == preset)
            #expect(preset.rawValue == preset.modellingSemantics.rawValue)
            #expect(preset.containerLookupScope == ContainerLookupScope(semantics: preset.modellingSemantics))
        }
        #expect(SemanticsPreset.standard.containerLookupScope == .anyResource)
        #expect(SemanticsPreset.legacy.containerLookupScope == .thisResource)
    }

    @Test("parses each container scope", arguments: ContainerLookupScope.allCases)
    func parsesContainerScope(scope: ContainerLookupScope) throws {
        let options = try SemanticsOptions.parse(["--\(SemanticsOptions.OptionName.containerScope)", scope.rawValue])
        #expect(options.containerLookupScope == scope)
    }

    @Test("rejects a container scope that does not exist")
    func rejectsUnknownScope() {
        #expect(throws: (any Error).self) {
            try SemanticsOptions.parse(["--\(SemanticsOptions.OptionName.containerScope)", "everywhere"])
        }
    }

    @Test("names the options and their values")
    func names() {
        #expect(SemanticsOptions.OptionName.semantics == SemanticsOptions.optionName)
        #expect(SemanticsOptions.OptionName.containerScope == "container-scope")
        #expect(SemanticsOptions.OptionName.config == "config")
        #expect(SemanticsOptions.OptionName.noConfig == "no-config")
        #expect(SemanticsOptions.containerScopeValueList == "any-resource|this-resource")
        let discussion = SemanticsOptions.discussion()
        for text in ["--container-scope", ModellingSemantics.environmentVariable, ModellingConfiguration.fileName] {
            #expect(discussion.contains(text), "\(text) is missing from the discussion")
        }
    }

    @Test("copies the container scope to generation and import options", arguments: ContainerLookupScope.allCases)
    func appliesContainerScope(scope: ContainerLookupScope) async {
        let settings = SemanticsSettings(preset: .standard, containerLookupScope: scope)
        var generation = GenerationOptions(mtlOptions: .standard)
        var imports = GenModelImportOptions(atlOptions: .standard)
        #expect(generation.containerLookupScope == nil)
        #expect(imports.containerLookupScope == nil)
        settings.apply(to: &generation)
        settings.apply(to: &imports)
        #expect(generation.containerLookupScope == scope)
        #expect(imports.containerLookupScope == scope)
        let resourceSet = settings.makeResourceSet()
        #expect(await resourceSet.defaultContainerLookupScope == scope)
    }

    @Test("applies the behaviours of the settings to generation options")
    func appliesToGenerationOptions() throws {
        var configuration = ModellingConfiguration()
        configuration.collectionKinds = .sequences
        let settings = SemanticsSettings(preset: .legacy, configuration: configuration)
        var generation = GenerationOptions(mtlOptions: .standard)
        generation.mtlOptions.letTypeMismatches = .skip
        try MTLSemanticsOptions.parse(["--block-line-breaks", "acceleo"]).apply(to: &generation, settings: settings)
        #expect(generation.mtlOptions.blockLineBreaks == .acceleo)
        #expect(generation.mtlOptions.aql.collectionKinds == .sequences)
        #expect(generation.mtlOptions.aql.collectionArguments == .firstElement)
        #expect(generation.mtlOptions.letTypeMismatches == .skip)
        var imports = GenModelImportOptions(atlOptions: .standard)
        try ATLSemanticsOptions.parse([]).apply(to: &imports, settings: settings)
        #expect(imports.atlOptions == .legacy)
    }

    // MARK: - Configuration files

    @Test("rejects --config together with --no-config")
    func conflictingConfigurationOptions() {
        #expect(throws: (any Error).self) {
            try SemanticsOptions.parse(["--config", "settings.json", "--no-config"])
        }
    }

    @Test("reads a configuration file found above the current directory")
    func discoveredConfiguration() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()
        let file = try scratch.writeConfiguration(#"{ "semantics": "legacy", "container-scope": "any-resource" }"#)
        let start = try scratch.directory("models")

        let settings = try SemanticsOptions.parse([]).settings(environment: [:], currentDirectory: start)

        #expect(settings.preset == .legacy)
        #expect(settings.containerLookupScope == .anyResource)
        #expect(samePath(settings.configuration.url, file))
    }

    @Test("ignores the configuration file with --no-config")
    func ignoredConfiguration() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()
        try scratch.writeConfiguration(#"{ "semantics": "legacy" }"#)

        let settings = try SemanticsOptions.parse(["--no-config"]).settings(environment: [:], currentDirectory: scratch.url)

        #expect(settings.preset == .standard)
        #expect(settings.configuration == ModellingConfiguration())
    }

    @Test("reads exactly the file given with --config")
    func explicitConfiguration() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()
        try scratch.writeConfiguration(#"{ "semantics": "standard" }"#)
        let file = try scratch.write(#"{ "semantics": "legacy" }"#, to: "elsewhere/settings.json")

        let absolute = try SemanticsOptions.parse(["--config", file.path])
            .settings(environment: [:], currentDirectory: scratch.url)
        let relative = try SemanticsOptions.parse(["--config", "elsewhere/settings.json"])
            .settings(environment: [:], currentDirectory: scratch.url)

        #expect(absolute.preset == .legacy)
        #expect(relative.preset == .legacy)
        #expect(samePath(relative.configuration.url, file))
    }

    @Test("reports a file given with --config that does not exist, naming it")
    func missingExplicitConfiguration() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        let file = scratch.url.appendingPathComponent("absent.json")

        #expect {
            try SemanticsOptions.parse(["--config", file.path]).settings(environment: [:], currentDirectory: scratch.url)
        } throws: { error in
            guard let error = error as? ModellingConfigurationError, case .unreadable(let path, _) = error else {
                return false
            }
            return samePath(URL(fileURLWithPath: path), file) && error.description.contains(file.lastPathComponent)
        }
    }

    @Test("reports an error in a discovered file")
    func invalidDiscoveredConfiguration() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()
        let file = try scratch.writeConfiguration(#"{ "semantics": "legacy", "flavour": "vanilla" }"#)

        #expect {
            try SemanticsOptions.parse([]).settings(environment: [:], currentDirectory: scratch.url)
        } throws: { error in
            guard let error = error as? ModellingConfigurationError, case .unknownKey("flavour", let path) = error else {
                return false
            }
            return samePath(URL(fileURLWithPath: path), file)
        }
    }

    @Test("reports an invalid environment variable when reading the settings")
    func invalidEnvironmentSettings() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()

        #expect(throws: ModellingSemanticsError.invalidValue("old", variable: Self.variable)) {
            try SemanticsOptions.parse(["--no-config"])
                .settings(environment: [Self.variable: "old"], currentDirectory: scratch.url)
        }
    }

    @Test("lets the command line, the environment and the file combine")
    func combined() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()
        try scratch.writeConfiguration(
            #"{ "semantics": "standard", "collection-kinds": "sequences", "let-type-mismatches": "skip" }"#)

        let command = try ResolvingCommand.parse(["--block-line-breaks", "acceleo"])
        let settings = try command.semantics.settings(environment: [Self.variable: "legacy"], currentDirectory: scratch.url)
        let mtl = command.mtl.mtlOptions(settings: settings)

        #expect(settings.preset == .legacy)
        #expect(settings.containerLookupScope == .thisResource)
        #expect(mtl.blockLineBreaks == .acceleo)
        #expect(mtl.aql.collectionKinds == .sequences)
        #expect(mtl.aql.collectionArguments == .firstElement)
        #expect(command.lets.letTypeMismatches(settings: settings) == .skip)
    }
}
