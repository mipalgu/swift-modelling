import Foundation
import Testing

@Suite("swift-ecore generate - Code generation from Ecore metamodels")
struct CodeGenerationTests {

    @Test("should generate Swift code from Families.ecore")
    @MainActor
    func testGenerateFamiliesSwift() async throws {
        // Given: The Families.ecore metamodel
        let ecoreFile = "Tests/swift-atl-tests/Resources/Families2Persons/Families.ecore"

        guard FileManager.default.fileExists(atPath: ecoreFile) else {
            return
        }

        let outputDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(outputDir) }

        // When: Generating Swift code
        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [ecoreFile, "--output", outputDir.path, "--language", "swift", "--verbose"]
        )

        // Then: Should succeed and create Generated.swift
        #expect(result.succeeded)
        let generatedFile = outputDir.appendingPathComponent("Generated.swift")
        #expect(FileManager.default.fileExists(atPath: generatedFile.path))

        // And: Should contain class definitions with bidirectional references
        let content = try String(contentsOf: generatedFile, encoding: .utf8)
        #expect(content.contains("class Family"))
        #expect(content.contains("class Member"))

        // Check for bidirectional reference implementation (Phase 3)
        #expect(content.contains("didSet"))
        #expect(content.contains("oldValue"))

        // Phase 5: Hashable and Equatable
        #expect(content.contains("Hashable"))
        #expect(content.contains("static func == (lhs: Family, rhs: Family) -> Bool"))
        #expect(content.contains("func hash(into hasher: inout Hasher)"))
    }

    @Test("should generate Swift code from minimal.ecore")
    @MainActor
    func testGenerateMinimalSwift() async throws {
        // Given: The minimal.ecore metamodel
        let ecoreFile = "/home/rh/.gemini/tmp/build-swift-modelling/checkouts/swift-ecore/Tests/ECoreTests/Resources/xmi/minimal.ecore"

        if !FileManager.default.fileExists(atPath: ecoreFile) { return }

        let outputDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(outputDir) }

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [ecoreFile, "--output", outputDir.path, "--language", "swift", "--verbose"]
        )

        #expect(result.succeeded)
        let generatedFile = outputDir.appendingPathComponent("Generated.swift")
        #expect(FileManager.default.fileExists(atPath: generatedFile.path))

        let content = try String(contentsOf: generatedFile, encoding: .utf8)
        #expect(content.contains("class") || content.contains("protocol"))

        // Phase 5: EEnum support
        #expect(content.contains("enum MyEnum"))
        #expect(content.contains("case ABC = 0"))
        #expect(content.contains("case DEF = 1"))

        // Phase 5: ID preservation (UUIDs should be used for identity)
        #expect(content.contains("let id: UUID"))
    }
}
