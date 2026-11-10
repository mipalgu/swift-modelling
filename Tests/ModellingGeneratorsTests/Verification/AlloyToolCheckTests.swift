//
// AlloyToolCheckTests.swift
// ModellingGeneratorsTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@testable import ModellingGenerators

/// Runs the Alloy analyser on the Alloy exports, if the Alloy jar is available.
@Suite("Alloy tool checks", .serialized, .enabled(if: VerificationTools.isAvailable(VerificationTools.alloyJar)))
struct AlloyToolCheckTests {
    /// The outcome of each command of a module, by command name.
    private func execute(_ module: String, files: [String: String]) throws -> [String: String] {
        let directory = try VerificationTools.scratchDirectory("alloy")
        try VerificationTools.write(files, to: directory)
        let jar = try #require(VerificationTools.path(VerificationTools.alloyJar))
        let result = try VerificationTools.run(
            VerificationTools.javaPrefix + ["-Duser.home=\(directory.path)", "-jar", jar, "exec", "-f", "-t", "none", "-o", directory.appendingPathComponent("out").path, module],
            in: directory)
        #expect(result.status == 0, "\(result.output)")
        var outcomes: [String: String] = [:]
        for line in result.output.split(separator: "\n") {
            let words = line.split(separator: " ", omittingEmptySubsequences: true)
            guard words.count >= 3, words[0].hasSuffix("."), ["run", "check"].contains(words[1]),
                let outcome = words.last, ["SAT", "UNSAT"].contains(outcome)
            else { continue }
            outcomes[String(words[2])] = String(outcome)
        }
        return outcomes
    }

    /// The metamodel module parses, has an instance that satisfies all invariants, and none of the
    /// invariants is implied by the structure alone.
    @Test("The metamodel module has instances")
    func metamodelHasInstances() async throws {
        let files = try await VerificationExports.metamodel(.alloy)
        let outcomes = try execute("lending.als", files: files)
        #expect(outcomes["instance"] == "SAT")
        #expect(outcomes.count == 8)
        for (name, outcome) in outcomes where name.hasSuffix("_holds") {
            #expect(outcome == "SAT", "\(name) should have a counterexample")
        }
    }

    /// The conforming model has an instance and satisfies every invariant.
    @Test("The conforming model satisfies the metamodel")
    func conformingModel() async throws {
        let files = try await VerificationExports.metamodel(.alloy).merging(try await VerificationExports.model(LendingFixtures.lendingModel, .alloy)) { a, _ in a }
        let outcomes = try execute("lending_instance.als", files: files)
        #expect(outcomes["conforms"] == "SAT")
        #expect(outcomes.count == 8)
        for (name, outcome) in outcomes where name.hasSuffix("_satisfied") {
            #expect(outcome == "UNSAT", "\(name) should hold")
        }
    }

    /// The model with violations conforms to the structure, and exactly the violated invariants
    /// have counterexamples.
    @Test("The violations are found")
    func violatingModel() async throws {
        let files = try await VerificationExports.metamodel(.alloy).merging(try await VerificationExports.model(LendingFixtures.lendingViolations, .alloy)) { a, _ in a }
        let outcomes = try execute("violations_instance.als", files: files)
        #expect(outcomes["conforms"] == "SAT")
        let violated = Set(outcomes.filter { $0.value == "SAT" && $0.key.hasSuffix("_satisfied") }.keys)
        #expect(violated == ["Library_UniqueBranchCodes_satisfied", "Item_AvailableHasNoLoan_satisfied", "Loan_OnLoanStatus_satisfied"])
    }
}
