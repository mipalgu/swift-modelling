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

        // Verify step 3-9 (ATL files) exist
        for step in 3...9 {
            let fileName = String(format: "atl-02-step-%02d", step)
            let contents = try FileManager.default.contentsOfDirectory(atPath: tutorial02Path.path)
            let matchingFiles = contents.filter { $0.hasPrefix(fileName) && $0.hasSuffix(".atl") }
            #expect(!matchingFiles.isEmpty, "Expected at least one file matching \(fileName)*.atl")
        }
    }

    @Test("Tutorial 02: Validate helper syntax")
    func testTutorial02HelperSyntax() async throws {
        let tutorial02Path = resourcesPath.appendingPathComponent("ATL-Tutorial-02")
        let step02Path = tutorial02Path.appendingPathComponent("atl-02-step-03-attribute-helper.atl")

        let content = try String(contentsOf: step02Path, encoding: .utf8)
        #expect(content.contains("helper context"))
        #expect(content.contains("def: isClassic()"))
    }

    @Test("Tutorial 02: Validate guard conditions")
    func testTutorial02GuardConditions() async throws {
        let tutorial02Path = resourcesPath.appendingPathComponent("ATL-Tutorial-02")
        let step05Path = tutorial02Path.appendingPathComponent("atl-02-step-06-simple-guard.atl")

        let content = try String(contentsOf: step05Path, encoding: .utf8)
        #expect(content.contains("from"))
        #expect(content.contains("(s.yearPublished"))
    }

    // MARK: - Tutorial 03: Working with Collections

    @Test("Tutorial 03: Verify collect operation")
    func testTutorial03CollectOperation() async throws {
        let tutorial03Path = resourcesPath.appendingPathComponent("ATL-Tutorial-03")
        let step02Path = tutorial03Path.appendingPathComponent("atl-03-step-03-collect-operation.atl")

        let content = try String(contentsOf: step02Path, encoding: .utf8)
        #expect(content.contains("->collect("))
    }

    @Test("Tutorial 03: Verify select operation")
    func testTutorial03SelectOperation() async throws {
        let tutorial03Path = resourcesPath.appendingPathComponent("ATL-Tutorial-03")
        let step03Path = tutorial03Path.appendingPathComponent("atl-03-step-04-select-operation.atl")

        let content = try String(contentsOf: step03Path, encoding: .utf8)
        #expect(content.contains("->select("))
    }

    @Test("Tutorial 03: Verify reject operation")
    func testTutorial03RejectOperation() async throws {
        let tutorial03Path = resourcesPath.appendingPathComponent("ATL-Tutorial-03")
        let step04Path = tutorial03Path.appendingPathComponent("atl-03-step-05-reject-operation.atl")

        let content = try String(contentsOf: step04Path, encoding: .utf8)
        #expect(content.contains("->reject("))
    }

    @Test("Tutorial 03: Verify exists operation")
    func testTutorial03ExistsOperation() async throws {
        let tutorial03Path = resourcesPath.appendingPathComponent("ATL-Tutorial-03")
        let step05Path = tutorial03Path.appendingPathComponent("atl-03-step-06-exists-operation.atl")

        let content = try String(contentsOf: step05Path, encoding: .utf8)
        #expect(content.contains("->exists("))
    }

    @Test("Tutorial 03: Verify forAll operation")
    func testTutorial03ForAllOperation() async throws {
        let tutorial03Path = resourcesPath.appendingPathComponent("ATL-Tutorial-03")
        let step06Path = tutorial03Path.appendingPathComponent("atl-03-step-07-forall-operation.atl")

        let content = try String(contentsOf: step06Path, encoding: .utf8)
        #expect(content.contains("->forAll("))
    }

    @Test("Tutorial 03: Verify chained operations")
    func testTutorial03ChainedOperations() async throws {
        let tutorial03Path = resourcesPath.appendingPathComponent("ATL-Tutorial-03")
        let step07Path = tutorial03Path.appendingPathComponent("atl-03-step-08-combined-operations.atl")

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
        let step10Path = tutorial04Path.appendingPathComponent("atl-04-step-10-called-rule.atl")

        let content = try String(contentsOf: step10Path, encoding: .utf8)
        #expect(content.contains("rule") && content.contains("("))
    }

    @Test("Tutorial 04: Verify do block")
    func testTutorial04DoBlock() async throws {
        let tutorial04Path = resourcesPath.appendingPathComponent("ATL-Tutorial-04")
        let step11Path = tutorial04Path.appendingPathComponent("atl-04-step-11-do-block.atl")

        let content = try String(contentsOf: step11Path, encoding: .utf8)
        #expect(content.contains("do {"))
    }

    // MARK: - Tutorial 05: OCL Expressions Deep Dive

    @Test("Tutorial 05: Verify navigation expressions")
    func testTutorial05Navigation() async throws {
        let tutorial05Path = resourcesPath.appendingPathComponent("ATL-Tutorial-05")
        let step02Path = tutorial05Path.appendingPathComponent("atl-05-step-03-navigation.atl")

        let content = try String(contentsOf: step02Path, encoding: .utf8)
        #expect(content.contains("->collect("))
        #expect(content.contains("->size()"))
    }

    @Test("Tutorial 05: Verify type checking operations")
    func testTutorial05TypeChecking() async throws {
        let tutorial05Path = resourcesPath.appendingPathComponent("ATL-Tutorial-05")
        let step03Path = tutorial05Path.appendingPathComponent("atl-05-step-04-type-checking.atl")

        let content = try String(contentsOf: step03Path, encoding: .utf8)
        #expect(content.contains("oclIsTypeOf"))
    }

    @Test("Tutorial 05: Verify type casting")
    func testTutorial05TypeCasting() async throws {
        let tutorial05Path = resourcesPath.appendingPathComponent("ATL-Tutorial-05")
        let step04Path = tutorial05Path.appendingPathComponent("atl-05-step-05-type-casting.atl")

        let content = try String(contentsOf: step04Path, encoding: .utf8)
        #expect(content.contains("oclAsType"))
    }

    @Test("Tutorial 05: Verify string operations")
    func testTutorial05StringOperations() async throws {
        let tutorial05Path = resourcesPath.appendingPathComponent("ATL-Tutorial-05")
        let step10Path = tutorial05Path.appendingPathComponent("atl-05-step-11-string-operations.atl")

        let content = try String(contentsOf: step10Path, encoding: .utf8)
        #expect(content.contains("toUpper") || content.contains("concat") || content.contains("+"))
    }

    @Test("Tutorial 05: Verify numeric operations")
    func testTutorial05NumericOperations() async throws {
        let tutorial05Path = resourcesPath.appendingPathComponent("ATL-Tutorial-05")
        let step11Path = tutorial05Path.appendingPathComponent("atl-05-step-12-numeric-operations.atl")

        let content = try String(contentsOf: step11Path, encoding: .utf8)
        #expect(content.contains(">") || content.contains("->sum()"))
    }

    // MARK: - Tutorial 06: Debugging Transformations

    @Test("Tutorial 06: Verify defensive checks")
    func testTutorial06DefensiveChecks() async throws {
        let tutorial06Path = resourcesPath.appendingPathComponent("ATL-Tutorial-06")
        let step02Path = tutorial06Path.appendingPathComponent("atl-06-step-04-defensive-checks.atl")

        let content = try String(contentsOf: step02Path, encoding: .utf8)
        #expect(content.contains("oclIsUndefined"))
    }

    @Test("Tutorial 06: Verify error handling pattern")
    func testTutorial06ErrorHandling() async throws {
        let tutorial06Path = resourcesPath.appendingPathComponent("ATL-Tutorial-06")
        let step08Path = tutorial06Path.appendingPathComponent("atl-06-step-10-robust-transformation.atl")

        let content = try String(contentsOf: step08Path, encoding: .utf8)
        #expect(content.contains("if") && content.contains("else"))
    }

    // MARK: - Tutorial 07: Complex Model Transformations

    @Test("Tutorial 07: Verify refining mode syntax")
    func testTutorial07RefiningMode() async throws {
        let tutorial07Path = resourcesPath.appendingPathComponent("ATL-Tutorial-07")
        let step02Path = tutorial07Path.appendingPathComponent("atl-07-step-02-refining-mode.atl")

        let content = try String(contentsOf: step02Path, encoding: .utf8)
        #expect(content.contains("create OUT: Model refining IN: Model;"))
    }

    @Test("Tutorial 07: Verify multiple source models")
    func testTutorial07MultipleSources() async throws {
        let tutorial07Path = resourcesPath.appendingPathComponent("ATL-Tutorial-07")
        let step12Path = tutorial07Path.appendingPathComponent("atl-07-step-12-multiple-sources.atl")

        let content = try String(contentsOf: step12Path, encoding: .utf8)
        #expect(content.contains("from INA:") && content.contains("INB:"))
    }

    // MARK: - Tutorial 08: Performance Optimisation

    @Test("Tutorial 08: Verify anti-patterns identified")
    func testTutorial08AntiPatterns() async throws {
        let tutorial08Path = resourcesPath.appendingPathComponent("ATL-Tutorial-08")
        let step01Path = tutorial08Path.appendingPathComponent("atl-08-step-03-inefficient-patterns.atl")

        #expect(FileManager.default.fileExists(atPath: step01Path.path))
    }

    @Test("Tutorial 08: Verify caching pattern")
    func testTutorial08Caching() async throws {
        let tutorial08Path = resourcesPath.appendingPathComponent("ATL-Tutorial-08")
        let step02Path = tutorial08Path.appendingPathComponent("atl-08-step-04-caching-results.atl")

        let content = try String(contentsOf: step02Path, encoding: .utf8)
        #expect(content.contains("helper context"))
    }

    @Test("Tutorial 08: Verify optimised patterns")
    func testTutorial08OptimisedPatterns() async throws {
        let tutorial08Path = resourcesPath.appendingPathComponent("ATL-Tutorial-08")
        let step08Path = tutorial08Path.appendingPathComponent("atl-08-step-10-complete-optimised.atl")

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

// MARK: - Tutorials 02, 06 and 08: metamodels and runs

extension ATL02to08Tests {
    /// The shared checks of the tutorials that show their metamodels.
    typealias Checks = ATL03to05ExecutionTests

    /// The tutorials on helpers and guards, on debugging and on performance, with the metamodels
    /// that they show and the sample models on which their transformations run.
    static let metamodels = [
        Checks.TargetMetamodel(
            tutorial: 2, tutorialFile: "ATL-02-helpers-guards.tutorial", sourceName: "Library.ecore",
            sourceFile: "atl-02-step-01-library-metamodel.ecore", targetName: "Catalog.ecore",
            targetFile: "atl-02-step-02-catalog-metamodel.ecore", transformationName: "LibraryTransform.atl",
            sampleFile: "atl-02-step-10-sample-library.xmi", sampleName: "library.xmi",
            features: [
                Checks.ExpectedFeature(className: "Item", name: "title", type: "//EString", isMany: false),
                Checks.ExpectedFeature(className: "Item", name: "category", type: "//EString", isMany: false),
                Checks.ExpectedFeature(className: "Item", name: "description", type: "//EString", isMany: false),
            ]),
        Checks.TargetMetamodel(
            tutorial: 6, tutorialFile: "ATL-06-debugging.tutorial", sourceName: "Source.ecore",
            sourceFile: "atl-06-step-01-source-metamodel.ecore", targetName: "Target.ecore",
            targetFile: "atl-06-step-02-target-metamodel.ecore", transformationName: "DebugExample.atl",
            sampleFile: "atl-06-step-11-sample-source.xmi", sampleName: "source.xmi",
            features: [
                Checks.ExpectedFeature(className: "Item", name: "name", type: "//EString", isMany: false),
                Checks.ExpectedFeature(className: "Item", name: "description", type: "//EString", isMany: false),
            ]),
        Checks.TargetMetamodel(
            tutorial: 8, tutorialFile: "ATL-08-performance.tutorial", sourceName: "Source.ecore",
            sourceFile: "atl-08-step-01-source-metamodel.ecore", targetName: "Target.ecore",
            targetFile: "atl-08-step-02-target-metamodel.ecore", transformationName: "OptimisationExample.atl",
            sampleFile: "atl-08-step-11-sample-source.xmi", sampleName: "source.xmi",
            features: [
                Checks.ExpectedFeature(className: "Item", name: "name", type: "//EString", isMany: false),
                Checks.ExpectedFeature(className: "Item", name: "count", type: "//EInt", isMany: false),
                Checks.ExpectedFeature(className: "Item", name: "names", type: "//EString", isMany: true),
                Checks.ExpectedFeature(className: "SpecialItem", name: "name", type: "//EString", isMany: false),
                Checks.ExpectedFeature(className: "SpecialItem", name: "specialProperty", type: "//EString", isMany: false),
            ]),
    ]

    /// A source metamodel that a tutorial shows itself, as a test argument.
    struct SourceMetamodel: Sendable, CustomTestStringConvertible {
        /// The tutorial and its metamodels.
        let metamodel: Checks.TargetMetamodel

        /// The features of the source metamodel, each with the end of its `eType` reference, such as
        /// `//EString` for an attribute or `//Element` for a reference.
        let features: [Checks.ExpectedFeature]

        /// The classes of the source metamodel that have a supertype, each with that supertype.
        let supertypes: [String: String]

        var testDescription: String { metamodel.sourceFile }
    }

    /// The source metamodels of the tutorials on debugging and on performance, which earlier
    /// tutorials do not provide.
    static let sourceMetamodels = [
        SourceMetamodel(
            metamodel: metamodels[1],
            features: [
                Checks.ExpectedFeature(className: "Container", name: "elements", type: "//Element", isMany: true),
                Checks.ExpectedFeature(className: "Container", name: "children", type: "//Element", isMany: true),
                Checks.ExpectedFeature(className: "Element", name: "name", type: "//EString", isMany: false),
                Checks.ExpectedFeature(className: "Element", name: "description", type: "//EString", isMany: false),
                Checks.ExpectedFeature(className: "Element", name: "parent", type: "//Element", isMany: false),
                Checks.ExpectedFeature(className: "Element", name: "items", type: "//Element", isMany: true),
            ],
            supertypes: [:]),
        SourceMetamodel(
            metamodel: metamodels[2],
            features: [
                Checks.ExpectedFeature(className: "Container", name: "name", type: "//EString", isMany: false),
                Checks.ExpectedFeature(className: "Container", name: "elements", type: "//Element", isMany: true),
                Checks.ExpectedFeature(className: "Element", name: "name", type: "//EString", isMany: false),
                Checks.ExpectedFeature(className: "Element", name: "active", type: "//EBoolean", isMany: false),
                Checks.ExpectedFeature(className: "Element", name: "priority", type: "//EInt", isMany: false),
                Checks.ExpectedFeature(
                    className: "SpecialElement", name: "specialValue", type: "//EString", isMany: false),
            ],
            supertypes: ["SpecialElement": "Element"]),
    ]

    /// The lines that the target model of each complete transformation must contain, by resource.
    static let completeTargetLines: [String: [String]] = [
        "atl-02-step-09-complete-transformation.atl": [
            "<libcat:Item title=\"The Lantern Keeper\" category=\"Classic\" description=\"Published 1894 (19th century) by Harriet Quill\"/>",
            "<libcat:Item title=\"Winter Ledger\" category=\"Classic\" description=\"Published 1931 (20th century) by Harriet Quill\"/>",
            "<libcat:Item title=\"Northern Tides\" category=\"Modern\" description=\"Published 1978 (20th century) by Jonah Brightwater\"/>",
            "<libcat:Item title=\"Glass Orchard\" category=\"Modern\" description=\"Published 2015 (21st century) by Jonah Brightwater\"/>",
        ],
        "atl-06-step-10-robust-transformation.atl": [
            "<tgt:Item name=\"Root Element\" description=\"The whole garden\"/>",
            "<tgt:Item name=\"Garden\" description=\"No description provided\"/>",
            "<tgt:Item name=\"Garden\" description=\"Rosemary, thyme and sage\"/>",
        ],
        "atl-08-step-10-complete-optimised.atl": [
            "name=\"Backlog\" count=\"3\">",
            "<names>Login page</names>",
            "<names>Search</names>",
            "<names>Release notes</names>",
        ],
    ]

    /// Every module of the three tutorials, each with the lines its target model must contain.
    static let modules: [Checks.TargetModule] = metamodels.flatMap { metamodel in
        Checks.modules(of: metamodel.tutorial).map {
            Checks.TargetModule(metamodel: metamodel, file: $0, expectedLines: completeTargetLines[$0] ?? [])
        }
    }

    /// The steps that end a section of a tutorial by running its complete transformation.
    struct RunSteps: Sendable, CustomTestStringConvertible {
        /// The tutorial and its metamodels.
        let metamodel: Checks.TargetMetamodel

        /// The title of the section that ends with the run.
        let section: String

        /// The resource of the complete transformation.
        let transformationFile: String

        /// The resource of the Terminal script that runs it.
        let scriptFile: String

        /// The file name under which the tutorial shows the target model that the run writes.
        let resultName: String

        /// The resource that shows the target model.
        let resultFile: String

        /// The number of commands that the script runs.
        let commands: Int

        /// The steps in order, each with the name under which the tutorial shows it and its resource.
        var codes: [(name: String, file: String)] {
            [
                (metamodel.transformationName, transformationFile), (metamodel.sampleName, metamodel.sampleFile),
                ("Terminal", scriptFile), (resultName, resultFile),
            ]
        }

        var testDescription: String { metamodel.tutorialFile }
    }

    /// The runs that end the three tutorials.
    static let runs = [
        RunSteps(
            metamodel: metamodels[0], section: "Using Guard Conditions",
            transformationFile: "atl-02-step-09-complete-transformation.atl",
            scriptFile: "atl-02-step-11-run-complete.sh", resultName: "catalog.xmi",
            resultFile: "atl-02-step-12-catalog.xmi", commands: 3),
        RunSteps(
            metamodel: metamodels[1], section: "Debugging Techniques",
            transformationFile: "atl-06-step-10-robust-transformation.atl",
            scriptFile: "atl-06-step-12-run-complete.sh", resultName: "target.xmi",
            resultFile: "atl-06-step-13-target.xmi", commands: 4),
        RunSteps(
            metamodel: metamodels[2], section: "Advanced Optimisation Techniques",
            transformationFile: "atl-08-step-10-complete-optimised.atl",
            scriptFile: "atl-08-step-12-run-complete.sh", resultName: "target.xmi",
            resultFile: "atl-08-step-13-target.xmi", commands: 4),
    ]

    /// A query that evaluates helpers of a tutorial on its sample model.
    struct HelperQuery: Sendable, CustomTestStringConvertible {
        /// The tutorial and its metamodels.
        let metamodel: Checks.TargetMetamodel

        /// The modules whose helpers the query defines.
        let modules: [String]

        /// The expression of the query, which calls the helpers.
        let expression: String

        /// The value that swift-atl prints.
        let expected: String

        var testDescription: String { modules.joined(separator: ", ") }
    }

    /// The keyword that starts a matched rule, which ends the helpers that a query takes from a module.
    static let ruleKeyword = "rule "

    /// The keyword of the line that names the models of a module.
    static let createKeyword = "create "

    /// The queries that evaluate every helper of the tutorials on debugging and on performance that
    /// their rules do not call, except `timestamp`, which calls a helper that the tutorial never defines.
    static let helperQueries = [
        HelperQuery(
            metamodel: metamodels[1],
            modules: [
                "atl-06-step-03-common-errors.atl", "atl-06-step-04-defensive-checks.atl",
                "atl-06-step-05-helper-validation.atl", "atl-06-step-06-edge-cases.atl",
                "atl-06-step-07-logging-helpers.atl", "atl-06-step-08-collection-debugging.atl",
            ],
            expression: """
                Source!Element.allInstances()->select(e | not e.parent.oclIsUndefined())->collect(e | e.errorProne())
                    ->union(Source!Element.allInstances()->collect(e |
                        e.safeName() + ', ' + e.getCount().toString() + ', ' + e.debugInfo()))
                    ->union(Source!Container.allInstances()->collect(c |
                        c.firstElementName() + ', ' + c.verifiedChildren->size().toString()))
                """,
            expected: """
                Sequence{'Garden', 'Garden', 'No parent, 2, Processing: Garden (type: Element)', \
                'Garden, 0, Processing: Vegetable Bed (type: Element)', \
                'Garden, 0, Processing: Herb Spiral (type: Element)', 'Garden, 2'}
                """),
        HelperQuery(
            metamodel: metamodels[1], modules: ["atl-06-step-10-robust-transformation.atl"],
            expression: "Source!Container.allInstances()->collect(c | c.validChildren->collect(e | e.safeName()))",
            expected: "Sequence{'Garden', 'Garden'}"),
        HelperQuery(
            metamodel: metamodels[2],
            modules: [
                "atl-08-step-03-inefficient-patterns.atl", "atl-08-step-04-caching-results.atl",
                "atl-08-step-05-optimised-collections.atl", "atl-08-step-07-helper-optimisation.atl",
                "atl-08-step-10-complete-optimised.atl",
            ],
            expression: """
                Source!Container.allInstances()->collect(c | c.name + ': ' + c.inefficientSearch()->size().toString()
                    + ', ' + c.hasElement('Search').toString() + ', ' + c.activeHighPriorityNames->size().toString()
                    + ', ' + c.statistics + ', ' + c.activeElementNames->size().toString())
                """,
            expected: "Sequence{'Backlog: 4, true, 2, Total: 4, Active: 3, 3', 'Archive: 0, false, 0, Total: 0, Active: 0, 0'}"),
    ]

    /// The helpers of a module, with the directives that name its metamodels, as the text of a query unit.
    ///
    /// - Parameter module: The text of the module.
    /// - Returns: The directives before the module header and the lines between the `create` line and
    ///   the first rule.
    static func helperLines(of module: String) -> (directives: [Substring], helpers: [Substring]) {
        let lines = module.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        let header = lines.firstIndex { $0.hasPrefix(createKeyword) } ?? lines.endIndex
        let directives = lines[..<header].filter { $0.hasPrefix("-- @") }
        let body = lines[header...].dropFirst()
        return (directives, Array(body.prefix { !$0.hasPrefix(ruleKeyword) }))
    }

    @Test("CLI: The metamodels of tutorials 02, 06 and 08 validate", arguments: metamodels)
    @MainActor
    func testMetamodelsValidate(_ metamodel: Checks.TargetMetamodel) async throws {
        try await Checks.expectTargetMetamodelValidates(metamodel)
        let result = try await executeSwiftEcore(
            command: "validate", arguments: [Checks.resource(metamodel.sourceFile, of: metamodel.tutorial).path])
        #expect(result.succeeded, "\(metamodel.sourceName) should validate: \(result.stdout)\(result.stderr)")
    }

    @Test("CLI: The sample model of tutorials 02, 06 and 08 conforms to the source metamodel", arguments: metamodels)
    @MainActor
    func testSampleValidates(_ metamodel: Checks.TargetMetamodel) async throws {
        try await Checks.expectSampleValidates(metamodel)
    }

    @Test(
        "Content: The target metamodel of tutorials 02, 06 and 08 declares what the transformations bind",
        arguments: metamodels)
    func testTargetMetamodelDeclaresBindings(_ metamodel: Checks.TargetMetamodel) throws {
        try Checks.expectTargetMetamodelDeclaresBindings(metamodel)
    }

    @Test("Content: The source metamodel of tutorials 06 and 08 declares the features expected", arguments: sourceMetamodels)
    func testSourceMetamodelFeatures(_ source: SourceMetamodel) throws {
        let metamodel = source.metamodel
        let ecore = try Checks.text(of: metamodel.sourceFile, in: metamodel.tutorial)
        let classes = try Checks.classes(in: ecore)
        for feature in source.features {
            let tag = try #require(classes[feature.className]?[feature.name], "\(feature.className).\(feature.name)")
            #expect(tag.contains("#\(feature.type)\""), "\(tag)")
            #expect(tag.contains("upperBound=\"-1\"") == feature.isMany, "\(tag)")
        }
        let declared = classes.flatMap { className, features in features.keys.map { "\(className).\($0)" } }
        #expect(Set(declared) == Set(source.features.map { "\($0.className).\($0.name)" }))
        for (subclass, supertype) in source.supertypes {
            #expect(ecore.contains("name=\"\(subclass)\" eSuperTypes=\"#//\(supertype)\""), "\(subclass)")
        }
    }

    @Test("CLI: Every module of tutorials 02, 06 and 08 checks against its metamodels", arguments: modules)
    @MainActor
    func testModuleValidatesAgainstMetamodels(_ module: Checks.TargetModule) async throws {
        let metamodel = module.metamodel
        let workspace = try Checks.makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }
        try Checks.copy(
            [
                (resource: metamodel.sourceFile, name: metamodel.sourceName),
                (resource: metamodel.targetFile, name: metamodel.targetName),
                (resource: module.file, name: metamodel.transformationName),
            ], of: metamodel.tutorial, to: workspace)
        let result = try await ATLAdvanced02Tests.execute(
            tool: "swift-atl", arguments: ["transform", metamodel.transformationName, "--validate-only"],
            in: workspace)
        #expect(result.succeeded, "\(module.file) should check: \(result.stdout)\(result.stderr)")
    }

    @Test("CLI: Every module of tutorials 02, 06 and 08 runs on the sample model", arguments: modules)
    @MainActor
    func testModuleRuns(_ module: Checks.TargetModule) async throws {
        try await Checks.expectModuleRuns(module)
    }

    @Test("Resources: Tutorials 02, 06 and 08 each have a complete transformation to check")
    func testModulesFound() {
        Checks.expectModulesFound(for: Self.metamodels, in: Self.modules)
    }

    @Test("Tutorial: The target metamodel of tutorials 02, 06 and 08 follows the source metamodel", arguments: metamodels)
    func testTargetMetamodelPosition(_ metamodel: Checks.TargetMetamodel) throws {
        try Checks.expectTargetMetamodelPosition(metamodel)
    }

    @Test("Tutorial: The source metamodel of tutorials 06 and 08 is the first step", arguments: sourceMetamodels)
    func testSourceMetamodelStep(_ source: SourceMetamodel) throws {
        let metamodel = source.metamodel
        let tutorial = try String(
            contentsOf: Checks.tutorialsPath.appendingPathComponent(metamodel.tutorialFile), encoding: .utf8)
        let step = try #require(Checks.blocks("@Step", in: tutorial[...]).first)
        #expect(step.contains("@Code(name: \"\(metamodel.sourceName)\", file: \(metamodel.sourceFile))"))
        Checks.expectStepShape(step)
    }

    @Test("Tutorial: Tutorials 02, 06 and 08 end a section by running the complete transformation", arguments: runs)
    func testRunSteps(_ run: RunSteps) throws {
        try Checks.expectSectionEnds(run.metamodel.tutorialFile, section: run.section, with: run.codes)
    }

    @Test("CLI: Replaying tutorials 02, 06 and 08 prints the documented output and writes the model shown", arguments: runs)
    @MainActor
    func testReplay(_ run: RunSteps) async throws {
        try await Checks.expectReplay(
            run.metamodel.tutorialFile, of: run.metamodel.tutorial, commands: run.commands, reports: 1)
    }

    @Test("CLI: The helpers of tutorials 06 and 08 evaluate on the sample model", arguments: helperQueries)
    @MainActor
    func testHelpersEvaluate(_ query: HelperQuery) async throws {
        let metamodel = query.metamodel
        let workspace = try Checks.makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }
        try Checks.copy(
            [
                (resource: metamodel.sourceFile, name: metamodel.sourceName),
                (resource: metamodel.sampleFile, name: metamodel.sampleName),
            ], of: metamodel.tutorial, to: workspace)
        var directives: [Substring] = []
        var helpers: [Substring] = []
        for module in query.modules {
            let parts = Self.helperLines(of: try Checks.text(of: module, in: metamodel.tutorial))
            directives = parts.directives
            helpers += parts.helpers
        }
        let sourceDirective = try #require(directives.first { $0.contains(" Source=") })
        let unit = ([sourceDirective, "", "query HelperValues = \(query.expression);"] + helpers)
            .joined(separator: "\n")
        let result = try await Checks.query(
            unit, arguments: ["--source", "IN:Source=\(metamodel.sampleName)"], in: workspace)
        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(Checks.lines(of: result.stdout) == [query.expected])
    }
}

// MARK: - Tutorial 07: metamodels, scenarios and runs

extension ATL02to08Tests {
    /// The number of the tutorial on complex transformations.
    static let complexTutorial = 7

    /// The tutorial file of the tutorial on complex transformations.
    static let complexTutorialFile = "ATL-07-complex-transformations.tutorial"

    /// The name under which a tutorial shows a file, with the resource that holds it.
    struct ShownFile: Sendable {
        /// The file name that the reader sees and saves.
        let name: String

        /// The resource of the file.
        let file: String

        /// The file as the text of a code directive of the tutorial.
        var code: String { "\(name): \(file)" }
    }

    /// A metamodel of the tutorial on complex transformations, with the features it declares.
    struct ComplexMetamodel: Sendable, CustomTestStringConvertible {
        /// The name of the metamodel, as the module headers give it.
        let name: String

        /// The metamodel as the tutorial shows it.
        let shown: ShownFile

        /// The features of the metamodel, each with the end of its `eType` reference.
        let features: [Checks.ExpectedFeature]

        var testDescription: String { shown.file }
    }

    /// A model that a module reads or writes, bound to a model name of the module header.
    struct ModelBinding: Sendable {
        /// The name of the model in the module header, such as `IN`.
        let model: String

        /// The name of the metamodel of the model.
        let metamodel: String

        /// The sample model, or the written model, as the tutorial shows it.
        let shown: ShownFile

        /// The binding as the argument of a `--source` or `--target` option.
        var argument: String { "\(model)=\(shown.name)" }
    }

    /// A scenario of the tutorial: a section with its metamodels, modules, sample models, run and results.
    struct Scenario: Sendable, CustomTestStringConvertible {
        /// The title of the section.
        let section: String

        /// The metamodels of the scenario, in the order the section shows them.
        let metamodels: [ComplexMetamodel]

        /// The names of the target metamodels, as the module headers give them.
        let targetMetamodels: [String]

        /// The keyword of the module headers before the source models: `from`, or `refining` for a
        /// module that refines its source model.
        let sourceKeyword: String

        /// The file name under which the tutorial saves the modules of the scenario.
        let transformationName: String

        /// The resources of the modules of the scenario, in step order.
        let modules: [String]

        /// The source models, each with the sample model that the section shows.
        let sources: [ModelBinding]

        /// The target models, each with the written model that the section shows.
        let targets: [ModelBinding]

        /// The resource of the Terminal script that runs the last module.
        let script: String

        /// The number of commands that the script runs.
        let commands: Int

        /// The code directives of the section in order, as `name: file`.
        var codes: [String] {
            metamodels.map(\.shown.code) + modules.map { "\(transformationName): \($0)" }
                + sources.map(\.shown.code) + ["Terminal: \(script)"] + targets.map(\.shown.code)
        }

        /// The steps that end the section, from the sample models to the written models.
        var runCodes: [(name: String, file: String)] {
            (sources.map(\.shown) + [ShownFile(name: "Terminal", file: script)] + targets.map(\.shown))
                .map { ($0.name, $0.file) }
        }

        var testDescription: String { section }
    }

    /// A feature of a metamodel of the tutorial on complex transformations.
    static func feature(_ className: String, _ name: String, _ type: String, many: Bool = false)
        -> Checks.ExpectedFeature
    {
        Checks.ExpectedFeature(className: className, name: name, type: type, isMany: many)
    }

    /// The metamodel of the refining scenario, which is the source and the target metamodel.
    static let refinedMetamodel = ComplexMetamodel(
        name: "Model", shown: ShownFile(name: "Model.ecore", file: "atl-07-step-01-model-metamodel.ecore"),
        features: [
            feature("Container", "elements", "//Element", many: true),
            feature("Container", "summaries", "//Summary", many: true),
            feature("Element", "name", "//EString"), feature("Element", "version", "//EInt"),
            feature("Element", "deprecated", "//EBoolean"), feature("Summary", "elementName", "//EString"),
        ])

    /// The scenarios of the tutorial on complex transformations, one for each section.
    static let scenarios = [
        Scenario(
            section: "Refining Mode Transformations", metamodels: [refinedMetamodel], targetMetamodels: ["Model"],
            sourceKeyword: "refining", transformationName: "RefiningExample.atl",
            modules: [
                "atl-07-step-02-refining-mode.atl", "atl-07-step-03-selective-refactoring.atl",
                "atl-07-step-04-refining-with-lazy.atl", "atl-07-step-05-complete-refactoring.atl",
            ],
            sources: [
                ModelBinding(
                    model: "IN", metamodel: "Model",
                    shown: ShownFile(name: "model.xmi", file: "atl-07-step-06-sample-model.xmi"))
            ],
            targets: [
                ModelBinding(
                    model: "OUT", metamodel: "Model",
                    shown: ShownFile(name: "refined.xmi", file: "atl-07-step-08-refined.xmi"))
            ],
            script: "atl-07-step-07-run-refining.sh", commands: 3),
        Scenario(
            section: "Multiple Source Models",
            metamodels: [
                ComplexMetamodel(
                    name: "ModelA", shown: ShownFile(name: "ModelA.ecore", file: "atl-07-step-09-modela-metamodel.ecore"),
                    features: [feature("ElementA", "name", "//EString"), feature("ElementA", "id", "//EInt")]),
                ComplexMetamodel(
                    name: "ModelB", shown: ShownFile(name: "ModelB.ecore", file: "atl-07-step-10-modelb-metamodel.ecore"),
                    features: [feature("ElementB", "name", "//EString"), feature("ElementB", "refId", "//EInt")]),
                ComplexMetamodel(
                    name: "Target", shown: ShownFile(name: "Target.ecore", file: "atl-07-step-11-target-metamodel.ecore"),
                    features: [
                        feature("Item", "name", "//EString"), feature("Item", "source", "//EString"),
                        feature("Item", "nameFromA", "//EString"),
                        feature("Item", "relatedB", "//EString", many: true),
                        feature("Combined", "nameA", "//EString"), feature("Combined", "nameB", "//EString"),
                        feature("Combined", "combined", "//EString"),
                    ]),
            ],
            targetMetamodels: ["Target"], sourceKeyword: "from", transformationName: "MultiModelExample.atl",
            modules: [
                "atl-07-step-12-multiple-sources.atl", "atl-07-step-13-cross-model-rules.atl",
                "atl-07-step-14-complete-multi-model.atl",
            ],
            sources: [
                ModelBinding(
                    model: "INA", metamodel: "ModelA",
                    shown: ShownFile(name: "modela.xmi", file: "atl-07-step-15-sample-modela.xmi")),
                ModelBinding(
                    model: "INB", metamodel: "ModelB",
                    shown: ShownFile(name: "modelb.xmi", file: "atl-07-step-16-sample-modelb.xmi")),
            ],
            targets: [
                ModelBinding(
                    model: "OUT", metamodel: "Target",
                    shown: ShownFile(name: "target.xmi", file: "atl-07-step-18-target.xmi"))
            ],
            script: "atl-07-step-17-run-multiple-sources.sh", commands: 6),
        Scenario(
            section: "Multiple Target Models",
            metamodels: [
                ComplexMetamodel(
                    name: "Source", shown: ShownFile(name: "Source.ecore", file: "atl-07-step-19-source-metamodel.ecore"),
                    features: [feature("Element", "name", "//EString")]),
                ComplexMetamodel(
                    name: "TargetA",
                    shown: ShownFile(name: "TargetA.ecore", file: "atl-07-step-20-targeta-metamodel.ecore"),
                    features: [feature("ItemA", "name", "//EString")]),
                ComplexMetamodel(
                    name: "TargetB",
                    shown: ShownFile(name: "TargetB.ecore", file: "atl-07-step-21-targetb-metamodel.ecore"),
                    features: [feature("ItemB", "title", "//EString")]),
            ],
            targetMetamodels: ["TargetA", "TargetB"], sourceKeyword: "from",
            transformationName: "MultiModelExample.atl",
            modules: ["atl-07-step-22-multiple-targets.atl"],
            sources: [
                ModelBinding(
                    model: "IN", metamodel: "Source",
                    shown: ShownFile(name: "source.xmi", file: "atl-07-step-23-sample-source.xmi"))
            ],
            targets: [
                ModelBinding(
                    model: "OUTA", metamodel: "TargetA",
                    shown: ShownFile(name: "targeta.xmi", file: "atl-07-step-25-targeta.xmi")),
                ModelBinding(
                    model: "OUTB", metamodel: "TargetB",
                    shown: ShownFile(name: "targetb.xmi", file: "atl-07-step-26-targetb.xmi")),
            ],
            script: "atl-07-step-24-run-multiple-targets.sh", commands: 5),
    ]

    /// Every metamodel of the tutorial on complex transformations.
    static let complexMetamodels = scenarios.flatMap(\.metamodels)

    /// A module of the tutorial on complex transformations, as a test argument.
    struct ComplexModule: Sendable, CustomTestStringConvertible {
        /// The scenario of the module.
        let scenario: Scenario

        /// The resource of the module.
        let file: String

        /// The lines between the root element tags of each model that the module writes, by model name.
        let expectedBodies: [String: [String]]

        var testDescription: String { file }
    }

    /// The element lines of the refined model in which only the deprecated element has changed.
    static let unchangedElements = [
        "<elements name=\"Parser\" version=\"1\"/>",
        "<elements name=\"Formatter\" version=\"2\" deprecated=\"true\"/>",
        "<elements name=\"Scheduler\" version=\"3\"/>",
    ]

    /// The lines between the root element tags of each model that each module writes, by resource and model.
    static let complexTargetBodies: [String: [String: [String]]] = [
        "atl-07-step-02-refining-mode.atl": ["OUT": unchangedElements],
        "atl-07-step-03-selective-refactoring.atl": [
            "OUT": ["<elements name=\"Parser\" version=\"2\"/>"] + unchangedElements.dropFirst()
        ],
        "atl-07-step-04-refining-with-lazy.atl": [
            "OUT": unchangedElements + [
                "<summaries elementName=\"Parser\"/>", "<summaries elementName=\"Formatter\"/>",
                "<summaries elementName=\"Scheduler\"/>",
            ]
        ],
        "atl-07-step-05-complete-refactoring.atl": [
            "OUT": [
                unchangedElements[0], "<elements name=\"Updated_Formatter\" version=\"2\" deprecated=\"false\"/>",
                unchangedElements[2],
            ]
        ],
        "atl-07-step-12-multiple-sources.atl": ["OUT": []],
        "atl-07-step-13-cross-model-rules.atl": [
            "OUT": [
                "<mtg:Item nameFromA=\"Kitchen\">", "<relatedB>Tiles</relatedB>", "<relatedB>Paint</relatedB>",
                "</mtg:Item>", "<mtg:Item nameFromA=\"Garden\">", "<relatedB>Seeds</relatedB>", "</mtg:Item>",
            ]
        ],
        "atl-07-step-14-complete-multi-model.atl": [
            "OUT": [
                "<mtg:Item name=\"Kitchen\" source=\"ModelA\"/>", "<mtg:Item name=\"Garden\" source=\"ModelA\"/>",
                "<mtg:Item name=\"Tiles\" source=\"ModelB\"/>", "<mtg:Item name=\"Seeds\" source=\"ModelB\"/>",
                "<mtg:Item name=\"Paint\" source=\"ModelB\"/>",
            ] + ["Kitchen", "Garden"].flatMap { a in
                ["Tiles", "Seeds", "Paint"].map { b in
                    "<mtg:Combined nameA=\"\(a)\" nameB=\"\(b)\" combined=\"\(a) + \(b)\"/>"
                }
            }
        ],
        "atl-07-step-22-multiple-targets.atl": [
            "OUTA": ["<tga:ItemA name=\"Morning shift\"/>", "<tga:ItemA name=\"Evening shift\"/>"],
            "OUTB": ["<tgb:ItemB title=\"Morning shift\"/>", "<tgb:ItemB title=\"Evening shift\"/>"],
        ],
    ]

    /// Every module of the tutorial on complex transformations, with the models it must write.
    static let complexModules: [ComplexModule] = scenarios.flatMap { scenario in
        scenario.modules.map {
            ComplexModule(scenario: scenario, file: $0, expectedBodies: complexTargetBodies[$0] ?? [:])
        }
    }

    /// Every sample model of the tutorial on complex transformations, with its scenario.
    static let complexSamples: [ModelBinding] = scenarios.flatMap(\.sources)

    /// The lines of an XMI document between the tags of its root element.
    ///
    /// - Parameter xmi: The text of the document.
    /// - Returns: Its trimmed, non-empty lines without the XML declaration and the root element
    ///   tags, or no lines for an empty root element.
    static func bodyLines(of xmi: String) -> [String] {
        Array(Checks.lines(of: xmi).dropFirst(2).dropLast())
    }

    /// Copies the metamodels and sample models of a scenario and a module into a new working directory.
    ///
    /// - Parameters:
    ///   - scenario: The scenario.
    ///   - module: The resource of the module, saved under the name the tutorial gives it.
    /// - Returns: The working directory, which the caller removes.
    /// - Throws: An error if the directory cannot be created or a file cannot be copied.
    static func complexWorkspace(for scenario: Scenario, module: String) throws -> URL {
        let workspace = try Checks.makeWorkspace()
        try Checks.copy(
            scenario.metamodels.map { (resource: $0.shown.file, name: $0.shown.name) }
                + scenario.sources.map { (resource: $0.shown.file, name: $0.shown.name) }
                + [(resource: module, name: scenario.transformationName)],
            of: complexTutorial, to: workspace)
        return workspace
    }

    @Test("CLI: Every metamodel of tutorial 07 validates", arguments: complexMetamodels)
    @MainActor
    func testComplexMetamodelValidates(_ metamodel: ComplexMetamodel) async throws {
        let result = try await executeSwiftEcore(
            command: "validate", arguments: [Checks.resource(metamodel.shown.file, of: Self.complexTutorial).path])
        #expect(result.succeeded, "\(metamodel.shown.name) should validate: \(result.stdout)\(result.stderr)")
    }

    @Test("Content: Every metamodel of tutorial 07 declares exactly the features expected", arguments: complexMetamodels)
    func testComplexMetamodelFeatures(_ metamodel: ComplexMetamodel) throws {
        let ecore = try Checks.text(of: metamodel.shown.file, in: Self.complexTutorial)
        #expect(ecore.contains("name=\"\(metamodel.name)\" nsURI=\""), "\(metamodel.shown.file)")
        let classes = try Checks.classes(in: ecore)
        for feature in metamodel.features {
            let tag = try #require(classes[feature.className]?[feature.name], "\(feature.className).\(feature.name)")
            #expect(tag.contains("#\(feature.type)\""), "\(tag)")
            #expect(tag.contains("upperBound=\"-1\"") == feature.isMany, "\(tag)")
        }
        let declared = classes.flatMap { className, features in features.keys.map { "\(className).\($0)" } }
        #expect(Set(declared) == Set(metamodel.features.map { "\($0.className).\($0.name)" }))
        #expect(Set(classes.keys) == Set(metamodel.features.map(\.className)))
    }

    @Test("Content: The metamodels of tutorial 07 have namespace URIs that no other metamodel uses")
    func testComplexNamespaceURIsDistinct() throws {
        let pattern = try NSRegularExpression(pattern: #"nsURI="([^"]+)""#)
        func uris(in text: String) -> [String] {
            let nsText = text as NSString
            return pattern.matches(in: text, range: NSRange(location: 0, length: nsText.length)).map {
                nsText.substring(with: $0.range(at: 1))
            }
        }
        let own = try Self.complexMetamodels.flatMap { uris(in: try Checks.text(of: $0.shown.file, in: Self.complexTutorial)) }
        #expect(own.count == Self.complexMetamodels.count)
        #expect(Set(own).count == own.count)
        let ownDirectory = Checks.directory(of: Self.complexTutorial)
        let enumerator = try #require(FileManager.default.enumerator(at: Checks.codePath, includingPropertiesForKeys: nil))
        var others: Set<String> = []
        for case let url as URL in enumerator
        where url.pathExtension == "ecore" && url.deletingLastPathComponent().lastPathComponent != ownDirectory {
            others.formUnion(uris(in: try String(contentsOf: url, encoding: .utf8)))
        }
        #expect(!others.isEmpty)
        #expect(others.isDisjoint(with: own), "\(others.intersection(own))")
    }

    @Test("CLI: Every sample model of tutorial 07 conforms to its metamodel", arguments: complexSamples)
    @MainActor
    func testComplexSampleValidates(_ sample: ModelBinding) async throws {
        let metamodel = try #require(Self.complexMetamodels.first { $0.name == sample.metamodel })
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [
                Checks.resource(sample.shown.file, of: Self.complexTutorial).path,
                "--metamodel", Checks.resource(metamodel.shown.file, of: Self.complexTutorial).path,
            ])
        #expect(result.succeeded, "\(sample.shown.name) should validate: \(result.stdout)\(result.stderr)")
    }

    @Test("CLI: Every module of tutorial 07 checks against its metamodels", arguments: complexModules)
    @MainActor
    func testComplexModuleValidates(_ module: ComplexModule) async throws {
        let scenario = module.scenario
        let workspace = try Self.complexWorkspace(for: scenario, module: module.file)
        defer { try? FileManager.default.removeItem(at: workspace) }
        let result = try await ATLAdvanced02Tests.execute(
            tool: "swift-atl", arguments: ["transform", scenario.transformationName, "--validate-only"],
            in: workspace)
        #expect(result.succeeded, "\(module.file) should check: \(result.stdout)\(result.stderr)")
    }

    @Test("CLI: Every module of tutorial 07 runs on the sample models and writes the models expected", arguments: complexModules)
    @MainActor
    func testComplexModuleRuns(_ module: ComplexModule) async throws {
        let scenario = module.scenario
        let workspace = try Self.complexWorkspace(for: scenario, module: module.file)
        defer { try? FileManager.default.removeItem(at: workspace) }
        let bindings = scenario.sources.flatMap { [Checks.sourceOption, $0.argument] }
            + scenario.targets.flatMap { [Checks.targetOption, $0.argument] }
        let result = try await ATLAdvanced02Tests.execute(
            tool: "swift-atl", arguments: ["transform", scenario.transformationName] + bindings, in: workspace)
        #expect(result.succeeded, "\(module.file) should run: \(result.stdout)\(result.stderr)")
        #expect(Set(module.expectedBodies.keys) == Set(scenario.targets.map(\.model)))
        for target in scenario.targets {
            let written = try String(contentsOf: workspace.appendingPathComponent(target.shown.name), encoding: .utf8)
            #expect(Self.bodyLines(of: written) == module.expectedBodies[target.model], "\(module.file): \(target.model)")
        }
    }

    @Test("Content: The target metamodels of tutorial 07 declare what the modules create and bind", arguments: scenarios)
    func testComplexTargetMetamodelsDeclareBindings(_ scenario: Scenario) throws {
        for name in scenario.targetMetamodels {
            let metamodel = try #require(scenario.metamodels.first { $0.name == name })
            let classes = try Checks.classes(in: try Checks.text(of: metamodel.shown.file, in: Self.complexTutorial))
            var instantiated = Set<String>()
            for module in scenario.modules {
                let atl = try Checks.text(of: module, in: Self.complexTutorial)
                for (className, features) in try Checks.boundFeatures(in: atl, of: name) {
                    instantiated.insert(className)
                    let declared = try #require(classes[className], "\(name) should declare \(className)")
                    for feature in features {
                        #expect(declared[feature] != nil, "\(className) should declare \(feature), which \(module) binds")
                    }
                }
            }
            #expect(Set(classes.keys) == instantiated, "Every class of \(name) should be one that a module creates")
        }
    }

    @Test("Content: The models of every module header of tutorial 07 are the models its scenario binds", arguments: complexModules)
    func testComplexModuleHeader(_ module: ComplexModule) throws {
        let scenario = module.scenario
        let header = try #require(
            Checks.lines(of: try Checks.text(of: module.file, in: Self.complexTutorial))
                .first { $0.hasPrefix(Self.createKeyword) })
        let targets = scenario.targets.map { "\($0.model): \($0.metamodel)" }.joined(separator: ", ")
        let sources = scenario.sources.map { "\($0.model): \($0.metamodel)" }.joined(separator: ", ")
        #expect(header == "\(Self.createKeyword)\(targets) \(scenario.sourceKeyword) \(sources);")
    }

    @Test("Resources: Every module of tutorial 07 belongs to a scenario and has the models it writes to check")
    func testComplexModulesFound() {
        #expect(Checks.modules(of: Self.complexTutorial) == Self.complexModules.map(\.file))
        #expect(Self.complexModules.allSatisfy { !$0.expectedBodies.isEmpty })
    }

    @Test("Tutorial: Each section of tutorial 07 shows its metamodels, modules, samples, run and results in order", arguments: scenarios)
    func testComplexSectionCodes(_ scenario: Scenario) throws {
        let tutorial = try String(
            contentsOf: Checks.tutorialsPath.appendingPathComponent(Self.complexTutorialFile), encoding: .utf8)
        let heading = try #require(tutorial.range(of: "@Section(title: \"\(scenario.section)\")"))
        let section = try #require(Checks.block(in: tutorial[...], from: heading.lowerBound))
        #expect(TutorialCatalogue.codes(in: String(section)).map { "\($0.name): \($0.file)" } == scenario.codes)
        let steps = Checks.blocks("@Step", in: section)
        for step in steps {
            Checks.expectStepShape(step)
        }
        for metamodel in scenario.metamodels {
            let step = try #require(steps.first { $0.contains("file: \(metamodel.shown.file))") })
            for feature in metamodel.features {
                #expect(step.contains("`\(feature.name)`"), "The caption should name \(feature.name)")
            }
        }
        try Checks.expectSectionEnds(Self.complexTutorialFile, section: scenario.section, with: scenario.runCodes)
    }

    @Test("Tutorial: The sections of tutorial 07 are the scenarios, in order")
    func testComplexSections() throws {
        let tutorial = try String(
            contentsOf: Checks.tutorialsPath.appendingPathComponent(Self.complexTutorialFile), encoding: .utf8)
        let codes = TutorialCatalogue.codes(in: tutorial).map { "\($0.name): \($0.file)" }
        #expect(codes == Self.scenarios.flatMap(\.codes))
    }

    @Test("Tutorial: The text and the modules of tutorial 07 qualify types only with metamodel names")
    func testComplexTypeQualifiers() throws {
        let tutorial = try String(
            contentsOf: Checks.tutorialsPath.appendingPathComponent(Self.complexTutorialFile), encoding: .utf8)
        let modules = try Self.complexModules.map { try Checks.text(of: $0.file, in: Self.complexTutorial) }
        let pattern = try NSRegularExpression(pattern: #"\b(\w+)!\w+"#)
        let names = Set(Self.complexMetamodels.map(\.name))
        func qualifiers(in document: String) -> [String] {
            let text = document as NSString
            return pattern.matches(in: document, range: NSRange(location: 0, length: text.length)).map {
                text.substring(with: $0.range(at: 1))
            }
        }
        #expect(!qualifiers(in: tutorial).isEmpty)
        for document in [tutorial] + modules {
            for qualifier in qualifiers(in: document) {
                #expect(names.contains(qualifier), "\(qualifier) is not a metamodel of the tutorial")
            }
        }
    }

    @Test("CLI: Replaying tutorial 07 prints the documented output and writes the models shown")
    @MainActor
    func testComplexReplay() async throws {
        try await Checks.expectReplay(
            Self.complexTutorialFile, of: Self.complexTutorial, commands: Self.scenarios.map(\.commands).reduce(0, +),
            reports: Self.scenarios.map(\.targets.count).reduce(0, +))
    }
}
