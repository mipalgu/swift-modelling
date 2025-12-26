import Foundation
import Testing

@Suite("swift-ecore generate - Code generation from Ecore metamodels")
struct CodeGenerationTests {

    @Test("should generate full Swift package structure from Families.ecore")
    @MainActor
    func testGenerateFamiliesIntegration() async throws {
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

        // Then: Should succeed
        #expect(result.succeeded)

        // Phase 6: Verify directory-based structure
        let pkgDir = outputDir.appendingPathComponent("Families")
        #expect(FileManager.default.fileExists(atPath: pkgDir.path))

        // Task 6.2: Verify separate files
        let expectedFiles = ["Family.swift", "Member.swift", "FamiliesFactory.swift", "FamiliesPackage.swift"]
        for fileName in expectedFiles {
            let fileURL = pkgDir.appendingPathComponent(fileName)
            #expect(FileManager.default.fileExists(atPath: fileURL.path), "Missing expected file: \(fileName)")
        }

        // Task 4.1 & 4.2: Verify Package and Factory content
        let packageContent = try String(contentsOf: pkgDir.appendingPathComponent("FamiliesPackage.swift"), encoding: .utf8)
        #expect(packageContent.contains("struct FamiliesPackage"))
        #expect(packageContent.contains("static let shared = FamiliesPackage()"))
        #expect(packageContent.contains("let eFamily: EClass"))
        #expect(packageContent.contains("let eMember: EClass"))

        let factoryContent = try String(contentsOf: pkgDir.appendingPathComponent("FamiliesFactory.swift"), encoding: .utf8)
        #expect(factoryContent.contains("struct FamiliesFactory"))
        #expect(factoryContent.contains("func createFamily() -> Family"))
        #expect(factoryContent.contains("func createMember() -> Member"))
        #expect(factoryContent.contains("func create(_ eClass: EClass) -> any EObject"))

        // Task 3.2 & 4.3: Verify bidirectional references and reflective access in Family.swift
        let familyContent = try String(contentsOf: pkgDir.appendingPathComponent("Family.swift"), encoding: .utf8)
        #expect(familyContent.contains("class Family: EObject, Hashable"))
        #expect(familyContent.contains("didSet"))
        #expect(familyContent.contains("func eGet(_ feature: some EStructuralFeature) -> (any EcoreValue)?"))
        #expect(familyContent.contains("func eSet(_ feature: some EStructuralFeature, value: (any EcoreValue)?)"))

        // Task 6.1: Verify DocC documentation (Australian English summary/description pattern)
        #expect(familyContent.contains("/// The Family class."))
        #expect(familyContent.contains("An implementation of the Family type from the Ecore metamodel."))
    }

    @Test("should generate documented Swift code from organisation.ecore")
    @MainActor
    func testGenerateOrganisationIntegration() async throws {
        // Given: The organisation.ecore metamodel
        let ecoreFile = "/home/rh/.gemini/tmp/build-swift-modelling/checkouts/swift-ecore/Tests/ECoreTests/Resources/xmi/organisation.ecore"

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

        // Then: Should succeed
        #expect(result.succeeded)

        let pkgDir = outputDir.appendingPathComponent("organisation")
        let personFile = pkgDir.appendingPathComponent("Person.swift")
        let teamFile = pkgDir.appendingPathComponent("Team.swift")

        #expect(FileManager.default.fileExists(atPath: personFile.path))
        #expect(FileManager.default.fileExists(atPath: teamFile.path))

        let personContent = try String(contentsOf: personFile, encoding: .utf8)
        #expect(personContent.contains("class Person"))

        // Verify DocC property documentation
        #expect(personContent.contains("/// The name attribute."))
        #expect(personContent.contains("/// The age attribute."))
    }

    @Test("should generate Swift code from minimal.ecore with enumerations")
    @MainActor
    func testGenerateMinimalWithEnums() async throws {
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

        let pkgDir = outputDir.appendingPathComponent("mytest")
        let enumFile = pkgDir.appendingPathComponent("MyEnum.swift")

        #expect(FileManager.default.fileExists(atPath: enumFile.path))

        let enumContent = try String(contentsOf: enumFile, encoding: .utf8)

        // Task 5.1 & 6.1: Verify documented enumeration
        #expect(enumContent.contains("/// The MyEnum enumeration."))
        #expect(enumContent.contains("enum MyEnum: Int, Sendable, Codable, CaseIterable"))
        #expect(enumContent.contains("case ABC = 0"))
        #expect(enumContent.contains("case DEF = 1"))
    }
}
