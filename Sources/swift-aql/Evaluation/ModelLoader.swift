//
// ModelLoader.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingCommandLine

/// A model that swift-aql has loaded.
struct LoadedModel: Sendable {
    /// The path of the model file, as given on the command line.
    let path: String

    /// The resource that holds the objects of the model.
    let resource: Resource

    /// The root objects of the model, in document order.
    let roots: [any EObject]

    /// The identifiers that the model file declares with `xmi:id`.
    let identifiers: XMIIdentifierIndex
}

/// Loads the models and metamodels named on the command line.
///
/// The metamodels are those given with `--metamodel`, or, if none is given, those that
/// ``MetamodelDiscovery`` finds beside the models. Every metamodel is registered with one
/// resource set before the models are read, so the models are read with the classes and data
/// types it defines. A model may be a metamodel file itself, such as an Ecore or a KM3 file, in
/// which case its first root package is both registered and queried.
@MainActor
struct ModelLoader {
    /// The paths of the metamodels given on the command line.
    let metamodels: [String]

    /// The settings of the run, which choose the container lookup scope of the resources.
    let settings: SemanticsSettings

    /// The options with which metamodels are read, such as those of KM3.
    let metamodelOptions: EcoreLoadOptions

    /// Creates a loader.
    ///
    /// - Parameters:
    ///   - metamodels: The paths of the metamodels given on the command line, if any.
    ///   - settings: The settings of the run.
    ///   - metamodelOptions: The options with which metamodels are read (default options).
    init(metamodels: [String], settings: SemanticsSettings, metamodelOptions: EcoreLoadOptions = EcoreLoadOptions()) {
        self.metamodels = metamodels
        self.settings = settings
        self.metamodelOptions = metamodelOptions
    }

    /// The metamodels with which the models are read.
    ///
    /// - Parameter models: The paths of the models.
    /// - Returns: The metamodels given on the command line, or, if none is, those found beside
    ///   the models that are not Ecore files.
    /// - Throws: ``SwiftAQLError/ambiguousMetamodels(_:_:)`` if discovery cannot choose.
    func effectiveMetamodels(for models: [String]) throws -> [String] {
        guard metamodels.isEmpty else { return metamodels }
        return try MetamodelDiscovery().metamodels(for: models.filter { !MetamodelRegistration.isMetamodelFile($0) })
    }

    /// Loads models.
    ///
    /// - Parameter models: The paths of the model files, as given on the command line.
    /// - Returns: The loaded models, in command line order.
    /// - Throws: ``SwiftAQLError/modelNotFound(_:)`` if a file does not exist, the errors of
    ///   metamodel registration, and the error of the parser if a file cannot be read.
    func load(_ models: [String]) async throws -> [LoadedModel] {
        for path in models where !FileManager.default.fileExists(atPath: path) {
            throw SwiftAQLError.modelNotFound(path)
        }
        let resourceSet = settings.makeResourceSet()
        for metamodel in try effectiveMetamodels(for: models) {
            try await MetamodelRegistration.registerMetamodel(at: metamodel, into: resourceSet, options: metamodelOptions)
        }
        var loaded: [LoadedModel] = []
        for path in models {
            let url = URL(fileURLWithPath: path)
            let resource: Resource
            if MetamodelRegistration.isMetamodelFile(path) {
                let package = try await MetamodelRegistration.registerMetamodel(
                    at: path, into: resourceSet, options: metamodelOptions)
                resource = await resourceSet.createResource(uri: url.absoluteString)
                await resource.add(package)
            } else {
                let format = try ModelFileFormat.detectedInstanceFormat(of: url)
                resource = try await ModelIO.load(
                    url: url, format: format, resourceSet: resourceSet,
                    options: ModelIO.LoadOptions(requiresMetamodel: false)
                ).resource
            }
            let identifiers = XMIIdentifierIndex(data: (try? Data(contentsOf: url)) ?? Data())
            loaded.append(
                LoadedModel(path: path, resource: resource, roots: await resource.getRootObjects(), identifiers: identifiers))
        }
        return loaded
    }
}
