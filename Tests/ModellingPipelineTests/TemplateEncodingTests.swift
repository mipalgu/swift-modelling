//
// TemplateEncodingTests.swift
// ModellingPipelineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation
import ModellingGenerators
import ModellingPipeline
import Testing

/// Tests for the character encoding in which a generation step reads its templates.
///
/// Templates that are not valid UTF-8 are read as ISO-8859-1 with a decoding warning, unless
/// ``GenerationStep/templateEncoding`` names their encoding.
@Suite("GenerationStep - template encodings")
@MainActor
struct TemplateEncodingTests {
    /// The text that the main template writes, with characters outside US-ASCII.
    static let expected = "Café Grüße"

    /// Encodes text in ISO-8859-1.
    ///
    /// - Parameter text: Text whose characters are all below U+0100.
    /// - Returns: One byte per character.
    static func latin1(_ text: String) -> Data {
        Data(text.unicodeScalars.map { UInt8($0.value) })
    }

    /// Writes a template set whose main module, in ISO-8859-1, writes ``expected`` to `result.txt`.
    ///
    /// - Parameter fixture: The fixture that receives the set.
    /// - Returns: The directory of the set.
    private func writeLatin1Set(in fixture: PipelineFixture) throws -> URL {
        let set = fixture.directory.appendingPathComponent("sets/greeting")
        try fixture.write(
            """
            { "name": "greeting", "mainModule": "generate", "mainTemplate": "generate" }
            """, to: set.appendingPathComponent(TemplateSetConstants.descriptorFileName))
        try Self.latin1(
            """
            [module generate('http://example.com')]
            [template public generate()]
            [file ('result.txt')]\(Self.expected)[/file]
            [/template]
            """
        ).write(to: set.appendingPathComponent("generate.mtl"))
        return set
    }

    /// Writes a single module in ISO-8859-1 that writes ``expected`` to `result.txt`.
    ///
    /// - Parameter fixture: The fixture that receives the module.
    /// - Returns: The location of the module.
    private func writeLatin1Module(in fixture: PipelineFixture) throws -> URL {
        let url = fixture.directory.appendingPathComponent("modules/Greeting.mtl")
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Self.latin1(
            """
            [module Greeting('http://example.com')]
            [template public main()]
            [file ('result.txt')]\(Self.expected)[/file]
            [/template]
            """
        ).write(to: url)
        return url
    }

    /// Runs a step and returns its result with the text of `result.txt`.
    private func run(
        _ templates: GenerationStep.Templates, encoding: TextEncoding?, fixture: PipelineFixture
    ) async throws -> (result: GenerationStep.Result, text: String) {
        let output = fixture.directory.appendingPathComponent("out-\(UUID().uuidString)")
        var step = GenerationStep(templates: templates, outputDirectory: output, mtlOptions: .standard)
        step.templateEncoding = encoding
        let result = try await step.run(arguments: [])
        return (result, try fixture.text(of: output.appendingPathComponent("result.txt")))
    }

    @Test("a step reads templates in UTF-8 by default")
    func defaultEncoding() throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let step = GenerationStep(
            templates: .module(fixture.listing), outputDirectory: fixture.directory, mtlOptions: .standard)
        #expect(step.templateEncoding == nil)
    }

    @Test("a template set that is not UTF-8 is read as ISO-8859-1 with a warning naming the file")
    func templateSetFallback() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let set = try writeLatin1Set(in: fixture)

        let (result, text) = try await run(.templateSet(set.path), encoding: nil, fixture: fixture)

        #expect(text == Self.expected)
        #expect(result.decodingWarnings.count == 1)
        let warning = try #require(result.decodingWarnings.first)
        #expect(warning.code == TextDecodingDiagnostic.decodedAsISOLatin1)
        #expect(warning.document == "generate.mtl")
        #expect(result.warnings.isEmpty)
    }

    @Test("a template set is read in the encoding of the step without a warning")
    func templateSetExplicit() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let set = try writeLatin1Set(in: fixture)

        let (result, text) = try await run(.templateSet(set.path), encoding: .isoLatin1, fixture: fixture)

        #expect(text == Self.expected)
        #expect(result.decodingWarnings.isEmpty)
    }

    @Test("a template set that is not valid in the encoding of the step is rejected")
    func templateSetMalformed() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let set = try writeLatin1Set(in: fixture)

        await #expect(throws: GenerationError.self) {
            _ = try await run(.templateSet(set.path), encoding: .utf8, fixture: fixture)
        }
    }

    @Test("a single module is read in the encoding of the step, or as ISO-8859-1 with a warning")
    func singleModule() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let module = try writeLatin1Module(in: fixture)

        let fallback = try await run(.module(module), encoding: nil, fixture: fixture)
        let explicit = try await run(.module(module), encoding: .isoLatin1, fixture: fixture)

        #expect(fallback.text == Self.expected)
        #expect(fallback.result.decodingWarnings.map(\.code) == [TextDecodingDiagnostic.decodedAsISOLatin1])
        #expect(fallback.result.decodingWarnings.first?.document?.hasSuffix("Greeting.mtl") == true)
        #expect(explicit.text == Self.expected)
        #expect(explicit.result.decodingWarnings.isEmpty)
        await #expect(throws: ModelPipelineError.self) {
            _ = try await run(.module(module), encoding: .utf8, fixture: fixture)
        }
    }
}
