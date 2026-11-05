//
// TemplateFileOptionTests.swift
// swift-mtl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Checks that `--template` names the template file when its value is an MTL module file.
@Suite("swift-mtl generate - template file given with --template")
struct TemplateFileOptionTests {
    /// Writes a module with two templates, `first` and `second`, that each write a file.
    ///
    /// - Parameter directory: The directory that receives `Greeting.mtl`.
    /// - Returns: The location of the module.
    private func writeModule(in directory: URL) throws -> URL {
        let module = directory.appendingPathComponent("Greeting.mtl")
        try """
        [module Greeting('http://example.com')]
        [template public first()]
        [file ('first.txt')]first[/file]
        [/template]
        [template public second()]
        [file ('second.txt')]second[/file]
        [/template]
        """.write(to: module, atomically: true, encoding: .utf8)
        return module
    }

    @Test("runs the module that --template names when no template file argument is given")
    @MainActor
    func templateOptionNamesFile() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let module = try writeModule(in: scratch)
        let output = scratch.appendingPathComponent("out")

        let result = try await executeSwiftMTL(
            command: "generate", arguments: ["--template", module.path, "--output", output.path])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(
            try String(contentsOf: output.appendingPathComponent("first.txt"), encoding: .utf8) == "first")
        #expect(!FileManager.default.fileExists(atPath: output.appendingPathComponent("second.txt").path))
    }

    @Test("still selects the main template by name with --template after a template file")
    @MainActor
    func templateOptionNamesMainTemplate() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let module = try writeModule(in: scratch)
        let output = scratch.appendingPathComponent("out")

        let result = try await executeSwiftMTL(
            command: "generate", arguments: [module.path, "--template", "second", "--output", output.path])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(
            try String(contentsOf: output.appendingPathComponent("second.txt"), encoding: .utf8) == "second")
    }

    @Test("rejects a template file given both as an argument and with --template")
    @MainActor
    func templateFileGivenTwice() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let module = try writeModule(in: scratch)

        let result = try await executeSwiftMTL(
            command: "generate", arguments: [module.path, "--template", module.path])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("not both"), "\(result.stderr)")
    }

    @Test("rejects a template file given with --template together with --template-set")
    @MainActor
    func templateFileWithTemplateSet() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let module = try writeModule(in: scratch)

        let result = try await executeSwiftMTL(
            command: "generate", arguments: ["--template", module.path, "--template-set", scratch.path])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("not both"), "\(result.stderr)")
    }

    @Test("reports a missing template file that --template names")
    @MainActor
    func missingTemplateFile() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let missing = scratch.appendingPathComponent("Missing.mtl")

        let result = try await executeSwiftMTL(
            command: "generate", arguments: ["--template", missing.path, "--output", scratch.path])

        #expect(!result.succeeded)
        #expect("\(result.stdout)\(result.stderr)".contains("File not found: \(missing.path)"))
    }
}
