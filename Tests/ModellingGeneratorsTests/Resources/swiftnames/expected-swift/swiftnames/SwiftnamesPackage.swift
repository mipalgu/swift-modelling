//
//  SwiftnamesPackage.swift
//

import ECore
import EMFBase
import Foundation

/// The description of the swiftnames package.
///
/// The shared instance builds the Ecore package of the model, with the metaclass of each class, enumeration and
/// data type, which the objects of the package return as their metaclass.
// @generated
public struct SwiftnamesPackage: Sendable {
    /// The shared description of the package.
    // @generated
    public static let shared = SwiftnamesPackage()

    /// The Ecore package that holds the classifiers.
    // @generated
    public let ePackage: EPackage

    /// The factory that creates the objects of the package.
    // @generated
    public var factory: SwiftnamesFactory { SwiftnamesFactory.shared }

    /// The metaclass of the Type class.
    // @generated
    public let eType: EClass

    /// The metaclass of the Vehicle class.
    // @generated
    public let eVehicle: EClass

    /// The metaclass of the Truck class.
    // @generated
    public let eTruck: EClass

    /// The metaclass of the Driver class.
    // @generated
    public let eDriver: EClass

    /// The metaclass of the Date class.
    // @generated
    public let eDate: EClass

    /// The metaclass of the Package class.
    // @generated
    public let ePackage_: EClass

    /// The metaclass of the Values class.
    // @generated
    public let eValues: EClass

    /// The Ecore enumeration of the Hue enumeration.
    // @generated
    public let eHue: EEnum

    /// The Ecore enumeration of the Mood enumeration.
    // @generated
    public let eMood: EEnum

    /// The Ecore data type of the Stamp data type.
    // @generated
    public let eStamp: EDataType

    /// Builds the Ecore package and its classifiers.
    // @generated
    private init() {
        let classID_Type = EUUID()
        let featureID_Type_name = EUUID()
        let featureID_Type_default = EUUID()
        let classID_Vehicle = EUUID()
        let featureID_Vehicle_guard = EUUID()
        let featureID_Vehicle_class = EUUID()
        let featureID_Vehicle_operator = EUUID()
        let featureID_Vehicle_repeat = EUUID()
        let featureID_Vehicle_where = EUUID()
        let featureID_Vehicle_in = EUUID()
        let featureID_Vehicle_protocol = EUUID()
        let featureID_Vehicle_id = EUUID()
        let featureID_Vehicle_hash = EUUID()
        let featureID_Vehicle_hue = EUUID()
        let featureID_Vehicle_shades = EUUID()
        let featureID_Vehicle_driver = EUUID()
        let featureID_Vehicle_kinds = EUUID()
        let featureID_Vehicle_wheels = EUUID()
        let classID_Truck = EUUID()
        let featureID_Truck_load = EUUID()
        let featureID_Truck_plate = EUUID()
        let featureID_Truck_trailer = EUUID()
        let featureID_Truck_towedBy = EUUID()
        let classID_Driver = EUUID()
        let featureID_Driver_vehicle = EUUID()
        let classID_Date = EUUID()
        let featureID_Date_when = EUUID()
        let featureID_Date_text = EUUID()
        let classID_Package = EUUID()
        let classID_Values = EUUID()
        let featureID_Values_big = EUUID()
        let featureID_Values_money = EUUID()
        let featureID_Values_bytes = EUUID()
        let featureID_Values_initial = EUUID()
        let featureID_Values_payload = EUUID()
        let featureID_Values_ratio = EUUID()
        let featureID_Values_small = EUUID()
        let featureID_Values_tiny = EUUID()
        let featureID_Values_huge = EUUID()
        let featureID_Values_flag = EUUID()
        let featureID_Values_count = EUUID()
        let featureID_Values_stamp = EUUID()
        let featureID_Values_mood = EUUID()
        let enum_Hue = EEnum(
            name: "Hue",
            literals: [
                EEnumLiteral(name: "red", value: 0, literal: "red"),
                EEnumLiteral(name: "green", value: 2, literal: "green"),
                EEnumLiteral(name: "blue", value: 3, literal: "blue"),
            ])
        let enum_Mood = EEnum(
            name: "Mood",
            literals: [
            ])
        let dataType_Stamp = EDataType(name: "Stamp", instanceClassName: "java.util.Date")
        let class_Type = EClass(
            id: classID_Type, name: "Type",
            isAbstract: true, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Type_name, name: "name",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: "say \"hi\"\n\\there", unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Type_default, name: "default",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
            ])
        let class_Vehicle = EClass(
            id: classID_Vehicle, name: "Vehicle",
            isAbstract: false, isInterface: false,
            eSuperTypes: [class_Type],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Vehicle_guard, name: "guard",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Vehicle_class, name: "class",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Vehicle_operator, name: "operator",
                    eType: EDataType(name: "EInt"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Vehicle_repeat, name: "repeat",
                    eType: EDataType(name: "EBoolean"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Vehicle_where, name: "where",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Vehicle_in, name: "in",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Vehicle_protocol, name: "protocol",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Vehicle_id, name: "id",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Vehicle_hash, name: "hash",
                    eType: EDataType(name: "EInt"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Vehicle_hue, name: "hue",
                    eType: enum_Hue,
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: "green", unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Vehicle_shades, name: "shades",
                    eType: enum_Hue,
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EReference(
                    id: featureID_Vehicle_driver, name: "driver",
                    eType: EClass(id: classID_Driver, name: "Driver"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: featureID_Driver_vehicle,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
                EReference(
                    id: featureID_Vehicle_kinds, name: "kinds",
                    eType: EClass(id: classID_Type, name: "Type"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: nil,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
                EReference(
                    id: featureID_Vehicle_wheels, name: "wheels",
                    eType: EClass(name: "Wheel"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    containment: true, opposite: nil,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
            ])
        let class_Truck = EClass(
            id: classID_Truck, name: "Truck",
            isAbstract: false, isInterface: false,
            eSuperTypes: [class_Vehicle],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Truck_load, name: "load",
                    eType: EDataType(name: "EDouble"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: "2.5", unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Truck_plate, name: "plate",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: "N/A", unsettable: false, derived: false),
                EReference(
                    id: featureID_Truck_trailer, name: "trailer",
                    eType: EClass(id: classID_Truck, name: "Truck"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: featureID_Truck_towedBy,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
                EReference(
                    id: featureID_Truck_towedBy, name: "towedBy",
                    eType: EClass(id: classID_Truck, name: "Truck"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: featureID_Truck_trailer,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
            ])
        let class_Driver = EClass(
            id: classID_Driver, name: "Driver",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EReference(
                    id: featureID_Driver_vehicle, name: "vehicle",
                    eType: EClass(id: classID_Vehicle, name: "Vehicle"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: featureID_Vehicle_driver,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
            ])
        let class_Date = EClass(
            id: classID_Date, name: "Date",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Date_when, name: "when",
                    eType: EDataType(name: "EDate"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Date_text, name: "text",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
            ])
        let class_Package = EClass(
            id: classID_Package, name: "Package",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
            ])
        let class_Values = EClass(
            id: classID_Values, name: "Values",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Values_big, name: "big",
                    eType: EDataType(name: "EBigInteger"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Values_money, name: "money",
                    eType: EDataType(name: "EBigDecimal"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Values_bytes, name: "bytes",
                    eType: EDataType(name: "EByteArray"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Values_initial, name: "initial",
                    eType: EDataType(name: "EChar"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: "x", unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Values_payload, name: "payload",
                    eType: EDataType(name: "EJavaObject"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Values_ratio, name: "ratio",
                    eType: EDataType(name: "EFloat"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: "0.5", unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Values_small, name: "small",
                    eType: EDataType(name: "EShort"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Values_tiny, name: "tiny",
                    eType: EDataType(name: "EByte"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Values_huge, name: "huge",
                    eType: EDataType(name: "ELong"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: "99999999999", unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Values_flag, name: "flag",
                    eType: EDataType(name: "EBooleanObject"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Values_count, name: "count",
                    eType: EDataType(name: "EIntegerObject"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: "7", unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Values_stamp, name: "stamp",
                    eType: dataType_Stamp,
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Values_mood, name: "mood",
                    eType: enum_Mood,
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
            ])
        self.ePackage = EPackage(
            name: "swiftnames", nsURI: "http://swift-modelling.org/test/swiftnames", nsPrefix: "sn",
            eClassifiers: [
                class_Type,
                class_Vehicle,
                class_Truck,
                class_Driver,
                class_Date,
                class_Package,
                class_Values,
                enum_Hue,
                enum_Mood,
                dataType_Stamp,
            ])
        self.eType = class_Type
        self.eVehicle = class_Vehicle
        self.eTruck = class_Truck
        self.eDriver = class_Driver
        self.eDate = class_Date
        self.ePackage_ = class_Package
        self.eValues = class_Values
        self.eHue = enum_Hue
        self.eMood = enum_Mood
        self.eStamp = dataType_Stamp
    }
}
