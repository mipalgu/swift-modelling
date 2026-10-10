//
//  PartsPackage.swift
//

import ECore
import EMFBase
import Foundation

/// The description of the parts package.
///
/// The shared instance builds the Ecore package of the model, with the metaclass of each class, enumeration and
/// data type, which the objects of the package return as their metaclass.
// @generated
public struct PartsPackage: Sendable {
    /// The shared description of the package.
    // @generated
    public static let shared = PartsPackage()

    /// The Ecore package that holds the classifiers.
    // @generated
    public let ePackage: EPackage

    /// The factory that creates the objects of the package.
    // @generated
    public var factory: PartsFactory { PartsFactory.shared }

    /// The metaclass of the Wheel class.
    // @generated
    public let eWheel: EClass

    /// The metaclass of the Self class.
    // @generated
    public let eSelf: EClass

    /// The metaclass of the Protocol class.
    // @generated
    public let eProtocol: EClass

    /// The metaclass of the String class.
    // @generated
    public let eString: EClass

    /// Builds the Ecore package and its classifiers.
    // @generated
    private init() {
        let classID_Wheel = EUUID()
        let featureID_Wheel_size = EUUID()
        let featureID_Wheel_vehicle = EUUID()
        let classID_Self = EUUID()
        let classID_Protocol = EUUID()
        let classID_String = EUUID()
        let class_Wheel = EClass(
            id: classID_Wheel, name: "Wheel",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Wheel_size, name: "size",
                    eType: EDataType(name: "EInt"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EReference(
                    id: featureID_Wheel_vehicle, name: "vehicle",
                    eType: EClass(name: "Vehicle"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: nil,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: true),
            ])
        let class_Self = EClass(
            id: classID_Self, name: "Self",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
            ])
        let class_Protocol = EClass(
            id: classID_Protocol, name: "Protocol",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
            ])
        let class_String = EClass(
            id: classID_String, name: "String",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
            ])
        self.ePackage = EPackage(
            name: "parts", nsURI: "http://swift-modelling.org/test/swiftnames/parts", nsPrefix: "parts",
            eClassifiers: [
                class_Wheel,
                class_Self,
                class_Protocol,
                class_String,
            ])
        self.eWheel = class_Wheel
        self.eSelf = class_Self
        self.eProtocol = class_Protocol
        self.eString = class_String
    }
}
