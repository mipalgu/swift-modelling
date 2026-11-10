//
//  TypingDiagnostic.swift
//  ModelTyping
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

/// How serious a typing diagnostic is.
public enum TypingSeverity: String, Sendable, Hashable, Codable, Comparable {
    /// The module cannot safely run on models of the provided metamodel.
    case error
    /// The module may misbehave, or a use that could only be guessed may fail.
    case warning
    /// Information that does not affect compatibility.
    case note

    /// Orders severities from most to least serious.
    ///
    /// - Parameters:
    ///   - lhs: The first severity.
    ///   - rhs: The second severity.
    /// - Returns: `true` if `lhs` is more serious than `rhs`.
    public static func < (lhs: TypingSeverity, rhs: TypingSeverity) -> Bool {
        let order: [TypingSeverity] = [.error, .warning, .note]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

/// The stable code of a typing diagnostic.
public enum TypingDiagnosticCode: String, Sendable, Hashable, Codable, CaseIterable {
    /// A required class has no provided counterpart.
    case missingClass
    /// A required feature has no provided counterpart.
    case missingFeature
    /// A required enumeration has no provided counterpart.
    case missingEnumeration
    /// A required enumeration literal has no provided counterpart.
    case missingLiteral
    /// A required attribute corresponds to a provided reference, or the reverse.
    case featureKindMismatch
    /// The provided feature type does not conform to the required one in the direction of use.
    case featureTypeMismatch
    /// The provided multiplicity does not conform to the required one in the direction of use.
    case multiplicityMismatch
    /// The provided feature does not keep the required ordering.
    case orderingMismatch
    /// The provided feature does not keep the required uniqueness.
    case uniquenessMismatch
    /// Containment differs between the required and provided feature.
    case containmentMismatch
    /// The opposite of the provided feature does not correspond to the required one.
    case oppositeMismatch
    /// A written feature cannot be set in the provided metamodel.
    case featureNotChangeable
    /// An instantiated class is abstract or an interface in the provided metamodel.
    case abstractInstantiation
    /// A provided class is abstract although the required class is concrete.
    case abstractnessMismatch
    /// A required subclass relation does not hold in the provided metamodel.
    case supertypeNotPreserved
    /// The provided metamodel has a class without a required counterpart.
    case unexpectedClass
    /// The provided metamodel has a feature without a required counterpart.
    case unexpectedFeature
    /// The provided enumeration has a literal without a required counterpart.
    case unexpectedLiteral
    /// The provided metamodel has an enumeration without a required counterpart.
    case unexpectedEnumeration
    /// A required abstract class is absent because the provided metamodel flattened it into its subclasses.
    case flattenedClass
    /// A mandatory provided feature of an instantiated class is never written.
    case mandatoryFeatureNotSet
    /// A mandatory provided feature has no required counterpart.
    case unmatchedMandatoryFeature
    /// A renaming was given for an isomorphic relation, which admits none, and was not applied.
    case renamingIgnored
    /// Partial subtyping was requested without a footprint.
    case missingFootprint
    /// A required metamodel has no provided counterpart.
    case missingMetamodel
}

/// A rule of the subtyping relation, with the work it follows.
///
/// Each rule names the definition it follows in the published work on model
/// typing. Where the default ``MatchingSemantics/accessRefined`` semantics
/// goes beyond that work, ``citation`` says so with the word "Extension".
/// The bibliographic references are:
///
/// - Steel and Jézéquel, [On model typing](https://doi.org/10.1007/s10270-006-0036-6),
///   Software and Systems Modeling 6(4), pp. 401-413, 2007.
/// - Guy, Combemale, Derrien, Steel and Jézéquel,
///   [On model subtyping](https://doi.org/10.1007/978-3-642-31491-9_30), ECMFA 2012, LNCS 7349,
///   pp. 400-415.
/// - Jeanneret, Glinz and Baudry,
///   [Estimating footprints of model operations](https://doi.org/10.1145/1985793.1985875),
///   ICSE 2011, pp. 601-610.
/// - Degueule, Combemale, Blouin, Barais and Jézéquel,
///   [Melange: a meta-language for modular and reusable development of DSLs](https://doi.org/10.1145/2814251.2814252),
///   SLE 2015, pp. 25-36.
public enum SubtypingRule: String, Sendable, Hashable, Codable, CaseIterable {
    /// Every required object type needs a provided object type of the (renamed) same name.
    case objectTypeCorrespondence
    /// Every required property needs a provided property of the (renamed) same name and kind.
    case propertyCorrespondence
    /// Property types match as the semantics prescribes: covariantly, by class
    /// or read-only subclass, or by the direction of use (an extension).
    case propertyTypeVariance
    /// Multiplicities match as the semantics prescribes: by multi-valuedness and
    /// mandatoriness, by equal bounds, or by the direction of use (an extension).
    case multiplicityVariance
    /// Many-valued properties keep the uniqueness, and with the extension the ordering, that matching demands.
    case collectionSemantics
    /// Composition and opposites must correspond.
    case containmentAndOpposites
    /// Abstract provided classes and read-only provided properties need required counterparts of the same kind.
    case instantiationAndChangeability
    /// Every mandatory provided feature needs a required counterpart.
    case mandatoryFeatureCorrespondence
    /// Required subclass relations must hold among the provided classes (an extension).
    case inheritancePreservation
    /// Isomorphic subtyping relates classes and features by equal names, admitting additions but no adaptation.
    case isomorphicStructure
    /// Non-isomorphic subtyping admits adaptations: renaming, and as extensions flattening and numeric widening.
    case nonIsomorphicAdaptation
    /// Partial subtyping checks only the part of the required model type that the module needs.
    case partialFootprint
    /// Enumeration literals must correspond (an extension).
    case enumerationLiterals
    /// A module that creates objects must write their mandatory features (an extension).
    case outputConformance

    /// Whether the rule as a whole goes beyond the cited publications.
    ///
    /// Rules for which this is `false` follow a published definition, but may
    /// still be refined by the default ``MatchingSemantics/accessRefined``
    /// semantics, as their ``citation`` states.
    public var isExtension: Bool {
        switch self {
        case .inheritancePreservation, .enumerationLiterals, .outputConformance: return true
        default: return false
        }
    }

    /// The publications the rule follows, with section, definition and page, and where it extends them.
    public var citation: String {
        switch self {
        case .objectTypeCorrespondence:
            return "Steel & Jézéquel 2007, Sect. 3.4, p. 406 and rule ModelTypeMatch, Fig. 11, p. 409 "
                + "(a same-named matching object type for each required one); "
                + "Guy et al. 2012, Def. 3 (1), p. 406 and Def. 4, p. 407"
        case .propertyCorrespondence:
            return "Steel & Jézéquel 2007, rule ObjTypeMatch, Fig. 10, p. 408 (every required property occurs in the "
                + "matching type); Guy et al. 2012, Def. 3 (4, 4.1), p. 406 (found in the class or a superclass)"
        case .propertyTypeVariance:
            return "Steel & Jézéquel 2007, rule PropMatch, Fig. 10, p. 408 (property types match covariantly); "
                + "Guy et al. 2012, Def. 3 (4.4), p. 406 (the matching class, or a subclass for a read-only property). "
                + "Extension (access-refined semantics): covariant when read, contravariant when written, invariant "
                + "when both, splitting the accessor and mutator pair of Steel & Jézéquel 2007, Sect. 3.2, p. 405"
        case .multiplicityVariance:
            return "Steel & Jézéquel 2007, rule PropMatch, Fig. 10, p. 408 and Sect. 4.3, p. 409 (equal "
                + "multi-valuedness; a mandatory required property needs a mandatory provided one); "
                + "Guy et al. 2012, Def. 3 (4.5, 4.6), p. 406 (equal bounds) and Sect. 3.2, p. 404. "
                + "Extension (access-refined semantics): bounds narrow when read and widen when written"
        case .collectionSemantics:
            return "Guy et al. 2012, Def. 3 (4.8), p. 406 (equal uniqueness; ordering is not compared); "
                + "Steel & Jézéquel 2007, Sect. 3.3, p. 406 leaves both open. "
                + "Extension (access-refined semantics): ordering and uniqueness by direction of use"
        case .containmentAndOpposites:
            return "Guy et al. 2012, Def. 3 (4.3, 4.7), p. 406 (equal composition; a required opposite needs the "
                + "same provided opposite); not part of Steel & Jézéquel 2007, Fig. 10. "
                + "Extension (access-refined semantics): severity by direction of use"
        case .instantiationAndChangeability:
            return "Guy et al. 2012, Def. 3 (2, 4.2), p. 406 (a provided abstract class or read-only property needs "
                + "an abstract or read-only required counterpart). Extension (access-refined semantics): checked "
                + "only for instantiated classes and written features; derived features count as read-only"
        case .mandatoryFeatureCorrespondence:
            return "Guy et al. 2012, Def. 3 (5), p. 407 and Sect. 4.1, p. 406 (every mandatory provided property "
                + "needs a required counterpart, so that manipulations can instantiate the class). "
                + "Extension (access-refined semantics): a warning, and only for instantiated classes"
        case .inheritancePreservation:
            return "Extension: neither Steel & Jézéquel 2007 (rule ObjTypeMatch, Fig. 10, p. 408 ignores "
                + "superclasses) nor Guy et al. 2012 (Def. 3, p. 406 uses superclasses only to find inherited "
                + "features) require required subclass relations to hold among the provided classes"
        case .isomorphicStructure:
            return "Guy et al. 2012, Sect. 4.1, p. 406, Def. 4, p. 407 and Def. 11, p. 410 (isomorphic subtyping is "
                + "model type matching, a subgraph isomorphism with equal names: additions are admitted, "
                + "adaptations are not)"
        case .nonIsomorphicAdaptation:
            return "Guy et al. 2012, Sect. 4.2 and Def. 5, 6 and 13, pp. 407-410 (subtyping through a bidirectional "
                + "model adaptation); Degueule et al., Melange, SLE 2015, Sect. 5.2.1, p. 34 (renaming). Extension: flattening "
                + "of abstract classes and numeric widening"
        case .partialFootprint:
            return "Guy et al. 2012, Sect. 4.4 and Def. 8, 9, 10, 12 and 14, pp. 408-410 (partial subtyping against "
                + "the effective model type); Jeanneret, Glinz & Baudry 2011, Sect. 4.2, p. 604 (static metamodel "
                + "footprint); Degueule et al., Melange, SLE 2015, Sect. 3.3.3, pp. 29-30 (slicing). Extension (access-refined "
                + "semantics): each footprint element is checked in its recorded direction of use"
        case .enumerationLiterals:
            return "Extension: neither publication defines matching for enumerations (Guy et al. 2012, Fig. 1, "
                + "p. 403 has data types only). The published semantics treat an enumeration as a data type and "
                + "demand equal literals; the access-refined semantics demand literal inclusion by direction of use"
        case .outputConformance:
            return "Extension of Guy et al. 2012, Def. 3 (5), p. 407: a mandatory feature of a class that the module "
                + "instantiates must be written by the module"
        }
    }
}

/// The metamodel element a diagnostic is about.
public struct ElementPath: Sendable, Hashable, Codable, Comparable, CustomStringConvertible {
    /// The name of the metamodel, as the module refers to it.
    public let metamodel: String
    /// The name of the classifier (class or enumeration), in required terms.
    public let classifier: String
    /// The name of the feature or literal, in required terms, if the diagnostic is about one.
    public let member: String?

    /// Creates an element path.
    ///
    /// - Parameters:
    ///   - metamodel: The metamodel name.
    ///   - classifier: The classifier name.
    ///   - member: The feature or literal name, if any (default: `nil`).
    public init(metamodel: String, classifier: String, member: String? = nil) {
        self.metamodel = metamodel
        self.classifier = classifier
        self.member = member
    }

    /// The path written as `metamodel!Classifier.member`.
    public var description: String {
        let prefix = metamodel.isEmpty ? "" : metamodel + ModelTypingVocabulary.atlTypeSeparator
        return prefix + classifier + (member.map { ModelTypingVocabulary.featureSeparator + $0 } ?? "")
    }

    /// Orders paths by metamodel, classifier and member.
    ///
    /// - Parameters:
    ///   - lhs: The first path.
    ///   - rhs: The second path.
    /// - Returns: `true` if `lhs` sorts before `rhs`.
    public static func < (lhs: ElementPath, rhs: ElementPath) -> Bool {
        (lhs.metamodel, lhs.classifier, lhs.member ?? "") < (rhs.metamodel, rhs.classifier, rhs.member ?? "")
    }
}

/// A finding of a subtyping check.
public struct TypingDiagnostic: Sendable, Hashable, Codable, CustomStringConvertible {
    /// How serious the finding is.
    public let severity: TypingSeverity
    /// The stable code of the finding.
    public let code: TypingDiagnosticCode
    /// The subtyping rule the finding is based on.
    public let rule: SubtypingRule
    /// The element the finding is about.
    public let element: ElementPath
    /// A description of the finding that names the elements involved.
    public let message: String

    /// Creates a diagnostic.
    ///
    /// - Parameters:
    ///   - severity: How serious the finding is.
    ///   - code: The stable code.
    ///   - rule: The rule the finding is based on.
    ///   - element: The element the finding is about.
    ///   - message: A description that names the elements involved.
    public init(
        severity: TypingSeverity, code: TypingDiagnosticCode, rule: SubtypingRule, element: ElementPath,
        message: String
    ) {
        self.severity = severity
        self.code = code
        self.rule = rule
        self.element = element
        self.message = message
    }

    /// The diagnostic as one line of text.
    public var description: String { "\(severity.rawValue): \(element): \(message) [\(code.rawValue)]" }
}
