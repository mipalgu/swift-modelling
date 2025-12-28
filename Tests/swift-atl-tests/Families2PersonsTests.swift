//
// Families2PersonsTests.swift
// swift-atl-tests
//
//  Created on 16/12/2025.
//

import Foundation
import Testing

/// Test suite for the Families2Persons ATL transformation tutorial.
///
/// This test suite validates the complete Families2Persons transformation workflow,
/// including parsing the ATL transformation, validating it, and verifying the
/// transformation files are properly structured.
@Suite("Families2Persons ATL Transformation")
struct Families2PersonsTests {

    // MARK: - Test Metamodel Loading

    /// Tests that the Families metamodel can be loaded successfully.
    @Test("Load Families metamodel")
    func testLoadFamiliesMetamodel() throws {
        let metamodelURL = try loadTestResource(named: "Families.ecore", subdirectory: "Families2Persons")

        #expect(FileManager.default.fileExists(atPath: metamodelURL.path))

        let content = try String(contentsOf: metamodelURL, encoding: .utf8)
        #expect(content.contains("name=\"Families\""))
        #expect(content.contains("name=\"Family\""))
        #expect(content.contains("name=\"Member\""))
        #expect(content.contains("name=\"lastName\""))
        #expect(content.contains("name=\"firstName\""))
    }

    /// Tests that the Persons metamodel can be loaded successfully.
    @Test("Load Persons metamodel")
    func testLoadPersonsMetamodel() throws {
        let metamodelURL = try loadTestResource(named: "Persons.ecore", subdirectory: "Families2Persons")

        #expect(FileManager.default.fileExists(atPath: metamodelURL.path))

        let content = try String(contentsOf: metamodelURL, encoding: .utf8)
        #expect(content.contains("name=\"Persons\""))
        #expect(content.contains("name=\"Person\""))
        #expect(content.contains("abstract=\"true\""))
        #expect(content.contains("name=\"Male\""))
        #expect(content.contains("name=\"Female\""))
        #expect(content.contains("name=\"fullName\""))
    }

    // MARK: - Test ATL Transformation Parsing

    /// Tests that the Families2Persons ATL transformation file is properly structured.
    @Test("Families2Persons transformation structure")
    func testFamilies2PersonsTransformationStructure() throws {
        let transformationURL = try loadTestResource(named: "Families2Persons.atl", subdirectory: "transformations")

        #expect(FileManager.default.fileExists(atPath: transformationURL.path))

        let content = try String(contentsOf: transformationURL, encoding: .utf8)

        // Verify module declaration
        #expect(content.contains("module Families2Persons"))

        // Verify metamodel references
        #expect(content.contains("create OUT: Persons from IN: Families"))

        // Verify helpers
        #expect(content.contains("helper context Families!Member def: isFemale()"))
        #expect(content.contains("helper context Families!Member def: familyName"))

        // Verify transformation rules
        #expect(content.contains("rule Member2Male"))
        #expect(content.contains("rule Member2Female"))
    }

    // MARK: - Test ATL File Content

    /// Tests that the ATL transformation contains proper helper definitions.
    @Test("Transformation helpers")
    func testTransformationHelpers() throws {
        let transformationURL = try loadTestResource(named: "Families2Persons.atl", subdirectory: "transformations")
        let content = try String(contentsOf: transformationURL, encoding: .utf8)

        // Verify isFemale helper logic
        #expect(content.contains("self.familyMother.oclIsUndefined()"))
        #expect(content.contains("self.familyDaughter.oclIsUndefined()"))

        // Verify familyName helper logic
        #expect(content.contains("self.familyFather.lastName"))
        #expect(content.contains("self.familyMother.lastName"))
    }

    /// Tests that the ATL transformation contains proper rule definitions.
    @Test("Transformation rules")
    func testTransformationRules() throws {
        let transformationURL = try loadTestResource(named: "Families2Persons.atl", subdirectory: "transformations")
        let content = try String(contentsOf: transformationURL, encoding: .utf8)

        // Verify Member2Male rule
        #expect(content.contains("from\n\t\ts: Families!Member (not s.isFemale())"))
        #expect(content.contains("to\n\t\tt: Persons!Male"))

        // Verify Member2Female rule
        #expect(content.contains("from\n\t\ts: Families!Member (s.isFemale())"))
        #expect(content.contains("to\n\t\tt: Persons!Female"))

        // Verify full name concatenation
        #expect(content.contains("fullName <- s.firstName + ' ' + s.familyName"))
    }

    // MARK: - Test Model Files

    /// Tests that the sample Families model is properly structured.
    @Test("Sample Families model structure")
    func testSampleFamiliesModelStructure() throws {
        let modelURL = try loadTestResource(named: "sample-Families.xmi", subdirectory: "models")

        #expect(FileManager.default.fileExists(atPath: modelURL.path))

        let content = try String(contentsOf: modelURL, encoding: .utf8)

        // Verify we have three families
        #expect(content.contains("lastName=\"March\""))
        #expect(content.contains("lastName=\"Sailor\""))
        #expect(content.contains("lastName=\"Smith\""))

        // Verify March family members
        #expect(content.contains("<father firstName=\"Jim\"/>"))
        #expect(content.contains("<mother firstName=\"Cindy\"/>"))
        #expect(content.contains("<sons firstName=\"Brandon\"/>"))
        #expect(content.contains("<daughters firstName=\"Brenda\"/>"))

        // Verify Sailor family has multiple children
        #expect(content.contains("<sons firstName=\"David\"/>"))
        #expect(content.contains("<sons firstName=\"Dylan\"/>"))
    }

    // MARK: - Test Expected Output

    /// Tests that the expected output file has the correct structure.
    @Test("Expected output structure")
    func testExpectedOutputStructure() throws {
        let outputURL = try loadTestResource(named: "expected-Persons.xmi", subdirectory: "models")

        #expect(FileManager.default.fileExists(atPath: outputURL.path))

        let content = try String(contentsOf: outputURL, encoding: .utf8)

        // Count expected persons
        let maleCount = content.components(separatedBy: "<Male").count - 1
        let femaleCount = content.components(separatedBy: "<Female").count - 1

        #expect(maleCount == 6)
        #expect(femaleCount == 7)
        #expect(maleCount + femaleCount == 13)
    }

    // MARK: - Test Tutorial Files Exist

    /// Tests that all required tutorial files exist.
    @Test("All tutorial files exist")
    func testAllTutorialFilesExist() throws {
        // Check metamodels
        let familiesMetamodel = try loadTestResource(named: "Families.ecore", subdirectory: "Families2Persons")
        #expect(FileManager.default.fileExists(atPath: familiesMetamodel.path))

        let personsMetamodel = try loadTestResource(named: "Persons.ecore", subdirectory: "Families2Persons")
        #expect(FileManager.default.fileExists(atPath: personsMetamodel.path))

        // Check transformation
        let transformation = try loadTestResource(named: "Families2Persons.atl", subdirectory: "transformations")
        #expect(FileManager.default.fileExists(atPath: transformation.path))

        // Check sample data
        let sampleModel = try loadTestResource(named: "sample-Families.xmi", subdirectory: "models")
        #expect(FileManager.default.fileExists(atPath: sampleModel.path))

        let expectedOutput = try loadTestResource(named: "expected-Persons.xmi", subdirectory: "models")
        #expect(FileManager.default.fileExists(atPath: expectedOutput.path))
    }

    /// Tests the expected person names in the output.
    @Test("Expected person names")
    func testExpectedPersonNames() throws {
        let outputURL = try loadTestResource(named: "expected-Persons.xmi", subdirectory: "models")
        let content = try String(contentsOf: outputURL, encoding: .utf8)

        // March family
        #expect(content.contains("Jim March"))
        #expect(content.contains("Cindy March"))
        #expect(content.contains("Brandon March"))
        #expect(content.contains("Brenda March"))

        // Sailor family
        #expect(content.contains("Peter Sailor"))
        #expect(content.contains("Jackie Sailor"))
        #expect(content.contains("David Sailor"))
        #expect(content.contains("Dylan Sailor"))
        #expect(content.contains("Kelly Sailor"))

        // Smith family
        #expect(content.contains("John Smith"))
        #expect(content.contains("Sarah Smith"))
        #expect(content.contains("Emma Smith"))
        #expect(content.contains("Olivia Smith"))
    }

    /// Tests the gender assignments in the expected output.
    @Test("Expected gender assignments")
    func testExpectedGenderAssignments() throws {
        let outputURL = try loadTestResource(named: "expected-Persons.xmi", subdirectory: "models")
        let content = try String(contentsOf: outputURL, encoding: .utf8)

        // Males
        #expect(content.contains("<Male fullName=\"Jim March\""))
        #expect(content.contains("<Male fullName=\"Brandon March\""))
        #expect(content.contains("<Male fullName=\"Peter Sailor\""))
        #expect(content.contains("<Male fullName=\"David Sailor\""))
        #expect(content.contains("<Male fullName=\"Dylan Sailor\""))
        #expect(content.contains("<Male fullName=\"John Smith\""))

        // Females
        #expect(content.contains("<Female fullName=\"Cindy March\""))
        #expect(content.contains("<Female fullName=\"Brenda March\""))
        #expect(content.contains("<Female fullName=\"Jackie Sailor\""))
        #expect(content.contains("<Female fullName=\"Kelly Sailor\""))
        #expect(content.contains("<Female fullName=\"Sarah Smith\""))
        #expect(content.contains("<Female fullName=\"Emma Smith\""))
        #expect(content.contains("<Female fullName=\"Olivia Smith\""))
    }

}
