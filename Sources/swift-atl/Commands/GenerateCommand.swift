//
// GenerateCommand.swift
// swift-atl
//
//  Created by Rene Hexel on 6/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Foundation
import GenModel
import ModellingGenerators

/// Command for generating code from Ecore models and generator models.
///
/// The generate command is the ATL entry to the shared generation pipeline. An Ecore model is
/// first transformed into a generator model (`.genmodel`) by the bundled ATL transformation
/// `Ecore2GenModel.atl`, or by a transformation given with `--transformations`. With the
/// pseudo-language `genmodel` the command stops there; with the name of a template set, such as
/// `java`, the generator model is then turned into source files by the templates of that set.
/// A generator model is generated from directly.
struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate generator models and code from Ecore models",
        discussion: """
            The input is an Ecore model (.ecore) or a generator model (.genmodel). An Ecore model \
            is transformed into a generator model with the ATL transformation Ecore2GenModel.atl, \
            which --transformations can replace with another file, or with a directory that holds \
            a file of that name.

            --language genmodel stops after creating the generator model, which is written beside \
            the Ecore model unless --output names a directory or a .genmodel file. Any other \
            language names a template set that turns the generator model into source files below \
            the --output directory. Template files in the directories given with --template-path \
            replace the bundled templates of the same name. Existing files are merged with the \
            generated code unless --force-overwrite or --diff says otherwise.

            Bundled languages: \(availableLanguageList()). A directory that holds a template set and \
            is given with --template-path adds its language.

            Examples:
                # Create library.genmodel beside library.ecore
                swift-atl generate library.ecore --language genmodel --base-package org.example

                # Generate source files from an Ecore model
                swift-atl generate library.ecore --language java --base-package org.example \\
                  --output Generated/

                # Generate from an existing generator model with customised templates
                swift-atl generate library.genmodel --language java --template-path my-templates
            """
    )

    /// The Ecore model or generator model to generate from.
    @Argument(
        help: ArgumentHelp("The Ecore model or generator model", valueName: "model.ecore"),
        completion: .file(extensions: ["ecore", "genmodel"]))
    var inputModel: String

    /// A replacement for the bundled Ecore to generator model transformation.
    @Option(
        name: .long,
        help: "An ATL transformation file, or a directory with Ecore2GenModel.atl, that replaces the bundled one"
    )
    var transformations: String?

    /// The target language.
    @Option(
        name: .shortAndLong,
        help: "Target language: genmodel, or the name of a template set (see the discussion)")
    var language: String = TemplateSetConstants.genModelLanguage

    /// The output directory, or the generator model file for the language `genmodel`.
    @Option(
        name: .shortAndLong,
        help: "Output directory (default: Generated, or beside the model for the language genmodel)")
    var output: String?

    /// The base package of the root packages.
    @Option(help: "The base package of the root packages")
    var basePackage: String?

    /// The prefixes of packages, either `Name` or `package=Name`.
    @Option(help: "A package prefix: Name for the root package, or package=Name for one package")
    var prefix: [String] = []

    /// The name of the model project.
    @Option(help: "The name of the model project")
    var modelProject: String?

    /// The plug-in identifier of the model project.
    @Option(name: .customLong("model-plugin-id"), help: "The plug-in identifier of the model project")
    var modelPluginID: String?

    /// The copyright text.
    @Option(help: "The copyright text")
    var copyright: String?

    /// The compliance level of the generated code.
    @Option(help: "The compliance level of the generated code, such as 17.0")
    var jdkLevel: String?

    /// Directories whose template files replace the bundled templates.
    @Option(
        name: .customLong("template-path"),
        help: "A directory with template files that replace bundled templates (can be repeated)")
    var templatePaths: [String] = []

    /// Whether existing files are replaced.
    @Flag(name: .customLong("force-overwrite"), help: "Replace existing files without merging")
    var forceOverwrite: Bool = false

    /// Whether the generated text of existing files is written beside them.
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

    /// The default output directory of the template languages.
    static let defaultOutputDirectory = "Generated"

    /// The languages that are available without extra template paths, as text for the help.
    static func availableLanguageList(templatePaths: [URL] = []) -> String {
        languages(templatePaths: templatePaths).joined(separator: ", ")
    }

    /// The languages that the command accepts.
    ///
    /// - Parameter templatePaths: The template directories to search in addition to the bundled ones.
    /// - Returns: The pseudo-language `genmodel` followed by the names of the template sets.
    static func languages(templatePaths: [URL] = []) -> [String] {
        [TemplateSetConstants.genModelLanguage] + TemplateSet.availableLanguages(templatePaths: templatePaths)
    }

    /// Executes the generate command.
    ///
    /// - Throws: ``ValidationError`` for unusable arguments, and `ExitCode.failure` after reporting
    ///   a failed generation.
    @MainActor
    func run() async throws {
        let inputURL = URL(fileURLWithPath: inputModel)
        let templateURLs = templatePaths.map { URL(fileURLWithPath: $0) }
        let available = Self.languages(templatePaths: templateURLs)
        guard available.contains(language) else {
            throw ValidationError(
                "Unsupported target language: \(language); available languages: "
                    + available.joined(separator: ", "))
        }
        guard FileManager.default.fileExists(atPath: inputModel) else {
            throw ValidationError("The model '\(inputModel)' does not exist")
        }
        let bar = GenerationProgressBar(verbose: verbose)
        defer { bar.finish() }
        do {
            if language == TemplateSetConstants.genModelLanguage {
                try await createGenModel(from: inputURL, bar: bar)
            } else {
                try await generateCode(from: inputURL, templateURLs: templateURLs, bar: bar)
            }
        } catch let error as ValidationError {
            throw error
        } catch {
            bar.finish()
            FileHandle.standardError.write(Data("Code generation failed: \(error)\n".utf8))
            throw ExitCode.failure
        }
    }

    /// The options that the command line gives the import of an Ecore model.
    ///
    /// - Returns: The import options.
    /// - Throws: ``ValidationError`` if the transformation location does not exist.
    func importOptions() throws -> GenModelImportOptions {
        var options = GenModelImportOptions()
        options.basePackage = basePackage
        prefix.forEach { options.addPrefix($0) }
        options.modelProject = modelProject
        options.modelPluginID = modelPluginID
        options.copyright = copyright
        options.complianceLevel = jdkLevel
        if let transformations {
            guard FileManager.default.fileExists(atPath: transformations) else {
                throw ValidationError("The transformation '\(transformations)' does not exist")
            }
            options.transformation = URL(fileURLWithPath: transformations)
        }
        return options
    }

    /// Creates a generator model from an Ecore model.
    private func createGenModel(from inputURL: URL, bar: GenerationProgressBar) async throws {
        guard inputURL.pathExtension.lowercased() == TemplateSetConstants.metamodelFileExtension else {
            throw ValidationError(
                "The language \(language) needs an Ecore model, but '\(inputModel)' is not one")
        }
        var options = try importOptions()
        options.output = output.map(genModelOutput(for:))
        let reporter = bar.reporter
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [inputURL], options: options,
            progress: { reporter(GenerationProgressUpdate(message: $0)) })
        bar.finish()
        if verbose {
            print(
                "Packages: \(result.packageCount), classes: \(result.classCount), "
                    + "enumerations: \(result.enumCount), data types: \(result.dataTypeCount), "
                    + "features: \(result.featureCount), operations: \(result.operationCount)")
        }
        print("Wrote \(result.url.path)")
    }

    /// The generator model file that an output argument names.
    ///
    /// - Parameter path: A `.genmodel` file, or a directory that receives a file named after the model.
    /// - Returns: The file to write.
    private func genModelOutput(for path: String) -> URL {
        let url = URL(fileURLWithPath: path)
        if url.pathExtension.lowercased() == GenModelConstants.genModelFileExtension { return url }
        return url.appendingPathComponent(
            GenerationPipeline.defaultOutput(for: URL(fileURLWithPath: inputModel)).lastPathComponent)
    }

    /// Generates source files with a template set.
    private func generateCode(from inputURL: URL, templateURLs: [URL], bar: GenerationProgressBar)
        async throws
    {
        var options = GenerationOptions(
            templatePaths: templateURLs, forceOverwrite: forceOverwrite, diff: diff)
        if useModelDirectory { options.includeSourceRoot = true }
        let directory = URL(fileURLWithPath: output ?? Self.defaultOutputDirectory)
        if verbose {
            print("Generating \(language) code from: \(inputURL.path)")
            print("Output directory: \(directory.path)")
        }
        let result = try await GenerationPipeline.generate(
            inputURL: inputURL, language: language, outputDirectory: directory,
            importOptions: try importOptions(), options: options, progress: bar.reporter)
        bar.finish()
        let noun = result.files.count == 1 ? "file" : "files"
        print("Generated \(result.files.count) \(noun) in: \(result.outputDirectory.path)")
    }
}
