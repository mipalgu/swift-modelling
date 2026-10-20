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
/// Commands include the option with `@OptionGroup`, and either pass ``unsetFeatures`` to the
/// engine they run or apply it to their generation and import options with ``apply(to:)-(GenerationOptions)``
/// and ``apply(to:)-(GenModelImportOptions)``.
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
    public var unsetFeatures: UnsetFeatureReads = .defaults

    /// Creates the option with unset features reading as their defaults.
    public init() {}

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
}
