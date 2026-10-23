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
import ModellingCommandLine
import ModellingGenerators

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

            Modules that the template imports are searched in the directory of the template and \
            then in the --template-path directories. Each --param name=value is available to the \
            templates as the variable [name/] and through the services parameter('name') and \
            hasParameter('name'); a name must be an identifier and not a reserved keyword. Existing \
            files are merged with the generated text when the module declares a merge, and \
            replaced otherwise; --force-overwrite always replaces them, and --diff keeps them and \
            writes the generated text beside them.

            \(UnsetFeatureOptions.discussion(reader: "the templates"))

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

                # Import modules from extra directories, and pass parameters
                swift-mtl generate template.mtl \\
                  --model input.xmi \\
                  --template-path shared/templates \\
                  --param package=org.example \\
                  --output generated/

                # Keep existing files, writing new text beside them as .<name>.new
                swift-mtl generate template.mtl --model input.xmi --diff --output generated/

                # Read unset features as undefined instead of their defaults
                swift-mtl generate template.mtl --model input.xmi --unset-features undefined

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

    /// The directories searched for imported modules.
    @OptionGroup var templatePathOptions: TemplatePathOptions

    /// The parameters of the templates.
    @OptionGroup var parameterOptions: TemplateParameterOptions

    @Flag(name: .customLong("force-overwrite"), help: "Replace existing files without merging")
    var forceOverwrite: Bool = false

    @Flag(help: "Write the generated text of existing files beside them as .<name>.new")
    var diff: Bool = false

    /// How the templates read features that a model does not set.
    @OptionGroup(title: "Evaluation")
    var unsetFeatureOptions: UnsetFeatureOptions

    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    @MainActor
    func run() async throws {
        try await generate(templateFile: templateFile)
    }

    /// Generates text with a single template file.
    ///
    /// - Parameter templateFile: The path of the template file.
    @MainActor
    private func generate(templateFile: String) async throws {
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

        let searchURLs = try templatePathOptions.directories()
        let parameters = try parameterOptions.services
        let parser = MTLParser(enableDebugging: verbose, searchPaths: searchURLs)
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

        let inputs = try await loadModels()

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

        try createOutputDirectory()

        // Execute generation
        let strategy = MTLFileSystemStrategy(
            basePath: output, options: generatorOptions, standardOutput: .capture)
        let generator = MTLGenerator(
            module: mtlModule, generationStrategy: strategy, serviceProviders: [parameters],
            unsetFeatureReads: unsetFeatureOptions.unsetFeatures)
        parameters.bind(to: generator)

        do {
            try await generator.generate(
                mainTemplate: mainTemplateName,
                arguments: inputs.arguments,
                models: inputs.models
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

    /// The options of the generator, from the command line.
    private var generatorOptions: MTLGeneratorOptions {
        MTLGeneratorOptions(
            forceOverwrite: forceOverwrite,
            redirectionPattern: diff && !forceOverwrite ? TemplateSetConstants.diffRedirectionPattern : nil,
            templateSearchPaths: templatePathOptions.templatePaths)
    }

    /// Creates the output directory if it does not exist.
    private func createOutputDirectory() throws {
        if !FileManager.default.fileExists(atPath: output) {
            let outputURL = URL(fileURLWithPath: output)
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
        }
    }

    /// The models of a run and the arguments of its main template.
    struct Inputs {
        /// The loaded models by the name of their file without its extension.
        var models: [String: Resource] = [:]

        /// The root objects of each model, in command line order.
        var arguments: [(any EcoreValue)?] = []

        /// The resource set with the registered metamodels.
        var resourceSet = ResourceSet()
    }

    /// Registers the metamodels and loads the models given on the command line.
    ///
    /// An Ecore file given with `--model` is registered as a metamodel and its package is passed
    /// to the template. Every other model is read as JSON if its extension is `json`, and as XMI
    /// otherwise; a JSON model is read without the registered metamodels.
    ///
    /// - Returns: The models, the arguments of the main template and the resource set.
    /// - Throws: ``ValidationError/fileNotFound(_:)`` if a model does not exist, and the errors of
    ///   the parsers.
    @MainActor
    private func loadModels() async throws -> Inputs {
        var inputs = Inputs()
        var rootObjectsByModel: [Int: [any EcoreValue]] = [:]
        let resourceSet = inputs.resourceSet
        if !metamodel.isEmpty || !model.isEmpty {
            if verbose {
                print("\n=== Loading Models ===")
            }

            // First pass: register metamodels (--metamodel files and .ecore --model files)
            for metamodelPath in metamodel {
                try await MetamodelRegistration.registerMetamodel(
                    at: metamodelPath, into: resourceSet,
                    announcement: MetamodelRole.registeredOnly.announcement, verbose: verbose)
            }
            for (index, modelPath) in model.enumerated() where MetamodelRegistration.isEcoreFile(modelPath) {
                let package = try await MetamodelRegistration.registerMetamodel(
                    at: modelPath, into: resourceSet,
                    announcement: MetamodelRole.registeredAndInput.announcement, verbose: verbose)
                let modelURL = URL(fileURLWithPath: modelPath)
                let resource = await resourceSet.createResource(uri: modelURL.absoluteString)
                await resource.add(package)
                inputs.models[modelURL.deletingPathExtension().lastPathComponent] = resource
                rootObjectsByModel[index] = await resource.getRootObjects()
            }

            // Second pass: load instance models (non-ecore files)
            for (index, modelPath) in model.enumerated() {
                let modelURL = URL(fileURLWithPath: modelPath)
                guard !MetamodelRegistration.isEcoreFile(modelPath) else { continue }
                guard FileManager.default.fileExists(atPath: modelPath) else {
                    throw ValidationError.fileNotFound(modelPath)
                }

                let format = ModelFileFormat.instanceFormat(of: modelURL)

                if verbose {
                    print("Loading input model \(index + 1): \(modelPath) (format: \(format.rawValue))")
                }

                let options = ModelIO.LoadOptions(requiresMetamodel: false, enableDebugging: verbose)
                let resource = try await ModelIO.load(
                    url: modelURL, format: format,
                    resourceSet: format == .json ? ResourceSet() : resourceSet, options: options
                ).resource

                // Use filename without extension as model name
                let modelName = modelURL.deletingPathExtension().lastPathComponent
                if verbose, inputs.models[modelName] != nil {
                    print("  ! Model name '\(modelName)' is already in use: replacing the earlier model")
                }
                inputs.models[modelName] = resource
                rootObjectsByModel[index] = await resource.getRootObjects()

                if verbose {
                    let count = await resource.count()
                    print("  ✓ Loaded \(count) objects")
                }
            }
        }

        // Template arguments are the root objects of each model in command line order
        inputs.arguments = model.indices.flatMap { index in
            (rootObjectsByModel[index] ?? []).map { Optional($0) }
        }
        return inputs
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
