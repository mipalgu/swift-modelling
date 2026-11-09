//
// OutputEncodingTests.swift
// swift-mtl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import ModellingCommandLine
import Testing

/// Tests for the character encoding in which `swift-mtl generate` writes files.
///
/// `--output-encoding`, and the `output-encoding` key of the configuration file, name the
/// encoding of the files that `[file]` blocks write without a charset of their own, and of
/// the file that keeps the text written outside any block. UTF-8 stays the default.
@Suite("swift-mtl generate - output encodings", .serialized)
struct OutputEncodingTests {
    /// The name of the option.
    static let option = "--" + OutputEncodingOptions.optionName

    /// The configuration key.
    static let key = OutputEncodingOptions.optionName

    /// A module with a file block that names no charset, one that names UTF-8, and text outside blocks.
    static let module = """
        [module Encoded('http://www.eclipse.org/emf/2002/Ecore')]

        [template public main(p : ecore::EPackage)]
        [file ('plain.txt', 'overwrite')]
        Café
        [/file]
        [file ('explicit.txt', 'overwrite', 'UTF-8')]
        Café
        [/file]
        Grüße
        [/template]
        """

    /// A module whose file block writes a character that ISO-8859-1 cannot hold.
    static let euroModule = """
        [module Euro('http://www.eclipse.org/emf/2002/Ecore')]

        [template public main(p : ecore::EPackage)]
        [file ('plain.txt', 'overwrite')]
        first
        price: 5 €
        [/file]
        [/template]
        """

    /// Runs `generate` on a module in a fresh repository.
    ///
    /// - Parameters:
    ///   - source: The text of the module.
    ///   - configuration: The text of a configuration file, if any.
    ///   - extra: The options after the arguments.
    ///   - check: Receives the result, the output directory and the repository.
    @MainActor
    func run(
        _ source: String, configuration: String? = nil, _ extra: [String] = [],
        check: (SubprocessResult, URL) throws -> Void
    ) async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }
        let template = workspace.root.appendingPathComponent("Encoded.mtl")
        try source.write(to: template, atomically: true, encoding: .utf8)
        if let configuration { try workspace.write(configuration) }
        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                template.path, "--model", workspace.root.appendingPathComponent("lib.ecore").path,
                "--output", workspace.output.path,
            ] + extra,
            workingDirectory: workspace.workingDirectory)
        try check(result, workspace.output)
    }

    /// Reads the bytes of a file.
    static func bytes(_ name: String, in directory: URL) -> Data? {
        try? Data(contentsOf: directory.appendingPathComponent(name))
    }

    /// The bytes of "Café\n" in ISO-8859-1.
    static let latin1Cafe = Data([0x43, 0x61, 0x66, 0xE9, 0x0A])

    @Test("writes UTF-8 by default, byte for byte as with an explicit UTF-8")
    @MainActor
    func defaultIsUTF8() async throws {
        var plain: [String: Data] = [:]
        try await run(Self.module) { result, output in
            #expect(result.succeeded, "\(result.stderr)")
            for name in ["plain.txt", "explicit.txt", "stdout"] { plain[name] = Self.bytes(name, in: output) }
        }
        #expect(plain["plain.txt"] == Data("Café\n".utf8))
        #expect(plain["stdout"] != nil)
        try await run(Self.module, [Self.option, "UTF-8"]) { result, output in
            #expect(result.succeeded, "\(result.stderr)")
            for name in ["plain.txt", "explicit.txt", "stdout"] {
                #expect(Self.bytes(name, in: output) == plain[name], "\(name)")
            }
        }
    }

    @Test("writes file blocks without a charset in the encoding, and keeps an explicit charset")
    @MainActor
    func latin1() async throws {
        try await run(Self.module, [Self.option, "ISO-8859-1"]) { result, output in
            #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
            #expect(Self.bytes("plain.txt", in: output) == Self.latin1Cafe)
            #expect(Self.bytes("explicit.txt", in: output) == Data("Café\n".utf8))
        }
    }

    @Test("writes the file of the text outside file blocks in the encoding")
    @MainActor
    func standardOutputFile() async throws {
        try await run(Self.module, [Self.option, "latin1"]) { result, output in
            #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
            let data = try #require(Self.bytes("stdout", in: output))
            #expect(data.contains(0xFC), "\(data)")
            #expect(!data.contains(0xC3))
        }
    }

    @Test("does not affect text printed on standard output")
    @MainActor
    func printedStandardOutput() async throws {
        try await run(Self.module, [Self.option, "ISO-8859-1", "--print-standard-output"]) { result, output in
            #expect(result.succeeded, "\(result.stderr)")
            #expect(result.stdout.contains("Grüße"))
            #expect(Self.bytes("stdout", in: output) == nil)
        }
    }

    @Test("writes windows-1252 characters that ISO-8859-1 lacks")
    @MainActor
    func windows1252() async throws {
        try await run(Self.euroModule, [Self.option, "windows-1252"]) { result, output in
            #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
            #expect(Self.bytes("plain.txt", in: output) == Data("first\nprice: 5 ".utf8) + Data([0x80, 0x0A]))
        }
    }

    @Test("fails for a character the encoding cannot hold, naming file, line and column, and leaves no file")
    @MainActor
    func unrepresentable() async throws {
        try await run(Self.euroModule, [Self.option, "ISO-8859-1"]) { result, output in
            #expect(!result.succeeded)
            let message = result.stdout + result.stderr
            for expected in ["U+20AC", "line 2, column 10", "plain.txt"] {
                #expect(message.contains(expected), "\(expected) is missing from: \(message)")
            }
            #expect(Self.bytes("plain.txt", in: output) == nil)
        }
    }

    @Test("reads the encoding from the configuration file")
    @MainActor
    func configurationKey() async throws {
        try await run(Self.module, configuration: #"{ "\#(Self.key)": "ISO-8859-1" }"#) { result, output in
            #expect(result.succeeded, "\(result.stderr)")
            #expect(Self.bytes("plain.txt", in: output) == Self.latin1Cafe)
        }
    }

    @Test("lets the command line override the configuration file")
    @MainActor
    func commandLineOverrides() async throws {
        try await run(Self.module, configuration: #"{ "\#(Self.key)": "ISO-8859-1" }"#, [Self.option, "UTF-8"]) {
            result, output in
            #expect(result.succeeded, "\(result.stderr)")
            #expect(Self.bytes("plain.txt", in: output) == Data("Café\n".utf8))
        }
    }

    @Test("rejects an unknown encoding, naming it")
    @MainActor
    func invalidName() async throws {
        try await run(Self.module, [Self.option, "no-such-encoding"]) { result, output in
            #expect(!result.succeeded)
            #expect((result.stdout + result.stderr).contains("no-such-encoding"), "\(result.stderr)")
            #expect(Self.bytes("plain.txt", in: output) == nil)
        }
    }

    @Test("writes the files of a template set in the encoding")
    @MainActor
    func templateSet() async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }
        try workspace.write(
            #"{ "name": "cafe", "mainModule": "generate", "mainTemplate": "generate" }"#,
            to: "sets/cafe/templateset.json")
        try workspace.write(
            """
            [module generate('http://www.eclipse.org/emf/2002/Ecore')]

            [template public generate(p : ecore::EPackage)]
            [file ('plain.txt', 'overwrite')]
            Café
            [/file]
            [/template]
            """, to: "sets/cafe/generate.mtl")

        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                "--template-set", workspace.root.appendingPathComponent("sets/cafe").path, "--model",
                workspace.root.appendingPathComponent("lib.ecore").path, "--output", workspace.output.path,
                Self.option, "ISO-8859-1",
            ], workingDirectory: workspace.workingDirectory)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(Self.bytes("plain.txt", in: workspace.output) == Self.latin1Cafe)
    }
}
