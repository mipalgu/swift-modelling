//
// ModelWorkspace.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import EOL
import Foundation
import ModellingCommandLine

/// The models of one run, loaded with their metamodels into one resource set.
///
/// A workspace registers the metamodels, reads the models that `--model` binds, creates the
/// models that `--target` binds and, once the run has succeeded, stores the targets and the
/// models that `--store` names. It creates the interpreters that run the programs, with the
/// models, the parameters and the call depth limit of the run.
///
/// Each model is typed by the metamodels whose namespace URIs its file uses, so that an
/// unqualified type name such as `Account` resolves in the model that holds such elements. A
/// target model is typed by the metamodels that no model read from a file uses, or by all of
/// them if every one is used. A model file that is itself a metamodel, such as an Ecore file,
/// is typed by the Ecore metamodel, so that programs can work on its classes.
///
/// A workspace is not thread-safe: it is created, used and discarded within one task.
final class ModelWorkspace {
    /// The configuration of the run.
    let configuration: RunConfiguration

    /// The resource set that holds the metamodels and models.
    let resourceSet: ResourceSet

    /// The models, in the order in which programs look up unqualified type names.
    let models: [EOLModel]

    /// The verbose report of the run.
    let log: VerboseLog

    /// Creates a workspace from models that have been loaded already.
    ///
    /// - Parameters:
    ///   - configuration: The configuration of the run.
    ///   - resourceSet: The resource set that holds the models.
    ///   - models: The models, in the order of ``ModelPlan/bindings``.
    init(configuration: RunConfiguration, resourceSet: ResourceSet, models: [EOLModel]) {
        self.configuration = configuration
        self.resourceSet = resourceSet
        self.models = models
        log = VerboseLog(isEnabled: configuration.verbose)
    }

    /// Loads the metamodels and models of a run.
    ///
    /// - Parameter configuration: The configuration of the run.
    /// - Returns: The workspace.
    /// - Throws: ``SwiftEpsilonError/modelNotFound(_:)`` if a model file does not exist,
    ///   ``SwiftEpsilonError/targetWithoutMetamodel(_:)`` if a target cannot be typed, and the
    ///   errors of reading the metamodels and models.
    static func load(_ configuration: RunConfiguration) async throws -> ModelWorkspace {
        let log = VerboseLog(isEnabled: configuration.verbose)
        let plan = configuration.plan
        for binding in plan.sources where !FileManager.default.fileExists(atPath: binding.path) {
            throw SwiftEpsilonError.modelNotFound(binding.path)
        }
        let resourceSet = configuration.settings.makeResourceSet()
        var metamodels: [EPackage] = []
        for path in configuration.metamodels {
            log("Loading metamodel \(path)")
            let packages = try await MetamodelRegistration.registerMetamodels(
                at: path, into: resourceSet, options: configuration.metamodelLoadOptions)
            for package in packages { log("Registered metamodel \(package.name) (\(package.nsURI))") }
            metamodels += packages
        }
        var models: [EOLModel] = []
        var used = Set<String>()
        for binding in plan.sources {
            let model = try await loadModel(binding, metamodels: metamodels, in: resourceSet, configuration: configuration)
            used.formUnion(model.packages.map(\.nsURI))
            if log.isEnabled {
                let count = await model.resource.count()
                log("Loaded model \(binding.name) from \(binding.path) (\(count) objects)")
            }
            models.append(model)
        }
        let unused = metamodels.filter { !used.contains($0.nsURI) }
        for binding in plan.targets {
            let packages = unused.isEmpty ? metamodels : unused
            guard !packages.isEmpty else { throw SwiftEpsilonError.targetWithoutMetamodel(binding.name) }
            let model = await EOLModel.empty(
                name: binding.name, packages: packages, resourceSet: resourceSet,
                uri: URL(fileURLWithPath: binding.path).absoluteString, aliases: binding.aliases)
            log("Created target model \(binding.name) for \(binding.path) (\(packages.map(\.name).joined(separator: ", ")))")
            models.append(model)
        }
        return ModelWorkspace(configuration: configuration, resourceSet: resourceSet, models: models)
    }

    /// Reads a model that `--model` binds.
    ///
    /// - Parameters:
    ///   - binding: The binding.
    ///   - metamodels: The root packages of the metamodels given on the command line.
    ///   - resourceSet: The resource set that receives the model.
    ///   - configuration: The configuration of the run.
    /// - Returns: The model, typed by the metamodels whose namespace URIs its file uses.
    /// - Throws: The error of the parser if the file cannot be read.
    private static func loadModel(
        _ binding: ModelBinding, metamodels: [EPackage], in resourceSet: ResourceSet, configuration: RunConfiguration
    ) async throws -> EOLModel {
        let url = URL(fileURLWithPath: binding.path)
        if await MetamodelRegistration.holdsMetamodel(at: binding.path) {
            let loaded = try await TextDocumentLoading.load(
                url: url, path: binding.path, resourceSet: resourceSet,
                options: ModelIO.LoadOptions(ecoreLoadOptions: configuration.metamodelLoadOptions),
                encoding: configuration.metamodelLoadOptions.textEncoding)
            return EOLModel(
                name: binding.name, resource: loaded.resource, packages: [EcorePackage.instance], aliases: binding.aliases)
        }
        let loaded = try await TextDocumentLoading.load(
            url: url, path: binding.path, format: try ModelFileFormat.detectedInstanceFormat(of: url),
            resourceSet: resourceSet, options: ModelIO.LoadOptions(requiresMetamodel: false),
            encoding: configuration.metamodelLoadOptions.textEncoding, diagnosticOutput: { _ in })
        ConversionWarningReport.write(loaded.diagnostics, metamodelGiven: !metamodels.isEmpty)
        let contents = (try? Data(contentsOf: url)).map { String(decoding: $0, as: UTF8.self) } ?? ""
        let used = metamodels.filter { package in usedNamespaces(of: package).contains { contents.contains($0) } }
        return EOLModel(
            name: binding.name, resource: loaded.resource, packages: used.isEmpty ? metamodels : used,
            aliases: binding.aliases)
    }

    /// The namespace URIs of a package and its nested packages.
    ///
    /// - Parameter package: The package.
    /// - Returns: The namespace URIs that are not empty.
    private static func usedNamespaces(of package: EPackage) -> [String] {
        ([package.nsURI] + package.eSubpackages.flatMap(usedNamespaces(of:))).filter { !$0.isEmpty }
    }

    /// Creates an interpreter for the models of the run.
    ///
    /// The interpreter has every model, the parameters of the run as global variables and its
    /// call depth limit, and reads imported modules in the encoding of the run.
    ///
    /// - Parameters:
    ///   - output: Where `print` and `println` write (standard output by default).
    ///   - errorOutput: Where `err` and `errln` write (standard error by default).
    /// - Returns: The interpreter.
    func makeInterpreter(
        output: any EOLOutputStream = EOLStandardOutput(), errorOutput: any EOLOutputStream = EOLStandardOutput(error: true)
    ) -> EOLInterpreter {
        let interpreter = EOLInterpreter(
            models: models, output: output, errorOutput: errorOutput,
            moduleLoader: SourceModuleLoader(encoding: configuration.encoding))
        interpreter.maximumCallDepth = configuration.maximumCallDepth
        for (name, value) in configuration.parameters.sorted(by: { $0.key < $1.key }) {
            interpreter.setGlobal(name, value.eolValue)
        }
        return interpreter
    }

    /// The parameters of the run as variables for a template.
    var variables: [String: EOLValue] { configuration.parameters.mapValues(\.eolValue) }

    /// The model that a name or alias denotes.
    ///
    /// - Parameter name: The name or alias.
    /// - Returns: The model, or `nil` if no model answers to the name.
    func model(named name: String) -> EOLModel? { models.first { $0.answers(to: name) } }

    /// Writes the target models and the models that `--store` names.
    ///
    /// Each model is written in the format of the extension of its file, and the warnings of
    /// writing it are reported on standard error.
    ///
    /// - Returns: The paths of the files written, in order.
    /// - Throws: ``OutputFileError`` if the encoding of the run cannot hold a character of a
    ///   model, and the error of the serialiser or of the file system for the first model that
    ///   cannot be written.
    @discardableResult
    func store() async throws -> [String] {
        var written: [String] = []
        let plan = configuration.plan
        var requests = plan.targets.map { (name: $0.name, path: $0.path) }
        for store in plan.stores {
            guard let binding = plan.sources.first(where: { $0.names.contains(store.name) }) else { continue }
            requests.append((binding.name, store.path ?? binding.path))
        }
        for request in requests {
            guard let model = model(named: request.name) else { continue }
            let url = URL(fileURLWithPath: request.path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let diagnostics = try await OutputFile.save(
                model.resource, to: url, format: ModelFileFormat.instanceFormat(of: url),
                xmiOptions: configuration.xmiOptions, encoding: configuration.outputEncoding)
            ConversionWarningReport.write(diagnostics, metamodelGiven: true)
            if log.isEnabled {
                let count = await model.resource.count()
                log("Stored model \(request.name) in \(request.path) (\(count) objects)")
            }
            written.append(request.path)
        }
        return written
    }
}
