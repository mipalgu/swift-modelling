//
//  Footprint.swift
//  ModelTyping
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

/// How a module accesses a metamodel element.
///
/// Under the access-refined semantics, an extension of the published
/// matching definitions, read access requires covariant conformance of the
/// provided element, write access contravariant conformance, and both
/// together invariance.
public struct AccessMode: OptionSet, Sendable, Hashable, Codable {
    /// The raw bit set.
    public let rawValue: Int

    /// Creates an access mode from its raw bit set.
    ///
    /// - Parameter rawValue: The raw bit set.
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// The element is read: a feature is navigated, or a class is matched, tested or enumerated.
    public static let read = AccessMode(rawValue: 1 << 0)
    /// A feature is assigned.
    public static let write = AccessMode(rawValue: 1 << 1)
    /// Instances of a class are created.
    public static let instantiate = AccessMode(rawValue: 1 << 2)

    /// Whether values flow out of the model into the module.
    public var isRead: Bool { contains(.read) }

    /// Whether values flow from the module into the model.
    public var isWrite: Bool { contains(.write) || contains(.instantiate) }

    /// The single uses with their names, in the order in which they are listed.
    private static let namedUses: [(mode: AccessMode, name: String)] = [
        (.read, "read"), (.write, "write"), (.instantiate, "instantiate"),
    ]

    /// The names of the single uses, `read`, `write` and `instantiate`, in the order in which
    /// they are listed.
    public static var allNames: [String] { namedUses.map(\.name) }

    /// The names of the uses that the mode contains, in the order of ``allNames``.
    public var names: [String] { Self.namedUses.filter { contains($0.mode) }.map(\.name) }

    /// A short textual form such as `read`, `write` or `read+write`.
    public var label: String {
        names.isEmpty ? "none" : names.joined(separator: "+")
    }

    /// Creates the access mode of the uses that some names name.
    ///
    /// - Parameter names: Names of ``allNames``, in any order.
    /// - Returns: The mode, or `nil` if a name names no use.
    public init?(names: some Sequence<String>) {
        var mode = AccessMode()
        for name in names {
            guard let use = Self.namedUses.first(where: { $0.name == name }) else { return nil }
            mode.insert(use.mode)
        }
        self = mode
    }

    /// Decodes an access mode from an array of the names of its uses, such as
    /// `["read", "write"]`.
    ///
    /// - Parameter decoder: The decoder.
    /// - Throws: `DecodingError.dataCorrupted` if a name names no use, and the errors of the
    ///   decoder.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let names = try container.decode([String].self)
        guard let mode = AccessMode(names: names) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unknown access in \(names); expected \(Self.allNames)")
        }
        self = mode
    }

    /// Encodes the access mode as an array of the names of its uses, in the order of
    /// ``allNames``.
    ///
    /// - Parameter encoder: The encoder.
    /// - Throws: The errors of the encoder.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(names)
    }
}

/// A reference to a feature through a class.
public struct FeatureReference: Sendable, Hashable, Codable, Comparable, CustomStringConvertible {
    /// The name of the class through which the feature is accessed.
    public let className: String
    /// The name of the feature.
    public let featureName: String

    /// Creates a feature reference.
    ///
    /// - Parameters:
    ///   - className: The name of the class through which the feature is accessed.
    ///   - featureName: The name of the feature.
    public init(className: String, featureName: String) {
        self.className = className
        self.featureName = featureName
    }

    /// The reference written as `Class.feature`.
    public var description: String { Renaming.memberKey(owner: className, member: featureName) }

    /// Orders references by class name, then feature name.
    ///
    /// - Parameters:
    ///   - lhs: The first reference.
    ///   - rhs: The second reference.
    /// - Returns: `true` if `lhs` sorts before `rhs`.
    public static func < (lhs: FeatureReference, rhs: FeatureReference) -> Bool {
        (lhs.className, lhs.featureName) < (rhs.className, rhs.featureName)
    }
}

/// A reference to an enumeration literal.
public struct LiteralReference: Sendable, Hashable, Codable, Comparable, CustomStringConvertible {
    /// The name of the enumeration.
    public let enumerationName: String
    /// The name of the literal.
    public let literalName: String

    /// Creates a literal reference.
    ///
    /// - Parameters:
    ///   - enumerationName: The name of the enumeration.
    ///   - literalName: The name of the literal.
    public init(enumerationName: String, literalName: String) {
        self.enumerationName = enumerationName
        self.literalName = literalName
    }

    /// The reference written as `Enumeration.literal`.
    public var description: String {
        enumerationName + ModelTypingVocabulary.literalSeparator + literalName
    }

    /// Orders references by enumeration name, then literal name.
    ///
    /// - Parameters:
    ///   - lhs: The first reference.
    ///   - rhs: The second reference.
    /// - Returns: `true` if `lhs` sorts before `rhs`.
    public static func < (lhs: LiteralReference, rhs: LiteralReference) -> Bool {
        (lhs.enumerationName, lhs.literalName) < (rhs.enumerationName, rhs.literalName)
    }
}

/// How, and how certainly, a module uses an element.
public struct Usage: Sendable, Hashable, Codable {
    /// The accumulated access modes.
    public var access: AccessMode
    /// Whether at least one use was established from static types rather than guessed.
    public var isCertain: Bool

    /// Creates a usage.
    ///
    /// - Parameters:
    ///   - access: The access modes.
    ///   - isCertain: Whether the use was established from static types (default: `true`).
    public init(_ access: AccessMode, isCertain: Bool = true) {
        self.access = access
        self.isCertain = isCertain
    }

    /// Merges another use of the same element into this one.
    ///
    /// - Parameter other: The other use.
    public mutating func merge(_ other: Usage) {
        access.formUnion(other.access)
        isCertain = isCertain || other.isCertain
    }
}

/// The part a metamodel plays for a module.
public enum MetamodelRole: String, Sendable, Hashable, Codable {
    /// Models of the metamodel are only read.
    case source
    /// Models of the metamodel are only created and written.
    case target
    /// Models of the metamodel are read and written, as in ATL refining mode.
    case sourceAndTarget

    /// The access that a total check of a metamodel in this role assumes for every element.
    public var assumedAccess: AccessMode {
        switch self {
        case .source: return .read
        case .target: return [.write, .instantiate]
        case .sourceAndTarget: return [.read, .write, .instantiate]
        }
    }
}

/// The elements of one metamodel that a module uses.
///
/// Following [Jeanneret, Glinz and Baudry](https://doi.org/10.1145/1985793.1985875) (2011, Sect. 4.2, p. 604), the
/// static metamodel footprint of a model operation is the set of metamodel elements
/// its definition involves. Partial subtyping checks only the part of the
/// required model type that the footprint determines: the footprint itself
/// under the access-refined semantics, or the effective model type extracted
/// from it (``ModelType/effectiveModelType(for:)``) under the published ones.
public struct MetamodelFootprint: Sendable, Hashable, Codable {
    /// The name under which the module refers to the metamodel.
    public let metamodelName: String
    /// The part the metamodel plays for the module.
    public var role: MetamodelRole
    /// The classes used, indexed by name.
    public var classes: [String: Usage]
    /// The features used, indexed by the class they are accessed through.
    public var features: [FeatureReference: Usage]
    /// The enumeration literals used.
    public var literals: [LiteralReference: Usage]

    /// Creates an empty metamodel footprint.
    ///
    /// - Parameters:
    ///   - metamodelName: The name under which the module refers to the metamodel.
    ///   - role: The part the metamodel plays for the module.
    public init(metamodelName: String, role: MetamodelRole) {
        self.metamodelName = metamodelName
        self.role = role
        self.classes = [:]
        self.features = [:]
        self.literals = [:]
    }

    /// Records the use of a class.
    ///
    /// - Parameters:
    ///   - name: The name of the class.
    ///   - usage: How the class is used.
    public mutating func record(className name: String, _ usage: Usage) {
        classes[name, default: Usage([], isCertain: false)].merge(usage)
    }

    /// Records the use of a feature.
    ///
    /// - Parameters:
    ///   - feature: The feature, referenced through a class.
    ///   - usage: How the feature is used.
    public mutating func record(feature: FeatureReference, _ usage: Usage) {
        features[feature, default: Usage([], isCertain: false)].merge(usage)
    }

    /// Records the use of an enumeration literal.
    ///
    /// - Parameters:
    ///   - literal: The literal.
    ///   - usage: How the literal is used.
    public mutating func record(literal: LiteralReference, _ usage: Usage) {
        literals[literal, default: Usage([], isCertain: false)].merge(usage)
    }

    /// The names of the used classes, sorted.
    public var classNames: [String] { classes.keys.sorted() }

    /// The used features, sorted.
    public var featureReferences: [FeatureReference] { features.keys.sorted() }

    /// Whether the footprint uses no element at all.
    public var isEmpty: Bool { classes.isEmpty && features.isEmpty && literals.isEmpty }
}

/// The coding of a metamodel footprint as a JSON object.
///
/// The classes are an object indexed by class name; the features and literals are arrays of
/// objects, sorted by reference, that hold the members of the reference beside those of the
/// usage, such as
/// `{"className": "Book", "featureName": "title", "access": ["read"], "isCertain": true}`.
extension MetamodelFootprint {
    /// The keys of the members of a footprint.
    private enum CodingKeys: String, CodingKey {
        /// The name under which the module refers to the metamodel.
        case metamodelName
        /// The part the metamodel plays for the module.
        case role
        /// The classes used.
        case classes
        /// The features used.
        case features
        /// The enumeration literals used.
        case literals
    }

    /// The use of one feature, as coded in a footprint.
    private struct FeatureUse: Codable {
        /// The name of the class through which the feature is accessed.
        let className: String
        /// The name of the feature.
        let featureName: String
        /// The accumulated access modes.
        let access: AccessMode
        /// Whether the use was established from static types.
        let isCertain: Bool
    }

    /// The use of one enumeration literal, as coded in a footprint.
    private struct LiteralUse: Codable {
        /// The name of the enumeration.
        let enumerationName: String
        /// The name of the literal.
        let literalName: String
        /// The accumulated access modes.
        let access: AccessMode
        /// Whether the use was established from static types.
        let isCertain: Bool
    }

    /// Decodes a footprint from its JSON object.
    ///
    /// - Parameter decoder: The decoder.
    /// - Throws: The errors of the decoder.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            metamodelName: try container.decode(String.self, forKey: .metamodelName),
            role: try container.decode(MetamodelRole.self, forKey: .role))
        classes = try container.decode([String: Usage].self, forKey: .classes)
        for use in try container.decode([FeatureUse].self, forKey: .features) {
            features[FeatureReference(className: use.className, featureName: use.featureName)] =
                Usage(use.access, isCertain: use.isCertain)
        }
        for use in try container.decode([LiteralUse].self, forKey: .literals) {
            literals[LiteralReference(enumerationName: use.enumerationName, literalName: use.literalName)] =
                Usage(use.access, isCertain: use.isCertain)
        }
    }

    /// Encodes the footprint as a JSON object.
    ///
    /// - Parameter encoder: The encoder.
    /// - Throws: The errors of the encoder.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(metamodelName, forKey: .metamodelName)
        try container.encode(role, forKey: .role)
        try container.encode(classes, forKey: .classes)
        let featureUses = features.sorted { $0.key < $1.key }.map { reference, usage in
            FeatureUse(
                className: reference.className, featureName: reference.featureName, access: usage.access,
                isCertain: usage.isCertain)
        }
        try container.encode(featureUses, forKey: .features)
        let literalUses = literals.sorted { $0.key < $1.key }.map { reference, usage in
            LiteralUse(
                enumerationName: reference.enumerationName, literalName: reference.literalName, access: usage.access,
                isCertain: usage.isCertain)
        }
        try container.encode(literalUses, forKey: .literals)
    }
}

/// The kind of a gap in static knowledge met while extracting a footprint.
public enum FootprintUncertaintyKind: String, Sendable, Hashable, Codable {
    /// A feature or operation was applied to an expression whose type could not be determined.
    case unknownReceiverType
    /// A written type name does not name a classifier of any known metamodel.
    case unknownType
    /// A feature is not declared by the static type of its receiver or by any of its subclasses.
    case unknownFeature
    /// A feature is declared only by subclasses of the static type of its receiver.
    case featureInSubclass
    /// An enumeration literal could not be attributed to a single enumeration.
    case unresolvedLiteral
    /// A variable is not bound in its scope.
    case unknownVariable
    /// An operation or helper could not be resolved, so its result type is unknown.
    case unknownOperation
}

/// A gap in static knowledge met while extracting a footprint.
///
/// Extraction is conservative: when types are unknown, the uses it can still
/// identify are recorded as uncertain, and the gap itself is reported here.
public struct FootprintUncertainty: Sendable, Hashable, Codable, CustomStringConvertible {
    /// The kind of gap.
    public let kind: FootprintUncertaintyKind
    /// A description of the gap that names the element involved.
    public let detail: String
    /// The source line of the construct, if known.
    public let line: Int?

    /// Creates an uncertainty.
    ///
    /// - Parameters:
    ///   - kind: The kind of gap.
    ///   - detail: A description that names the element involved.
    ///   - line: The source line of the construct, if known (default: `nil`).
    public init(kind: FootprintUncertaintyKind, detail: String, line: Int? = nil) {
        self.kind = kind
        self.detail = detail
        self.line = line
    }

    /// The uncertainty as one line of text.
    public var description: String {
        (line.map { "line \($0): " } ?? "") + detail
    }
}

/// The elements of every metamodel that a module uses.
public struct Footprint: Sendable, Hashable, Codable {
    /// The footprints of the individual metamodels, indexed by metamodel name.
    public var metamodels: [String: MetamodelFootprint]
    /// The gaps in static knowledge met during extraction.
    public var uncertainties: [FootprintUncertainty]

    /// Creates a footprint.
    ///
    /// - Parameters:
    ///   - metamodels: The metamodel footprints, indexed by metamodel name (default: none).
    ///   - uncertainties: The gaps in static knowledge (default: none).
    public init(metamodels: [String: MetamodelFootprint] = [:], uncertainties: [FootprintUncertainty] = []) {
        self.metamodels = metamodels
        self.uncertainties = uncertainties
    }

    /// The footprint of one metamodel.
    ///
    /// - Parameter name: The metamodel name.
    /// - Returns: The metamodel footprint, or `nil` if the module does not use that metamodel.
    public subscript(metamodel name: String) -> MetamodelFootprint? { metamodels[name] }

    /// Whether the extraction was complete, that is, met no gap in static knowledge.
    public var isComplete: Bool { uncertainties.isEmpty }
}
