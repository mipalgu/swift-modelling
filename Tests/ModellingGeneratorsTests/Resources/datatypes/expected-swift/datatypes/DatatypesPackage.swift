//
//  DatatypesPackage.swift
//

import ECore
import EMFBase
import Foundation

/// The description of the datatypes package.
///
/// The shared instance builds the Ecore package of the model, with the metaclass of each class, enumeration and
/// data type, which the objects of the package return as their metaclass.
// @generated
public struct DatatypesPackage: Sendable {
    /// The shared description of the package.
    // @generated
    public static let shared = DatatypesPackage()

    /// The Ecore package that holds the classifiers.
    // @generated
    public let ePackage: EPackage

    /// The factory that creates the objects of the package.
    // @generated
    public var factory: DatatypesFactory { DatatypesFactory.shared }

    /// The metaclass of the Thing class.
    // @generated
    public let eThing: EClass

    /// The metaclass of the Class class.
    // @generated
    public let eClass: EClass

    /// The metaclass of the Gizmo class.
    // @generated
    public let eGizmo: EClass

    /// The Ecore enumeration of the Colour enumeration.
    // @generated
    public let eColour: EEnum

    /// The Ecore data type of the Count data type.
    // @generated
    public let eCount: EDataType

    /// The Ecore data type of the Anything data type.
    // @generated
    public let eAnything: EDataType

    /// The Ecore data type of the Stamp data type.
    // @generated
    public let eStamp: EDataType

    /// The Ecore data type of the Hidden data type.
    // @generated
    public let eHidden: EDataType

    /// Builds the Ecore package and its classifiers.
    // @generated
    private init() {
        let classID_Thing = EUUID()
        let classID_Class = EUUID()
        let classID_Gizmo = EUUID()
        let enum_Colour = EEnum(
            name: "Colour",
            literals: [
                EEnumLiteral(name: "Red", value: 0, literal: "Red"),
            ])
        let dataType_Count = EDataType(name: "Count", instanceClassName: "int")
        let dataType_Anything = EDataType(name: "Anything", instanceClassName: "java.lang.Object")
        let dataType_Stamp = EDataType(name: "Stamp", instanceClassName: "java.util.Date")
        let dataType_Hidden = EDataType(name: "Hidden", instanceClassName: "java.lang.String")
        let class_Thing = EClass(
            id: classID_Thing, name: "Thing",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
            ])
        let class_Class = EClass(
            id: classID_Class, name: "Class",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
            ])
        let class_Gizmo = EClass(
            id: classID_Gizmo, name: "Gizmo",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
            ])
        self.ePackage = EPackage(
            name: "datatypes", nsURI: "http://swift-modelling.org/test/datatypes", nsPrefix: "dt",
            eClassifiers: [
                class_Thing,
                class_Class,
                class_Gizmo,
                enum_Colour,
                dataType_Count,
                dataType_Anything,
                dataType_Stamp,
                dataType_Hidden,
            ])
        self.eThing = class_Thing
        self.eClass = class_Class
        self.eGizmo = class_Gizmo
        self.eColour = enum_Colour
        self.eCount = dataType_Count
        self.eAnything = dataType_Anything
        self.eStamp = dataType_Stamp
        self.eHidden = dataType_Hidden
    }
}
