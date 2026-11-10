//
// InspectionReport.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation

/// What the inspect command found in a metamodel or a model.
///
/// The report holds the same information whether it is written as text or as JSON. Parts that
/// the options of the command did not ask for are left out.
struct InspectionReport: Codable, Sendable, Equatable {
    /// The kinds of document that can be inspected.
    enum Kind: String, Codable, Sendable {
        /// An Ecore metamodel.
        case metamodel

        /// A model that conforms to a metamodel.
        case model

        /// A multi-level model, whose levels are listed.
        case multiLevelModel
    }

    /// The name of the inspected file.
    var file: String

    /// Whether the file is a metamodel or a model.
    var kind: Kind

    /// The format in which the file was read, such as `XMI`.
    var format: String

    /// How much detail the report holds.
    var detail: String

    /// The packages of a metamodel, or `nil` for a model.
    var packages: [PackageReport]?

    /// The contents of a model, or `nil` for a metamodel.
    var model: ModelReport?

    /// The inheritance hierarchy of the classes, if asked for.
    var hierarchy: [HierarchyNode]?

    /// Every reference between the classes of a metamodel, or between the objects of a model,
    /// if asked for.
    var referenceGraph: [ReferenceEdge]?

    /// The levels of a multi-level model, from the top down; `nil` for other documents.
    var multiLevel: MultiLevelReport?
}

/// The levels of a multi-level model.
struct MultiLevelReport: Codable, Sendable, Equatable {
    /// The potency scheme of the model, such as `MetaDepth`.
    var potencyVariant: String

    /// The level crossing mode under which the model is read, as the command line spells it.
    var levelCrossing: String

    /// The levels, from the top down.
    var levels: [LevelReport]
}

/// One level of a multi-level model.
struct LevelReport: Codable, Sendable, Equatable {
    /// The number of the level.
    var level: Int

    /// The name of the level model.
    var name: String

    /// The name of the level model that it instantiates, if any.
    var typeModel: String?

    /// The clabjects of the level, in declaration order.
    var clabjects: [ClabjectReport]
}

/// A clabject of a multi-level model.
struct ClabjectReport: Codable, Sendable, Equatable {
    /// The name of the clabject.
    var name: String

    /// The name of its ontological type, if it has one.
    var type: String?

    /// Its potency, if it declares or receives one.
    var potency: String?

    /// Whether it is an edge rather than a node.
    var isEdge: Bool

    /// Whether it is abstract.
    var isAbstract: Bool

    /// The names of the features that it declares.
    var features: [String]
}

/// One package of a metamodel.
struct PackageReport: Codable, Sendable, Equatable {
    /// The name of the package.
    var name: String

    /// The namespace URI of the package.
    var nsURI: String

    /// The namespace prefix of the package.
    var nsPrefix: String

    /// The classes of the package, in document order.
    var classes: [ClassReport]

    /// The enumerations of the package, in document order.
    var enumerations: [EnumerationReport]

    /// The data types of the package that are not enumerations, in document order.
    var dataTypes: [DataTypeReport]

    /// The subpackages, in document order.
    var subpackages: [PackageReport]
}

/// One class of a metamodel.
struct ClassReport: Codable, Sendable, Equatable {
    /// The name of the class.
    var name: String

    /// Whether the class is abstract.
    var abstract: Bool

    /// Whether the class is an interface.
    var interface: Bool

    /// The names of the direct supertypes, in declared order.
    var supertypes: [String]

    /// The names of all supertypes, most general first, if the inheritance was asked for.
    var allSupertypes: [String]?

    /// The names of the classes that directly extend the class, if the inheritance was asked for.
    var subclasses: [String]?

    /// The attributes that the class declares, if asked for.
    var attributes: [FeatureReport]?

    /// The references that the class declares, if asked for.
    var references: [FeatureReport]?

    /// The features that the class inherits, if the inheritance was asked for.
    var inheritedFeatures: [FeatureReport]?

    /// The operations that the class declares, if asked for.
    var operations: [OperationReport]?

    /// The names of the OCL invariants of the class, if asked for and present.
    var constraints: [String]?
}

/// One attribute or reference of a class.
struct FeatureReport: Codable, Sendable, Equatable {
    /// The name of the feature.
    var name: String

    /// The name of the type of the feature.
    var type: String

    /// The bounds of the feature, such as `[0..*]`.
    var multiplicity: String

    /// The properties of the feature, such as `containment` or `id`.
    var flags: [String]

    /// The default value, if the feature declares one.
    var defaultValue: String?

    /// The opposite of a reference, as `Class.reference`, if it has one.
    var opposite: String?

    /// The class that declares an inherited feature.
    var declaredBy: String?
}

/// One operation of a class.
struct OperationReport: Codable, Sendable, Equatable {
    /// The name of the operation.
    var name: String

    /// The name of the type of the result, or `void`.
    var returnType: String

    /// The parameters, in declared order.
    var parameters: [FeatureReport]
}

/// One enumeration of a metamodel.
struct EnumerationReport: Codable, Sendable, Equatable {
    /// The name of the enumeration.
    var name: String

    /// The literals of the enumeration, in declared order.
    var literals: [LiteralReport]
}

/// One literal of an enumeration.
struct LiteralReport: Codable, Sendable, Equatable {
    /// The name of the literal.
    var name: String

    /// The value of the literal.
    var value: Int
}

/// One data type of a metamodel.
struct DataTypeReport: Codable, Sendable, Equatable {
    /// The name of the data type.
    var name: String

    /// The name of the class of its values, if declared.
    var instanceClassName: String?
}

/// A class and the classes that extend it.
struct HierarchyNode: Codable, Sendable, Equatable {
    /// The name of the class.
    var name: String

    /// The properties of the class, such as `abstract`.
    var flags: [String]

    /// The classes that directly extend the class.
    var subclasses: [HierarchyNode]
}

/// A reference from one class or object to another.
struct ReferenceEdge: Codable, Sendable, Equatable {
    /// The class or object that holds the reference.
    var source: String

    /// The name of the reference.
    var reference: String

    /// The class or object that the reference leads to.
    var target: String

    /// The bounds of the reference, for a metamodel.
    var multiplicity: String?

    /// Whether the reference contains its targets.
    var containment: Bool

    /// The opposite of the reference, as `Class.reference`, if it has one.
    var opposite: String?
}

/// The contents of a model.
struct ModelReport: Codable, Sendable, Equatable {
    /// The number of root objects.
    var rootObjects: Int

    /// The number of objects, including every contained object.
    var objects: Int

    /// The number of objects of each class, in alphabetical order.
    var classes: [ClassCount]

    /// The namespace URIs of the metamodels that the model was read with, or the names of
    /// those registered under their names, as packages of KM3 metamodels are.
    var metamodels: [String]

    /// The containment tree of the objects, for full detail.
    var tree: [ObjectReport]?
}

/// The number of objects of one class.
struct ClassCount: Codable, Sendable, Equatable {
    /// The name of the class.
    var name: String

    /// How many objects the class has.
    var count: Int

    /// The names of all supertypes, most general first, if the inheritance was asked for.
    var supertypes: [String]?
}

/// One object of a model and what it contains.
struct ObjectReport: Codable, Sendable, Equatable {
    /// The name of the class of the object.
    var className: String

    /// The description of the object, its class and the value that names it.
    var label: String

    /// The fragment that locates the object, such as `//@employees.0`.
    var location: String

    /// The attribute values that the object sets, in the order of its class.
    var attributes: [NamedValue]

    /// The non-containment references that the object sets, in the order of its class.
    var references: [NamedValue]

    /// The contained objects, grouped by containment reference.
    var contents: [ContainedObjects]
}

/// A feature and its value, written as text.
struct NamedValue: Codable, Sendable, Equatable {
    /// The name of the feature.
    var name: String

    /// The values of the feature, written as text.
    var values: [String]
}

/// The objects that one containment reference holds.
struct ContainedObjects: Codable, Sendable, Equatable {
    /// The name of the containment reference.
    var feature: String

    /// The contained objects, in order.
    var objects: [ObjectReport]
}

extension InspectionReport {
    /// The report as a JSON document, with sorted keys and indentation.
    ///
    /// - Returns: The JSON text, ending with a line break.
    /// - Throws: The error of the encoder.
    func json() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(self), as: UTF8.self) + "\n"
    }
}
