//
// GenerateEncodingTests.swift
// swift-atl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for the character encoding in which `swift-atl generate` reads a transformation given
/// with `--transformations` and the templates of a template set.
///
/// A file that is not valid UTF-8 is read as ISO-8859-1 with a warning on standard error that
/// names it; `--encoding` names the encoding instead.
@Suite("swift-atl generate - source encodings", .serialized)
struct GenerateEncodingTests {
    /// Text with characters outside US-ASCII.
    static let greeting = "Grüße"

    /// The warning that a file was read as ISO-8859-1.
    static let fallbackWarning = "The text is not valid UTF-8 and was read as ISO-8859-1"

    /// Encodes text in ISO-8859-1.
    ///
    /// - Parameter text: Text whose characters are all below U+0100.
    /// - Returns: One byte per character.
    static func latin1(_ text: String) throws -> Data {
        try #require(text.data(using: .isoLatin1))
    }

    /// The transformation that the generator models are created with by default.
    static func bundledTransformation() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/ModellingGenerators/Transformations/Ecore2GenModel.atl")
    }

    /// Writes a copy of the bundled transformation in ISO-8859-1, with a comment in German.
    ///
    /// - Parameter fixture: The fixture whose scratch directory receives the copy.
    /// - Returns: The location of the copy.
    static func writeLatin1Transformation(in fixture: LibraryFixture) throws -> URL {
        let text = try String(contentsOf: bundledTransformation(), encoding: .utf8) + "\n-- \(greeting)\n"
        let file = fixture.scratch.appendingPathComponent("Ecore2GenModel.atl")
        try latin1(text).write(to: file)
        return file
    }

    /// Writes a template set `note` in ISO-8859-1 that writes ``greeting`` to `note.txt`.
    ///
    /// - Parameter fixture: The fixture whose scratch directory receives the set.
    /// - Returns: The directory to give with `--template-path`.
    static func writeLatin1Templates(in fixture: LibraryFixture) throws -> URL {
        let languages = fixture.scratch.appendingPathComponent("languages")
        let note = languages.appendingPathComponent("note")
        try FileManager.default.createDirectory(at: note, withIntermediateDirectories: true)
        try Data(#"{ "name": "note", "mainModule": "generate", "mainTemplate": "generate" }"#.utf8)
            .write(to: note.appendingPathComponent("templateset.json"))
        try latin1(
            """
            [module generate('http://www.eclipse.org/emf/2002/GenModel')/]
            [template public generate(genModel : GenModel)]
            [file ('note.txt')]\(greeting)[/file]
            [/template]
            """
        ).write(to: note.appendingPathComponent("generate.mtl"))
        return languages
    }

    /// Runs `generate` with a transformation in ISO-8859-1.
    @MainActor
    private func generateGenModel(_ extra: [String]) async throws -> (SubprocessResult, LibraryFixture, URL) {
        let fixture = try LibraryFixture.make()
        let transformation = try Self.writeLatin1Transformation(in: fixture)
        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [
                fixture.ecore.path, "--language", "genmodel", "--transformations", transformation.path, "-o",
                fixture.output.path,
            ] + extra)
        return (result, fixture, transformation)
    }

    @Test("a transformation that is not UTF-8 is read as ISO-8859-1 with a warning naming it")
    @MainActor
    func transformationFallback() async throws {
        let (result, fixture, transformation) = try await generateGenModel([])
        defer { fixture.remove() }

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stderr.contains("warning: \(transformation.path): line "), "\(result.stderr)")
        #expect(result.stderr.contains(Self.fallbackWarning), "\(result.stderr)")
    }

    @Test("--encoding names the encoding of a transformation")
    @MainActor
    func transformationExplicit() async throws {
        let (latin1, fixture, _) = try await generateGenModel(["--encoding", "latin1"])
        defer { fixture.remove() }
        let (utf8, other, transformation) = try await generateGenModel(["--encoding", "UTF-8"])
        defer { other.remove() }

        #expect(latin1.succeeded, "\(latin1.stdout)\(latin1.stderr)")
        #expect(!latin1.stderr.contains(Self.fallbackWarning), "\(latin1.stderr)")
        #expect(!utf8.succeeded)
        #expect((utf8.stdout + utf8.stderr).contains("not valid UTF-8"), "\(utf8.stdout)\(utf8.stderr)")
        #expect(!utf8.stderr.contains("warning: \(transformation.path)"), "\(utf8.stderr)")
    }

    /// Runs `generate` with the template set `note` in ISO-8859-1.
    @MainActor
    private func generateNote(_ extra: [String]) async throws -> (result: SubprocessResult, text: String?) {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let languages = try Self.writeLatin1Templates(in: fixture)
        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [
                fixture.ecore.path, "--language", "note", "--template-path", languages.path, "-o",
                fixture.output.path,
            ] + extra)
        let text = try? String(contentsOf: fixture.output.appendingPathComponent("note.txt"), encoding: .utf8)
        return (result, text)
    }

    @Test("templates that are not UTF-8 are read as ISO-8859-1 with a warning naming them in the set")
    @MainActor
    func templateFallback() async throws {
        let (result, text) = try await generateNote([])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text == Self.greeting)
        #expect(result.stderr.contains("warning: generate.mtl: line "), "\(result.stderr)")
        #expect(result.stderr.contains(Self.fallbackWarning), "\(result.stderr)")
    }

    @Test("--encoding names the encoding of the templates")
    @MainActor
    func templateExplicit() async throws {
        let latin1 = try await generateNote(["--encoding", "ISO-8859-1"])
        let utf8 = try await generateNote(["--encoding", "UTF-8"])

        #expect(latin1.result.succeeded, "\(latin1.result.stdout)\(latin1.result.stderr)")
        #expect(latin1.text == Self.greeting)
        #expect(!latin1.result.stderr.contains(Self.fallbackWarning), "\(latin1.result.stderr)")
        #expect(!utf8.result.succeeded)
        #expect((utf8.result.stdout + utf8.result.stderr).contains("not valid UTF-8"))
    }

    @Test("the help of generate describes --encoding")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftATL(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("--encoding"))
    }
}
