//
// AQLSemanticsOptions.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ArgumentParser
import ModellingCommandLine

/// The command line options that choose the behaviours of AQL expressions.
///
/// The options are the expression options that swift-mtl offers for the expressions of its
/// templates, with the same names, values and defaults, so that an expression behaves the same
/// in a template and on the command line of swift-aql. An option that is not given takes the
/// value of the configuration file, else that of the preset that `--semantics` chooses.
struct AQLSemanticsOptions: ParsableArguments, Sendable {
    /// The long names of the options, shared with swift-mtl.
    typealias OptionName = MTLSemanticsOptions.OptionName

    /// How a collection passed to an operation that adds an element is treated.
    @Option(
        name: .customLong(OptionName.collectionArguments),
        help: ArgumentHelp(
            "How a collection argument is added: \(AQLCollectionArguments.whole.rawValue) (the default) "
                + "or \(AQLCollectionArguments.firstElement.rawValue), as in version 0.6",
            valueName: MTLSemanticsOptions.valueList(AQLCollectionArguments.self)))
    var collectionArguments: AQLCollectionArguments?

    /// Whether sequences, ordered sets, sets and bags are told apart.
    @Option(
        name: .customLong(OptionName.collectionKinds),
        help: ArgumentHelp(
            "The kinds of collections: \(AQLCollectionKinds.distinguished.rawValue) (the default) "
                + "or \(AQLCollectionKinds.sequences.rawValue), as in version 0.6",
            valueName: MTLSemanticsOptions.valueList(AQLCollectionKinds.self)))
    var collectionKinds: AQLCollectionKinds?

    /// The collection that an arrow call on a single value sees.
    @Option(
        name: .customLong(OptionName.singleValueCollections),
        help: ArgumentHelp(
            "The collection of a single value in an arrow call: \(AQLSingleValueCollections.set.rawValue) "
                + "(the default) or \(AQLSingleValueCollections.sequence.rawValue), as in version 0.6",
            valueName: MTLSemanticsOptions.valueList(AQLSingleValueCollections.self)))
    var singleValueCollections: AQLSingleValueCollections?

    /// How the container of an object is found.
    @Option(
        name: .customLong(OptionName.containerLookup),
        help: ArgumentHelp(
            "How containers are found: \(AQLContainerLookup.resources.rawValue) (the default) "
                + "or \(AQLContainerLookup.registeredObjects.rawValue), as in version 0.6",
            valueName: MTLSemanticsOptions.valueList(AQLContainerLookup.self)))
    var containerLookup: AQLContainerLookup?

    /// Creates the options with nothing given, which leaves every behaviour to the preset.
    init() {}

    /// The behaviours of expressions that the options and the settings of a run select.
    ///
    /// Each behaviour is the option given on the command line, else the option in the
    /// configuration file of the settings, else that of their preset, exactly as for the
    /// expressions of swift-mtl.
    ///
    /// - Parameter settings: The preset and configuration file of the run.
    /// - Returns: The options of the expression language.
    func aqlOptions(settings: SemanticsSettings) -> AQLOptions {
        var options = MTLSemanticsOptions()
        options.collectionArguments = collectionArguments
        options.collectionKinds = collectionKinds
        options.singleValueCollections = singleValueCollections
        options.containerLookup = containerLookup
        return options.aqlOptions(settings: settings)
    }
}
