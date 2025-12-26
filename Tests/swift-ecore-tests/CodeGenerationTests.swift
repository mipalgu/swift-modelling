import Foundation
import Testing
import ECore

@testable import swift_ecore

@Suite("swift-ecore generate - Code generation from Ecore metamodels")
struct CodeGenerationTests {

    /// Helper to create a simple test metamodel
    func createTestMetamodel() -> EPackage {
        // Create a simple Person class with name and age attributes + a reference to Company
        let stringType = EDataType(name: "EString", instanceClassName: "String")
        let intType = EDataType(name: "EInt", instanceClassName: "Int")

        // Create Company class first (for the reference)
        let companyClass = EClass(
            name: "Company",
            isAbstract: false,
            isInterface: false
        )

        let nameAttr = EAttribute(name: "name", eType: stringType, lowerBound: 0)
        let ageAttr = EAttribute(name: "age", eType: intType, lowerBound: 0)

        // Add a reference to Company (this will force Person to be a class)
        let employerRef = EReference(name: "employer", eType: companyClass, lowerBound: 0, upperBound: 1, containment: false)

        let personClass = EClass(
            name: "Person",
            isAbstract: false,
            isInterface: false,
            eStructuralFeatures: [nameAttr, ageAttr, employerRef]
        )

        let testPackage = EPackage(
            name: "test",
            nsURI: "http://test/1.0",
            nsPrefix: "test",
            eClassifiers: [personClass, companyClass, stringType, intType]
        )

        return testPackage
    }

    @Test("should generate Swift code from EPackage without crashing")
    @MainActor
    func testGenerateFromEPackage() async throws {
        // Given: A manually created test metamodel
        let ePackage = createTestMetamodel()

        // Create a resource with the EPackage
        let resource = Resource(uri: "file://test.ecore")
        _ = await resource.add(ePackage)

        // When: Generating Swift code
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let generator = try CodeGenerator(language: "swift", outputDirectory: tempDir)
        try await generator.generate(from: resource, verbose: false)

        // Then: Should produce generated Swift file
        let outputFile = tempDir.appendingPathComponent("Generated.swift")
        #expect(FileManager.default.fileExists(atPath: outputFile.path))

        let generatedCode = try String(contentsOf: outputFile, encoding: String.Encoding.utf8)

        // Verify it contains expected content
        #expect(!generatedCode.isEmpty)
        #expect(generatedCode.contains("import Foundation"))
        #expect(generatedCode.contains("import ECore"))

        // Verify it contains Person class
        #expect(generatedCode.contains("class Person"))

        // Verify attributes are generated
        #expect(generatedCode.contains("var name"))
        #expect(generatedCode.contains("var age"))

        let fileSize = try FileManager.default.attributesOfItem(atPath: outputFile.path)[.size] as? Int ?? 0
        #expect(fileSize > 0)
    }

    @Test("should generate proper initializers for classes")
    @MainActor
    func testGenerateInitializers() async throws {
        // Given: A manually created test metamodel
        let ePackage = createTestMetamodel()

        let resource = Resource(uri: "file://test.ecore")
        _ = await resource.add(ePackage)

        // When: Generating code
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let generator = try CodeGenerator(language: "swift", outputDirectory: tempDir)
        try await generator.generate(from: resource, verbose: false)

        let outputFile = tempDir.appendingPathComponent("Generated.swift")
        let generatedCode = try String(contentsOf: outputFile, encoding: String.Encoding.utf8)

        // Then: Should include EObject protocol conformance
        #expect(generatedCode.contains("let id: EUUID = EUUID()"))
        #expect(generatedCode.contains("let eClass: EClass"))

        // Should include designated initializer
        #expect(generatedCode.contains("init(eClass: EClass)"))

        // Should include convenience initializer with parameters
        #expect(generatedCode.contains("convenience init"))
    }
}
