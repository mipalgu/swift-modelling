//
// GenModelServices+Features.swift
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
    /// Shortcuts to the properties of the Ecore feature that a generator feature describes.
    var featureServices: [AQLService] {
        typealias Name = GenModelServiceName
        let featureReceiver = genElementReceiver(of: GenModelConstants.ClassName.genFeature)
        return [
            property(Name.isReferenceType, on: featureReceiver) { $0.isReferenceType },
            property(Name.isAttributeType, on: featureReceiver) { $0.isAttributeType },
            property(Name.isContainment, on: featureReceiver) { $0.isContainment },
            property(Name.isContainer, on: featureReceiver) { $0.isContainer },
            property(Name.isBidirectional, on: featureReceiver) { $0.isBidirectional },
            link(Name.reverseGenFeature, on: featureReceiver) { $0.reverseGenFeature },
            property(Name.isListType, on: featureReceiver) { $0.isListType },
            property(Name.isRequired, on: featureReceiver) { $0.isRequired },
            property(Name.isChangeable, on: featureReceiver) { $0.isChangeable },
            property(Name.isVolatile, on: featureReceiver) { $0.isVolatile },
            property(Name.isTransient, on: featureReceiver) { $0.isTransient },
            property(Name.isDerived, on: featureReceiver) { Self.isDerived($0) },
            property(Name.isUnsettable, on: featureReceiver) { Self.isUnsettable($0) },
            property(Name.isResolveProxies, on: featureReceiver) { Self.resolvesProxies($0) },
            property(Name.hasDefault, on: featureReceiver) { $0.hasDefault },
            property(Name.defaultValueLiteral, on: featureReceiver) { $0.defaultValueLiteral },
            property(Name.lowerBound, on: featureReceiver) { $0.lowerBound },
            property(Name.upperBound, on: featureReceiver) { $0.upperBound },
        ]
    }

    /// Whether the Ecore feature of a generator feature is derived.
    ///
    /// - Parameter element: A generator feature.
    /// - Returns: The `derived` flag of the Ecore feature; `false` if there is none.
    static func isDerived(_ element: GenElement) -> Bool {
        switch element.ecoreFeature {
        case let attribute as EAttribute: return attribute.derived
        case let reference as EReference: return reference.derived
        default: return false
        }
    }

    /// Whether the Ecore feature of a generator feature is unsettable.
    ///
    /// - Parameter element: A generator feature.
    /// - Returns: The `unsettable` flag of the Ecore feature; `false` if there is none.
    static func isUnsettable(_ element: GenElement) -> Bool {
        switch element.ecoreFeature {
        case let attribute as EAttribute: return attribute.unsettable
        case let reference as EReference: return reference.unsettable
        default: return false
        }
    }

    /// Whether the Ecore feature of a generator feature resolves proxies.
    ///
    /// - Parameter element: A generator feature.
    /// - Returns: The `resolveProxies` flag of a reference; `false` for an attribute or if there is none.
    static func resolvesProxies(_ element: GenElement) -> Bool {
        (element.ecoreFeature as? EReference)?.resolveProxies ?? false
    }
}
