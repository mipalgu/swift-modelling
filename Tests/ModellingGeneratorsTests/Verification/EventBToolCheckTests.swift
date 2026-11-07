//
// EventBToolCheckTests.swift
// ModellingGeneratorsTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@testable import ModellingGenerators

/// Checks the Event-B exports with the Rodin formula library, if its jar is available.
///
/// The checker in the test resources reads the CamilleX text of the exported contexts and
/// machines, and parses and type-checks every axiom, invariant and action the way the static
/// checker of Rodin does. For the models, it also evaluates the invariants of the machine on the
/// values that its initialisation assigns, which decides the invariant proof obligations of the
/// initialisation.
@Suite("Event-B tool checks", .serialized, .enabled(if: VerificationTools.isAvailable(VerificationTools.eventBJar)))
struct EventBToolCheckTests {
    /// The environment variable that names the Java compiler, `javac` on the search path by default.
    static let javac = "JAVAC"

    /// The labels of the invariants that the model with violations violates.
    static let expectedViolations: Set<String> = [
        "Library_UniqueBranchCodes", "Item_AvailableHasNoLoan", "Loan_OnLoanStatus",
    ]

    /// The outcome of a run of the checker.
    struct Outcome {
        /// The exit status of the checker.
        let status: Int32
        /// The lines that the checker printed.
        let lines: [String]

        /// The labels of the formulas that the checker reports with a verdict, such as `holds`.
        ///
        /// - Parameters:
        ///   - verdict: The first word of the line: `holds`, `violated` or `undefined`.
        ///   - kind: The kind of formula: `axiom` or `invariant`.
        /// - Returns: The labels; axioms are qualified by their context.
        func labels(_ verdict: String, _ kind: String) -> Set<String> {
            Set(lines.compactMap { line in
                let prefix = verdict + " " + kind + " "
                guard line.hasPrefix(prefix) else { return nil }
                return String(line.dropFirst(prefix.count).prefix { $0 != ":" })
            })
        }
    }

    /// Compiles the checker and runs it on exported files.
    ///
    /// - Parameters:
    ///   - files: The exported files, by relative path.
    ///   - machine: The machine to evaluate, if any.
    /// - Returns: The outcome.
    private func check(_ files: [String: String], evaluating machine: String? = nil) throws -> Outcome {
        let directory = try VerificationTools.scratchDirectory("eventb")
        try VerificationTools.write(files, to: directory)
        let jar = try #require(VerificationTools.path(VerificationTools.eventBJar))
        let source = LendingFixtures.lendingDirectory.deletingLastPathComponent()
            .appendingPathComponent("eventb-checker").appendingPathComponent("EventBChecker.java")
        let classes = directory.appendingPathComponent("classes")
        let compiler = ProcessInfo.processInfo.environment[Self.javac] ?? "javac"
        let compiled = try VerificationTools.run([compiler, "-cp", jar, "-d", classes.path, source.path], in: directory)
        try #require(compiled.status == 0, "\(compiled.output)")
        let names = files.keys.map { ($0 as NSString).lastPathComponent }.sorted()
        let arguments = (machine.map { ["--evaluate", $0] } ?? []) + names
        let result = try VerificationTools.run(
            VerificationTools.javaPrefix + ["-cp", jar + ":" + classes.path, "EventBChecker"] + arguments, in: directory)
        return Outcome(status: result.status, lines: result.output.split(separator: "\n").map(String.init))
    }

    /// The exports of the metamodel and of a model, in one set of files.
    private func exports(of model: URL) async throws -> [String: String] {
        try await VerificationExports.metamodel(.eventB).merging(try await VerificationExports.model(model, .eventB)) { a, _ in a }
    }

    /// The context and machine of the metamodel parse and type-check.
    @Test("The metamodel components type-check")
    func metamodelTypeChecks() async throws {
        let outcome = try check(try await VerificationExports.metamodel(.eventB))
        #expect(outcome.status == 0, "\(outcome.lines.joined(separator: "\n"))")
        #expect(outcome.lines.contains { $0.hasPrefix("checked context lending_ctx:") })
        #expect(outcome.lines.contains { $0.hasPrefix("checked machine lending_machine:") })
    }

    /// The components of the conforming model type-check, the values satisfy the axioms of both
    /// contexts, and every invariant holds after the initialisation.
    @Test("The conforming model satisfies the metamodel")
    func conformingModel() async throws {
        let outcome = try check(try await exports(of: LendingFixtures.lendingModel), evaluating: "lending_instance_machine")
        #expect(outcome.status == 0, "\(outcome.lines.joined(separator: "\n"))")
        #expect(outcome.lines.contains { $0.hasPrefix("checked context lending_instance_ctx:") })
        #expect(outcome.lines.contains { $0.hasPrefix("checked machine lending_instance_machine:") })
        #expect(outcome.labels("violated", "axiom").isEmpty)
        #expect(outcome.labels("undefined", "axiom").isEmpty)
        #expect(outcome.labels("violated", "invariant").isEmpty)
        #expect(outcome.labels("undefined", "invariant").isEmpty)
        #expect(outcome.labels("holds", "invariant").isSuperset(of: Self.expectedViolations))
    }

    /// The model with violations satisfies the axioms and the structure of the metamodel, and
    /// violates exactly the expected invariants.
    @Test("The violations are found")
    func violatingModel() async throws {
        let outcome = try check(
            try await exports(of: LendingFixtures.lendingViolations), evaluating: "violations_instance_machine")
        #expect(outcome.status == 0, "\(outcome.lines.joined(separator: "\n"))")
        #expect(outcome.labels("violated", "axiom").isEmpty)
        #expect(outcome.labels("undefined", "axiom").isEmpty)
        #expect(outcome.labels("undefined", "invariant").isEmpty)
        #expect(outcome.labels("violated", "invariant") == Self.expectedViolations)
    }
}
