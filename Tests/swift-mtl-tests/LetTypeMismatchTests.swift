//
// LetTypeMismatchTests.swift
// swift-mtl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for `swift-mtl generate --let-type-mismatches`, which chooses whether a typed `let`
/// whose value does not conform to the declared type is an error or a skipped block.
@Suite("swift-mtl generate - typed let mismatches", .serialized)
struct LetTypeMismatchTests {
    /// The long name of the option.
    private static let option = "--let-type-mismatches"

    /// The text that starts the line of a warning on standard error.
    private static let warningPrefix = "warning: "

    /// A template whose typed let binds a string to an integer variable.
    private static let template = """
        [module Mismatch('http://www.example.org/mismatch')]

        [template main()]
        [file ('result.txt', 'overwrite', 'UTF-8')]
        before[let n : Integer = 'text']inside[n/][/let]after
        [/file]
        [/template]
        """

    /// Writes a text file, creating its directory.
    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Generates with the mismatching template and extra arguments.
    ///
    /// - Parameter extra: The arguments after the template and output directory.
    /// - Returns: The result of the command and the generated text, if any.
    @MainActor
    private func generate(_ extra: [String]) async throws -> (result: SubprocessResult, text: String?) {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let template = scratch.appendingPathComponent("Mismatch.mtl")
        let output = scratch.appendingPathComponent("out")
        try write(Self.template, to: template)

        let result = try await executeSwiftMTL(
            command: "generate", arguments: [template.path, "--output", output.path] + extra)
        let text = try? String(contentsOf: output.appendingPathComponent("result.txt"), encoding: .utf8)
        return (result, text)
    }

    /// The lines of standard error that report warnings.
    private func warnings(in result: SubprocessResult) -> [Substring] {
        result.stderr.split(whereSeparator: \.isNewline).filter { $0.hasPrefix(Self.warningPrefix) }
    }

    @Test("fails on a mismatch by default, naming the variable and the types")
    @MainActor
    func defaultFails() async throws {
        let (result, text) = try await generate([])

        #expect(!result.succeeded)
        let message = result.stdout + result.stderr
        #expect(message.contains("'n'"), "\(message)")
        #expect(message.contains("Integer"))
        #expect(text?.contains("inside") != true)
        #expect(warnings(in: result).isEmpty)
    }

    @Test("fails on a mismatch with --let-type-mismatches error")
    @MainActor
    func explicitError() async throws {
        let (result, text) = try await generate([Self.option, "error"])

        #expect(!result.succeeded)
        #expect(text?.contains("inside") != true)
    }

    @Test("skips the let block and warns on standard error with --let-type-mismatches skip")
    @MainActor
    func skipWarns() async throws {
        let (result, text) = try await generate([Self.option, "skip"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text?.contains("beforeafter") == true, "\(text ?? "no output")")
        #expect(text?.contains("inside") == false)
        let lines = warnings(in: result)
        #expect(lines.count == 1, "\(result.stderr)")
        let line = String(lines.first ?? "")
        #expect(line.contains("'n'"))
        #expect(line.contains("Integer"))
        #expect(line.contains("String"))
        #expect(!result.stdout.contains(Self.warningPrefix))
    }

    @Test("skips the let block of a template set and warns on standard error")
    @MainActor
    func templateSetSkips() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let set = scratch.appendingPathComponent("sets/mismatch")
        try write(
            """
            { "name": "mismatch", "mainModule": "Mismatch", "mainTemplate": "main" }
            """, to: set.appendingPathComponent("templateset.json"))
        try write(Self.template, to: set.appendingPathComponent("Mismatch.mtl"))
        let output = scratch.appendingPathComponent("out")

        let skipped = try await executeSwiftMTL(
            command: "generate", arguments: ["--template-set", set.path, "--output", output.path, Self.option, "skip"])

        #expect(skipped.succeeded, "\(skipped.stdout)\(skipped.stderr)")
        let text = try String(contentsOf: output.appendingPathComponent("result.txt"), encoding: .utf8)
        #expect(text.contains("beforeafter"))
        #expect(warnings(in: skipped).count == 1, "\(skipped.stderr)")

        let failed = try await executeSwiftMTL(
            command: "generate", arguments: ["--template-set", set.path, "--output", output.path])
        #expect(!failed.succeeded)
        #expect(warnings(in: failed).isEmpty)
    }

    @Test("rejects a value that is not a mode")
    @MainActor
    func rejectsUnknownMode() async throws {
        let (result, _) = try await generate([Self.option, "sometimes"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("sometimes"))
    }

    @Test("describes the option and its values in the help")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftMTL(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains(Self.option))
        #expect(result.stdout.contains("error|skip"))
        #expect(result.stdout.contains("Acceleo"))
        #expect(result.stdout.contains("standard error"))
    }
}
