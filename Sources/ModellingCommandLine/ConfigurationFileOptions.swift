//
// ConfigurationFileOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Foundation

/// The command line options that choose the configuration file of a command without a preset.
///
/// `--config` names the configuration file to read, and `--no-config` reads none. Without
/// either, the file that ``ModellingConfiguration/discover(from:)`` finds from the current
/// directory is read, if there is one. The options are spelt as in ``SemanticsOptions``, which
/// offers them together with the preset; commands that choose no behaviours of the languages,
/// such as those that only read models and metamodels, include this group with `@OptionGroup`
/// instead. Such a command consults neither the `SWIFT_MODELLING_SEMANTICS` environment
/// variable nor the `semantics` key of the file.
///
/// A command obtains the ``settings(currentDirectory:)`` of a run once, before it reads its
/// documents, and passes them to the option groups whose keys it honours, such as
/// ``SourceEncodingOptions/encoding(settings:)`` and
/// ``MetamodelFormatOptions/ecoreLoadOptions(settings:encodingOptions:)``. An option given on the
/// command line overrides its key in the file.
public struct ConfigurationFileOptions: ParsableArguments, Sendable {
    /// The help of `--config`.
    public static let configHelp = ArgumentHelp(
        "A configuration file to read instead of the \(ModellingConfiguration.fileName) found "
            + "from the current directory",
        valueName: SemanticsOptions.configValueName)

    /// The help of `--no-config`.
    public static let noConfigHelp = ArgumentHelp("Read no configuration file")

    /// The configuration file given on the command line, if any.
    @Option(name: .customLong(SemanticsOptions.OptionName.config), help: ConfigurationFileOptions.configHelp)
    public var configurationPath: String?

    /// Whether no configuration file is read.
    @Flag(name: .customLong(SemanticsOptions.OptionName.noConfig), help: ConfigurationFileOptions.noConfigHelp)
    public var ignoresConfiguration: Bool = false

    /// Creates the options with nothing given, which reads the configuration file found from
    /// the current directory, if any.
    public init() {}

    /// Checks that the options do not contradict each other.
    ///
    /// - Throws: A validation error if both `--config` and `--no-config` are given.
    public func validate() throws {
        try Self.validate(configurationPath: configurationPath, ignoresConfiguration: ignoresConfiguration)
    }

    /// Reads the configuration file that the options select.
    ///
    /// - Parameter currentDirectory: The directory that the command runs in.
    /// - Returns: The settings of the file, empty if no file is read.
    /// - Throws: ``ModellingConfigurationError`` if the file cannot be read or is not valid.
    public func configuration(currentDirectory: URL) throws(ModellingConfigurationError) -> ModellingConfiguration {
        try Self.configuration(
            path: configurationPath, ignoresConfiguration: ignoresConfiguration, currentDirectory: currentDirectory)
    }

    /// The settings of a run, with the configuration file that the options select.
    ///
    /// The preset of the settings is ``SemanticsSettings/defaultPreset``, whatever the
    /// environment and the file say, as the commands that take these options choose no
    /// behaviours of the languages.
    ///
    /// - Parameter currentDirectory: The directory that the command runs in, from which the
    ///   configuration file is found (default: the current directory of the process).
    /// - Returns: The settings, whose ``SemanticsSettings/configuration`` holds the file.
    /// - Throws: ``ModellingConfigurationError`` if the file cannot be read or is not valid.
    public func settings(
        currentDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    ) throws(ModellingConfigurationError) -> SemanticsSettings {
        SemanticsSettings(configuration: try configuration(currentDirectory: currentDirectory))
    }

    /// A paragraph that describes the configuration file in the discussion of a command.
    ///
    /// - Parameter keys: The keys of the file that the command honours, in the order to list them.
    /// - Returns: The paragraph, naming the file, the options that choose it and the keys.
    public static func discussion(keys: [String]) -> String {
        let quoted = keys.map { "\"\($0)\"" }
        let listed: String
        if let last = quoted.last, quoted.count > 1 {
            listed = quoted.dropLast().joined(separator: ", ") + " and " + last
        } else {
            listed = quoted.first ?? ""
        }
        return "The configuration file is the first \(ModellingConfiguration.fileName) in the current "
            + "directory or a parent directory, up to the root of the repository; "
            + "--\(SemanticsOptions.OptionName.config) names another file and "
            + "--\(SemanticsOptions.OptionName.noConfig) reads none. Its keys \(listed) give the "
            + "options of the same names, and an option given on the command line overrides its key."
    }

    /// Checks that a configuration file is not both named and skipped.
    ///
    /// - Parameters:
    ///   - configurationPath: The file named with `--config`, if any.
    ///   - ignoresConfiguration: Whether `--no-config` is given.
    /// - Throws: A validation error if both are given.
    static func validate(configurationPath: String?, ignoresConfiguration: Bool) throws {
        if configurationPath != nil && ignoresConfiguration {
            throw ValidationError(
                "--\(SemanticsOptions.OptionName.config) and --\(SemanticsOptions.OptionName.noConfig) "
                    + "cannot be given together")
        }
    }

    /// Reads the configuration file that `--config` and `--no-config` select.
    ///
    /// With `--no-config` no file is read. With `--config`, exactly the file it names is read,
    /// relative to the current directory. Otherwise the file that
    /// ``ModellingConfiguration/discover(from:)`` finds from the current directory is read, if
    /// there is one.
    ///
    /// - Parameters:
    ///   - path: The file named with `--config`, if any.
    ///   - ignoresConfiguration: Whether `--no-config` is given.
    ///   - currentDirectory: The directory that the command runs in.
    /// - Returns: The settings of the file, empty if no file is read.
    /// - Throws: ``ModellingConfigurationError`` if the file cannot be read or is not valid.
    static func configuration(
        path: String?, ignoresConfiguration: Bool, currentDirectory: URL
    ) throws(ModellingConfigurationError) -> ModellingConfiguration {
        if ignoresConfiguration { return ModellingConfiguration() }
        if let path {
            let base = URL(fileURLWithPath: currentDirectory.path, isDirectory: true)
            return try ModellingConfiguration(contentsOf: URL(fileURLWithPath: path, relativeTo: base).absoluteURL)
        }
        guard let file = ModellingConfiguration.discover(from: currentDirectory) else {
            return ModellingConfiguration()
        }
        return try ModellingConfiguration(contentsOf: file)
    }
}
