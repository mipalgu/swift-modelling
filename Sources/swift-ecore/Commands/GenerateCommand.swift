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
import ModellingGenerators

/// Command for generating code from models.
///
/// The generate command creates source code in various target languages from Ecore metamodels
/// or model instances. Languages that have a template set, such as Java, are generated from a
/// generator model (`.genmodel`) by the template engine; an Ecore model given for such a language is
/// imported into a temporary generator model first. The languages that the built-in generator
/// writes itself (Swift, C++, C and LLVM) are generated from Ecore, XMI or JSON models.
struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate code from models",
        discussion: """
            For a language with a template set, such as java, the input is a generator model \
            (.genmodel, see the genmodel command) or an Ecore model. Template files in the \
            directories given with --template-path replace the bundled templates of the same name. \
            Existing files are merged with the generated code unless --force-overwrite or --diff \
            says otherwise.
            """
    )

    /// Input model file path.
    @Argument(help: "Input model file path (.genmodel, .ecore, .xmi or .json)")
    var inputPath: String

    /// Output directory for generated code.
    @Option(name: .shortAndLong, help: "Output directory for generated code")
    var output: String = "."

    /// Target language for code generation.
    @Option(
        name: .shortAndLong,
        help: "Target language: swift, cpp, c, llvm, or the name of a template set such as java")
    var language: String = "swift"

    /// Directories whose template files replace the bundled templates.
    @Option(
        name: .customLong("template-path"),
        help: "A directory with template files that replace bundled templates (can be repeated)")
    var templatePaths: [String] = []

    /// Whether existing files are replaced.
    @Flag(name: .customLong("force-overwrite"), help: "Replace existing files without merging")
    var forceOverwrite: Bool = false

    /// Whether the differences with existing files are written beside them.
    @Flag(help: "Write the generated text of existing files beside them as .<name>.new")
    var diff: Bool = false

    /// Whether the model directory of the generator model is part of the output location.
    @Flag(
        name: .customLong("model-directory"),
        help: "Write below the model directory of the generator model, such as <output>/project/src")
    var useModelDirectory: Bool = false

    /// Enable verbose output.
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    /// Executes the generate command.
    ///
    /// Generates code in the specified target language from the input model.
    ///
    /// - Throws: `GenerationError` if generation fails.
    @MainActor
    func run() async throws {
        guard FileManager.default.fileExists(atPath: inputPath) else {
            throw GenerationError.fileNotFound(inputPath)
        }
        let inputURL = URL(fileURLWithPath: inputPath)
        let extensionName = inputURL.pathExtension.lowercased()
        let templateURLs = templatePaths.map { URL(fileURLWithPath: $0) }
        let templateLanguages = TemplateSet.availableLanguages(templatePaths: templateURLs)

        if extensionName == "genmodel" {
            guard templateLanguages.contains(language) else {
                throw templateLanguageError(templateLanguages)
            }
            try await generateFromTemplates(genModel: inputURL, templateURLs: templateURLs)
        } else if templateLanguages.contains(language)
            && !CodeGenerator.supportedLanguages.contains(language)
        {
            try await generateFromEcore(inputURL, templateURLs: templateURLs)
        } else {
            guard CodeGenerator.supportedLanguages.contains(language) else {
                throw templateLanguageError(templateLanguages)
            }
            try await generateWithBuiltInGenerator(inputURL)
        }
    }

    // MARK: - Template sets

    /// The error for a language that has no generator for the given input.
    private func templateLanguageError(_ templateLanguages: [String]) -> GenerationError {
        if CodeGenerator.supportedLanguages.contains(language) {
            return .generatorModelRequired(language)
        }
        return .unknownLanguage(language, CodeGenerator.supportedLanguages + templateLanguages)
    }

    /// Generates code from a generator model with a template set.
    private func generateFromTemplates(genModel: URL, templateURLs: [URL]) async throws {
        var options = GenerationOptions(
            templatePaths: templateURLs, forceOverwrite: forceOverwrite, diff: diff)
        if useModelDirectory { options.includeSourceRoot = true }
        let bar = GenerationProgressBar(verbose: verbose)
        if verbose {
            print("Generating \(language) code from: \(genModel.path)")
            print("Output directory: \(output)")
        }
        let result: ModellingGenerators.GenerationResult
        do {
            result = try await ModellingGenerators.GenerationPipeline.generate(
                genModelURL: genModel, language: language, outputDirectory: URL(fileURLWithPath: output),
                options: options, progress: { bar.show($0) })
        } catch {
            bar.finish()
            throw error
        }
        bar.finish()
        let noun = result.files.count == 1 ? "file" : "files"
        print("Generated \(result.files.count) \(noun) in: \(result.outputDirectory.path)")
    }

    /// Imports an Ecore model into a temporary generator model and generates code from that.
    private func generateFromEcore(_ ecore: URL, templateURLs: [URL]) async throws {
        let scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-ecore-generate")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: scratch) }
        var importOptions = GenModelImportOptions()
        importOptions.output = scratch.appendingPathComponent(
            ModellingGenerators.GenerationPipeline.defaultOutput(for: ecore).lastPathComponent)
        let imported = try await ModellingGenerators.GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [ecore], options: importOptions)
        try await generateFromTemplates(genModel: imported.url, templateURLs: templateURLs)
    }

    // MARK: - Built-in generator

    /// Generates code with the generator that writes Swift, C++, C and LLVM itself.
    private func generateWithBuiltInGenerator(_ inputURL: URL) async throws {
        if verbose {
            print("Generating \(language) code from: \(inputPath)")
            print("Output directory: \(output)")
        }

        let outputURL = URL(fileURLWithPath: output)

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
