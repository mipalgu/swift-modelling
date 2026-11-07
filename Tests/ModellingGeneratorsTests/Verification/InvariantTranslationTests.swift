//
// InvariantTranslationTests.swift
// ModellingGeneratorsTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import Testing

@testable import ModellingGenerators

/// The translation of the invariants of the lending metamodel to each target.
@Suite("Invariant translation")
struct InvariantTranslationTests {
    /// The expected translation of each invariant, by class and constraint name.
    static let expected: [VerificationTarget: [String: String]] = [
        .alloy: [
            "Member.NonNegativeAge": "all self: Member | self.age >= 0",
            "Loan.OnLoanStatus": "all self: Loan | self.item.status = Status_ON_LOAN",
            "Item.AvailableHasNoLoan":
                "all self: Item | (self.status = Status_AVAILABLE) implies (no self.loan)",
            "ReferenceBook.ReadingRoomOnly": "all self: ReferenceBook | self.status != Status_ON_LOAN",
            "Member.ActiveLoans": "all self: Member | (self.active = True) or (no self.loans)",
            "Member.AgeRestriction":
                "all self: Member | all l: self.loans | (l.item in Restricted) implies (self.age >= l.item.minimumAge)",
            "Library.UniqueBranchCodes":
                "all self: Library | all disj b_1, b_2: self.branches | b_1.code != b_2.code",
        ],
        .tla: [
            "Member.NonNegativeAge": "\\A self \\in Member : obj[self].age >= 0",
            "Loan.OnLoanStatus": "\\A self \\in Loan : obj[obj[self].item].status = \"ON_LOAN\"",
            "Item.AvailableHasNoLoan":
                "\\A self \\in Item : (obj[self].status = \"AVAILABLE\") => (obj[self].loan = Null)",
            "ReferenceBook.ReadingRoomOnly": "\\A self \\in ReferenceBook : obj[self].status # \"ON_LOAN\"",
            "Member.ActiveLoans": "\\A self \\in Member : (obj[self].active) \\/ (obj[self].loans = {})",
            "Member.AgeRestriction":
                "\\A self \\in Member : \\A l \\in obj[self].loans : (obj[l].item \\in Restricted) => (obj[self].age >= obj[obj[l].item].minimumAge)",
            "Library.UniqueBranchCodes":
                "\\A self \\in Library : \\A b_1, b_2 \\in obj[self].branches : (b_1 # b_2) => (obj[b_1].code # obj[b_2].code)",
        ],
        .eventB: [
            "Member.NonNegativeAge": "∀self·self ∈ Member ⇒ (Member_age(self) ≥ 0)",
            "Loan.OnLoanStatus": "∀self·self ∈ Loan ⇒ (Item_status(Loan_item(self)) = Status_ON_LOAN)",
            "Item.AvailableHasNoLoan":
                "∀self·self ∈ Item ⇒ ((Item_status(self) = Status_AVAILABLE) ⇒ (Item_loan[{self}] = ∅))",
            "ReferenceBook.ReadingRoomOnly": "∀self·self ∈ ReferenceBook ⇒ (Item_status(self) ≠ Status_ON_LOAN)",
            "Member.ActiveLoans":
                "∀self·self ∈ Member ⇒ ((Member_active(self) = TRUE) ∨ (Member_loans[{self}] = ∅))",
            "Member.AgeRestriction":
                "∀self·self ∈ Member ⇒ (∀l·l ∈ Member_loans[{self}] ⇒ ((Loan_item(l) ∈ Restricted) ⇒ (Member_age(self) ≥ Restricted_minimumAge(Loan_item(l)))))",
            "Library.UniqueBranchCodes":
                "∀self·self ∈ Library ⇒ (∀b_1, b_2·b_1 ∈ Library_branches[{self}] ∧ b_2 ∈ Library_branches[{self}] ∧ b_1 ≠ b_2 ⇒ (Branch_code(b_1) ≠ Branch_code(b_2)))",
        ],
        .lean: [
            "Member.NonNegativeAge":
                "∀ self ∈ m.instancesOf Obj.isMember, optGe (m.one Obj.Member_age (some self)) (some 0) = true",
            "Loan.OnLoanStatus":
                "∀ self ∈ m.instancesOf Obj.isLoan, optEq (m.one Obj.Item_status (m.one Obj.Loan_item (some self))) (some Status.ON_LOAN) = true",
            "Item.AvailableHasNoLoan":
                "∀ self ∈ m.instancesOf Obj.isItem, (!(optEq (m.one Obj.Item_status (some self)) (some Status.AVAILABLE)) || (m.one Obj.Item_loan (some self)).isNone) = true",
            "ReferenceBook.ReadingRoomOnly":
                "∀ self ∈ m.instancesOf Obj.isReferenceBook, optNe (m.one Obj.Item_status (some self)) (some Status.ON_LOAN) = true",
            "Member.ActiveLoans":
                "∀ self ∈ m.instancesOf Obj.isMember, (optEq (m.one Obj.Member_active (some self)) (some true) || (m.many Obj.Member_loans (some self)).isEmpty) = true",
            "Member.AgeRestriction":
                "∀ self ∈ m.instancesOf Obj.isMember, (m.many Obj.Member_loans (some self)).all (fun l => (!(m.isKindOf Obj.isRestricted (m.one Obj.Loan_item (some l))) || optGe (m.one Obj.Member_age (some self)) (m.one Obj.Restricted_minimumAge (m.one Obj.Loan_item (some l))))) = true",
            "Library.UniqueBranchCodes":
                "∀ self ∈ m.instancesOf Obj.isLibrary, allDistinct ((m.many Obj.Library_branches (some self)).map (fun b => m.one Obj.Branch_code (some b))) = true",
        ],
    ]

    @Test("Each invariant of the lending metamodel translates as expected", arguments: VerificationTarget.allCases)
    func translatesInvariants(target: VerificationTarget) async throws {
        let package = try await LendingFixtures.lendingPackage()
        let translator = InvariantTranslator(packages: [package])
        let expectations = try #require(Self.expected[target])
        for (key, formula) in expectations {
            let parts = key.split(separator: ".").map(String.init)
            let result = translator.translate(className: parts[0], constraint: parts[1], target: target)
            #expect(result == .success(formula), "\(target.rawValue) \(key)")
        }
    }

    @Test("String operations are reported as outside the subset", arguments: VerificationTarget.allCases)
    func rejectsStringOperations(target: VerificationTarget) async throws {
        let translator = InvariantTranslator(packages: [try await LendingFixtures.lendingPackage()])
        let result = translator.translate(className: "Named", constraint: "NonEmptyName", target: target)
        #expect(result == .failure(TranslationError("string operations are not supported")))
    }

    @Test("A missing constraint body is reported")
    func reportsMissingBody() async throws {
        let translator = InvariantTranslator(packages: [try await LendingFixtures.lendingPackage()])
        let result = translator.translate(className: "Member", constraint: "Unknown", target: .alloy)
        #expect(result == .failure(TranslationError("the constraint 'Unknown' has no OCL body")))
    }

    @Test(
        "Constructs outside the subset are reported",
        arguments: [
            ("self.loans->sortedBy(l | l.due)->first() = null", "the operation 'sortedBy' is not supported"),
            ("self.age / 2 > 1", "real division '/' is not supported; use 'div'"),
            ("self.loanCount > 0", "the derived feature 'loanCount' is not exported"),
            ("self.canBorrow()", "the operation 'canBorrow' is not supported"),
            ("self.unknown > 0", "'Member' has no feature 'unknown'"),
            ("self.age", "the invariant does not denote a truth value"),
        ])
    func rejectsUnsupported(text: String, reason: String) async throws {
        let index = MetamodelIndex(packages: [try await LendingFixtures.lendingPackage()])
        #expect(throws: TranslationError(reason)) {
            _ = try OCLTypeChecker(index: index).check(text, context: "Member")
        }
    }

    @Test("Text that is not OCL is reported as unparsable")
    func reportsParseErrors() async throws {
        let index = MetamodelIndex(packages: [try await LendingFixtures.lendingPackage()])
        do {
            _ = try OCLTypeChecker(index: index).check("self.age >", context: "Member")
            Issue.record("the text was accepted")
        } catch let error as TranslationError {
            #expect(error.reason.hasPrefix("the invariant cannot be parsed: "))
        }
    }

    @Test(
        "Further constructs of the subset translate to Alloy",
        arguments: [
            ("self.loans->exists(l | l.due > 7)", "all self: Member | some l: self.loans | l.due > 7"),
            ("self.loans->one(l | l.due > 7)", "all self: Member | one l: self.loans | l.due > 7"),
            ("self.loans->select(l | l.due > 7)->size() <= 2", "all self: Member | #{l: self.loans | l.due > 7} <= 2"),
            ("self.loans->reject(l | l.due > 7)->notEmpty()", "all self: Member | some {l: self.loans | not (l.due > 7)}"),
            ("self.loans.item->includes(self.loans->any(l | true).item) or true", nil),
            ("Member.allInstances()->size() >= 1", "all self: Member | #Member >= 1"),
            ("self.age + 1 > self.age - 1 * 2", "all self: Member | plus[self.age, 1] > minus[self.age, mul[1, 2]]"),
            ("let a = self.age in a >= 0 and not (a > 150)", "all self: Member | (self.age >= 0) and (not (self.age > 150))"),
            ("self.loans->collect(l | l.item)->excludes(self.loans->first())", nil),
            ("if self.active then self.age >= 16 else true endif", "all self: Member | (self.active = True) implies (self.age >= 16) else (none = none)"),
            ("self.age div 2 >= self.age mod 2 and -self.age <= 0", "all self: Member | (div[self.age, 2] >= rem[self.age, 2]) and (minus[0, self.age] <= 0)"),
            ("self.name <> 'x' xor self.active = false", "all self: Member | not ((self.name != \"x\") iff (not (self.active = True)))"),
            ("self.loans->collect(l | l.item)->forAll(i | not i.oclIsUndefined())", "all self: Member | all i: self.loans.item | not (no i)"),
        ] as [(String, String?)])
    func translatesFurtherAlloy(text: String, expected: String?) async throws {
        let package = try await LendingFixtures.lendingPackage()
        let translator = InvariantTranslator(packages: [package])
        let result = translator.translate(text: text, className: "Member", target: .alloy)
        if let expected {
            #expect(result == .success(expected))
        } else {
            #expect(throws: (any Error).self) { try result.get() }
        }
    }

    @Test("Identifiers that are reserved words are made safe")
    func escapesReservedWords() {
        #expect(VerificationTarget.alloy.identifier("sig") == "sig_")
        #expect(VerificationTarget.tla.identifier("Init") == "Init_")
        #expect(VerificationTarget.eventB.identifier("card") == "card_")
        #expect(VerificationTarget.lean.identifier("def") == "«def»")
        #expect(VerificationTarget.lean.identifier("Model") == "Model_")
        #expect(VerificationTarget.alloy.identifier("Library") == "Library")
        #expect(VerificationTarget.tla.literal(enumeration: "Status", literal: "ON_LOAN") == "\"ON_LOAN\"")
        #expect(VerificationTarget.lean.literal(enumeration: "Status", literal: "end") == "Status.«end»")
        #expect(VerificationTarget.alloy.feature(className: "Member", feature: "age") == "age")
    }

    @Test("The invariants of a class are read from its annotations")
    func readsInvariants() async throws {
        let package = try await LendingFixtures.lendingPackage()
        let member = try #require(package.eClassifiers.first { $0.name == "Member" } as? EClass)
        let invariants = InvariantCatalogue.invariants(of: member, in: package)
        #expect(invariants.map(\.name) == ["NonNegativeAge", "AgeRestriction", "ActiveLoans"])
        #expect(invariants.first?.body == "self.age >= 0")
    }
}
