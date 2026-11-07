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
            inferring the formats from the file extensions unless --input-format or \
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
            the warnings are followed by a hint to give one. Warnings do not change the exit \
            status.

            \(ReferenceStyleOptions.discussion(written: "outputs"))
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
        name: .long, help: "Input format (xmi, json, ecore) - auto-detect from extension if not specified")
    var inputFormat: String?

    /// Output format override.
    @Option(name: .long, help: "Output format (xmi, json, ecore) - infer from extension if not specified")
    var outputFormat: String?

    /// Enable verbose output.
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    /// Overwrite output file if it exists.
    @Flag(help: "Overwrite output file if it exists")
    var force: Bool = false

    /// The metamodels of the model.
    @OptionGroup var metamodelOptions: MetamodelOptions

    /// How the data types of a KM3 metamodel are read.
    @OptionGroup var km3Options: KM3Options

    /// How an XMI output spells references into itself.
    @OptionGroup var referenceStyleOptions: ReferenceStyleOptions

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
        let resourceSet = try await metamodelOptions.resourceSet(
            verbose: verbose, options: km3Options.ecoreLoadOptions)

        // Load input, collecting what the parser could not keep
        let readFormat = try Self.format(named: inputFormatToUse) {
            ConversionError.unsupportedInputFormat($0)
        }
        let writeFormat = try Self.format(named: outputFormatToUse) {
            ConversionError.unsupportedOutputFormat($0)
        }
        if verbose { print("Reading \(readFormat.description)...") }
        let loaded = try await ModelIO.load(
            url: inputURL, format: readFormat, resourceSet: resourceSet ?? ResourceSet(),
            options: ModelIO.LoadOptions(requiresMetamodel: false, ecoreLoadOptions: km3Options.ecoreLoadOptions))
        FileDiagnosticReport.write(await loaded.resource.loadDiagnostics, file: inputPath)
        let resource = loaded.resource
        var diagnostics = loaded.diagnostics
        try Self.checkOutput(writeFormat, isMetamodel: !loaded.packages.isEmpty, input: inputURL.lastPathComponent)
        if validate {
            try await check(loaded, at: inputURL, in: resourceSet ?? ResourceSet())
        }

        // Save output
        if verbose { print("Writing \(writeFormat.description)...") }
        try await ModelIO.save(
            resource, to: outputURL, format: writeFormat,
            xmiOptions: referenceStyleOptions.serializationOptions, diagnostics: &diagnostics)
        withExtendedLifetime(resourceSet) {}
        ConversionWarningReport.write(diagnostics, metamodelGiven: metamodelOptions.isGiven)

        if verbose {
            let objects = await resource.getRootObjects()
            print("Converted \(objects.count) object(s) successfully")
        }

        print("Conversion completed: \(outputPath)")
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

    /// Validates a loaded model and prints what validation found.
    ///
    /// - Parameters:
    ///   - loaded: The loaded model.
    ///   - url: The location of the model.
    ///   - resourceSet: The resource set with the registered metamodels.
    /// - Throws: ``ConversionError/invalidModel(_:)`` if the model has an error.
    private func check(_ loaded: ModelIO.Loaded, at url: URL, in resourceSet: ResourceSet) async throws {
        let document = ModelDocument(
            path: inputPath, url: url, format: loaded.format, resource: loaded.resource, resourceSet: resourceSet,
            packages: loaded.packages, metamodels: await ModelDocument.registeredMetamodels(of: resourceSet),
            diagnostics: loaded.diagnostics)
        let outcome = await ModelChecker(document: document, options: ValidationOptions()).check()
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

    /// The formats in which a metamodel is read and written.
    ///
    /// They are Ecore and JSON, followed by every other format whose built-in handler may hold
    /// a metamodel, such as KM3.
    static let metamodelFormats: [ModelFormat] = formats([.ecore, .json]) { $0 != .model }

    /// The formats in which a model is read and written.
    ///
    /// They are XMI and JSON, followed by every other format whose built-in handler may hold
    /// a model.
    static let modelFormats: [ModelFormat] = formats([.xmi, .json]) { $0 != .metamodel }

    /// The formats whose built-in handlers have a role, the preferred ones first.
    ///
    /// - Parameters:
    ///   - preferred: The formats that come first, in order.
    ///   - accepts: Whether the role of a handler qualifies its format.
    /// - Returns: The preferred formats, followed by the other qualifying formats.
    private static func formats(_ preferred: [ModelFormat], where accepts: (ModelFormatRole) -> Bool) -> [ModelFormat] {
        let others = ModelFormatRegistry.builtInHandlers.filter { accepts($0.role) }.compactMap(\.format)
        return preferred + others.filter { !preferred.contains($0) }
    }

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
    /// - Throws: ``ConversionError/metamodelOutputFormat(_:format:)`` for a metamodel in a
    ///   format other than ``metamodelFormats``, or ``ConversionError/modelOutputFormat(_:format:)``
    ///   for a model in a format other than ``modelFormats``.
    static func checkOutput(_ format: ModelFormat, isMetamodel: Bool, input: String) throws {
        if isMetamodel, !metamodelFormats.contains(format) {
            throw ConversionError.metamodelOutputFormat(input, format: format.rawValue)
        }
        if !isMetamodel, !modelFormats.contains(format) {
            throw ConversionError.modelOutputFormat(input, format: format.rawValue)
        }
    }
}
