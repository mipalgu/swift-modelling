//
// GenerateCommand.swift
// swift-mtl
//
//  Created by Rene Hexel on 28/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//

import AQL
import ArgumentParser
import ECore
import EMFBase
import Foundation
import MTL
import ModellingCommandLine
import ModellingGenerators
import ModellingPipeline

/// Command for generating text from models using MTL templates.
///
/// The generate command executes MTL templates to produce text output from
/// models, supporting code generation, documentation generation, and other
/// model-to-text transformations. The templates are either a single template
/// file or a template set, named by its directory or by its bundled language.
struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate text from models using MTL templates",
        discussion: """
            Generates text files from models using MTL (Model-to-Text Language) templates.
            Supports generation from models in XMI and JSON formats with automatic
            format detection based on file extensions.

            --template names the main template of the module. A value that ends in .mtl names \
            the template file instead, when no template file argument is given.

            Modules that the template imports are searched in the directory of the template and \
            then in the --template-path directories. Each --param name=value is available to the \
            templates as the variable [name/] and through the services parameter('name') and \
            hasParameter('name'); a name must be an identifier and not a reserved keyword. Existing \
            files are merged with the generated text when the module declares a merge, and \
            replaced otherwise; --force-overwrite always replaces them, and --diff keeps them and \
            writes the generated text beside them. Text that the templates write outside their \
            [file] blocks is saved as stdout in the output directory, unless it is only white \
            space or a [file] block of the run wrote stdout itself; \
            --\(GenerateCommand.printStandardOutputOption) prints that text on standard output \
            instead and saves no stdout file.

            Instead of a template file, --template-set names a template set: a directory with a \
            templateset.json descriptor, or the language of a bundled set \
            (\(GenerateCommand.bundledLanguageList())). The main template of the set receives the \
            root objects of the models, and the data models of the set are available to its \
            templates. Files in the --template-path directories replace the files of the set with \
            the same relative path. --code-style chooses one of the code styles of the set \
            (\(CodeStyleOptions.bundledStyleList())).

            \(UnsetFeatureOptions.discussion(reader: "the templates"))

            \(LetTypeMismatchOptions.discussion(reader: "the templates"))

            \(MTLSemanticsOptions.discussion(reader: "the templates"))

            \(SourceEncodingOptions.discussion(reader: "the template file or the templates of the template set, and the modules they import"))

            \(SemanticsOptions.discussion())

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

                # Name the template file with --template instead of as an argument
                swift-mtl generate --template template.mtl \\
                  --model input.xmi \\
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

                # Run a template set, from its directory or by the name of a bundled set
                swift-mtl generate --template-set my-set/ \\
                  --model input.xmi \\
                  --output generated/

                # Keep existing files, writing new text beside them as .<name>.new
                swift-mtl generate template.mtl --model input.xmi --diff --output generated/

                # Read unset features as undefined instead of their defaults
                swift-mtl generate template.mtl --model input.xmi --unset-features undefined

                # Skip typed lets of another type with a warning, as Acceleo 3 does
                swift-mtl generate template.mtl --model input.xmi --let-type-mismatches skip

                # Generate as version 0.6 did, but drop line breaks after one-line blocks
                swift-mtl generate template.mtl --model input.xmi \\
                  --semantics legacy --block-line-breaks acceleo

                # Verbose output
                swift-mtl generate template.mtl \\
                  --model input.xmi \\
                  --output generated/ \\
                  --verbose

                # Trace the template and model parsers
                swift-mtl generate template.mtl --model input.xmi --debug
            """
    )

    @Argument(help: "MTL template file (.mtl)")
    var templateFile: String?

    /// The template set to run instead of a template file.
    @Option(
        name: .customLong("template-set"),
        help: ArgumentHelp(
            "A template set directory, or the language of a bundled template set, instead of a template file",
            valueName: "directory|language"))
    var templateSet: String?

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

    /// The main template to run, or the template file when no template file argument is given.
    ///
    /// A value with the extension of MTL module files names the template file, since a
    /// template name cannot contain a dot. Any other value names the main template.
    @Option(
        name: .shortAndLong,
        help: """
            Main template name to execute (auto-detect if not specified), or the template file \
            (.mtl) when no template file argument is given
            """)
    var template: String?

    /// The directories searched for imported modules.
    @OptionGroup var templatePathOptions: TemplatePathOptions

    /// The parameters of the templates.
    @OptionGroup var parameterOptions: TemplateParameterOptions

    @Flag(name: .customLong("force-overwrite"), help: "Replace existing files without merging")
    var forceOverwrite: Bool = false

    @Flag(help: "Write the generated text of existing files beside them as .<name>.new")
    var diff: Bool = false

    /// The long name of the option that prints the text outside file blocks.
    static let printStandardOutputOption = "print-standard-output"

    /// Whether the text written outside any file block is printed instead of saved.
    @Flag(
        name: .customLong(GenerateCommand.printStandardOutputOption),
        help: ArgumentHelp(
            "Print the text that the templates write outside [file] blocks instead of saving it "
                + "as \(MTLStandardOutput.fileName) in the output directory"))
    var printStandardOutput: Bool = false

    /// How the templates read features that a model does not set.
    @OptionGroup(title: "Evaluation")
    var unsetFeatureOptions: UnsetFeatureOptions

    /// How a typed let treats a value that does not conform to its declared type.
    @OptionGroup(title: "Evaluation")
    var letTypeMismatchOptions: LetTypeMismatchOptions

    /// The behaviours of the templates and their expressions.
    @OptionGroup(title: "Evaluation")
    var mtlSemanticsOptions: MTLSemanticsOptions

    /// The preset of the behaviours, standard or that of version 0.6.
    @OptionGroup(title: "Evaluation")
    var semanticsOptions: SemanticsOptions

    /// The character encoding of the template file or the templates of the template set, and of
    /// the modules they import.
    @OptionGroup var encodingOptions: SourceEncodingOptions

    /// How metamodels in KM3 and in grammar formats are read.
    @OptionGroup var formatOptions: MetamodelFormatOptions

    /// The level whose deep view presents each multi-level model.
    @OptionGroup var deepViewOptions: DeepViewOptions

    /// The behaviours of the templates that the command line and the settings of a run select.
    ///
    /// - Parameter settings: The preset, configuration file and container scope of the run.
    /// - Returns: The options of the templates.
    func mtlOptions(settings: SemanticsSettings) -> MTLOptions {
        var options = mtlSemanticsOptions.mtlOptions(settings: settings)
        options.unsetFeatureReads = unsetFeatureOptions.unsetFeatures(settings: settings)
        options.letTypeMismatches = letTypeMismatchOptions.letTypeMismatches(settings: settings)
        return options
    }

    /// The code style of the text that a template set generates.
    @OptionGroup(title: "Code style")
    var codeStyle: CodeStyleOptions

    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    /// Whether the template and model parsers trace their work.
    @OptionGroup var debugOptions: DebugOptions

    /// The languages of the bundled template sets, as text for the help.
    ///
    /// - Returns: The names of the languages, separated by commas.
    static func bundledLanguageList() -> String {
        TemplateSetLocator().availableLanguages().joined(separator: ", ")
    }

    /// Whether a value of `--template` names a template file rather than a template.
    ///
    /// - Parameter value: The value of the option.
    /// - Returns: `true` if the value has the extension of MTL module files.
    static func namesTemplateFile(_ value: String) -> Bool {
        URL(fileURLWithPath: value).pathExtension == MTLSyntax.moduleFileExtension
    }

    /// Checks that the command line names either a template file or a template set.
    ///
    /// A template file that `--template` names takes the place of the template file argument.
    ///
    /// - Throws: A validation error if both or neither are given, or if an option that applies
    ///   to only one of them is given with the other.
    mutating func validate() throws {
        if let value = template, Self.namesTemplateFile(value) {
            guard templateFile == nil else {
                throw ArgumentParser.ValidationError(
                    "Give the template file either as an argument or with --template, not both")
            }
            templateFile = value
            template = nil
        }
        switch (templateFile, templateSet) {
        case (nil, nil):
            throw ArgumentParser.ValidationError("Give a template file or --template-set")
        case (.some, .some):
            throw ArgumentParser.ValidationError("Give either a template file or --template-set, not both")
        case (.some, nil) where codeStyle.isGiven:
            throw ArgumentParser.ValidationError("--code-style only applies to a template set")
        case (nil, .some) where template != nil:
            throw ArgumentParser.ValidationError("--template does not apply to a template set, which names its main template")
        default:
            break
        }
    }

    @MainActor
    func run() async throws {
        let settings = try semanticsOptions.settings()
        if let templateSet {
            try await generate(templateSet: templateSet, settings: settings)
        } else if let templateFile {
            try await generate(templateFile: templateFile, settings: settings)
        }
    }

    /// Prints the settings of a run that do not appear on the command line.
    ///
    /// - Parameter settings: The preset, configuration file and container scope of the run.
    private func printSettings(_ settings: SemanticsSettings) {
        if let file = settings.configuration.url {
            print("Configuration File: \(file.path)")
        }
        print("Semantics: \(settings.preset.rawValue)")
        print("Container Scope: \(settings.containerLookupScope.rawValue)")
    }

    /// Generates text with a single template file.
    ///
    /// - Parameters:
    ///   - templateFile: The path of the template file.
    ///   - settings: The preset, configuration file and container scope of the run.
    @MainActor
    private func generate(templateFile: String, settings: SemanticsSettings) async throws {
        // Print configuration if verbose
        if verbose {
            print("MTL Template: \(templateFile)")
            print("Metamodels: \(metamodel.joined(separator: ", "))")
            print("Input Models: \(model.joined(separator: ", "))")
            print("Output Directory: \(output)")
            if let template = template {
                print("Main Template: \(template)")
            }
            printSettings(settings)
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
        let parser = MTLParser(
            enableDebugging: debugOptions.debug, searchPaths: searchURLs,
            encoding: encodingOptions.encoding(settings: settings))
        let mtlModule: MTLModule
        do {
            mtlModule = try await parser.parseReportingWarnings(templateURL)
        } catch {
            throw ValidationError.parseFailed(templateFile, error.localizedDescription)
        }

        if verbose {
            print("✓ Successfully parsed MTL module: \(mtlModule.name)")
            print("  Templates: \(mtlModule.templates.count)")
            print("  Queries: \(mtlModule.queries.count)")
            print("  Macros: \(mtlModule.macros.count)")
        }

        let inputs = try await loadModels(settings: settings)

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
        let standardOutputBefore = FileState(of: standardOutputURL)
        let strategy = MTLFileSystemStrategy(
            basePath: output, options: generatorOptions, standardOutput: .capture)
        let generator = MTLGenerator(
            module: mtlModule, generationStrategy: strategy, options: mtlOptions(settings: settings),
            serviceProviders: [parameters] + inputs.services)
        parameters.bind(to: generator)

        do {
            try await generator.generate(
                mainTemplate: mainTemplateName,
                arguments: inputs.arguments,
                models: inputs.models
            )
        } catch {
            GenerationWarningReport.write(generator.statistics.warnings)
            throw ValidationError.generationFailed(error.localizedDescription)
        }
        GenerationWarningReport.write(generator.statistics.warnings)
        try await writeStandardOutput(of: strategy, before: standardOutputBefore)

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

    /// Generates text with a template set.
    ///
    /// - Parameters:
    ///   - templateSet: The directory of the template set, or the language of a bundled set.
    ///   - settings: The preset, configuration file and container scope of the run.
    @MainActor
    private func generate(templateSet: String, settings: SemanticsSettings) async throws {
        if verbose {
            print("Template Set: \(templateSet)")
            print("Metamodels: \(metamodel.joined(separator: ", "))")
            print("Input Models: \(model.joined(separator: ", "))")
            print("Output Directory: \(output)")
            printSettings(settings)
        }
        let templateURLs = try templatePathOptions.directories()
        let parameters = try parameterOptions.values
        let inputs = try await loadModels(settings: settings)
        try createOutputDirectory()

        if verbose {
            print("\n=== Executing Generation ===")
        }
        var step = GenerationStep(
            templates: .templateSet(templateSet, codeStyle: codeStyle.codeStyle), templatePaths: templateURLs,
            parameters: parameters, outputDirectory: URL(fileURLWithPath: output),
            generatorOptions: generatorOptions, mtlOptions: mtlOptions(settings: settings))
        step.templateEncoding = encodingOptions.encoding(settings: settings)
        let verbose = self.verbose
        let result = try await step.run(
            arguments: inputs.arguments, models: inputs.models, resourceSet: inputs.resourceSet,
            progress: { update in if verbose { print("  \(update.message)") } })
        FileDiagnosticReport.write(result.decodingWarnings)
        GenerationWarningReport.write(result.warnings)
        let standardOutputFile = standardOutputURL.standardizedFileURL
        try writeStandardOutput(
            result.standardOutput,
            writtenByRun: result.files.contains { $0.standardizedFileURL == standardOutputFile })

        if verbose {
            print("\n=== Generation Complete ===")
            print("✓ Generation successful")
            print("  Template set: \(result.templateSet ?? templateSet)")
            print("  Main template: \(result.mainTemplate)")
            print("  Files written: \(result.files.count)")
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
        var resourceSet: ResourceSet

        /// The services of the deep views that replace multi-level models, if any.
        var services: [any AQLServiceProvider] = []
    }

    /// Registers the metamodels and loads the models given on the command line.
    ///
    /// A metamodel file given with `--model`, such as an Ecore or a KM3 file, is registered as a
    /// metamodel and its first root package is passed to the template. Every other model is read as JSON if its extension is `json`, as XMI if
    /// it is `xmi`, and otherwise in the format of its contents; a JSON model is read without
    /// the registered metamodels. Every resource set that receives a model has the container
    /// lookup scope of the settings as its default.
    ///
    /// - Parameter settings: The settings of the run, whose container lookup scope applies.
    /// - Returns: The models, the arguments of the main template and the resource set.
    /// - Throws: ``ValidationError/fileNotFound(_:)`` if a model does not exist, and the errors of
    ///   the parsers.
    @MainActor
    private func loadModels(settings: SemanticsSettings) async throws -> Inputs {
        var inputs = Inputs(resourceSet: settings.makeResourceSet())
        var rootObjectsByModel: [Int: [any EcoreValue]] = [:]
        let resourceSet = inputs.resourceSet
        if !metamodel.isEmpty || !model.isEmpty {
            if verbose {
                print("\n=== Loading Models ===")
            }

            // First pass: register metamodels (--metamodel files and metamodel --model files)
            let metamodelOptions = formatOptions.ecoreLoadOptions(settings: settings)
            await MultiLevelSupport.registerFormats()
            var metamodelModels = Set<Int>()
            for (index, modelPath) in model.enumerated() where await MetamodelRegistration.holdsMetamodel(at: modelPath) {
                metamodelModels.insert(index)
            }
            for metamodelPath in metamodel {
                try await MetamodelRegistration.registerMetamodel(
                    at: metamodelPath, into: resourceSet,
                    announcement: MetamodelRole.registeredOnly.announcement, verbose: verbose,
                    debug: debugOptions.debug, options: metamodelOptions)
            }
            for (index, modelPath) in model.enumerated() where metamodelModels.contains(index) {
                let package = try await MetamodelRegistration.registerMetamodel(
                    at: modelPath, into: resourceSet,
                    announcement: MetamodelRole.registeredAndInput.announcement, verbose: verbose,
                    debug: debugOptions.debug, options: metamodelOptions)
                let modelURL = URL(fileURLWithPath: modelPath)
                let resource = await resourceSet.createResource(uri: modelURL.absoluteString)
                await resource.add(package)
                inputs.models[modelURL.deletingPathExtension().lastPathComponent] = resource
                rootObjectsByModel[index] = await resource.getRootObjects()
            }

            // Second pass: load instance models (files that are not metamodels)
            for (index, modelPath) in model.enumerated() {
                let modelURL = URL(fileURLWithPath: modelPath)
                guard !metamodelModels.contains(index) else { continue }
                guard FileManager.default.fileExists(atPath: modelPath) else {
                    throw ValidationError.fileNotFound(modelPath)
                }

                let format = try ModelFileFormat.detectedInstanceFormat(of: modelURL)
                if format != .metadepth, MultiLevelSupport.holdsLinguisticInstances(modelURL) {
                    await MultiLevelSupport.registerLinguisticMetamodel(in: resourceSet)
                }

                if verbose {
                    print("Loading input model \(index + 1): \(modelPath) (format: \(format.rawValue))")
                }

                let options = ModelIO.LoadOptions(requiresMetamodel: false, enableDebugging: debugOptions.debug)
                var resource = try await ModelIO.load(
                    url: modelURL, format: format,
                    resourceSet: format == .json ? settings.makeResourceSet() : resourceSet, options: options
                ).resource
                var isDeepView = false
                if let level = deepViewOptions.level,
                    let views = try await MultiLevelSupport.views(of: resource, level: level, in: resourceSet)
                {
                    resource = views.view.resource
                    inputs.services.append(views.services)
                    isDeepView = true
                }

                // Use filename without extension as model name
                let modelName = modelURL.deletingPathExtension().lastPathComponent
                if verbose, inputs.models[modelName] != nil {
                    print("  ! Model name '\(modelName)' is already in use: replacing the earlier model")
                }
                inputs.models[modelName] = resource
                // A deep view passes its first clabject, as a model passes its root object
                let roots = await resource.getRootObjects()
                rootObjectsByModel[index] = isDeepView ? Array(roots.prefix(1)) : roots

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
    /// The file in the output directory that keeps the text written outside any file block.
    ///
    /// - Returns: The file named ``MTLStandardOutput/fileName`` in the output directory.
    var standardOutputURL: URL {
        URL(fileURLWithPath: output).appendingPathComponent(MTLStandardOutput.fileName)
    }

    /// Writes the text a single template produced outside any file block.
    ///
    /// Text that a template writes outside a `[file]` block is collected by the
    /// generation strategy and saved in the output directory under the standard
    /// output file name, so that it remains available after the command finishes,
    /// or printed on standard output with ``printStandardOutput``.
    /// Nothing is written when the template produced no such text, or only white
    /// space such as the line breaks between its file blocks. A file of that name
    /// that the template wrote itself with a `[file]` block is kept as the template
    /// wrote it: the file counts as written by the run when it appeared, or was
    /// replaced or modified, during the generation.
    ///
    /// - Parameters:
    ///   - strategy: The file system strategy used for generation.
    ///   - before: The state of the standard output file before the generation.
    /// - Throws: An error if the file cannot be written.
    func writeStandardOutput(of strategy: MTLFileSystemStrategy, before: FileState) async throws {
        try writeStandardOutput(
            await strategy.standardOutput, writtenByRun: FileState(of: standardOutputURL) != before)
    }

    /// Writes the text written outside any file block to the standard output file, or prints it.
    ///
    /// Nothing is written or printed when there is no text or when the text is empty or only
    /// white space. With ``printStandardOutput``, the text is printed on standard output and no
    /// file is written. Otherwise the text is saved in the standard output file, unless the run
    /// itself wrote that file with a `[file]` block.
    ///
    /// - Parameters:
    ///   - text: The text written outside any file block, or `nil` if none was kept.
    ///   - writtenByRun: Whether the run wrote the standard output file with a `[file]` block.
    /// - Throws: An error if the file cannot be written.
    func writeStandardOutput(_ text: String?, writtenByRun: Bool) throws {
        guard let text, text.contains(where: { !$0.isWhitespace }) else { return }
        if printStandardOutput {
            print(text, terminator: "")
            return
        }
        guard !writtenByRun else { return }
        try text.write(to: standardOutputURL, atomically: true, encoding: .utf8)
    }
}

/// The state of a file on disk, which tells whether the file was written between two looks.
///
/// Two states of the same path differ when the file appeared or disappeared, or when it was
/// replaced or modified in between.
struct FileState: Equatable, Sendable {
    /// Whether the file exists.
    let exists: Bool

    /// The number of the file in its file system, which changes when the file is replaced.
    let fileNumber: UInt64?

    /// The time of the last modification of the file.
    let modificationDate: Date?

    /// The size of the file in bytes.
    let size: UInt64?

    /// Looks at a file.
    ///
    /// - Parameter url: The location of the file.
    init(of url: URL) {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        exists = attributes != nil
        fileNumber = (attributes?[.systemFileNumber] as? NSNumber)?.uint64Value
        modificationDate = attributes?[.modificationDate] as? Date
        size = (attributes?[.size] as? NSNumber)?.uint64Value
    }
}
