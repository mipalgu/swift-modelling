//
//  TotalSubtypingTests.swift
//  ModelTypingTests
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import ModelTyping
import Testing

@Suite("Total subtyping")
struct TotalSubtypingTests {
    @Test("A metamodel is an isomorphic and non-isomorphic subtype of itself", arguments: [
        "LibraryV1", "LibraryV2", "Families", "Persons",
    ])
    func reflexivity(fixture: String) async throws {
        let modelType = try await Fixtures.modelType(fixture)
        for mode in [SubtypingMode.totalIsomorphic, .totalNonIsomorphic] {
            for role in [MetamodelRole.source, .target, .sourceAndTarget] {
                let report = ModelTypeChecker().check(required: modelType, provided: modelType, mode: mode, role: role)
                #expect(report.diagnostics.isEmpty, "\(fixture) \(mode) \(role): \(report.formatted())")
            }
        }
    }

    @Test("Optional additions and a refined hierarchy are isomorphic and non-isomorphic subtypes")
    func refinement() async throws {
        let v1 = try await Fixtures.modelType("LibraryV1"), refined = try await Fixtures.modelType("LibraryV1Refined")
        let nonIsomorphic = ModelTypeChecker().check(required: v1, provided: refined, mode: .totalNonIsomorphic)
        #expect(nonIsomorphic.compatible, "\(nonIsomorphic.formatted())")
        #expect(nonIsomorphic.warnings.isEmpty)
        #expect(nonIsomorphic.diagnostics(withCode: .unexpectedClass).map(\.element.classifier).sorted() == ["Entity", "Magazine"])
        #expect(nonIsomorphic.diagnostics.allSatisfy { $0.severity == .note && $0.rule == .nonIsomorphicAdaptation })

        // Guy et al. (2012, Def. 4, p. 407): model type matching is a subgraph
        // isomorphism, so optional additions do not break isomorphic subtyping.
        for semantics in MatchingSemantics.allCases {
            let isomorphic = ModelTypeChecker(options: CheckOptions(semantics: semantics))
                .check(required: v1, provided: refined, mode: .totalIsomorphic)
            #expect(isomorphic.compatible, "\(semantics): \(isomorphic.formatted())")
            #expect(isomorphic.has(.unexpectedClass, .note, at: "library!Magazine"))
            #expect(isomorphic.has(.unexpectedFeature, .note, at: "library!Book.subtitle"))
            #expect(isomorphic.diagnostics(withCode: .supertypeNotPreserved).isEmpty)
            #expect(isomorphic.diagnostics.allSatisfy { $0.severity == .note && $0.rule == .isomorphicStructure })
        }
    }

    @Test("The reverse direction loses required elements")
    func reverseRefinement() async throws {
        let v1 = try await Fixtures.modelType("LibraryV1"), refined = try await Fixtures.modelType("LibraryV1Refined")
        let report = ModelTypeChecker().check(required: refined, provided: v1, mode: .totalNonIsomorphic)
        #expect(report.has(.missingClass, .error, at: "library!Magazine"))
        #expect(report.has(.missingFeature, .error, at: "library!Book.subtitle"))
        #expect(report.has(.flattenedClass, .warning, at: "library!Entity"))
    }

    @Test("A renamed, flattened and retyped revision is diagnosed element by element")
    func revision() async throws {
        let v1 = try await Fixtures.modelType("LibraryV1"), v2 = try await Fixtures.modelType("LibraryV2")
        let report = ModelTypeChecker().check(required: v1, provided: v2, mode: .totalNonIsomorphic)
        #expect(!report.compatible)
        #expect(report.has(.missingClass, .error, at: "library!Writer"))
        #expect(report.has(.flattenedClass, .warning, at: "library!Item"))
        #expect(report.has(.missingFeature, .error, at: "library!Book.isbn"))
        #expect(report.has(.missingFeature, .error, at: "library!Library.writers"))
        #expect(report.has(.featureTypeMismatch, .error, at: "library!Book.pages"))
        #expect(report.has(.featureTypeMismatch, .error, at: "library!Book.authors"))
        #expect(report.has(.unexpectedLiteral, .error, at: "library!Genre.drama"))
        #expect(report.has(.unexpectedClass, .note, at: "library!Magazine"))
        #expect(report.renamingHints.contains {
            $0.kind == .classifier && $0.requiredName == "Writer" && $0.suggestedName == "Author" && $0.reason == .similarStructure
        })
        #expect(report.renamingHints.contains {
            $0.kind == .feature && $0.owner == "Book" && $0.requiredName == "isbn" && $0.suggestedName == "ISBN"
                && $0.reason == .caseDifference
        })
        let suggested = report.suggestedRenaming
        #expect(suggested.classifiers["Writer"] == "Author")
        #expect(suggested.members["Book.isbn"] == "ISBN")
    }

    @Test("Renaming and widening resolve what they can, and nothing more")
    func revisionWithRenaming() async throws {
        let v1 = try await Fixtures.modelType("LibraryV1"), v2 = try await Fixtures.modelType("LibraryV2")
        let renaming = try Renaming(parsing: ["Writer=Author", "Library.writers=authors", "Book.isbn=ISBN"])
        let renamed = ModelTypeChecker(options: CheckOptions(renaming: renaming))
            .check(required: v1, provided: v2, mode: .totalNonIsomorphic)
        #expect(Set(renamed.errors.map(\.element.description)) == [
            "library!Book.pages", "library!Writer.born", "library!Genre.drama",
        ])
        let widened = ModelTypeChecker(options: CheckOptions(renaming: renaming, allowsNumericWidening: true))
            .check(required: v1, provided: v2, mode: .totalNonIsomorphic)
        #expect(Set(widened.errors.map(\.element.description)) == ["library!Book.pages", "library!Genre.drama"])
    }

    @Test("Target metamodels are checked contravariantly")
    func targetRole() async throws {
        let persons = try await Fixtures.modelType("Persons"), revised = try await Fixtures.modelType("PersonsV2")
        let report = ModelTypeChecker().check(required: persons, provided: revised, mode: .totalNonIsomorphic, role: .target)
        #expect(report.has(.abstractInstantiation, .error, at: "Persons!Female"))
        #expect(report.has(.featureNotChangeable, .error, at: "Persons!Male.fullName"))
        #expect(report.has(.missingLiteral, .error, at: "Persons!Salutation.ms"))
        #expect(report.has(.missingLiteral, .error, at: "Persons!Salutation.mx"))
        #expect(!report.has(.abstractInstantiation, .error, at: "Persons!Person"))
        #expect(report.renamingHints.contains { $0.kind == .literal && $0.requiredName == "ms" && $0.suggestedName == "mrs" })
        let extension_ = try await Fixtures.modelType("PersonsV3")
        let extended = ModelTypeChecker().check(required: persons, provided: extension_, mode: .totalNonIsomorphic, role: .target)
        #expect(extended.compatible, "\(extended.formatted())")
    }

    @Test("Abstractness follows MOF class matching; supertypes follow the inheritance extension")
    func isomorphicFlags() {
        let a = Build.modelType([Build.eClass("Base"), Build.eClass("Leaf", supers: ["Base"])])
        let b = Build.modelType([Build.eClass("Base", abstract: true), Build.eClass("Leaf")])
        // Guy et al. (2012, Def. 3, condition 2, p. 406): a provided abstract
        // class needs an abstract required class.
        let published = ModelTypeChecker(options: CheckOptions(semantics: .mofClassMatching))
            .check(required: a, provided: b, mode: .totalIsomorphic)
        #expect(published.has(.abstractnessMismatch, .error, at: "mm!Base"))
        #expect(published.has(.supertypeNotPreserved, .warning, at: "mm!Leaf"))
        let report = ModelTypeChecker().check(required: a, provided: b, mode: .totalIsomorphic)
        #expect(report.codes(.error) == [.supertypeNotPreserved])
        #expect(report.has(.supertypeNotPreserved, .error, at: "mm!Leaf"))
        let nonIsomorphic = ModelTypeChecker().check(required: a, provided: b, mode: .totalNonIsomorphic)
        #expect(nonIsomorphic.codes(.error) == [.supertypeNotPreserved])
    }

    @Test("An abstract class that types a reference cannot be flattened")
    func flatteningNeedsNoReferences() {
        let a = Build.modelType([
            Build.eClass("Shelf", [Build.reference("items", "Item", upper: -1)]),
            Build.eClass("Item", abstract: true), Build.eClass("Book", supers: ["Item"]),
        ])
        let b = Build.modelType([Build.eClass("Shelf", [Build.reference("items", "Book", upper: -1)]), Build.eClass("Book")])
        let report = ModelTypeChecker().check(required: a, provided: b, mode: .totalNonIsomorphic)
        #expect(report.has(.missingClass, .error, at: "mm!Item"))
    }

    @Test("Missing provided metamodels and footprints are reported")
    func missingInputs() async throws {
        let v1 = try await Fixtures.modelType("LibraryV1")
        let missing = ModelTypeChecker().check(required: ["lib": v1], provided: [:], mode: .totalNonIsomorphic)
        #expect(missing.codes(.error) == [.missingMetamodel])
        let partial = ModelTypeChecker().check(required: v1, provided: v1, mode: .partial)
        #expect(partial.codes(.error) == [.missingFootprint])
    }

    @Test("Missing enumerations are reported with hints")
    func enumerations() {
        let a = Build.modelType([Build.eEnum("Colour", ["red"])])
        let b = Build.modelType([Build.eEnum("Color", ["red"]), Build.eEnum("Size", ["s"])])
        let report = ModelTypeChecker().check(required: a, provided: b, mode: .totalIsomorphic)
        #expect(report.has(.missingEnumeration, .error, at: "mm!Colour"))
        #expect(report.has(.unexpectedEnumeration, .note, at: "mm!Size"))
        #expect(report.renamingHints.map(\.suggestedName) == ["Color"])
    }
}
