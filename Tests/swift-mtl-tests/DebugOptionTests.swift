//
// DebugOptionTests.swift
// swift-mtl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Checks that `--verbose` reports progress only, and that `--debug` adds the parser traces.
///
/// The template and model parsers can trace their work line by line. That trace is a
/// debugging aid for the parsers, not progress information for the user, so it appears only
/// when `--debug` is given.
@Suite("swift-mtl - verbose progress and debug traces")
struct DebugOptionTests {
    /// The prefixes of the lines that the template and model parsers write as their trace.
    static let tracePrefixes = ["[MTLParser]", "[MTLLexer]", "[MTLSyntaxParser]", "[XMI]"]

    /// The text that the XMI parser traces for the root element of an Ecore metamodel.
    static let metamodelTraceMarker = "ecore:EPackage"

    /// Reports whether the output of a command contains a parser trace.
    ///
    /// - Parameter result: The result of running the command.
    /// - Returns: `true` if standard output or standard error contains a trace line.
    private func hasTrace(_ result: SubprocessResult) -> Bool {
        let output = result.stdout + result.stderr
        return Self.tracePrefixes.contains { output.contains($0) }
    }

    /// Runs `generate` with a template that takes a company and a model of a company.
    ///
    /// - Parameter flags: The flags that select the output, such as `--verbose` or `--debug`.
    /// - Returns: The result of running the command.
    @MainActor
    private func generateWithModel(_ flags: [String]) async throws -> SubprocessResult {
        let template = try loadTestResource(named: "with-model-param.mtl", subdirectory: "templates")
        let model = try loadTestResource(named: "simple-model.xmi", subdirectory: "models")
        let output = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(output) }
        return try await executeSwiftMTL(
            command: "generate",
            arguments: [template.path, "--model", model.path, "--output", output.path] + flags)
    }

    /// Runs `generate` with a template without parameters and a registered metamodel.
    ///
    /// - Parameter flags: The flags that select the output, such as `--verbose` or `--debug`.
    /// - Returns: The result of running the command.
    @MainActor
    private func generateWithMetamodel(_ flags: [String]) async throws -> SubprocessResult {
        let template = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")
        let metamodel = try loadTestResource(named: "company.ecore", subdirectory: "models")
        let output = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(output) }
        return try await executeSwiftMTL(
            command: "generate",
            arguments: [template.path, "--metamodel", metamodel.path, "--output", output.path] + flags)
    }

    /// Runs a command that reads a single template without a model.
    ///
    /// - Parameters:
    ///   - command: The command, `parse` or `validate`.
    ///   - flags: The flags that select the output, such as `--verbose` or `--debug`.
    /// - Returns: The result of running the command.
    @MainActor
    private func readTemplate(_ command: String, _ flags: [String]) async throws -> SubprocessResult {
        let template = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")
        return try await executeSwiftMTL(command: command, arguments: [template.path] + flags)
    }

    @Test("generate --verbose reports progress without parser traces")
    @MainActor
    func generateVerboseHasNoTrace() async throws {
        let result = try await generateWithModel(["--verbose"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.contains("Successfully parsed MTL module: CompanyReport"), "\(result.stdout)")
        #expect(result.stdout.contains("Loading input model 1:"), "\(result.stdout)")
        #expect(result.stdout.contains("Generation successful"), "\(result.stdout)")
        #expect(!hasTrace(result), "\(result.stdout)\(result.stderr)")
    }

    @Test("generate --debug traces the template and model parsers")
    @MainActor
    func generateDebugHasTrace() async throws {
        let result = try await generateWithModel(["--debug"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.contains("[MTLParser]"), "\(result.stdout)")
        #expect(result.stdout.contains("[XMI]"), "\(result.stdout)")
    }

    @Test("generate --debug --verbose reports progress as well as the traces")
    @MainActor
    func generateDebugAndVerbose() async throws {
        let result = try await generateWithModel(["--debug", "--verbose"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.contains("Successfully parsed MTL module: CompanyReport"), "\(result.stdout)")
        #expect(hasTrace(result), "\(result.stdout)")
    }

    @Test("generate --verbose registers a metamodel without tracing its parser")
    @MainActor
    func metamodelVerboseHasNoTrace() async throws {
        let result = try await generateWithMetamodel(["--verbose"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.contains("Registered metamodel 'company'"), "\(result.stdout)")
        #expect(!hasTrace(result), "\(result.stdout)\(result.stderr)")
    }

    @Test("generate --debug traces the parser of a registered metamodel")
    @MainActor
    func metamodelDebugHasTrace() async throws {
        let result = try await generateWithMetamodel(["--debug"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.contains("[XMI]"), "\(result.stdout)")
        #expect(result.stdout.contains(Self.metamodelTraceMarker), "\(result.stdout)")
    }

    @Test("parse and validate with --verbose report progress without parser traces", arguments: ["parse", "validate"])
    @MainActor
    func readVerboseHasNoTrace(command: String) async throws {
        let result = try await readTemplate(command, ["--verbose"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.contains("simple-hello.mtl"), "\(result.stdout)")
        #expect(!hasTrace(result), "\(result.stdout)\(result.stderr)")
    }

    @Test("parse and validate with --debug trace the template parser", arguments: ["parse", "validate"])
    @MainActor
    func readDebugHasTrace(command: String) async throws {
        let result = try await readTemplate(command, ["--debug"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.contains("[MTLParser]"), "\(result.stdout)")
    }

    @Test("parse and validate without flags print no parser traces", arguments: ["parse", "validate"])
    @MainActor
    func readQuietHasNoTrace(command: String) async throws {
        let result = try await readTemplate(command, [])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(!hasTrace(result), "\(result.stdout)\(result.stderr)")
    }
}
