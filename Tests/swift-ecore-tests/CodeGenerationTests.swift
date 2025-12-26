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

    @Test("should generate protocols for abstract EClasses")
    @MainActor
    func testGenerateProtocol() async throws {
        // Given: An abstract EClass
        let stringType = EDataType(name: "EString", instanceClassName: "String")
        let intType = EDataType(name: "EInt", instanceClassName: "Int")

        let abstractPersonClass = EClass(
            name: "Person",
            isAbstract: true,  // Abstract class
            isInterface: false,
            eStructuralFeatures: [
                EAttribute(name: "name", eType: stringType, lowerBound: 0),
                EAttribute(name: "age", eType: intType, lowerBound: 0)
            ]
        )

        let testPackage = EPackage(
            name: "test",
            nsURI: "http://test/1.0",
            nsPrefix: "test",
            eClassifiers: [abstractPersonClass, stringType, intType]
        )

        let resource = Resource(uri: "file://test.ecore")
        _ = await resource.add(testPackage)

        // When: Generating Swift code
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let generator = try CodeGenerator(language: "swift", outputDirectory: tempDir)
        try await generator.generate(from: resource, verbose: false)

        let outputFile = tempDir.appendingPathComponent("Generated.swift")
        let generatedCode = try String(contentsOf: outputFile, encoding: String.Encoding.utf8)

        // Then: Should generate a protocol, not a class
        #expect(generatedCode.contains("protocol Person: EObject"))
        #expect(!generatedCode.contains("class Person"))

        // Should have property requirements with { get set }
        #expect(generatedCode.contains("var name: String? { get set }"))
        #expect(generatedCode.contains("var age: Int? { get set }"))

        // Should NOT have initializers (protocols don't have init)
        #expect(!generatedCode.contains("init(eClass:"))
    }

    @Test("should generate single inheritance correctly")
    @MainActor
    func testSingleInheritance() async throws {
        // Given: A base class and a derived class
        let stringType = EDataType(name: "EString", instanceClassName: "String")
        let intType = EDataType(name: "EInt", instanceClassName: "Int")

        // Dummy class for reference
        let companyClass = EClass(
            name: "Company",
            isAbstract: false,
            isInterface: false
        )

        // Base class: Person with name and company reference (forces class generation)
        let personClass = EClass(
            name: "Person",
            isAbstract: false,
            isInterface: false,
            eStructuralFeatures: [
                EAttribute(name: "name", eType: stringType, lowerBound: 0),
                EReference(name: "company", eType: companyClass, lowerBound: 0, upperBound: 1, containment: false)
            ]
        )

        // Derived class: Employee extends Person, adds employeeId
        var employeeClass = EClass(
            name: "Employee",
            isAbstract: false,
            isInterface: false,
            eStructuralFeatures: [
                EAttribute(name: "name", eType: stringType, lowerBound: 0),  // Inherited from Person
                EReference(name: "company", eType: companyClass, lowerBound: 0, upperBound: 1, containment: false),  // Inherited from Person
                EAttribute(name: "employeeId", eType: intType, lowerBound: 0)  // Local to Employee
            ]
        )
        employeeClass.eSuperTypes.append(personClass)

        let testPackage = EPackage(
            name: "test",
            nsURI: "http://test/1.0",
            nsPrefix: "test",
            eClassifiers: [personClass, employeeClass, companyClass, stringType, intType]
        )

        let resource = Resource(uri: "file://test.ecore")
        _ = await resource.add(testPackage)

        // When: Generating Swift code
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let generator = try CodeGenerator(language: "swift", outputDirectory: tempDir)
        try await generator.generate(from: resource, verbose: false)

        let outputFile = tempDir.appendingPathComponent("Generated.swift")
        let generatedCode = try String(contentsOf: outputFile, encoding: String.Encoding.utf8)

        // Then: Employee should extend Person
        #expect(generatedCode.contains("class Employee: Person"))

        // Employee should NOT redefine id and eClass (inherited from Person)
        let employeeClassStart = generatedCode.range(of: "class Employee: Person")!.upperBound
        let employeeClassEnd = generatedCode.range(of: "\n}\n", range: employeeClassStart..<generatedCode.endIndex)!.lowerBound
        let employeeClassBody = String(generatedCode[employeeClassStart..<employeeClassEnd])

        #expect(!employeeClassBody.contains("let id: EUUID"))
        #expect(!employeeClassBody.contains("let eClass: EClass"))

        // Employee should only have local property (employeeId), not inherited (name, company)
        #expect(employeeClassBody.contains("var employeeId"))
        #expect(!employeeClassBody.contains("var name"))
        #expect(!employeeClassBody.contains("var company"))

        // Employee should call super.init()
        #expect(generatedCode.contains("super.init(eClass: eClass)"))

        // Person should have EObject conformance
        #expect(generatedCode.contains("class Person: EObject"))
        #expect(generatedCode.contains("let id: EUUID"))
        #expect(generatedCode.contains("let eClass: EClass"))
    }

    @Test("should handle multiple inheritance via protocols")
    @MainActor
    func testMultipleInheritance() async throws {
        // Given: Abstract interfaces and a concrete class implementing multiple protocols
        let stringType = EDataType(name: "EString", instanceClassName: "String")
        let intType = EDataType(name: "EInt", instanceClassName: "Int")

        // Abstract interface: Named (has name property)
        let namedInterface = EClass(
            name: "Named",
            isAbstract: true,
            isInterface: true,
            eStructuralFeatures: [
                EAttribute(name: "name", eType: stringType, lowerBound: 0)
            ]
        )

        // Abstract interface: Identifiable (has id property)
        let identifiableInterface = EClass(
            name: "Identifiable",
            isAbstract: true,
            isInterface: true,
            eStructuralFeatures: [
                EAttribute(name: "identifier", eType: intType, lowerBound: 0)
            ]
        )

        // Concrete class: Product implements both Named and Identifiable
        var productClass = EClass(
            name: "Product",
            isAbstract: false,
            isInterface: false,
            eStructuralFeatures: [
                EAttribute(name: "name", eType: stringType, lowerBound: 0),       // From Named
                EAttribute(name: "identifier", eType: intType, lowerBound: 0),    // From Identifiable
                EAttribute(name: "price", eType: intType, lowerBound: 0)          // Local to Product
            ]
        )
        productClass.eSuperTypes.append(namedInterface)
        productClass.eSuperTypes.append(identifiableInterface)

        let testPackage = EPackage(
            name: "test",
            nsURI: "http://test/1.0",
            nsPrefix: "test",
            eClassifiers: [namedInterface, identifiableInterface, productClass, stringType, intType]
        )

        let resource = Resource(uri: "file://test.ecore")
        _ = await resource.add(testPackage)

        // When: Generating Swift code
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let generator = try CodeGenerator(language: "swift", outputDirectory: tempDir)
        try await generator.generate(from: resource, verbose: false)

        let outputFile = tempDir.appendingPathComponent("Generated.swift")
        let generatedCode = try String(contentsOf: outputFile, encoding: String.Encoding.utf8)

        // Then: Named and Identifiable should be protocols
        #expect(generatedCode.contains("protocol Named: EObject"))
        #expect(generatedCode.contains("protocol Identifiable: EObject"))

        // Product should implement both protocols
        #expect(generatedCode.contains("class Product: EObject, Named, Identifiable"))

        // Product should have its own id and eClass (not inherited from concrete class)
        #expect(generatedCode.contains("let id: EUUID"))
        #expect(generatedCode.contains("let eClass: EClass"))

        // Product should only have local property (price), not inherited ones (name, identifier)
        let productClassStart = generatedCode.range(of: "class Product: EObject, Named, Identifiable")!.upperBound
        let productClassEnd = generatedCode.range(of: "\n}\n", range: productClassStart..<generatedCode.endIndex)!.lowerBound
        let productClassBody = String(generatedCode[productClassStart..<productClassEnd])

        #expect(productClassBody.contains("var price"))
        #expect(!productClassBody.contains("var name"))
        #expect(!productClassBody.contains("var identifier"))
    }
}
