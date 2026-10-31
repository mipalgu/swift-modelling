//
// SemanticsSettings.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import ModellingGenerators

/// The preset, configuration file and container lookup scope that apply to a run of a command.
///
/// The settings combine the sources of the behaviours of a command, from the highest
/// precedence to the lowest:
///
/// 1. a behaviour option given on the command line, such as `--block-line-breaks`;
/// 2. the same option in the configuration file (see ``ModellingConfiguration``);
/// 3. `--semantics` on the command line;
/// 4. the `SWIFT_MODELLING_SEMANTICS` environment variable (`ModellingSemantics.environmentVariable`);
/// 5. `semantics` in the configuration file;
/// 6. the built-in default, ``defaultPreset``.
///
/// Levels 3 to 6 choose the ``preset``. The option groups combine the preset and the
/// ``configuration`` with the options given on the command line, for example through
/// ``MTLSemanticsOptions/mtlOptions(settings:)``. `--let-type-mismatches` and `--unset-features`
/// do not depend on the preset: an option on the command line overrides the configuration file,
/// which overrides their built-in defaults.
///
/// Commands obtain the settings from ``SemanticsOptions/settings(environment:currentDirectory:)``;
/// ``resolve(semantics:containerLookupScope:environment:configuration:)`` combines the sources
/// without reading files or the environment of the process.
public struct SemanticsSettings: Sendable, Equatable {
    /// The preset that applies when neither the command line, the environment nor the
    /// configuration file chooses one, ``SemanticsPreset/standard``.
    public static let defaultPreset = SemanticsPreset.standard

    /// The preset of behaviours that applies where no option chooses a behaviour.
    public var preset: SemanticsPreset

    /// The objects whose containers a model answers for.
    ///
    /// This is the scope given on the command line with `--container-scope`, else the
    /// `container-scope` of the configuration file, else the scope of the ``preset``.
    public var containerLookupScope: ContainerLookupScope

    /// The settings of the configuration file, empty if no file was read.
    public var configuration: ModellingConfiguration

    /// Creates settings from a preset, a configuration and a container lookup scope.
    ///
    /// - Parameters:
    ///   - preset: The preset of behaviours (default: ``defaultPreset``).
    ///   - configuration: The settings of the configuration file (default: none).
    ///   - containerLookupScope: The scope given on the command line, or `nil` for the scope
    ///     of the configuration file, else that of the preset.
    public init(
        preset: SemanticsPreset = SemanticsSettings.defaultPreset,
        configuration: ModellingConfiguration = ModellingConfiguration(),
        containerLookupScope: ContainerLookupScope? = nil
    ) {
        self.preset = preset
        self.configuration = configuration
        self.containerLookupScope =
            containerLookupScope ?? configuration.containerLookupScope ?? preset.containerLookupScope
    }

    /// Combines the sources of the settings.
    ///
    /// The preset is the one given on the command line, else the one that the environment
    /// variable names, else the `semantics` of the configuration file, else ``defaultPreset``.
    /// The environment variable is checked even when the command line gives a preset, so that
    /// an invalid value is always reported.
    ///
    /// - Parameters:
    ///   - semantics: The preset given on the command line, if any.
    ///   - containerLookupScope: The container lookup scope given on the command line, if any.
    ///   - environment: The environment variables to read.
    ///   - configuration: The settings of the configuration file.
    /// - Returns: The settings.
    /// - Throws: `ModellingSemanticsError.invalidValue(_:variable:)` if the environment
    ///   variable names no preset.
    public static func resolve(
        semantics: SemanticsPreset?, containerLookupScope: ContainerLookupScope?,
        environment: [String: String], configuration: ModellingConfiguration
    ) throws(ModellingSemanticsError) -> SemanticsSettings {
        let fromEnvironment = try ModellingSemantics.fromEnvironment(environment).map(SemanticsPreset.init)
        return SemanticsSettings(
            preset: semantics ?? fromEnvironment ?? configuration.semantics ?? defaultPreset,
            configuration: configuration, containerLookupScope: containerLookupScope)
    }

    /// Creates a resource set whose resources use the container lookup scope of the settings.
    ///
    /// - Returns: An empty resource set with ``containerLookupScope`` as its default.
    public func makeResourceSet() -> ResourceSet {
        ResourceSet(defaultContainerLookupScope: containerLookupScope)
    }

    /// Copies the container lookup scope of the settings to generation options.
    ///
    /// - Parameter options: The generation options to update.
    public func apply(to options: inout GenerationOptions) {
        options.containerLookupScope = containerLookupScope
    }

    /// Copies the container lookup scope of the settings to the options of an Ecore model import.
    ///
    /// - Parameter options: The import options to update.
    public func apply(to options: inout GenModelImportOptions) {
        options.containerLookupScope = containerLookupScope
    }
}
