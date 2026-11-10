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

    /// The configuration file whose keys give the options that the command line leaves open.
    @OptionGroup var configurationOptions: ConfigurationFileOptions

    /// Whether progress and details are reported on standard error.
    @Flag(
        name: [.customShort("v"), .customLong(SwiftHenshinVocabulary.OptionName.verbose)],
        help: "Report progress and details on standard error")
    var verbose = false

    /// Creates the options with nothing given.
    init() {}

    /// A loader that reads modules as the command line alone says.
    var loader: ModuleLoader {
        loader(settings: SemanticsSettings())
    }

    /// The settings of a run, with the configuration file that the options select.
    ///
    /// - Returns: The settings, whose configuration holds the file, if any.
    /// - Throws: ``ModellingConfigurationError`` if the file cannot be read or is not valid.
    func settings() throws -> SemanticsSettings {
        try configurationOptions.settings()
    }

    /// A loader that reads modules as the options of a run say.
    ///
    /// - Parameter settings: The settings of the run, whose configuration file gives the
    ///   encoding of Henshin Text documents unless `--encoding` does.
    /// - Returns: The loader.
    func loader(settings: SemanticsSettings) -> ModuleLoader {
        ModuleLoader(
            metamodels: metamodelOptions.metamodels, encoding: encodingOptions.encoding(settings: settings),
            log: Log(verbose: verbose))
    }
}
