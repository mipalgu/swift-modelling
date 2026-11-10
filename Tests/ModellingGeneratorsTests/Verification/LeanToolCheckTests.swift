//
// LeanToolCheckTests.swift
// ModellingGeneratorsTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@testable import ModellingGenerators

/// Elaborates the Lean exports with a Lean 4 toolchain, if the `lean` executable is available.
///
/// The metamodel module is compiled to an object file in a scratch directory, and a model module
/// is then elaborated with that directory on the Lean search path. A theorem of a model module
/// elaborates exactly if `decide` proves it, so the theorems that Lean reports as errors are the
/// violated conditions.
@Suite("Lean tool checks", .serialized, .enabled(if: VerificationTools.isAvailable(VerificationTools.lean)))
struct LeanToolCheckTests {
    /// The environment variable that tells Lean where to find imported modules.
    static let searchPathVariable = "LEAN_PATH"

    /// The extension of Lean source files.
    static let sourceExtension = "lean"

    /// The extension of compiled Lean modules.
    static let objectExtension = "olean"

    /// The result of elaborating a model module.
    struct Elaboration {
        /// The exit status of Lean for the model module.
        var status: Int32
        /// The diagnostics that Lean wrote.
        var output: String
        /// The lines of the model module at which Lean reported errors.
        var errorLines: Set<Int>
        /// The names of the theorems declared on those lines.
        var failedTheorems: Set<String>
    }

    /// Compiles the metamodel module of the lending metamodel into a directory.
    ///
    /// - Parameter directory: The scratch directory that receives the source and object files.
    /// - Returns: The exit status and diagnostics of Lean.
    private func compileMetamodel(in directory: URL) async throws -> (status: Int32, output: String) {
        let files = try await VerificationExports.metamodel(.lean)
        try VerificationTools.write(files, to: directory)
        let source = try #require(files.keys.first { $0.hasSuffix("." + Self.sourceExtension) })
        let name = ((source as NSString).lastPathComponent as NSString).deletingPathExtension
        let lean = try #require(VerificationTools.path(VerificationTools.lean))
        return try VerificationTools.run(
            [lean, "-o", directory.appendingPathComponent(name + "." + Self.objectExtension).path, source],
            in: directory)
    }

    /// Compiles the metamodel module and elaborates the module of a model against it.
    ///
    /// - Parameter model: The model to export.
    /// - Returns: The outcome of elaborating the model module.
    private func elaborate(_ model: URL) async throws -> Elaboration {
        let directory = try VerificationTools.scratchDirectory("lean")
        let metamodel = try await compileMetamodel(in: directory)
        #expect(metamodel.status == 0, "\(metamodel.output)")
        let files = try await VerificationExports.model(model, .lean)
        try VerificationTools.write(files, to: directory)
        let (path, text) = try #require(files.first)
        let source = (path as NSString).lastPathComponent
        let lean = try #require(VerificationTools.path(VerificationTools.lean))
        let result = try VerificationTools.run(
            [lean, source], in: directory, environment: [Self.searchPathVariable: directory.path])
        let errorLines = Self.errorLines(in: result.output, file: source)
        let lines = text.components(separatedBy: "\n")
        let theorems = errorLines.compactMap { line -> String? in
            guard line >= 1, line <= lines.count else { return nil }
            return Self.theoremName(in: lines[line - 1])
        }
        return Elaboration(
            status: result.status, output: result.output, errorLines: errorLines, failedTheorems: Set(theorems))
    }

    /// The lines of a file at which Lean reported errors.
    ///
    /// Lean reports an error as `File.lean:line:column: error: message`.
    ///
    /// - Parameters:
    ///   - output: The diagnostics of Lean.
    ///   - file: The name of the file.
    /// - Returns: The line numbers, starting at 1.
    static func errorLines(in output: String, file: String) -> Set<Int> {
        var lines: Set<Int> = []
        for diagnostic in output.split(separator: "\n") where diagnostic.hasPrefix(file + ":") {
            let parts = diagnostic.dropFirst(file.count + 1).split(separator: ":", maxSplits: 3)
            guard parts.count == 4, parts[2].trimmingCharacters(in: .whitespaces) == "error",
                let line = Int(parts[0])
            else { continue }
            lines.insert(line)
        }
        return lines
    }

    /// The name of the theorem that a line declares.
    ///
    /// - Parameter line: A line of a Lean module.
    /// - Returns: The name, or `nil` if the line does not declare a theorem.
    static func theoremName(in line: String) -> String? {
        let words = line.split(separator: " ", omittingEmptySubsequences: true)
        guard words.count >= 2, words[0] == "theorem" else { return nil }
        return String(words[1])
    }

    /// The metamodel module elaborates without errors.
    @Test("The metamodel module elaborates")
    func metamodelElaborates() async throws {
        let directory = try VerificationTools.scratchDirectory("lean")
        let result = try await compileMetamodel(in: directory)
        #expect(result.status == 0, "\(result.output)")
        #expect(!result.output.contains(": error"), "\(result.output)")
    }

    /// The conforming model is well formed and satisfies every invariant.
    @Test("The conforming model satisfies the metamodel")
    func conformingModel() async throws {
        let elaboration = try await elaborate(LendingFixtures.lendingModel)
        #expect(elaboration.status == 0, "\(elaboration.output)")
        #expect(elaboration.errorLines.isEmpty, "\(elaboration.output)")
    }

    /// The model with violations is well formed, and exactly the theorems of the violated
    /// invariants fail.
    @Test("The violations are found")
    func violatingModel() async throws {
        let elaboration = try await elaborate(LendingFixtures.lendingViolations)
        #expect(elaboration.status != 0)
        #expect(elaboration.errorLines.count == elaboration.failedTheorems.count, "\(elaboration.output)")
        #expect(
            elaboration.failedTheorems
                == ["Library_UniqueBranchCodes_holds", "Item_AvailableHasNoLoan_holds", "Loan_OnLoanStatus_holds"],
            "\(elaboration.output)")
    }
}
