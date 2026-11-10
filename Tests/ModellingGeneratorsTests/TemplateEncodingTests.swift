//
// TemplateEncodingTests.swift
// ModellingGeneratorsTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation
import Testing

@testable import ModellingGenerators

/// Tests for the character encodings in which the generation pipelines read templates and the
/// transformation that replaces the bundled `Ecore2GenModel` transformation.
///
/// Files that are not valid UTF-8 are read as ISO-8859-1 with a decoding warning, unless the
/// options name their encoding.
@Suite("Generation - template and transformation encodings")
struct TemplateEncodingTests {
    /// A comment with characters outside US-ASCII.
    static let greeting = "Grüße"

    /// Encodes text in ISO-8859-1.
    ///
    /// - Parameter text: Text whose characters are all below U+0100.
    /// - Returns: One byte per character.
    static func latin1(_ text: String) throws -> Data {
        try #require(text.data(using: .isoLatin1))
    }

    @Test("the options read templates and transformations in UTF-8 by default")
    func defaults() {
        #expect(GenerationOptions(mtlOptions: .standard).templateEncoding == nil)
        #expect(GenModelImportOptions(atlOptions: .standard).transformationEncoding == nil)
    }

    /// Generates the library with an `outline` template set written in ISO-8859-1.
    ///
    /// - Parameter encoding: The encoding of the templates, or `nil` for UTF-8 with a fallback.
    /// - Returns: The result of the generation and the text of `outline.txt`.
    @MainActor
    private func outline(encoding: TextEncoding?) async throws -> (result: GenerationResult, text: String) {
        let generated = try await GeneratedProject.make(
            "library", stem: "library", options: GenModelImportOptions(basePackage: "org.example", defaults: .wizard))
        let scratch = try ScratchDirectory()
        defer {
            generated.remove()
            scratch.remove()
        }
        try scratch.write(
            #"""
            {"name": "outline", "mainModule": "main", "mainTemplate": "main", "options": {"lineDelimiter": "\n"}}
            """#, to: "outline/templateset.json")
        try Self.latin1(
            """
            [module main('http://www.eclipse.org/emf/2002/GenModel')/]
            [template public main(genModel : GenModel)]
            [file ('outline.txt')]\(Self.greeting)[/file]
            [/template]
            """
        ).write(to: scratch.url.appendingPathComponent("outline/main.mtl"))
        var options = GenerationOptions(templatePaths: [scratch.url], mtlOptions: .standard)
        options.templateEncoding = encoding
        let result = try await generated.generate(language: "outline", options: options)
        return (result, try generated.text("outline.txt"))
    }

    @Test("a template that is not UTF-8 is read as ISO-8859-1 with a warning naming it in the set")
    @MainActor
    func templateFallback() async throws {
        let (result, text) = try await outline(encoding: nil)
        #expect(text == Self.greeting)
        #expect(result.decodingWarnings.map(\.code) == [TextDecodingDiagnostic.decodedAsISOLatin1])
        #expect(result.decodingWarnings.first?.document == "main.mtl")
    }

    @Test("templates are read in the encoding of the options without a warning")
    @MainActor
    func templateExplicit() async throws {
        let (result, text) = try await outline(encoding: .isoLatin1)
        #expect(text == Self.greeting)
        #expect(result.decodingWarnings.isEmpty)
    }

    @Test("templates that are not valid in the encoding of the options are rejected")
    @MainActor
    func templateMalformed() async throws {
        await #expect(throws: GenerationError.self) {
            _ = try await outline(encoding: .utf8)
        }
    }

    /// Imports the library Ecore model with a copy of the bundled transformation in ISO-8859-1.
    ///
    /// - Parameter encoding: The encoding of the transformation, or `nil` for UTF-8 with a fallback.
    /// - Returns: The result of the import.
    @MainActor
    private func importLatin1(encoding: TextEncoding?) async throws -> GenModelResult {
        let project = try FixtureProject.make("library")
        defer { project.remove() }
        let bundled = try #require(GenModelTransformation.resourceURL)
        let transformation = project.root.appendingPathComponent("Ecore2GenModel.atl")
        let text = try String(contentsOf: bundled, encoding: .utf8) + "\n-- \(Self.greeting)\n"
        try Self.latin1(text).write(to: transformation)
        var options = GenModelImportOptions(transformation: transformation, atlOptions: .standard)
        options.transformationEncoding = encoding
        return try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [project.root.appendingPathComponent("model/library.ecore")], options: options)
    }

    @Test("a transformation that is not UTF-8 is read as ISO-8859-1 with a warning")
    @MainActor
    func transformationFallback() async throws {
        let result = try await importLatin1(encoding: nil)
        #expect(result.decodingWarnings.map(\.code) == [TextDecodingDiagnostic.decodedAsISOLatin1])
        #expect(result.decodingWarnings.first?.document?.hasSuffix("Ecore2GenModel.atl") == true)
        #expect(result.packageCount > 0)
    }

    @Test("a transformation is read in the encoding of the options without a warning")
    @MainActor
    func transformationExplicit() async throws {
        let result = try await importLatin1(encoding: .isoLatin1)
        #expect(result.decodingWarnings.isEmpty)
        #expect(result.packageCount > 0)
    }

    @Test("a transformation that is not valid in the encoding of the options is rejected")
    @MainActor
    func transformationMalformed() async throws {
        await #expect(throws: GenerationError.self) {
            _ = try await importLatin1(encoding: .utf8)
        }
    }
}
