//
// ProgramOptions.swift
// swift-xtend
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ModellingCommandLine

/// The command line options that both commands of swift-xtend share.
///
/// They name the Xtend source, the models and metamodels it works on, the class to use, and
/// the encoding of the source files, with the same options and defaults as the other tools of
/// the package.
struct ProgramOptions: ParsableArguments, Sendable {
    /// The Xtend source file.
    @Argument(help: ArgumentHelp("The Xtend source file", valueName: SwiftXtendVocabulary.ValueName.source))
    var source: String

    /// Further Xtend source files that belong to the same program.
    @Option(
        name: .customLong(SwiftXtendVocabulary.OptionName.include),
        help: ArgumentHelp(
            "An additional Xtend source file (can be specified multiple times)",
            valueName: SwiftXtendVocabulary.ValueName.source))
    var includes: [String] = []

    /// The models the program works on.
    @Option(
        name: .customLong(SwiftXtendVocabulary.OptionName.model),
        help: ArgumentHelp(
            "A model to work on (can be specified multiple times)",
            discussion: """
                The first model is the input of the method or generator; the objects of further \
                models can be reached by the program, as well. Models can be in any model format \
                of the registry, such as XMI, JSON or UML, chosen by their extension or contents.
                """,
            valueName: SwiftXtendVocabulary.ValueName.model))
    var models: [String] = []

    /// The class to use.
    @Option(
        name: .customLong(SwiftXtendVocabulary.OptionName.className),
        help: ArgumentHelp(
            "The class to use (default: the only class of the source; for generate, the first class with a generator method)",
            valueName: SwiftXtendVocabulary.ValueName.className))
    var className: String?

    /// The metamodels of the models.
    @OptionGroup var metamodelOptions: MetamodelOptions

    /// How metamodels in KM3 and in grammar formats are read.
    @OptionGroup var formatOptions: MetamodelFormatOptions

    /// The preset of the behaviours and the configuration file.
    @OptionGroup(title: "Evaluation")
    var semanticsOptions: SemanticsOptions

    /// The character encoding of the Xtend source files.
    @OptionGroup var encodingOptions: SourceEncodingOptions

    /// Whether progress is reported on standard error.
    @Flag(name: [.customShort("v"), .customLong(SwiftXtendVocabulary.OptionName.verbose)], help: "Report progress on standard error")
    var verbose: Bool = false

    /// Creates the options with nothing given.
    init() {}
}
