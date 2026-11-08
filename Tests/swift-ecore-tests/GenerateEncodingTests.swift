//
// GenerateEncodingTests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for the character encoding in which `swift-ecore generate` reads templates.
///
/// A template that is not valid UTF-8 is read as ISO-8859-1 with a warning on standard error
/// that names it within the template set; `--encoding`, and the `encoding` key of the
/// configuration file, name the encoding instead.
@Suite("swift-ecore generate - template encodings", .serialized)
struct GenerateEncodingTests {
    /// A header module in which a comment has characters outside US-ASCII.
    static let header = """
        [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
        [template public header(element : OclAny, fileName : String)]
        // Grüße
        [/template]
        """

    /// The start of a generated file.
    static let expectedHeader = "// Grüße\n"

    /// The warning that a file was read as ISO-8859-1.
    static let fallbackWarning = "The text is not valid UTF-8 and was read as ISO-8859-1"

    /// Creates the repository of ``ConfigurationTests`` with the header module in ISO-8859-1.
    static func workspace() throws -> ConfigurationTests.Workspace {
        let workspace = try ConfigurationTests.Workspace()
        let data = try #require(header.data(using: .isoLatin1))
        try data.write(to: workspace.root.appendingPathComponent("templates/Header.mtl"))
        return workspace
    }

    @Test("a template that is not UTF-8 is read as ISO-8859-1 with a warning naming it")
    @MainActor
    func fallback() async throws {
        let workspace = try Self.workspace()
        defer { workspace.remove() }

        let (result, text) = try await workspace.generate()

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text?.hasPrefix(Self.expectedHeader) == true, "\(text ?? "")")
        #expect(result.stderr.contains("warning: Header.mtl: line "), "\(result.stderr)")
        #expect(result.stderr.contains(Self.fallbackWarning), "\(result.stderr)")
    }

    @Test("--encoding names the encoding of the templates")
    @MainActor
    func explicit() async throws {
        let workspace = try Self.workspace()
        defer { workspace.remove() }

        let latin1 = try await workspace.generate(["--encoding", "latin1"])
        let utf8 = try await workspace.generate(["--encoding", "UTF-8"])

        #expect(latin1.result.succeeded, "\(latin1.result.stdout)\(latin1.result.stderr)")
        #expect(latin1.text?.hasPrefix(Self.expectedHeader) == true)
        #expect(!latin1.result.stderr.contains(Self.fallbackWarning), "\(latin1.result.stderr)")
        #expect(!utf8.result.succeeded)
        #expect((utf8.result.stdout + utf8.result.stderr).contains("not valid UTF-8"))
    }

    @Test("the configuration file names the encoding, which --encoding overrides")
    @MainActor
    func configured() async throws {
        let workspace = try Self.workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "encoding": "ISO-8859-1" }"#)

        let configured = try await workspace.generate()
        let overridden = try await workspace.generate(["--encoding", "UTF-8"])

        #expect(configured.result.succeeded, "\(configured.result.stdout)\(configured.result.stderr)")
        #expect(configured.text?.hasPrefix(Self.expectedHeader) == true)
        #expect(!configured.result.stderr.contains(Self.fallbackWarning), "\(configured.result.stderr)")
        #expect(!overridden.result.succeeded)
    }

    @Test("the help of generate describes --encoding")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftEcore(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("--encoding"))
    }
}
