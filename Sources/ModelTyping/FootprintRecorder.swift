//
//  FootprintRecorder.swift
//  ModelTyping
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import EMFBase

/// A metamodel as a module refers to it, together with the part it plays.
public struct MetamodelBinding: Sendable, Hashable {
    /// The name under which the module refers to the metamodel.
    ///
    /// For ATL this is the metamodel name of the module header (`Families` in
    /// `IN : Families`); for AQL and MTL it is the name given by the caller,
    /// conventionally the package name.
    public let name: String
    /// The model type of the metamodel the module was written against.
    public let modelType: ModelType
    /// The part the metamodel plays for the module.
    public let role: MetamodelRole

    /// Creates a metamodel binding.
    ///
    /// - Parameters:
    ///   - name: The name under which the module refers to the metamodel.
    ///   - modelType: The model type of the required metamodel.
    ///   - role: The part the metamodel plays for the module (default: ``MetamodelRole/source``).
    public init(name: String, modelType: ModelType, role: MetamodelRole = .source) {
        self.name = name
        self.modelType = modelType
        self.role = role
    }
}

/// Accumulates a footprint while a language-specific walker visits a module.
///
/// The recorder owns type resolution against the required metamodels, so that
/// the ATL, MTL and AQL walkers share one interpretation of written type
/// names, navigations and enumeration literals.
struct FootprintRecorder {
    /// The required metamodels, in lookup order.
    let bindings: [MetamodelBinding]
    /// The footprint recorded so far.
    var footprint: Footprint

    /// Creates a recorder for a set of required metamodels.
    ///
    /// - Parameter bindings: The required metamodels, in lookup order.
    init(bindings: [MetamodelBinding]) {
        self.bindings = bindings
        var footprint = Footprint()
        for binding in bindings {
            footprint.metamodels[binding.name] = MetamodelFootprint(
                metamodelName: binding.name, role: binding.role)
        }
        self.footprint = footprint
    }

    /// The model type bound to a metamodel name.
    func modelType(_ metamodel: String) -> ModelType? {
        bindings.first { $0.name == metamodel }?.modelType
    }

    /// The line an origin starts on, if known.
    static func line(_ origin: SourceOrigin?) -> Int? { origin?.range?.start.line }

    // MARK: - Uncertainties

    /// Records a gap in static knowledge, once per kind, detail and line.
    mutating func note(_ kind: FootprintUncertaintyKind, _ detail: String, at origin: SourceOrigin?) {
        let uncertainty = FootprintUncertainty(kind: kind, detail: detail, line: Self.line(origin))
        if !footprint.uncertainties.contains(uncertainty) {
            footprint.uncertainties.append(uncertainty)
        }
    }

    // MARK: - Recording

    /// Records the use of a class.
    mutating func recordClass(_ className: String, in metamodel: String, _ usage: Usage) {
        footprint.metamodels[metamodel]?.record(className: className, usage)
    }

    /// Records the use of a feature through a class.
    mutating func recordFeature(_ featureName: String, of className: String, in metamodel: String, _ usage: Usage) {
        footprint.metamodels[metamodel]?.record(
            feature: FeatureReference(className: className, featureName: featureName), usage)
    }

    /// Records the use of an enumeration literal.
    mutating func recordLiteral(_ literal: String, of enumeration: String, in metamodel: String, _ usage: Usage) {
        footprint.metamodels[metamodel]?.record(
            literal: LiteralReference(enumerationName: enumeration, literalName: literal), usage)
    }

    // MARK: - Type resolution

    /// The metamodel a qualifier denotes, by metamodel name, package name or namespace prefix.
    func metamodel(forQualifier qualifier: String) -> String? {
        if let binding = bindings.first(where: { $0.name == qualifier }) { return binding.name }
        return bindings.first { $0.modelType.containsPackage(namedOrPrefixed: qualifier) }?.name
    }

    /// Resolves a written type, recording the classes it names.
    ///
    /// - Parameters:
    ///   - text: The type as written in source.
    ///   - access: How the named class is used, or `nil` to record nothing.
    ///   - origin: Where the type is written.
    /// - Returns: The static type the text denotes.
    mutating func resolve(written text: String, access: AccessMode?, at origin: SourceOrigin?) -> StaticType {
        let written = WrittenTypeName(text)
        var type = resolveClassifier(
            qualifier: written.qualifier, name: written.name, access: access, at: origin,
            isPrimitive: written.isPrimitive)
        for _ in 0..<written.collectionDepth { type = .collection(type) }
        return type
    }

    /// Resolves a classifier name, recording a class it names.
    ///
    /// - Parameters:
    ///   - qualifier: The metamodel or package qualifier, if written.
    ///   - name: The simple classifier name.
    ///   - access: How a named class is used, or `nil` to record nothing.
    ///   - origin: Where the name is written.
    ///   - isPrimitive: Whether the name is a known primitive type name.
    /// - Returns: The static type the name denotes.
    mutating func resolveClassifier(
        qualifier: String?, name: String, access: AccessMode?, at origin: SourceOrigin?,
        isPrimitive: Bool = false
    ) -> StaticType {
        if isPrimitive { return .dataValue(name) }
        let candidates: [MetamodelBinding]
        if let qualifier {
            guard let metamodel = metamodel(forQualifier: qualifier) else {
                note(.unknownType, "type '\(qualifier)::\(name)' names an unknown metamodel '\(qualifier)'", at: origin)
                return .unknown
            }
            candidates = bindings.filter { $0.name == metamodel }
        } else {
            candidates = bindings.filter {
                $0.modelType.objectTypes[name] != nil || $0.modelType.enumerations[name] != nil
                    || $0.modelType.dataTypes[name] != nil
            }
        }
        guard let binding = candidates.first else {
            if let canonical = ModelTypingVocabulary.canonicalDataTypes[name] {
                return .dataValue(canonical.rawValue)
            }
            note(.unknownType, "type '\(name)' is not declared by any required metamodel", at: origin)
            return .unknown
        }
        let modelType = binding.modelType
        if modelType.objectTypes[name] != nil {
            if let access { recordClass(name, in: binding.name, Usage(access)) }
            return .object(metamodel: binding.name, className: name)
        }
        if modelType.enumerations[name] != nil {
            return .enumeration(metamodel: binding.name, name: name)
        }
        if let dataType = modelType.dataTypes[name] {
            return .dataValue(Self.dataValueName(typeName: dataType.name, instanceClassName: dataType.instanceClassName))
        }
        note(.unknownType, "type '\(binding.name)!\(name)' is not declared by the required metamodel", at: origin)
        if let access { recordClass(name, in: binding.name, Usage(access)) }
        return .object(metamodel: binding.name, className: name)
    }

    /// The name of the data value category of a data type.
    static func dataValueName(typeName: String, instanceClassName: String?) -> String {
        let canonical = instanceClassName.flatMap { ModelTypingVocabulary.canonicalDataTypes[$0] }
            ?? ModelTypingVocabulary.canonicalDataTypes[typeName]
        return canonical?.rawValue ?? typeName
    }

    /// The static type of the values of a property.
    func valueType(of property: PropertyType, in metamodel: String) -> StaticType {
        let single: StaticType
        switch property.typeKind {
        case .objectType: single = .object(metamodel: metamodel, className: property.typeName)
        case .enumeration: single = .enumeration(metamodel: metamodel, name: property.typeName)
        case .dataType:
            single = .dataValue(Self.dataValueName(typeName: property.typeName, instanceClassName: property.instanceClassName))
        }
        return property.isMany ? .collection(single) : single
    }

    // MARK: - Navigation

    /// Records a feature access and infers the type of its result.
    ///
    /// Navigating a collection navigates each element and flattens the result.
    /// When the receiver's class does not declare the feature, the subclasses
    /// that do are recorded as uncertain uses; when the receiver's type is
    /// unknown, every class declaring a feature of that name is.
    ///
    /// - Parameters:
    ///   - source: The static type of the receiver.
    ///   - feature: The name of the feature.
    ///   - access: How the feature is used.
    ///   - origin: Where the access is written.
    ///   - roles: The metamodel roles that may own the feature when the receiver type is unknown.
    /// - Returns: The static type of the result.
    mutating func navigate(
        _ source: StaticType, feature: String, access: AccessMode, at origin: SourceOrigin?,
        roles: Set<MetamodelRole> = [.source, .sourceAndTarget]
    ) -> StaticType {
        switch source {
        case .collection(let element):
            let result = navigate(element, feature: feature, access: access, at: origin, roles: roles)
            return result.isUnknown ? .unknown : result.flattenedCollection
        case .object(let metamodel, let className):
            return navigate(object: className, in: metamodel, feature: feature, access: access, at: origin)
        case .unknown:
            return navigateUnknown(feature: feature, access: access, at: origin, roles: roles)
        default:
            note(.unknownFeature, "values of type '\(source)' have no feature '\(feature)'", at: origin)
            return .unknown
        }
    }

    /// Navigates a feature of an instance of a known class.
    private mutating func navigate(
        object className: String, in metamodel: String, feature: String, access: AccessMode,
        at origin: SourceOrigin?
    ) -> StaticType {
        guard let modelType = modelType(metamodel), let objectType = modelType.objectTypes[className] else {
            recordFeature(feature, of: className, in: metamodel, Usage(access, isCertain: false))
            note(.unknownFeature, "feature '\(feature)' of undeclared class '\(metamodel)!\(className)'", at: origin)
            return .unknown
        }
        if let property = objectType.property(named: feature) {
            recordFeature(feature, of: className, in: metamodel, Usage(access))
            return valueType(of: property, in: metamodel)
        }
        let owners = modelType.subclassNames(of: className).sorted().filter {
            modelType.objectTypes[$0]?.property(named: feature) != nil
        }
        guard !owners.isEmpty else {
            recordFeature(feature, of: className, in: metamodel, Usage(access, isCertain: false))
            note(.unknownFeature, "'\(metamodel)!\(className)' has no feature '\(feature)'", at: origin)
            return .unknown
        }
        for owner in owners {
            recordFeature(feature, of: owner, in: metamodel, Usage(access, isCertain: false))
        }
        note(.featureInSubclass,
             "feature '\(feature)' is declared only by subclasses of '\(metamodel)!\(className)': "
                + owners.joined(separator: ", "), at: origin)
        return commonType(of: owners.compactMap { modelType.objectTypes[$0]?.property(named: feature) }, in: metamodel)
    }

    /// Navigates a feature of a receiver of unknown type.
    private mutating func navigateUnknown(
        feature: String, access: AccessMode, at origin: SourceOrigin?, roles: Set<MetamodelRole>
    ) -> StaticType {
        var candidates: [(String, String, PropertyType)] = []
        for binding in bindings where roles.contains(binding.role) {
            for (name, objectType) in binding.modelType.objectTypes.sorted(by: { $0.key < $1.key }) {
                if objectType.ownPropertyNames.contains(feature), let property = objectType.property(named: feature) {
                    candidates.append((binding.name, name, property))
                }
            }
        }
        for (metamodel, className, _) in candidates {
            recordFeature(feature, of: className, in: metamodel, Usage(access, isCertain: false))
        }
        let names = candidates.map { "\($0.0)!\($0.1)" }
        note(.unknownReceiverType,
             "feature '\(feature)' applied to an expression of unknown type"
                + (names.isEmpty ? "" : "; candidate owners: " + names.joined(separator: ", ")),
             at: origin)
        guard let metamodel = candidates.first?.0, Set(candidates.map(\.0)).count == 1 else { return .unknown }
        return commonType(of: candidates.map(\.2), in: metamodel)
    }

    /// The value type shared by several properties, or ``StaticType/unknown`` if they differ.
    private func commonType(of properties: [PropertyType], in metamodel: String) -> StaticType {
        let types = Set(properties.map { valueType(of: $0, in: metamodel) })
        return types.count == 1 ? types.first! : .unknown
    }

    // MARK: - Enumeration literals

    /// Records an enumeration literal, attributing it to an enumeration where possible.
    ///
    /// - Parameters:
    ///   - literal: The literal name.
    ///   - enumeration: The enumeration, if written or inferred from context.
    ///   - metamodel: The metamodel of the enumeration, if known.
    ///   - access: How the literal is used.
    ///   - origin: Where the literal is written.
    mutating func literal(
        _ literal: String, enumeration: String?, metamodel: String?, access: AccessMode,
        at origin: SourceOrigin?
    ) {
        if let enumeration, let metamodel {
            recordLiteral(literal, of: enumeration, in: metamodel, Usage(access))
            return
        }
        var candidates: [(String, String)] = []
        for binding in bindings where metamodel == nil || binding.name == metamodel {
            for (name, type) in binding.modelType.enumerations.sorted(by: { $0.key < $1.key })
            where (enumeration == nil || enumeration == name) && type.literalNames.contains(literal) {
                candidates.append((binding.name, name))
            }
        }
        if candidates.count == 1, let (metamodel, name) = candidates.first {
            recordLiteral(literal, of: name, in: metamodel, Usage(access))
            return
        }
        for (metamodel, name) in candidates {
            recordLiteral(literal, of: name, in: metamodel, Usage(access, isCertain: false))
        }
        note(.unresolvedLiteral,
             "literal '\(literal)' "
                + (candidates.isEmpty ? "belongs to no enumeration of the required metamodels"
                    : "may belong to " + candidates.map { "\($0.0)!\($0.1)" }.joined(separator: ", ")),
             at: origin)
    }
}
