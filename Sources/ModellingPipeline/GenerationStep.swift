//
// GenerationStep.swift
// ModellingPipeline
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Foundation
import MTL
import ModellingGenerators

/// A model-to-text generation with MTL templates, run on models held in memory.
///
/// The templates are either a template set, found by a ``TemplateSetLocator`` and run through
/// its main module and template, or a single module with a chosen template. The arguments of
/// the template are given when the step runs, and the models by name are available to the
/// templates as well. Parameters are available to the templates as variables and through the
/// services `parameter('name')` and `hasParameter('name')`, and further service providers can
/// be added. Files are written below ``outputDirectory``.
///
/// ## Example
///
/// ```swift
/// let step = GenerationStep(
///     templates: .templateSet("c", codeStyle: nil),
///     parameters: ["prefix": "lib"],
///     outputDirectory: URL(fileURLWithPath: "Generated"),
///     mtlOptions: .standard)
/// let result = try await step.run(arguments: [root], models: ["model": resource])
/// print(result.files)
/// ```
public struct GenerationStep: Sendable {
    /// The templates that a generation step runs.
    public enum Templates: Sendable, Equatable {
        /// A template set, named by its language or by its directory.
        ///
        /// The set is assembled by the locator with the override directories of the step, and
        /// its main template runs. The code style is one of the styles of the set, or `nil` for
        /// its default style.
        case templateSet(String, locator: TemplateSetLocator = TemplateSetLocator(), codeStyle: String? = nil)

        /// A single module and the name of the template to run.
        ///
        /// Without a name, the main template of the module runs, or its first template by name
        /// if no template is marked as main.
        case module(URL, mainTemplate: String? = nil)
    }

    /// What a generation step wrote.
    public struct Result: Sendable, Equatable {
        /// The directory that relative file names were resolved against.
        public let outputDirectory: URL

        /// The files that the templates wrote, in the order they were finished.
        public let files: [URL]

        /// The text that the templates wrote outside any file block, if there was any.
        public let standardOutput: String?

        /// The name of the template that ran.
        public let mainTemplate: String

        /// The name of the template set that ran, or `nil` for a single module.
        public let templateSet: String?

        /// The distinct warnings of the templates, in the order in which they were first reported.
        ///
        /// Each warning is a `SourceDiagnostic`, such as a `let` block that was skipped because
        /// its value does not conform to the declared type of its variable.
        public let warnings: [SourceDiagnostic]

        /// Creates the description of a generation.
        ///
        /// - Parameters:
        ///   - outputDirectory: The directory that relative file names were resolved against.
        ///   - files: The files that were written.
        ///   - standardOutput: The text written outside any file block.
        ///   - mainTemplate: The name of the template that ran.
        ///   - templateSet: The name of the template set, if one ran.
        public init(
            outputDirectory: URL, files: [URL], standardOutput: String?, mainTemplate: String,
            templateSet: String?
        ) {
            self.init(
                outputDirectory: outputDirectory, files: files, standardOutput: standardOutput,
                mainTemplate: mainTemplate, templateSet: templateSet, warnings: [])
        }

        /// Creates the description of a generation that reported warnings.
        ///
        /// - Parameters:
        ///   - outputDirectory: The directory that relative file names were resolved against.
        ///   - files: The files that were written.
        ///   - standardOutput: The text written outside any file block.
        ///   - mainTemplate: The name of the template that ran.
        ///   - templateSet: The name of the template set, if one ran.
        ///   - warnings: The distinct warnings of the templates, in the order in which they were
        ///     first reported.
        public init(
            outputDirectory: URL, files: [URL], standardOutput: String?, mainTemplate: String,
            templateSet: String?, warnings: [SourceDiagnostic]
        ) {
            self.outputDirectory = outputDirectory
            self.files = files
            self.standardOutput = standardOutput
            self.mainTemplate = mainTemplate
            self.templateSet = templateSet
            self.warnings = warnings
        }
    }

    /// The templates to run.
    public var templates: Templates

    /// Directories with templates.
    ///
    /// For a template set, files in these directories replace the files of the set with the same
    /// relative path, later directories taking precedence. For a single module, they are searched
    /// for the modules it imports.
    public var templatePaths: [URL]

    /// The values of the template parameters by name.
    public var parameters: [String: any EcoreValue]

    /// Further providers of services for the templates; later providers take precedence.
    public var serviceProviders: [any AQLServiceProvider]

    /// The directory that the templates write below; it is created if necessary.
    public var outputDirectory: URL

    /// The options of the generator.
    ///
    /// For a template set, the line delimiter of its descriptor and the layout of the chosen
    /// code style replace those of the options when the set defines them. Without template
    /// search paths, the paths of ``templatePaths`` are used.
    public var generatorOptions: MTLGeneratorOptions

    /// The behaviours of the template language and its expression language.
    ///
    /// A step created with ``init(templates:templatePaths:parameters:serviceProviders:outputDirectory:generatorOptions:mtlOptions:)``
    /// carries the value given there, such as `MTLOptions.standard` for the behaviour documented
    /// for this release. A step created with the initialiser of version 0.6 carries
    /// `MTLOptions.legacy`, so that its templates behave as they did in that version. Warnings,
    /// such as those of `let` blocks skipped because of `MTLLetTypeMismatches.skip`, are
    /// returned in ``Result/warnings``.
    public var mtlOptions: MTLOptions

    /// How the templates read features that a model does not set.
    ///
    /// The setting is part of ``mtlOptions``.
    public var unsetFeatureReads: UnsetFeatureReads {
        get { mtlOptions.unsetFeatureReads }
        set { mtlOptions.unsetFeatureReads = newValue }
    }

    /// Creates a generation step whose templates behave as in version 0.6.
    ///
    /// The step carries `MTLOptions.legacy` with the given way of reading unset features.
    ///
    /// - Parameters:
    ///   - templates: The templates to run.
    ///   - templatePaths: Directories with templates (default: none).
    ///   - parameters: The values of the template parameters by name (default: none).
    ///   - serviceProviders: Further providers of services (default: none).
    ///   - outputDirectory: The directory that the templates write below.
    ///   - generatorOptions: The options of the generator (default options).
    ///   - unsetFeatureReads: How unset features read (default ``UnsetFeatureReads/defaults``).
    @available(
        *, deprecated,
        message: "Use init(templates:templatePaths:parameters:serviceProviders:outputDirectory:generatorOptions:mtlOptions:); pass mtlOptions: .legacy to keep the behaviour of version 0.6"
    )
    public init(
        templates: Templates, templatePaths: [URL] = [], parameters: [String: any EcoreValue] = [:],
        serviceProviders: [any AQLServiceProvider] = [], outputDirectory: URL,
        generatorOptions: MTLGeneratorOptions = MTLGeneratorOptions(),
        unsetFeatureReads: UnsetFeatureReads = .defaults
    ) {
        var mtlOptions = MTLOptions.legacy
        mtlOptions.unsetFeatureReads = unsetFeatureReads
        self.init(
            templates: templates, templatePaths: templatePaths, parameters: parameters,
            serviceProviders: serviceProviders, outputDirectory: outputDirectory,
            generatorOptions: generatorOptions, mtlOptions: mtlOptions)
    }

    /// Creates a generation step with the given behaviours of the templates.
    ///
    /// Pass `MTLOptions.standard` for the behaviour documented for this release, or
    /// `MTLOptions.legacy` for that of version 0.6.
    ///
    /// - Parameters:
    ///   - templates: The templates to run.
    ///   - templatePaths: Directories with templates (default: none).
    ///   - parameters: The values of the template parameters by name (default: none).
    ///   - serviceProviders: Further providers of services (default: none).
    ///   - outputDirectory: The directory that the templates write below.
    ///   - generatorOptions: The options of the generator (default options).
    ///   - mtlOptions: The behaviours of the template language and its expression language,
    ///     including how unset features read.
    public init(
        templates: Templates, templatePaths: [URL] = [], parameters: [String: any EcoreValue] = [:],
        serviceProviders: [any AQLServiceProvider] = [], outputDirectory: URL,
        generatorOptions: MTLGeneratorOptions = MTLGeneratorOptions(), mtlOptions: MTLOptions
    ) {
        self.templates = templates
        self.templatePaths = templatePaths
        self.parameters = parameters
        self.serviceProviders = serviceProviders
        self.outputDirectory = outputDirectory
        self.generatorOptions = generatorOptions
        self.mtlOptions = mtlOptions
    }

    /// Runs the templates.
    ///
    /// For a template set, its data models are loaded into the resource set and made available
    /// through the service `templateData('name')`, and the progress reports carry the number of
    /// files to write when the set can predict it.
    ///
    /// - Parameters:
    ///   - arguments: The arguments of the template, in order.
    ///   - models: The models available to the templates, by name (default: none).
    ///   - resourceSet: The resource set that receives the data models of a template set
    ///     (default: a new resource set).
    ///   - progress: A receiver of progress reports; reports are dropped by default.
    /// - Returns: A description of what was written, including the warnings of the templates.
    /// - Throws: `MTLParameterError` if a parameter name is not an identifier or is reserved,
    ///   `GenerationError` if a template set cannot be assembled or fails,
    ///   ``ModelPipelineError`` if a module cannot be parsed or has no such template, and
    ///   the error of the file system if the output directory cannot be created.
    @MainActor
    public func run(
        arguments: [(any EcoreValue)?], models: [String: Resource] = [:],
        resourceSet: ResourceSet = ResourceSet(), progress: @escaping GenerationProgressReporter = { _ in }
    ) async throws -> Result {
        let parameterServices = try MTLParameterServices(values: parameters)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        var options = generatorOptions
        if options.templateSearchPaths.isEmpty { options.templateSearchPaths = templatePaths.map(\.path) }
        switch templates {
        case .templateSet(let reference, let locator, let codeStyle):
            progress(GenerationProgressUpdate(message: "Assembling the \(reference) templates"))
            let set = try locator.assemble(templateSet: reference, templatePaths: templatePaths)
            defer { set.remove() }
            if let layout = try set.descriptor.layoutConfiguration(forStyle: codeStyle) { options.layout = layout }
            if let delimiter = set.descriptor.options.lineDelimiter { options.lineDelimiter = delimiter }
            let data = try await TemplateRun.loadDataModels(of: set, into: resourceSet)
            let module = try await TemplateRun.parseMainModule(of: set)
            let services: [any AQLServiceProvider] =
                [TemplateDataServices(roots: data.roots), parameterServices] + serviceProviders
            let setModels = models.merging(data.models) { model, _ in model }
            let total = try await TemplateRun.expectedFileCount(
                of: module, descriptor: set.descriptor, arguments: arguments, services: services,
                models: setModels, mtlOptions: mtlOptions, prepare: parameterServices.bind(to:))
            return try await generate(
                module: module, mainTemplate: set.descriptor.mainTemplate, arguments: arguments,
                models: setModels, services: services, options: options, total: total,
                templateSet: set.descriptor.name, parameters: parameterServices, progress: progress)
        case .module(let url, let requested):
            let module: MTLModule
            do {
                module = try await MTLParser(searchPaths: templatePaths).parse(url)
            } catch {
                throw ModelPipelineError.templatesUnreadable(url.path, String(describing: error))
            }
            let mainTemplate = try Self.mainTemplate(of: module, requested: requested)
            return try await generate(
                module: module, mainTemplate: mainTemplate, arguments: arguments, models: models,
                services: [parameterServices] + serviceProviders, options: options, total: nil,
                templateSet: nil, parameters: parameterServices, progress: progress)
        }
    }

    /// The template of a module that a step runs.
    ///
    /// - Parameters:
    ///   - module: The parsed module.
    ///   - requested: The name of the template to run, if one was chosen.
    /// - Returns: The requested template, else the first main template by name, else the first
    ///   template by name.
    /// - Throws: ``ModelPipelineError/templateNotFound(_:_:)`` if the requested template does
    ///   not exist, and ``ModelPipelineError/noTemplates(_:)`` if the module has no templates.
    static func mainTemplate(of module: MTLModule, requested: String?) throws -> String {
        if let requested {
            guard module.templates[requested] != nil else {
                throw ModelPipelineError.templateNotFound(requested, module.name)
            }
            return requested
        }
        let names = module.templates.keys.sorted()
        if let main = names.first(where: { module.templates[$0]?.isMain == true }) { return main }
        guard let first = names.first else { throw ModelPipelineError.noTemplates(module.name) }
        return first
    }

    /// Runs a parsed module and describes what it wrote.
    @MainActor
    private func generate(
        module: MTLModule, mainTemplate: String, arguments: [(any EcoreValue)?], models: [String: Resource],
        services: [any AQLServiceProvider], options: MTLGeneratorOptions, total: Int?, templateSet: String?,
        parameters: MTLParameterServices, progress: @escaping GenerationProgressReporter
    ) async throws -> Result {
        let base = outputDirectory.standardizedFileURL
        progress(GenerationProgressUpdate(message: "Generating with \(templateSet ?? module.name)", total: total))
        let output = try await TemplateRun.run(
            module: module, mainTemplate: mainTemplate, arguments: arguments, models: models,
            services: services, options: options, outputDirectory: base, total: total,
            mtlOptions: mtlOptions, keepsStandardOutput: true, progress: progress, prepare: parameters.bind(to:))
        let count = output.files.count
        progress(GenerationProgressUpdate(message: "Done", completed: count, total: total ?? count))
        return Result(
            outputDirectory: base, files: output.files, standardOutput: output.standardOutput,
            mainTemplate: mainTemplate, templateSet: templateSet, warnings: output.warnings)
    }
}
