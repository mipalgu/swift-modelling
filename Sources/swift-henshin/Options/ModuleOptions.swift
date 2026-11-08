//
// ModuleOptions.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ModellingCommandLine

/// The command line options with which every command that reads a module reads it.
///
/// They name the metamodels of the module, the character encoding of a Henshin Text
/// document, and whether progress is reported.
struct ModuleOptions: ParsableArguments, Sendable {
    /// The metamodels of the module and of the models.
    @OptionGroup var metamodelOptions: MetamodelOptions

    /// The character encoding of a Henshin Text document.
    @OptionGroup var encodingOptions: SourceEncodingOptions

    /// Whether progress and details are reported on standard error.
    @Flag(
        name: [.customShort("v"), .customLong(SwiftHenshinVocabulary.OptionName.verbose)],
        help: "Report progress and details on standard error")
    var verbose = false

    /// Creates the options with nothing given.
    init() {}

    /// A loader that reads modules as the options say.
    var loader: ModuleLoader {
        ModuleLoader(
            metamodels: metamodelOptions.metamodels, encoding: encodingOptions.explicitEncoding,
            log: Log(verbose: verbose))
    }
}
