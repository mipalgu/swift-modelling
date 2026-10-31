//
// UnsetFeatureOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import ModellingGenerators

/// Parses a command-line value into an unset feature mode.
///
/// The raw values of the enumeration are the command-line spellings, so no
/// mapping is needed beyond the conformance.
extension UnsetFeatureReads: @retroactive ExpressibleByArgument {}

/// The command line option that chooses how transformations and templates read unset features.
///
/// A structural feature that a model does not set reads, by default, as the Eclipse Modeling
/// Framework reports it: an unset single-valued attribute as its declared default or the default
/// of its data type (such as `false`, zero or the first literal of an enumeration), an unset
/// many-valued feature as an empty collection, and an unset string attribute or reference as
/// undefined. The non-standard `undefined` mode reads every unset feature as undefined instead.
///
/// A command that reads a configuration file (see ``SemanticsOptions``) takes the mode from the
/// file unless it is given on the command line. The preset does not change the mode.
///
/// Commands include the option with `@OptionGroup`, and either pass ``unsetFeatures(settings:)``,
/// or ``unsetFeatures`` if they read no configuration file, to the engine they run, or apply it
/// to their generation and import options with ``apply(to:settings:)-(GenerationOptions,_)`` and
/// ``apply(to:settings:)-(GenModelImportOptions,_)``, or ``apply(to:)-(GenerationOptions)`` and
/// ``apply(to:)-(GenModelImportOptions)``.
public struct UnsetFeatureOptions: ParsableArguments, Sendable {
    /// The long name of the option.
    public static let optionName = "unset-features"

    /// The values of the option, separated as in the usage of a command.
    public static let valueList = UnsetFeatureReads.allCases.map(\.rawValue).joined(separator: "|")

    /// How unset features read.
    @Option(
        name: .customLong(UnsetFeatureOptions.optionName),
        help: ArgumentHelp(
            "How unset features read: \(UnsetFeatureReads.defaults.rawValue) (the default), as in "
                + "the Eclipse Modeling Framework, or \(UnsetFeatureReads.undefined.rawValue)",
            discussion: """
                With \(UnsetFeatureReads.defaults.rawValue), an unset single-valued attribute reads \
                as its declared default or the default of its data type (false, 0, 0.0 or the first \
                enumeration literal), an unset many-valued feature as an empty collection, and an \
                unset string or reference as undefined, as the Eclipse Modeling Framework and its \
                engines read them. With \(UnsetFeatureReads.undefined.rawValue), every unset feature \
                reads as undefined.
                """,
            valueName: UnsetFeatureOptions.valueList))
    public var explicitUnsetFeatures: UnsetFeatureReads?

    /// The mode that applies when neither the command line nor the configuration file
    /// chooses one, `UnsetFeatureReads.defaults`.
    public static let defaultMode = UnsetFeatureReads.defaults

    /// The mode given on the command line, or ``defaultMode`` if none is.
    ///
    /// The mode that applies to a run of a command that reads a configuration file also
    /// depends on that file; ``unsetFeatures(settings:)`` resolves it. Setting this property
    /// gives the mode as if on the command line.
    public var unsetFeatures: UnsetFeatureReads {
        get { explicitUnsetFeatures ?? Self.defaultMode }
        set { explicitUnsetFeatures = newValue }
    }

    /// Creates the option with nothing given, which reads unset features as their defaults
    /// unless the configuration file says otherwise.
    public init() {}

    /// The mode that applies to a run.
    ///
    /// The mode does not depend on the preset: it is the mode given on the command line, else
    /// the `unset-features` of the configuration file, else ``defaultMode``.
    ///
    /// - Parameter settings: The settings of the run, whose configuration file is consulted.
    /// - Returns: How unset features read.
    public func unsetFeatures(settings: SemanticsSettings) -> UnsetFeatureReads {
        explicitUnsetFeatures ?? settings.configuration.unsetFeatures ?? Self.defaultMode
    }

    /// A paragraph that describes the option in the discussion of a command.
    ///
    /// - Parameter reader: What reads the features, in the plural, such as `the templates`.
    /// - Returns: The paragraph, naming the option, its values and the semantics of each.
    public static func discussion(reader: String) -> String {
        "--\(optionName) chooses how \(reader) read features that a model does not set. With "
            + "\(UnsetFeatureReads.defaults.rawValue), the default, they read as the Eclipse Modeling "
            + "Framework reports them: an unset attribute as its declared default or the default of "
            + "its data type, such as false or 0, and an unset many-valued feature as an empty "
            + "collection, while an unset string or reference stays undefined. With "
            + "\(UnsetFeatureReads.undefined.rawValue), every unset feature reads as undefined."
    }

    /// Copies the mode given on the command line to generation options.
    ///
    /// - Parameter options: The generation options to update.
    public func apply(to options: inout GenerationOptions) {
        options.unsetFeatureReads = unsetFeatures
    }

    /// Copies the mode given on the command line to the options of an Ecore model import.
    ///
    /// - Parameter options: The import options to update.
    public func apply(to options: inout GenModelImportOptions) {
        options.unsetFeatureReads = unsetFeatures
    }

    /// Copies the mode that applies to a run to generation options.
    ///
    /// - Parameters:
    ///   - options: The generation options to update.
    ///   - settings: The settings of the run, whose configuration file is consulted.
    public func apply(to options: inout GenerationOptions, settings: SemanticsSettings) {
        options.unsetFeatureReads = unsetFeatures(settings: settings)
    }

    /// Copies the mode that applies to a run to the options of an Ecore model import.
    ///
    /// - Parameters:
    ///   - options: The import options to update.
    ///   - settings: The settings of the run, whose configuration file is consulted.
    public func apply(to options: inout GenModelImportOptions, settings: SemanticsSettings) {
        options.unsetFeatureReads = unsetFeatures(settings: settings)
    }
}
