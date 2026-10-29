//
// TemplateRun.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Foundation
import MTL

/// The steps of a template run that the generation pipelines of this package share.
///
/// A run loads the data models of a template set, parses its main module, optionally counts
/// the files it will write, and runs the main template with a strategy that reports every
/// finished file.
package enum TemplateRun {
    /// The loaded data models of a template set.
    package struct DataModels {
        /// The root objects of each model by its name in the template set.
        package var roots: [String: [DynamicEObject]] = [:]

        /// The resources that hold the models and their metamodels.
        package var resources: [Resource] = []

        /// Creates an empty collection of data models.
        package init() {}

        /// The models by the alias under which templates reach them.
        ///
        /// - Returns: Each resource under ``TemplateSetConstants/dataModelAliasPrefix`` followed
        ///   by its position.
        package var models: [String: Resource] {
            var models: [String: Resource] = [:]
            for (index, resource) in resources.enumerated() {
                models["\(TemplateSetConstants.dataModelAliasPrefix)\(index)"] = resource
            }
            return models
        }
    }

    /// What a template run wrote.
    package struct Output: Sendable {
        /// The files that the templates wrote, in the order they were finished.
        package var files: [URL]

        /// The text written outside any file block, if it was kept and there was any.
        package var standardOutput: String?

        /// The distinct warnings of the templates, in the order in which they were first reported.
        package var warnings: [SourceDiagnostic] = []
    }

    /// Loads the data models of a template set and registers their metamodels.
    ///
    /// - Parameters:
    ///   - set: The assembled template set.
    ///   - resourceSet: The resource set that receives the models and their metamodels.
    /// - Returns: The loaded models.
    /// - Throws: ``GenerationError/templateSetInvalid(_:_:)`` if a model cannot be loaded.
    package static func loadDataModels(of set: TemplateSet, into resourceSet: ResourceSet) async throws
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

    /// Parses the main module of a template set.
    ///
    /// - Parameter set: The assembled template set.
    /// - Returns: The parsed module, with its imports resolved through the search paths of the set.
    /// - Throws: ``GenerationError/templateSetInvalid(_:_:)`` if the templates cannot be parsed.
    package static func parseMainModule(of set: TemplateSet) async throws -> MTLModule {
        do {
            return try await MTLParser(searchPaths: set.searchPaths).parse(set.mainModuleURL)
        } catch {
            throw GenerationError.templateSetInvalid(
                set.descriptor.name, "the templates cannot be parsed: \(error)")
        }
    }

    /// The number of files that a template set will write, from its file count template.
    ///
    /// - Parameters:
    ///   - module: The parsed main module of the template set.
    ///   - descriptor: The descriptor of the template set.
    ///   - arguments: The arguments of the main template.
    ///   - services: The services available to the templates.
    ///   - models: The models available to the templates, by alias.
    ///   - unsetFeatureReads: How the templates read features that a model does not set.
    ///   - letTypeMismatches: How a typed `let` treats a value that does not conform to its type.
    ///   - prepare: Prepares the counting generator, such as by binding global variables.
    /// - Returns: The number of files, or `nil` if the template set has no file count template.
    /// - Throws: ``GenerationError`` if the file count template is missing or fails.
    @MainActor
    package static func expectedFileCount(
        of module: MTLModule, descriptor: TemplateSetDescriptor, arguments: [(any EcoreValue)?],
        services: [any AQLServiceProvider], models: [String: Resource],
        unsetFeatureReads: UnsetFeatureReads, letTypeMismatches: MTLLetTypeMismatches = .error,
        prepare: @MainActor (MTLGenerator) -> Void = { _ in }
    ) async throws -> Int? {
        guard let name = descriptor.fileCountTemplate else { return nil }
        guard !module.templates(named: name).isEmpty else {
            throw GenerationError.templateSetInvalid(
                descriptor.name, "the file count template '\(name)' is missing")
        }
        let counting = MTLInMemoryStrategy()
        let generator = MTLGenerator(
            module: module, generationStrategy: counting, serviceProviders: services,
            unsetFeatureReads: unsetFeatureReads, letTypeMismatches: letTypeMismatches)
        prepare(generator)
        do {
            try await generator.generate(mainTemplate: name, arguments: arguments, models: models)
        } catch {
            throw GenerationError.generationFailed(String(describing: error))
        }
        let counts = await counting.getGeneratedFiles().values.compactMap {
            Int($0.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return counts.first
    }

    /// Runs a template and writes its files below a directory.
    ///
    /// Each finished file is reported to the progress receiver, with the total if it is known.
    ///
    /// - Parameters:
    ///   - module: The parsed module.
    ///   - mainTemplate: The name of the template to run.
    ///   - arguments: The arguments of the template.
    ///   - models: The models available to the templates, by alias.
    ///   - services: The services available to the templates.
    ///   - options: The options of the file system strategy.
    ///   - outputDirectory: The directory that relative file names are resolved against.
    ///   - total: The number of files that will be written, if known.
    ///   - unsetFeatureReads: How the templates read features that a model does not set.
    ///   - letTypeMismatches: How a typed `let` treats a value that does not conform to its type.
    ///   - keepsStandardOutput: Whether text written outside any file block is kept and returned,
    ///     instead of being discarded.
    ///   - progress: The receiver of progress reports.
    ///   - prepare: Prepares the generator, such as by binding global variables.
    /// - Returns: The files written, the text written outside any file block and the warnings.
    /// - Throws: ``GenerationError/generationFailed(_:)`` if the templates fail.
    @MainActor
    package static func run(
        module: MTLModule, mainTemplate: String, arguments: [(any EcoreValue)?],
        models: [String: Resource], services: [any AQLServiceProvider], options: MTLGeneratorOptions,
        outputDirectory: URL, total: Int?, unsetFeatureReads: UnsetFeatureReads,
        letTypeMismatches: MTLLetTypeMismatches = .error, keepsStandardOutput: Bool = false, progress: @escaping GenerationProgressReporter,
        prepare: @MainActor (MTLGenerator) -> Void = { _ in }
    ) async throws -> Output {
        let files = MTLFileSystemStrategy(
            basePath: outputDirectory.path, options: options,
            standardOutput: keepsStandardOutput ? .capture : .discard)
        let strategy = GenerationProgressStrategy(
            wrapping: files, outputDirectory: outputDirectory, total: total, report: progress,
            keepsStandardOutput: keepsStandardOutput)
        let generator = MTLGenerator(
            module: module, generationStrategy: strategy, serviceProviders: services,
            unsetFeatureReads: unsetFeatureReads, letTypeMismatches: letTypeMismatches)
        prepare(generator)
        do {
            try await generator.generate(mainTemplate: mainTemplate, arguments: arguments, models: models)
        } catch {
            throw GenerationError.generationFailed(String(describing: error))
        }
        return Output(
            files: await strategy.completedFiles, standardOutput: await files.standardOutput,
            warnings: generator.statistics.warnings)
    }
}
