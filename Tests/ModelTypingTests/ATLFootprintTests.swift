//
//  ATLFootprintTests.swift
//  ModelTypingTests
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import ATL
import ModelTyping
import Testing

/// A self-authored transformation in the style of the public Families to Persons example.
let familiesToPersonsModule = """
    module Families2Persons;
    create OUT : Persons from IN : Families;

    helper context Families!Member def: isFemale() : Boolean =
        if not self.familyMother.oclIsUndefined() then true
        else not self.familyDaughter.oclIsUndefined() endif;

    helper context Families!Member def: familyName : String =
        if not self.familyFather.oclIsUndefined() then self.familyFather.lastName
        else if not self.familyMother.oclIsUndefined() then self.familyMother.lastName
        else if not self.familySon.oclIsUndefined() then self.familySon.lastName
        else self.familyDaughter.lastName endif endif endif;

    rule Member2Male {
        from s : Families!Member (not s.isFemale())
        to t : Persons!Male (
            fullName <- s.firstName + ' ' + s.familyName,
            salutation <- #mr
        )
    }

    rule Member2Female {
        from s : Families!Member (s.isFemale())
        to t : Persons!Female (
            fullName <- s.firstName + ' ' + s.familyName,
            salutation <- #ms
        )
    }
    """

@Suite("ATL footprints")
struct ATLFootprintTests {
    /// The family and person model types, indexed by the metamodel names of the header.
    private func metamodels() async throws -> [String: ModelType] {
        ["Families": try await Fixtures.modelType("Families"), "Persons": try await Fixtures.modelType("Persons")]
    }

    /// Extracts the footprint of an ATL module.
    private func footprint(_ source: String) async throws -> Footprint {
        try await ATLFootprintExtractor(metamodels: try await metamodels()).footprint(ofSource: source)
    }

    @Test("Source reads and target writes are separated by metamodel")
    func familiesToPersons() async throws {
        let footprint = try await footprint(familiesToPersonsModule)
        let families = try #require(footprint[metamodel: "Families"])
        let persons = try #require(footprint[metamodel: "Persons"])
        #expect(families.role == .source)
        #expect(persons.role == .target)
        #expect(families.classNames == ["Member"])
        #expect(families.featureNames == [
            "Family.lastName", "Member.familyDaughter", "Member.familyFather", "Member.familyMother",
            "Member.familySon", "Member.firstName",
        ])
        #expect(families.features.values.allSatisfy { $0.access == .read })
        #expect(persons.classNames == ["Female", "Male"])
        #expect(persons.classes.values.allSatisfy { $0.access == .instantiate })
        #expect(persons.featureNames == ["Female.fullName", "Female.salutation", "Male.fullName", "Male.salutation"])
        #expect(persons.features.values.allSatisfy { $0.access == .write })
        #expect(persons.literals.keys.map(\.description).sorted() == ["Salutation.mr", "Salutation.ms"])
        #expect(footprint.isComplete, "\(footprint.uncertainties)")
    }

    @Test("Roles follow the module header")
    func roles() async throws {
        let parser = ATLParser(options: .standard)
        let plain = try await parser.parseContent(familiesToPersonsModule, filename: "f.atl")
        #expect(ATLFootprintExtractor.roles(of: plain) == ["Families": .source, "Persons": .target])
        let refining = try await parser.parseContent("""
            module Rename;
            create OUT : Families refining IN : Families;
            rule R { from s : Families!Member to t : Families!Member ( firstName <- s.firstName.toUpper() ) }
            """, filename: "r.atl")
        #expect(ATLFootprintExtractor.roles(of: refining) == ["Families": .sourceAndTarget])
        let footprint = ATLFootprintExtractor(metamodels: try await metamodels()).footprint(of: refining)
        #expect(footprint[metamodel: "Families"]?.access("Member.firstName") == [.read, .write])
    }

    @Test("Called and lazy rules, using blocks and do blocks are visited")
    func imperative() async throws {
        let footprint = try await footprint("""
            module M;
            create OUT : Persons from IN : Families;
            rule Family2Persons {
                from f : Families!Family
                using { head : Families!Member = f.father; }
                to p : Persons!Male ( fullName <- head.firstName )
                do {
                    for (s in f.sons) { thisModule.son(s); }
                    if (f.daughters->notEmpty()) { p.salutation <- #mx; } else { p.fullName <- f.lastName; }
                }
            }
            lazy rule Son { from m : Families!Member to t : Persons!Male ( fullName <- m.firstName ) }
            rule son(m : Families!Member) {
                to t : Persons!Male ( fullName <- m.firstName )
                do { t.salutation <- if m.familySon.oclIsUndefined() then #ms else #mr endif; }
            }
            """)
        let families = try #require(footprint[metamodel: "Families"])
        let persons = try #require(footprint[metamodel: "Persons"])
        #expect(families.classNames == ["Family", "Member"])
        #expect(families.featureNames == [
            "Family.daughters", "Family.father", "Family.lastName", "Family.sons", "Member.familySon", "Member.firstName",
        ])
        #expect(persons.featureNames == ["Male.fullName", "Male.salutation"])
        #expect(persons.literals.keys.map(\.description).sorted() == ["Salutation.mr", "Salutation.ms", "Salutation.mx"])
        #expect(footprint.isComplete, "\(footprint.uncertainties)")
    }

    @Test("Module helpers, iterate and type literals are typed")
    func moduleHelpers() async throws {
        let footprint = try await footprint("""
            module M;
            create OUT : Persons from IN : Families;
            helper def: families : Sequence(Families!Family) = Families!Family.allInstances();
            helper def: total : Integer = thisModule.families->iterate(f; n : Integer = 0 | n + f.sons->size());
            rule R {
                from m : Families!Member (thisModule.families->exists(f | f.mother = m))
                to t : Persons!Female ( fullName <- m.firstName + thisModule.total.toString() )
            }
            """)
        let families = try #require(footprint[metamodel: "Families"])
        #expect(families.classNames == ["Family", "Member"])
        #expect(families.featureNames == ["Family.mother", "Family.sons", "Member.firstName"])
        #expect(footprint.isComplete, "\(footprint.uncertainties)")
    }

    @Test("Enumeration literals compared with a typed value are attributed to its enumeration")
    func comparedLiterals() async throws {
        let footprint = try await footprint("""
            module M;
            create OUT : Persons from IN : Persons;
            rule R { from p : Persons!Male (p.salutation = #mr) to t : Persons!Male ( fullName <- p.fullName ) }
            """)
        let persons = try #require(footprint[metamodel: "Persons"])
        #expect(persons.role == .sourceAndTarget)
        #expect(persons.literals[LiteralReference(enumerationName: "Salutation", literalName: "mr")]?.access == .read)
        #expect(persons.access("Male.fullName") == [.read, .write])
    }

    @Test("Gaps in static knowledge are reported, not hidden")
    func gaps() async throws {
        let footprint = try await footprint("""
            module M;
            create OUT : Persons from IN : Families, EXTRA : Unknown;
            rule R {
                from m : Families!Member (m.firstName <> #sir)
                to t : Persons!Male ( fullName <- m.refImmediateComposite().lastName )
            }
            """)
        let kinds = Set(footprint.uncertainties.map(\.kind))
        #expect(kinds == [.unknownType, .unknownReceiverType, .unresolvedLiteral])
        #expect(footprint[metamodel: "Families"]?.features[FeatureReference(className: "Family", featureName: "lastName")]?.isCertain == false)
        #expect(footprint[metamodel: "Unknown"] == nil)
    }

    @Test("Unparsable modules are rejected")
    func parseFailure() async throws {
        await #expect(throws: FootprintExtractionError.self) { try await footprint("module ;") }
    }
}
