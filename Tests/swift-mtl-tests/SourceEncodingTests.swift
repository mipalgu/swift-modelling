//
// SourceEncodingTests.swift
// swift-mtl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for the character encoding in which the commands of `swift-mtl` read templates.
///
/// A template or imported module that is not valid UTF-8 is read as ISO-8859-1 with a warning
/// on standard error; `--encoding`, and for `generate` the `encoding` key of the configuration
/// file, name the encoding instead.
@Suite("swift-mtl - source encodings", .serialized)
struct SourceEncodingTests {
    /// The main module, which imports ``library``.
    static let main = """
        [module Encoded('http://www.eclipse.org/emf/2002/Ecore')]
        [import Library/]

        [template public main(p : ecore::EPackage)]
        [file ('result.txt', 'overwrite', 'UTF-8')]
        Café [greeting()/]
        [/file]
        [/template]

        """

    /// The imported module.
    static let library = """
        [module Library('http://www.eclipse.org/emf/2002/Ecore')]
        [template public greeting()]Grüße[/template]

        """

    /// What the main template writes, in UTF-8.
    static let expected = "Café Grüße\n"

    /// The warning that a file was read as ISO-8859-1.
    static let fallbackWarning = "The text is not valid UTF-8 and was read as ISO-8859-1"

    /// Encodes text in ISO-8859-1.
    ///
    /// - Parameter text: Text whose characters are all below U+0100.
    /// - Returns: One byte per character.
    static func latin1(_ text: String) -> Data {
        Data(text.unicodeScalars.map { UInt8($0.value) })
    }

    /// A repository with the probe model of ``ConfigurationTests`` and the two modules.
    struct Workspace {
        /// The repository of ``ConfigurationTests``.
        let base: ConfigurationTests.Workspace

        /// The main module.
        var template: URL { base.root.appendingPathComponent("Encoded.mtl") }

        /// The imported module.
        var importedModule: URL { base.root.appendingPathComponent("Library.mtl") }

        /// Creates the repository with the modules in ISO-8859-1 or UTF-8.
        ///
        /// - Parameter utf8: Whether the modules are written in UTF-8.
        init(utf8: Bool = false) throws {
            base = try ConfigurationTests.Workspace()
            let encode = utf8 ? { Data($0.utf8) } : SourceEncodingTests.latin1
            try encode(SourceEncodingTests.main).write(to: template)
            try encode(SourceEncodingTests.library).write(to: importedModule)
        }

        /// Runs a command on the main module from the working directory.
        ///
        /// - Parameters:
        ///   - command: `generate`, `parse` or `validate`.
        ///   - extra: The options after the arguments.
        /// - Returns: The result of the command and the generated text, if any.
        @MainActor
        func run(_ command: String, _ extra: [String] = []) async throws -> (result: SubprocessResult, text: String?) {
            try? FileManager.default.removeItem(at: base.output)
            var arguments = [template.path]
            if command == "generate" {
                arguments += ["--model", base.root.appendingPathComponent("lib.ecore").path, "--output", base.output.path]
            }
            let result = try await executeSwiftMTL(
                command: command, arguments: arguments + extra, workingDirectory: base.workingDirectory)
            let text = try? String(contentsOf: base.output.appendingPathComponent("result.txt"), encoding: .utf8)
            return (result, text)
        }

        /// Removes the repository.
        func remove() { base.remove() }
    }

    @Test("reads templates that are not UTF-8 as ISO-8859-1, with a warning for each file", arguments: ["generate", "parse", "validate"])
    @MainActor
    func latin1Fallback(command: String) async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (result, text) = try await workspace.run(command)

        #expect(result.succeeded, "\(command): \(result.stdout)\(result.stderr)")
        if command == "generate" { #expect(text == Self.expected) }
        for file in [workspace.template, workspace.importedModule] {
            #expect(
                result.stderr.contains("warning: \(file.path): line "), "\(command): \(file.lastPathComponent): \(result.stderr)")
        }
        #expect(result.stderr.contains(Self.fallbackWarning), "\(command): \(result.stderr)")
    }

    @Test("reads UTF-8 templates without a warning", arguments: ["generate", "parse", "validate"])
    @MainActor
    func utf8(command: String) async throws {
        let workspace = try Workspace(utf8: true)
        defer { workspace.remove() }

        let (result, text) = try await workspace.run(command)

        #expect(result.succeeded, "\(command): \(result.stdout)\(result.stderr)")
        if command == "generate" { #expect(text == Self.expected) }
        #expect(!result.stderr.contains("warning:"), "\(command): \(result.stderr)")
    }

    @Test("reads the encoding given with --encoding without a warning", arguments: ["generate", "parse", "validate"])
    @MainActor
    func explicitEncoding(command: String) async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (result, text) = try await workspace.run(command, ["--encoding", "latin1"])

        #expect(result.succeeded, "\(command): \(result.stdout)\(result.stderr)")
        if command == "generate" { #expect(text == Self.expected) }
        #expect(!result.stderr.contains(Self.fallbackWarning), "\(command): \(result.stderr)")
    }

    @Test("rejects templates that are not valid in the encoding given", arguments: ["generate", "parse", "validate"])
    @MainActor
    func malformed(command: String) async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (result, _) = try await workspace.run(command, ["--encoding", "UTF-8"])

        let output = result.stdout + result.stderr
        #expect(output.contains("not valid UTF-8"), "\(command): \(output)")
        #expect(output.contains(workspace.template.lastPathComponent), "\(command): \(output)")
        if command != "parse" { #expect(!result.succeeded, "\(command): \(output)") }
    }

    @Test("generate reads the encoding of the configuration file, which --encoding overrides")
    @MainActor
    func configuredEncoding() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.base.write(#"{ "encoding": "ISO-8859-1" }"#)

        let configured = try await workspace.run("generate")
        let overridden = try await workspace.run("generate", ["--encoding", "UTF-8"])

        #expect(configured.result.succeeded, "\(configured.result.stdout)\(configured.result.stderr)")
        #expect(configured.text == Self.expected)
        #expect(!configured.result.stderr.contains(Self.fallbackWarning), "\(configured.result.stderr)")
        #expect(!overridden.result.succeeded)
        #expect((overridden.result.stdout + overridden.result.stderr).contains("not valid UTF-8"))
    }

    /// Writes a template set whose main module, in ISO-8859-1, imports ``library`` and writes
    /// ``expected`` to `result.txt`.
    ///
    /// - Parameter workspace: The repository that receives the set below its root.
    /// - Returns: The directory of the set.
    static func writeLatin1Set(in workspace: Workspace) throws -> URL {
        let set = workspace.base.root.appendingPathComponent("sets/encoded")
        try FileManager.default.createDirectory(at: set, withIntermediateDirectories: true)
        try Data(#"{ "name": "encoded", "mainModule": "Encoded", "mainTemplate": "main" }"#.utf8)
            .write(to: set.appendingPathComponent("templateset.json"))
        try latin1(main).write(to: set.appendingPathComponent("Encoded.mtl"))
        try latin1(library).write(to: set.appendingPathComponent("Library.mtl"))
        return set
    }

    /// Runs `generate` with the template set of ``writeLatin1Set(in:)``.
    @MainActor
    private func generateSet(_ extra: [String]) async throws -> (result: SubprocessResult, text: String?) {
        let workspace = try Workspace(utf8: true)
        defer { workspace.remove() }
        let set = try Self.writeLatin1Set(in: workspace)
        let output = workspace.base.output
        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                "--template-set", set.path, "--model", workspace.base.root.appendingPathComponent("lib.ecore").path,
                "--output", output.path,
            ] + extra,
            workingDirectory: workspace.base.workingDirectory)
        let text = try? String(contentsOf: output.appendingPathComponent("result.txt"), encoding: .utf8)
        return (result, text)
    }

    @Test("reads the templates of a set that are not UTF-8 as ISO-8859-1, naming each in the set")
    @MainActor
    func templateSetFallback() async throws {
        let (result, text) = try await generateSet([])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text == Self.expected)
        for file in ["Encoded.mtl", "Library.mtl"] {
            #expect(result.stderr.contains("warning: \(file): line "), "\(file): \(result.stderr)")
        }
        #expect(result.stderr.contains(Self.fallbackWarning), "\(result.stderr)")
    }

    @Test("reads the templates of a set in the encoding given with --encoding")
    @MainActor
    func templateSetExplicit() async throws {
        let latin1 = try await generateSet(["--encoding", "latin1"])
        let utf8 = try await generateSet(["--encoding", "UTF-8"])

        #expect(latin1.result.succeeded, "\(latin1.result.stdout)\(latin1.result.stderr)")
        #expect(latin1.text == Self.expected)
        #expect(!latin1.result.stderr.contains(Self.fallbackWarning), "\(latin1.result.stderr)")
        #expect(!utf8.result.succeeded)
        #expect((utf8.result.stdout + utf8.result.stderr).contains("not valid UTF-8"))
    }
}
