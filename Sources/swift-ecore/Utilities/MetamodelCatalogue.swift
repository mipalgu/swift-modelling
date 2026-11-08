//
// MetamodelCatalogue.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase

/// The classifiers of one or more metamodels, with the relations between them.
///
/// The catalogue lists every class, enumeration and data type of the packages and their
/// subpackages in document order, and answers which classes extend a class, what a reference
/// is the opposite of, and how bounds are written.
struct MetamodelCatalogue: Sendable {
    /// The packages, in document order, each followed by its subpackages.
    let packages: [EPackage]

    /// Every class of the packages, in document order.
    let classes: [EClass]

    /// The classes by identifier.
    let classesByIdentifier: [EUUID: EClass]

    /// Creates the catalogue of the given root packages.
    ///
    /// - Parameter roots: The root packages of the metamodels.
    init(roots: [EPackage]) {
        packages = roots.flatMap(\.allPackages)
        classes = packages.flatMap { $0.eClassifiers.compactMap { $0 as? EClass } }
        classesByIdentifier = Self.classesByIdentifier(in: roots)
    }

    /// The classes of packages and their subpackages, by identifier.
    ///
    /// - Parameter roots: The root packages.
    /// - Returns: Every class, keyed by its identifier.
    static func classesByIdentifier(in roots: [EPackage]) -> [EUUID: EClass] {
        var result: [EUUID: EClass] = [:]
        for package in roots.flatMap(\.allPackages) {
            for case let eClass as EClass in package.eClassifiers { result[eClass.id] = eClass }
        }
        return result
    }

    /// The canonical definition of a class.
    ///
    /// - Parameter eClass: A class, possibly a copy held by a feature type.
    /// - Returns: The definition in the catalogue, or the class itself if it is not part of it.
    func canonical(_ eClass: EClass) -> EClass {
        classesByIdentifier[eClass.id] ?? eClass
    }

    /// The direct supertypes of a class, in their declared order.
    ///
    /// - Parameter eClass: The class.
    /// - Returns: The canonical supertypes.
    func supertypes(of eClass: EClass) -> [EClass] {
        canonical(eClass).eSuperTypes.map(canonical)
    }

    /// The classes that directly extend a class, in document order.
    ///
    /// - Parameter eClass: The class.
    /// - Returns: The direct subclasses.
    func directSubclasses(of eClass: EClass) -> [EClass] {
        classes.filter { candidate in candidate.eSuperTypes.contains { $0.id == eClass.id } }
    }

    /// The classes that extend a class directly or indirectly, in document order.
    ///
    /// - Parameter eClass: The class.
    /// - Returns: All subclasses.
    func allSubclasses(of eClass: EClass) -> [EClass] {
        classes.filter { candidate in candidate.eAllSuperTypes.contains { $0.id == eClass.id } }
    }

    /// The classes without a supertype in the catalogue, in document order.
    var hierarchyRoots: [EClass] {
        classes.filter { eClass in !eClass.eSuperTypes.contains { classesByIdentifier[$0.id] != nil } }
    }

    /// The reference that is the opposite of a reference, if it has one.
    ///
    /// - Parameter reference: The reference.
    /// - Returns: The opposite reference and the class that declares it.
    func opposite(of reference: EReference) -> (reference: EReference, owner: EClass)? {
        guard let oppositeID = reference.opposite else { return nil }
        for eClass in classes {
            if let found = eClass.eStructuralFeatures.compactMap({ $0 as? EReference }).first(where: { $0.id == oppositeID }) {
                return (found, eClass)
            }
        }
        return nil
    }

    /// The attributes of a class, those of its most general supertypes first.
    ///
    /// - Parameter eClass: The class.
    /// - Returns: The declared and inherited attributes, in the order of the Eclipse Modeling Framework.
    static func attributes(of eClass: EClass) -> [EAttribute] {
        eClass.eAllStructuralFeatures.compactMap { $0 as? EAttribute }
    }

    /// The references of a class, those of its most general supertypes first.
    ///
    /// - Parameter eClass: The class.
    /// - Returns: The declared and inherited references, in the order of the Eclipse Modeling Framework.
    static func references(of eClass: EClass) -> [EReference] {
        eClass.eAllStructuralFeatures.compactMap { $0 as? EReference }
    }

    /// The flags of a class: abstract or interface.
    ///
    /// - Parameter eClass: The class.
    /// - Returns: The flags that apply, in a fixed order.
    static func flags(of eClass: EClass) -> [String] {
        var flags: [String] = []
        if eClass.isInterface {
            flags.append(ModelVocabulary.interfaceFlag)
        } else if eClass.isAbstract {
            flags.append(ModelVocabulary.abstractFlag)
        }
        return flags
    }

    /// The flags of a structural feature.
    ///
    /// - Parameter feature: The attribute or reference.
    /// - Returns: The flags that apply, such as `containment` or `id`, in a fixed order.
    static func flags(of feature: any EStructuralFeature) -> [String] {
        let shape = FeatureShape(feature)
        var flags: [String] = []
        if let reference = feature as? EReference {
            if reference.containment { flags.append(ModelVocabulary.containmentFlag) }
            if reference.container { flags.append(ModelVocabulary.containerFlag) }
        }
        if let attribute = feature as? EAttribute, attribute.isID { flags.append(ModelVocabulary.idFlag) }
        if shape.derived { flags.append(ModelVocabulary.derivedFlag) }
        if shape.transient { flags.append(ModelVocabulary.transientFlag) }
        if !shape.changeable { flags.append(ModelVocabulary.readOnlyFlag) }
        return flags
    }

    /// Writes bounds as a multiplicity.
    ///
    /// - Parameters:
    ///   - lower: The lower bound.
    ///   - upper: The upper bound, ``ModelVocabulary/unboundedUpperBound`` for no limit.
    /// - Returns: For example `[0..1]` or `[1..*]`.
    static func multiplicity(lower: Int, upper: Int) -> String {
        let upperText = upper == ModelVocabulary.unboundedUpperBound ? ModelVocabulary.unbounded : "\(upper)"
        return "[\(lower)..\(upperText)]"
    }

    /// The name of the type of a typed element.
    ///
    /// - Parameter classifier: The type, or `nil` for none.
    /// - Returns: The name of the type, or ``ModelVocabulary/voidType`` for none.
    static func typeName(_ classifier: (any EClassifier)?) -> String {
        classifier?.name ?? ModelVocabulary.voidType
    }
}

/// The properties that attributes and references share.
struct FeatureShape: Sendable {
    /// The type of the feature.
    let type: any EClassifier

    /// The lower bound of the feature.
    let lowerBound: Int

    /// The upper bound of the feature, ``ModelVocabulary/unboundedUpperBound`` for no limit.
    let upperBound: Int

    /// Whether the value of the feature is computed from other features.
    let derived: Bool

    /// Whether the value of the feature is not saved.
    let transient: Bool

    /// Whether the value of the feature can be set.
    let changeable: Bool

    /// Whether the values of the feature are ordered.
    let ordered: Bool

    /// Whether the values of the feature are unique.
    let unique: Bool

    /// Whether the value of the feature is computed when it is read rather than stored.
    let volatile: Bool

    /// Whether the feature distinguishes being unset from holding its default value.
    let unsettable: Bool

    /// The default value of the feature as text, if it declares one.
    let defaultValueLiteral: String?

    /// The bounds of the feature as a multiplicity, such as `[0..*]`.
    var multiplicity: String { MetamodelCatalogue.multiplicity(lower: lowerBound, upper: upperBound) }

    /// Reads the shared properties of an attribute or a reference.
    ///
    /// - Parameter feature: The attribute or reference.
    init(_ feature: any EStructuralFeature) {
        switch feature {
        case let attribute as EAttribute:
            type = attribute.eType
            lowerBound = attribute.lowerBound
            upperBound = attribute.upperBound
            derived = attribute.derived
            transient = attribute.transient
            changeable = attribute.changeable
            ordered = attribute.ordered
            unique = attribute.unique
            volatile = attribute.volatile
            unsettable = attribute.unsettable
            defaultValueLiteral = attribute.defaultValueLiteral
        case let reference as EReference:
            type = reference.eType
            lowerBound = reference.lowerBound
            upperBound = reference.upperBound
            derived = reference.derived
            transient = reference.transient
            changeable = reference.changeable
            ordered = reference.ordered
            unique = reference.unique
            volatile = reference.volatile
            unsettable = reference.unsettable
            defaultValueLiteral = reference.defaultValueLiteral
        default:
            type = EDataType(name: feature.name)
            lowerBound = 0
            upperBound = 1
            derived = false
            transient = false
            changeable = true
            ordered = true
            unique = true
            volatile = false
            unsettable = false
            defaultValueLiteral = nil
        }
    }
}
