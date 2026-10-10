//
//  MapsPackage.swift
//

import ECore
import EMFBase
import Foundation

/// The description of the maps package.
///
/// The shared instance builds the Ecore package of the model, with the metaclass of each class, enumeration and
/// data type, which the objects of the package return as their metaclass.
// @generated
public struct MapsPackage: Sendable {
    /// The shared description of the package.
    // @generated
    public static let shared = MapsPackage()

    /// The Ecore package that holds the classifiers.
    // @generated
    public let ePackage: EPackage

    /// The factory that creates the objects of the package.
    // @generated
    public var factory: MapsFactory { MapsFactory.shared }

    /// The metaclass of the Dictionary class.
    // @generated
    public let eDictionary: EClass

    /// The metaclass of the StringToIntEntry class.
    // @generated
    public let eStringToIntEntry: EClass

    /// Builds the Ecore package and its classifiers.
    // @generated
    private init() {
        let classID_Dictionary = EUUID()
        let featureID_Dictionary_entries = EUUID()
        let classID_StringToIntEntry = EUUID()
        let featureID_StringToIntEntry_key = EUUID()
        let featureID_StringToIntEntry_value = EUUID()
        let class_Dictionary = EClass(
            id: classID_Dictionary, name: "Dictionary",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EReference(
                    id: featureID_Dictionary_entries, name: "entries",
                    eType: EClass(id: classID_StringToIntEntry, name: "StringToIntEntry"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    containment: true, opposite: nil,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
            ])
        let class_StringToIntEntry = EClass(
            id: classID_StringToIntEntry, name: "StringToIntEntry",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_StringToIntEntry_key, name: "key",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_StringToIntEntry_value, name: "value",
                    eType: EDataType(name: "EInt"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
            ])
        self.ePackage = EPackage(
            name: "maps", nsURI: "http://swift-modelling.org/test/maps", nsPrefix: "maps",
            eClassifiers: [
                class_Dictionary,
                class_StringToIntEntry,
            ])
        self.eDictionary = class_Dictionary
        self.eStringToIntEntry = class_StringToIntEntry
    }
}
