//
// KM3Options.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore

/// Parses a command-line value into a way of reading the data types of a KM3 metamodel.
///
/// The raw values of the enumeration, `ecore` and `declared`, are the command-line spellings.
extension KM3PrimitiveTypeMapping: @retroactive ExpressibleByArgument {}

/// The command line option that chooses how the data types of a KM3 metamodel are read.
///
/// A KM3 metamodel (`.km3`) declares its primitive types, such as `String` or `Integer`, as
/// data types of its own. With `ecore`, the default, such a declaration stands for the
/// built-in Ecore data type of the same meaning, such as `EString`, so that models of the
/// metamodel read and write their values as other Ecore metamodels do. With `declared`, every
/// declared data type becomes a data type of its package, as the KM32EMF transformation of the
/// ATL tool chain makes it.
///
/// The configuration file may choose the mapping too, under the key ``optionName``; an option
/// given on the command line overrides it. The preset of ``SemanticsOptions`` does not change it.
public struct KM3Options: ParsableArguments, Sendable {
    /// The long name of the option, and the key of the configuration file.
    public static let optionName = "km3-primitives"

    /// The values of the option, separated as in the usage of a command.
    public static let valueList = KM3PrimitiveTypeMapping.allCases.map(\.rawValue).joined(separator: "|")

    /// The mapping that applies when neither the command line nor the configuration file
    /// chooses one, that of `KM3ReadOptions.standard`.
    public static let defaultMapping = KM3ReadOptions.standard.primitiveTypes

    /// The mapping given on the command line, if any.
    @Option(
        name: .customLong(KM3Options.optionName),
        help: ArgumentHelp(
            "How the data types of a KM3 metamodel are read: \(KM3PrimitiveTypeMapping.ecore.rawValue) "
                + "(the default) or \(KM3PrimitiveTypeMapping.declared.rawValue)",
            discussion: """
                With \(KM3PrimitiveTypeMapping.ecore.rawValue), a data type that a KM3 metamodel \
                declares with the name of a primitive type, such as String or Integer, stands for \
                the built-in Ecore data type, such as EString or EInt. With \
                \(KM3PrimitiveTypeMapping.declared.rawValue), every declared data type becomes a data \
                type of its package, as in the KM32EMF transformation of the ATL tool chain.
                """,
            valueName: KM3Options.valueList))
    public var explicitPrimitiveTypes: KM3PrimitiveTypeMapping?

    /// Creates the option with nothing given.
    public init() {}

    /// The options with which KM3 metamodels are read, from the command line alone.
    ///
    /// Commands that read no configuration file use these options.
    public var readOptions: KM3ReadOptions {
        KM3ReadOptions(primitiveTypes: explicitPrimitiveTypes ?? Self.defaultMapping)
    }

    /// The options with which KM3 metamodels are read in a run.
    ///
    /// The mapping is the one given on the command line, else the `km3-primitives` of the
    /// configuration file, else ``defaultMapping``.
    ///
    /// - Parameter settings: The settings of the run, whose configuration file is consulted.
    /// - Returns: The options of the KM3 reader.
    public func readOptions(settings: SemanticsSettings) -> KM3ReadOptions {
        KM3ReadOptions(
            primitiveTypes: explicitPrimitiveTypes ?? settings.configuration.km3PrimitiveTypes ?? Self.defaultMapping)
    }

    /// The options with which metamodels are loaded, from the command line alone.
    public var ecoreLoadOptions: EcoreLoadOptions {
        EcoreLoadOptions(km3Options: readOptions)
    }

    /// The options with which metamodels are loaded in a run.
    ///
    /// - Parameter settings: The settings of the run, whose configuration file is consulted.
    /// - Returns: The default load options with the KM3 options of ``readOptions(settings:)``.
    public func ecoreLoadOptions(settings: SemanticsSettings) -> EcoreLoadOptions {
        EcoreLoadOptions(km3Options: readOptions(settings: settings))
    }
}
