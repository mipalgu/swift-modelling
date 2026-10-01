//
// GenerationPipeline+Generate.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Foundation
import GenModel
import MTL

extension GenerationPipeline {
    /// Generates code from a generator model with the template set of a language.
    ///
    /// The generator model and the Ecore models it describes are loaded, the template set of the
    /// language is assembled from the bundled set and the override directories in
    /// ``GenerationOptions/templatePaths``, the generator model services and the data models of the
    /// set are registered, and the main template of the set runs with the generator model as its
    /// argument. Files are written below the output directory.
    ///
    /// Existing files are treated as ``GenerationOptions`` describes. Progress reports follow
    /// each finished file and carry the total when the template set can predict it.
    ///
    /// - Parameters:
    ///   - genModelURL: The location of the `.genmodel` file.
    ///   - language: The language, which names the template set.
    ///   - outputDirectory: The directory to write below; it is created if necessary.
    ///   - options: The settings of the generation.
    ///   - progress: A receiver of progress reports; reports are dropped by default.
    /// - Returns: A description of what was written.
    /// - Throws: ``GenerationError`` if the generator model or template set cannot be read, the
    ///   language is unknown, or the templates fail.
    @MainActor
    public static func generate(
        genModelURL: URL, language: String, outputDirectory: URL,
        options: GenerationOptions = GenerationOptions(),
        progress: @escaping GenerationProgressReporter = { _ in }
    ) async throws -> GenerationResult {
        let source = genModelURL.standardizedFileURL
        guard FileManager.default.fileExists(atPath: source.path) else {
            throw GenerationError.sourceModelNotFound(source.path)
        }
        progress(GenerationProgressUpdate(message: "Assembling the \(language) templates"))
        let templateSet = try TemplateSet.assemble(language: language, templatePaths: options.templatePaths)
        defer { templateSet.remove() }

        progress(GenerationProgressUpdate(message: "Loading \(source.lastPathComponent)"))
        let resourceSet = ResourceSet()
        let document = try await loadGenModel(source, into: resourceSet)
        guard let root = await document.resource.getRootObjects().first as? DynamicEObject else {
            throw GenerationError.genModelUnreadable(source.path, "the document is empty")
        }
        let context = await GenModelContext.snapshot(
            of: [document.resource], ecorePackages: ecorePackages(of: document),
            instanceTypeNames: instanceTypeNames(of: document))
        guard let genModel = context.element(id: root.id) else {
            throw GenerationError.genModelUnreadable(source.path, "the document is not a generator model")
        }

        let data = try await loadDataModels(of: templateSet, into: resourceSet)
        let module = try await parseMainModule(of: templateSet)
        let base = outputBase(
            for: genModel, descriptor: templateSet.descriptor, in: outputDirectory, options: options)
        let services: [any AQLServiceProvider] = [
            GenModelServices(context: context), TemplateDataServices(roots: data.roots),
        ]
        var models: [String: Resource] = [TemplateSetConstants.genModelAlias: document.resource]
        for (index, resource) in data.resources.enumerated() {
            models["\(TemplateSetConstants.dataModelAliasPrefix)\(index)"] = resource
        }
        for (index, package) in document.foreignPackages.sorted(by: { $0.key.path < $1.key.path }).enumerated() {
            if let resource = await resourceSet.getResource(uri: package.key.absoluteString) {
                models["ECORE_\(index)"] = resource
            }
        }
        let total = try await expectedFileCount(
            of: module, descriptor: templateSet.descriptor, root: root, services: services, models: models)

        var generatorOptions = MTLGeneratorOptions(
            forceOverwrite: options.forceOverwrite, redirectionPattern: options.effectiveRedirectionPattern,
            lineDelimiter: options.lineDelimiter ?? templateSet.descriptor.options.lineDelimiter ?? "\n",
            templateSearchPaths: options.templatePaths.map(\.path))
        if options.forceOverwrite { generatorOptions.redirectionPattern = nil }
        let strategy = GenerationProgressStrategy(
            wrapping: MTLFileSystemStrategy(basePath: base.path, options: generatorOptions),
            outputDirectory: base, total: total, report: progress)
        let generator = MTLGenerator(module: module, generationStrategy: strategy, serviceProviders: services)

        progress(GenerationProgressUpdate(message: "Generating \(language) code", total: total))
        do {
            try await generator.generate(
                mainTemplate: templateSet.descriptor.mainTemplate, arguments: [root], models: models)
        } catch {
            throw GenerationError.generationFailed(String(describing: error))
        }
        let files = await strategy.completedFiles
        progress(GenerationProgressUpdate(message: "Done", completed: files.count, total: total ?? files.count))
        return GenerationResult(
            outputDirectory: base, files: files, language: templateSet.descriptor.name,
            packageCount: genModel.allGenPackages.count)
    }

    // MARK: - Loading

    private static func loadGenModel(_ url: URL, into resourceSet: ResourceSet) async throws -> GenModelDocument {
        do {
            return try await GenModelResource.loadDocument(
                url: url, resourceSet: resourceSet, resolution: .nameFragments)
        } catch {
            throw GenerationError.genModelUnreadable(url.path, String(describing: error))
        }
    }

    private static func ecorePackages(of document: GenModelDocument) -> [EPackage] {
        document.foreignPackages.sorted { $0.key.path < $1.key.path }.map(\.value) + [EcorePackage.instance]
    }

    /// The instance class names of the classes of all source models, by class identifier.
    private static func instanceTypeNames(of document: GenModelDocument) -> [EUUID: String] {
        var names: [EUUID: String] = [:]
        func visit(_ package: EPackage) {
            for case let eClass as EClass in package.eClassifiers {
                if let name = eClass.instanceClassName, !name.isEmpty { names[eClass.id] = name }
            }
            package.eSubpackages.forEach(visit)
        }
        document.foreignPackages.values.forEach(visit)
        return names
    }

    /// The loaded data models of a template set.
    struct DataModels {
        /// The root objects of each model by its name in the template set.
        var roots: [String: [DynamicEObject]] = [:]
        /// The resources that hold the models.
        var resources: [Resource] = []
    }

    private static func loadDataModels(of set: TemplateSet, into resourceSet: ResourceSet) async throws
        -> DataModels
    {
        var result = DataModels()
        for entry in set.descriptor.dataModels {
            let metamodelURL = set.directory.appendingPathComponent(entry.metamodel)
            let modelURL = set.directory.appendingPathComponent(entry.model)
            do {
                let metamodelResource = try await resourceSet.loadEcoreResource(uri: metamodelURL.absoluteString)
                for case let package as EPackage in await metamodelResource.getRootObjects() {
                    await resourceSet.registerMetamodel(package, uri: package.nsURI)
                }
                let model = try await resourceSet.loadXMIResource(uri: modelURL.absoluteString)
                result.roots[entry.name] = await model.getRootObjects().compactMap { $0 as? DynamicEObject }
                result.resources.append(model)
                result.resources.append(metamodelResource)
            } catch {
                throw GenerationError.templateSetInvalid(
                    set.descriptor.name, "the data model '\(entry.name)' cannot be loaded: \(error)")
            }
        }
        return result
    }

    private static func parseMainModule(of set: TemplateSet) async throws -> MTLModule {
        do {
            return try await MTLParser(searchPaths: [set.directory]).parse(set.mainModuleURL)
        } catch {
            throw GenerationError.templateSetInvalid(
                set.descriptor.name, "the templates cannot be parsed: \(error)")
        }
    }

    // MARK: - Layout and counting

    private static func outputBase(
        for genModel: GenElement, descriptor: TemplateSetDescriptor, in directory: URL,
        options: GenerationOptions
    ) -> URL {
        var base = directory.standardizedFileURL
        let includes = options.includeSourceRoot ?? descriptor.layout.includeSourceRoot
        if includes, let setting = descriptor.layout.sourceRootSetting,
            let root = GenModelServices.setting(setting, of: genModel) as? String
        {
            let relative = root.drop(while: { $0 == "/" })
            if !relative.isEmpty { base = base.appendingPathComponent(String(relative)) }
        }
        return base
    }

    @MainActor
    private static func expectedFileCount(
        of module: MTLModule, descriptor: TemplateSetDescriptor, root: DynamicEObject,
        services: [any AQLServiceProvider], models: [String: Resource]
    ) async throws -> Int? {
        guard let name = descriptor.fileCountTemplate else { return nil }
        guard !module.templates(named: name).isEmpty else {
            throw GenerationError.templateSetInvalid(
                descriptor.name, "the file count template '\(name)' is missing")
        }
        let counting = MTLInMemoryStrategy()
        let generator = MTLGenerator(module: module, generationStrategy: counting, serviceProviders: services)
        do {
            try await generator.generate(mainTemplate: name, arguments: [root], models: models)
        } catch {
            throw GenerationError.generationFailed(String(describing: error))
        }
        let counts = await counting.getGeneratedFiles().values.compactMap {
            Int($0.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return counts.first
    }
}
