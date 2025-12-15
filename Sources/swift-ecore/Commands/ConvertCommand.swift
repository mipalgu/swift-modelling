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

/// Command for converting between model formats.
///
/// The convert command supports bidirectional conversion between XMI and JSON formats,
/// preserving model structure and data integrity.
struct ConvertCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "convert",
        abstract: "Convert between model formats (XMI <-> JSON)"
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

    /// Executes the convert command.
    ///
    /// Converts the input file to the output format based on file extensions.
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

        // Load input
        let resource: Resource

        switch inputFormatToUse {
        case "xmi":
            if verbose { print("Reading XMI...") }
            let parser = XMIParser()
            resource = try await parser.parse(inputURL)
        case "json":
            if verbose { print("Reading JSON...") }
            let parser = JSONParser()
            resource = try await parser.parse(inputURL)
        default:
            throw ConversionError.unsupportedInputFormat(inputFormatToUse)
        }

        // Save output
        switch outputFormatToUse {
        case "xmi":
            if verbose { print("Writing XMI...") }
            let serializer = XMISerializer()
            let content = try await serializer.serialize(resource)
            try content.write(to: outputURL, atomically: true, encoding: .utf8)
        case "json":
            if verbose { print("Writing JSON...") }
            let serializer = JSONSerializer()
            let content = try await serializer.serialize(resource)
            try content.write(to: outputURL, atomically: true, encoding: .utf8)
        default:
            throw ConversionError.unsupportedOutputFormat(outputFormatToUse)
        }

        if verbose {
            let objects = await resource.getRootObjects()
            print("Converted \(objects.count) object(s) successfully")
        }

        print("Conversion completed: \(outputPath)")
    }
}
