import Testing
import Foundation

/// Test suite for Ecore Tutorial 07: Cross-Resource References
/// Validates splitting models across files and managing cross-resource references
@Suite("Tutorial: Cross-Resource References")
struct Ecore07Tests {

    let tutorialCodePath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")
        .appendingPathComponent("SwiftModelling")
        .appendingPathComponent("SwiftModelling.docc")
        .appendingPathComponent("Resources")
        .appendingPathComponent("Code")
        .appendingPathComponent("Ecore-Tutorial-07")

    // MARK: - Section 1: Understanding Resources and Proxies

    @Test("Step 1.1: Validate Organization metamodel")
    func testStep01ValidateMetamodel() async throws {
        let metamodelPath = tutorialCodePath.appendingPathComponent("ecore-07-step-01-organization.ecore")

        #expect(FileManager.default.fileExists(atPath: metamodelPath.path))

        let content = try String(contentsOf: metamodelPath, encoding: .utf8)
        #expect(content.contains("name=\"Organization\""))
        #expect(content.contains("name=\"Department\""))
        #expect(content.contains("name=\"relatedDepartments\""))
    }

    // MARK: - Section 2: Creating Linked Models

    @Test("Step 2.1: Validate Shared Library model")
    func testStep02ValidateSharedModel() async throws {
        let sharedPath = tutorialCodePath.appendingPathComponent("ecore-07-step-02-shared.xmi")

        #expect(FileManager.default.fileExists(atPath: sharedPath.path))

        let content = try String(contentsOf: sharedPath, encoding: .utf8)
        #expect(content.contains("name=\"Shared Services\""))
        #expect(content.contains("name=\"IT\""))
        #expect(content.contains("name=\"HR\""))
    }

    @Test("Step 2.2: Validate Project referencing Library")
    func testStep03ValidateProjectModel() async throws {
        let projectPath = tutorialCodePath.appendingPathComponent("ecore-07-step-03-project.xmi")

        #expect(FileManager.default.fileExists(atPath: projectPath.path))

        let content = try String(contentsOf: projectPath, encoding: .utf8)
        #expect(content.contains("name=\"Project Alpha\""))

        // Check for the href to the external file
        #expect(content.contains("href=\"SharedDeps.xmi#//@relatedDepartments.0\""))
    }
}
