//
//  BridgePackage.swift
//

import ECore
import EMFBase
import Foundation

/// The description of the bridge package.
///
/// The shared instance builds the Ecore package of the model, with the metaclass of each class, enumeration and
/// data type, which the objects of the package return as their metaclass.
// @generated
public struct BridgePackage: Sendable {
    /// The shared description of the package.
    // @generated
    public static let shared = BridgePackage()

    /// The Ecore package that holds the classifiers.
    // @generated
    public let ePackage: EPackage

    /// The factory that creates the objects of the package.
    // @generated
    public var factory: BridgeFactory { BridgeFactory.shared }

    /// The metaclass of the Span class.
    // @generated
    public let eSpan: EClass

    /// Builds the Ecore package and its classifiers.
    // @generated
    private init() {
        let classID_Span = EUUID()
        let featureID_Span_label = EUUID()
        let featureID_Span_length = EUUID()
        let featureID_Span_payload = EUUID()
        let featureID_Span_supports = EUUID()
        let featureID_Span_next = EUUID()
        let class_Span = EClass(
            id: classID_Span, name: "Span",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Span_label, name: "label",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Span_length, name: "length",
                    eType: EDataType(name: "EDouble"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Span_payload, name: "payload",
                    eType: EDataType(name: "EJavaObject"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EReference(
                    id: featureID_Span_supports, name: "supports",
                    eType: EClass(name: "EObject"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: nil,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
                EReference(
                    id: featureID_Span_next, name: "next",
                    eType: EClass(id: classID_Span, name: "Span"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: nil,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
            ])
        self.ePackage = EPackage(
            name: "bridge", nsURI: "http://swift-modelling.org/test/bridge", nsPrefix: "bridge",
            eClassifiers: [
                class_Span,
            ])
        self.eSpan = class_Span
    }
}
