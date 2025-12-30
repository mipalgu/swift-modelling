import Testing
import Foundation

/// Test suite for ATL Tutorials 02-08
/// Validates tutorial resources and content
@Suite("ATL Tutorials 02-08 Validation")
struct ATL02to08Tests {

    let resourcesPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")
        .appendingPathComponent("SwiftModelling")
        .appendingPathComponent("SwiftModelling.docc")
        .appendingPathComponent("Resources")
        .appendingPathComponent("Code")

    // MARK: - Tutorial 02: ATL Helpers and Guards

    @Test("Tutorial 02: Verify all resource files exist")
    func testTutorial02ResourcesExist() async throws {
        let tutorial02Path = resourcesPath.appendingPathComponent("ATL-Tutorial-02")

        // Verify directory exists
        #expect(FileManager.default.fileExists(atPath: tutorial02Path.path))

        // Verify step 1 (metamodel) exists
        let step01 = tutorial02Path.appendingPathComponent("atl-02-step-01-library-metamodel.ecore")
        #expect(FileManager.default.fileExists(atPath: step01.path))

        // Verify step 2-8 (ATL files) exist
        for step in 2...8 {
            let fileName = String(format: "atl-02-step-%02d", step)
            let contents = try FileManager.default.contentsOfDirectory(atPath: tutorial02Path.path)
            let matchingFiles = contents.filter { $0.hasPrefix(fileName) && $0.hasSuffix(".atl") }
            #expect(!matchingFiles.isEmpty, "Expected at least one file matching \(fileName)*.atl")
        }
    }

    @Test("Tutorial 02: Validate helper syntax")
    func testTutorial02HelperSyntax() async throws {
        let tutorial02Path = resourcesPath.appendingPathComponent("ATL-Tutorial-02")
        let step02Path = tutorial02Path.appendingPathComponent("atl-02-step-02-attribute-helper.atl")

        let content = try String(contentsOf: step02Path, encoding: .utf8)
        #expect(content.contains("helper context"))
        #expect(content.contains("def: isClassic()"))
    }

    @Test("Tutorial 02: Validate guard conditions")
    func testTutorial02GuardConditions() async throws {
        let tutorial02Path = resourcesPath.appendingPathComponent("ATL-Tutorial-02")
        let step05Path = tutorial02Path.appendingPathComponent("atl-02-step-05-simple-guard.atl")

        let content = try String(contentsOf: step05Path, encoding: .utf8)
        #expect(content.contains("from"))
        #expect(content.contains("(s.yearPublished"))
    }

    // MARK: - Tutorial 03: Working with Collections

    @Test("Tutorial 03: Verify collect operation")
    func testTutorial03CollectOperation() async throws {
        let tutorial03Path = resourcesPath.appendingPathComponent("ATL-Tutorial-03")
        let step02Path = tutorial03Path.appendingPathComponent("atl-03-step-02-collect-operation.atl")

        let content = try String(contentsOf: step02Path, encoding: .utf8)
        #expect(content.contains("->collect("))
    }

    @Test("Tutorial 03: Verify select operation")
    func testTutorial03SelectOperation() async throws {
        let tutorial03Path = resourcesPath.appendingPathComponent("ATL-Tutorial-03")
        let step03Path = tutorial03Path.appendingPathComponent("atl-03-step-03-select-operation.atl")

        let content = try String(contentsOf: step03Path, encoding: .utf8)
        #expect(content.contains("->select("))
    }

    @Test("Tutorial 03: Verify reject operation")
    func testTutorial03RejectOperation() async throws {
        let tutorial03Path = resourcesPath.appendingPathComponent("ATL-Tutorial-03")
        let step04Path = tutorial03Path.appendingPathComponent("atl-03-step-04-reject-operation.atl")

        let content = try String(contentsOf: step04Path, encoding: .utf8)
        #expect(content.contains("->reject("))
    }

    @Test("Tutorial 03: Verify exists operation")
    func testTutorial03ExistsOperation() async throws {
        let tutorial03Path = resourcesPath.appendingPathComponent("ATL-Tutorial-03")
        let step05Path = tutorial03Path.appendingPathComponent("atl-03-step-05-exists-operation.atl")

        let content = try String(contentsOf: step05Path, encoding: .utf8)
        #expect(content.contains("->exists("))
    }

    @Test("Tutorial 03: Verify forAll operation")
    func testTutorial03ForAllOperation() async throws {
        let tutorial03Path = resourcesPath.appendingPathComponent("ATL-Tutorial-03")
        let step06Path = tutorial03Path.appendingPathComponent("atl-03-step-06-forall-operation.atl")

        let content = try String(contentsOf: step06Path, encoding: .utf8)
        #expect(content.contains("->forAll("))
    }

    @Test("Tutorial 03: Verify chained operations")
    func testTutorial03ChainedOperations() async throws {
        let tutorial03Path = resourcesPath.appendingPathComponent("ATL-Tutorial-03")
        let step07Path = tutorial03Path.appendingPathComponent("atl-03-step-07-combined-operations.atl")

        let content = try String(contentsOf: step07Path, encoding: .utf8)
        #expect(content.contains("->select("))
        #expect(content.contains("->collect("))
    }

    // MARK: - Tutorial 04: Advanced Rule Patterns

    @Test("Tutorial 04: Verify lazy rule syntax")
    func testTutorial04LazyRule() async throws {
        let tutorial04Path = resourcesPath.appendingPathComponent("ATL-Tutorial-04")
        let step02Path = tutorial04Path.appendingPathComponent("atl-04-step-02-lazy-rule.atl")

        let content = try String(contentsOf: step02Path, encoding: .utf8)
        #expect(content.contains("lazy rule"))
    }

    @Test("Tutorial 04: Verify lazy rule invocation")
    func testTutorial04LazyRuleInvocation() async throws {
        let tutorial04Path = resourcesPath.appendingPathComponent("ATL-Tutorial-04")
        let step03Path = tutorial04Path.appendingPathComponent("atl-04-step-03-calling-lazy.atl")

        let content = try String(contentsOf: step03Path, encoding: .utf8)
        #expect(content.contains("thisModule."))
    }

    @Test("Tutorial 04: Verify called rule syntax")
    func testTutorial04CalledRule() async throws {
        let tutorial04Path = resourcesPath.appendingPathComponent("ATL-Tutorial-04")
        let step05Path = tutorial04Path.appendingPathComponent("atl-04-step-05-called-rule.atl")

        let content = try String(contentsOf: step05Path, encoding: .utf8)
        #expect(content.contains("rule") && content.contains("("))
    }

    @Test("Tutorial 04: Verify do block")
    func testTutorial04DoBlock() async throws {
        let tutorial04Path = resourcesPath.appendingPathComponent("ATL-Tutorial-04")
        let step06Path = tutorial04Path.appendingPathComponent("atl-04-step-06-do-block.atl")

        let content = try String(contentsOf: step06Path, encoding: .utf8)
        #expect(content.contains("do {"))
    }

    // MARK: - Tutorial 05: OCL Expressions Deep Dive

    @Test("Tutorial 05: Verify navigation expressions")
    func testTutorial05Navigation() async throws {
        let tutorial05Path = resourcesPath.appendingPathComponent("ATL-Tutorial-05")
        let step02Path = tutorial05Path.appendingPathComponent("atl-05-step-02-navigation.atl")

        let content = try String(contentsOf: step02Path, encoding: .utf8)
        #expect(content.contains("->collect("))
        #expect(content.contains("->size()"))
    }

    @Test("Tutorial 05: Verify type checking operations")
    func testTutorial05TypeChecking() async throws {
        let tutorial05Path = resourcesPath.appendingPathComponent("ATL-Tutorial-05")
        let step03Path = tutorial05Path.appendingPathComponent("atl-05-step-03-type-checking.atl")

        let content = try String(contentsOf: step03Path, encoding: .utf8)
        #expect(content.contains("oclIsTypeOf"))
    }

    @Test("Tutorial 05: Verify type casting")
    func testTutorial05TypeCasting() async throws {
        let tutorial05Path = resourcesPath.appendingPathComponent("ATL-Tutorial-05")
        let step04Path = tutorial05Path.appendingPathComponent("atl-05-step-04-type-casting.atl")

        let content = try String(contentsOf: step04Path, encoding: .utf8)
        #expect(content.contains("oclAsType"))
    }

    @Test("Tutorial 05: Verify string operations")
    func testTutorial05StringOperations() async throws {
        let tutorial05Path = resourcesPath.appendingPathComponent("ATL-Tutorial-05")
        let step05Path = tutorial05Path.appendingPathComponent("atl-05-step-05-string-operations.atl")

        let content = try String(contentsOf: step05Path, encoding: .utf8)
        #expect(content.contains("toUpper") || content.contains("concat") || content.contains("+"))
    }

    @Test("Tutorial 05: Verify numeric operations")
    func testTutorial05NumericOperations() async throws {
        let tutorial05Path = resourcesPath.appendingPathComponent("ATL-Tutorial-05")
        let step06Path = tutorial05Path.appendingPathComponent("atl-05-step-06-numeric-operations.atl")

        let content = try String(contentsOf: step06Path, encoding: .utf8)
        #expect(content.contains(">") || content.contains("->sum()"))
    }

    // MARK: - Tutorial 06: Debugging Transformations

    @Test("Tutorial 06: Verify defensive checks")
    func testTutorial06DefensiveChecks() async throws {
        let tutorial06Path = resourcesPath.appendingPathComponent("ATL-Tutorial-06")
        let step02Path = tutorial06Path.appendingPathComponent("atl-06-step-02-defensive-checks.atl")

        let content = try String(contentsOf: step02Path, encoding: .utf8)
        #expect(content.contains("oclIsUndefined"))
    }

    @Test("Tutorial 06: Verify error handling pattern")
    func testTutorial06ErrorHandling() async throws {
        let tutorial06Path = resourcesPath.appendingPathComponent("ATL-Tutorial-06")
        let step08Path = tutorial06Path.appendingPathComponent("atl-06-step-08-robust-transformation.atl")

        let content = try String(contentsOf: step08Path, encoding: .utf8)
        #expect(content.contains("if") && content.contains("else"))
    }

    // MARK: - Tutorial 07: Complex Model Transformations

    @Test("Tutorial 07: Verify refining mode syntax")
    func testTutorial07RefiningMode() async throws {
        let tutorial07Path = resourcesPath.appendingPathComponent("ATL-Tutorial-07")
        let step01Path = tutorial07Path.appendingPathComponent("atl-07-step-01-refining-mode.atl")

        let content = try String(contentsOf: step01Path, encoding: .utf8)
        #expect(content.contains("refining"))
    }

    @Test("Tutorial 07: Verify multiple source models")
    func testTutorial07MultipleSources() async throws {
        let tutorial07Path = resourcesPath.appendingPathComponent("ATL-Tutorial-07")
        let step05Path = tutorial07Path.appendingPathComponent("atl-07-step-05-multiple-sources.atl")

        let content = try String(contentsOf: step05Path, encoding: .utf8)
        #expect(content.contains("from INA:") && content.contains("INB:"))
    }

    // MARK: - Tutorial 08: Performance Optimisation

    @Test("Tutorial 08: Verify anti-patterns identified")
    func testTutorial08AntiPatterns() async throws {
        let tutorial08Path = resourcesPath.appendingPathComponent("ATL-Tutorial-08")
        let step01Path = tutorial08Path.appendingPathComponent("atl-08-step-01-inefficient-patterns.atl")

        #expect(FileManager.default.fileExists(atPath: step01Path.path))
    }

    @Test("Tutorial 08: Verify caching pattern")
    func testTutorial08Caching() async throws {
        let tutorial08Path = resourcesPath.appendingPathComponent("ATL-Tutorial-08")
        let step02Path = tutorial08Path.appendingPathComponent("atl-08-step-02-caching-results.atl")

        let content = try String(contentsOf: step02Path, encoding: .utf8)
        #expect(content.contains("helper context"))
    }

    @Test("Tutorial 08: Verify optimised patterns")
    func testTutorial08OptimisedPatterns() async throws {
        let tutorial08Path = resourcesPath.appendingPathComponent("ATL-Tutorial-08")
        let step08Path = tutorial08Path.appendingPathComponent("atl-08-step-08-complete-optimised.atl")

        let content = try String(contentsOf: step08Path, encoding: .utf8)
        #expect(content.contains("rule"))
    }

    // MARK: - Tutorial File Structure Validation

    @Test("Verify all tutorial directories exist")
    func testAllTutorialDirectoriesExist() async throws {
        for tutorial in 2...8 {
            let tutorialPath = resourcesPath.appendingPathComponent("ATL-Tutorial-0\(tutorial)")
            #expect(FileManager.default.fileExists(atPath: tutorialPath.path),
                   "Tutorial \(tutorial) directory should exist")
        }
    }

    @Test("Verify tutorial .tutorial files exist")
    func testTutorialFilesExist() async throws {
        let tutorialsPath = resourcesPath
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Tutorials")
            .appendingPathComponent("ATL-CLI")

        let expectedTutorials = [
            "ATL-02-helpers-guards.tutorial",
            "ATL-03-collections.tutorial",
            "ATL-04-advanced-rules.tutorial",
            "ATL-05-ocl-expressions.tutorial",
            "ATL-06-debugging.tutorial",
            "ATL-07-complex-transformations.tutorial",
            "ATL-08-performance.tutorial"
        ]

        for tutorialFile in expectedTutorials {
            let tutorialPath = tutorialsPath.appendingPathComponent(tutorialFile)
            #expect(FileManager.default.fileExists(atPath: tutorialPath.path),
                   "\(tutorialFile) should exist")
        }
    }
}
