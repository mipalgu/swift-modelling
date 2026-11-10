//
// CreateCommand.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import Foundation
import ModellingCommandLine

/// Command for creating a model with a single root object.
///
/// The command writes a model whose only object is an instance of a class of a metamodel, with
/// no features set, as a starting point for editing a model by hand or by a program.
struct CreateCommand: AsyncParsableCommand {
    /// The name, summary and help of the `create` subcommand.
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a model with one root object of a metamodel class",
        discussion: """
            Writes a model whose only object is an instance of the class that --root-class \
            names, with no features set. The class must be a concrete class of one of the \
            metamodels given with --\(MetamodelOptions.optionName). The output format follows \
            from the extension of the output file unless --output-format is given.

            \(OutputEncodingOptions.discussion(writer: OutputEncodingVocabulary.created))

            \(SourceEncodingOptions.discussion(reader: EncodingVocabulary.createdMetamodels))

            \(ConfigurationFileOptions.discussion(keys: ConfigurationVocabulary.creationKeys))
            """
    )

    /// The metamodels that define the root class.
    @OptionGroup var metamodelOptions: MetamodelOptions

    /// How metamodels in KM3 and in grammar formats are read.
    @OptionGroup var formatOptions: MetamodelFormatOptions

    /// The character encoding of the metamodels in text formats.
    @OptionGroup var encodingOptions: SourceEncodingOptions

    /// The configuration file whose keys give the options that the command line leaves open.
    @OptionGroup var configurationOptions: ConfigurationFileOptions

    /// The character encoding of the files that the command writes.
    @OptionGroup var outputEncodingOptions: OutputEncodingOptions

    /// The name of the class of the root object.
    @Option(help: "The class of the root object")
    var rootClass: String

    /// The file to write.
    @Option(name: .shortAndLong, help: "The model file to write (.xmi or .json)")
    var output: String

    /// The output format override.
    @Option(help: "Output format (\(ConvertCommand.modelFormatNames)) - infer from extension if not specified")
    var outputFormat: String?

    /// Whether an existing file is replaced.
    @Flag(help: "Overwrite output file if it exists")
    var force = false

    /// Enable verbose output.
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose = false

    /// Checks that a metamodel is given.
    ///
    /// - Throws: A validation error of the argument parser if no metamodel is given.
    func validate() throws {
        guard metamodelOptions.isGiven else {
            throw ArgumentParser.ValidationError("Give the metamodel that defines the root class with --\(MetamodelOptions.optionName)")
        }
    }

    /// Executes the create command.
    ///
    /// - Throws: ``CreationError`` if the output exists, the class is unknown or abstract, or the
    ///   format cannot hold a model, or the error of a metamodel, the serialiser or the file system.
    ///   Also ``ModellingConfigurationError`` if the configuration file cannot be read or is not valid,
    ///   and `OutputFileError` if the encoding of the model cannot hold one of its characters.
    func run() async throws {
        let settings = try configurationOptions.settings()
        let loadOptions = formatOptions.ecoreLoadOptions(settings: settings, encodingOptions: encodingOptions)
        let url = URL(fileURLWithPath: output)
        if FileManager.default.fileExists(atPath: output) && !force {
            throw CreationError.outputExists(output)
        }
        let formatName = outputFormat ?? url.pathExtension
        guard let format = ModelFormat(fileExtension: formatName), ConvertCommand.modelFormats.contains(format) else {
            throw CreationError.unsupportedFormat(formatName)
        }
        let resourceSet =
            try await metamodelOptions.resourceSet(verbose: verbose, options: loadOptions) ?? ResourceSet()
        let catalogue = MetamodelCatalogue(roots: await ModelDocument.registeredMetamodels(of: resourceSet))
        guard let eClass = catalogue.classes.first(where: { $0.name == rootClass }) else {
            let concrete = catalogue.classes.filter { !$0.isAbstract && !$0.isInterface }.map(\.name)
            throw CreationError.unknownClass(rootClass, concrete)
        }
        guard !eClass.isAbstract && !eClass.isInterface else {
            throw CreationError.abstractClass(rootClass)
        }
        let resource = await resourceSet.createResource(uri: url.absoluteString)
        _ = await resource.add(DynamicEObject(eClass: eClass))
        try await OutputFile.save(
            resource, to: url, format: format, encoding: outputEncodingOptions.encoding(settings: settings))
        if verbose { print("Created a \(eClass.name) as the root object") }
        print("Model created: \(output)")
    }
}
