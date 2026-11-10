//
//  PublishedSemanticsTests.swift
//  ModelTypingTests
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import ECore
import EMFBase
import ModelTyping
import Testing

/// Tests of the published matching relations, one definition at a time.
///
/// The state machine variants follow the running example of Steel and
/// Jézéquel (2007, Sect. 2.1); the expected verdicts are those of their
/// Table 1 (p. 409) and, where Guy et al. (2012, Def. 3, p. 406) are stricter,
/// those that Definition 3 implies.
@Suite("Published matching semantics")
struct PublishedSemanticsTests {
    /// Options that select a matching semantics.
    private func options(_ semantics: MatchingSemantics, renaming: Renaming = .identity) -> CheckOptions {
        CheckOptions(renaming: renaming, semantics: semantics)
    }

    /// Checks a total relation under a semantics.
    private func total(
        _ required: ModelType, _ provided: ModelType, _ semantics: MatchingSemantics,
        mode: SubtypingMode = .totalIsomorphic, role: MetamodelRole = .source
    ) -> CompatibilityReport {
        ModelTypeChecker(options: options(semantics)).check(required: required, provided: provided, mode: mode, role: role)
    }

    /// A state machine metamodel in the style of Steel and Jézéquel (2007, Figs. 1 to 5).
    ///
    /// - Parameters:
    ///   - initialLower: The lower bound of `StateMachine.initialState`.
    ///   - initialUpper: The upper bound of `StateMachine.initialState`.
    ///   - composite: Whether a state machine is itself a state (Fig. 4).
    ///   - finalStates: Whether the metamodel adds a `FinalState` subclass (Fig. 5).
    /// - Returns: The model type.
    private func stateMachines(
        initialLower: Int = 0, initialUpper: Int = 1, composite: Bool = false, finalStates: Bool = false
    ) -> ModelType {
        let contained = EUUID(), container = EUUID(), outgoing = EUUID(), source = EUUID()
        let incoming = EUUID(), target = EUUID()
        var classifiers: [any EClassifier] = [
            Build.eClass("StateMachine", supers: composite ? ["State"] : [], [
                Build.reference("initialState", "State", lower: initialLower, upper: initialUpper),
                Build.reference("containedState", "State", upper: -1, containment: true, id: contained,
                                opposite: container),
            ]),
            Build.eClass("State", [
                Build.attribute("name", lower: 1),
                Build.reference("stateMachine", "StateMachine", id: container, opposite: contained),
                Build.reference("outgoing", "Transition", upper: -1, id: outgoing, opposite: source),
                Build.reference("incoming", "Transition", upper: -1, id: incoming, opposite: target),
            ]),
            Build.eClass("Transition", [
                Build.attribute("event", lower: 1),
                Build.reference("src", "State", lower: 1, id: source, opposite: outgoing),
                Build.reference("tgt", "State", lower: 1, id: target, opposite: incoming),
            ]),
        ]
        if finalStates { classifiers.append(Build.eClass("FinalState", supers: ["State"])) }
        return Build.modelType(classifiers, name: "statecharts")
    }

    /// The variants of Table 1, in its row and column order.
    private var variants: [(name: String, modelType: ModelType)] {
        [
            ("Simple", stateMachines()),
            ("Multiple-start", stateMachines(initialUpper: -1)),
            ("Mandatory-start", stateMachines(initialLower: 1)),
            ("Composite", stateMachines(composite: true)),
            ("With-final-states", stateMachines(finalStates: true)),
        ]
    }

    /// Steel and Jézéquel (2007), Table 1, p. 409: row matches column.
    private let steelTable1: [[Bool]] = [
        [true, false, false, false, false],
        [false, true, false, false, false],
        [true, false, true, false, false],
        [true, false, false, true, false],
        [true, false, false, false, true],
    ]

    /// Checks every pair of variants and returns the matching relation, row matches column.
    private func relation(_ semantics: MatchingSemantics) -> [[Bool]] {
        variants.map { row in
            variants.map { column in total(column.modelType, row.modelType, semantics).compatible }
        }
    }

    // MARK: - Steel and Jézéquel (2007)

    @Test("Object type matching reproduces Table 1 of Steel and Jézéquel")
    func steelTableOne() {
        #expect(relation(.objectTypeMatching) == steelTable1)
    }

    @Test("Object type matching relaxes a lower bound but keeps multi-valuedness (Fig. 10, PropMatch)")
    func steelMultiplicities() {
        let optional = stateMachines(), mandatory = stateMachines(initialLower: 1), many = stateMachines(initialUpper: -1)
        #expect(total(optional, mandatory, .objectTypeMatching).compatible)
        let tightened = total(mandatory, optional, .objectTypeMatching)
        #expect(tightened.has(.multiplicityMismatch, .error, at: "statecharts!StateMachine.initialState"))
        #expect(tightened.errors.allSatisfy { $0.rule == .multiplicityVariance })
        #expect(total(optional, many, .objectTypeMatching).has(.multiplicityMismatch, .error, at: "statecharts!StateMachine.initialState"))
        #expect(total(many, optional, .objectTypeMatching).has(.multiplicityMismatch, .error, at: "statecharts!StateMachine.initialState"))
    }

    @Test("Object type matching is covariant in property types, whatever the direction of use")
    func steelCovariance() {
        let general = shelves(itemsOf: "Item"), specific = shelves(itemsOf: "Book")
        for role in [MetamodelRole.source, .target, .sourceAndTarget] {
            #expect(total(general, specific, .objectTypeMatching, role: role).compatible)
            #expect(total(specific, general, .objectTypeMatching, role: role).has(.featureTypeMismatch, .error, at: "mm!Shelf.items"))
        }
    }

    @Test("Object type matching ignores ordering, uniqueness, containment, opposites and abstractness")
    func steelIgnores() {
        let plain = shelves(itemsOf: "Item")
        let changed = Build.modelType([
            Build.eClass("Shelf", abstract: true, [
                Build.reference("items", "Item", upper: -1, containment: true, ordered: false, unique: false),
                Build.attribute("label"),
            ]),
            Build.eClass("Item", abstract: true, [Build.attribute("id", lower: 1, changeable: false)]),
            Build.eClass("Book", supers: ["Item"], [Build.attribute("title")]),
        ])
        #expect(total(plain, changed, .objectTypeMatching).errors.isEmpty)
    }

    // MARK: - Guy et al. (2012), Definition 3

    @Test("MOF class matching forbids the lower bound relaxation of Table 1 (Def. 3, 4.5)")
    func guyTableOne() {
        var expected = steelTable1
        expected[2][0] = false
        #expect(relation(.mofClassMatching) == expected)
        let report = total(stateMachines(), stateMachines(initialLower: 1), .mofClassMatching)
        #expect(report.has(.multiplicityMismatch, .error, at: "statecharts!StateMachine.initialState"))
    }

    @Test("MOF class matching admits a subclass as property type only for read-only properties (Def. 3, 4.4)")
    func guyReadOnlyCovariance() {
        let general = shelves(itemsOf: "Item"), specific = shelves(itemsOf: "Book")
        let changeable = total(general, specific, .mofClassMatching)
        #expect(changeable.has(.featureTypeMismatch, .error, at: "mm!Shelf.items"))
        #expect(changeable.errors.allSatisfy { $0.rule == .propertyTypeVariance })
        let readOnly = shelves(itemsOf: "Item", changeable: false)
        #expect(total(readOnly, shelves(itemsOf: "Book", changeable: false), .mofClassMatching).compatible)
        #expect(!total(specific, general, .mofClassMatching).compatible)
    }

    @Test("A provided abstract class needs an abstract required class (Def. 3, 2)")
    func guyAbstractness() {
        let concrete = Build.modelType([Build.eClass("Base")]), abstract = Build.modelType([Build.eClass("Base", abstract: true)])
        let report = total(concrete, abstract, .mofClassMatching)
        #expect(report.has(.abstractnessMismatch, .error, at: "mm!Base"))
        #expect(report.errors.allSatisfy { $0.rule == .instantiationAndChangeability })
        #expect(total(abstract, concrete, .mofClassMatching).compatible)
        #expect(total(concrete, abstract, .accessRefined).compatible)
        #expect(total(concrete, abstract, .accessRefined, role: .target).has(.abstractInstantiation, .error, at: "mm!Base"))
    }

    @Test("A provided read-only property needs a read-only required property (Def. 3, 4.2)")
    func guyReadOnly() {
        let writable = Build.modelType([Build.eClass("Book", [Build.attribute("title")])])
        let fixed = Build.modelType([Build.eClass("Book", [Build.attribute("title", changeable: false)])])
        #expect(total(writable, fixed, .mofClassMatching).has(.featureNotChangeable, .error, at: "mm!Book.title"))
        #expect(total(fixed, writable, .mofClassMatching).compatible)
        #expect(total(writable, fixed, .accessRefined).compatible)
    }

    @Test("Composition must be equal (Def. 3, 4.3)")
    func guyComposition() {
        let plain = shelves(itemsOf: "Item"), owning = shelves(itemsOf: "Item", containment: true)
        #expect(total(plain, owning, .mofClassMatching).has(.containmentMismatch, .error, at: "mm!Shelf.items"))
        #expect(total(owning, plain, .mofClassMatching).has(.containmentMismatch, .error, at: "mm!Shelf.items"))
    }

    @Test("A required opposite needs the same provided opposite, but not the reverse (Def. 3, 4.7)")
    func guyOpposites() {
        let (paired, unpaired) = authorship()
        #expect(total(paired, unpaired, .mofClassMatching).has(.oppositeMismatch, .error, at: "mm!Book.authors"))
        let gained = total(unpaired, paired, .mofClassMatching)
        #expect(gained.compatible && gained.diagnostics.isEmpty)
        #expect(total(unpaired, paired, .accessRefined).diagnostics.isEmpty)
        let written = total(unpaired, paired, .accessRefined, role: .target)
        #expect(written.compatible && written.has(.oppositeMismatch, .warning, at: "mm!Book.authors"))
    }

    @Test("Uniqueness must be equal and ordering is not compared (Def. 3, 4.8)")
    func guyCollectionSemantics() {
        let set = shelves(itemsOf: "Item"), bag = shelves(itemsOf: "Item", unique: false)
        #expect(total(set, bag, .mofClassMatching).has(.uniquenessMismatch, .error, at: "mm!Shelf.items"))
        #expect(total(bag, set, .mofClassMatching).has(.uniquenessMismatch, .error, at: "mm!Shelf.items"))
        let unordered = shelves(itemsOf: "Item", ordered: false)
        #expect(total(set, unordered, .mofClassMatching).diagnostics.isEmpty)
        #expect(total(set, unordered, .accessRefined).has(.orderingMismatch, .error, at: "mm!Shelf.items"))
    }

    @Test("A mandatory provided feature needs a required counterpart (Def. 3, 5)")
    func guyMandatoryAdditions() {
        let books = Build.modelType([Build.eClass("Book", [Build.attribute("title")])])
        let registered = Build.modelType([Build.eClass("Book", [Build.attribute("title"), Build.attribute("isbn", lower: 1)])])
        let annotated = Build.modelType([Build.eClass("Book", [Build.attribute("title"), Build.attribute("note")])])
        let guy = total(books, registered, .mofClassMatching)
        #expect(guy.has(.unmatchedMandatoryFeature, .error, at: "mm!Book.isbn"))
        #expect(guy.errors.allSatisfy { $0.rule == .mandatoryFeatureCorrespondence })
        #expect(total(books, annotated, .mofClassMatching).has(.unexpectedFeature, .note, at: "mm!Book.note"))
        #expect(total(books, registered, .objectTypeMatching).has(.unexpectedFeature, .note, at: "mm!Book.isbn"))
        #expect(total(books, registered, .accessRefined).has(.unexpectedFeature, .note, at: "mm!Book.isbn"))
        let created = total(books, registered, .accessRefined, role: .target)
        #expect(created.compatible && created.has(.unmatchedMandatoryFeature, .warning, at: "mm!Book.isbn"))
    }

    @Test("Inheritance preservation is an extension: a warning under the published semantics")
    func inheritanceExtension() {
        let a = Build.modelType([Build.eClass("Base"), Build.eClass("Leaf", supers: ["Base"])])
        let b = Build.modelType([Build.eClass("Base"), Build.eClass("Leaf")])
        for semantics in [MatchingSemantics.objectTypeMatching, .mofClassMatching] {
            let report = total(a, b, semantics)
            #expect(report.compatible && report.has(.supertypeNotPreserved, .warning, at: "mm!Leaf"))
        }
        #expect(total(a, b, .accessRefined).has(.supertypeNotPreserved, .error, at: "mm!Leaf"))
    }

    @Test("Enumerations are data types: the published semantics demand equal literals")
    func enumerationIdentity() {
        func library(_ literals: [String]) -> ModelType {
            let genre = Build.eEnum("Genre", literals)
            return Build.modelType([genre, Build.eClass("Book", [EAttribute(name: "genre", eType: genre)])])
        }
        let two = library(["fiction", "poetry"]), three = library(["fiction", "poetry", "drama"]), one = library(["fiction"])
        #expect(total(two, three, .mofClassMatching, role: .target).has(.unexpectedLiteral, .error, at: "mm!Genre.drama"))
        #expect(total(two, one, .mofClassMatching).has(.missingLiteral, .error, at: "mm!Genre.poetry"))
        #expect(total(two, three, .accessRefined, mode: .totalNonIsomorphic, role: .target).compatible)
        #expect(total(two, one, .accessRefined, mode: .totalNonIsomorphic).compatible)
    }

    // MARK: - Isomorphic subtyping (Guy et al. 2012, Def. 4 and 11)

    @Test("Isomorphic subtyping is a subgraph isomorphism: additions are allowed", arguments: MatchingSemantics.allCases)
    func isomorphicAdditions(semantics: MatchingSemantics) {
        let books = Build.modelType([Build.eClass("Book", [Build.attribute("title")])])
        let more = Build.modelType([
            Build.eClass("Book", [Build.attribute("title"), Build.attribute("note")]), Build.eClass("Magazine"),
            Build.eEnum("Size", ["s"]),
        ])
        let report = total(books, more, semantics)
        #expect(report.compatible)
        #expect(report.has(.unexpectedClass, .note, at: "mm!Magazine"))
        #expect(report.has(.unexpectedFeature, .note, at: "mm!Book.note"))
        #expect(report.has(.unexpectedEnumeration, .note, at: "mm!Size"))
        #expect(report.diagnostics.allSatisfy { $0.severity == .note && $0.rule == .isomorphicStructure })
    }

    @Test("Isomorphic subtyping admits no renaming", arguments: [SubtypingMode.totalIsomorphic, .partialIsomorphic])
    func isomorphicNames(mode: SubtypingMode) {
        let required = Build.modelType([Build.eClass("Book", [Build.attribute("title")])])
        let provided = Build.modelType([Build.eClass("Book", [Build.attribute("name")])])
        var footprint = MetamodelFootprint(metamodelName: "mm", role: .source)
        footprint.record(feature: FeatureReference(className: "Book", featureName: "title"), Usage(.read))
        let renaming = Renaming(members: ["Book.title": "name"])
        let nonIsomorphic: SubtypingMode = mode == .totalIsomorphic ? .totalNonIsomorphic : .partial
        for semantics in MatchingSemantics.allCases {
            let checker = ModelTypeChecker(options: options(semantics, renaming: renaming))
            #expect(checker.check(required: required, provided: provided, mode: nonIsomorphic, footprint: footprint).compatible)
            let report = checker.check(required: required, provided: provided, mode: mode, footprint: footprint)
            #expect(report.has(.missingFeature, .error, at: "mm!Book.title"))
            #expect(report.has(.renamingIgnored, .note, at: "mm!*"))
        }
    }

    // MARK: - Partial subtyping (Guy et al. 2012, Def. 9, 10, 12 and 14)

    @Test("The effective model type closes the footprint over superclasses, mandatory features and their types")
    func effectiveModelType() {
        let library = Build.modelType([
            Build.eClass("Named", abstract: true, [Build.attribute("name", lower: 1)]),
            Build.eClass("Shelf", supers: ["Named"], [
                Build.reference("items", "Item", upper: -1), Build.attribute("label"),
            ]),
            Build.eClass("Item", abstract: true, [Build.attribute("id", lower: 1), Build.attribute("note")]),
            Build.eClass("Book", supers: ["Item"], [Build.attribute("title")]),
            Build.eClass("Library", [Build.reference("shelves", "Shelf", upper: -1, containment: true)]),
        ])
        var footprint = MetamodelFootprint(metamodelName: "mm", role: .source)
        footprint.record(feature: FeatureReference(className: "Shelf", featureName: "items"), Usage(.read))
        let effective = library.effectiveModelType(for: footprint)
        #expect(Set(effective.objectTypes.keys) == ["Named", "Shelf", "Item"])
        #expect(Set(effective.objectTypes["Shelf"]?.properties.keys.map { $0 } ?? []) == ["items", "name"])
        #expect(Set(effective.objectTypes["Item"]?.properties.keys.map { $0 } ?? []) == ["id"])
        #expect(effective.objectTypes["Shelf"]?.allSuperTypeNames == ["Named"])
        #expect(effective.objectTypes["Item"]?.isAbstract == true)
    }

    @Test("Partial subtyping under MOF class matching checks the effective model type")
    func guyPartial() {
        let required = shelves(itemsOf: "Item")
        var footprint = MetamodelFootprint(metamodelName: "mm", role: .source)
        footprint.record(feature: FeatureReference(className: "Shelf", featureName: "items"), Usage(.read))
        func partial(_ provided: ModelType, _ semantics: MatchingSemantics) -> CompatibilityReport {
            ModelTypeChecker(options: options(semantics)).check(
                required: required, provided: provided, mode: .partial, footprint: footprint)
        }
        let relabelled = shelves(itemsOf: "Item", labelType: "EInt")
        #expect(partial(relabelled, .mofClassMatching).diagnostics.isEmpty)
        #expect(partial(relabelled, .accessRefined).diagnostics.isEmpty)
        let optionalID = shelves(itemsOf: "Item", idLower: 0)
        #expect(partial(optionalID, .mofClassMatching).has(.multiplicityMismatch, .error, at: "mm!Item.id"))
        #expect(partial(optionalID, .accessRefined).compatible)
        let specific = shelves(itemsOf: "Book")
        #expect(partial(specific, .mofClassMatching).has(.featureTypeMismatch, .error, at: "mm!Shelf.items"))
        #expect(partial(specific, .objectTypeMatching).compatible)
        #expect(partial(specific, .accessRefined).compatible)
    }

    @Test("Uses that could only be guessed stay warnings in the effective model type")
    func guyPartialUncertain() {
        let required = shelves(itemsOf: "Item"), provided = shelves(itemsOf: "Book")
        var footprint = MetamodelFootprint(metamodelName: "mm", role: .source)
        footprint.record(feature: FeatureReference(className: "Shelf", featureName: "items"), Usage(.read, isCertain: false))
        let report = ModelTypeChecker(options: options(.mofClassMatching)).check(
            required: required, provided: provided, mode: .partial, footprint: footprint)
        #expect(report.compatible && report.has(.featureTypeMismatch, .warning, at: "mm!Shelf.items"))
    }

    @Test("Published partial subtyping covers enumerations, kinds and uses outside the required model type")
    func guyPartialEnumerations() {
        let genre = Build.eEnum("Genre", ["fiction", "poetry"])
        let required = Build.modelType([genre, Build.eClass("Book", [
            EAttribute(name: "genre", eType: genre), EAttribute(name: "kind", eType: genre),
            Build.attribute("pages", "EInt"), Build.attribute("author"),
        ])])
        let provided = Build.modelType([
            Build.eEnum("Genre", ["fiction"]), Build.eEnum("Mood", ["happy"]), Build.eClass("Writer"),
            Build.eClass("Book", [
                EAttribute(name: "genre", eType: Build.eEnum("Genre", ["fiction"])), Build.attribute("kind"),
                Build.attribute("pages"), Build.reference("author", "Writer"),
            ]),
        ])
        var footprint = MetamodelFootprint(metamodelName: "mm", role: .source)
        for feature in ["genre", "kind", "pages", "author", "unknown"] {
            footprint.record(feature: FeatureReference(className: "Book", featureName: feature), Usage(.read))
        }
        footprint.record(className: "Ghost", Usage(.read))
        for (enumeration, literal) in [("Genre", "poetry"), ("Mood", "calm"), ("Colour", "red")] {
            footprint.record(literal: LiteralReference(enumerationName: enumeration, literalName: literal), Usage(.read))
        }
        let effective = required.effectiveModelType(for: footprint)
        #expect(Set(effective.enumerations.keys) == ["Genre"])
        let report = ModelTypeChecker(options: options(.mofClassMatching)).check(
            required: required, provided: provided, mode: .partial, footprint: footprint)
        #expect(report.has(.missingLiteral, .error, at: "mm!Genre.poetry"))
        #expect(report.has(.featureTypeMismatch, .error, at: "mm!Book.kind"))
        #expect(report.has(.featureTypeMismatch, .error, at: "mm!Book.pages"))
        #expect(report.has(.featureKindMismatch, .error, at: "mm!Book.author"))
        #expect(report.has(.missingFeature, .error, at: "mm!Book.unknown"))
        #expect(report.has(.missingClass, .error, at: "mm!Ghost"))
        #expect(report.has(.missingLiteral, .error, at: "mm!Mood.calm"))
        #expect(report.has(.missingEnumeration, .error, at: "mm!Colour"))
    }

    // MARK: - Fixtures

    /// A shelf metamodel whose `items` reference is typed by the given class.
    private func shelves(
        itemsOf type: String, upper: Int = -1, ordered: Bool = true, unique: Bool = true, containment: Bool = false,
        changeable: Bool = true, labelType: String = "EString", idLower: Int = 1
    ) -> ModelType {
        let items = EReference(name: "items", eType: EClass(name: type), lowerBound: 0, upperBound: upper,
                               changeable: changeable, containment: containment, ordered: ordered, unique: unique)
        return Build.modelType([
            Build.eClass("Shelf", [items, Build.attribute("label", labelType)]),
            Build.eClass("Item", abstract: true, [Build.attribute("id", lower: idLower)]),
            Build.eClass("Book", supers: ["Item"], [Build.attribute("title")]),
        ])
    }

    /// A pair of book and writer metamodels, with and without opposites.
    private func authorship() -> (paired: ModelType, unpaired: ModelType) {
        let booksID = EUUID(), authorsID = EUUID()
        let paired = Build.modelType([
            Build.eClass("Book", [Build.reference("authors", "Writer", upper: -1, id: authorsID, opposite: booksID)]),
            Build.eClass("Writer", [Build.reference("books", "Book", upper: -1, id: booksID, opposite: authorsID)]),
        ])
        let unpaired = Build.modelType([
            Build.eClass("Book", [Build.reference("authors", "Writer", upper: -1)]),
            Build.eClass("Writer", [Build.reference("books", "Book", upper: -1)]),
        ])
        return (paired, unpaired)
    }
}
