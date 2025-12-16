//
// Families2PersonsTests.swift
// swift-atl-tests
//
//  Created on 16/12/2025.
//

import Foundation
import XCTest

/// Test suite for the Families2Persons ATL transformation tutorial.
///
/// This test suite validates the complete Families2Persons transformation workflow,
/// including parsing the ATL transformation, validating it, and verifying the
/// transformation files are properly structured.
final class Families2PersonsTests: XCTestCase {

    /// Base path for test resources.
    let resourcesPath = "Tests/swift-atl-tests/Resources"

    /// Path to the ATL transformation file.
    var transformationPath: String {
        "\(resourcesPath)/transformations/Families2Persons.atl"
    }

    /// Path to the Families metamodel.
    var familiesMetamodelPath: String {
        "\(resourcesPath)/metamodels/Families.ecore"
    }

    /// Path to the Persons metamodel.
    var personsMetamodelPath: String {
        "\(resourcesPath)/metamodels/Persons.ecore"
    }

    /// Path to the sample Families model.
    var sampleFamiliesPath: String {
        "\(resourcesPath)/models/sample-Families.xmi"
    }

    /// Path to the expected Persons output.
    var expectedPersonsPath: String {
        "\(resourcesPath)/models/expected-Persons.xmi"
    }

    /// Output path for generated Persons model.
    var outputPersonsPath: String {
        "/tmp/output-Persons.xmi"
    }

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        // Ensure output directory exists
        try? FileManager.default.createDirectory(
            atPath: "/tmp",
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    override func tearDown() {
        super.tearDown()
        // Clean up generated files
        try? FileManager.default.removeItem(atPath: outputPersonsPath)
    }

    // MARK: - Test Metamodel Loading

    /// Tests that the Families metamodel can be loaded successfully.
    func testLoadFamiliesMetamodel() throws {
        let metamodelURL = URL(fileURLWithPath: familiesMetamodelPath)
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: familiesMetamodelPath),
            "Families metamodel file should exist")

        let content = try String(contentsOf: metamodelURL, encoding: .utf8)
        XCTAssertTrue(
            content.contains("name=\"Families\""),
            "Metamodel should define Families package")
        XCTAssertTrue(
            content.contains("name=\"Family\""),
            "Metamodel should define Family class")
        XCTAssertTrue(
            content.contains("name=\"Member\""),
            "Metamodel should define Member class")
        XCTAssertTrue(
            content.contains("name=\"lastName\""),
            "Family should have lastName attribute")
        XCTAssertTrue(
            content.contains("name=\"firstName\""),
            "Member should have firstName attribute")
    }

    /// Tests that the Persons metamodel can be loaded successfully.
    func testLoadPersonsMetamodel() throws {
        let metamodelURL = URL(fileURLWithPath: personsMetamodelPath)
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: personsMetamodelPath),
            "Persons metamodel file should exist")

        let content = try String(contentsOf: metamodelURL, encoding: .utf8)
        XCTAssertTrue(
            content.contains("name=\"Persons\""),
            "Metamodel should define Persons package")
        XCTAssertTrue(
            content.contains("name=\"Person\""),
            "Metamodel should define Person class")
        XCTAssertTrue(
            content.contains("abstract=\"true\""),
            "Person class should be abstract")
        XCTAssertTrue(
            content.contains("name=\"Male\""),
            "Metamodel should define Male class")
        XCTAssertTrue(
            content.contains("name=\"Female\""),
            "Metamodel should define Female class")
        XCTAssertTrue(
            content.contains("name=\"fullName\""),
            "Person should have fullName attribute")
    }

    // MARK: - Test ATL Transformation Parsing

    /// Tests that the Families2Persons ATL transformation file is properly structured.
    func testFamilies2PersonsTransformationStructure() throws {
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: transformationPath),
            "ATL transformation file should exist")

        let content = try String(
            contentsOf: URL(fileURLWithPath: transformationPath), encoding: .utf8)

        // Verify module declaration
        XCTAssertTrue(
            content.contains("module Families2Persons"),
            "Transformation should declare Families2Persons module")

        // Verify metamodel references
        XCTAssertTrue(
            content.contains("create OUT: Persons from IN: Families"),
            "Transformation should define input and output models")

        // Verify helpers
        XCTAssertTrue(
            content.contains("helper context Families!Member def: isFemale()"),
            "Transformation should define isFemale helper")
        XCTAssertTrue(
            content.contains("helper context Families!Member def: familyName"),
            "Transformation should define familyName helper")

        // Verify transformation rules
        XCTAssertTrue(
            content.contains("rule Member2Male"),
            "Transformation should define Member2Male rule")
        XCTAssertTrue(
            content.contains("rule Member2Female"),
            "Transformation should define Member2Female rule")
    }

    // MARK: - Test ATL File Content

    /// Tests that the ATL transformation contains proper helper definitions.
    func testTransformationHelpers() throws {
        let content = try String(
            contentsOf: URL(fileURLWithPath: transformationPath), encoding: .utf8)

        // Verify isFemale helper logic
        XCTAssertTrue(
            content.contains("self.familyMother.oclIsUndefined()"),
            "isFemale helper should check familyMother")
        XCTAssertTrue(
            content.contains("self.familyDaughter.oclIsUndefined()"),
            "isFemale helper should check familyDaughter")

        // Verify familyName helper logic
        XCTAssertTrue(
            content.contains("self.familyFather.lastName"),
            "familyName helper should access father's lastName")
        XCTAssertTrue(
            content.contains("self.familyMother.lastName"),
            "familyName helper should access mother's lastName")
    }

    /// Tests that the ATL transformation contains proper rule definitions.
    func testTransformationRules() throws {
        let content = try String(
            contentsOf: URL(fileURLWithPath: transformationPath), encoding: .utf8)

        // Verify Member2Male rule
        XCTAssertTrue(
            content.contains("from\n\t\ts: Families!Member (not s.isFemale())"),
            "Member2Male should match non-female members")
        XCTAssertTrue(
            content.contains("to\n\t\tt: Persons!Male"),
            "Member2Male should create Male persons")

        // Verify Member2Female rule
        XCTAssertTrue(
            content.contains("from\n\t\ts: Families!Member (s.isFemale())"),
            "Member2Female should match female members")
        XCTAssertTrue(
            content.contains("to\n\t\tt: Persons!Female"),
            "Member2Female should create Female persons")

        // Verify full name concatenation
        XCTAssertTrue(
            content.contains("fullName <- s.firstName + ' ' + s.familyName"),
            "Rules should concatenate first and last names")
    }

    // MARK: - Test Model Files

    /// Tests that the sample Families model is properly structured.
    func testSampleFamiliesModelStructure() throws {
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: sampleFamiliesPath),
            "Sample families model should exist")

        let content = try String(
            contentsOf: URL(fileURLWithPath: sampleFamiliesPath), encoding: .utf8)

        // Verify we have three families
        XCTAssertTrue(
            content.contains("lastName=\"March\""),
            "Model should contain March family")
        XCTAssertTrue(
            content.contains("lastName=\"Sailor\""),
            "Model should contain Sailor family")
        XCTAssertTrue(
            content.contains("lastName=\"Smith\""),
            "Model should contain Smith family")

        // Verify March family members
        XCTAssertTrue(
            content.contains("<father firstName=\"Jim\"/>"),
            "March family should have father Jim")
        XCTAssertTrue(
            content.contains("<mother firstName=\"Cindy\"/>"),
            "March family should have mother Cindy")
        XCTAssertTrue(
            content.contains("<sons firstName=\"Brandon\"/>"),
            "March family should have son Brandon")
        XCTAssertTrue(
            content.contains("<daughters firstName=\"Brenda\"/>"),
            "March family should have daughter Brenda")

        // Verify Sailor family has multiple children
        XCTAssertTrue(
            content.contains("<sons firstName=\"David\"/>"),
            "Sailor family should have son David")
        XCTAssertTrue(
            content.contains("<sons firstName=\"Dylan\"/>"),
            "Sailor family should have son Dylan")
    }

    // MARK: - Test Expected Output

    /// Tests that the expected output file has the correct structure.
    func testExpectedOutputStructure() throws {
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: expectedPersonsPath),
            "Expected persons output should exist")

        let content = try String(
            contentsOf: URL(fileURLWithPath: expectedPersonsPath), encoding: .utf8)

        // Count expected persons
        let maleCount = content.components(separatedBy: "<Male").count - 1
        let femaleCount = content.components(separatedBy: "<Female").count - 1

        XCTAssertEqual(maleCount, 6, "Expected output should have 6 males")
        XCTAssertEqual(femaleCount, 7, "Expected output should have 7 females")
        XCTAssertEqual(maleCount + femaleCount, 13, "Expected output should have 13 total persons")
    }

    // MARK: - Test Tutorial Files Exist

    /// Tests that all required tutorial files exist.
    func testAllTutorialFilesExist() {
        // Check metamodels
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: familiesMetamodelPath),
            "Families metamodel should exist")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: personsMetamodelPath),
            "Persons metamodel should exist")

        // Check transformation
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: transformationPath),
            "ATL transformation should exist")

        // Check sample data
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: sampleFamiliesPath),
            "Sample families model should exist")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: expectedPersonsPath),
            "Expected persons output should exist")
    }

    /// Tests the expected person names in the output.
    func testExpectedPersonNames() throws {
        let content = try String(
            contentsOf: URL(fileURLWithPath: expectedPersonsPath), encoding: .utf8)

        // March family
        XCTAssertTrue(content.contains("Jim March"), "Should contain Jim March")
        XCTAssertTrue(content.contains("Cindy March"), "Should contain Cindy March")
        XCTAssertTrue(content.contains("Brandon March"), "Should contain Brandon March")
        XCTAssertTrue(content.contains("Brenda March"), "Should contain Brenda March")

        // Sailor family
        XCTAssertTrue(content.contains("Peter Sailor"), "Should contain Peter Sailor")
        XCTAssertTrue(content.contains("Jackie Sailor"), "Should contain Jackie Sailor")
        XCTAssertTrue(content.contains("David Sailor"), "Should contain David Sailor")
        XCTAssertTrue(content.contains("Dylan Sailor"), "Should contain Dylan Sailor")
        XCTAssertTrue(content.contains("Kelly Sailor"), "Should contain Kelly Sailor")

        // Smith family
        XCTAssertTrue(content.contains("John Smith"), "Should contain John Smith")
        XCTAssertTrue(content.contains("Sarah Smith"), "Should contain Sarah Smith")
        XCTAssertTrue(content.contains("Emma Smith"), "Should contain Emma Smith")
        XCTAssertTrue(content.contains("Olivia Smith"), "Should contain Olivia Smith")
    }

    /// Tests the gender assignments in the expected output.
    func testExpectedGenderAssignments() throws {
        let content = try String(
            contentsOf: URL(fileURLWithPath: expectedPersonsPath), encoding: .utf8)

        // Males
        XCTAssertTrue(content.contains("<Male fullName=\"Jim March\""), "Jim should be Male")
        XCTAssertTrue(
            content.contains("<Male fullName=\"Brandon March\""), "Brandon should be Male")
        XCTAssertTrue(content.contains("<Male fullName=\"Peter Sailor\""), "Peter should be Male")
        XCTAssertTrue(content.contains("<Male fullName=\"David Sailor\""), "David should be Male")
        XCTAssertTrue(content.contains("<Male fullName=\"Dylan Sailor\""), "Dylan should be Male")
        XCTAssertTrue(content.contains("<Male fullName=\"John Smith\""), "John should be Male")

        // Females
        XCTAssertTrue(
            content.contains("<Female fullName=\"Cindy March\""), "Cindy should be Female")
        XCTAssertTrue(
            content.contains("<Female fullName=\"Brenda March\""), "Brenda should be Female")
        XCTAssertTrue(
            content.contains("<Female fullName=\"Jackie Sailor\""), "Jackie should be Female")
        XCTAssertTrue(
            content.contains("<Female fullName=\"Kelly Sailor\""), "Kelly should be Female")
        XCTAssertTrue(
            content.contains("<Female fullName=\"Sarah Smith\""), "Sarah should be Female")
        XCTAssertTrue(content.contains("<Female fullName=\"Emma Smith\""), "Emma should be Female")
        XCTAssertTrue(
            content.contains("<Female fullName=\"Olivia Smith\""), "Olivia should be Female")
    }

}
