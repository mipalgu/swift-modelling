//
// GenerateCommand.swift
// swift-mtl
//
//  Created by Rene Hexel on 28/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//

import ArgumentParser
import ECore
import EMFBase
import Foundation
import MTL

/// Command for generating text from models using MTL templates.
///
/// The generate command executes MTL templates to produce text output from
/// models, supporting code generation, documentation generation, and other
/// model-to-text transformations.
struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate text from models using MTL templates",
        discussion: """
            Generates text files from models using MTL (Model-to-Text Language) templates.
            Supports generation from models in XMI and JSON formats with automatic
            format detection based on file extensions.

            Examples:
                # Basic generation
                swift-mtl generate template.mtl \\
                  --model input.xmi \\
                  --output generated/

                # Multiple models
                swift-mtl generate template.mtl \\
                  --model families.xmi \\
                  --model departments.xmi \\
                  --output generated/

                # Specify main template
                swift-mtl generate template.mtl \\
                  --model input.xmi \\
                  --template generateAll \\
                  --output generated/

                # Ecore model: the EPackage becomes a template argument
                swift-mtl generate ecore2dot.mtl \\
                  --model library.ecore \\
                  --output generated/

                # Register a metamodel only, and pass just the instance model
                swift-mtl generate template.mtl \\
                  --metamodel library.ecore \\
                  --model books.xmi \\
                  --output generated/

                # Verbose output
                swift-mtl generate template.mtl \\
                  --model input.xmi \\
                  --output generated/ \\
                  --verbose
            """
    )

    @Argument(help: "MTL template file (.mtl)")
    var templateFile: String

    @Option(
        name: .long,
        help: """
            Input model file (XMI, JSON, or Ecore, can be specified multiple times). \
            The root object of each model is passed to the main template in command line \
            order. An Ecore file is also registered as a metamodel, and its EPackage is \
            passed as a template argument.
            """
    )
    var model: [String] = []

    @Option(
        name: .long,
        help: """
            Ecore metamodel file to register without passing it to the template \
            (can be specified multiple times). Use this to supply the metamodel of an \
            instance model when the template does not take the EPackage as an argument.
            """
    )
    var metamodel: [String] = []

    @Option(name: .shortAndLong, help: "Output directory for generated files")
    var output: String = "."

    @Option(name: .shortAndLong, help: "Main template name to execute (auto-detect if not specified)")
    var template: String?

    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    @MainActor
    func run() async throws {
        // Print configuration if verbose
        if verbose {
            print("MTL Template: \(templateFile)")
            print("Metamodels: \(metamodel.joined(separator: ", "))")
            print("Input Models: \(model.joined(separator: ", "))")
            print("Output Directory: \(output)")
            if let template = template {
                print("Main Template: \(template)")
            }
        }

        // Parse MTL template
        if verbose {
            print("\n=== Parsing MTL Template ===")
        }

        let templateURL = URL(fileURLWithPath: templateFile)
        guard FileManager.default.fileExists(atPath: templateFile) else {
            throw ValidationError.fileNotFound(templateFile)
        }

        let parser = MTLParser(enableDebugging: verbose)
        let mtlModule: MTLModule
        do {
            mtlModule = try await parser.parse(templateURL)
        } catch {
            throw ValidationError.parseFailed(templateFile, error.localizedDescription)
        }

        if verbose {
            print("✓ Successfully parsed MTL module: \(mtlModule.name)")
            print("  Templates: \(mtlModule.templates.count)")
            print("  Queries: \(mtlModule.queries.count)")
            print("  Macros: \(mtlModule.macros.count)")
        }

        // Load models
        var loadedModels: [String: Resource] = [:]
        var rootObjectsByModel: [Int: [any EcoreValue]] = [:]
        let resourceSet = ResourceSet()
        if !metamodel.isEmpty || !model.isEmpty {
            if verbose {
                print("\n=== Loading Models ===")
            }

            // First pass: register metamodels (--metamodel files and .ecore --model files)
            for metamodelPath in metamodel {
                _ = try await registerMetamodel(at: metamodelPath, role: .registeredOnly, resourceSet: resourceSet, verbose: verbose)
            }
            for (index, modelPath) in model.enumerated() where isEcoreFile(modelPath) {
                let package = try await registerMetamodel(
                    at: modelPath, role: .registeredAndInput, resourceSet: resourceSet, verbose: verbose)
                let modelURL = URL(fileURLWithPath: modelPath)
                let resource = await resourceSet.createResource(uri: modelURL.absoluteString)
                await resource.add(package)
                loadedModels[modelURL.deletingPathExtension().lastPathComponent] = resource
                rootObjectsByModel[index] = await resource.getRootObjects()
            }

            // Second pass: load instance models (non-ecore files)
            for (index, modelPath) in model.enumerated() {
                let modelURL = URL(fileURLWithPath: modelPath)
                guard !isEcoreFile(modelPath) else { continue }
                guard FileManager.default.fileExists(atPath: modelPath) else {
                    throw ValidationError.fileNotFound(modelPath)
                }

                // Detect format based on extension
                let format = detectFormat(from: modelPath)

                if verbose {
                    print("Loading input model \(index + 1): \(modelPath) (format: \(format))")
                }

                let resource = try await loadModel(from: modelPath, format: format, verbose: verbose, resourceSet: resourceSet)

                // Use filename without extension as model name
                let modelName = modelURL.deletingPathExtension().lastPathComponent
                if verbose, loadedModels[modelName] != nil {
                    print("  ! Model name '\(modelName)' is already in use: replacing the earlier model")
                }
                loadedModels[modelName] = resource
                rootObjectsByModel[index] = await resource.getRootObjects()

                if verbose {
                    let count = await resource.count()
                    print("  ✓ Loaded \(count) objects")
                }
            }
        }

        // Determine main template
        let mainTemplateName: String
        if let specified = template {
            mainTemplateName = specified
            guard mtlModule.templates[mainTemplateName] != nil else {
                throw ValidationError.generationFailed("Template '\(mainTemplateName)' not found in module")
            }
        } else {
            // Find first template marked as main, or use first template
            if let main = mtlModule.templates.first(where: { $0.value.isMain }) {
                mainTemplateName = main.key
            } else if let first = mtlModule.templates.first {
                mainTemplateName = first.key
            } else {
                throw ValidationError.generationFailed("No templates found in module")
            }
        }

        if verbose {
            print("\n=== Executing Generation ===")
            print("Main template: \(mainTemplateName)")
            print("Output directory: \(output)")
        }

        // Create output directory if needed
        if !FileManager.default.fileExists(atPath: output) {
            let outputURL = URL(fileURLWithPath: output)
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
        }

        // Execute generation
        let strategy = MTLFileSystemStrategy(basePath: output, standardOutput: .capture)
        let generator = MTLGenerator(module: mtlModule, generationStrategy: strategy)

        // Template arguments are the root objects of each model in command line order
        let rootObjects: [(any EcoreValue)?] = model.indices.flatMap { index in
            (rootObjectsByModel[index] ?? []).map { Optional($0) }
        }

        do {
            try await generator.generate(
                mainTemplate: mainTemplateName,
                arguments: rootObjects,
                models: loadedModels
            )
        } catch {
            throw ValidationError.generationFailed(error.localizedDescription)
        }
        try await writeStandardOutput(of: strategy)

        // Display results
        if verbose {
            print("\n=== Generation Complete ===")
            let stats = generator.statistics
            print("✓ Generation successful")
            print("  Templates executed: \(stats.templatesExecuted)")
            print("  Execution time: \(String(format: "%.3f", stats.executionTime * 1000))ms")
        } else {
            print("✓ Generation complete")
        }
    }
}

// MARK: - Helper Functions

/// The role an Ecore file plays in a generation run.
enum MetamodelRole {
    /// Registered for instance model parsing only (`--metamodel`).
    case registeredOnly
    /// Registered, and its EPackage is also passed to the template (`--model`).
    case registeredAndInput

    /// The text used to announce the role in verbose output.
    var announcement: String {
        switch self {
        case .registeredOnly: return "Loading metamodel (registered only)"
        case .registeredAndInput: return "Loading metamodel (registered and used as input model)"
        }
    }
}

/// Reports whether a path names an Ecore metamodel file.
///
/// - Parameter path: The file path to examine.
/// - Returns: `true` if the file extension is `ecore` (case-insensitive).
func isEcoreFile(_ path: String) -> Bool {
    URL(fileURLWithPath: path).pathExtension.lowercased() == "ecore"
}

/// Loads an Ecore metamodel and registers it with a resource set.
///
/// - Parameters:
///   - path: The path to the `.ecore` file.
///   - role: The role the metamodel plays, used for verbose output.
///   - resourceSet: The resource set in which to register the metamodel.
///   - verbose: Whether to print progress.
/// - Returns: The loaded root package.
/// - Throws: `ValidationError.fileNotFound` if the file does not exist, or any loading error.
@MainActor
func registerMetamodel(
    at path: String,
    role: MetamodelRole,
    resourceSet: ResourceSet,
    verbose: Bool = false
) async throws -> EPackage {
    guard FileManager.default.fileExists(atPath: path) else {
        throw ValidationError.fileNotFound(path)
    }
    if verbose {
        print("\(role.announcement): \(path)")
    }
    let package = try await EPackage(url: URL(fileURLWithPath: path), enableDebugging: verbose)
    await resourceSet.registerMetamodel(package, uri: package.nsURI)
    if verbose {
        print("  ✓ Registered metamodel '\(package.name)' with URI: \(package.nsURI)")
    }
    return package
}

/// Model format enumeration.
enum ModelFormat: String {
    case xmi
    case json

    var description: String {
        switch self {
        case .xmi: return "XMI"
        case .json: return "JSON"
        }
    }
}

/// Detects the model format based on file extension.
func detectFormat(from path: String) -> ModelFormat {
    let pathExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
    switch pathExtension {
    case "xmi", "ecore":
        return .xmi
    case "json":
        return .json
    default:
        return .xmi  // Default to XMI
    }
}

/// Loads a model from a file using the appropriate parser.
///
/// - Parameters:
///   - path: The path to the model file.
///   - format: The format of the model file (XMI or JSON).
///   - verbose: Whether to enable verbose debugging output.
///   - resourceSet: An optional `ResourceSet` for metamodel-guided parsing.
/// - Returns: The loaded `Resource` containing the model objects.
func loadModel(
    from path: String,
    format: ModelFormat,
    verbose: Bool,
    resourceSet: ResourceSet? = nil
) async throws -> Resource {
    let url = URL(fileURLWithPath: path)

    let resource: Resource
    switch format {
    case .xmi:
        let parser = XMIParser(resourceSet: resourceSet, enableDebugging: verbose)
        resource = try await parser.parse(url)
    case .json:
        let parser = JSONParser()
        resource = try await parser.parse(url)
    }

    return resource
}

// MARK: - Error Types

/// Validation errors for the generate command.
enum ValidationError: Error, CustomStringConvertible {
    case fileNotFound(String)
    case parseFailed(String, String)
    case generationFailed(String)

    var description: String {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .parseFailed(let path, let message):
            return "Failed to parse \(path): \(message)"
        case .generationFailed(let message):
            return "Generation failed: \(message)"
        }
    }
}

extension GenerateCommand {
    /// Writes the text a template produced outside any file block.
    ///
    /// Text that a template writes outside a `[file]` block is collected by the
    /// generation strategy and saved in the output directory under the standard
    /// output file name, so that it remains available after the command finishes.
    /// Nothing is written when the template produced no such text.
    ///
    /// - Parameter strategy: The file system strategy used for generation.
    /// - Throws: An error if the file cannot be written.
    func writeStandardOutput(of strategy: MTLFileSystemStrategy) async throws {
        guard let text = await strategy.standardOutput else { return }
        let url = URL(fileURLWithPath: output).appendingPathComponent(MTLStandardOutput.fileName)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}
