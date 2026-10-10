//
//  EnumerationsPackage.swift
//

import ECore
import EMFBase
import Foundation

/// The description of the enumerations package.
///
/// The shared instance builds the Ecore package of the model, with the metaclass of each class, enumeration and
/// data type, which the objects of the package return as their metaclass.
// @generated
public struct EnumerationsPackage: Sendable {
    /// The shared description of the package.
    // @generated
    public static let shared = EnumerationsPackage()

    /// The Ecore package that holds the classifiers.
    // @generated
    public let ePackage: EPackage

    /// The factory that creates the objects of the package.
    // @generated
    public var factory: EnumerationsFactory { EnumerationsFactory.shared }

    /// The metaclass of the Light class.
    // @generated
    public let eLight: EClass

    /// The Ecore enumeration of the Colour enumeration.
    // @generated
    public let eColour: EEnum

    /// The Ecore enumeration of the Mode enumeration.
    // @generated
    public let eMode: EEnum

    /// The Ecore enumeration of the Empty enumeration.
    // @generated
    public let eEmpty: EEnum

    /// Builds the Ecore package and its classifiers.
    // @generated
    private init() {
        let classID_Light = EUUID()
        let featureID_Light_colour = EUUID()
        let featureID_Light_mode = EUUID()
        let enum_Colour = EEnum(
            name: "Colour",
            literals: [
                EEnumLiteral(name: "Red", value: 0, literal: "red"),
                EEnumLiteral(name: "Amber", value: 1, literal: "amber"),
                EEnumLiteral(name: "Yellow", value: 1, literal: "yellow"),
                EEnumLiteral(name: "Green", value: 5, literal: "Green"),
            ])
        let enum_Mode = EEnum(
            name: "Mode",
            literals: [
                EEnumLiteral(name: "default", value: 0, literal: "default"),
                EEnumLiteral(name: "fastForward", value: 1, literal: "fastForward"),
                EEnumLiteral(name: "HTTPServer", value: 2, literal: "HTTPServer"),
                EEnumLiteral(name: "_", value: 3, literal: "_"),
                EEnumLiteral(name: "quote", value: 4, literal: "say \"hi\""),
            ])
        let enum_Empty = EEnum(
            name: "Empty",
            literals: [
            ])
        let class_Light = EClass(
            id: classID_Light, name: "Light",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Light_colour, name: "colour",
                    eType: enum_Colour,
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Light_mode, name: "mode",
                    eType: enum_Mode,
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
            ])
        self.ePackage = EPackage(
            name: "enumerations", nsURI: "http://swift-modelling.org/test/enumerations", nsPrefix: "enums",
            eClassifiers: [
                class_Light,
                enum_Colour,
                enum_Mode,
                enum_Empty,
            ])
        self.eLight = class_Light
        self.eColour = enum_Colour
        self.eMode = enum_Mode
        self.eEmpty = enum_Empty
    }
}
