//
//  ModelTypeChecker.swift
//  ModelTyping
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

/// The subtyping relation a check decides.
///
/// The modes follow the two criteria of [Guy et al.](https://doi.org/10.1007/978-3-642-31491-9_30) (2012, Sect. 4.5,
/// pp. 409-410): whether the whole required model type or only the part a
/// module needs is considered (total or partial), and whether classes and
/// features must correspond by equal names (isomorphic) or may correspond
/// through an adaptation such as a renaming (non-isomorphic). In every mode
/// the provided model type may contain classes, optional features and
/// enumerations that the required one lacks, since model type matching is a
/// subgraph isomorphism (Guy et al. 2012, Def. 4, p. 407).
public enum SubtypingMode: String, Sendable, Hashable, Codable, CaseIterable {
    /// Total isomorphic subtyping (Guy et al. 2012, Def. 11, p. 410): every
    /// required class and feature must match a provided one of the same name.
    case totalIsomorphic
    /// Total non-isomorphic subtyping (Guy et al. 2012, Def. 13, p. 410):
    /// every required element must match a provided element after adaptation.
    /// The adaptations are renaming and, as extensions, flattening abstract
    /// classes into their subclasses and optional numeric widening.
    case totalNonIsomorphic
    /// Partial isomorphic subtyping (Guy et al. 2012, Def. 12, p. 410): only
    /// the part of the required model type that the module needs must match,
    /// by equal names.
    case partialIsomorphic
    /// Partial non-isomorphic subtyping (Guy et al. 2012, Def. 14, p. 410):
    /// only the part of the required model type that the module needs must
    /// match, after renaming.
    case partial

    /// Whether the mode admits no adaptation, so that names must be equal.
    public var isIsomorphic: Bool { self == .totalIsomorphic || self == .partialIsomorphic }

    /// Whether the mode considers only the part of the required model type that the module needs.
    public var isPartial: Bool { self == .partialIsomorphic || self == .partial }
}

/// The definition of class and property matching that a check applies.
///
/// The two published definitions decide substitutability for every possible
/// manipulation of a model, independently of how a module accesses it. The
/// access-refined semantics is an extension: it takes into account whether
/// each element is read, written or instantiated, as recorded by the role of
/// a metamodel or by the footprint of a module, and accepts every provided
/// metamodel that is safe for those uses. It coincides with MOF class
/// matching for elements that are both read and written, apart from the
/// additional extension rules for ordering, derived features, inheritance and
/// enumeration literals.
public enum MatchingSemantics: String, Sendable, Hashable, Codable, CaseIterable {
    /// Object type matching as defined by [Steel and Jézéquel](https://doi.org/10.1007/s10270-006-0036-6) (2007, rules
    /// PropMatch, ObjTypeMatch and ModelTypeMatch, Fig. 10 and 11,
    /// pp. 408-409).
    ///
    /// Property types match covariantly; a many-valued property matches only
    /// a many-valued one; a mandatory required property needs a mandatory
    /// provided one, while an optional required property may be provided as
    /// mandatory. Ordering, uniqueness, composition, opposites, abstractness
    /// and changeability are not compared.
    case objectTypeMatching
    /// MOF class matching as defined by Guy et al. (2012, Def. 3, pp. 406-407).
    ///
    /// Property types must be the matching class, or a subclass of it for a
    /// read-only required property; bounds, uniqueness and composition must be
    /// equal; a required opposite needs the same provided opposite; a provided
    /// abstract class or read-only property needs an abstract or read-only
    /// required counterpart; and every mandatory feature that a provided class
    /// declares itself needs a required counterpart.
    case mofClassMatching
    /// Matching by the direction of use: an extension of both definitions.
    ///
    /// Property types and multiplicities are covariant when read,
    /// contravariant when written and invariant when both; abstractness
    /// matters only for instantiated classes and changeability only for
    /// written features. The extension also demands kept ordering, preserved
    /// subclass relations and corresponding enumeration literals.
    case accessRefined

    /// Whether the semantics is one of the published definitions rather than the extension.
    public var isPublished: Bool { self != .accessRefined }
}

/// Options that tune a subtyping check.
public struct CheckOptions: Sendable, Hashable {
    /// The renaming from required to provided names, applied only in non-isomorphic modes.
    public var renaming: Renaming
    /// Whether numeric data types may widen in the direction of use (for example `EInt` to `ELong`).
    ///
    /// Widening is an extension. It applies only in non-isomorphic modes, and
    /// only where the semantics gives a single direction of use, which is only
    /// the access-refined semantics. The published definitions do not apply it,
    /// even to a feature that a module only reads: they match a property type
    /// only by the same type or, for classes, by a subclass, define no subtype
    /// relation between data types such as `EInt` and `ELong`, and assume every
    /// possible use of a property. A finding that widening would have resolved
    /// says so.
    public var allowsNumericWidening: Bool
    /// Whether lower bound violations are reported as warnings instead of errors.
    ///
    /// This leniency is an extension that applies only to the access-refined semantics.
    public var lenientLowerBounds: Bool
    /// Whether renaming hints are computed for missing elements.
    public var suggestsRenamings: Bool
    /// The largest edit distance accepted for name hints, or `nil` for one edit per three characters.
    public var maximumHintDistance: Int?
    /// The smallest feature name similarity for a structural class hint.
    public var minimumStructuralSimilarity: Double
    /// The definition of class and property matching to apply.
    public var semantics: MatchingSemantics

    /// Creates options.
    ///
    /// The default semantics is the access-refined extension, because a
    /// module's footprint and metamodel roles record how it uses each element,
    /// and the published definitions, which assume every possible use, would
    /// reject provided metamodels that are safe for those uses. The published
    /// definitions are selected with ``MatchingSemantics/mofClassMatching`` or
    /// ``MatchingSemantics/objectTypeMatching``.
    ///
    /// - Parameters:
    ///   - renaming: The renaming from required to provided names (default: ``Renaming/identity``).
    ///   - allowsNumericWidening: Whether numeric types may widen (default: `false`).
    ///   - lenientLowerBounds: Whether lower bound violations are warnings (default: `false`).
    ///   - suggestsRenamings: Whether hints are computed (default: `true`).
    ///   - maximumHintDistance: The largest edit distance for name hints (default: `nil`).
    ///   - minimumStructuralSimilarity: The smallest similarity for class hints (default: 0.5).
    ///   - semantics: The matching semantics (default: ``MatchingSemantics/accessRefined``).
    public init(
        renaming: Renaming = .identity, allowsNumericWidening: Bool = false, lenientLowerBounds: Bool = false,
        suggestsRenamings: Bool = true, maximumHintDistance: Int? = nil, minimumStructuralSimilarity: Double = 0.5,
        semantics: MatchingSemantics = .accessRefined
    ) {
        self.renaming = renaming
        self.allowsNumericWidening = allowsNumericWidening
        self.lenientLowerBounds = lenientLowerBounds
        self.suggestsRenamings = suggestsRenamings
        self.maximumHintDistance = maximumHintDistance
        self.minimumStructuralSimilarity = minimumStructuralSimilarity
        self.semantics = semantics
    }
}

/// Decides whether provided metamodels can stand in for the required ones.
///
/// The checker implements structural model subtyping in the sense of
/// [Steel and Jézéquel (2007)](https://doi.org/10.1007/s10270-006-0036-6), in the total and
/// partial, isomorphic and non-isomorphic variants of
/// [Guy et al. (2012)](https://doi.org/10.1007/978-3-642-31491-9_30). The required model types
/// are those a module was written against; the provided model types are those of the models it
/// should now run on. The ``CheckOptions/semantics`` select the published
/// matching definitions or the access-refined extension, under which each
/// metamodel is checked in its role: metamodels that are only read are
/// checked covariantly, metamodels that are only written contravariantly, and
/// metamodels that are both read and written invariantly.
public struct ModelTypeChecker: Sendable {
    /// The options of the check.
    public let options: CheckOptions

    /// Creates a checker.
    ///
    /// - Parameter options: The options of the check (default: standard options).
    public init(options: CheckOptions = CheckOptions()) {
        self.options = options
    }

    /// Checks one pair of model types.
    ///
    /// - Parameters:
    ///   - required: The model type the module was written against.
    ///   - provided: The model type of the models the module should run on.
    ///   - mode: The subtyping relation to decide.
    ///   - role: The part the metamodel plays (default: ``MetamodelRole/source``).
    ///   - metamodelName: The name used in diagnostics (default: the first package name).
    ///   - footprint: The footprint, required for the partial modes.
    /// - Returns: The report.
    public func check(
        required: ModelType, provided: ModelType, mode: SubtypingMode, role: MetamodelRole = .source,
        metamodelName: String? = nil, footprint: MetamodelFootprint? = nil
    ) -> CompatibilityReport {
        let name = metamodelName ?? footprint?.metamodelName ?? required.packageNames.first ?? ""
        var wrapped: Footprint?
        if let footprint {
            var renamed = footprint
            if renamed.metamodelName != name {
                renamed = MetamodelFootprint(metamodelName: name, role: footprint.role)
                renamed.classes = footprint.classes
                renamed.features = footprint.features
                renamed.literals = footprint.literals
            }
            wrapped = Footprint(metamodels: [name: renamed])
        }
        return check(
            required: [name: required], provided: [name: provided], mode: mode, roles: [name: role],
            footprint: wrapped)
    }

    /// Checks several metamodels of a module.
    ///
    /// - Parameters:
    ///   - required: The required model types, indexed by metamodel name.
    ///   - provided: The provided model types, indexed by the same names.
    ///   - mode: The subtyping relation to decide.
    ///   - roles: The roles of the metamodels; roles recorded in the footprint take precedence.
    ///   - footprint: The footprint of the module, required for the partial modes.
    /// - Returns: The report, which includes the footprint.
    public func check(
        required: [String: ModelType], provided: [String: ModelType], mode: SubtypingMode,
        roles: [String: MetamodelRole] = [:], footprint: Footprint? = nil
    ) -> CompatibilityReport {
        var diagnostics: [TypingDiagnostic] = []
        var hints: [RenamingHint] = []
        let names = Set(required.keys).union(footprint?.metamodels.keys.map { $0 } ?? [])
        for name in names.sorted() {
            let usage = footprint?.metamodels[name]
            let role = usage?.role ?? roles[name] ?? .source
            let requiredType = required[name] ?? ModelType(packageNames: [name], objectTypes: [:])
            guard let providedType = provided[name] else {
                diagnostics.append(TypingDiagnostic(
                    severity: .error, code: .missingMetamodel, rule: .objectTypeCorrespondence,
                    element: ElementPath(metamodel: name, classifier: "*"),
                    message: "no provided metamodel was given for '\(name)'"))
                continue
            }
            var comparison = MetamodelComparison(
                metamodel: name, required: requiredType, provided: providedType, mode: mode, role: role,
                options: options)
            if mode.isIsomorphic, options.renaming != .identity {
                comparison.report(.note, .renamingIgnored, .isomorphicStructure,
                                  ElementPath(metamodel: name, classifier: "*"),
                                  "isomorphic subtyping admits no renaming; the given renaming was not applied")
            }
            switch (mode.isPartial, usage) {
            case (false, _):
                comparison.checkTotal()
            case (true, nil):
                comparison.report(.error, .missingFootprint, .partialFootprint,
                                  ElementPath(metamodel: name, classifier: "*"),
                                  "partial subtyping needs the footprint of the module")
            case (true, let usage?) where options.semantics.isPublished:
                let effective = EffectiveModelType(of: requiredType, for: usage)
                var restricted = MetamodelComparison(
                    metamodel: name, required: effective.modelType, provided: providedType, mode: mode, role: role,
                    options: options, certainty: effective)
                restricted.diagnostics = comparison.diagnostics
                restricted.checkTotal(reportsAdditions: false)
                restricted.checkClassesOutsideRequiredType(usage, of: requiredType)
                comparison = restricted
            case (true, let usage?):
                comparison.checkPartial(usage)
            }
            diagnostics += comparison.diagnostics
            hints += comparison.hints
        }
        return CompatibilityReport(
            mode: mode, diagnostics: diagnostics.sorted(by: CompatibilityReport.ordering),
            footprint: footprint, renamingHints: hints)
    }
}

/// The comparison of one required and one provided model type.
struct MetamodelComparison {
    /// The metamodel name used in diagnostics.
    let metamodel: String
    /// The model type the module was written against, or the effective part of it.
    let required: ModelType
    /// The model type of the models the module should run on.
    let provided: ModelType
    /// The subtyping relation to decide.
    let mode: SubtypingMode
    /// The part the metamodel plays.
    let role: MetamodelRole
    /// The options of the check.
    let options: CheckOptions
    /// The renaming in effect: the given one in non-isomorphic modes, the identity otherwise.
    let renaming: Renaming
    /// Which elements rest on certain uses, when the required model type is an effective model type.
    let certainty: EffectiveModelType?
    /// The findings so far.
    var diagnostics: [TypingDiagnostic] = []
    /// The renaming hints so far.
    var hints: [RenamingHint] = []
    /// The required classifiers already reported as missing.
    private var reportedMissing: Set<String> = []

    /// Creates a comparison.
    ///
    /// - Parameters:
    ///   - metamodel: The metamodel name used in diagnostics.
    ///   - required: The required model type, or the effective part of it.
    ///   - provided: The provided model type.
    ///   - mode: The subtyping relation to decide.
    ///   - role: The part the metamodel plays.
    ///   - options: The options of the check.
    ///   - certainty: The certainty of the elements of an effective model type (default: `nil`, all certain).
    init(metamodel: String, required: ModelType, provided: ModelType, mode: SubtypingMode, role: MetamodelRole,
         options: CheckOptions, certainty: EffectiveModelType? = nil) {
        self.metamodel = metamodel
        self.required = required
        self.provided = provided
        self.mode = mode
        self.role = role
        self.options = options
        self.renaming = mode.isIsomorphic ? .identity : options.renaming
        self.certainty = certainty
    }

    /// The matching semantics of the check.
    private var semantics: MatchingSemantics { options.semantics }

    // MARK: - Reporting

    /// Records a finding.
    mutating func report(
        _ severity: TypingSeverity, _ code: TypingDiagnosticCode, _ rule: SubtypingRule, _ element: ElementPath,
        _ message: String
    ) {
        let diagnostic = TypingDiagnostic(severity: severity, code: code, rule: rule, element: element, message: message)
        if !diagnostics.contains(diagnostic) { diagnostics.append(diagnostic) }
    }

    /// The path of a required classifier or member.
    private func path(_ classifier: String, _ member: String? = nil) -> ElementPath {
        ElementPath(metamodel: metamodel, classifier: classifier, member: member)
    }

    /// The severity of a violation, downgraded for uses that could only be guessed.
    private func severity(certain: Bool) -> TypingSeverity { certain ? .error : .warning }

    // MARK: - Name mapping

    /// The provided name of a required classifier.
    private func mapped(_ classifier: String) -> String { renaming.providedClassifierName(for: classifier) }

    /// The provided name of a required feature accessed through a required class.
    private func mapped(feature: String, of className: String) -> String {
        var owners = [className]
        if let objectType = required.objectTypes[className] {
            if let declaring = objectType.property(named: feature)?.declaringClassName { owners.append(declaring) }
            owners += objectType.allSuperTypeNames.sorted()
        }
        return renaming.providedMemberName(for: feature, ownedBy: owners)
    }

    /// The provided name of a required literal.
    private func mapped(literal: String, of enumeration: String) -> String {
        renaming.providedMemberName(for: literal, ownedBy: [enumeration])
    }

    /// The provided class names that no required class maps to.
    private var unmatchedProvidedClasses: [String] {
        let matched = Set(required.objectTypes.keys.map(mapped))
        return provided.objectTypes.keys.filter { !matched.contains($0) }.sorted()
    }

    // MARK: - Total checks

    /// Checks every required element.
    ///
    /// Under the published semantics every element is matched as the
    /// definition prescribes; under the access-refined semantics every element
    /// is checked in the access mode of the metamodel's role.
    ///
    /// - Parameter reportsAdditions: Whether provided elements without a required
    ///   counterpart are listed as notes (default: `true`).
    mutating func checkTotal(reportsAdditions: Bool = true) {
        let access = role.assumedAccess
        for name in required.objectTypes.keys.sorted() {
            let objectType = required.objectTypes[name]!
            let certain = certainty?.isCertain(className: name) ?? true
            guard let providedType = provided.objectTypes[mapped(name)] else {
                if !mode.isIsomorphic, isFlattenable(objectType) {
                    report(.warning, .flattenedClass, .nonIsomorphicAdaptation, path(name),
                           "abstract class '\(name)' is absent; its features must be provided by its subclasses")
                    continue
                }
                reportMissingClass(name, certain: certain)
                continue
            }
            let classAccess: AccessMode = access.contains(.instantiate) && objectType.isInstantiable
                ? access : access.subtracting(.instantiate)
            if semantics.isPublished {
                checkPublishedClassFlags(objectType, providedType, certain: certain)
            } else {
                checkClassFlags(objectType, providedType, access: classAccess, certain: certain)
            }
            checkInheritance(objectType, providedType, certain: certain)
            for featureName in objectType.properties.keys.sorted() {
                let featureCertain = certainty?.isCertain(feature: featureName, of: name) ?? true
                if semantics.isPublished {
                    checkFeature(featureName, of: name, access: [.read, .write], certain: featureCertain, footprint: nil)
                    continue
                }
                let property = objectType.properties[featureName]!
                var featureAccess = access.subtracting(.instantiate)
                if !property.isChangeable || property.isDerived { featureAccess.remove(.write) }
                if featureAccess.isEmpty { continue }
                checkFeature(featureName, of: name, access: featureAccess, certain: featureCertain, footprint: nil)
            }
            checkAdditionalFeatures(objectType, providedType, classAccess: classAccess, certain: certain,
                                    reportsAdditions: reportsAdditions)
        }
        if reportsAdditions {
            for extra in unmatchedProvidedClasses {
                reportExtra(.unexpectedClass, path(extra), "provided metamodel adds class '\(extra)'")
            }
        }
        checkEnumerationsTotal(access: access, reportsAdditions: reportsAdditions)
    }

    /// Checks the footprint elements that lie outside the required model type, which no effective model type contains.
    ///
    /// - Parameters:
    ///   - footprint: The footprint of the module.
    ///   - requiredType: The complete required model type.
    mutating func checkClassesOutsideRequiredType(_ footprint: MetamodelFootprint, of requiredType: ModelType) {
        for name in footprint.classNames where requiredType.objectTypes[name] == nil {
            if provided.objectTypes[mapped(name)] == nil {
                reportMissingClass(name, certain: footprint.classes[name]!.isCertain)
            }
        }
        for reference in footprint.featureReferences
        where requiredType.objectTypes[reference.className]?.property(named: reference.featureName) == nil {
            let usage = footprint.features[reference]!
            checkFeature(reference.featureName, of: reference.className, access: usage.access,
                         certain: usage.isCertain, footprint: footprint)
        }
        for literal in footprint.literals.keys.sorted() where requiredType.enumerations[literal.enumerationName] == nil {
            let usage = footprint.literals[literal]!
            guard let providedEnumeration = provided.enumerations[mapped(literal.enumerationName)] else {
                reportMissingEnumeration(literal.enumerationName, certain: usage.isCertain)
                continue
            }
            if !providedEnumeration.literalNames.contains(mapped(literal: literal.literalName, of: literal.enumerationName)) {
                reportMissingLiteral(literal.literalName, of: literal.enumerationName, certain: usage.isCertain)
            }
        }
    }

    /// Reports an element the provided metamodel adds, which every mode admits.
    private mutating func reportExtra(_ code: TypingDiagnosticCode, _ element: ElementPath, _ message: String) {
        report(.note, code, mode.isIsomorphic ? .isomorphicStructure : .nonIsomorphicAdaptation, element, message)
    }

    /// Checks the provided features of a class that no required feature maps to.
    ///
    /// MOF class matching demands a required counterpart for every mandatory
    /// feature the provided class declares itself (Guy et al. 2012, Def. 3,
    /// condition 5). The access-refined semantics warns instead, and only
    /// about mandatory features, including inherited ones, of a class the
    /// module instantiates, since only then must the module set them.
    private mutating func checkAdditionalFeatures(
        _ objectType: ObjectType, _ providedType: ObjectType, classAccess: AccessMode, certain: Bool,
        reportsAdditions: Bool
    ) {
        let name = objectType.name
        let mappedNames = Set(objectType.properties.keys.map { mapped(feature: $0, of: name) })
        var reported: Set<String> = []
        switch semantics {
        case .mofClassMatching:
            for extra in providedType.ownPropertyNames where !mappedNames.contains(extra) {
                guard let property = providedType.properties[extra], property.lowerBound > 0 else { continue }
                report(severity(certain: certain), .unmatchedMandatoryFeature, .mandatoryFeatureCorrespondence,
                       path(name, extra),
                       "provided class '\(providedType.name)' declares mandatory feature '\(extra)' \(property.multiplicityDescription) without a required counterpart")
                reported.insert(extra)
            }
        case .accessRefined where classAccess.contains(.instantiate) && providedType.isInstantiable:
            for featureName in providedType.properties.keys.sorted() where !mappedNames.contains(featureName) {
                let property = providedType.properties[featureName]!
                guard property.lowerBound > 0, property.isChangeable, !property.isDerived,
                    !isContainerReference(property)
                else { continue }
                report(.warning, .unmatchedMandatoryFeature, .mandatoryFeatureCorrespondence, path(name, featureName),
                       "the module creates '\(name)' but cannot set mandatory provided feature '\(featureName)' \(property.multiplicityDescription), which it does not know")
                reported.insert(featureName)
            }
        default:
            break
        }
        guard reportsAdditions else { return }
        for extra in providedType.ownPropertyNames where !mappedNames.contains(extra) && !reported.contains(extra) {
            reportExtra(.unexpectedFeature, path(name, extra), "provided class '\(providedType.name)' adds feature '\(extra)'")
        }
    }

    /// Whether an absent required class can be regarded as flattened into its subclasses.
    ///
    /// Only an abstract class that types no reference can be flattened: it has
    /// no instances of its own and no navigation yields it.
    private func isFlattenable(_ objectType: ObjectType) -> Bool {
        guard !objectType.isInstantiable else { return false }
        let referenced = required.objectTypes.values.contains { owner in
            owner.ownPropertyNames.contains { owner.properties[$0]?.typeName == objectType.name }
        }
        let hasSubclass = required.objectTypes.values.contains { $0.allSuperTypeNames.contains(objectType.name) }
        return !referenced && hasSubclass
    }

    /// Checks the enumerations of the required model type.
    ///
    /// The published semantics treat an enumeration as a data type, which must
    /// be the same on both sides, so the literals must be equal. The
    /// access-refined semantics demand the required literals when values are
    /// written and no unknown provided literals when values are read.
    private mutating func checkEnumerationsTotal(access: AccessMode, reportsAdditions: Bool) {
        let exact = semantics.isPublished
        for name in required.enumerations.keys.sorted() {
            let enumeration = required.enumerations[name]!
            let certain = certainty?.isCertain(enumeration: name) ?? true
            guard let providedEnumeration = provided.enumerations[mapped(name)] else {
                reportMissingEnumeration(name, certain: certain)
                continue
            }
            let requiredLiterals = Set(enumeration.literalNames.map { mapped(literal: $0, of: name) })
            let providedLiterals = Set(providedEnumeration.literalNames)
            if exact || access.isWrite {
                for literal in enumeration.literalNames where !providedLiterals.contains(mapped(literal: literal, of: name)) {
                    reportMissingLiteral(literal, of: name, certain: certain)
                }
            }
            if exact || access.isRead {
                for literal in providedEnumeration.literalNames.sorted() where !requiredLiterals.contains(literal) {
                    report(severity(certain: certain), .unexpectedLiteral, .enumerationLiterals, path(name, literal),
                           "provided enumeration '\(providedEnumeration.name)' has literal '\(literal)', which models may hold but the module does not know")
                }
            }
        }
        guard reportsAdditions else { return }
        let matched = Set(required.enumerations.keys.map(mapped))
        for extra in provided.enumerations.keys.sorted() where !matched.contains(extra) {
            reportExtra(.unexpectedEnumeration, path(extra), "provided metamodel adds enumeration '\(extra)'")
        }
    }

    // MARK: - Partial checks

    /// Checks the elements of a footprint, each in the access mode recorded for it.
    ///
    /// This is the access-refined counterpart of partial subtyping: instead of
    /// matching the effective model type, it checks each footprint element in
    /// the direction in which the module uses it.
    mutating func checkPartial(_ footprint: MetamodelFootprint) {
        for name in footprint.classNames {
            let usage = footprint.classes[name]!
            guard let providedType = provided.objectTypes[mapped(name)] else {
                reportMissingClass(name, certain: usage.isCertain)
                continue
            }
            if let objectType = required.objectTypes[name] {
                checkClassFlags(objectType, providedType, access: usage.access, certain: usage.isCertain)
            } else if usage.access.contains(.instantiate), !providedType.isInstantiable {
                report(severity(certain: usage.isCertain), .abstractInstantiation, .instantiationAndChangeability, path(name),
                       "the module creates instances of '\(name)', but provided class '\(providedType.name)' is abstract")
            }
        }
        for reference in footprint.featureReferences {
            let usage = footprint.features[reference]!
            checkFeature(reference.featureName, of: reference.className, access: usage.access,
                         certain: usage.isCertain, footprint: footprint)
        }
        checkLiteralsPartial(footprint)
        checkFootprintInheritance(footprint)
        checkMandatoryFeatures(footprint)
    }

    /// Checks the literals and the enumeration-typed attributes a footprint reads.
    private mutating func checkLiteralsPartial(_ footprint: MetamodelFootprint) {
        for literal in footprint.literals.keys.sorted() {
            let usage = footprint.literals[literal]!
            guard let providedEnumeration = provided.enumerations[mapped(literal.enumerationName)] else {
                reportMissingEnumeration(literal.enumerationName, certain: usage.isCertain)
                continue
            }
            if !providedEnumeration.literalNames.contains(mapped(literal: literal.literalName, of: literal.enumerationName)) {
                reportMissingLiteral(literal.literalName, of: literal.enumerationName, certain: usage.isCertain)
            }
        }
        for reference in footprint.featureReferences where footprint.features[reference]!.access.isRead {
            guard let property = required.objectTypes[reference.className]?.property(named: reference.featureName),
                property.typeKind == .enumeration,
                let requiredEnumeration = required.enumerations[property.typeName],
                let providedEnumeration = provided.enumerations[mapped(property.typeName)]
            else { continue }
            let known = Set(requiredEnumeration.literalNames.map { mapped(literal: $0, of: property.typeName) })
            for literal in providedEnumeration.literalNames.sorted() where !known.contains(literal) {
                report(.warning, .unexpectedLiteral, .enumerationLiterals, path(property.typeName, literal),
                       "'\(reference)' is read, and models may hold literal '\(literal)' of '\(providedEnumeration.name)', which the module does not know")
            }
        }
    }

    /// Checks that subclass relations among footprint classes still hold.
    private mutating func checkFootprintInheritance(_ footprint: MetamodelFootprint) {
        let classes = footprint.classNames
        for sub in classes {
            for sup in classes where sub != sup && required.conforms(sub, to: sup) {
                let providedSub = mapped(sub), providedSup = mapped(sup)
                guard provided.objectTypes[providedSub] != nil, provided.objectTypes[providedSup] != nil else { continue }
                if !provided.conforms(providedSub, to: providedSup) {
                    report(.warning, .supertypeNotPreserved, .inheritancePreservation, path(sub),
                           "the module uses '\(sub)' as a kind of '\(sup)', but provided '\(providedSub)' is not a subclass of '\(providedSup)'")
                }
            }
        }
    }

    /// Checks that every mandatory provided feature of an instantiated class is written.
    private mutating func checkMandatoryFeatures(_ footprint: MetamodelFootprint) {
        for name in footprint.classNames where footprint.classes[name]!.access.contains(.instantiate) {
            guard let providedType = provided.objectTypes[mapped(name)] else { continue }
            var written: Set<String> = []
            for reference in footprint.featureReferences where footprint.features[reference]!.access.contains(.write) {
                if reference.className == name || required.conforms(name, to: reference.className)
                    || required.objectTypes[name] == nil {
                    written.insert(mapped(feature: reference.featureName, of: reference.className))
                }
            }
            for featureName in providedType.properties.keys.sorted() {
                let property = providedType.properties[featureName]!
                guard property.lowerBound > 0, property.isChangeable, !property.isDerived,
                    !written.contains(featureName), !isContainerReference(property)
                else { continue }
                report(.warning, .mandatoryFeatureNotSet, .outputConformance, path(name, featureName),
                       "the module creates '\(name)' but never sets mandatory provided feature '\(featureName)' \(property.multiplicityDescription)")
            }
        }
    }

    /// Whether a provided reference is the container side of a containment.
    private func isContainerReference(_ property: PropertyType) -> Bool {
        guard property.kind == .reference, let opposite = property.oppositeName else { return false }
        return provided.objectTypes[property.typeName]?.property(named: opposite)?.isContainment ?? false
    }

    // MARK: - Shared class checks

    /// Reports a missing class with renaming hints.
    private mutating func reportMissingClass(_ name: String, certain: Bool) {
        guard reportedMissing.insert(name).inserted else { return }
        let renamed = mapped(name)
        report(severity(certain: certain), .missingClass, .objectTypeCorrespondence, path(name),
               "provided metamodel has no class '\(renamed)'" + (certain ? "" : " (use inferred without static type)"))
        guard options.suggestsRenamings else { return }
        let candidates = unmatchedProvidedClasses
        let nearMisses = NameSimilarity.nearMisses(of: renamed, among: candidates, maximumDistance: options.maximumHintDistance)
        for miss in nearMisses {
            hints.append(RenamingHint(kind: .classifier, metamodel: metamodel, requiredName: name,
                                      suggestedName: miss.name, reason: miss.reason, distance: miss.distance))
        }
        guard nearMisses.isEmpty, let objectType = required.objectTypes[name] else { return }
        let requiredFeatures = Set(objectType.properties.keys)
        let similar = candidates.compactMap { candidate -> (String, Double)? in
            guard let providedType = provided.objectTypes[candidate] else { return nil }
            let similarity = NameSimilarity.jaccard(requiredFeatures, Set(providedType.properties.keys))
            return similarity >= options.minimumStructuralSimilarity ? (candidate, similarity) : nil
        }.sorted { ($1.1, $0.0) < ($0.1, $1.0) }
        for (candidate, _) in similar {
            hints.append(RenamingHint(kind: .classifier, metamodel: metamodel, requiredName: name,
                                      suggestedName: candidate, reason: .similarStructure,
                                      distance: NameSimilarity.editDistance(name, candidate)))
        }
    }

    /// Reports a missing enumeration with renaming hints.
    private mutating func reportMissingEnumeration(_ name: String, certain: Bool) {
        guard reportedMissing.insert(name).inserted else { return }
        report(severity(certain: certain), .missingEnumeration, .objectTypeCorrespondence, path(name),
               "provided metamodel has no enumeration '\(mapped(name))'")
        guard options.suggestsRenamings else { return }
        let matched = Set(required.enumerations.keys.map(mapped))
        let candidates = provided.enumerations.keys.filter { !matched.contains($0) }.sorted()
        for miss in NameSimilarity.nearMisses(of: mapped(name), among: candidates, maximumDistance: options.maximumHintDistance) {
            hints.append(RenamingHint(kind: .classifier, metamodel: metamodel, requiredName: name,
                                      suggestedName: miss.name, reason: miss.reason, distance: miss.distance))
        }
    }

    /// Reports a missing literal with renaming hints.
    private mutating func reportMissingLiteral(_ literal: String, of enumeration: String, certain: Bool) {
        let renamed = mapped(literal: literal, of: enumeration)
        report(severity(certain: certain), .missingLiteral, .enumerationLiterals, path(enumeration, literal),
               "provided enumeration '\(mapped(enumeration))' has no literal '\(renamed)'")
        guard options.suggestsRenamings, let providedEnumeration = provided.enumerations[mapped(enumeration)] else { return }
        let known = Set((required.enumerations[enumeration]?.literalNames ?? []).map { mapped(literal: $0, of: enumeration) })
        let candidates = providedEnumeration.literalNames.filter { !known.contains($0) }
        let nearMisses = NameSimilarity.nearMisses(of: renamed, among: candidates, maximumDistance: options.maximumHintDistance)
        for miss in nearMisses {
            appendHint(RenamingHint(kind: .literal, metamodel: metamodel, owner: enumeration, requiredName: literal,
                                    suggestedName: miss.name, reason: miss.reason, distance: miss.distance))
        }
        if nearMisses.isEmpty, candidates.count == 1 {
            appendHint(RenamingHint(kind: .literal, metamodel: metamodel, owner: enumeration, requiredName: literal,
                                    suggestedName: candidates[0], reason: .uniqueStructuralCandidate,
                                    distance: NameSimilarity.editDistance(literal, candidates[0])))
        }
    }

    /// Adds a hint once.
    private mutating func appendHint(_ hint: RenamingHint) {
        if !hints.contains(hint) { hints.append(hint) }
    }

    /// Checks instantiability of a class pair under the access-refined semantics.
    private mutating func checkClassFlags(_ requiredType: ObjectType, _ providedType: ObjectType, access: AccessMode, certain: Bool) {
        let name = requiredType.name
        if access.contains(.instantiate), !providedType.isInstantiable {
            report(severity(certain: certain), .abstractInstantiation, .instantiationAndChangeability, path(name),
                   "the module creates instances of '\(name)', but provided class '\(providedType.name)' is "
                    + (providedType.isInterface ? "an interface" : "abstract"))
        }
    }

    /// Checks abstractness of a class pair under the published semantics.
    ///
    /// MOF class matching demands that a provided abstract class match only an
    /// abstract required class (Guy et al. 2012, Def. 3, condition 2); object
    /// type matching does not compare abstractness.
    private mutating func checkPublishedClassFlags(_ requiredType: ObjectType, _ providedType: ObjectType, certain: Bool) {
        guard semantics == .mofClassMatching, !providedType.isInstantiable, requiredType.isInstantiable else { return }
        report(severity(certain: certain), .abstractnessMismatch, .instantiationAndChangeability, path(requiredType.name),
               "provided '\(providedType.name)' is \(providedType.isInterface ? "an interface" : "abstract"), but required '\(requiredType.name)' is concrete")
    }

    /// Checks that the required subclass relations of a class hold in the provided metamodel.
    ///
    /// The rule is an extension; under the published semantics a violation is
    /// a warning, so that the verdict is the published one.
    private mutating func checkInheritance(_ requiredType: ObjectType, _ providedType: ObjectType, certain: Bool) {
        let name = requiredType.name
        let failure: TypingSeverity = semantics.isPublished ? .warning : severity(certain: certain)
        for superName in requiredType.allSuperTypeNames.sorted() where required.objectTypes[superName] != nil {
            let providedSuper = mapped(superName)
            guard provided.objectTypes[providedSuper] != nil else { continue }
            if !provided.conforms(providedType.name, to: providedSuper) {
                report(failure, .supertypeNotPreserved, .inheritancePreservation, path(name),
                       "'\(name)' is a subclass of '\(superName)', but provided '\(providedType.name)' is not a subclass of '\(providedSuper)'")
            }
        }
    }

    // MARK: - Feature checks

    /// Checks one required feature, accessed through a class, against the provided metamodel.
    private mutating func checkFeature(
        _ featureName: String, of className: String, access: AccessMode, certain: Bool,
        footprint: MetamodelFootprint?
    ) {
        let element = path(className, featureName)
        let providedClassName = mapped(className)
        guard let providedType = provided.objectTypes[providedClassName] else {
            reportMissingClass(className, certain: certain)
            return
        }
        let providedName = mapped(feature: featureName, of: className)
        guard let providedProperty = providedType.property(named: providedName) else {
            let use = semantics.isPublished ? "" : " (\(access.label))"
            report(severity(certain: certain), .missingFeature, .propertyCorrespondence, element,
                   "provided class '\(providedClassName)' has no feature '\(providedName)'\(use)"
                    + (certain ? "" : " (use inferred without static type)"))
            suggestFeatures(for: featureName, of: className, in: providedType)
            return
        }
        guard let requiredProperty = required.objectTypes[className]?.property(named: featureName) else { return }
        if semantics.isPublished {
            comparePublished(requiredProperty, providedProperty, certain: certain, element: element)
        } else {
            compare(requiredProperty, providedProperty, access: access, certain: certain, element: element, footprint: footprint)
        }
    }

    /// Adds renaming hints for a missing feature.
    private mutating func suggestFeatures(for featureName: String, of className: String, in providedType: ObjectType) {
        guard options.suggestsRenamings else { return }
        let requiredType = required.objectTypes[className]
        let matched = Set((requiredType?.properties.keys.map { $0 } ?? []).map { mapped(feature: $0, of: className) })
        let candidates = providedType.properties.keys.filter { !matched.contains($0) }.sorted()
        let renamed = mapped(feature: featureName, of: className)
        let nearMisses = NameSimilarity.nearMisses(of: renamed, among: candidates, maximumDistance: options.maximumHintDistance)
        for miss in nearMisses {
            appendHint(RenamingHint(kind: .feature, metamodel: metamodel, owner: className, requiredName: featureName,
                                    suggestedName: miss.name, reason: miss.reason, distance: miss.distance))
        }
        guard nearMisses.isEmpty, let property = requiredType?.property(named: featureName) else { return }
        let structural = candidates.filter { candidate in
            guard let other = providedType.property(named: candidate), other.kind == property.kind else { return false }
            return typesCorrespond(property, other)
        }
        if structural.count == 1 {
            appendHint(RenamingHint(kind: .feature, metamodel: metamodel, owner: className, requiredName: featureName,
                                    suggestedName: structural[0], reason: .uniqueStructuralCandidate,
                                    distance: NameSimilarity.editDistance(featureName, structural[0])))
        }
    }

    /// Whether two properties are typed by corresponding classifiers, ignoring variance.
    private func typesCorrespond(_ requiredProperty: PropertyType, _ providedProperty: PropertyType) -> Bool {
        switch requiredProperty.typeKind {
        case .objectType, .enumeration:
            return mapped(requiredProperty.typeName) == providedProperty.typeName
        case .dataType:
            return canonical(requiredProperty) == canonical(providedProperty)
        }
    }

    /// The canonical data type category of an attribute, if it has a known one.
    private func canonical(_ property: PropertyType) -> CanonicalDataType? {
        property.instanceClassName.flatMap { ModelTypingVocabulary.canonicalDataTypes[$0] }
            ?? ModelTypingVocabulary.canonicalDataTypes[property.typeName]
    }

    /// Whether two data typed properties have the same data type.
    ///
    /// Data types are the same if they share a canonical category, or, when
    /// either has none, if their (renamed) names are equal.
    private func sameDataType(_ requiredProperty: PropertyType, _ providedProperty: PropertyType) -> Bool {
        if let requiredCanonical = canonical(requiredProperty), let providedCanonical = canonical(providedProperty) {
            return requiredCanonical == providedCanonical
        }
        return mapped(requiredProperty.typeName) == providedProperty.typeName
    }

    // MARK: - Published property matching

    /// Compares a required and a provided property as a published definition prescribes.
    ///
    /// Object type matching (Steel and Jézéquel 2007, rule PropMatch) compares
    /// property types covariantly, multi-valuedness for equality and
    /// mandatoriness by implication. MOF class matching (Guy et al. 2012,
    /// Def. 3, conditions 4.2 to 4.8) compares types by class or, for a
    /// read-only property, by subclass, and demands equal bounds, uniqueness
    /// and composition, a corresponding opposite and kept changeability.
    private mutating func comparePublished(
        _ requiredProperty: PropertyType, _ providedProperty: PropertyType, certain: Bool, element: ElementPath
    ) {
        let failure = severity(certain: certain)
        guard requiredProperty.kind == providedProperty.kind else {
            report(failure, .featureKindMismatch, .propertyCorrespondence, element,
                   "required \(requiredProperty.kind.rawValue) corresponds to a provided \(providedProperty.kind.rawValue)")
            return
        }
        let mof = semantics == .mofClassMatching
        let providedName = providedProperty.typeName
        switch requiredProperty.typeKind {
        case .objectType:
            let expected = mapped(requiredProperty.typeName)
            let isSubclass = provided.conforms(providedName, to: expected)
            let matches = mof ? isSubclass && (providedName == expected || !requiredProperty.isChangeable) : isSubclass
            if !matches {
                report(failure, .featureTypeMismatch, .propertyTypeVariance, element, mof
                    ? "provided type '\(providedName)' is neither required type '\(expected)' nor, for a read-only property, a subclass of it"
                    : "provided type '\(providedName)' does not match required type '\(expected)'")
            }
        case .enumeration:
            if providedProperty.typeKind != .enumeration || mapped(requiredProperty.typeName) != providedName {
                report(failure, .featureTypeMismatch, .propertyTypeVariance, element,
                       "provided type '\(providedName)' is not required enumeration '\(mapped(requiredProperty.typeName))'")
            }
        case .dataType:
            if providedProperty.typeKind != .dataType || !sameDataType(requiredProperty, providedProperty) {
                report(failure, .featureTypeMismatch, .propertyTypeVariance, element,
                       "provided data type '\(providedName)' is not required data type '\(requiredProperty.typeName)'"
                        + (ignoresRequestedWidening(requiredProperty, providedProperty)
                            ? " (numeric widening applies only to the access-refined semantics)" : ""))
            }
        }
        let description = "required \(requiredProperty.multiplicityDescription), provided \(providedProperty.multiplicityDescription)"
        guard mof else {
            if requiredProperty.isMany != providedProperty.isMany {
                report(failure, .multiplicityMismatch, .multiplicityVariance, element,
                       "single and multi-valued properties do not match: " + description)
            }
            if requiredProperty.lowerBound > 0, providedProperty.lowerBound == 0 {
                report(failure, .multiplicityMismatch, .multiplicityVariance, element,
                       "a mandatory required property is provided as optional: " + description)
            }
            return
        }
        if requiredProperty.effectiveUpperBound != providedProperty.effectiveUpperBound {
            report(failure, .multiplicityMismatch, .multiplicityVariance, element, "upper bounds differ: " + description)
        }
        if requiredProperty.lowerBound != providedProperty.lowerBound {
            report(failure, .multiplicityMismatch, .multiplicityVariance, element, "lower bounds differ: " + description)
        }
        if requiredProperty.isMany, providedProperty.isMany, requiredProperty.isUnique != providedProperty.isUnique {
            report(failure, .uniquenessMismatch, .collectionSemantics, element,
                   "required \(requiredProperty.isUnique ? "" : "non-")unique values are provided as \(providedProperty.isUnique ? "" : "non-")unique")
        }
        if requiredProperty.isContainment != providedProperty.isContainment {
            report(failure, .containmentMismatch, .containmentAndOpposites, element,
                   "required \(requiredProperty.isContainment ? "containment" : "non-containment") reference is provided as \(providedProperty.isContainment ? "containment" : "non-containment")")
        }
        if let opposite = requiredProperty.oppositeName {
            let expected = mapped(feature: opposite, of: requiredProperty.typeName)
            if providedProperty.oppositeName != expected {
                report(failure, .oppositeMismatch, .containmentAndOpposites, element,
                       "required opposite '\(expected)' is provided as \(providedProperty.oppositeName.map { "'\($0)'" } ?? "none")")
            }
        }
        if !providedProperty.isChangeable, requiredProperty.isChangeable {
            report(failure, .featureNotChangeable, .instantiationAndChangeability, element,
                   "provided '\(providedProperty.name)' is read-only, but the required property is changeable")
        }
    }

    /// Whether numeric widening was asked for between two data types that it could relate,
    /// although the published semantics do not apply it.
    ///
    /// The published definitions match a property type only by the same type or, for
    /// classes, by a subclass; they define no subtype relation between data types, so `EInt`
    /// does not match `ELong`. They also assume every possible use of a property, while
    /// widening is safe only in one direction of use, which only the access-refined semantics
    /// records.
    private func ignoresRequestedWidening(_ requiredProperty: PropertyType, _ providedProperty: PropertyType) -> Bool {
        guard options.allowsNumericWidening, let requiredCanonical = canonical(requiredProperty),
            let providedCanonical = canonical(providedProperty)
        else {
            return false
        }
        return requiredCanonical.widens(to: providedCanonical) || providedCanonical.widens(to: requiredCanonical)
    }

    // MARK: - Access-refined property matching

    /// Compares a required and a provided property in the direction of use.
    private mutating func compare(
        _ requiredProperty: PropertyType, _ providedProperty: PropertyType, access: AccessMode, certain: Bool,
        element: ElementPath, footprint: MetamodelFootprint?
    ) {
        let reads = access.isRead
        let writes = access.contains(.write)
        let failure = severity(certain: certain)
        guard requiredProperty.kind == providedProperty.kind else {
            report(failure, .featureKindMismatch, .propertyCorrespondence, element,
                   "required \(requiredProperty.kind.rawValue) corresponds to a provided \(providedProperty.kind.rawValue)")
            return
        }
        checkType(requiredProperty, providedProperty, reads: reads, writes: writes, severity: failure, element: element)
        checkMultiplicity(requiredProperty, providedProperty, reads: reads, writes: writes, severity: failure,
                          element: element)
        checkCollectionSemantics(requiredProperty, providedProperty, reads: reads, writes: writes, severity: failure,
                                 element: element)
        if requiredProperty.isContainment != providedProperty.isContainment {
            let containmentSeverity: TypingSeverity = mode.isPartial && !writes ? .warning : failure
            report(containmentSeverity, .containmentMismatch, .containmentAndOpposites, element,
                   "required \(requiredProperty.isContainment ? "containment" : "non-containment") reference is provided as \(providedProperty.isContainment ? "containment" : "non-containment")")
        }
        checkOpposite(requiredProperty, providedProperty, writes: writes, severity: failure, element: element,
                      footprint: footprint)
        if writes, !providedProperty.isChangeable || providedProperty.isDerived {
            report(failure, .featureNotChangeable, .instantiationAndChangeability, element,
                   "the module writes the feature, but provided '\(providedProperty.name)' is "
                    + (providedProperty.isDerived ? "derived" : "not changeable"))
        }
    }

    /// Checks property types: covariant for reading, contravariant for writing, invariant for both.
    private mutating func checkType(
        _ requiredProperty: PropertyType, _ providedProperty: PropertyType, reads: Bool, writes: Bool,
        severity: TypingSeverity, element: ElementPath
    ) {
        let requiredName = requiredProperty.typeName, providedName = providedProperty.typeName
        switch requiredProperty.typeKind {
        case .objectType:
            let expected = mapped(requiredName)
            let readOK = provided.conforms(providedName, to: expected)
            let writeOK = provided.conforms(expected, to: providedName)
            if !((!reads || readOK) && (!writes || writeOK)) {
                let relation = reads && writes ? "the same as" : (reads ? "a subclass of" : "a superclass of")
                report(severity, .featureTypeMismatch, .propertyTypeVariance, element,
                       "provided type '\(providedName)' is not \(relation) required type '\(expected)'")
            }
        case .enumeration:
            if providedProperty.typeKind != .enumeration || mapped(requiredName) != providedName {
                report(severity, .featureTypeMismatch, .propertyTypeVariance, element,
                       "provided type '\(providedName)' does not correspond to required enumeration '\(mapped(requiredName))'")
            }
        case .dataType:
            let widening = options.allowsNumericWidening && !mode.isIsomorphic
            let ok: Bool
            if providedProperty.typeKind != .dataType {
                ok = false
            } else if sameDataType(requiredProperty, providedProperty) {
                ok = true
            } else if widening, let requiredCanonical = canonical(requiredProperty),
                let providedCanonical = canonical(providedProperty)
            {
                ok = (!reads || providedCanonical.widens(to: requiredCanonical))
                    && (!writes || requiredCanonical.widens(to: providedCanonical))
            } else {
                ok = false
            }
            if !ok {
                let direction = reads && writes ? "read and written" : (reads ? "read" : "written")
                report(severity, .featureTypeMismatch, .propertyTypeVariance, element,
                       "provided data type '\(providedName)' is not compatible with required '\(requiredName)' when \(direction)"
                        + (widening ? "" : " (numeric widening is off)"))
            }
        }
    }

    /// Checks multiplicities: the provided interval lies within the required one for reading, and the reverse for writing.
    private mutating func checkMultiplicity(
        _ requiredProperty: PropertyType, _ providedProperty: PropertyType, reads: Bool, writes: Bool,
        severity: TypingSeverity, element: ElementPath
    ) {
        let rLower = requiredProperty.lowerBound, pLower = providedProperty.lowerBound
        let rUpper = requiredProperty.effectiveUpperBound, pUpper = providedProperty.effectiveUpperBound
        let upperOK = (!reads || pUpper <= rUpper) && (!writes || rUpper <= pUpper)
        let lowerOK = (!reads || pLower >= rLower) && (!writes || rLower >= pLower)
        let description = "required \(requiredProperty.multiplicityDescription), provided \(providedProperty.multiplicityDescription)"
        if !upperOK {
            report(severity, .multiplicityMismatch, .multiplicityVariance, element, "upper bounds do not conform: " + description)
        }
        if !lowerOK {
            let lowerSeverity: TypingSeverity = options.lenientLowerBounds && !mode.isIsomorphic ? .warning : severity
            report(lowerSeverity, .multiplicityMismatch, .multiplicityVariance, element, "lower bounds do not conform: " + description)
        }
    }

    /// Checks ordering and uniqueness of many-valued properties.
    private mutating func checkCollectionSemantics(
        _ requiredProperty: PropertyType, _ providedProperty: PropertyType, reads: Bool, writes: Bool,
        severity: TypingSeverity, element: ElementPath
    ) {
        guard requiredProperty.isMany, providedProperty.isMany else { return }
        let checks: [(Bool, Bool, TypingDiagnosticCode, String)] = [
            (requiredProperty.isOrdered, providedProperty.isOrdered, .orderingMismatch, "ordered"),
            (requiredProperty.isUnique, providedProperty.isUnique, .uniquenessMismatch, "unique"),
        ]
        for (requiredFlag, providedFlag, code, word) in checks where requiredFlag != providedFlag {
            let message = "required \(requiredFlag ? "" : "non-")\(word) values are provided as \(providedFlag ? "" : "non-")\(word)"
            if reads && requiredFlag && !providedFlag {
                report(severity, code, .collectionSemantics, element, message)
            } else if writes {
                report(.warning, code, .collectionSemantics, element, message)
            }
        }
    }

    /// Checks that opposites correspond.
    ///
    /// A required opposite needs the same provided opposite (Guy et al. 2012,
    /// Def. 3, condition 4.7). A provided opposite that the required property
    /// lacks is harmless for reading; written values update it, which the
    /// module does not expect, so writing it is a warning.
    private mutating func checkOpposite(
        _ requiredProperty: PropertyType, _ providedProperty: PropertyType, writes: Bool, severity: TypingSeverity,
        element: ElementPath, footprint: MetamodelFootprint?
    ) {
        let expected = requiredProperty.oppositeName.map { mapped(feature: $0, of: requiredProperty.typeName) }
        guard expected != providedProperty.oppositeName else { return }
        let message = "required opposite \(expected.map { "'\($0)'" } ?? "none") is provided as \(providedProperty.oppositeName.map { "'\($0)'" } ?? "none")"
        guard let footprint else {
            if expected != nil {
                report(severity, .oppositeMismatch, .containmentAndOpposites, element, message)
            } else if writes {
                report(.warning, .oppositeMismatch, .containmentAndOpposites, element,
                       message + "; writes update an opposite that the module does not know")
            }
            return
        }
        guard writes else { return }
        let oppositeRead = requiredProperty.oppositeName.map { opposite in
            footprint.features.contains { $0.key.featureName == opposite && $0.value.access.isRead }
        } ?? false
        report(oppositeRead ? severity : .warning, .oppositeMismatch, .containmentAndOpposites, element,
               message + (oppositeRead ? "; the module reads the opposite after writing" : "; writes update opposites differently"))
    }
}
