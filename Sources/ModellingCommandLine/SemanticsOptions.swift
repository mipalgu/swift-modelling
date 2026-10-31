//
// SemanticsOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ATL
import ArgumentParser
import ECore
import Foundation
import MTL

/// Parses a command-line value into the objects whose containers a model answers for.
extension ContainerLookupScope: @retroactive ExpressibleByArgument {}

/// A set of behaviours of the modelling languages, chosen as a whole.
///
/// Each case gives every behaviour that has an alternative a value at once: ``standard`` the
/// behaviour documented for this release, and ``legacy`` the behaviour of version 0.6. The raw
/// value of each case is its command-line spelling.
public enum SemanticsPreset: String, CaseIterable, Sendable, ExpressibleByArgument {
    /// The behaviour documented for this release, which is the default.
    case standard

    /// The behaviour of version 0.6.
    case legacy

    /// The behaviours of the template language that the preset gives.
    ///
    /// - Returns: `MTLOptions.standard` or `MTLOptions.legacy`.
    public var mtlOptions: MTLOptions {
        switch self {
        case .standard: return .standard
        case .legacy: return .legacy
        }
    }

    /// The behaviours of the transformation language that the preset gives.
    ///
    /// - Returns: `ATLOptions.standard` or `ATLOptions.legacy`.
    public var atlOptions: ATLOptions {
        switch self {
        case .standard: return .standard
        case .legacy: return .legacy
        }
    }

    /// Creates the preset that a choice of semantics of the libraries names.
    ///
    /// - Parameter semantics: The semantics, such as the value of the
    ///   `SWIFT_MODELLING_SEMANTICS` environment variable.
    public init(_ semantics: ModellingSemantics) {
        switch semantics {
        case .standard: self = .standard
        case .legacy: self = .legacy
        }
    }

    /// The choice of semantics of the libraries that the preset names.
    ///
    /// - Returns: `ModellingSemantics.standard` or `ModellingSemantics.legacy`.
    public var modellingSemantics: ModellingSemantics {
        switch self {
        case .standard: return .standard
        case .legacy: return .legacy
        }
    }

    /// The objects whose containers a model answers for with the preset.
    ///
    /// - Returns: `ContainerLookupScope.anyResource` for ``standard`` and
    ///   `ContainerLookupScope.thisResource` for ``legacy``.
    public var containerLookupScope: ContainerLookupScope {
        ContainerLookupScope(semantics: modellingSemantics)
    }
}

/// The command line options that choose the behaviours of the modelling languages as a whole.
///
/// `--semantics standard` selects the behaviour documented for this release, and
/// `--semantics legacy` that of version 0.6. The option sets every behaviour that
/// ``MTLSemanticsOptions`` and ``ATLSemanticsOptions`` offer, and the container lookup scope; an
/// option of those groups that is given on the command line overrides the preset, whatever the
/// order of the options.
///
/// Without `--semantics`, the preset comes from the `SWIFT_MODELLING_SEMANTICS` environment
/// variable, else from the configuration file, else it is ``SemanticsSettings/defaultPreset``.
/// The configuration file is the one that `--config` names, or the one that
/// ``ModellingConfiguration/discover(from:)`` finds from the current directory unless
/// `--no-config` is given. ``SemanticsSettings`` describes the precedence of all sources.
///
/// `--container-scope` chooses the objects whose containers a model answers for, which commands
/// apply to the resource sets into which they load their models.
///
/// Commands include the options with `@OptionGroup` once, next to the groups whose behaviours
/// they preset, obtain the ``settings(environment:currentDirectory:)`` before they run, and pass
/// the settings to the other groups.
public struct SemanticsOptions: ParsableArguments, Sendable {
    /// The long names of the options.
    public enum OptionName {
        /// The option that chooses the preset.
        public static let semantics = "semantics"

        /// The option that chooses the container lookup scope.
        public static let containerScope = "container-scope"

        /// The option that names the configuration file.
        public static let config = "config"

        /// The flag that skips the configuration file.
        public static let noConfig = "no-config"
    }

    /// The long name of the option that chooses the preset.
    public static let optionName = OptionName.semantics

    /// The values of the option, separated as in the usage of a command.
    public static let valueList = SemanticsPreset.allCases.map(\.rawValue).joined(separator: "|")

    /// The values of `--container-scope`, separated as in the usage of a command.
    public static let containerScopeValueList = MTLSemanticsOptions.valueList(ContainerLookupScope.self)

    /// The name of the value of `--config` in the usage of a command.
    static let configValueName = "file"

    /// The preset given on the command line, if any.
    @Option(
        name: .customLong(OptionName.semantics),
        help: ArgumentHelp(
            "The behaviours of the languages: \(SemanticsPreset.standard.rawValue) (the default) "
                + "or \(SemanticsPreset.legacy.rawValue), as in version 0.6",
            discussion: """
                \(SemanticsPreset.standard.rawValue) selects the behaviour documented for this \
                release, and \(SemanticsPreset.legacy.rawValue) that of version 0.6, for every \
                behaviour option of the command. A behaviour option that is given as well \
                overrides the preset. Without this option, the \
                \(ModellingSemantics.environmentVariable) environment variable and then the \
                configuration file choose the preset.
                """,
            valueName: SemanticsOptions.valueList))
    public var explicitSemantics: SemanticsPreset?

    /// The preset given on the command line, or ``SemanticsSettings/defaultPreset`` if none is.
    ///
    /// The preset that applies to a run also depends on the environment and the configuration
    /// file; ``settings(environment:currentDirectory:)`` resolves it. Setting this property
    /// gives the preset as if on the command line.
    public var semantics: SemanticsPreset {
        get { explicitSemantics ?? SemanticsSettings.defaultPreset }
        set { explicitSemantics = newValue }
    }

    /// The container lookup scope given on the command line, if any.
    @Option(
        name: .customLong(OptionName.containerScope),
        help: ArgumentHelp(
            "The objects whose containers a model finds: \(ContainerLookupScope.anyResource.rawValue) "
                + "(the default) or \(ContainerLookupScope.thisResource.rawValue), as in version 0.6",
            discussion: """
                With \(ContainerLookupScope.anyResource.rawValue), a model finds the container of \
                an object of another model of the run that it holds in a containment reference, so \
                eContainer() and the services that depend on it find containers across models. \
                With \(ContainerLookupScope.thisResource.rawValue), a model answers only for the \
                objects that it holds itself. The default follows the preset: \
                \(SemanticsPreset.standard.containerLookupScope.rawValue) for \
                \(SemanticsPreset.standard.rawValue) and \
                \(SemanticsPreset.legacy.containerLookupScope.rawValue) for \
                \(SemanticsPreset.legacy.rawValue).
                """,
            valueName: SemanticsOptions.containerScopeValueList))
    public var containerLookupScope: ContainerLookupScope?

    /// The configuration file given on the command line, if any.
    @Option(
        name: .customLong(OptionName.config),
        help: ArgumentHelp(
            "A configuration file to read instead of the \(ModellingConfiguration.fileName) found "
                + "from the current directory",
            valueName: SemanticsOptions.configValueName))
    public var configurationPath: String?

    /// Whether no configuration file is read.
    @Flag(
        name: .customLong(OptionName.noConfig),
        help: ArgumentHelp("Read no configuration file"))
    public var ignoresConfiguration: Bool = false

    /// Creates the options with nothing given, which leaves the preset to the environment, the
    /// configuration file and the default.
    public init() {}

    /// Checks that the options do not contradict each other.
    ///
    /// - Throws: A validation error if both `--config` and `--no-config` are given.
    public func validate() throws {
        if configurationPath != nil && ignoresConfiguration {
            throw ValidationError("--\(OptionName.config) and --\(OptionName.noConfig) cannot be given together")
        }
    }

    /// Reads the configuration file that the options select.
    ///
    /// With `--no-config` no file is read. With `--config`, exactly the file it names is read,
    /// relative to the current directory. Otherwise the file that
    /// ``ModellingConfiguration/discover(from:)`` finds from the current directory is read, if
    /// there is one.
    ///
    /// - Parameter currentDirectory: The directory that the command runs in.
    /// - Returns: The settings of the file, empty if no file is read.
    /// - Throws: ``ModellingConfigurationError`` if the file cannot be read or is not valid.
    public func configuration(currentDirectory: URL) throws(ModellingConfigurationError) -> ModellingConfiguration {
        if ignoresConfiguration { return ModellingConfiguration() }
        if let configurationPath {
            let base = URL(fileURLWithPath: currentDirectory.path, isDirectory: true)
            return try ModellingConfiguration(
                contentsOf: URL(fileURLWithPath: configurationPath, relativeTo: base).absoluteURL)
        }
        guard let file = ModellingConfiguration.discover(from: currentDirectory) else {
            return ModellingConfiguration()
        }
        return try ModellingConfiguration(contentsOf: file)
    }

    /// Resolves the settings of a run from the options, the environment and the configuration file.
    ///
    /// - Parameters:
    ///   - environment: The environment variables to read (default: those of the process).
    ///   - currentDirectory: The directory that the command runs in, from which the
    ///     configuration file is found (default: the current directory of the process).
    /// - Returns: The settings, as ``SemanticsSettings/resolve(semantics:containerLookupScope:environment:configuration:)``
    ///   combines them.
    /// - Throws: ``ModellingConfigurationError`` if the configuration file cannot be read or is
    ///   not valid, and `ModellingSemanticsError` if the environment variable names no preset.
    public func settings(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        currentDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    ) throws -> SemanticsSettings {
        try SemanticsSettings.resolve(
            semantics: explicitSemantics, containerLookupScope: containerLookupScope, environment: environment,
            configuration: configuration(currentDirectory: currentDirectory))
    }

    /// A paragraph that describes the options in the discussion of a command.
    ///
    /// - Returns: The paragraph, naming the options, their values, the environment variable, the
    ///   configuration file and the precedence of the options that they preset.
    public static func discussion() -> String {
        "--\(optionName) \(SemanticsPreset.legacy.rawValue) selects the behaviour of version 0.6 "
            + "for every behaviour option of the command, and --\(optionName) "
            + "\(SemanticsPreset.standard.rawValue), the default, the behaviour of this release. "
            + "A behaviour option given on the command line overrides the preset. Without "
            + "--\(optionName), the \(ModellingSemantics.environmentVariable) environment variable "
            + "(\(SemanticsPreset.standard.rawValue) or \(SemanticsPreset.legacy.rawValue)) and then "
            + "the \(OptionName.semantics) key of the configuration file choose the preset. The "
            + "configuration file is the first \(ModellingConfiguration.fileName) in the current "
            + "directory or a parent directory, up to the root of the repository; "
            + "--\(OptionName.config) names another file and --\(OptionName.noConfig) reads none. Its "
            + "keys are the names of the behaviour options, such as \"\(MTLSemanticsOptions.OptionName.blockLineBreaks)\": "
            + "\"\(MTLBlockLineBreaks.kept.rawValue)\", and they override the preset but not the command "
            + "line. --\(OptionName.containerScope) \(ContainerLookupScope.thisResource.rawValue) lets each "
            + "model find only the containers of its own objects, as in version 0.6, and "
            + "\(ContainerLookupScope.anyResource.rawValue) also those of objects of other models."
    }
}
