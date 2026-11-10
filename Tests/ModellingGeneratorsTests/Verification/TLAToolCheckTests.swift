//
// TLAToolCheckTests.swift
// ModellingGeneratorsTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@testable import ModellingGenerators

/// Runs SANY and TLC on the TLA+ exports, if the TLA+ tools jar is available.
///
/// SANY parses the module of the metamodel, which cannot be model checked by itself, and TLC
/// checks the module of each model with the configuration exported beside it. TLC runs with
/// `-continue`, so that it reports every violated invariant of the single state of a model.
@Suite("TLA+ tool checks", .serialized, .enabled(if: VerificationTools.isAvailable(VerificationTools.tlaToolsJar)))
struct TLAToolCheckTests {
    /// The prefix of the lines in which TLC reports a violated invariant.
    private static let violationPrefix = "Error: Invariant "

    /// The text that follows the name of a violated invariant.
    private static let violationSuffix = " is violated"

    /// The word with which SANY reports parse and semantic errors, in any case.
    private static let errorMarker = "error"

    /// The line in which TLC reports that the state space was explored completely.
    private static let completion = "distinct states found"

    /// The invariants that every exported model configuration checks for the structure of the
    /// metamodel.
    private static let structuralInvariants: Set<String> = ["TypeOK", "Multiplicities", "Opposites", "Containment"]

    /// The invariants that the violations model does not satisfy.
    private static let violatedByViolations: Set<String> = [
        "Inv_Library_UniqueBranchCodes", "Inv_Item_AvailableHasNoLoan", "Inv_Loan_OnLoanStatus",
    ]

    /// Runs SANY on a module.
    ///
    /// - Parameters:
    ///   - module: The file name of the module.
    ///   - files: The exported files, by relative path.
    /// - Returns: The exit status and output of SANY.
    private func parse(_ module: String, files: [String: String]) throws -> (status: Int32, output: String) {
        let directory = try VerificationTools.scratchDirectory("tla")
        try VerificationTools.write(files, to: directory)
        let jar = try #require(VerificationTools.path(VerificationTools.tlaToolsJar))
        return try VerificationTools.run(VerificationTools.javaPrefix + ["-cp", jar, "tla2sany.SANY", module], in: directory)
    }

    /// Runs TLC on a model module with its exported configuration.
    ///
    /// - Parameters:
    ///   - model: The name of the model module, without extension.
    ///   - files: The exported files, by relative path.
    /// - Returns: The names of the invariants that TLC reports as violated.
    private func check(_ model: String, files: [String: String]) throws -> Set<String> {
        let directory = try VerificationTools.scratchDirectory("tla")
        try VerificationTools.write(files, to: directory)
        let jar = try #require(VerificationTools.path(VerificationTools.tlaToolsJar))
        let result = try VerificationTools.run(
            VerificationTools.javaPrefix + [
                "-XX:+UseParallelGC", "-cp", jar, "tlc2.TLC", "-workers", "1", "-deadlock", "-continue",
                "-metadir", directory.appendingPathComponent("states").path,
                "-config", model + ".cfg", model + ".tla",
            ],
            in: directory)
        #expect(result.status == 0, "\(result.output)")
        #expect(result.output.contains(Self.completion), "\(result.output)")
        var violated: Set<String> = []
        for line in result.output.split(separator: "\n").map(String.init) where line.hasPrefix("Error:") {
            guard line.hasPrefix(Self.violationPrefix), let end = line.range(of: Self.violationSuffix) else {
                Issue.record("TLC reported an error that is not a violated invariant: \(line)")
                continue
            }
            violated.insert(String(line[line.index(line.startIndex, offsetBy: Self.violationPrefix.count)..<end.lowerBound]))
        }
        return violated
    }

    /// The exports of the metamodel together with the exports of a model.
    ///
    /// - Parameter model: The model.
    /// - Returns: The files of both exports, by relative path.
    private func exports(of model: URL) async throws -> [String: String] {
        try await VerificationExports.metamodel(.tla).merging(try await VerificationExports.model(model, .tla)) { a, _ in a }
    }

    /// The module of the metamodel parses.
    @Test("SANY parses the metamodel module")
    func metamodelParses() async throws {
        let result = try parse("lending.tla", files: try await VerificationExports.metamodel(.tla))
        #expect(result.status == 0, "\(result.output)")
        #expect(!result.output.localizedCaseInsensitiveContains(Self.errorMarker), "\(result.output)")
    }

    /// The modules of both models parse.
    @Test("SANY parses the model modules", arguments: [LendingFixtures.lendingModel, LendingFixtures.lendingViolations])
    func modelParses(model: URL) async throws {
        let name = model.deletingPathExtension().lastPathComponent + "_instance"
        let result = try parse(name + ".tla", files: try await exports(of: model))
        #expect(result.status == 0, "\(result.output)")
        #expect(!result.output.localizedCaseInsensitiveContains(Self.errorMarker), "\(result.output)")
    }

    /// The conforming model satisfies the structure of the metamodel and every invariant.
    @Test("TLC finds no error in the conforming model")
    func conformingModel() async throws {
        let violated = try check("lending_instance", files: try await exports(of: LendingFixtures.lendingModel))
        #expect(violated.isEmpty)
    }

    /// The model with violations satisfies the structure of the metamodel, and exactly the
    /// invariants that it violates are reported.
    @Test("TLC reports exactly the violated invariants")
    func violatingModel() async throws {
        let violated = try check("violations_instance", files: try await exports(of: LendingFixtures.lendingViolations))
        #expect(violated.isDisjoint(with: Self.structuralInvariants))
        #expect(violated == Self.violatedByViolations)
    }

    /// A model in which a member has more loans than the metamodel allows violates only the
    /// multiplicities of the metamodel.
    @Test("TLC reports a violated multiplicity")
    func excessLoans() async throws {
        let periodicals = (3...5).map {
            "  <items xsi:type=\"lending:Periodical\" name=\"Issue \($0)\" status=\"ON_LOAN\" issue=\"\($0)\"/>\n"
        }
        let loans = [1, 3, 4, 5].map { "<loans item=\"//@items.\($0)\" due=\"14\"/>" }
        let model = try TLAVariantModels.write(
            "loans",
            replacing: [
                ("<loans item=\"//@items.1\" due=\"14\"/>", loans.joined()),
                ("</lending:Library>", periodicals.joined() + "</lending:Library>"),
            ])
        let violated = try check("loans_instance", files: try await exports(of: model))
        #expect(violated == ["Multiplicities"], "\(violated)")
    }

    /// A model with a value of a data type that the export does not interpret is checked with
    /// that value.
    @Test("TLC checks models with uninterpreted values")
    func uninterpretedValues() async throws {
        let model = try TLAVariantModels.write("rated", replacing: [("pages=\"320\"", "pages=\"320\" rating=\"4.5\"")])
        let violated = try check("rated_instance", files: try await exports(of: model))
        #expect(violated.isEmpty)
    }
}

/// Variants of the conforming lending model, written to scratch directories.
enum TLAVariantModels {
    /// Writes a variant of the conforming lending model.
    ///
    /// The variant is the text of the conforming model with passages replaced in turn; each
    /// passage must occur in the model.
    ///
    /// - Parameters:
    ///   - name: The name of the model file, without extension.
    ///   - replacements: Each passage to replace, with the text that replaces it.
    /// - Returns: The location of the variant, in a new scratch directory.
    /// - Throws: An error if a passage does not occur or the variant cannot be written.
    static func write(_ name: String, replacing replacements: [(passage: String, replacement: String)]) throws -> URL {
        var text = try String(contentsOf: LendingFixtures.lendingModel, encoding: .utf8)
        for (passage, replacement) in replacements {
            guard text.contains(passage) else { throw CocoaError(.fileReadCorruptFile) }
            text = text.replacingOccurrences(of: passage, with: replacement)
        }
        let directory = try VerificationTools.scratchDirectory("tla-model")
        let url = directory.appendingPathComponent(name + ".xmi")
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
