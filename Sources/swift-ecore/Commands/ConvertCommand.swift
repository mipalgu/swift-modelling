//
// ConvertCommand.swift
// ECore
//
//  Created by Rene Hexel on 3/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import Foundation
import ModellingCommandLine
import MultiLevel

/// Command for converting between model formats and between metamodel formats.
///
/// The convert command supports bidirectional conversion between XMI and JSON formats,
/// preserving model structure and data integrity, and between Ecore metamodels (`.ecore`) and
/// JSON metamodels. A JSON file is a metamodel when its roots are Ecore packages, whatever its
/// name. References to other metamodel files keep their file names. With one or more
/// `--metamodel` files, the model is read with the classes of those metamodels and written
/// with package-qualified classes and typed references. Whatever cannot be kept is reported as a warning on standard
/// error, and `--reference-style` chooses how an XMI output spells references into itself.
struct ConvertCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "convert",
        abstract: "Convert models (XMI <-> JSON) and metamodels (Ecore <-> JSON)",
        discussion: """
            Converts a model between XMI and JSON, or a metamodel between Ecore and JSON, \
            choosing the input format from the extension and the contents of the file unless \
            --input-format is given, and the output format from its extension unless \
            --output-format is given. The output file is the second argument or the value of \
            --output. JSON is written indented, with the keys of every object of a model in \
            alphabetical order.

            A JSON file whose roots are Ecore packages is a metamodel, whatever its name. A \
            metamodel is written as .ecore, as JSON or as KM3 (.km3), and a model as XMI or JSON, \
            so a metamodel cannot be written as an XMI model, nor a model as .ecore. A KM3 \
            metamodel is read as --\(KM3Options.optionName) says, and what KM3 cannot express, \
            such as annotations and default values, is reported when a metamodel is written as \
            KM3; namespace URIs are not written. References to \
            other metamodel files keep their file names, so a converted metamodel still refers \
            to the .ecore or JSON files it referred to, and swift-ecore reads either format. To convert a set of \
            metamodels that refer to each other, convert every file into the same directory, \
            then replace the extension in the references, for example with \
            sed -i.bak 's/base\\.ecore#/base.json#/g' shop.json for a shop.json that refers \
            to base.ecore.

            --validate checks the model or metamodel as the validate command does and writes \
            nothing if it has an error.

            --\(MetamodelOptions.optionName) names an Ecore metamodel of the model. \
            \(MetamodelOptions.effect)

            Information that cannot be kept, such as a class that no metamodel defines or a \
            reference that cannot be written as a fragment, is reported on standard error as a \
            line starting with '\(ConversionWarningReport.warningPrefix)'. Without a metamodel, \
            the warnings of converting a model are followed by a hint to give one. Warnings do \
            not change the exit status, but an error of reading the input, such as a syntax \
            error of a grammar, stops the conversion.

            \(ReferenceStyleOptions.discussion(written: "outputs"))

            \(SourceEncodingOptions.discussion(reader: EncodingVocabulary.encodedDocuments, configurable: false))
            """
    )

    /// Input file path.
    @Argument(help: "Input file path")
    var inputPath: String

    /// Output file path, given as the second argument.
    @Argument(help: "Output file path (or give it with --output)")
    var outputArgument: String?

    /// Output file path, given as an option.
    @Option(name: .shortAndLong, help: "Output file path, instead of the second argument")
    var output: String?

    /// Whether the model is validated before it is written.
    @Flag(help: "Validate the model, against its metamodels if given, and write nothing if it is invalid")
    var validate = false

    /// Input format override.
    @Option(
        name: .long,
        help: "Input format (\(ConvertCommand.readableFormatNames)) - detected from the extension and contents if not specified")
    var inputFormat: String?

    /// Output format override.
    @Option(
        name: .long,
        help: "Output format (\(ConvertCommand.writableFormatNames)) - infer from extension if not specified")
    var outputFormat: String?

    /// Enable verbose output.
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    /// Overwrite output file if it exists.
    @Flag(help: "Overwrite output file if it exists")
    var force: Bool = false

    /// The metamodels of the model.
    @OptionGroup var metamodelOptions: MetamodelOptions

    /// How metamodels in KM3 and in grammar formats are read.
    @OptionGroup var formatOptions: MetamodelFormatOptions

    /// The character encoding of the documents in text formats.
    @OptionGroup var encodingOptions: SourceEncodingOptions

    /// The options with which the documents and metamodels are read, in the encoding of
    /// `--encoding`.
    private var loadOptions: EcoreLoadOptions { formatOptions.ecoreLoadOptions(encoding: encodingOptions.explicitEncoding) }

    /// The Complete OCL documents that constrain the metamodels.
    @OptionGroup var completeOCLOptions: CompleteOCLOptions

    /// Which references of a multi-level model may cross levels.
    @OptionGroup var levelCrossingOptions: LevelCrossingOptions

    /// How an XMI output spells references into itself.
    @OptionGroup var referenceStyleOptions: ReferenceStyleOptions

    /// The long name of the option that selects the level of a multi-level model to export.
    static let levelOption = "level"

    /// The level of a multi-level model whose Ecore metamodel is written.
    @Option(
        name: .customLong(ConvertCommand.levelOption),
        help: ArgumentHelp(
            "Write the Ecore metamodel whose instances live at this level of a multi-level model, in a metamodel format",
            valueName: "level"))
    var level: Int?

    /// Executes the convert command.
    ///
    /// Converts the input file to the output format based on file extensions, and reports
    /// what the conversion could not keep as warnings on standard error. A metamodel is written
    /// as `.ecore` or as JSON, and a model as XMI or JSON.
    ///
    /// - Throws: `ConversionError` if conversion fails, or the output format does not suit a
    ///   metamodel or a model.
    func run() async throws {
        let outputPath = try resolvedOutputPath()
        if verbose {
            print("Converting: \(inputPath) -> \(outputPath)")
        }

        let inputURL = URL(fileURLWithPath: inputPath)
        let outputURL = URL(fileURLWithPath: outputPath)

        guard FileManager.default.fileExists(atPath: inputPath) else {
            throw ConversionError.fileNotFound(inputPath)
        }

        if FileManager.default.fileExists(atPath: outputPath) && !force {
            throw ConversionError.outputExists(outputPath)
        }

        // Determine input format (explicit flag or infer from extension)
        let inputFormatToUse: String
        if let explicitFormat = inputFormat {
            inputFormatToUse = explicitFormat.lowercased()
            if verbose {
                print("Using explicit input format: \(inputFormatToUse)")
            }
        } else {
            inputFormatToUse = inputURL.pathExtension.lowercased()
            if verbose {
                print("Inferring input format from extension: \(inputFormatToUse)")
            }
        }

        // Determine output format (explicit flag or infer from extension)
        let outputFormatToUse: String
        if let explicitFormat = outputFormat {
            outputFormatToUse = explicitFormat.lowercased()
            if verbose {
                print("Using explicit output format: \(outputFormatToUse)")
            }
        } else {
            outputFormatToUse = outputURL.pathExtension.lowercased()
            if verbose {
                print("Inferring output format from extension: \(outputFormatToUse)")
            }
        }

        // Register metamodels, if any, for both reading and writing
        await MultiLevelSupport.registerFormats()
        var resourceSet = try await metamodelOptions.resourceSet(
            applying: completeOCLOptions.documents, verbose: verbose, options: loadOptions)
        let linguistic = MultiLevelSupport.holdsLinguisticInstances(inputURL)
        if linguistic {
            let linguisticSet = resourceSet ?? ResourceSet()
            await MultiLevelSupport.registerLinguisticMetamodel(in: linguisticSet)
            resourceSet = linguisticSet
        }

        // Load input, collecting what the parser could not keep
        let readFormat = try await readFormat(named: inputFormatToUse)
        let writeFormat = try Self.format(named: outputFormatToUse) {
            ConversionError.unsupportedOutputFormat($0)
        }
        if readFormat == .metadepth, resourceSet == nil {
            resourceSet = ResourceSet()
        }
        if verbose { print("Reading \(readFormat.description)...") }
        let loaded = try await ModelIO.load(
            url: inputURL, format: readFormat, resourceSet: resourceSet ?? ResourceSet(),
            options: ModelIO.LoadOptions(requiresMetamodel: false, ecoreLoadOptions: loadOptions))
        try DocumentError.report(await loaded.resource.loadDiagnostics, file: inputPath)
        var resource = loaded.resource
        var diagnostics = loaded.diagnostics
        let deepModel = readFormat == .metadepth || linguistic
            ? await MultiLevelSupport.deepModel(in: loaded.resource) : nil
        if let level {
            guard let deepModel else { throw ConversionError.levelWithoutDeepModel(inputURL.lastPathComponent) }
            resource = try await Self.levelMetamodel(of: deepModel, level: level, in: resourceSet ?? ResourceSet())
        } else if let deepModel, !Self.modelFormats.contains(writeFormat), MetamodelRegistration.isWritable(writeFormat) {
            throw ConversionError.deepModelNeedsLevel(
                inputURL.lastPathComponent, format: writeFormat.rawValue, levels: deepModel.levelNumbers)
        }
        var convertedToMetamodel = false
        if level == nil, loaded.packages.isEmpty, Self.metamodelFormats.contains(writeFormat),
            !Self.modelFormats.contains(writeFormat),
            await MetamodelRegistration.documentHandler(at: inputPath) is any MetamodelConvertingModelFormatHandler
        {
            resource = try await Self.convertedMetamodel(
                at: inputPath, options: loadOptions, in: resourceSet ?? ResourceSet())
            convertedToMetamodel = true
        }
        let isMetamodel = level != nil || convertedToMetamodel || !loaded.packages.isEmpty
        try Self.checkOutput(writeFormat, isMetamodel: isMetamodel, input: inputURL.lastPathComponent)
        if completeOCLOptions.isGiven && !metamodelOptions.isGiven {
            try await MetamodelRegistration.applyCompleteOCL(
                completeOCLOptions.documents, to: loaded.packages.isEmpty ? [] : [resource],
                in: resourceSet ?? ResourceSet(), verbose: verbose, encoding: loadOptions.textEncoding)
        }
        if validate {
            try await check(loaded, deepModel: deepModel, at: inputURL, in: resourceSet ?? ResourceSet())
        }

        // Save output
        if verbose { print("Writing \(writeFormat.description)...") }
        try await ModelIO.save(
            resource, to: outputURL, format: writeFormat,
            xmiOptions: referenceStyleOptions.serializationOptions, diagnostics: &diagnostics)
        withExtendedLifetime(resourceSet) {}
        ConversionWarningReport.write(
            diagnostics, metamodelGiven: metamodelOptions.isGiven || deepModel != nil || isMetamodel)

        if verbose {
            let objects = await resource.getRootObjects()
            print("Converted \(objects.count) object(s) successfully")
        }

        print("Conversion completed: \(outputPath)")
    }

    /// The format in which the input is read.
    ///
    /// Without `--input-format`, the format registry chooses the format from the extension and
    /// the contents of the file, as the other commands do, so that a file whose extension names
    /// no format, such as a Stratego signature (`.str`), is still recognised by its contents.
    ///
    /// - Parameter name: The name of the format given with `--input-format`, or the extension
    ///   of the input file, in lower case.
    /// - Returns: The format.
    /// - Throws: ``ConversionError/unsupportedInputFormat(_:)`` if the name denotes no format and
    ///   the contents of the file name none either.
    func readFormat(named name: String) async throws -> ModelFormat {
        let named = ModelFormat(fileExtension: name)
        guard inputFormat == nil, let recognised = await MetamodelRegistration.documentHandler(at: inputPath)?.format else {
            return try named ?? Self.format(named: name) { ConversionError.unsupportedInputFormat($0) }
        }
        if verbose, recognised != named { print("Recognised input format from contents: \(recognised.rawValue)") }
        return recognised
    }

    /// The output path, from the second argument or the `--output` option.
    ///
    /// - Returns: The path.
    /// - Throws: ``ConversionError/outputRequired`` unless exactly one of the two is given.
    func resolvedOutputPath() throws -> String {
        switch (outputArgument, output) {
        case (let path?, nil), (nil, let path?): return path
        default: throw ConversionError.outputRequired
        }
    }

    /// The metamodel that a model of a format such as UML converts into, in a new resource.
    ///
    /// A UML class model is read as the metamodel that it describes, as `--metamodel` reads it.
    ///
    /// - Parameters:
    ///   - path: The path of the model.
    ///   - options: The options with which metamodels are read.
    ///   - resourceSet: The resource set that receives the resource.
    /// - Returns: The resource, whose roots are the packages of the metamodel.
    /// - Throws: The error of the reader.
    static func convertedMetamodel(
        at path: String, options: EcoreLoadOptions, in resourceSet: ResourceSet
    ) async throws -> Resource {
        let packages = try await MetamodelRegistration.loadPackages(at: path, options: options)
        let resource = await resourceSet.createResource(uri: URL(fileURLWithPath: path).absoluteString + "#metamodel")
        for package in packages { await resource.add(package) }
        return resource
    }

    /// The Ecore metamodel of a level of a multi-level model, in a new resource.
    ///
    /// - Parameters:
    ///   - model: The multi-level model.
    ///   - level: The level whose metamodel is exported.
    ///   - resourceSet: The resource set that receives the resource.
    /// - Returns: The resource, whose only root is the package of the level.
    /// - Throws: ``ConversionError/noSuchLevel(_:levels:)`` if the model has no such level.
    static func levelMetamodel(of model: DeepModel, level: Int, in resourceSet: ResourceSet) async throws -> Resource {
        guard model.levelNumbers.contains(level), let package = try? model.ecorePackage(forLevel: level) else {
            throw ConversionError.noSuchLevel(level, levels: model.levelNumbers)
        }
        let resource = await resourceSet.createResource(uri: package.nsURI)
        await resource.add(package)
        return resource
    }

    /// Validates a loaded model and prints what validation found.
    ///
    /// - Parameters:
    ///   - loaded: The loaded model.
    ///   - deepModel: The multi-level model of the input, if it holds one.
    ///   - url: The location of the model.
    ///   - resourceSet: The resource set with the registered metamodels.
    /// - Throws: ``ConversionError/invalidModel(_:)`` if the model has an error.
    private func check(
        _ loaded: ModelIO.Loaded, deepModel: DeepModel?, at url: URL, in resourceSet: ResourceSet
    ) async throws {
        var document = ModelDocument(
            path: inputPath, url: url, format: loaded.format, resource: loaded.resource, resourceSet: resourceSet,
            packages: loaded.packages, metamodels: await ModelDocument.registeredMetamodels(of: resourceSet),
            diagnostics: loaded.diagnostics)
        document.deepModel = deepModel
        let options = ValidationOptions(levelCrossing: levelCrossingOptions.mode)
        let outcome = await ModelChecker(document: document, options: options).check()
        let report = ValidationReport(
            document: document, metamodelPaths: metamodelOptions.metamodels, strict: false,
            findings: outcome.findings, abstractClasses: nil, constraints: outcome.constraints)
        print(report.text(verbose: verbose), terminator: "")
        guard report.valid else {
            StandardOutput.flush()
            throw ConversionError.invalidModel(report.errors)
        }
        if verbose { print("Validation completed successfully") }
    }

    /// The formats in which a metamodel is written.
    ///
    /// They are Ecore and JSON, followed by every other format whose built-in handler may hold
    /// a metamodel and can write it, such as KM3 or EMOF. Formats that are only read, such as
    /// Langium, are not among them.
    static let metamodelFormats: [ModelFormat] = MetamodelRegistration.writableFormats(
        preferring: [.ecore, .json]) { $0 != .model }

    /// The formats in which a model is written.
    ///
    /// They are XMI and JSON, followed by every other format whose built-in handler may hold
    /// a model and can write it, such as UML.
    static let modelFormats: [ModelFormat] = MetamodelRegistration.writableFormats(
        preferring: [.xmi, .json]) { $0 != .metamodel }

    /// The formats that can be read, named for the help of `--input-format`.
    static let readableFormatNames = ModelFormat.allCases.map(\.rawValue).joined(separator: ", ")

    /// The formats that can be written, named for the help of `--output-format`.
    static let writableFormatNames = ModelFormat.allCases.filter(MetamodelRegistration.isWritable)
        .map(\.rawValue).joined(separator: ", ")

    /// The formats in which a model is written, named for the help of a command.
    static let modelFormatNames = modelFormats.map(\.rawValue).joined(separator: ", ")

    /// The format that a format name denotes.
    ///
    /// - Parameters:
    ///   - name: The name of the format, in lower case, such as `xmi`, `json` or `ecore`.
    ///   - unsupported: Creates the error for a name that denotes no format.
    /// - Returns: The format.
    /// - Throws: The error of `unsupported` for any other name.
    static func format(named name: String, unsupported: (String) -> ConversionError) throws -> ModelFormat {
        guard let format = ModelFormat(fileExtension: name) else { throw unsupported(name) }
        return format
    }

    /// Checks that a format can hold what a file holds.
    ///
    /// - Parameters:
    ///   - format: The format of the output.
    ///   - isMetamodel: Whether the input is a metamodel rather than a model.
    ///   - input: The name of the input file, for the error.
    /// - Throws: ``ConversionError/readOnlyOutputFormat(_:format:isMetamodel:)`` for a format
    ///   that is only read, such as Langium, ``ConversionError/metamodelOutputFormat(_:format:)``
    ///   for a metamodel in a format other than ``metamodelFormats``, or
    ///   ``ConversionError/modelOutputFormat(_:format:)`` for a model in a format other than
    ///   ``modelFormats``.
    static func checkOutput(_ format: ModelFormat, isMetamodel: Bool, input: String) throws {
        if !MetamodelRegistration.isWritable(format) {
            throw ConversionError.readOnlyOutputFormat(input, format: format, isMetamodel: isMetamodel)
        }
        if isMetamodel, !metamodelFormats.contains(format) {
            throw ConversionError.metamodelOutputFormat(input, format: format.rawValue)
        }
        if !isMetamodel, !modelFormats.contains(format) {
            throw ConversionError.modelOutputFormat(input, format: format.rawValue)
        }
    }
}
