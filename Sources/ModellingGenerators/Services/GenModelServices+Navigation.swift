//
// GenModelServices+Navigation.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Foundation
import GenModel

extension GenModelServices {
    /// Services that move between generator elements and order classifiers.
    var navigationServices: [AQLService] {
        typealias Name = GenModelServiceName
        return [
            link(Name.genModel) { $0.genModel },
            link(Name.genPackage) { $0.genPackage },
            link(Name.parentGenPackage) { $0.parentGenPackage },
            link(Name.genClass) { $0.genClass },
            link(Name.container) { $0.container },
            list(Name.allGenPackages) { $0.allGenPackages },
            list(Name.genClassifiers) { $0.genClassifiers },
            list(Name.orderedGenClasses) { $0.orderedGenClasses },
            list(Name.orderedGenClassifiers) { $0.orderedGenClassifiers },
            list(Name.uniqueValuedGenEnumLiterals) { Self.uniqueValuedLiterals(of: $0) },
            property(Name.classifierID) { $0.classifierID },
            property(Name.classifierIDName) { $0.classifierIDName },
        ] + ecoreServices
    }

    /// The services that return the native Ecore element that a generator element describes.
    var ecoreServices: [AQLService] {
        typealias Name = GenModelServiceName
        return [
            property(Name.ecorePackage) { $0.ecorePackage },
            property(Name.ecoreClass) { $0.ecoreClass },
            property(Name.ecoreFeature) { $0.ecoreFeature.flatMap { $0 as? any EcoreValue } },
            property(Name.ecoreEnum) { $0.ecoreEnum },
            property(Name.ecoreEnumLiteral) { $0.ecoreEnumLiteral },
            property(Name.ecoreDataType) { $0.ecoreDataType },
        ]
    }

    /// The literals of an enumeration that are the first to carry their value.
    ///
    /// - Parameter element: A generator enumeration.
    /// - Returns: The literals in model order, leaving out those whose value an earlier literal has.
    static func uniqueValuedLiterals(of element: GenElement) -> [GenElement] {
        var seen = Set<Int>()
        return element.genEnumLiterals.filter { literal in
            seen.insert(literal.ecoreEnumLiteral?.value ?? 0).inserted
        }
    }

    /// Services about classes: inherited features and operations, numbering and supertypes.
    var classServices: [AQLService] {
        typealias Name = GenModelServiceName
        let provider = self
        let classReceiver = genElementReceiver(of: GenModelConstants.ClassName.genClass)
        return [
            list(Name.allGenFeatures) { $0.allGenFeatures },
            list(Name.inheritedGenFeatures) { $0.inheritedGenFeatures },
            list(Name.implementedGenFeatures) { $0.implementedGenFeatures },
            list(Name.allGenOperations) { $0.allGenOperations },
            list(Name.baseGenClasses) { $0.baseGenClasses },
            list(Name.allBaseGenClasses) { $0.allBaseGenClasses },
            link(Name.baseGenClass) { $0.baseGenClass },
            link(Name.classExtendsGenClass) { $0.classExtendsGenClass },
            list(Name.implementedGenClasses) { $0.implementedGenClasses },
            property(Name.featureCount, on: classReceiver) { $0.featureCount },
            property(Name.operationCount, on: classReceiver) { $0.operationCount },
            property(Name.isMapEntry) { $0.isMapEntry },
            link(Name.labelFeature) { $0.labelFeature },
            property(Name.isInterface) { $0.isInterface },
            property(Name.isAbstract) { $0.isAbstract },
            AQLService(Name.featureID, receiver: classReceiver, arity: 1) { call in
                let owner = try provider.element(of: call)
                let feature = try provider.element(call.argument(0), in: call.name)
                return owner.featureID(of: feature)
            },
            AQLService(Name.operationID, receiver: classReceiver, arity: 1) { call in
                let owner = try provider.element(of: call)
                let operation = try provider.element(call.argument(0), in: call.name)
                return owner.operationID(of: operation)
            },
        ]
    }
}
