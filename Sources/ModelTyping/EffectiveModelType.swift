//
//  EffectiveModelType.swift
//  ModelTyping
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

/// The effective model type of a module: the part of a required model type that the module needs.
///
/// [Guy et al.](https://doi.org/10.1007/978-3-642-31491-9_30) (2012, Def. 9 and 10, p. 409) define partial subtyping
/// with respect to the effective model type of a feature, extracted from the
/// required model type so that the required model type matches it. The
/// extraction starts from the footprint of the module
/// ([Jeanneret, Glinz and Baudry 2011](https://doi.org/10.1145/1985793.1985875), Sect. 4.2,
/// p. 604) and closes it in the manner of positive metamodel slicing
/// ([Degueule et al. 2015](https://doi.org/10.1145/2814251.2814252), Sect. 3.3.3, pp. 29-30):
/// with
/// every used class come its superclasses and its mandatory features, and
/// with every included feature comes the class or enumeration that types it,
/// until nothing more is added. The mandatory features are needed because
/// MOF class matching (Guy et al. 2012, Def. 3, condition 5) demands a
/// counterpart for every mandatory feature of the matching class.
///
/// Each included element remembers whether it is reached from at least one
/// use that was established from static types, so that a partial check can
/// report elements reached only from guessed uses as warnings.
struct EffectiveModelType: Sendable {
    /// The effective model type.
    let modelType: ModelType
    /// The classes reached from a certain use.
    private let certainClasses: Set<String>
    /// The features reached from a certain use, as `Class.feature` references.
    private let certainFeatures: Set<FeatureReference>
    /// The enumerations reached from a certain use.
    private let certainEnumerations: Set<String>

    /// Extracts the effective model type of a footprint from a required model type.
    ///
    /// Footprint elements that the required model type does not declare are
    /// left out, since no part of it can describe them.
    ///
    /// - Parameters:
    ///   - required: The required model type.
    ///   - footprint: The footprint of the module on that model type.
    init(of required: ModelType, for footprint: MetamodelFootprint) {
        var slice = Slice(required: required)
        for (name, usage) in footprint.classes { slice.include(className: name, certain: usage.isCertain) }
        for (reference, usage) in footprint.features {
            slice.include(feature: reference.featureName, of: reference.className, certain: usage.isCertain)
        }
        for (literal, usage) in footprint.literals {
            slice.include(enumeration: literal.enumerationName, certain: usage.isCertain)
        }
        slice.close()
        var objectTypes: [String: ObjectType] = [:]
        for (name, _) in slice.classes {
            let objectType = required.objectTypes[name]!
            let kept = Set(slice.features[name]?.keys.map { $0 } ?? [])
            objectTypes[name] = ObjectType(
                name: name, packageName: objectType.packageName, isAbstract: objectType.isAbstract,
                isInterface: objectType.isInterface,
                directSuperTypeNames: objectType.directSuperTypeNames.filter { slice.classes[$0] != nil },
                allSuperTypeNames: objectType.allSuperTypeNames.filter { slice.classes[$0] != nil },
                ownPropertyNames: objectType.ownPropertyNames.filter(kept.contains),
                properties: objectType.properties.filter { kept.contains($0.key) })
        }
        modelType = ModelType(
            packageNames: required.packageNames, objectTypes: objectTypes,
            enumerations: required.enumerations.filter { slice.enumerations[$0.key] != nil },
            dataTypes: required.dataTypes)
        certainClasses = Set(slice.classes.filter(\.value).map(\.key))
        certainFeatures = Set(slice.features.flatMap { owner, features in
            features.filter(\.value).map { FeatureReference(className: owner, featureName: $0.key) }
        })
        certainEnumerations = Set(slice.enumerations.filter(\.value).map(\.key))
    }

    /// Whether a class is reached from a certain use.
    ///
    /// - Parameter className: The name of the class.
    /// - Returns: `true` if at least one certain use leads to the class.
    func isCertain(className: String) -> Bool { certainClasses.contains(className) }

    /// Whether a feature is reached from a certain use.
    ///
    /// - Parameters:
    ///   - feature: The name of the feature.
    ///   - className: The class through which the feature is included.
    /// - Returns: `true` if at least one certain use leads to the feature.
    func isCertain(feature: String, of className: String) -> Bool {
        certainFeatures.contains(FeatureReference(className: className, featureName: feature))
    }

    /// Whether an enumeration is reached from a certain use.
    ///
    /// - Parameter enumeration: The name of the enumeration.
    /// - Returns: `true` if at least one certain use leads to the enumeration.
    func isCertain(enumeration: String) -> Bool { certainEnumerations.contains(enumeration) }
}

/// The growing set of included elements while an effective model type is sliced.
private struct Slice {
    /// The required model type being sliced.
    let required: ModelType
    /// The included classes, with whether a certain use reaches them.
    var classes: [String: Bool] = [:]
    /// The included features per class, with whether a certain use reaches them.
    var features: [String: [String: Bool]] = [:]
    /// The included enumerations, with whether a certain use reaches them.
    var enumerations: [String: Bool] = [:]
    /// Whether the last inclusion added an element or made one certain.
    private var changed = false

    /// Creates an empty slice of a required model type.
    ///
    /// - Parameter required: The required model type.
    init(required: ModelType) { self.required = required }

    /// Includes a class, if the required model type declares it.
    mutating func include(className: String, certain: Bool) {
        guard required.objectTypes[className] != nil else { return }
        let entry = Self.merged(classes[className], certain)
        if entry != classes[className] { classes[className] = entry; changed = true }
    }

    /// Includes a feature and its class, if the required model type declares them.
    mutating func include(feature: String, of className: String, certain: Bool) {
        guard required.objectTypes[className]?.property(named: feature) != nil else { return }
        include(className: className, certain: certain)
        let entry = Self.merged(features[className]?[feature], certain)
        if entry != features[className]?[feature] { features[className, default: [:]][feature] = entry; changed = true }
    }

    /// Includes an enumeration, if the required model type declares it.
    mutating func include(enumeration: String, certain: Bool) {
        guard required.enumerations[enumeration] != nil else { return }
        let entry = Self.merged(enumerations[enumeration], certain)
        if entry != enumerations[enumeration] { enumerations[enumeration] = entry; changed = true }
    }

    /// Adds superclasses, mandatory features and feature types until nothing changes.
    mutating func close() {
        repeat {
            changed = false
            for (name, certain) in classes {
                let objectType = required.objectTypes[name]!
                for superName in objectType.allSuperTypeNames { include(className: superName, certain: certain) }
                for property in objectType.properties.values where property.lowerBound > 0 {
                    include(feature: property.name, of: name, certain: certain)
                }
            }
            for (owner, included) in features {
                for (feature, certain) in included {
                    guard let property = required.objectTypes[owner]?.property(named: feature) else { continue }
                    switch property.typeKind {
                    case .objectType: include(className: property.typeName, certain: certain)
                    case .enumeration: include(enumeration: property.typeName, certain: certain)
                    case .dataType: break
                    }
                }
            }
        } while changed
    }

    /// The certainty of an element after one more inclusion.
    ///
    /// - Parameters:
    ///   - entry: Whether a certain use reaches the element so far, or `nil` if it is not yet included.
    ///   - certain: Whether the new use is certain.
    /// - Returns: Whether a certain use reaches the element after the inclusion.
    private static func merged(_ entry: Bool?, _ certain: Bool) -> Bool { (entry ?? false) || certain }
}

extension ModelType {
    /// Extracts the effective model type of a footprint.
    ///
    /// The effective model type (Guy et al. 2012, Def. 9 and 10, p. 409)
    /// contains the classes and features that the footprint uses, together
    /// with their superclasses, the mandatory features of every included
    /// class, and the classes and enumerations that type included features,
    /// closed transitively. Partial subtyping under a published matching
    /// semantics matches the provided model type against it (Def. 12 and 14,
    /// p. 410).
    ///
    /// - Parameter footprint: The footprint of a module on this model type.
    /// - Returns: The effective model type.
    public func effectiveModelType(for footprint: MetamodelFootprint) -> ModelType {
        EffectiveModelType(of: self, for: footprint).modelType
    }
}
