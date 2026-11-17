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

    @Test("Step 1.1: Validate Organisation metamodel")
    func testStep01ValidateMetamodel() async throws {
        let metamodelPath = tutorialCodePath.appendingPathComponent("ecore-07-step-01-organisation.ecore")

        #expect(FileManager.default.fileExists(atPath: metamodelPath.path))

        let content = try String(contentsOf: metamodelPath, encoding: .utf8)
        #expect(content.contains("name=\"Organisation\""))
        #expect(content.contains("name=\"Department\""))
        #expect(content.contains("name=\"relatedDepartments\""))
    }

    // MARK: - Section 2: Creating Linked Models

    @Test("Step 2.1: Validate Shared Library model")
    func testStep02ValidateSharedModel() async throws {
        let sharedPath = tutorialCodePath.appendingPathComponent("ecore-07-step-02-shared.xmi")

        #expect(FileManager.default.fileExists(atPath: sharedPath.path))

        let content = try String(contentsOf: sharedPath, encoding: .utf8)
        #expect(content.contains("<org:Department xmi:id=\"it\" name=\"IT\"/>"))
        #expect(content.contains("name=\"HR\""))
    }

    @Test("Step 2.2: Validate Project referencing Library")
    func testStep03ValidateProjectModel() async throws {
        let projectPath = tutorialCodePath.appendingPathComponent("ecore-07-step-03-project.xmi")

        #expect(FileManager.default.fileExists(atPath: projectPath.path))

        let content = try String(contentsOf: projectPath, encoding: .utf8)
        #expect(content.contains("name=\"Project Alpha\""))

        // Check for the href to the external file
        #expect(content.contains("href=\"SharedDeps.xmi#it\""))
    }

    // MARK: - The href explanation

    @Test("Step 1.2: The href that the tutorial explains names an identifier of the shared library")
    func testHrefMatchesSharedIdentifier() async throws {
        let project = try String(
            contentsOf: tutorialCodePath.appendingPathComponent("ecore-07-step-03-project.xmi"), encoding: .utf8)
        let shared = try String(
            contentsOf: tutorialCodePath.appendingPathComponent("ecore-07-step-02-shared.xmi"), encoding: .utf8)

        #expect(project.contains("<relatedDepartments href=\"SharedDeps.xmi#it\"/>"))
        #expect(shared.contains("xmi:id=\"it\""))
    }

    @Test("Step 1.2: The tutorial shows ProjectA.xmi before it explains the href")
    func testTutorialShowsFileBeforeExplaining() async throws {
        let tutorial = tutorialCodePath
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Tutorials")
            .appendingPathComponent("Ecore-CLI")
            .appendingPathComponent("07-cross-resource-refs.tutorial")
        let content = try String(contentsOf: tutorial, encoding: .utf8)

        let firstShown = try #require(content.range(of: "file: ecore-07-step-03-project.xmi"))
        let sharedCreated = try #require(content.range(of: "file: ecore-07-step-02-shared.xmi"))
        let explanation = try #require(content.range(of: "Read the two parts of an `href`"))
        #expect(firstShown.lowerBound < sharedCreated.lowerBound)
        #expect(content.contains("a file that you create and use later in this tutorial"))
        #expect(content.contains("`/0`"))
        #expect(content.contains("`//@employees.1`"))
        #expect(firstShown.lowerBound < explanation.lowerBound)
        #expect(explanation.lowerBound < sharedCreated.lowerBound)
    }
}
