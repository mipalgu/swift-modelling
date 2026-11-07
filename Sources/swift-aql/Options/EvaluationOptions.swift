//
// EvaluationOptions.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ArgumentParser
import ECore
import ModellingCommandLine

/// The command line options that every command of swift-aql shares.
///
/// They name the metamodels of the models, select the object bound to `self`, choose how
/// expressions behave and how unset features read, and name the encoding of an expression
/// file, with the same options and defaults as the other tools of the package.
struct EvaluationOptions: ParsableArguments, Sendable {
    /// The object bound to `self`, by identifier, fragment path or name.
    @Option(
        name: .customLong(SwiftAQLVocabulary.OptionName.context),
        help: ArgumentHelp(
            "The object to bind to self, by its xmi:id, its fragment path or its name",
            discussion: """
                The value is first looked up as an identifier that the model declares with \
                xmi:id, then, if it starts with a slash, as a fragment path such as \
                /0/@departments.1, and finally as the label of an object, which is the value of \
                its name attribute or its first string attribute. Without this option, self is \
                the first root object of the first model.
                """,
            valueName: SwiftAQLVocabulary.ValueName.context))
    var context: String?

    /// The metamodels of the models.
    @OptionGroup var metamodelOptions: MetamodelOptions

    /// How the data types of a KM3 metamodel are read.
    @OptionGroup var km3Options: KM3Options

    /// How expressions read features that a model does not set.
    @OptionGroup(title: "Evaluation")
    var unsetFeatureOptions: UnsetFeatureOptions

    /// The behaviours of expressions.
    @OptionGroup(title: "Evaluation")
    var aqlSemanticsOptions: AQLSemanticsOptions

    /// The preset of the behaviours, standard or that of version 0.6, and the configuration file.
    @OptionGroup(title: "Evaluation")
    var semanticsOptions: SemanticsOptions

    /// The character encoding of an expression file.
    @OptionGroup var encodingOptions: SourceEncodingOptions

    /// Creates the options with nothing given.
    init() {}
}
