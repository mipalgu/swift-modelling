import Foundation
import MTL
import Testing

@testable import ModellingGenerators

/// Tests for the setting that chooses how typed `let` blocks treat values that do not conform.
@Suite("Generation options - typed let mismatches")
struct LetTypeMismatchesOptionTests {
    /// A header module whose typed let binds the file name, a string, to an integer variable.
    private static let header = """
        [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
        [template public header(element : OclAny, fileName : String)][let n : Integer = fileName]// [n/][/let]// Customised[/template]
        """

    @Test("generation options treat a mismatch as an error unless told otherwise")
    func generationOptionsDefault() {
        #expect(GenerationOptions().letTypeMismatches == .error)
        #expect(GenerationOptions(letTypeMismatches: .skip).letTypeMismatches == .skip)
    }

    @Test("options that differ only in how mismatches are treated are not equal")
    func equality() {
        var skipping = GenerationOptions()
        skipping.letTypeMismatches = .skip

        #expect(skipping != GenerationOptions())
    }

    /// Generates Swift from the library Ecore model with the mismatching header module.
    ///
    /// - Parameter letTypeMismatches: How mismatches are treated.
    /// - Returns: The result of the generation and the text of one generated file.
    @MainActor
    private func generate(
        letTypeMismatches: MTLLetTypeMismatches
    ) async throws -> (result: GenerationResult, text: String) {
        let project = try FixtureProject.make("library")
        defer { project.remove() }
        let templates = try ScratchDirectory()
        defer { templates.remove() }
        try templates.write(Self.header, to: "Header.mtl")
        let output = project.root.appendingPathComponent("swift")
        let result = try await GenerationPipeline.generate(
            inputURL: project.root.appendingPathComponent("model/library.ecore"), language: "swift",
            outputDirectory: output,
            options: GenerationOptions(templatePaths: [templates.url], letTypeMismatches: letTypeMismatches))
        let text = try String(
            contentsOf: output.appendingPathComponent("library/BookCategory.swift"), encoding: .utf8)
        return (result, text)
    }

    @Test("the skip mode skips the let block and returns one warning for the repeated mismatch")
    @MainActor
    func skipReportsWarning() async throws {
        let (result, text) = try await generate(letTypeMismatches: .skip)

        #expect(text.hasPrefix("// Customised\n"))
        #expect(result.warnings.count == 1)
        let message = try #require(result.warnings.first?.message)
        #expect(message.contains("'n'"))
        #expect(message.contains("Integer"))
        #expect(message.contains("String"))
    }

    @Test("a mismatch fails the generation by default")
    @MainActor
    func defaultFails() async throws {
        await #expect(throws: GenerationError.self) {
            _ = try await generate(letTypeMismatches: .error)
        }
    }
}
