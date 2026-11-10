//
//  ModelType.swift
//  ModelTyping
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import ECore
import EMFBase

/// The kind of a structural feature.
public enum PropertyKind: String, Sendable, Hashable, Codable {
    /// A feature whose values are data values (an `EAttribute`).
    case attribute
    /// A feature whose values are objects (an `EReference`).
    case reference
}

/// The kind of classifier a property is typed by.
public enum PropertyTypeKind: String, Sendable, Hashable, Codable {
    /// The property is typed by a class.
    case objectType
    /// The property is typed by a data type.
    case dataType
    /// The property is typed by an enumeration.
    case enumeration
}

/// A property of an object type, as seen by model typing.
///
/// A property captures the parts of an `EStructuralFeature` that structural
/// subtyping compares: its name, kind, type, multiplicity, collection
/// semantics, containment, opposite and changeability. Upper bounds use
/// ``PropertyType/unbounded`` for an unlimited number of values.
public struct PropertyType: Sendable, Hashable, Codable {
    /// The upper bound value that denotes an unlimited number of values.
    public static let unbounded = -1

    /// The name of the property.
    public let name: String
    /// The name of the class that declares the property.
    public let declaringClassName: String
    /// Whether the property is an attribute or a reference.
    public let kind: PropertyKind
    /// The name of the classifier that types the property.
    public let typeName: String
    /// The kind of classifier that types the property.
    public let typeKind: PropertyTypeKind
    /// The Java instance class name of a data type, if the metamodel declares one.
    public let instanceClassName: String?
    /// The minimum number of values.
    public let lowerBound: Int
    /// The maximum number of values, or ``unbounded``.
    public let upperBound: Int
    /// Whether the values of a many-valued property are ordered.
    public let isOrdered: Bool
    /// Whether the values of a many-valued property are unique.
    public let isUnique: Bool
    /// Whether the property is a containment reference.
    public let isContainment: Bool
    /// The name of the opposite reference, if the property has one.
    public let oppositeName: String?
    /// Whether the property can be set.
    public let isChangeable: Bool
    /// Whether the property is derived from other properties.
    public let isDerived: Bool

    /// Creates a property.
    ///
    /// - Parameters:
    ///   - name: The name of the property.
    ///   - declaringClassName: The name of the class that declares the property.
    ///   - kind: Whether the property is an attribute or a reference.
    ///   - typeName: The name of the classifier that types the property.
    ///   - typeKind: The kind of classifier that types the property.
    ///   - instanceClassName: The Java instance class name of a data type (default: `nil`).
    ///   - lowerBound: The minimum number of values (default: 0).
    ///   - upperBound: The maximum number of values, or ``unbounded`` (default: 1).
    ///   - isOrdered: Whether many values are ordered (default: `true`).
    ///   - isUnique: Whether many values are unique (default: `true`).
    ///   - isContainment: Whether the property is a containment reference (default: `false`).
    ///   - oppositeName: The name of the opposite reference (default: `nil`).
    ///   - isChangeable: Whether the property can be set (default: `true`).
    ///   - isDerived: Whether the property is derived (default: `false`).
    public init(
        name: String, declaringClassName: String, kind: PropertyKind, typeName: String,
        typeKind: PropertyTypeKind, instanceClassName: String? = nil, lowerBound: Int = 0,
        upperBound: Int = 1, isOrdered: Bool = true, isUnique: Bool = true,
        isContainment: Bool = false, oppositeName: String? = nil, isChangeable: Bool = true,
        isDerived: Bool = false
    ) {
        self.name = name
        self.declaringClassName = declaringClassName
        self.kind = kind
        self.typeName = typeName
        self.typeKind = typeKind
        self.instanceClassName = instanceClassName
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.isOrdered = isOrdered
        self.isUnique = isUnique
        self.isContainment = isContainment
        self.oppositeName = oppositeName
        self.isChangeable = isChangeable
        self.isDerived = isDerived
    }

    /// Whether the property can hold more than one value.
    public var isMany: Bool { upperBound == Self.unbounded || upperBound > 1 }

    /// The upper bound as a comparable number, with ``unbounded`` mapped to `Int.max`.
    public var effectiveUpperBound: Int { upperBound == Self.unbounded ? Int.max : upperBound }

    /// The multiplicity in the conventional `[lower..upper]` notation.
    public var multiplicityDescription: String {
        "[\(lowerBound)..\(upperBound == Self.unbounded ? "*" : String(upperBound))]"
    }
}

/// An object type: the model typing view of a class.
///
/// Following [Steel and Jézéquel](https://doi.org/10.1007/s10270-006-0036-6), an object type is characterised by its
/// properties. The object type keeps both the properties the class declares
/// itself and the flattened set including every inherited property, so that a
/// provided metamodel may declare a required property in a different place of
/// its inheritance hierarchy.
public struct ObjectType: Sendable, Hashable, Codable {
    /// The name of the class.
    public let name: String
    /// The name of the package that contains the class.
    public let packageName: String
    /// Whether the class is abstract.
    public let isAbstract: Bool
    /// Whether the class is an interface.
    public let isInterface: Bool
    /// The names of the direct supertypes, in declaration order.
    public let directSuperTypeNames: [String]
    /// The names of all direct and indirect supertypes.
    public let allSuperTypeNames: Set<String>
    /// The names of the properties the class declares itself, in declaration order.
    public let ownPropertyNames: [String]
    /// Every property of the class, including inherited ones, indexed by name.
    public let properties: [String: PropertyType]

    /// Creates an object type.
    ///
    /// - Parameters:
    ///   - name: The name of the class.
    ///   - packageName: The name of the containing package.
    ///   - isAbstract: Whether the class is abstract.
    ///   - isInterface: Whether the class is an interface.
    ///   - directSuperTypeNames: The names of the direct supertypes.
    ///   - allSuperTypeNames: The names of all supertypes.
    ///   - ownPropertyNames: The names of the declared properties.
    ///   - properties: Every property including inherited ones, indexed by name.
    public init(
        name: String, packageName: String, isAbstract: Bool, isInterface: Bool,
        directSuperTypeNames: [String], allSuperTypeNames: Set<String>, ownPropertyNames: [String],
        properties: [String: PropertyType]
    ) {
        self.name = name
        self.packageName = packageName
        self.isAbstract = isAbstract
        self.isInterface = isInterface
        self.directSuperTypeNames = directSuperTypeNames
        self.allSuperTypeNames = allSuperTypeNames
        self.ownPropertyNames = ownPropertyNames
        self.properties = properties
    }

    /// Whether instances of the class can be created.
    public var isInstantiable: Bool { !isAbstract && !isInterface }

    /// Looks up a property, including inherited ones.
    ///
    /// - Parameter name: The name of the property.
    /// - Returns: The property, or `nil` if the class has no property of that name.
    public func property(named name: String) -> PropertyType? { properties[name] }
}

/// An enumeration type.
public struct EnumerationType: Sendable, Hashable, Codable {
    /// The name of the enumeration.
    public let name: String
    /// The name of the package that contains the enumeration.
    public let packageName: String
    /// The names of the literals, in declaration order.
    public let literalNames: [String]

    /// Creates an enumeration type.
    ///
    /// - Parameters:
    ///   - name: The name of the enumeration.
    ///   - packageName: The name of the containing package.
    ///   - literalNames: The names of the literals.
    public init(name: String, packageName: String, literalNames: [String]) {
        self.name = name
        self.packageName = packageName
        self.literalNames = literalNames
    }
}

/// A data type declared by a metamodel.
public struct DataTypeDescriptor: Sendable, Hashable, Codable {
    /// The name of the data type.
    public let name: String
    /// The Java instance class name, if declared.
    public let instanceClassName: String?

    /// Creates a data type descriptor.
    ///
    /// - Parameters:
    ///   - name: The name of the data type.
    ///   - instanceClassName: The Java instance class name, if declared.
    public init(name: String, instanceClassName: String?) {
        self.name = name
        self.instanceClassName = instanceClassName
    }
}

/// A model type: the set of object types a metamodel defines.
///
/// [Steel and Jézéquel](https://doi.org/10.1007/s10270-006-0036-6) define a model type as a set of object types, so that
/// metamodels can be compared structurally rather than by identity. A model
/// type is built from one or more `EPackage`s (including their subpackages)
/// and indexes their classes, enumerations and data types by name. Classes are
/// also reachable by their qualified name `package::Class`.
public struct ModelType: Sendable, Hashable {
    /// The names of the packages the model type was built from.
    public let packageNames: [String]
    /// The namespace prefixes of the packages the model type was built from.
    public let packagePrefixes: [String]
    /// The object types, indexed by class name.
    public let objectTypes: [String: ObjectType]
    /// The enumerations, indexed by name.
    public let enumerations: [String: EnumerationType]
    /// The data types declared by the packages, indexed by name.
    public let dataTypes: [String: DataTypeDescriptor]

    /// Builds the model type of a set of packages.
    ///
    /// Supertypes and inherited properties are resolved by name within the
    /// given packages, and opposites are resolved through their identifiers.
    /// When two packages declare a classifier with the same name, the first
    /// declaration is used.
    ///
    /// - Parameter packages: The packages whose classifiers form the model type.
    public init(packages: [EPackage]) {
        let allPackages = packages.flatMap(\.allPackages)
        var classes: [(EClass, String)] = []
        var enumerations: [String: EnumerationType] = [:]
        var dataTypes: [String: DataTypeDescriptor] = [:]
        for package in allPackages {
            for classifier in package.eClassifiers {
                switch classifier {
                case let eClass as EClass:
                    classes.append((eClass, package.name))
                case let eEnum as EEnum:
                    if enumerations[eEnum.name] == nil {
                        enumerations[eEnum.name] = EnumerationType(
                            name: eEnum.name, packageName: package.name,
                            literalNames: eEnum.literals.map(\.name))
                    }
                case let dataType as EDataType:
                    if dataTypes[dataType.name] == nil {
                        dataTypes[dataType.name] = DataTypeDescriptor(
                            name: dataType.name, instanceClassName: dataType.instanceClassName)
                    }
                default:
                    break
                }
            }
        }
        var referenceNames: [EUUID: String] = [:]
        for (eClass, _) in classes {
            for case let reference as EReference in eClass.eStructuralFeatures {
                referenceNames[reference.id] = reference.name
            }
        }
        var classByName: [String: (EClass, String)] = [:]
        for entry in classes where classByName[entry.0.name] == nil {
            classByName[entry.0.name] = entry
        }
        var ownProperties: [String: [PropertyType]] = [:]
        for (name, entry) in classByName {
            ownProperties[name] = entry.0.eStructuralFeatures.map {
                Self.property(of: $0, declaredBy: name, opposites: referenceNames,
                              enumerations: enumerations, dataTypes: dataTypes)
            }
        }
        var objectTypes: [String: ObjectType] = [:]
        for (name, entry) in classByName {
            let eClass = entry.0
            let order = Self.linearisedSuperTypes(of: name, in: classByName)
            var properties: [String: PropertyType] = [:]
            for className in [name] + order {
                for property in ownProperties[className] ?? [] where properties[property.name] == nil {
                    properties[property.name] = property
                }
            }
            objectTypes[name] = ObjectType(
                name: name, packageName: entry.1, isAbstract: eClass.isAbstract,
                isInterface: eClass.isInterface,
                directSuperTypeNames: eClass.eSuperTypes.map(\.name),
                allSuperTypeNames: Set(order), ownPropertyNames: eClass.eStructuralFeatures.map(\.name),
                properties: properties)
        }
        self.packageNames = allPackages.map(\.name)
        self.packagePrefixes = allPackages.map(\.nsPrefix)
        self.objectTypes = objectTypes
        self.enumerations = enumerations
        self.dataTypes = dataTypes
    }

    /// Creates a model type directly from its parts.
    ///
    /// - Parameters:
    ///   - packageNames: The names of the packages the model type represents.
    ///   - objectTypes: The object types, indexed by class name.
    ///   - enumerations: The enumerations, indexed by name (default: none).
    ///   - dataTypes: The declared data types, indexed by name (default: none).
    public init(
        packageNames: [String], objectTypes: [String: ObjectType],
        enumerations: [String: EnumerationType] = [:], dataTypes: [String: DataTypeDescriptor] = [:]
    ) {
        self.packageNames = packageNames
        self.packagePrefixes = []
        self.objectTypes = objectTypes
        self.enumerations = enumerations
        self.dataTypes = dataTypes
    }

    /// Looks up an object type by simple or qualified name.
    ///
    /// - Parameter name: A class name, optionally qualified as `package::Class`.
    /// - Returns: The object type, or `nil` if the model type has no such class.
    public func objectType(named name: String) -> ObjectType? {
        if let objectType = objectTypes[name] { return objectType }
        let (qualifier, simpleName) = Self.splitQualifiedName(name)
        guard let qualifier, let objectType = objectTypes[simpleName],
            objectType.packageName == qualifier || packagePrefixes.contains(qualifier)
        else { return nil }
        return objectType
    }

    /// Whether the model type was built from a package with the given name or prefix.
    ///
    /// - Parameter qualifier: A package name or namespace prefix.
    /// - Returns: `true` if one of the packages has that name or prefix.
    public func containsPackage(namedOrPrefixed qualifier: String) -> Bool {
        packageNames.contains(qualifier) || packagePrefixes.contains(qualifier)
    }

    /// Whether one class is the same as, or a subclass of, another.
    ///
    /// - Parameters:
    ///   - subclassName: The name of the potential subclass.
    ///   - superclassName: The name of the potential superclass.
    /// - Returns: `true` if both classes exist and the first conforms to the second.
    public func conforms(_ subclassName: String, to superclassName: String) -> Bool {
        guard let subclass = objectTypes[subclassName], objectTypes[superclassName] != nil else {
            return false
        }
        return subclassName == superclassName || subclass.allSuperTypeNames.contains(superclassName)
    }

    /// The names of the classes that conform to a class, including the class itself.
    ///
    /// - Parameter className: The name of the class.
    /// - Returns: The names of the class and all of its direct and indirect subclasses.
    public func subclassNames(of className: String) -> Set<String> {
        Set(objectTypes.values.filter { conforms($0.name, to: className) }.map(\.name))
    }

    /// Splits a qualified name into its qualifier and simple name.
    ///
    /// Both the AQL separator `::` and the ATL separator `!` are recognised;
    /// the last separator determines the split.
    ///
    /// - Parameter name: A simple or qualified name.
    /// - Returns: The qualifier (or `nil` for a simple name) and the simple name.
    public static func splitQualifiedName(_ name: String) -> (qualifier: String?, name: String) {
        for separator in [ModelTypingVocabulary.aqlTypeSeparator, ModelTypingVocabulary.atlTypeSeparator] {
            if let range = name.range(of: separator, options: .backwards) {
                return (String(name[..<range.lowerBound]), String(name[range.upperBound...]))
            }
        }
        return (nil, name)
    }

    // MARK: - Construction helpers

    /// Converts an Ecore feature into a property.
    private static func property(
        of feature: any EStructuralFeature, declaredBy className: String, opposites: [EUUID: String],
        enumerations: [String: EnumerationType], dataTypes: [String: DataTypeDescriptor]
    ) -> PropertyType {
        if let reference = feature as? EReference {
            return PropertyType(
                name: reference.name, declaringClassName: className, kind: .reference,
                typeName: reference.eType.name, typeKind: .objectType,
                lowerBound: reference.lowerBound, upperBound: reference.upperBound,
                isOrdered: reference.ordered, isUnique: reference.unique,
                isContainment: reference.containment,
                oppositeName: reference.opposite.flatMap { opposites[$0] },
                isChangeable: reference.changeable, isDerived: reference.derived)
        }
        let attribute = feature as? EAttribute
        let type = attribute?.eType
        let typeName = type?.name ?? ""
        let typeKind: PropertyTypeKind = type is EEnum || enumerations[typeName] != nil
            ? .enumeration : .dataType
        return PropertyType(
            name: feature.name, declaringClassName: className, kind: .attribute,
            typeName: typeName, typeKind: typeKind,
            instanceClassName: (type as? EDataType)?.instanceClassName
                ?? dataTypes[typeName]?.instanceClassName,
            lowerBound: attribute?.lowerBound ?? 0, upperBound: attribute?.upperBound ?? 1,
            isOrdered: attribute?.ordered ?? true, isUnique: attribute?.unique ?? true,
            isChangeable: attribute?.changeable ?? true, isDerived: attribute?.derived ?? false)
    }

    /// Lists the supertypes of a class breadth first, each once, resolving names in the index.
    private static func linearisedSuperTypes(
        of className: String, in classes: [String: (EClass, String)]
    ) -> [String] {
        var order: [String] = []
        var seen: Set<String> = [className]
        var queue = classes[className].map { $0.0.eSuperTypes.map(\.name) } ?? []
        while !queue.isEmpty {
            let next = queue.removeFirst()
            guard seen.insert(next).inserted else { continue }
            order.append(next)
            queue.append(contentsOf: classes[next].map { $0.0.eSuperTypes.map(\.name) } ?? [])
        }
        return order
    }
}
