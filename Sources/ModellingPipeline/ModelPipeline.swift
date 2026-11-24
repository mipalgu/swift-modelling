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
/// A pipeline runs its ``steps`` in order over one
/// [`ResourceSet`](https://mipalgu.github.io/swift-ecore/documentation/ecore/resourceset/). Each model it loads
/// or creates is kept under a name, by which later steps refer to it: a transformation reads
/// its source models and stores its target models by name, a generation passes the root objects
/// of named models to its template, and a save writes a named model. Models are read and written
/// with [`ModelIO`](https://mipalgu.github.io/swift-ecore/documentation/ecore/modelio/), in any format it supports,
/// and what a conversion cannot keep is collected in one
/// [`ConversionDiagnostics`](https://mipalgu.github.io/swift-ecore/documentation/ecore/conversiondiagnostics/). Progress is reported to a
/// `GenerationProgressReporter`.
///
/// ## Example
///
/// ```swift
/// let pipeline = ModelPipeline(steps: [
///     .registerMetamodels([familiesEcore, personsEcore]),
///     .load(name: "IN", url: familiesXMI),
///     .transform(
///         TransformationStep(moduleURL: families2Persons, atlOptions: .standard), targets: ["OUT": "persons"]),
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

        /// Writes a named model to a file and gives the model the location of that file.
        ///
        /// Without a format, the format is taken from the file extension. Without XMI options,
        /// an XMI document is written with ``ModelPipeline/defaultXMIOptions``, which refer to
        /// other documents relative to the file; options given to the step are used as they are.
        ///
        /// The model is saved as the file, as
        /// [`ModelIO.saveAs`](https://mipalgu.github.io/swift-ecore/documentation/ecore/modelio/)
        /// saves it: thereafter it has the URI of the file, and the other models of the pipeline
        /// refer to it there when they are saved. Consecutive save steps save their models
        /// together: each model takes the location of its file before any is written, so that
        /// models that refer to each other refer to each other at the files written, whichever
        /// step comes first. A model saved by two steps of such a run takes the file of the first
        /// and is copied to the other. Two different models saved to the same file, or a model
        /// saved to the file of another model of the pipeline that the run does not save, are a
        /// `DocumentRelocationError`, and then no file of the run is written.
        case save(
            name: String, url: URL, format: ModelFormat? = nil,
            xmiOptions: XMISerializationOptions = ModelPipeline.defaultXMIOptions)
    }

    /// The options with which a save step writes XMI when it is given none.
    ///
    /// They keep the layout of
    /// [`XMISerializationOptions.legacy`](https://mipalgu.github.io/swift-ecore/documentation/ecore/xmiserializationoptions/legacy/)
    /// and write the URI of another document relative to the saved file, such as
    /// `../models/tasks.xmi#//@tasks.1`, so that the file holds no absolute path and keeps
    /// referring to the other document when both are moved together. A URI that cannot be
    /// made relative, such as one of another scheme or on another drive, is written in full.
    public static let defaultXMIOptions: XMISerializationOptions = {
        var options = XMISerializationOptions.legacy
        options.relativeURIs = true
        return options
    }()

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
        var saves: [(name: String, url: URL, format: ModelFormat?, xmiOptions: XMISerializationOptions)] = []
        for step in steps {
            if case .save(let name, let url, let format, let xmiOptions) = step {
                saves.append((name, url, format, xmiOptions))
                continue
            }
            try await save(saves, state: &state, progress: progress)
            saves = []
            try await run(step, in: resourceSet, state: &state, progress: progress)
        }
        try await save(saves, state: &state, progress: progress)
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
            try await save([(name, url, format, xmiOptions)], state: &state, progress: progress)
        }
    }

    /// Runs consecutive save steps together.
    ///
    /// Every model takes the location of its first file before any file is written, and keeps
    /// its previous location if a file cannot be written.
    ///
    /// - Parameters:
    ///   - saves: The names of the models, their files, formats and XMI options, in order.
    ///   - state: The models and diagnostics of the run.
    ///   - progress: The receiver of progress reports.
    /// - Throws: ``ModelPipelineError/unknownModel(_:_:)`` if a model is unknown,
    ///   `DocumentRelocationError` if the models cannot take their files, and the errors of
    ///   writing a file.
    @MainActor
    private func save(
        _ saves: [(name: String, url: URL, format: ModelFormat?, xmiOptions: XMISerializationOptions)],
        state: inout State, progress: @escaping GenerationProgressReporter
    ) async throws {
        guard !saves.isEmpty else { return }
        var models: [Resource] = []
        for save in saves { models.append(try state.model(save.name)) }
        let relocation = try await DocumentRelocation.relocate(zip(models, saves).map { ($0, $1.url) })
        do {
            for (model, save) in zip(models, saves) {
                guard let placement = relocation.placements.first(where: { $0.resource === model && $0.url == save.url })
                else { continue }
                progress(GenerationProgressUpdate(message: "Saving \(save.url.lastPathComponent)"))
                try FileManager.default.createDirectory(
                    at: save.url.deletingLastPathComponent(), withIntermediateDirectories: true)
                if placement.isCopy {
                    try await ModelIO.save(
                        model, to: save.url, format: save.format, xmiOptions: save.xmiOptions,
                        diagnostics: &state.diagnostics)
                } else {
                    try await ModelIO.saveAs(
                        model, to: save.url, format: save.format, xmiOptions: save.xmiOptions,
                        diagnostics: &state.diagnostics)
                }
            }
        } catch {
            await relocation.restore()
            throw error
        }
    }
}
