//
//  ClassesPackage.swift
//

import ECore
import EMFBase
import Foundation

/// The description of the classes package.
///
/// The shared instance builds the Ecore package of the model, with the metaclass of each class, enumeration and
/// data type, which the objects of the package return as their metaclass.
// @generated
public struct ClassesPackage: Sendable {
    /// The shared description of the package.
    // @generated
    public static let shared = ClassesPackage()

    /// The Ecore package that holds the classifiers.
    // @generated
    public let ePackage: EPackage

    /// The factory that creates the objects of the package.
    // @generated
    public var factory: ClassesFactory { ClassesFactory.shared }

    /// The metaclass of the Shape class.
    // @generated
    public let eShape: EClass

    /// The metaclass of the Canvas class.
    // @generated
    public let eCanvas: EClass

    /// The metaclass of the Named class.
    // @generated
    public let eNamed: EClass

    /// The metaclass of the Circle class.
    // @generated
    public let eCircle: EClass

    /// The Ecore enumeration of the Colour enumeration.
    // @generated
    public let eColour: EEnum

    /// Builds the Ecore package and its classifiers.
    // @generated
    private init() {
        let classID_Shape = EUUID()
        let featureID_Shape_label = EUUID()
        let featureID_Shape_visible = EUUID()
        let featureID_Shape_weight = EUUID()
        let featureID_Shape_tags = EUUID()
        let featureID_Shape_levels = EUUID()
        let featureID_Shape_colour = EUUID()
        let featureID_Shape_description = EUUID()
        let featureID_Shape_canvas = EUUID()
        let classID_Canvas = EUUID()
        let featureID_Canvas_shapes = EUUID()
        let featureID_Canvas_background = EUUID()
        let featureID_Canvas_favourites = EUUID()
        let featureID_Canvas_selected = EUUID()
        let featureID_Canvas_primary = EUUID()
        let classID_Named = EUUID()
        let featureID_Named_name = EUUID()
        let classID_Circle = EUUID()
        let featureID_Circle_radius = EUUID()
        let featureID_Circle_filled = EUUID()
        let enum_Colour = EEnum(
            name: "Colour",
            literals: [
                EEnumLiteral(name: "Red", value: 0, literal: "Red"),
                EEnumLiteral(name: "Green", value: 1, literal: "Green"),
                EEnumLiteral(name: "Blue", value: 2, literal: "Blue"),
            ])
        let class_Shape = EClass(
            id: classID_Shape, name: "Shape",
            isAbstract: true, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Shape_label, name: "label",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: true, derived: false),
                EAttribute(
                    id: featureID_Shape_visible, name: "visible",
                    eType: EDataType(name: "EBoolean"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: "true", unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Shape_weight, name: "weight",
                    eType: EDataType(name: "EDouble"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: "1.5", unsettable: true, derived: false),
                EAttribute(
                    id: featureID_Shape_tags, name: "tags",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Shape_levels, name: "levels",
                    eType: EDataType(name: "EInt"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: true, derived: false),
                EAttribute(
                    id: featureID_Shape_colour, name: "colour",
                    eType: enum_Colour,
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: "Green", unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Shape_description, name: "description",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: true, transient: true,
                    defaultValueLiteral: nil, unsettable: false, derived: true),
                EReference(
                    id: featureID_Shape_canvas, name: "canvas",
                    eType: EClass(id: classID_Canvas, name: "Canvas"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: featureID_Canvas_shapes,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: true),
            ])
        let class_Canvas = EClass(
            id: classID_Canvas, name: "Canvas",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EReference(
                    id: featureID_Canvas_shapes, name: "shapes",
                    eType: EClass(id: classID_Shape, name: "Shape"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    containment: true, opposite: featureID_Shape_canvas,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
                EReference(
                    id: featureID_Canvas_background, name: "background",
                    eType: EClass(id: classID_Shape, name: "Shape"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: true, opposite: nil,
                    resolveProxies: true, unsettable: true, derived: false,
                    container: false),
                EReference(
                    id: featureID_Canvas_favourites, name: "favourites",
                    eType: EClass(id: classID_Shape, name: "Shape"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: nil,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
                EReference(
                    id: featureID_Canvas_selected, name: "selected",
                    eType: EClass(id: classID_Shape, name: "Shape"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: nil,
                    resolveProxies: false, unsettable: false, derived: false,
                    container: false),
                EReference(
                    id: featureID_Canvas_primary, name: "primary",
                    eType: EClass(id: classID_Shape, name: "Shape"),
                    lowerBound: 1, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: nil,
                    resolveProxies: true, unsettable: true, derived: false,
                    container: false),
            ])
        let class_Named = EClass(
            id: classID_Named, name: "Named",
            isAbstract: true, isInterface: true,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Named_name, name: "name",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
            ])
        let class_Circle = EClass(
            id: classID_Circle, name: "Circle",
            isAbstract: false, isInterface: false,
            eSuperTypes: [class_Shape, class_Named],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Circle_radius, name: "radius",
                    eType: EDataType(name: "EDouble"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Circle_filled, name: "filled",
                    eType: EDataType(name: "EBoolean"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
            ])
        self.ePackage = EPackage(
            name: "classes", nsURI: "http://swift-modelling.org/test/classes", nsPrefix: "cls",
            eClassifiers: [
                class_Shape,
                class_Canvas,
                class_Named,
                class_Circle,
                enum_Colour,
            ])
        self.eShape = class_Shape
        self.eCanvas = class_Canvas
        self.eNamed = class_Named
        self.eCircle = class_Circle
        self.eColour = enum_Colour
    }
}
