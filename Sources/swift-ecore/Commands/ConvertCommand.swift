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

/// Command for converting between model formats.
///
/// The convert command supports bidirectional conversion between XMI and JSON formats,
/// preserving model structure and data integrity. With one or more `--metamodel` files, the
/// model is read with the classes of those metamodels and written with package-qualified
/// classes and typed references. Whatever cannot be kept is reported as a warning on standard
/// error, and `--reference-style` chooses how an XMI output spells references into itself.
struct ConvertCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "convert",
        abstract: "Convert between model formats (XMI <-> JSON)",
        discussion: """
            Converts a model between XMI and JSON, inferring the formats from the file \
            extensions unless --input-format or --output-format is given.

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

    /// Output file path.
    @Argument(help: "Output file path")
    var outputPath: String

    /// Input format override.
    @Option(
        name: .long, help: "Input format (xmi, json) - auto-detect from extension if not specified")
    var inputFormat: String?

    /// Output format override.
    @Option(name: .long, help: "Output format (xmi, json) - infer from extension if not specified")
    var outputFormat: String?

    /// Enable verbose output.
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    /// Overwrite output file if it exists.
    @Flag(help: "Overwrite output file if it exists")
    var force: Bool = false

    /// The metamodels of the model.
    @OptionGroup var metamodelOptions: MetamodelOptions

    /// How an XMI output spells references into itself.
    @OptionGroup var referenceStyleOptions: ReferenceStyleOptions

    /// Executes the convert command.
    ///
    /// Converts the input file to the output format based on file extensions, and reports
    /// what the conversion could not keep as warnings on standard error.
    ///
    /// - Throws: `ConversionError` if conversion fails.
    func run() async throws {
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
        let resourceSet = try await metamodelOptions.resourceSet(verbose: verbose)

        // Load input, collecting what the parser could not keep
        let resource: Resource
        var diagnostics = ConversionDiagnostics()

        switch inputFormatToUse {
        case "xmi":
            if verbose { print("Reading XMI...") }
            let parser = XMIParser(resourceSet: resourceSet)
            resource = try await parser.parse(inputURL)
            diagnostics.merge(await parser.diagnostics)
        case "json":
            if verbose { print("Reading JSON...") }
            let parser = JSONParser(resourceSet: resourceSet)
            resource = try await parser.parse(inputURL)
            diagnostics.merge(await parser.diagnostics)
        default:
            throw ConversionError.unsupportedInputFormat(inputFormatToUse)
        }

        // Save output
        let content: String
        switch outputFormatToUse {
        case "xmi":
            if verbose { print("Writing XMI...") }
            let serializer = XMISerializer(options: referenceStyleOptions.serializationOptions)
            content = try await serializer.serialize(resource, relativeTo: outputURL, diagnostics: &diagnostics)
        case "json":
            if verbose { print("Writing JSON...") }
            let serializer = JSONSerializer()
            content = try await serializer.serialize(resource, diagnostics: &diagnostics)
        default:
            throw ConversionError.unsupportedOutputFormat(outputFormatToUse)
        }
        try content.write(to: outputURL, atomically: true, encoding: .utf8)
        withExtendedLifetime(resourceSet) {}
        ConversionWarningReport.write(diagnostics, metamodelGiven: metamodelOptions.isGiven)

        if verbose {
            let objects = await resource.getRootObjects()
            print("Converted \(objects.count) object(s) successfully")
        }

        print("Conversion completed: \(outputPath)")
    }
}
