//
// GenerationPipeline+Model.swift
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
    /// Exports a model of a metamodel with the model template of a template set.
    ///
    /// The template set of the language is assembled as for
    /// ``generate(genModelURL:language:outputDirectory:options:progress:)``, and its descriptor
    /// must name a ``TemplateSetDescriptor/modelTemplate``. The metamodel is registered, the
    /// model is read in the format of its extension or contents, such as XMI or JSON, and the
    /// model template runs with the root package of the metamodel that declares the class of
    /// the model's root object and with that root object as its arguments. The global variable
    /// ``TemplateSetConstants/modelNameVariable`` holds the name of the model file without its
    /// extension, and the services of the data models of the set and the
    /// ``VerificationServices`` are available to the templates. Files are written below the
    /// output directory.
    ///
    /// A model export reads every feature that the model does not set as undefined, whatever
    /// ``GenerationOptions/unsetFeatureReads`` says, so that an unset optional value is absent
    /// from the export rather than replaced by its default.
    ///
    /// ```swift
    /// let result = try await GenerationPipeline.generate(
    ///     modelURL: URL(fileURLWithPath: "model/branch.xmi"),
    ///     metamodelURL: URL(fileURLWithPath: "model/library.ecore"),
    ///     language: "alloy", outputDirectory: URL(fileURLWithPath: "verification"))
    /// print(result.files.map(\.lastPathComponent))
    /// ```
    ///
    /// - Parameters:
    ///   - modelURL: The location of the model to export.
    ///   - metamodelURL: The location of its metamodel: an Ecore model or another metamodel
    ///     format that the model format registry reads, or a generator model, whose Ecore models
    ///     are then the metamodel.
    ///   - language: The language, which names the template set.
    ///   - outputDirectory: The directory to write below; it is created if necessary.
    ///   - options: The settings of the generation (default: the behaviour documented for this
    ///     release).
    ///   - progress: A receiver of progress reports; reports are dropped by default.
    /// - Returns: A description of what was written, including the warnings of the templates;
    ///   its ``GenerationResult/packageCount`` is the number of root packages of the metamodel.
    /// - Throws: ``GenerationError/modelNotFound(_:)`` or ``GenerationError/modelUnreadable(_:_:)``
    ///   if the model cannot be read, ``GenerationError/sourceModelNotFound(_:)`` or
    ///   ``GenerationError/sourceModelUnreadable(_:_:)`` if the metamodel cannot be read,
    ///   ``GenerationError/noModelTemplate(_:)`` if the template set cannot export models, and
    ///   the other cases of ``GenerationError`` if the template set is unknown or invalid or the
    ///   templates fail.
    @MainActor
    public static func generate(
        modelURL: URL, metamodelURL: URL, language: String, outputDirectory: URL,
        options: GenerationOptions = GenerationOptions(mtlOptions: .standard),
        progress: @escaping GenerationProgressReporter = { _ in }
    ) async throws -> GenerationResult {
        let model = modelURL.standardizedFileURL
        let metamodel = metamodelURL.standardizedFileURL
        guard FileManager.default.fileExists(atPath: metamodel.path) else {
            throw GenerationError.sourceModelNotFound(metamodel.path)
        }
        guard FileManager.default.fileExists(atPath: model.path) else {
            throw GenerationError.modelNotFound(model.path)
        }
        progress(GenerationProgressUpdate(message: "Assembling the \(language) templates"))
        let templateSet = try TemplateSet.assemble(language: language, templatePaths: options.templatePaths)
        defer { templateSet.remove() }
        let descriptor = templateSet.descriptor
        guard let modelTemplate = descriptor.modelTemplate else {
            throw GenerationError.noModelTemplate(descriptor.name)
        }
        let layout = try descriptor.layoutConfiguration(forStyle: options.codeStyle)

        progress(GenerationProgressUpdate(message: "Loading \(metamodel.lastPathComponent)"))
        let resourceSet = ResourceSet(defaultContainerLookupScope: options.containerLookupScope)
        let metamodels = try await registerMetamodels(of: metamodel, in: resourceSet)
        progress(GenerationProgressUpdate(message: "Loading \(model.lastPathComponent)"))
        let instance: Resource
        do {
            instance = try await ModelIO.load(url: model, resourceSet: resourceSet).resource
        } catch {
            throw GenerationError.modelUnreadable(model.path, String(describing: error))
        }
        guard let root = await instance.getRootObjects().first else {
            throw GenerationError.modelUnreadable(model.path, "the document is empty")
        }
        guard let package = rootPackage(declaring: root, among: metamodels.packages) else {
            throw GenerationError.noRootPackage(metamodel.path)
        }

        let data = try await TemplateRun.loadDataModels(of: templateSet, into: resourceSet)
        let parsed = try await TemplateRun.parseMainModule(of: templateSet, encoding: options.templateEncoding)
        let module = parsed.module
        let services: [any AQLServiceProvider] = [TemplateDataServices(roots: data.roots), VerificationServices()]
        var models: [String: Resource] = [TemplateSetConstants.modelAlias: instance]
        models.merge(data.models) { _, data in data }
        for (index, resource) in metamodels.resources.enumerated() {
            models[TemplateSetConstants.ecoreModelAliasPrefix + String(index)] = resource
        }
        var mtlOptions = options.mtlOptions
        mtlOptions.unsetFeatureReads = .undefined
        let name = model.deletingPathExtension().lastPathComponent
        let bindName: @MainActor (MTLGenerator) -> Void = { generator in
            generator.setGlobalVariable(TemplateSetConstants.modelNameVariable, value: name)
        }
        let arguments: [(any EcoreValue)?] = [package, root]
        let total = try await TemplateRun.expectedFileCount(
            of: module, template: descriptor.modelFileCountTemplate, descriptor: descriptor,
            arguments: arguments, services: services, models: models, mtlOptions: mtlOptions, prepare: bindName)

        var generatorOptions = MTLGeneratorOptions(
            forceOverwrite: options.forceOverwrite, redirectionPattern: options.effectiveRedirectionPattern,
            lineDelimiter: options.lineDelimiter ?? descriptor.options.lineDelimiter ?? "\n",
            templateSearchPaths: options.templatePaths.map(\.path))
        if options.forceOverwrite { generatorOptions.redirectionPattern = nil }
        generatorOptions.layout = layout

        let base = outputDirectory.standardizedFileURL
        progress(GenerationProgressUpdate(message: "Exporting \(model.lastPathComponent) to \(language)", total: total))
        let output = try await TemplateRun.run(
            module: module, mainTemplate: modelTemplate, arguments: arguments, models: models,
            services: services, options: generatorOptions, outputDirectory: base, total: total,
            mtlOptions: mtlOptions, progress: progress, prepare: bindName)
        let files = output.files
        progress(GenerationProgressUpdate(message: "Done", completed: files.count, total: total ?? files.count))
        return GenerationResult(
            outputDirectory: base, files: files, language: descriptor.name,
            packageCount: metamodels.packages.count, warnings: output.warnings,
            decodingWarnings: parsed.decodingWarnings)
    }

    // MARK: - Metamodels of a model export

    /// Registers the metamodel of a model export with a resource set.
    ///
    /// - Parameters:
    ///   - url: The location of the metamodel, or of a generator model whose Ecore models are
    ///     the metamodel.
    ///   - resourceSet: The resource set that receives the metamodel.
    /// - Returns: The root packages of the metamodel and the resources that hold them.
    /// - Throws: ``GenerationError/sourceModelUnreadable(_:_:)`` if the metamodel cannot be read,
    ///   and ``GenerationError/noRootPackage(_:)`` if it holds no package.
    @MainActor
    private static func registerMetamodels(
        of url: URL, in resourceSet: ResourceSet
    ) async throws -> (packages: [EPackage], resources: [Resource]) {
        let packages: [EPackage]
        var resources: [Resource] = []
        do {
            let locations = try await metamodelLocations(of: url)
            packages = try await ModelIO.registerMetamodels(at: locations, in: resourceSet)
            for location in locations {
                if let resource = await resourceSet.getResource(
                    uri: URIReference.canonicalise(location.absoluteString))
                {
                    resources.append(resource)
                }
            }
        } catch {
            throw GenerationError.sourceModelUnreadable(url.path, String(describing: error))
        }
        guard !packages.isEmpty else { throw GenerationError.noRootPackage(url.path) }
        return (packages, resources)
    }

    /// The locations of the metamodels that a file names.
    ///
    /// - Parameter url: The location of a metamodel or of a generator model.
    /// - Returns: The Ecore models of a generator model, in the order of their paths, or the
    ///   location itself for any other file.
    /// - Throws: The error of the generator model reader if a generator model cannot be read.
    @MainActor
    private static func metamodelLocations(of url: URL) async throws -> [URL] {
        guard url.pathExtension.lowercased() == GenModelConstants.genModelFileExtension else { return [url] }
        let document = try await GenModelResource.loadDocument(
            url: url, resourceSet: ResourceSet(), resolution: .nameFragments)
        return document.foreignPackages.keys.sorted { $0.path < $1.path }
    }

    /// The root package that declares the class of an object, directly or in a nested package.
    ///
    /// - Parameters:
    ///   - object: The object, such as the root object of a model.
    ///   - packages: The root packages of the metamodel.
    /// - Returns: The root package that declares the class of the object, else the first root
    ///   package, or `nil` if there is none.
    static func rootPackage(declaring object: any EObject, among packages: [EPackage]) -> EPackage? {
        guard let eClass = object.eClass as? EClass else { return packages.first }
        func declares(_ package: EPackage) -> Bool {
            package.eClassifiers.contains { $0.id == eClass.id } || package.eSubpackages.contains(where: declares)
        }
        return packages.first(where: declares) ?? packages.first(where: { package in
            package.eClassifiers.contains { $0.name == eClass.name }
        }) ?? packages.first
    }
}
