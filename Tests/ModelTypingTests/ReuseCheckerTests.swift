//
//  ReuseCheckerTests.swift
//  ModelTypingTests
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import AQL
import ATL
import Foundation
import ModelTyping
import MTL
import Testing

/// End-to-end verdicts: can a module written against one metamodel run on another?
@Suite("Reuse verdicts")
struct ReuseCheckerTests {
    // MARK: - ATL

    /// Checks the families to persons transformation against provided metamodel versions.
    private func familiesToPersons(
        families: String = "Families", persons: String = "Persons", mode: SubtypingMode = .partial,
        options: CheckOptions = CheckOptions()
    ) async throws -> CompatibilityReport {
        let module = try await ATLParser(options: .standard).parseContent(familiesToPersonsModule, filename: "f.atl")
        let required = ["Families": try await Fixtures.modelType("Families"), "Persons": try await Fixtures.modelType("Persons")]
        let provided = ["Families": try await Fixtures.modelType(families), "Persons": try await Fixtures.modelType(persons)]
        return ReuseChecker.check(atl: module, required: required, provided: provided, mode: mode, options: options)
    }

    @Test("The transformation runs on its own metamodels in every mode", arguments: SubtypingMode.allCases)
    func atlIdentity(mode: SubtypingMode) async throws {
        let report = try await familiesToPersons(mode: mode)
        #expect(report.compatible, "\(report.formatted())")
        #expect(report.diagnostics.isEmpty)
        #expect(report.isConclusive)
        #expect(report.footprint?[metamodel: "Persons"]?.role == .target)
    }

    @Test("A renamed source feature is found by a structural hint and resolved by renaming")
    func atlRenamedSource() async throws {
        let report = try await familiesToPersons(families: "FamiliesV2")
        #expect(!report.compatible)
        #expect(report.errors.map(\.element.description) == ["Families!Member.firstName"])
        let hint = try #require(report.renamingHints.first)
        #expect(hint.renamingEntry == "Member.firstName=givenName")
        #expect(hint.reason == .uniqueStructuralCandidate)
        let renamed = try await familiesToPersons(families: "FamiliesV2", options: CheckOptions(renaming: report.suggestedRenaming))
        #expect(renamed.compatible, "\(renamed.formatted())")
    }

    @Test("Target changes that break output are errors; benign additions are warnings")
    func atlTargetRevisions() async throws {
        let broken = try await familiesToPersons(persons: "PersonsV2")
        #expect(broken.has(.abstractInstantiation, .error, at: "Persons!Female"))
        #expect(broken.has(.featureNotChangeable, .error, at: "Persons!Male.fullName"))
        #expect(broken.has(.missingLiteral, .error, at: "Persons!Salutation.ms"))
        #expect(broken.has(.mandatoryFeatureNotSet, .warning, at: "Persons!Male.age"))
        #expect(!broken.has(.missingLiteral, .error, at: "Persons!Salutation.mx"))
        #expect(broken.renamingHints.contains { $0.renamingEntry == "Salutation.ms=mrs" })

        let extended = try await familiesToPersons(persons: "PersonsV3")
        #expect(extended.compatible, "\(extended.formatted())")
        #expect(extended.warnings.map(\.element.description) == ["Persons!Female.registration", "Persons!Male.registration"])
        #expect(extended.warnings.allSatisfy { $0.code == .mandatoryFeatureNotSet && $0.rule == .outputConformance })
    }

    @Test("Partial subtyping accepts what total subtyping rejects")
    func atlModesDiffer() async throws {
        let partial = try await familiesToPersons(families: "FamiliesV2", options: CheckOptions(
            renaming: Renaming(members: ["Member.firstName": "givenName"])))
        #expect(partial.compatible)
        // Guy et al. (2012, Def. 3 and 4, pp. 406-407): isomorphic subtyping
        // admits optional additions but no renaming, and every mandatory
        // provided feature needs a required counterpart.
        let renaming = Renaming(members: ["Member.firstName": "givenName"])
        let total = try await familiesToPersons(
            families: "FamiliesV2", persons: "PersonsV3", mode: .totalIsomorphic, options: CheckOptions(renaming: renaming))
        #expect(!total.compatible)
        #expect(total.has(.missingFeature, .error, at: "Families!Member.firstName"))
        #expect(total.has(.renamingIgnored, .note, at: "Families!*"))
        #expect(total.has(.unexpectedFeature, .note, at: "Persons!Person.birthYear"))
        #expect(total.has(.unmatchedMandatoryFeature, .warning, at: "Persons!Male.registration"))
        let published = try await familiesToPersons(
            families: "FamiliesV2", persons: "PersonsV3", mode: .totalNonIsomorphic,
            options: CheckOptions(renaming: renaming, semantics: .mofClassMatching))
        #expect(published.errors.map(\.element.description) == ["Persons!Person.registration"])
    }

    // MARK: - MTL

    /// Checks the catalogue generator against a provided library version.
    private func catalogue(_ provided: String, options: CheckOptions = CheckOptions()) async throws -> CompatibilityReport {
        let module = try await MTLParser().parse(catalogueModule)
        return ReuseChecker.check(
            mtl: module, metamodelName: "library", required: try await Fixtures.modelType("LibraryV1"),
            provided: try await Fixtures.modelType(provided), options: options)
    }

    @Test("A generator runs on a refined extension of its metamodel")
    func mtlRefined() async throws {
        let report = try await catalogue("LibraryV1Refined")
        #expect(report.compatible, "\(report.formatted())")
        #expect(report.diagnostics.isEmpty)
    }

    @Test("Hints converge step by step towards the remaining genuine incompatibility")
    func mtlRevision() async throws {
        let first = try await catalogue("LibraryV2")
        #expect(Set(first.errors.map(\.element.description)) == [
            "library!Writer", "library!Library.writers", "library!Book.isbn", "library!Book.pages", "library!Book.authors",
        ])
        #expect(first.has(.unexpectedLiteral, .warning, at: "library!Genre.drama"))
        #expect(first.suggestedRenaming.entries == ["Book.isbn=ISBN", "Writer=Author"])

        let second = try await catalogue("LibraryV2", options: CheckOptions(renaming: first.suggestedRenaming))
        #expect(second.suggestedRenaming.entries == ["Library.writers=authors"])

        var renaming = first.suggestedRenaming
        renaming.members.merge(second.suggestedRenaming.members) { current, _ in current }
        let third = try await catalogue("LibraryV2", options: CheckOptions(renaming: renaming, allowsNumericWidening: true))
        #expect(third.errors.map(\.element.description) == ["library!Book.pages"])
        #expect(third.errors.first?.message.contains("when read") == true)
    }

    // MARK: - AQL

    /// Checks an AQL expression on `self : library::Library` against a provided library version.
    private func query(_ source: String, _ provided: String, mode: SubtypingMode = .partial,
                       options: CheckOptions = CheckOptions()) async throws -> CompatibilityReport {
        let expression = try #require(AQLParser().parse(source).expression)
        return ReuseChecker.check(
            aql: expression, variables: ["self": "library::Library"], metamodelName: "library",
            required: try await Fixtures.modelType("LibraryV1"), provided: try await Fixtures.modelType(provided),
            mode: mode, options: options)
    }

    @Test("Reading a widened attribute is incompatible, reading a narrowed one needs widening")
    func aqlWidening() async throws {
        #expect(!(try await query("self.books->select(b | b.pages > 100).title", "LibraryV2").compatible))
        let renaming = try Renaming(parsing: ["Writer=Author", "Library.writers=authors"])
        let narrowed = "self.writers->collect(w | w.born)"
        #expect(!(try await query(narrowed, "LibraryV2", options: CheckOptions(renaming: renaming)).compatible))
        #expect(try await query(narrowed, "LibraryV2", options: CheckOptions(renaming: renaming, allowsNumericWidening: true)).compatible)
    }

    @Test("Partial checks ignore unused elements that total checks reject")
    func aqlPartialVersusTotal() async throws {
        let source = "self.books->collect(b | b.title)"
        #expect(try await query(source, "LibraryV2").compatible)
        #expect(!(try await query(source, "LibraryV2", mode: .totalNonIsomorphic).compatible))
    }

    @Test("Footprint classes keep their subclass relations")
    func aqlInheritance() async throws {
        let report = try await query(
            "library::Book.allInstances()->select(b | b.oclIsKindOf(library::Item))", "LibraryV2")
        #expect(report.has(.missingClass, .error, at: "library!Item"))
        let unrelated = Build.modelType([
            Build.eClass("Library"), Build.eClass("Item", abstract: true), Build.eClass("Book"),
        ], name: "library")
        let detached = try await query("library::Book.allInstances()->select(b | b.oclIsKindOf(library::Item))", "LibraryV1")
        #expect(detached.compatible)
        let expression = try #require(AQLParser().parse("library::Book.allInstances()->select(b | b.oclIsKindOf(library::Item))").expression)
        let report2 = ReuseChecker.check(
            aql: expression, variables: [:], metamodelName: "library",
            required: try await Fixtures.modelType("LibraryV1"), provided: unrelated)
        #expect(report2.has(.supertypeNotPreserved, .warning, at: "library!Book"))
    }

    @Test("Guessed uses make a verdict inconclusive and only warn")
    func aqlInconclusive() async throws {
        let report = try await query("self.eContainer().name", "LibraryV2")
        #expect(report.compatible)
        #expect(!report.isConclusive)
        #expect(report.has(.missingClass, .warning, at: "library!Writer"))
    }

    // MARK: - Report

    @Test("Reports format as text and round-trip through JSON")
    func reportOutput() async throws {
        let report = try await query("self.eContainer().isbn", "LibraryV2")
        let text = report.formatted()
        #expect(text.hasPrefix("compatible (partial, inconclusive): 0 error(s), 1 warning(s)"))
        #expect(text.contains("warning: library!Book.isbn: provided class 'Book' has no feature 'isbn' (read) (use inferred without static type) [missingFeature]"))
        #expect(text.contains("uncertain: line 1: feature 'isbn' applied to an expression of unknown type; candidate owners: library!Book"))
        #expect(text.contains("hint: --rename Book.isbn=ISBN (caseDifference)"))
        let data = try JSONEncoder().encode(report)
        #expect(try JSONDecoder().decode(CompatibilityReport.self, from: data) == report)
        let total = try await query("self.name", "LibraryV1Refined", mode: .totalNonIsomorphic)
        #expect(!total.formatted().contains("note:"))
        #expect(total.formatted(includesNotes: true).contains("note: library!Entity: provided metamodel adds class 'Entity' [unexpectedClass]"))
    }

    @Test("Every rule names the work it follows")
    func citations() {
        for rule in SubtypingRule.allCases {
            #expect(!rule.citation.isEmpty)
            #expect(rule.citation.contains("p. ") || rule.citation.contains("pp. "), "\(rule) cites no page")
            #expect(!rule.isExtension || rule.citation.hasPrefix("Extension"), "\(rule) is not labelled as an extension")
            #expect(!rule.citation.contains("\u{2014}"))
        }
        #expect(SubtypingRule.propertyTypeVariance.citation.contains("Extension (access-refined semantics)"))
        #expect(SubtypingRule.mandatoryFeatureCorrespondence.citation.contains("Def. 3 (5), p. 407"))
        #expect(SubtypingRule.isomorphicStructure.citation.contains("Def. 4, p. 407"))
        #expect(SubtypingRule.objectTypeCorrespondence.citation.contains("Steel & Jézéquel"))
        #expect(SubtypingRule.partialFootprint.citation.contains("Jeanneret"))
        #expect(SubtypingRule.nonIsomorphicAdaptation.citation.contains("Melange"))
        #expect(TypingSeverity.error < .warning && TypingSeverity.warning < .note)
        #expect(MetamodelRole.target.assumedAccess == [.write, .instantiate])
        #expect(AccessMode([.read, .write, .instantiate]).label == "read+write+instantiate")
        #expect(AccessMode().label == "none")
    }
}
