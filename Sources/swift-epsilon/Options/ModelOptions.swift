//
// ModelOptions.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ModellingCommandLine

/// The command line options that bind models and name their metamodels.
///
/// Every command of swift-epsilon reads models with `--model name=file` and their metamodels
/// with `--metamodel`, and may store a model that it changed with `--store`.
struct ModelOptions: ParsableArguments, Sendable {
    /// The models that are read, as `name=file` or `name,alias=file`.
    @Option(
        name: .customLong(SwiftEpsilonVocabulary.OptionName.model),
        help: ArgumentHelp(
            "A model to read, as name=file or name,alias=file (can be specified multiple times)",
            discussion: """
                Programs refer to the model by its name or an alias, as in Bank!Account.all. A \
                model is read in the format of its extension or contents (XMI, JSON or UML), and \
                is not written unless --\(SwiftEpsilonVocabulary.OptionName.store) names it.
                """,
            valueName: SwiftEpsilonVocabulary.ValueName.model))
    var models: [String] = []

    /// The models that are written after a successful run.
    @Option(
        name: .customLong(SwiftEpsilonVocabulary.OptionName.store),
        help: ArgumentHelp(
            "Store a model read with --\(SwiftEpsilonVocabulary.OptionName.model) after a successful run, "
                + "in its own file or in the file given (can be specified multiple times)",
            valueName: SwiftEpsilonVocabulary.ValueName.store))
    var stores: [String] = []

    /// The metamodels of the models.
    @OptionGroup var metamodelOptions: MetamodelOptions

    /// How metamodels in KM3 and in grammar formats are read.
    @OptionGroup var formatOptions: MetamodelFormatOptions

    /// How stored XMI models spell references into themselves.
    @OptionGroup var referenceStyleOptions: ReferenceStyleOptions

    /// Creates the options with nothing given.
    init() {}
}

/// The command line option that binds target models, which are created empty and stored.
struct TargetOptions: ParsableArguments, Sendable {
    /// The models that are created and stored, as `name=file` or `name,alias=file`.
    @Option(
        name: .customLong(SwiftEpsilonVocabulary.OptionName.target),
        help: ArgumentHelp(
            "A model to create empty and store after a successful run, as name=file or "
                + "name,alias=file (can be specified multiple times)",
            discussion: """
                The model is not read: it starts empty, with the metamodels given with \
                --\(MetamodelOptions.optionName) that no model read with \
                --\(SwiftEpsilonVocabulary.OptionName.model) uses, and is written in the format \
                of its extension (XMI, JSON or UML) once the run has succeeded.
                """,
            valueName: SwiftEpsilonVocabulary.ValueName.model))
    var targets: [String] = []

    /// Creates the option with no targets.
    init() {}
}

/// The command line options that control how a program runs.
///
/// They pass parameters to the program, limit the depth of its operation calls, choose the
/// configuration file and the character encoding of its source files, and turn on verbose
/// output.
struct ExecutionOptions: ParsableArguments, Sendable {
    /// The parameters of the program, as `name=value`.
    @Option(
        name: .customLong(SwiftEpsilonVocabulary.OptionName.parameter),
        help: ArgumentHelp(
            "A parameter for the program as name=value (can be specified multiple times)",
            discussion: """
                The program reads the parameter as a global variable of that name. The value is \
                a Boolean for true or false, an Integer for a whole number, a Real for another \
                number and a String otherwise.
                """,
            valueName: SwiftEpsilonVocabulary.ValueName.parameter))
    var parameters: [String] = []

    /// The maximum depth of nested operation calls.
    @Option(
        name: .customLong(SwiftEpsilonVocabulary.OptionName.maximumCallDepth),
        help: ArgumentHelp(
            "The maximum depth of nested operation calls before the program stops with an error "
                + "(default: \(SwiftEpsilonVocabulary.defaultMaximumCallDepth))",
            valueName: SwiftEpsilonVocabulary.ValueName.maximumCallDepth))
    var maximumCallDepth: Int = SwiftEpsilonVocabulary.defaultMaximumCallDepth

    /// Whether progress is reported in detail on standard error.
    @Flag(
        name: [.customShort("v"), .customLong(SwiftEpsilonVocabulary.OptionName.verbose)],
        help: "Report each step on standard error")
    var verbose: Bool = false

    /// The configuration file and the container lookup scope of the models.
    @OptionGroup(title: "Configuration")
    var semanticsOptions: SemanticsOptions

    /// The character encoding of the source files.
    @OptionGroup var encodingOptions: SourceEncodingOptions

    /// Creates the options with nothing given.
    init() {}

    /// Checks that the limit of nested operation calls is positive.
    ///
    /// - Throws: A validation error if the limit is less than one.
    func validate() throws {
        guard maximumCallDepth >= 1 else {
            throw ValidationError("--\(SwiftEpsilonVocabulary.OptionName.maximumCallDepth) must be at least 1")
        }
    }
}
