//
// GenModelFinaliser.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import GenModel

/// Completes a generator model that the transformation produced so that it can be written.
///
/// The transformation leaves a few things to this step because the model values it
/// produces are not yet in the form that the serialiser and the generator model readers
/// share: collections of text come back as untyped arrays, references to source model
/// elements come back as unresolved proxies, and enumeration literals are kept as text
/// rather than as the names that the transformation's enumeration checks accept.
enum GenModelFinaliser {
    /// Finalises every generator model of a resource.
    ///
    /// - Parameters:
    ///   - resource: The resource holding the generator model.
    ///   - resourceSet: The resource set holding the resource and the source models.
    ///   - complianceLevel: The compliance level to record, or `nil` to leave it unset.
    static func finalise(
        _ resource: Resource, in resourceSet: ResourceSet, complianceLevel: String?
    ) async {
        await normaliseTextCollections(in: resource)
        await resolveSourceReferences(in: resource, resourceSet: resourceSet)
        for case let object as DynamicEObject in await resource.getRootObjects()
        where object.eClass.name == GenModelConstants.ClassName.genModel {
            if let complianceLevel {
                _ = await resource.eSet(
                    objectId: object.id, feature: GenModelImportConstants.Setting.complianceLevel,
                    value: complianceLevel)
            }
        }
    }

    /// Replaces untyped collections of text by typed arrays.
    ///
    /// - Parameter resource: The resource whose objects are normalised.
    static func normaliseTextCollections(in resource: Resource) async {
        for object in await resource.getAllObjects() {
            for name in await resource.getFeatureNames(objectId: object.id) {
                guard let array = await resource.eGet(objectId: object.id, feature: name) as? EcoreValueArray
                else { continue }
                let texts = array.values.compactMap { $0 as? String }
                if texts.count == array.values.count {
                    _ = await resource.eSet(objectId: object.id, feature: name, value: texts)
                }
            }
        }
    }

    /// Replaces references to source model elements by references that the serialiser can name.
    ///
    /// The transformation stores a reference to a source element as a proxy whose fragment
    /// is the element's identifier when the element has no containment path. Such a proxy
    /// is replaced by the identifier of the element, and any remaining proxy is resolved
    /// through the resource set.
    ///
    /// - Parameters:
    ///   - resource: The resource whose references are resolved.
    ///   - resourceSet: The resource set holding the source models.
    static func resolveSourceReferences(in resource: Resource, resourceSet: ResourceSet) async {
        for object in await resource.getAllObjects() {
            for name in GenModelConstants.FeatureName.ecoreReferences {
                guard let value = await resource.eGet(objectId: object.id, feature: name) else { continue }
                if let proxy = value as? ResourceProxy,
                    let identifier = await identifier(of: proxy, in: resourceSet)
                {
                    _ = await resource.eSet(objectId: object.id, feature: name, value: identifier)
                }
            }
        }
        _ = await resourceSet.resolveAllProxies()
    }

    private static func identifier(of proxy: ResourceProxy, in resourceSet: ResourceSet) async -> EUUID? {
        guard let identifier = UUID(uuidString: proxy.fragment),
            await resourceSet.resolve(identifier) != nil
        else { return nil }
        return identifier
    }

}
