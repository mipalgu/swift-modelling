import Testing
import Foundation

/// Test suite for ATL Advanced Tutorial 01: Class to Relational
/// Validates the classic Class2Relational transformation benchmark
@Suite("Advanced Tutorial: Class2Relational Transformation")
struct ATLAdvanced01Tests {

    static let tutorialCodePath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")
        .appendingPathComponent("SwiftModelling")
        .appendingPathComponent("SwiftModelling.docc")
        .appendingPathComponent("Resources")
        .appendingPathComponent("Code")
        .appendingPathComponent("ATL-Advanced-01")

    // MARK: - Section 1: CLI Validation of Metamodels

    @Test("CLI: Validate Class metamodel via swift-ecore")
    @MainActor
    func testCLIValidateClassMetamodel() async throws {
        let classEcorePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("class.ecore")

        #expect(FileManager.default.fileExists(atPath: classEcorePath.path), "Class metamodel should exist")

        // Use swift-ecore validate to ensure the metamodel can be loaded
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [classEcorePath.path]
        )

        #expect(result.succeeded, "Class metamodel should validate successfully: \(result.stderr)")
    }

    @Test("CLI: Validate Relational metamodel via swift-ecore")
    @MainActor
    func testCLIValidateRelationalMetamodel() async throws {
        let relationalEcorePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("relational.ecore")

        #expect(FileManager.default.fileExists(atPath: relationalEcorePath.path), "Relational metamodel should exist")

        // Use swift-ecore validate to ensure the metamodel can be loaded
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [relationalEcorePath.path]
        )

        #expect(result.succeeded, "Relational metamodel should validate successfully: \(result.stderr)")
    }

    @Test("CLI: Validate sample input model via swift-ecore")
    @MainActor
    func testCLIValidateSampleInput() async throws {
        let samplePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("sample-classes.xmi")

        #expect(FileManager.default.fileExists(atPath: samplePath.path), "Sample classes model should exist")

        // Use swift-ecore validate to ensure the model can be loaded
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [samplePath.path]
        )

        #expect(result.succeeded, "Sample classes model should validate successfully: \(result.stderr)")
    }

    @Test("CLI: Validate expected output model via swift-ecore")
    @MainActor
    func testCLIValidateExpectedOutput() async throws {
        let outputPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected-output.xmi")

        #expect(FileManager.default.fileExists(atPath: outputPath.path), "Expected output should exist")

        // Use swift-ecore validate to ensure the model can be loaded
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [outputPath.path]
        )

        #expect(result.succeeded, "Expected output should validate successfully: \(result.stderr)")
    }

    // MARK: - Section 2: Validate Source Metamodel (Class) Content

    @Test("Content: Validate Class metamodel structure")
    func testStep01ValidateClassMetamodel() async throws {
        let classEcorePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("class.ecore")

        let content = try String(contentsOf: classEcorePath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("ecore:EPackage"))
        #expect(content.contains("name=\"Class\""))
        #expect(content.contains("nsURI=\"http://www.example.org/class\""))

        // Verify key classes exist
        #expect(content.contains("name=\"Package\""))
        #expect(content.contains("name=\"Class\""))
        #expect(content.contains("name=\"Attribute\""))
        #expect(content.contains("name=\"DataType\""))
        #expect(content.contains("name=\"Classifier\""))
        #expect(content.contains("name=\"NamedElement\""))
    }

    @Test("Content: Validate Class metamodel features")
    func testStep02ValidateClassFeatures() async throws {
        let classEcorePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("class.ecore")
        let content = try String(contentsOf: classEcorePath, encoding: .utf8)

        // Verify Package contains classifiers
        #expect(content.contains("name=\"classifiers\""))

        // Verify Class has key features
        #expect(content.contains("name=\"isAbstract\""))
        #expect(content.contains("name=\"superType\""))
        #expect(content.contains("name=\"attributes\""))

        // Verify Attribute has key features
        #expect(content.contains("name=\"multiValued\""))
        #expect(content.contains("name=\"type\""))
        #expect(content.contains("name=\"owner\""))
    }

    // MARK: - Section 3: Validate Target Metamodel (Relational) Content

    @Test("Content: Validate Relational metamodel structure")
    func testStep03ValidateRelationalMetamodel() async throws {
        let relationalEcorePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("relational.ecore")

        let content = try String(contentsOf: relationalEcorePath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("ecore:EPackage"))
        #expect(content.contains("name=\"Relational\""))
        #expect(content.contains("nsURI=\"http://www.example.org/relational\""))

        // Verify key classes exist
        #expect(content.contains("name=\"Schema\""))
        #expect(content.contains("name=\"Table\""))
        #expect(content.contains("name=\"Column\""))
        #expect(content.contains("name=\"Type\""))
    }

    @Test("Content: Validate Relational metamodel features")
    func testStep04ValidateRelationalFeatures() async throws {
        let relationalEcorePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("relational.ecore")
        let content = try String(contentsOf: relationalEcorePath, encoding: .utf8)

        // Verify Schema contains tables and types
        #expect(content.contains("name=\"tables\""))
        #expect(content.contains("name=\"types\""))

        // Verify Table has key features
        #expect(content.contains("name=\"columns\""))
        #expect(content.contains("name=\"key\""))
        #expect(content.contains("name=\"schema\""))

        // Verify Column has type reference
        #expect(content.contains("name=\"keyOf\""))
    }

    // MARK: - Section 4: Validate ATL Transformation

    @Test("ATL: Validate transformation module declaration")
    func testStep05ValidateModuleDeclaration() async throws {
        let atlPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("class2relational.atl")

        #expect(FileManager.default.fileExists(atPath: atlPath.path))

        let content = try String(contentsOf: atlPath, encoding: .utf8)

        // Verify module declaration
        #expect(content.contains("module Class2Relational"))
        #expect(content.contains("create OUT: Relational from IN: Class"))
    }

    @Test("ATL: Validate helper functions")
    func testStep06ValidateHelpers() async throws {
        let atlPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("class2relational.atl")
        let content = try String(contentsOf: atlPath, encoding: .utf8)

        // Verify allAttributes helper
        #expect(content.contains("helper context Class!Class def: allAttributes"))
        #expect(content.contains("superType"))

        // Verify isDataType helper
        #expect(content.contains("helper context Class!Classifier def: isDataType"))
        #expect(content.contains("oclIsTypeOf"))

        // Verify sqlTypeName helper
        #expect(content.contains("helper context Class!DataType def: sqlTypeName"))
        #expect(content.contains("INTEGER"))
        #expect(content.contains("VARCHAR"))
        #expect(content.contains("BOOLEAN"))
    }

    @Test("ATL: Validate Package2Schema rule")
    func testStep07ValidatePackage2SchemaRule() async throws {
        let atlPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("class2relational.atl")
        let content = try String(contentsOf: atlPath, encoding: .utf8)

        #expect(content.contains("rule Package2Schema"))
        #expect(content.contains("p: Class!Package"))
        #expect(content.contains("s: Relational!Schema"))
        #expect(content.contains("name <- p.name"))
        #expect(content.contains("tables <-"))
        #expect(content.contains("types <-"))
    }

    @Test("ATL: Validate Class2Table rule")
    func testStep08ValidateClass2TableRule() async throws {
        let atlPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("class2relational.atl")
        let content = try String(contentsOf: atlPath, encoding: .utf8)

        #expect(content.contains("rule Class2Table"))
        #expect(content.contains("c: Class!Class"))
        #expect(content.contains("not c.isAbstract"))
        #expect(content.contains("t: Relational!Table"))
        #expect(content.contains("key: Relational!Column"))
        #expect(content.contains("name <- 'id'"))
        #expect(content.contains("keyOf <- t"))
    }

    @Test("ATL: Validate attribute transformation rules")
    func testStep09ValidateAttributeRules() async throws {
        let atlPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("class2relational.atl")
        let content = try String(contentsOf: atlPath, encoding: .utf8)

        // SingleValuedAttribute2Column rule
        #expect(content.contains("rule SingleValuedAttribute2Column"))
        #expect(content.contains("not a.multiValued"))
        #expect(content.contains("c: Relational!Column"))

        // MultiValuedAttribute2Table rule
        #expect(content.contains("rule MultiValuedAttribute2Table"))
        #expect(content.contains("a.multiValued"))
        #expect(content.contains("t: Relational!Table"))

        // ClassAttribute2ForeignKey rule
        #expect(content.contains("rule ClassAttribute2ForeignKey"))
        #expect(content.contains("fk: Relational!Column"))
        #expect(content.contains("_id"))
    }

    // MARK: - Section 5: Validate Sample Input Model Content

    @Test("Content: Validate sample classes model")
    func testStep10ValidateSampleInput() async throws {
        let samplePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("sample-classes.xmi")

        let content = try String(contentsOf: samplePath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("xmi:XMI"))
        #expect(content.contains("class:Package"))
        #expect(content.contains("name=\"library\""))

        // Verify data types
        #expect(content.contains("name=\"Integer\""))
        #expect(content.contains("name=\"String\""))
        #expect(content.contains("name=\"Boolean\""))
        #expect(content.contains("name=\"Date\""))

        // Verify classes
        #expect(content.contains("name=\"Author\""))
        #expect(content.contains("name=\"Book\""))
        #expect(content.contains("name=\"Member\""))
        #expect(content.contains("name=\"Loan\""))
    }

    @Test("Content: Validate sample model attributes")
    func testStep11ValidateSampleAttributes() async throws {
        let samplePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("sample-classes.xmi")
        let content = try String(contentsOf: samplePath, encoding: .utf8)

        // Verify Author attributes
        #expect(content.contains("name=\"firstName\""))
        #expect(content.contains("name=\"lastName\""))
        #expect(content.contains("name=\"birthYear\""))

        // Verify Book attributes (including multi-valued)
        #expect(content.contains("name=\"title\""))
        #expect(content.contains("name=\"isbn\""))
        #expect(content.contains("name=\"keywords\" multiValued=\"true\""))

        // Verify Member attributes
        #expect(content.contains("name=\"memberNumber\""))
        #expect(content.contains("name=\"email\""))
        #expect(content.contains("name=\"borrowedBooks\" multiValued=\"true\""))
    }

    // MARK: - Section 6: Validate Expected Output Content

    @Test("Content: Validate expected output schema")
    func testStep12ValidateExpectedOutput() async throws {
        let outputPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected-output.xmi")

        let content = try String(contentsOf: outputPath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("xmi:XMI"))
        #expect(content.contains("relational:Schema"))
        #expect(content.contains("name=\"library\""))

        // Verify SQL types created
        #expect(content.contains("name=\"INTEGER\""))
        #expect(content.contains("name=\"VARCHAR(255)\""))
        #expect(content.contains("name=\"BOOLEAN\""))
        #expect(content.contains("name=\"DATE\""))
    }

    @Test("Content: Validate expected tables")
    func testStep13ValidateExpectedTables() async throws {
        let outputPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected-output.xmi")
        let content = try String(contentsOf: outputPath, encoding: .utf8)

        // Verify main tables created from classes
        #expect(content.contains("<tables name=\"Author\""))
        #expect(content.contains("<tables name=\"Book\""))
        #expect(content.contains("<tables name=\"Member\""))
        #expect(content.contains("<tables name=\"Loan\""))

        // Verify multi-valued attribute tables
        #expect(content.contains("<tables name=\"Book_keywords\""))
        #expect(content.contains("<tables name=\"Member_borrowedBooks\""))
    }

    @Test("Content: Validate primary keys")
    func testStep14ValidatePrimaryKeys() async throws {
        let outputPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected-output.xmi")
        let content = try String(contentsOf: outputPath, encoding: .utf8)

        // Verify id columns exist as primary keys
        #expect(content.contains("<columns name=\"id\""))
        #expect(content.contains("keyOf="))

        // Count id columns (should be 4 - one for each main table)
        let idColumns = content.components(separatedBy: "<columns name=\"id\"").count - 1
        #expect(idColumns >= 4, "Expected at least 4 primary key columns")
    }

    @Test("Content: Validate foreign keys")
    func testStep15ValidateForeignKeys() async throws {
        let outputPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected-output.xmi")
        let content = try String(contentsOf: outputPath, encoding: .utf8)

        // Verify foreign key columns for class-typed attributes
        #expect(content.contains("name=\"author_id\""))
        #expect(content.contains("name=\"book_id\""))
        #expect(content.contains("name=\"member_id\""))
    }

    @Test("Content: Validate multi-valued attribute tables")
    func testStep16ValidateMultiValuedTables() async throws {
        let outputPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected-output.xmi")
        let content = try String(contentsOf: outputPath, encoding: .utf8)

        // Book_keywords table should have book_id and keywords columns
        #expect(content.contains("<tables name=\"Book_keywords\""))

        // Member_borrowedBooks table should have member_id and borrowedBooks columns
        #expect(content.contains("<tables name=\"Member_borrowedBooks\""))
    }
}
