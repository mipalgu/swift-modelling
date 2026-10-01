//
// GenModelTransformation.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ECore
import EMFBase
import Foundation
import GenModel
import OrderedCollections

/// Loads and runs the bundled transformation from Ecore models to generator models.
///
/// The transformation is an ATL module bundled with this library. It is parsed against
/// the Ecore and generator metamodels, which are bound by their namespace URIs.
struct GenModelTransformation {
    /// The parsed transformation.
    let module: ATLModule

    /// Parses the bundled transformation.
    ///
    /// - Parameter generatorMetamodel: The generator metamodel that the transformation targets.
    /// - Returns: The parsed transformation.
    /// - Throws: ``GenerationError/transformationUnavailable(_:)`` if the transformation is
    ///   missing from the bundle or cannot be parsed.
    @MainActor
    static func load(generatorMetamodel: EPackage) async throws -> GenModelTransformation {
        guard
            let url = Bundle.module.url(
                forResource: GenModelImportConstants.transformationName,
                withExtension: GenModelImportConstants.transformationExtension,
                subdirectory: GenModelImportConstants.transformationDirectory)
        else {
            throw GenerationError.transformationUnavailable("the bundled transformation is missing")
        }
        let registry = ATLMetamodelRegistry(packages: [EcorePackage.instance, generatorMetamodel])
        do {
            let module = try await ATLParser().parse(url, metamodelRegistry: registry)
            return GenModelTransformation(module: module)
        } catch {
            throw GenerationError.transformationUnavailable(String(describing: error))
        }
    }

    /// Runs the transformation on one source model.
    ///
    /// - Parameters:
    ///   - source: The resource holding the source model.
    ///   - target: The resource that receives the generator model.
    ///   - parameters: The values of the module parameters.
    /// - Throws: ``GenerationError/transformationFailed(_:)`` if the transformation fails.
    @MainActor
    func run(
        source: Resource, target: Resource, parameters: [String: any EcoreValue]
    ) async throws {
        do {
            try await ATLVirtualMachine(module: module).execute(
                sources: [GenModelImportConstants.sourceAlias: source],
                targets: [GenModelImportConstants.targetAlias: target],
                parameters: parameters)
        } catch {
            throw GenerationError.transformationFailed(String(describing: error))
        }
    }

    /// Computes the values of the module parameters from the options.
    ///
    /// Options that are not set are passed as empty text, which the transformation treats as unset.
    ///
    /// - Parameters:
    ///   - options: The import options.
    ///   - modelProject: The resolved name of the model project, or empty if the root package decides.
    ///   - modelName: The name of the generator model.
    ///   - foreignModels: The locations of the source models relative to the generator model.
    /// - Returns: The parameter values by name.
    static func parameters(
        options: GenModelImportOptions, modelProject: String, modelName: String,
        foreignModels: [String]
    ) -> [String: any EcoreValue] {
        typealias Name = GenModelImportConstants.Parameter
        let prefixes = options.packagePrefixes.keys.sorted().map {
            $0 + GenModelImportConstants.assignmentSeparator + (options.packagePrefixes[$0] ?? "")
        }
        let values: [String: any EcoreValue] = [
            Name.importerID: GenModelImportConstants.importerID,
            Name.rootExtendsClass: options.rootExtendsClass,
            Name.operationReflection: options.operationReflection,
            Name.importOrganizing: options.importOrganizing,
            Name.copyrightFields: GenModelImportConstants.defaultCopyrightFields,
            Name.bigModelThreshold: GenModelImportConstants.bigModelThreshold,
            Name.basePackage: options.basePackage ?? "",
            Name.prefix: options.prefix ?? "",
            Name.packagePrefixes: prefixes.joined(separator: GenModelImportConstants.listSeparator),
            Name.modelProject: modelProject,
            Name.modelPluginID: options.modelPluginID ?? "",
            Name.modelDirectory: options.modelDirectory ?? "",
            Name.modelName: modelName,
            Name.copyright: options.copyright ?? "",
            Name.foreignModels: foreignModels.joined(separator: GenModelImportConstants.listSeparator),
            Name.listSeparator: GenModelImportConstants.listSeparator,
            Name.assignmentSeparator: GenModelImportConstants.assignmentSeparator,
            Name.extendedMetaDataSource: GenModelImportConstants.extendedMetaDataSource,
            Name.featureMapEntryClass: GenModelImportConstants.featureMapEntryClass,
            Name.xmlTypeNsURI: GenModelImportConstants.xmlTypeNsURI,
            Name.ecoreNsURI: GenModelImportConstants.ecoreNsURI,
        ]
        return values
    }
}
