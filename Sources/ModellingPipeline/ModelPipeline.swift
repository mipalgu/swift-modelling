//
// ModelPipeline.swift
// ModellingPipeline
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingGenerators

/// A sequence of steps that load, transform, generate from and save models.
///
/// A pipeline runs its ``steps`` in order over one ``ECore/ResourceSet``. Each model it loads
/// or creates is kept under a name, by which later steps refer to it: a transformation reads
/// its source models and stores its target models by name, a generation passes the root objects
/// of named models to its template, and a save writes a named model. Models are read and written
/// with ``ECore/ModelIO``, in any format it supports, and what a conversion cannot keep is
/// collected in one ``ECore/ConversionDiagnostics``. Progress is reported to a
/// `GenerationProgressReporter`.
///
/// ## Example
///
/// ```swift
/// let pipeline = ModelPipeline(steps: [
///     .registerMetamodels([familiesEcore, personsEcore]),
///     .load(name: "IN", url: familiesXMI),
///     .transform(TransformationStep(moduleURL: families2Persons), targets: ["OUT": "persons"]),
///     .save(name: "persons", url: personsJSON),
/// ])
/// let result = try await pipeline.run()
/// for warning in result.diagnostics.warnings { print(warning) }
/// ```
public struct ModelPipeline: Sendable {
    /// A step of a model pipeline.
    public enum Step: Sendable {
        /// Loads Ecore documents and registers their packages as metamodels.
        case registerMetamodels([URL])

        /// Registers metamodel packages that are already loaded, such as built-in ones.
        case registerPackages([EPackage])

        /// Loads a model or metamodel document and keeps it under a name.
        ///
        /// Without a format, the format is taken from the file extension or the contents.
        case load(name: String, url: URL, format: ModelFormat? = nil, options: ModelIO.LoadOptions = ModelIO.LoadOptions())

        /// Runs a transformation and keeps its target models.
        ///
        /// `sources` maps an alias that the module declares to the name of a pipeline model, and
        /// `targets` maps a target alias to the name under which the pipeline keeps the target.
        /// A source alias without a mapping reads the pipeline model of the same name, and a
        /// target alias without a mapping is kept under its own name.
        case transform(TransformationStep, sources: [String: String] = [:], targets: [String: String] = [:])

        /// Runs a generation with the root objects of named models as the template arguments.
        ///
        /// Every model of the pipeline is available to the templates under its name.
        case generate(GenerationStep, arguments: [String] = [])

        /// Writes a named model to a file.
        ///
        /// Without a format, the format is taken from the file extension.
        case save(name: String, url: URL, format: ModelFormat? = nil, xmiOptions: XMISerializationOptions = .legacy)
    }

    /// What a pipeline produced.
    public struct Result: Sendable {
        /// The resource set over which the pipeline ran.
        public let resourceSet: ResourceSet

        /// The models of the pipeline by name.
        public let models: [String: Resource]

        /// What the conversions of the pipeline could not keep.
        public let diagnostics: ConversionDiagnostics

        /// The files that the generation steps wrote, in order.
        public let generatedFiles: [URL]

        /// The results of the generation steps, in order.
        public let generations: [GenerationStep.Result]
    }

    /// The steps, in the order in which they run.
    public var steps: [Step]

    /// Creates a pipeline.
    ///
    /// - Parameter steps: The steps, in the order in which they run (default: none).
    public init(steps: [Step] = []) {
        self.steps = steps
    }

    /// Runs the steps in order.
    ///
    /// - Parameters:
    ///   - resourceSet: The resource set that receives the metamodels and models (default: a
    ///     new resource set).
    ///   - progress: A receiver of progress reports; reports are dropped by default.
    /// - Returns: The models, diagnostics and generated files of the run.
    /// - Throws: ``ModelPipelineError/unknownModel(_:_:)`` if a step names a model that the
    ///   pipeline does not hold, and the errors of the step that fails.
    @MainActor
    public func run(
        in resourceSet: ResourceSet = ResourceSet(), progress: @escaping GenerationProgressReporter = { _ in }
    ) async throws -> Result {
        var state = State()
        for step in steps {
            try await run(step, in: resourceSet, state: &state, progress: progress)
        }
        return Result(
            resourceSet: resourceSet, models: state.models, diagnostics: state.diagnostics,
            generatedFiles: state.generations.flatMap(\.files), generations: state.generations)
    }

    /// The models and outcomes collected while a pipeline runs.
    private struct State {
        var models: [String: Resource] = [:]
        var diagnostics = ConversionDiagnostics()
        var generations: [GenerationStep.Result] = []

        /// The model of a name.
        func model(_ name: String) throws -> Resource {
            guard let model = models[name] else {
                throw ModelPipelineError.unknownModel(name, Array(models.keys))
            }
            return model
        }
    }

    /// Runs one step.
    @MainActor
    private func run(
        _ step: Step, in resourceSet: ResourceSet, state: inout State,
        progress: @escaping GenerationProgressReporter
    ) async throws {
        switch step {
        case .registerMetamodels(let urls):
            progress(GenerationProgressUpdate(message: "Registering \(urls.map(\.lastPathComponent).joined(separator: ", "))"))
            try await ModelIO.registerMetamodels(at: urls, in: resourceSet)
        case .registerPackages(let packages):
            progress(GenerationProgressUpdate(message: "Registering \(packages.map(\.name).joined(separator: ", "))"))
            for package in packages {
                await resourceSet.registerMetamodel(package, uri: package.nsURI)
            }
        case .load(let name, let url, let format, let options):
            progress(GenerationProgressUpdate(message: "Loading \(url.lastPathComponent)"))
            let loaded = try await ModelIO.load(url: url, format: format, resourceSet: resourceSet, options: options)
            state.models[name] = loaded.resource
            state.diagnostics.merge(loaded.diagnostics)
        case .transform(let transformation, let sources, let targets):
            progress(GenerationProgressUpdate(message: "Transforming with \(transformation.moduleURL.lastPathComponent)"))
            var available = state.models
            for (alias, name) in sources { available[alias] = try state.model(name) }
            let results = try await transformation.run(sources: available, targetResourceSet: resourceSet)
            for (alias, resource) in results { state.models[targets[alias] ?? alias] = resource }
        case .generate(let generation, let arguments):
            var roots: [(any EcoreValue)?] = []
            for name in arguments {
                roots += try await state.model(name).getRootObjects().map { Optional($0) }
            }
            let result = try await generation.run(
                arguments: roots, models: state.models, resourceSet: resourceSet, progress: progress)
            state.generations.append(result)
        case .save(let name, let url, let format, let xmiOptions):
            progress(GenerationProgressUpdate(message: "Saving \(url.lastPathComponent)"))
            let model = try state.model(name)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try await ModelIO.save(
                model, to: url, format: format, xmiOptions: xmiOptions, diagnostics: &state.diagnostics)
        }
    }
}
