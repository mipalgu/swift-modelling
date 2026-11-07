//
// MetamodelIndex.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation

/// The kind of value that a data type or an expression denotes.
indirect enum ValueKind: Equatable, Hashable, Sendable {
    /// A truth value.
    case boolean
    /// An integer.
    case integer
    /// Text.
    case string
    /// A literal of the named enumeration.
    case enumeration(String)
    /// An object of the named class.
    case object(String)
    /// A value of a data type that the exports do not interpret, named by the data type.
    case uninterpreted(String)
}

/// A summary of a structural feature, as the translation of invariants needs it.
struct FeatureInfo: Equatable, Sendable {
    /// The name of the feature.
    let name: String
    /// The name of the class that declares the feature.
    let owner: String
    /// The kind of the values of the feature.
    let kind: ValueKind
    /// The lower bound of the feature.
    let lowerBound: Int
    /// The upper bound of the feature, with `-1` for unbounded.
    let upperBound: Int
    /// Whether the feature is a containment reference.
    let isContainment: Bool
    /// Whether the feature is derived, and therefore not exported.
    let isDerived: Bool
    /// Whether the feature can change after an object has been created.
    let isChangeable: Bool

    /// Whether the feature holds several values.
    var isMany: Bool { upperBound != 1 }

    /// Whether the feature holds at most one value that may be absent.
    var isOptional: Bool { !isMany && lowerBound == 0 }

    /// Whether the feature is a reference.
    var isReference: Bool {
        if case .object = kind { return true }
        return false
    }
}

/// A summary of a class, as the translation of invariants needs it.
struct ClassInfo: Equatable, Sendable {
    /// The name of the class.
    let name: String
    /// The names of the direct supertypes, in declaration order.
    let superTypes: [String]
    /// Whether the class is abstract or an interface, and so has no direct instances.
    let isAbstract: Bool
    /// The features that the class declares, in declaration order.
    let features: [FeatureInfo]
}

/// A name-based index of the classes, enumerations and data types of one or more packages.
///
/// The index resolves types by name, so that the translation of invariants does not depend on
/// how the Ecore runtime represents references between metamodel elements. Nested packages are
/// included; classifiers are identified by their simple names.
struct MetamodelIndex: Sendable {
    /// The classes, by name.
    private(set) var classes: [String: ClassInfo] = [:]
    /// The literals of each enumeration, by enumeration name.
    private(set) var enumerations: [String: [String]] = [:]
    /// The kind of each data type, by data type name.
    private(set) var dataTypes: [String: ValueKind] = [:]

    /// Creates an index of packages and their nested packages.
    ///
    /// - Parameter packages: The packages to index.
    init(packages: [EPackage]) {
        var stack = packages
        var all: [EPackage] = []
        while let package = stack.popLast() {
            all.append(package)
            stack.append(contentsOf: package.eSubpackages)
        }
        for package in all {
            for classifier in package.eClassifiers {
                if let eEnum = classifier as? EEnum {
                    enumerations[eEnum.name] = eEnum.literals.map(\.name)
                } else if let dataType = classifier as? EDataType {
                    dataTypes[dataType.name] = Self.kind(ofDataType: dataType.name, instanceClass: dataType.instanceClassName)
                }
            }
        }
        for package in all {
            for case let eClass as EClass in package.eClassifiers {
                let features = eClass.eStructuralFeatures.compactMap { feature -> FeatureInfo? in
                    if let attribute = feature as? EAttribute {
                        return FeatureInfo(
                            name: attribute.name, owner: eClass.name, kind: kind(of: attribute.eType),
                            lowerBound: attribute.lowerBound, upperBound: attribute.upperBound, isContainment: false,
                            isDerived: attribute.derived || attribute.volatile, isChangeable: attribute.changeable)
                    }
                    guard let reference = feature as? EReference else { return nil }
                    return FeatureInfo(
                        name: reference.name, owner: eClass.name, kind: kind(of: reference.eType),
                        lowerBound: reference.lowerBound, upperBound: reference.upperBound,
                        isContainment: reference.containment,
                        isDerived: reference.derived || reference.volatile, isChangeable: reference.changeable)
                }
                classes[eClass.name] = ClassInfo(
                    name: eClass.name, superTypes: eClass.eSuperTypes.map(\.name),
                    isAbstract: eClass.isAbstract || eClass.isInterface, features: features)
            }
        }
    }

    /// The kind of value of a data type, from its name or the class of its instances.
    ///
    /// - Parameters:
    ///   - name: The name of the data type.
    ///   - instanceClass: The name of the class of its instances, if the model gives one.
    /// - Returns: The kind of value, which is uninterpreted for types that are not integers,
    ///   truth values or text.
    static func kind(ofDataType name: String, instanceClass: String?) -> ValueKind {
        if VerificationVocabulary.integerTypes.contains(name) { return .integer }
        if VerificationVocabulary.booleanTypes.contains(name) { return .boolean }
        if VerificationVocabulary.stringTypes.contains(name) { return .string }
        if let instanceClass {
            if VerificationVocabulary.integerInstanceClasses.contains(instanceClass) { return .integer }
            if VerificationVocabulary.booleanInstanceClasses.contains(instanceClass) { return .boolean }
            if VerificationVocabulary.stringInstanceClasses.contains(instanceClass) { return .string }
        }
        return .uninterpreted(name)
    }

    private func kind(of classifier: any EClassifier) -> ValueKind {
        if classifier is EClass { return .object(classifier.name) }
        if classifier is EEnum { return .enumeration(classifier.name) }
        if let known = dataTypes[classifier.name] { return known }
        return Self.kind(ofDataType: classifier.name, instanceClass: (classifier as? EDataType)?.instanceClassName)
    }

    /// The class and all its direct and indirect supertypes, nearest first.
    ///
    /// - Parameter name: The name of the class.
    /// - Returns: The names of the class and its supertypes, without repetitions.
    func lineage(of name: String) -> [String] {
        var result: [String] = []
        var queue = [name]
        while !queue.isEmpty {
            let next = queue.removeFirst()
            guard !result.contains(next) else { continue }
            result.append(next)
            queue.append(contentsOf: classes[next]?.superTypes ?? [])
        }
        return result
    }

    /// Whether a class is the same as, or a subclass of, another.
    ///
    /// - Parameters:
    ///   - name: The name of the class.
    ///   - other: The name of the possible supertype.
    /// - Returns: `true` if `other` is `name` or one of its supertypes.
    func conforms(_ name: String, to other: String) -> Bool {
        lineage(of: name).contains(other)
    }

    /// Finds a feature of a class or of one of its supertypes.
    ///
    /// - Parameters:
    ///   - name: The name of the feature.
    ///   - className: The name of the class.
    /// - Returns: The feature, or `nil` if neither the class nor a supertype declares it.
    func feature(named name: String, in className: String) -> FeatureInfo? {
        for ancestor in lineage(of: className) {
            if let feature = classes[ancestor]?.features.first(where: { $0.name == name }) { return feature }
        }
        return nil
    }

    /// The concrete classes that conform to a class, in name order.
    ///
    /// - Parameter name: The name of the class.
    /// - Returns: The classes that can have instances that are instances of `name`.
    func concreteSubclasses(of name: String) -> [String] {
        classes.values.filter { !$0.isAbstract && conforms($0.name, to: name) }.map(\.name).sorted()
    }
}
