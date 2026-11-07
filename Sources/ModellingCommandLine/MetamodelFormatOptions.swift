//
// MetamodelFormatOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore

/// The command line options that choose how metamodels in the formats that need them are read.
///
/// The options combine ``KM3Options``, for the data types of KM3 metamodels, and
/// ``GrammarImportOptions``, for metamodels imported from ASDL, Langium, Xtext and SDF3
/// grammars, into the options of a metamodel load. Commands include them with `@OptionGroup`
/// and pass ``ecoreLoadOptions`` or ``ecoreLoadOptions(settings:)`` wherever they read a
/// metamodel. Metamodels in formats that need no options, such as Ecore, are read alike either
/// way.
public struct MetamodelFormatOptions: ParsableArguments, Sendable {
    /// How the data types of a KM3 metamodel are read.
    @OptionGroup public var km3: KM3Options

    /// How metamodels are imported from grammars.
    @OptionGroup public var grammar: GrammarImportOptions

    /// Creates the options with nothing given.
    public init() {}

    /// The options with which metamodels are loaded, from the command line alone.
    ///
    /// Commands that read no configuration file use these options.
    public var ecoreLoadOptions: EcoreLoadOptions {
        var options = km3.ecoreLoadOptions
        grammar.apply(to: &options)
        return options
    }

    /// The options with which metamodels are loaded in a run.
    ///
    /// Each option is the one given on the command line, else the value of its key in the
    /// configuration file, else its default.
    ///
    /// - Parameter settings: The settings of the run, whose configuration file is consulted.
    /// - Returns: The options of the metamodel readers.
    public func ecoreLoadOptions(settings: SemanticsSettings) -> EcoreLoadOptions {
        var options = km3.ecoreLoadOptions(settings: settings)
        grammar.apply(to: &options, configuration: settings.configuration)
        return options
    }
}
