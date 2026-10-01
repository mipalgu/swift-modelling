//
// GenerationPipeline.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import GenModel

/// A receiver of progress messages from the generation pipeline.
public typealias GenerationProgress = @Sendable (String) -> Void

/// The pipeline that turns Ecore models into generator models.
///
/// The pipeline loads the Ecore models, runs the bundled Ecore to generator model
/// transformation with the settings that the Eclipse Ecore importer gives a freshly
/// imported model, optionally keeps the settings of an existing generator model, and
/// writes the result in the layout that the Eclipse Modeling Framework uses.
///
/// ## Example
///
/// ```swift
/// var options = GenModelImportOptions()
/// options.basePackage = "org.example"
/// let result = try await GenerationPipeline.ecoreToGenModel(
///     ecoreURLs: [URL(fileURLWithPath: "model/library.ecore")], options: options)
/// print(result.url.path)
/// ```
public enum GenerationPipeline {
    /// Imports Ecore models into a generator model and writes it.
    ///
    /// Each source model contributes its root packages as generator packages of one
    /// generator model. The generator model refers to the source models by relative
    /// locations, so the files should stay where they are relative to the output.
    ///
    /// The model project is the option ``GenModelImportOptions/modelProject`` if given,
    /// otherwise the parent directory of the first source model when that lives in a
    /// directory named `model`, otherwise the name of the first root package.
    ///
    /// - Parameters:
    ///   - ecoreURLs: The locations of the Ecore models, the first of which names the output.
    ///   - options: The settings of the import.
    ///   - progress: A receiver of progress messages; messages are dropped by default.
    /// - Returns: A description of the generator model that was written.
    /// - Throws: ``GenerationError`` if a model is missing or unreadable, the transformation
    ///   fails, or the output cannot be written.
    @MainActor
    public static func ecoreToGenModel(
        ecoreURLs: [URL], options: GenModelImportOptions = GenModelImportOptions(),
        progress: GenerationProgress = { _ in }
    ) async throws -> GenModelResult {
        guard let first = ecoreURLs.first else { throw GenerationError.noSourceModels }
        let sources = ecoreURLs.map(\.standardizedFileURL)
        for url in sources where !FileManager.default.fileExists(atPath: url.path) {
            throw GenerationError.sourceModelNotFound(url.path)
        }
        let output = (options.output ?? defaultOutput(for: first)).standardizedFileURL

        let resourceSet = ResourceSet()
        let generatorMetamodel: EPackage
        do {
            generatorMetamodel = try await GenModelPackage.load()
        } catch {
            throw GenerationError.transformationUnavailable(String(describing: error))
        }
        await resourceSet.registerMetamodel(generatorMetamodel, uri: GenModelConstants.nsURI)
        await GenModelFragments.register(in: resourceSet)

        progress("Loading the transformation")
        let transformation = try await GenModelTransformation.load(generatorMetamodel: generatorMetamodel)

        var loaded: [(url: URL, resource: Resource, package: EPackage)] = []
        for url in sources {
            progress("Loading \(url.lastPathComponent)")
            loaded.append(try await loadSource(url, into: resourceSet))
        }

        let target = await resourceSet.createResource(uri: output.absoluteString)
        let parameters = GenModelTransformation.parameters(
            options: options,
            modelProject: modelProject(for: first, options: options),
            modelName: modelName(forOutput: output),
            foreignModels: sources.map { URIReference.relativise($0.absoluteString, against: output.absoluteString) })
        for (index, source) in loaded.enumerated() {
            progress("Transforming \(source.url.lastPathComponent) (\(index + 1) of \(loaded.count))")
            try await transformation.run(source: source.resource, target: target, parameters: parameters)
        }
        try await mergeGenModels(in: target)

        progress("Completing the generator model")
        var complianceLevel = options.complianceLevel
        if complianceLevel == nil && options.reload == nil {
            complianceLevel = GenModelImportConstants.defaultComplianceLevel
        }
        await GenModelFinaliser.finalise(
            target, in: resourceSet, sources: loaded.map(\.package), complianceLevel: complianceLevel)

        var reloaded = false
        if let reload = options.reload {
            progress("Reconciling with \(reload.lastPathComponent)")
            try await GenModelReconciler.reconcile(
                target, in: resourceSet, with: reload.standardizedFileURL, overriding: options)
            reloaded = true
        }

        progress("Writing \(output.lastPathComponent)")
        do {
            try FileManager.default.createDirectory(
                at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
            try await GenModelResource.save(target, to: output)
        } catch {
            throw GenerationError.outputFailed(output.path, String(describing: error))
        }
        return await summary(of: target, resourceSet: resourceSet, url: output, reloaded: reloaded)
    }

    /// The location of the generator model written for a source model when no output is given.
    ///
    /// - Parameter ecoreURL: The location of the source model.
    /// - Returns: A file beside the source model, named after it, with the generator model extension.
    public static func defaultOutput(for ecoreURL: URL) -> URL {
        ecoreURL.deletingPathExtension().appendingPathExtension(GenModelConstants.genModelFileExtension)
    }

    /// The name of the model project for a source model.
    ///
    /// - Parameters:
    ///   - ecoreURL: The location of the first source model.
    ///   - options: The import options.
    /// - Returns: The explicit project name, otherwise the name of the parent directory when the
    ///   source model lives in a directory named `model`, otherwise empty text, which lets the
    ///   transformation use the name of the root package.
    static func modelProject(for ecoreURL: URL, options: GenModelImportOptions) -> String {
        if let project = options.modelProject, !project.isEmpty { return project }
        let directory = ecoreURL.standardizedFileURL.deletingLastPathComponent()
        guard directory.lastPathComponent == GenModelImportConstants.modelFolderName else { return "" }
        return directory.deletingLastPathComponent().lastPathComponent
    }

    /// The name of a generator model, derived from the file it is written to.
    ///
    /// - Parameter output: The generator model file.
    /// - Returns: The file name without its extensions, with its first letter in upper case.
    static func modelName(forOutput output: URL) -> String {
        var name = output.deletingPathExtension().lastPathComponent
        if let dot = name.lastIndex(of: ".") { name = String(name[..<dot]) }
        return GenModelNaming.capName(name)
    }

    private static func loadSource(_ url: URL, into resourceSet: ResourceSet) async throws
        -> (url: URL, resource: Resource, package: EPackage)
    {
        do {
            let resource = try await resourceSet.loadEcoreResource(uri: url.absoluteString)
            guard let package = await resource.getRootObjects().first as? EPackage else {
                throw GenerationError.noRootPackage(url.path)
            }
            return (url, resource, package)
        } catch let error as GenerationError {
            throw error
        } catch {
            throw GenerationError.sourceModelUnreadable(url.path, String(describing: error))
        }
    }

    /// Moves the packages of every further generator model into the first and discards the rest.
    private static func mergeGenModels(in target: Resource) async throws {
        let models = await target.getRootObjects().compactMap { $0 as? DynamicEObject }
            .filter { $0.eClass.name == GenModelConstants.ClassName.genModel }
        guard let primary = models.first else {
            throw GenerationError.transformationFailed("the transformation produced no generator model")
        }
        let feature = GenModelConstants.FeatureName.genPackages
        var packages = await target.eGet(objectId: primary.id, feature: feature).map(identifiers(in:)) ?? []
        for extra in models.dropFirst() {
            if let more = await target.eGet(objectId: extra.id, feature: feature) {
                packages += identifiers(in: more)
            }
            _ = await target.remove(id: extra.id)
        }
        if models.count > 1 {
            _ = await target.eSet(objectId: primary.id, feature: feature, value: packages)
        }
    }

    private static func identifiers(in value: any EcoreValue) -> [EUUID] {
        switch value {
        case let id as EUUID: return [id]
        case let ids as [EUUID]: return ids
        default: return []
        }
    }

    private static func summary(
        of target: Resource, resourceSet: ResourceSet, url: URL, reloaded: Bool
    ) async -> GenModelResult {
        var counts: [String: Int] = [:]
        for case let object as DynamicEObject in await target.getAllObjects() {
            counts[object.eClass.name, default: 0] += 1
        }
        typealias Name = GenModelConstants.ClassName
        return GenModelResult(
            url: url, resourceSet: resourceSet, resource: target,
            packageCount: counts[Name.genPackage] ?? 0, classCount: counts[Name.genClass] ?? 0,
            enumCount: counts[Name.genEnum] ?? 0, dataTypeCount: counts[Name.genDataType] ?? 0,
            featureCount: counts[Name.genFeature] ?? 0,
            operationCount: counts[Name.genOperation] ?? 0, reloaded: reloaded)
    }
}
