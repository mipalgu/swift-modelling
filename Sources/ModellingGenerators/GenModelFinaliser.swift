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
/// elements come back as unresolved proxies, and the references to the generator models
/// of other metamodels cannot be expressed in the transformation at all.
enum GenModelFinaliser {
    /// Finalises every generator model of a resource.
    ///
    /// - Parameters:
    ///   - resource: The resource holding the generator model.
    ///   - resourceSet: The resource set holding the resource and the source models.
    ///   - sources: The root packages of the source models.
    ///   - complianceLevel: The compliance level to record, or `nil` to leave it unset.
    static func finalise(
        _ resource: Resource, in resourceSet: ResourceSet, sources: [EPackage],
        complianceLevel: String?
    ) async {
        await normaliseTextCollections(in: resource)
        await resolveSourceReferences(in: resource, resourceSet: resourceSet)
        let usesEcore = referencesEcoreClassifiers(sources)
        for case let object as DynamicEObject in await resource.getRootObjects()
        where object.eClass.name == GenModelConstants.ClassName.genModel {
            if let complianceLevel {
                _ = await resource.eSet(
                    objectId: object.id, feature: GenModelImportConstants.Setting.complianceLevel,
                    value: complianceLevel)
            }
            if usesEcore {
                _ = await resource.eSet(
                    objectId: object.id, feature: GenModelConstants.FeatureName.usedGenPackages,
                    value: [ecoreGenPackageProxy])
            }
        }
    }

    /// The reference to the generator package of the Ecore metamodel.
    static var ecoreGenPackageProxy: ResourceProxy {
        ResourceProxy(
            uri: GenModelImportConstants.ecoreGenModelLocation,
            fragment: GenModelImportConstants.ecoreGenPackageFragment)
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

    /// Whether any of the packages refers to a classifier of the Ecore metamodel.
    ///
    /// A classifier counts as an Ecore classifier when none of the packages declares it and
    /// the Ecore metamodel has a classifier of the same name.
    ///
    /// - Parameter packages: The root packages of the source models.
    /// - Returns: `true` if a supertype or the type of a feature is an Ecore classifier.
    static func referencesEcoreClassifiers(_ packages: [EPackage]) -> Bool {
        var declared = Set<EUUID>()
        var classes: [EClass] = []
        func collect(_ package: EPackage) {
            for classifier in package.eClassifiers {
                declared.insert(classifier.id)
                if let eClass = classifier as? EClass { classes.append(eClass) }
            }
            package.eSubpackages.forEach(collect)
        }
        packages.forEach(collect)

        func isEcore(_ classifier: any EClassifier) -> Bool {
            !declared.contains(classifier.id) && EcorePackage.instance.getClassifier(classifier.name) != nil
        }
        for eClass in classes {
            if eClass.eSuperTypes.contains(where: { isEcore($0) }) { return true }
            for feature in eClass.eStructuralFeatures {
                switch feature {
                case let attribute as EAttribute where isEcore(attribute.eType): return true
                case let reference as EReference where isEcore(reference.eType): return true
                default: continue
                }
            }
        }
        return false
    }
}
