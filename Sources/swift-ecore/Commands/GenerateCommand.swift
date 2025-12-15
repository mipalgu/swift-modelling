//
// GenerateCommand.swift
// ECore
//
//  Created by Rene Hexel on 3/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import Foundation

/// Command for generating code from models.
///
/// The generate command creates source code in various target languages
/// from Ecore metamodels or model instances.
struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate code from models"
    )

    /// Input model file path.
    @Argument(help: "Input model file path")
    var inputPath: String

    /// Output directory for generated code.
    @Option(name: .shortAndLong, help: "Output directory for generated code")
    var output: String = "."

    /// Target language for code generation.
    @Option(name: .shortAndLong, help: "Target language (swift, cpp, c, llvm)")
    var language: String = "swift"

    /// Enable verbose output.
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    /// Executes the generate command.
    ///
    /// Generates code in the specified target language from the input model.
    ///
    /// - Throws: `GenerationError` if generation fails.
    func run() async throws {
        if verbose {
            print("Generating \(language) code from: \(inputPath)")
            print("Output directory: \(output)")
        }

        let inputURL = URL(fileURLWithPath: inputPath)
        let outputURL = URL(fileURLWithPath: output)

        guard FileManager.default.fileExists(atPath: inputPath) else {
            throw GenerationError.fileNotFound(inputPath)
        }

        // Create output directory if it doesn't exist
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        // Load model
        let resource: Resource
        let fileExtension = inputURL.pathExtension.lowercased()

        switch fileExtension {
        case "ecore":
            if verbose { print("Loading Ecore metamodel...") }
            let parser = XMIParser()
            resource = try await parser.parse(inputURL)
        case "xmi":
            if verbose { print("Loading XMI model...") }
            let parser = XMIParser()
            resource = try await parser.parse(inputURL)
        case "json":
            if verbose { print("Loading JSON model...") }
            let parser = JSONParser()
            resource = try await parser.parse(inputURL)
        default:
            throw GenerationError.unsupportedFormat(fileExtension)
        }

        // Generate code
        let generator = try CodeGenerator(language: language, outputDirectory: outputURL)
        try await generator.generate(from: resource, verbose: verbose)

        print("Code generation completed in: \(output)")
    }
}
