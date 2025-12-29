import Testing
import Foundation

/// Test suite for ATL Tutorial 01: Creating Your First ATL Transformation
/// Validates each step of the Families2Persons transformation tutorial
@Suite("Tutorial: Creating Your First ATL Transformation")
struct ATL01Tests {

    let tutorialCodePath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")
        .appendingPathComponent("SwiftModelling")
        .appendingPathComponent("SwiftModelling.docc")
        .appendingPathComponent("Resources")
        .appendingPathComponent("Code")
        .appendingPathComponent("ATL-Tutorial-01")

    // MARK: - Section 1: Understand the Metamodels

    @Test("Step 1.1: Validate Families metamodel structure")
    func testStep01ValidateFamiliesMetamodel() async throws {
        // Load the Families metamodel
        let familiesEcorePath = tutorialCodePath.appendingPathComponent("01-first-transformation-families.ecore")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: familiesEcorePath.path))

        // Verify it's valid XMI
        let content = try String(contentsOf: familiesEcorePath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("ecore:EPackage"))
        #expect(content.contains("name=\"Families\""))
        #expect(content.contains("nsURI=\"http://www.example.org/families\""))

        // Verify contains Family and Member classes
        #expect(content.contains("name=\"Family\""))
        #expect(content.contains("name=\"Member\""))

        // Verify key references
        #expect(content.contains("name=\"father\""))
        #expect(content.contains("name=\"mother\""))
        #expect(content.contains("name=\"sons\""))
        #expect(content.contains("name=\"daughters\""))
    }

    @Test("Step 1.2: Validate Persons metamodel structure")
    func testStep02ValidatePersonsMetamodel() async throws {
        // Load the Persons metamodel
        let personsEcorePath = tutorialCodePath.appendingPathComponent("01-first-transformation-persons.ecore")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: personsEcorePath.path))

        // Verify it's valid XMI
        let content = try String(contentsOf: personsEcorePath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("ecore:EPackage"))
        #expect(content.contains("name=\"Persons\""))
        #expect(content.contains("nsURI=\"http://www.example.org/persons\""))

        // Verify contains Person, Male, and Female classes
        #expect(content.contains("name=\"Person\""))
        #expect(content.contains("abstract=\"true\""))
        #expect(content.contains("name=\"Male\""))
        #expect(content.contains("name=\"Female\""))

        // Verify fullName attribute
        #expect(content.contains("name=\"fullName\""))
    }

    @Test("Step 1.3: Load sample input model")
    func testStep03LoadSampleInput() async throws {
        // Load the sample families model
        let samplePath = tutorialCodePath.appendingPathComponent("01-first-transformation-sample.xmi")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: samplePath.path))

        // Verify it's valid XMI
        let content = try String(contentsOf: samplePath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("xmi:XMI"))

        // Verify contains 3 families
        #expect(content.contains("lastName=\"March\""))
        #expect(content.contains("lastName=\"Sailor\""))
        #expect(content.contains("lastName=\"Smith\""))

        // Verify first family members
        #expect(content.contains("firstName=\"Jim\""))
        #expect(content.contains("firstName=\"Cindy\""))
        #expect(content.contains("firstName=\"Brandon\""))
        #expect(content.contains("firstName=\"Brenda\""))
    }

    // MARK: - Section 2: Write Helper Functions

    @Test("Step 2.1: Validate isFemale helper exists")
    func testStep04ValidateIsFemaleHelper() async throws {
        // Load the ATL transformation
        let atlPath = tutorialCodePath.appendingPathComponent("01-first-transformation-complete.atl")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: atlPath.path))

        let atlContent = try String(contentsOf: atlPath, encoding: .utf8)

        // Verify helper definition exists
        #expect(atlContent.contains("helper context Families!Member def: isFemale()"))
        #expect(atlContent.contains("Boolean"))

        // Verify helper checks familyMother
        #expect(atlContent.contains("familyMother"))
        #expect(atlContent.contains("oclIsUndefined()"))

        // Verify helper checks familyDaughter
        #expect(atlContent.contains("familyDaughter"))
    }

    @Test("Step 2.2: Validate familyName helper exists")
    func testStep05ValidateFamilyNameHelper() async throws {
        // Load the ATL transformation
        let atlPath = tutorialCodePath.appendingPathComponent("01-first-transformation-complete.atl")
        let atlContent = try String(contentsOf: atlPath, encoding: .utf8)

        // Verify helper definition exists
        #expect(atlContent.contains("helper context Families!Member def: familyName"))
        #expect(atlContent.contains("String"))

        // Verify helper checks all family relationships
        #expect(atlContent.contains("familyFather.lastName"))
        #expect(atlContent.contains("familyMother.lastName"))
        #expect(atlContent.contains("familySon.lastName"))
        #expect(atlContent.contains("familyDaughter.lastName"))
    }

    // MARK: - Section 3: Define Transformation Rules

    @Test("Step 3.1: Validate Member2Male rule structure")
    func testStep06ValidateMember2MaleRule() async throws {
        // Load the ATL transformation
        let atlPath = tutorialCodePath.appendingPathComponent("01-first-transformation-complete.atl")
        let atlContent = try String(contentsOf: atlPath, encoding: .utf8)

        // Verify rule exists
        #expect(atlContent.contains("rule Member2Male"))

        // Verify source pattern
        #expect(atlContent.contains("from"))
        #expect(atlContent.contains("s: Families!Member"))
        #expect(atlContent.contains("not s.isFemale()"))

        // Verify target pattern
        #expect(atlContent.contains("to"))
        #expect(atlContent.contains("t: Persons!Male"))

        // Verify binding
        #expect(atlContent.contains("fullName <- s.firstName + ' ' + s.familyName"))
    }

    @Test("Step 3.2: Validate Member2Female rule structure")
    func testStep07ValidateMember2FemaleRule() async throws {
        // Load the ATL transformation
        let atlPath = tutorialCodePath.appendingPathComponent("01-first-transformation-complete.atl")
        let atlContent = try String(contentsOf: atlPath, encoding: .utf8)

        // Verify rule exists
        #expect(atlContent.contains("rule Member2Female"))

        // Verify source pattern
        #expect(atlContent.contains("s: Families!Member"))
        #expect(atlContent.contains("s.isFemale()"))

        // Verify target pattern
        #expect(atlContent.contains("t: Persons!Female"))

        // Verify binding
        #expect(atlContent.contains("fullName <- s.firstName + ' ' + s.familyName"))
    }

    @Test("Step 3.3: Validate complete transformation module")
    func testStep08ValidateCompleteModule() async throws {
        // Load the ATL transformation
        let atlPath = tutorialCodePath.appendingPathComponent("01-first-transformation-complete.atl")
        let atlContent = try String(contentsOf: atlPath, encoding: .utf8)

        // Verify module declaration
        #expect(atlContent.contains("module Families2Persons"))

        // Verify model declarations
        #expect(atlContent.contains("create OUT: Persons from IN: Families"))

        // Verify both helpers exist
        #expect(atlContent.contains("def: isFemale()"))
        #expect(atlContent.contains("def: familyName"))

        // Verify both rules exist
        #expect(atlContent.contains("rule Member2Male"))
        #expect(atlContent.contains("rule Member2Female"))
    }

    // MARK: - Section 4: Run the Transformation

    @Test("Step 4.1: Verify transformation input files exist")
    func testStep09VerifyInputFiles() async throws {
        // Check that all required input files exist
        let familiesEcore = tutorialCodePath.appendingPathComponent("01-first-transformation-families.ecore")
        let personsEcore = tutorialCodePath.appendingPathComponent("01-first-transformation-persons.ecore")
        let sampleXMI = tutorialCodePath.appendingPathComponent("01-first-transformation-sample.xmi")
        let atlFile = tutorialCodePath.appendingPathComponent("01-first-transformation-complete.atl")

        #expect(FileManager.default.fileExists(atPath: familiesEcore.path))
        #expect(FileManager.default.fileExists(atPath: personsEcore.path))
        #expect(FileManager.default.fileExists(atPath: sampleXMI.path))
        #expect(FileManager.default.fileExists(atPath: atlFile.path))
    }

    @Test("Step 4.2: Validate expected output structure")
    func testStep10ValidateExpectedOutput() async throws {
        // Load the expected output
        let outputPath = tutorialCodePath.appendingPathComponent("01-first-transformation-output.xmi")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: outputPath.path))

        // Verify it's valid XMI
        let content = try String(contentsOf: outputPath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("xmi:XMI"))

        // Verify contains both Male and Female persons
        #expect(content.contains("<Male "))
        #expect(content.contains("<Female "))

        // Count occurrences of Male and Female
        let maleCount = content.components(separatedBy: "<Male ").count - 1
        let femaleCount = content.components(separatedBy: "<Female ").count - 1

        // Based on sample input: 3 fathers + 3 sons = 6 males, 3 mothers + 4 daughters = 7 females
        #expect(maleCount == 6)
        #expect(femaleCount == 7)
    }

    @Test("Step 4.3: Verify specific person mappings")
    func testStep11VerifyPersonMappings() async throws {
        // Load the expected output
        let outputPath = tutorialCodePath.appendingPathComponent("01-first-transformation-output.xmi")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: outputPath.path))

        let content = try String(contentsOf: outputPath, encoding: .utf8)

        // Verify specific male persons (from fathers and sons)
        #expect(content.contains("fullName=\"Jim March\""))
        #expect(content.contains("fullName=\"Brandon March\""))
        #expect(content.contains("fullName=\"Peter Sailor\""))
        #expect(content.contains("fullName=\"David Sailor\""))
        #expect(content.contains("fullName=\"Dylan Sailor\""))
        #expect(content.contains("fullName=\"John Smith\""))

        // Verify specific female persons (from mothers and daughters)
        #expect(content.contains("fullName=\"Cindy March\""))
        #expect(content.contains("fullName=\"Brenda March\""))
        #expect(content.contains("fullName=\"Jackie Sailor\""))
        #expect(content.contains("fullName=\"Kelly Sailor\""))
        #expect(content.contains("fullName=\"Sarah Smith\""))
        #expect(content.contains("fullName=\"Emma Smith\""))
        #expect(content.contains("fullName=\"Olivia Smith\""))
    }
}
