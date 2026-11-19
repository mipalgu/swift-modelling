//
// ATL03to05ExecutionTests.swift
// TutorialTests
//
// Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Runs the transformations and queries of the ATL tutorials on collections, advanced rules and
/// OCL expressions through the swift-atl command-line tool.
///
/// The tests check that every ATL file of these tutorials parses, that each transformation of the
/// advanced rules tutorial runs on the sample project of the example solutions of its exercises
/// and writes the report that the tutorial describes, that the section of example solutions shows
/// each metamodel, command, output and report as the tools produce them, and that the behaviour
/// the tutorials describe for `collect` and `oclAsType` is the behaviour of the tool.
@Suite("ATL Tutorials 03-05: Execution")
struct ATL03to05ExecutionTests {

    /// The directory that holds the code resources of the tutorials.
    static let codePath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources/SwiftModelling/SwiftModelling.docc/Resources/Code")

    /// The directory that holds the tutorial files of the ATL series.
    static let tutorialsPath = codePath
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Tutorials/ATL-CLI")

    /// The resource directory of each of the three tutorials, by tutorial number.
    static let tutorialDirectories = [3: "ATL-Tutorial-03", 4: "ATL-Tutorial-04", 5: "ATL-Tutorial-05"]

    /// The pattern of the name of the resource directory of an ATL tutorial, by tutorial number.
    static let tutorialDirectoryFormat = "ATL-Tutorial-%02d"

    /// The extension of an ATL file.
    static let atlExtension = ".atl"

    /// The ATL files of the three tutorials, as paths relative to ``codePath``.
    static let atlFiles: [String] = tutorialDirectories.values.sorted().flatMap { directory in
        atlFiles(in: directory).map { "\(directory)/\($0)" }
    }

    /// The resource directory of an ATL tutorial.
    ///
    /// - Parameter tutorial: The number of the tutorial.
    /// - Returns: The name of its directory within ``codePath``.
    static func directory(of tutorial: Int) -> String {
        tutorialDirectories[tutorial] ?? String(format: tutorialDirectoryFormat, tutorial)
    }

    /// The ATL files of a resource directory, in step order.
    ///
    /// - Parameter directory: The name of the directory within ``codePath``.
    /// - Returns: The file names of its ATL files, sorted.
    static func atlFiles(in directory: String) -> [String] {
        ((try? FileManager.default.contentsOfDirectory(
            atPath: codePath.appendingPathComponent(directory).path)) ?? [])
            .filter { $0.hasSuffix(atlExtension) }
            .sorted()
    }

    /// The location of a resource of a tutorial.
    ///
    /// - Parameters:
    ///   - name: The file name of the resource.
    ///   - tutorial: The number of the tutorial.
    /// - Returns: The location of the resource.
    static func resource(_ name: String, of tutorial: Int) -> URL {
        codePath.appendingPathComponent(directory(of: tutorial)).appendingPathComponent(name)
    }

    /// The text of a resource of a tutorial.
    ///
    /// - Parameters:
    ///   - name: The file name of the resource.
    ///   - tutorial: The number of the tutorial.
    /// - Returns: The text of the resource.
    /// - Throws: An error if the resource cannot be read.
    static func text(of name: String, in tutorial: Int) throws -> String {
        try String(contentsOf: resource(name, of: tutorial), encoding: .utf8)
    }

    /// The lines of a text without surrounding white space, leaving out empty lines.
    ///
    /// - Parameter text: A text, such as an XMI document.
    /// - Returns: Its non-empty lines, trimmed.
    static func lines(of text: String) -> [String] {
        text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Creates an empty working directory, which the caller removes.
    ///
    /// - Returns: The new directory.
    /// - Throws: An error if the directory cannot be created.
    static func makeWorkspace() throws -> URL {
        let workspace = FileManager.default.temporaryDirectory
            .resolvingSymlinksInPath()
            .appendingPathComponent("swift-modelling-tutorial-tests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        return workspace
    }

    /// Copies resources of a tutorial into a working directory under the names the tutorial gives them.
    ///
    /// - Parameters:
    ///   - files: The resource names, each with the name under which the tutorial saves it.
    ///   - tutorial: The number of the tutorial.
    ///   - workspace: The working directory.
    /// - Throws: An error if a file cannot be copied.
    static func copy(_ files: [(resource: String, name: String)], of tutorial: Int, to workspace: URL) throws {
        for file in files {
            let destination = workspace.appendingPathComponent(file.name)
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.copyItem(at: resource(file.resource, of: tutorial), to: destination)
        }
    }

    /// Evaluates a query unit with swift-atl in a working directory.
    ///
    /// - Parameters:
    ///   - query: The text of the query unit.
    ///   - arguments: Further arguments of the query command, such as `--source`.
    ///   - workspace: The working directory, which receives the query as `Query.atl`.
    /// - Returns: The result of the command.
    /// - Throws: An error if the query cannot be written or the tool cannot be run.
    @MainActor
    static func query(_ query: String, arguments: [String] = [], in workspace: URL) async throws
        -> SubprocessResult
    {
        try query.write(to: workspace.appendingPathComponent("Query.atl"), atomically: true, encoding: .utf8)
        return try await ATLAdvanced02Tests.execute(
            tool: "swift-atl", arguments: ["query", "Query.atl"] + arguments, in: workspace)
    }

    // MARK: - Parsing

    @Test("CLI: Every ATL file of tutorials 03 to 05 parses", arguments: atlFiles)
    @MainActor
    func testATLFileParses(_ file: String) async throws {
        let result = try await ATLAdvanced02Tests.execute(
            tool: "swift-atl", arguments: ["parse", Self.codePath.appendingPathComponent(file).path])
        #expect(result.succeeded, "\(file) should parse: \(result.stdout)\(result.stderr)")
    }

    @Test("Resources: The tutorials have ATL files to parse")
    func testATLFilesFound() {
        #expect(Self.atlFiles.count >= 20)
    }

    // MARK: - Tutorial 03: collect

    @Test("CLI: collect keeps one value per element and the kind of collection the tutorial names")
    @MainActor
    func testCollectResultKinds() async throws {
        let workspace = try Self.makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }
        let cases = [
            ("Sequence{4, 4, 2}->collect(c | c * 10)", "Sequence{40, 40, 20}"),
            ("OrderedSet{4, 3, 2}->collect(c | c mod 2)", "Sequence{0, 1, 0}"),
            ("Set{4, 3, 2}->collect(c | c mod 2)->oclType()", "Bag"),
            ("Bag{4, 3, 2}->collect(c | c mod 2)->oclType()", "Bag"),
            ("Sequence{4, 4, 2}->collect(c | c)->sum()", "10"),
            ("Sequence{1, 2}->collect(x | Sequence{x, x})", "Sequence{1, 1, 2, 2}"),
        ]
        for (expression, expected) in cases {
            let result = try await Self.query("query Collect = \(expression);\n", in: workspace)
            #expect(result.succeeded, "\(expression) should evaluate: \(result.stderr)")
            #expect(result.stdout == consoleText("\(expected)\n"), "\(expression)")
        }
    }

    @Test("CLI: collect over the courses of a department gives a Sequence of their credits")
    @MainActor
    func testCollectOverCourses() async throws {
        let workspace = try Self.makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }
        try Self.copy(
            [(resource: "atl-03-step-01-university-metamodel.ecore", name: "University.ecore")], of: 3,
            to: workspace)
        let department = """
            <?xml version="1.0" encoding="UTF-8"?>
            <uni:Department xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" \
            xmlns:uni="http://www.example.org/university" name="Physics">
              <courses code="P101" title="Mechanics" credits="4" level="100"/>
              <courses code="P301" title="Optics" credits="4" level="300"/>
              <courses code="P302" title="Optics Laboratory" credits="2" level="300"/>
            </uni:Department>
            """
        try department.write(to: workspace.appendingPathComponent("department.xmi"), atomically: true, encoding: .utf8)
        let header = "-- @path University=/University/University.ecore\n"
        let credits = "University!Department.allInstances()->first().courses->collect(c | c.credits)"
        for (expression, expected) in [(credits, "Sequence{4, 4, 2}"), (credits + "->sum()", "10")] {
            let result = try await Self.query(
                header + "query Credits = \(expression);\n", arguments: ["--source", "department.xmi"], in: workspace)
            #expect(result.succeeded, "\(expression) should evaluate: \(result.stderr)")
            #expect(result.stdout == consoleText("\(expected)\n"), "\(expression)")
        }
    }

    @Test("Tutorial: The collect question names a collection result and a reduction distractor")
    func testCollectQuestion() throws {
        let tutorial = try String(
            contentsOf: Self.tutorialsPath.appendingPathComponent("ATL-03-collections.tutorial"), encoding: .utf8)
        #expect(tutorial.contains("A new collection holding the value of `c.credits` for each course"))
        #expect(tutorial.contains("A single value that combines the credits of all courses"))
        #expect(!tutorial.contains("It maps each element to a new value"))
        #expect(tutorial.contains("gives a Bag"))
    }

    // MARK: - Tutorial 04: example solutions of the exercises

    /// The versions of the target metamodel in the example solutions of the advanced rules
    /// tutorial, in the order in which the tutorial extends the metamodel.
    static let reportMetamodels = [
        "atl-04-step-15-report-metamodel.ecore",
        "atl-04-step-21-report-detailed-summary.ecore",
        "atl-04-step-28-report-highlights.ecore",
        "atl-04-step-35-report-status.ecore",
        completeReportMetamodel,
    ]

    /// The complete target metamodel of the example solutions, which the complete transformation needs.
    static let completeReportMetamodel = "atl-04-step-36-report-complete.ecore"

    /// The sample project of the example solutions.
    static let sampleProject = "atl-04-step-16-sample-project.xmi"

    /// The source metamodel of the advanced rules tutorial.
    static let projectMetamodel = "atl-04-step-01-project-metamodel.ecore"

    /// The title of the section of the advanced rules tutorial that holds the example solutions.
    static let solutionsTitle = "Example Solutions"

    /// The marker that starts the instruction of an exercise step of the advanced rules tutorial.
    static let exerciseMarker = "Exercise:"

    /// The text of the advanced rules tutorial.
    ///
    /// - Returns: The text of the tutorial file.
    /// - Throws: An error if the tutorial cannot be read.
    static func advancedRulesTutorial() throws -> String {
        try String(
            contentsOf: tutorialsPath.appendingPathComponent("ATL-04-advanced-rules.tutorial"), encoding: .utf8)
    }

    /// The text of a block directive or other bracketed construct, from its start to its closing bracket.
    ///
    /// - Parameters:
    ///   - text: The text that holds the construct.
    ///   - start: The position at which the construct starts, such as the name of a directive.
    ///   - opening: The opening bracket, by default a brace.
    ///   - closing: The closing bracket, by default a brace.
    /// - Returns: The construct with its body, or `nil` if its brackets do not balance.
    static func block(
        in text: Substring, from start: Substring.Index, opening: Character = "{", closing: Character = "}"
    ) -> Substring? {
        guard let open = text[start...].firstIndex(of: opening) else { return nil }
        var depth = 0
        var index = open
        while index < text.endIndex {
            switch text[index] {
            case opening: depth += 1
            case closing:
                depth -= 1
                if depth == 0 { return text[start...index] }
            default: break
            }
            index = text.index(after: index)
        }
        return nil
    }

    /// The blocks of a directive within a text, in document order.
    ///
    /// - Parameters:
    ///   - directive: The directive, such as `@Step`.
    ///   - text: The text to search.
    /// - Returns: Each block of the directive with its body.
    static func blocks(_ directive: String, in text: Substring) -> [Substring] {
        var found: [Substring] = []
        var rest = text
        while let range = rest.range(of: directive + " {"), let body = block(in: text, from: range.lowerBound) {
            found.append(body)
            rest = text[body.endIndex...]
        }
        return found
    }

    /// The main flow of the advanced rules tutorial, its section of example solutions and the rest.
    ///
    /// - Returns: The text before the section of example solutions, the section itself, and the
    ///   text after it.
    /// - Throws: An error if the tutorial cannot be read or has no section of example solutions.
    static func advancedRulesParts() throws -> (mainFlow: Substring, solutions: Substring, remainder: Substring) {
        let tutorial = try advancedRulesTutorial()[...]
        let heading = try #require(tutorial.range(of: "@Section(title: \"\(solutionsTitle)\")"))
        let section = try #require(block(in: tutorial, from: heading.lowerBound))
        return (tutorial[..<heading.lowerBound], section, tutorial[section.endIndex...])
    }

    /// Runs a transformation of the advanced rules tutorial on the sample project.
    ///
    /// The working directory receives the source metamodel of the tutorial, the transformation
    /// under the name that the tutorial gives it, the sample project and a target metamodel.
    ///
    /// - Parameters:
    ///   - resource: The resource of the transformation.
    ///   - name: The file name under which the tutorial saves the transformation.
    ///   - report: The text of the target metamodel, by default that of the complete example solution.
    /// - Returns: The result of the command and the report it wrote, if any.
    /// - Throws: An error if a file cannot be prepared or the tool cannot be run.
    @MainActor
    static func runReport(_ resource: String, as name: String, report: String? = nil) async throws
        -> (result: SubprocessResult, report: String?)
    {
        let workspace = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }
        try copy(
            [
                (resource: projectMetamodel, name: "Project.ecore"), (resource: resource, name: name),
                (resource: sampleProject, name: "project.xmi"),
            ],
            of: 4, to: workspace)
        try (report ?? text(of: completeReportMetamodel, in: 4))
            .write(to: workspace.appendingPathComponent("Report.ecore"), atomically: true, encoding: .utf8)
        let result = try await ATLAdvanced02Tests.execute(
            tool: "swift-atl",
            arguments: ["transform", name, "--source", "IN=project.xmi", "--target", "OUT=report.xmi"],
            in: workspace)
        let output = try? String(contentsOf: workspace.appendingPathComponent("report.xmi"), encoding: .utf8)
        return (result, output)
    }

    @Test("CLI: The reference Report metamodel validates")
    @MainActor
    func testReportMetamodelValidates() async throws {
        let result = try await executeSwiftEcore(command: "validate", arguments: [Self.resource(Self.completeReportMetamodel, of: 4).path])
        #expect(result.succeeded, "Report.ecore should validate: \(result.stdout)\(result.stderr)")
    }

    @Test("CLI: The sample project conforms to the Project metamodel")
    @MainActor
    func testSampleProjectValidates() async throws {
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [
                Self.resource(Self.sampleProject, of: 4).path,
                "--metamodel", Self.resource(Self.projectMetamodel, of: 4).path,
            ])
        #expect(result.succeeded, "project.xmi should validate: \(result.stdout)\(result.stderr)")
    }

    @Test("Content: The sample project is the example project that the tutorial describes")
    func testSampleProjectMatchesTutorial() throws {
        let content = try Self.text(of: Self.sampleProject, in: 4)
        #expect(content.contains("priority=\"8\" completed=\"true\""))
        #expect(content.contains("priority=\"6\" completed=\"false\""))
        #expect(content.contains("priority=\"2\" completed=\"false\""))
        #expect(content.components(separatedBy: "<resources ").count - 1 == 2)
    }

    @Test("Content: The reference metamodel declares every class and feature that the transformations bind")
    func testReportMetamodelFeatures() throws {
        let content = try Self.text(of: Self.completeReportMetamodel, in: 4)
        let names = [
            "Document", "Summary", "DetailedSummary", "ResourceItem", "StatusReport", "name", "completionRate",
            "statusMessage", "summaries", "highlights", "resources", "title", "status", "priorityLevel",
            "description", "category", "projectName", "totalTasks", "completion", "resourceCount",
        ]
        for name in names {
            #expect(content.contains("name=\"\(name)\""), "Report.ecore should declare \(name)")
        }
        #expect(content.contains("name=\"DetailedSummary\" eSuperTypes=\"#//Summary\""))
        #expect(content.contains("name=\"highlights\" upperBound=\"-1\" eType=\"#//Summary\"/>"))
    }

    // MARK: - Tutorial 04: transformations

    /// A transformation of the advanced rules tutorial, with the file it is saved as and the report it writes.
    struct ReportRun: Sendable, CustomTestStringConvertible {
        /// The resource of the transformation.
        let resource: String

        /// The file name under which the tutorial saves the transformation.
        let name: String

        /// The resource that holds the report the transformation writes, if there is one.
        let expectedReport: String?

        /// The position in ``reportMetamodels`` of the version of the target metamodel with which
        /// the example solutions reach this transformation.
        let metamodelVersion: Int

        /// Lines that the report must contain, in this order.
        let expectedLines: [String]

        var testDescription: String { resource }
    }

    /// The transformations of the advanced rules tutorial in step order.
    static let reportRuns = [
        ReportRun(
            resource: "atl-04-step-02-lazy-rule.atl", name: "ProjectTransform.atl", expectedReport: nil,
            metamodelVersion: 0, expectedLines: ["<xmi:XMI xmi:version=\"2.0\" xmlns:xmi=\"http://www.omg.org/XMI\"/>"]),
        ReportRun(
            resource: "atl-04-step-03-calling-lazy.atl", name: "ProjectTransform.atl",
            expectedReport: "atl-04-step-20-report-calling-lazy.xmi", metamodelVersion: 0,
            expectedLines: [
                "<summaries title=\"Pour slab\" status=\"Done\"/>",
                "<summaries title=\"Frame walls\" status=\"Pending\"/>",
            ]),
        ReportRun(
            resource: "atl-04-step-06-multiple-lazy.atl", name: "ProjectTransform.atl",
            expectedReport: "atl-04-step-24-report-multiple-lazy.xmi", metamodelVersion: 1,
            expectedLines: [
                "<summaries xsi:type=\"rep:DetailedSummary\" title=\"Pour slab\" status=\"Done\" priorityLevel=\"8\" description=\"Priority 8 task\"/>",
                "<summaries xsi:type=\"rep:DetailedSummary\" title=\"Frame walls\" status=\"Pending\" priorityLevel=\"6\" description=\"Priority 6 task\"/>",
                "<summaries title=\"Paint trim\" status=\"Pending\"/>",
            ]),
        ReportRun(
            resource: "atl-04-step-07-matched-rule.atl", name: "ProjectTransformMatched.atl",
            expectedReport: "atl-04-step-27-report-matched.xmi", metamodelVersion: 1, expectedLines: []),
        ReportRun(
            resource: "atl-04-step-08-lazy-called-twice.atl", name: "ProjectHighlights.atl",
            expectedReport: "atl-04-step-31-report-highlights.xmi", metamodelVersion: 2, expectedLines: []),
        ReportRun(
            resource: "atl-04-step-09-unique-lazy.atl", name: "ProjectHighlights.atl",
            expectedReport: "atl-04-step-34-report-unique.xmi", metamodelVersion: 2,
            expectedLines: ["<highlights href=\"#//@summaries.0\"/>", "<highlights href=\"#//@summaries.1\"/>"]),
        ReportRun(
            resource: "atl-04-step-10-called-rule.atl", name: "ProjectTransform.atl", expectedReport: nil,
            metamodelVersion: 3, expectedLines: ["<xmi:XMI xmi:version=\"2.0\" xmlns:xmi=\"http://www.omg.org/XMI\"/>"]),
        ReportRun(
            resource: "atl-04-step-11-do-block.atl", name: "ProjectTransform.atl", expectedReport: nil,
            metamodelVersion: 3, expectedLines: ["name=\"Garden Shed\" completionRate=\"33\"/>"]),
        ReportRun(
            resource: "atl-04-step-12-combined-rules.atl", name: "ProjectTransform.atl", expectedReport: nil,
            metamodelVersion: 3, expectedLines: [
                "<summaries title=\"Paint trim\" status=\"Pending\"/>",
                "<rep:StatusReport projectName=\"Garden Shed\" totalTasks=\"3\"/>",
            ]),
        ReportRun(
            resource: "atl-04-step-13-complete-transformation.atl", name: "ProjectTransform.atl",
            expectedReport: "atl-04-step-39-report-complete.xmi", metamodelVersion: 4,
            expectedLines: [
                "<rep:Document name=\"Garden Shed\" completionRate=\"33\" statusMessage=\"Project in progress: 33% complete\">",
                "<summaries title=\"Pour slab\" status=\"Done\" priorityLevel=\"8\"/>",
                "<summaries title=\"Frame walls\" status=\"Pending\" priorityLevel=\"6\"/>",
                "<resources name=\"Concrete mixer\" category=\"Equipment\"/>",
                "<resources name=\"Carpenter\" category=\"Person\"/>",
                "<rep:StatusReport projectName=\"Garden Shed\" totalTasks=\"3\" completion=\"33\" resourceCount=\"2\"/>",
            ]),
    ]

    @Test("CLI: Each transformation of the advanced rules tutorial writes the report it describes", arguments: reportRuns)
    @MainActor
    func testReportRun(_ run: ReportRun) async throws {
        let (result, report) = try await Self.runReport(run.resource, as: run.name)
        #expect(result.succeeded, "\(run.resource) should run: \(result.stdout)\(result.stderr)")
        let actual = Self.lines(of: try #require(report, "\(run.resource) should write a report"))
        if let expectedReport = run.expectedReport {
            #expect(actual == Self.lines(of: try Self.text(of: expectedReport, in: 4)))
        }
        var remaining = actual[...]
        for line in run.expectedLines {
            guard let index = remaining.firstIndex(where: { $0.contains(line) }) else {
                Issue.record("The report of \(run.resource) lacks \(line):\n\(actual.joined(separator: "\n"))")
                break
            }
            remaining = remaining[remaining.index(after: index)...]
        }
    }

    // MARK: - Tutorial 04: section of example solutions

    /// The code that the steps of the example solutions show, in step order, each with the name
    /// under which the tutorial shows it and its resource.
    static let solutionCodes: [(name: String, file: String)] = [
        ("Report.ecore", "atl-04-step-15-report-metamodel.ecore"),
        ("project.xmi", sampleProject),
        ("Terminal", "atl-04-step-17-validate.sh"),
        ("ProjectTransform.atl", "atl-04-step-03-calling-lazy.atl"),
        ("Terminal", "atl-04-step-19-run-calling-lazy.sh"),
        ("report.xmi", "atl-04-step-20-report-calling-lazy.xmi"),
        ("Report.ecore", "atl-04-step-21-report-detailed-summary.ecore"),
        ("ProjectTransform.atl", "atl-04-step-06-multiple-lazy.atl"),
        ("Terminal", "atl-04-step-23-run-multiple-lazy.sh"),
        ("report.xmi", "atl-04-step-24-report-multiple-lazy.xmi"),
        ("ProjectTransformMatched.atl", "atl-04-step-07-matched-rule.atl"),
        ("Terminal", "atl-04-step-26-run-matched.sh"),
        ("report-matched.xmi", "atl-04-step-27-report-matched.xmi"),
        ("Report.ecore", "atl-04-step-28-report-highlights.ecore"),
        ("ProjectHighlights.atl", "atl-04-step-08-lazy-called-twice.atl"),
        ("Terminal", "atl-04-step-30-run-highlights.sh"),
        ("report-highlights.xmi", "atl-04-step-31-report-highlights.xmi"),
        ("ProjectHighlights.atl", "atl-04-step-09-unique-lazy.atl"),
        ("Terminal", "atl-04-step-33-run-unique.sh"),
        ("report-unique.xmi", "atl-04-step-34-report-unique.xmi"),
        ("Report.ecore", "atl-04-step-35-report-status.ecore"),
        ("Report.ecore", completeReportMetamodel),
        ("ProjectTransform.atl", "atl-04-step-13-complete-transformation.atl"),
        ("Terminal", "atl-04-step-38-run-complete.sh"),
        ("report.xmi", "atl-04-step-39-report-complete.xmi"),
    ]

    /// The option of `swift-atl transform` that binds a target model to the file it writes.
    static let targetOption = "--target"

    /// The option of `swift-atl transform` that binds a source model to the file it reads.
    static let sourceOption = "--source"

    /// The separator between the name of a model and its file in a model binding, as in `OUT=report.xmi`.
    static let modelBindingSeparator: Character = "="

    @Test("Tutorial: The example solutions are the last section, directly before the assessments")
    func testSolutionsSectionPosition() throws {
        let (mainFlow, _, remainder) = try Self.advancedRulesParts()
        #expect(mainFlow.contains("@Section(title: \"Called Rules and Imperative Sections\")"))
        #expect(mainFlow.components(separatedBy: "@Section(").count - 1 == 3)
        #expect(remainder.drop(while: \.isWhitespace).hasPrefix("@Assessments"))
        #expect(!remainder.contains("@Section("))
    }

    @Test("Tutorial: The example solutions show the files, commands and reports of the exercises in order")
    func testSolutionsCodes() throws {
        let solutions = try Self.advancedRulesParts().solutions
        let codes = TutorialCatalogue.codes(in: String(solutions)).map { "\($0.name): \($0.file)" }
        #expect(codes == Self.solutionCodes.map { "\($0.name): \($0.file)" })
        for metamodel in Self.reportMetamodels {
            #expect(Self.solutionCodes.contains { $0.name == "Report.ecore" && $0.file == metamodel }, "\(metamodel)")
        }
        for run in Self.reportRuns {
            guard let report = run.expectedReport else { continue }
            #expect(Self.solutionCodes.contains { $0.file == report }, "The solutions should show \(report)")
        }
    }

    @Test("Tutorial: Every step of the example solutions has an instruction, one code and at most one caption")
    func testSolutionsStepShape() throws {
        let solutions = try Self.advancedRulesParts().solutions
        let steps = Self.blocks("@Step", in: solutions)
        #expect(steps.count == Self.solutionCodes.count)
        for step in steps {
            Self.expectStepShape(step)
        }
    }

    /// The paragraphs of the body of a step, each joined into one line.
    ///
    /// - Parameter step: The `@Step` directive with its body.
    /// - Returns: The paragraphs of its body in order, each with its lines trimmed and joined by spaces.
    static func paragraphs(of step: Substring) -> [String] {
        let body = step.drop { $0 != "{" }.dropFirst().dropLast()
        var paragraphs: [String] = []
        var current = ""
        for line in body.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                if !current.isEmpty { paragraphs.append(current) }
                current = ""
            } else {
                current += trimmed + " "
            }
        }
        if !current.isEmpty { paragraphs.append(current) }
        return paragraphs
    }

    /// Expects a step to start with an instruction and to hold one code and at most one caption.
    ///
    /// - Parameter step: The `@Step` directive with its body.
    static func expectStepShape(_ step: Substring) {
        let paragraphs = paragraphs(of: step)
        let isCode: (String) -> Bool = { $0.hasPrefix("@Code(") }
        #expect(paragraphs.filter(isCode).count == 1, "\(step)")
        #expect((1...2).contains(paragraphs.filter { !isCode($0) }.count), "\(step)")
        #expect(paragraphs.first.map(isCode) == false, "\(step)")
    }

    @Test("Tutorial: The introduction and every exercise point to the example solutions")
    func testExercisesPointToSolutions() throws {
        let mainFlow = try Self.advancedRulesParts().mainFlow
        let intro = try #require(Self.blocks("@Intro(title: \"Advanced Rule Patterns\")", in: mainFlow).first)
        #expect(intro.contains("\"\(Self.solutionsTitle)\""))
        let exercises = Self.blocks("@Step", in: mainFlow).filter { $0.contains(Self.exerciseMarker) }
        #expect(exercises.count == 3)
        for exercise in exercises {
            #expect(exercise.contains("\"\(Self.solutionsTitle)\""), "\(exercise)")
        }
    }

    @Test("CLI: Every version of the Report metamodel in the example solutions validates", arguments: reportMetamodels)
    @MainActor
    func testReportMetamodelVersionValidates(_ metamodel: String) async throws {
        let result = try await executeSwiftEcore(command: "validate", arguments: [Self.resource(metamodel, of: 4).path])
        #expect(result.succeeded, "\(metamodel) should validate: \(result.stdout)\(result.stderr)")
    }

    @Test(
        "CLI: Each version of the Report metamodel suffices for the transformations up to its point",
        arguments: Array(reportMetamodels.indices))
    @MainActor
    func testReportMetamodelVersionSuffices(_ version: Int) async throws {
        let metamodel = try Self.text(of: Self.reportMetamodels[version], in: 4)
        let runs = Self.reportRuns.filter { $0.metamodelVersion <= version }
        #expect(!runs.isEmpty)
        for run in runs {
            let (result, report) = try await Self.runReport(run.resource, as: run.name, report: metamodel)
            #expect(result.succeeded, "\(run.resource) should run: \(result.stdout)\(result.stderr)")
            if let expectedReport = run.expectedReport {
                #expect(
                    Self.lines(of: report ?? "") == Self.lines(of: try Self.text(of: expectedReport, in: 4)),
                    "\(run.resource) with \(Self.reportMetamodels[version])")
            }
        }
    }

    @Test(
        "CLI: Each extension of the Report metamodel is needed by a transformation at its point",
        arguments: Array(reportMetamodels.indices.dropFirst()))
    @MainActor
    func testReportMetamodelExtensionNeeded(_ version: Int) async throws {
        let previous = try Self.text(of: Self.reportMetamodels[version - 1], in: 4)
        var failures = 0
        for run in Self.reportRuns where run.metamodelVersion == version {
            let (result, _) = try await Self.runReport(run.resource, as: run.name, report: previous)
            if !result.succeeded { failures += 1 }
        }
        #expect(failures > 0, "A transformation should need \(Self.reportMetamodels[version])")
    }

    @Test("CLI: Replaying the example solutions prints the documented output and writes the reports shown")
    @MainActor
    func testSolutionsReplay() async throws {
        let solutions = try Self.advancedRulesParts().solutions
        let workspace = try Self.makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }
        try Self.copy([(resource: Self.projectMetamodel, name: "Project.ecore")], of: 4, to: workspace)
        let (commandCount, reportCount) = try await Self.replay(
            TutorialCatalogue.codes(in: String(solutions)), of: 4, in: workspace)
        #expect(commandCount >= Self.solutionCodes.filter { $0.name == "Terminal" }.count)
        #expect(reportCount == Self.reportRuns.compactMap(\.expectedReport).count)
    }

    /// Replays code directives of a tutorial in a working directory.
    ///
    /// Each file is saved under its name, each command of a Terminal step must succeed and print
    /// the output that the script documents, and each file shown after a Terminal step that wrote
    /// it must have the content that the command wrote.
    ///
    /// - Parameters:
    ///   - codes: The code directives in step order.
    ///   - tutorial: The number of the tutorial.
    ///   - workspace: The working directory.
    /// - Returns: The number of commands run and the number of written files compared.
    /// - Throws: An error if a file cannot be read or copied or a tool cannot be run.
    @MainActor
    static func replay(_ codes: [TutorialCode], of tutorial: Int, in workspace: URL) async throws
        -> (commands: Int, reports: Int)
    {
        var written = Set<String>()
        var commandCount = 0
        var reportCount = 0
        for code in codes {
            let source = Self.resource(code.file, of: tutorial)
            switch code.kind {
            case .terminal:
                let script = try String(contentsOf: source, encoding: .utf8)
                var output = ""
                written = []
                for command in Self.lines(of: script)
                where command.first != TutorialReplayConfiguration.commentCharacter {
                    let words = command.split(separator: " ").map(String.init)
                    let tool = try #require(words.first)
                    #expect(TutorialReplayConfiguration.toolNames.contains(tool), "\(code.file): \(command)")
                    let result = try await ATLAdvanced02Tests.execute(
                        tool: tool, arguments: Array(words.dropFirst()), in: workspace)
                    #expect(result.succeeded, "\(code.file): \(command): \(result.stdout)\(result.stderr)")
                    output += result.stdout
                    commandCount += 1
                    for (option, value) in zip(words, words.dropFirst()) where option == Self.targetOption {
                        written.insert(String(value.split(separator: Self.modelBindingSeparator).last ?? ""))
                    }
                }
                let documented = DocumentedOutput.expectedLines(inScript: script).map {
                    DocumentedOutput.normalised($0.text)
                }
                #expect(Self.lines(of: output).map { DocumentedOutput.normalised($0) } == documented, "\(code.file)")
            case .file where written.contains(code.name):
                let report = try String(contentsOf: workspace.appendingPathComponent(code.name), encoding: .utf8)
                let shown = try String(contentsOf: source, encoding: .utf8)
                #expect(Self.lines(of: report) == Self.lines(of: shown), "\(code.file)")
                reportCount += 1
            case .file:
                let destination = workspace.appendingPathComponent(code.name)
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.copyItem(at: source, to: destination)
            case .display:
                Issue.record("The replayed steps should show no output block: \(code.file)")
            }
        }
        return (commandCount, reportCount)
    }

    @Test("Content: The reports differ as the comparison section describes")
    func testComparisonReports() throws {
        func count(_ text: String, _ marker: String) -> Int { text.components(separatedBy: marker).count - 1 }
        let lazy = try Self.text(of: "atl-04-step-20-report-calling-lazy.xmi", in: 4)
        let matched = try Self.text(of: "atl-04-step-27-report-matched.xmi", in: 4)
        let twice = try Self.text(of: "atl-04-step-31-report-highlights.xmi", in: 4)
        let unique = try Self.text(of: "atl-04-step-34-report-unique.xmi", in: 4)
        let complete = try Self.text(of: "atl-04-step-39-report-complete.xmi", in: 4)
        #expect(count(lazy, "title=") == 2)
        #expect(!lazy.contains("Paint trim"))
        #expect(count(matched, "title=") == 3)
        #expect(count(matched, "<summaries ") == 2)
        #expect(matched.contains("<rep:Summary title=\"Paint trim\""))
        #expect(count(twice, "title=") == 5)
        #expect(count(twice, "<summaries ") == 3)
        #expect(count(twice, "<rep:Summary ") == 2)
        #expect(count(unique, "title=") == 3)
        #expect(!unique.contains("<rep:Summary "))
        #expect(count(complete, "<rep:") == 2)
    }

    @Test("Content: The unique version differs from the twice-called version only in its rule modifier")
    func testUniqueLazyRuleModifier() throws {
        let twice = try Self.text(of: "atl-04-step-08-lazy-called-twice.atl", in: 4)
        let unique = try Self.text(of: "atl-04-step-09-unique-lazy.atl", in: 4)
        #expect(twice.contains("\nlazy rule TaskSummary {"))
        #expect(unique.contains("\nunique lazy rule TaskSummary {"))
        let code: (String) -> [String] = { text in
            Self.lines(of: text).filter { !$0.hasPrefix("--") }.map {
                $0.replacingOccurrences(of: "unique lazy rule", with: "lazy rule")
            }
        }
        #expect(code(twice) == code(unique))
    }

    /// A target metamodel with a mistake, and what the tutorial says a run of the complete
    /// transformation then shows.
    struct MetamodelMistake: Sendable, CustomTestStringConvertible {
        /// What is wrong with the metamodel.
        let description: String

        /// The text of the reference metamodel to replace, as a regular expression.
        let pattern: String

        /// The text that replaces it.
        let replacement: String

        /// The message that the run prints, or `nil` if the run succeeds.
        let message: String?

        /// A line that the report contains, if the run succeeds.
        let reportLine: String?

        var testDescription: String { description }
    }

    /// The mistakes that the closing exercise check of the advanced rules tutorial describes.
    static let metamodelMistakes = [
        MetamodelMistake(
            description: "missing statusMessage",
            pattern: #"\s*<eStructuralFeatures[^>]*name="statusMessage"[^>]*/>"#, replacement: "",
            message: "Transformation failed: Invalid operation: Property 'statusMessage' not found in class 'Document'",
            reportLine: nil),
        MetamodelMistake(
            description: "missing ResourceItem",
            pattern: #"\s*<eClassifiers xsi:type="ecore:EClass" name="ResourceItem">.*?</eClassifiers>"#,
            replacement: "",
            message: "Transformation failed: Type error: Class 'ResourceItem' not found in model 'OUT'",
            reportLine: nil),
        MetamodelMistake(
            description: "summaries not a containment reference",
            pattern: ##"name="summaries" upperBound="-1" eType="#//Summary" containment="true""##,
            replacement: ##"name="summaries" upperBound="-1" eType="#//Summary""##,
            message: nil, reportLine: "<summaries href=\"#/1\"/>"),
    ]

    @Test("CLI: The complete transformation reports the metamodel mistakes as the tutorial says", arguments: metamodelMistakes)
    @MainActor
    func testMetamodelMistake(_ mistake: MetamodelMistake) async throws {
        let reference = try Self.text(of: Self.completeReportMetamodel, in: 4)
        let pattern = try NSRegularExpression(pattern: mistake.pattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(reference.startIndex..., in: reference)
        #expect(pattern.numberOfMatches(in: reference, range: range) == 1, "\(mistake.description)")
        let faulty = pattern.stringByReplacingMatches(
            in: reference, range: range, withTemplate: NSRegularExpression.escapedTemplate(for: mistake.replacement))
        let (result, report) = try await Self.runReport(
            "atl-04-step-13-complete-transformation.atl", as: "ProjectTransform.atl", report: faulty)
        if let message = mistake.message {
            #expect(!result.succeeded)
            #expect(result.stdout.contains(message) || result.stderr.contains(message), "\(result.stdout)\(result.stderr)")
            let check = try String(
                contentsOf: Self.tutorialsPath.appendingPathComponent("ATL-04-advanced-rules.tutorial"), encoding: .utf8)
            #expect(check.contains("`\(message)`"))
        }
        if let line = mistake.reportLine {
            #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
            #expect(report?.contains(line) == true, "\(report ?? "")")
        }
    }

    @Test("Tutorial: The main flow of the advanced rules tutorial leaves the metamodel, model and runs as exercises")
    func testExercises() throws {
        let tutorial = try Self.advancedRulesTutorial()
        let (mainFlow, solutions, _) = try Self.advancedRulesParts()
        #expect(!tutorial.contains("resolveLazy"))
        #expect(tutorial.contains("thisModule.TaskSummary(task)"))
        #expect(!mainFlow.contains("name: \"Report.ecore\""))
        #expect(!mainFlow.contains("name: \"Terminal\""))
        #expect(!tutorial.contains("name: \"Output\""))
        #expect(solutions.contains("name: \"Report.ecore\""))
        #expect(solutions.contains("name: \"Terminal\""))
        for link in [
            "<doc:01-first-metamodel>", "<doc:02-model-instances>", "<doc:03-metamodel-relationships>",
            "<doc:04-advanced-features>", "<doc:01-first-transformation>",
        ] {
            #expect(tutorial.contains(link), "The tutorial should link to \(link)")
        }
        #expect(tutorial.contains("swift-atl transform ProjectTransform.atl --source IN=project.xmi --target OUT=report.xmi"))
        for file in Self.atlFiles where file.hasPrefix("ATL-Tutorial-04/") {
            let content = try String(contentsOf: Self.codePath.appendingPathComponent(file), encoding: .utf8)
            #expect(!content.contains("resolveLazy"), "\(file)")
        }
    }

    // MARK: - Tutorial 05: oclAsType

    @Test("Content: The type casting step checks with oclIsKindOf before it casts")
    func testGuardedCast() throws {
        let content = try Self.text(of: "atl-05-step-05-type-casting.atl", in: 5)
        let check = try #require(content.range(of: "self.oclIsKindOf(Organisation!Manager)"))
        let cast = try #require(content.range(of: "self.oclAsType(Organisation!Manager).teamSize"))
        #expect(check.lowerBound < cast.lowerBound)
    }

    @Test("CLI: The sample department conforms to the Organisation metamodel")
    @MainActor
    func testSampleOrganisationValidates() async throws {
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [
                Self.resource("atl-05-step-06-sample-organisation.xmi", of: 5).path,
                "--metamodel", Self.resource("atl-05-step-01-organisation-metamodel.ecore", of: 5).path,
            ])
        #expect(result.succeeded, "organisation.xmi should validate: \(result.stdout)\(result.stderr)")
    }

    @Test("CLI: A checked cast reports every team size, and an unchecked cast of a developer fails")
    @MainActor
    func testCastQueries() async throws {
        let workspace = try Self.makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }
        try Self.copy(
            [
                (resource: "atl-05-step-01-organisation-metamodel.ecore", name: "Organisation.ecore"),
                (resource: "atl-05-step-06-sample-organisation.xmi", name: "organisation.xmi"),
                (resource: "atl-05-step-07-guarded-query.atl", name: "TeamSizes.atl"),
                (resource: "atl-05-step-09-unchecked-query.atl", name: "UncheckedTeamSizes.atl"),
            ], of: 5, to: workspace)

        let guarded = try await ATLAdvanced02Tests.execute(
            tool: "swift-atl", arguments: ["query", "TeamSizes.atl", "--source", "organisation.xmi"], in: workspace)
        #expect(guarded.succeeded, "The checked query should run: \(guarded.stderr)")
        #expect(guarded.stdout == consoleText("Sequence{'Aiko Tanaka: 4', 'Ben Okafor: 0', 'Carla Mendes: 2'}\n"))

        let unchecked = try await ATLAdvanced02Tests.execute(
            tool: "swift-atl", arguments: ["query", "UncheckedTeamSizes.atl", "--source", "organisation.xmi"],
            in: workspace)
        #expect(!unchecked.succeeded, "The unchecked query should fail")
        #expect(unchecked.stdout.isEmpty)
        #expect(unchecked.stderr.contains("Cannot cast a value of type 'Developer' to 'Organisation!Manager'"))
    }

    @Test("CLI: A cast of an undefined value is undefined, and a cast to a supertype returns the object")
    @MainActor
    func testCastOfUndefinedAndSupertype() async throws {
        let workspace = try Self.makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }
        try Self.copy(
            [
                (resource: "atl-05-step-01-organisation-metamodel.ecore", name: "Organisation.ecore"),
                (resource: "atl-05-step-06-sample-organisation.xmi", name: "organisation.xmi"),
            ], of: 5, to: workspace)
        let header = "-- @path Organisation=/Organisation/Organisation.ecore\n"
        let cases = [
            ("OclUndefined.oclAsType(Organisation!Manager).oclIsUndefined()", "true"),
            ("Organisation!Manager.allInstances()->collect(m | m.oclAsType(Organisation!Employee).name)",
             "Sequence{'Aiko Tanaka', 'Carla Mendes'}"),
        ]
        for (expression, expected) in cases {
            let result = try await Self.query(
                header + "query Cast = \(expression);\n", arguments: ["--source", "organisation.xmi"],
                in: workspace)
            #expect(result.succeeded, "\(expression) should evaluate: \(result.stderr)")
            #expect(result.stdout == consoleText("\(expected)\n"), "\(expression)")
        }
    }

    @Test("Tutorial: The oclAsType question names the type error as the correct answer")
    func testCastQuestion() throws {
        let tutorial = try String(
            contentsOf: Self.tutorialsPath.appendingPathComponent("ATL-05-ocl-expressions.tutorial"), encoding: .utf8)
        let question = try #require(tutorial.range(of: "Can you use `oclAsType` without checking the type first?"))
        let tail = tutorial[question.upperBound...]
        let correct = try #require(tail.range(of: "@Choice(isCorrect: true)"))
        let answer = tail[correct.upperBound...].prefix(200)
        #expect(answer.contains("the cast stops the transformation with a type error"))
        #expect(tutorial.contains("file: atl-05-step-10-run-unchecked.sh"))
    }

    // MARK: - Tutorials 03 and 05: target metamodels

    /// A feature that a target metamodel must declare, with its type and multiplicity.
    struct ExpectedFeature: Sendable {
        /// The class that declares the feature.
        let className: String

        /// The name of the feature.
        let name: String

        /// The type of the feature, as the end of its `eType` reference, such as `//EString`.
        let type: String

        /// Whether the feature is many-valued.
        let isMany: Bool
    }

    /// The source and target metamodels of a tutorial that gives its target metamodel, with the
    /// sample model on which its transformations run.
    struct TargetMetamodel: Sendable, CustomTestStringConvertible {
        /// The number of the tutorial.
        let tutorial: Int

        /// The tutorial file within ``ATL03to05ExecutionTests/tutorialsPath``.
        let tutorialFile: String

        /// The file name under which the tutorial saves the source metamodel.
        let sourceName: String

        /// The resource of the source metamodel.
        let sourceFile: String

        /// The file name under which the tutorial saves the target metamodel.
        let targetName: String

        /// The resource of the target metamodel.
        let targetFile: String

        /// The file name under which the tutorial saves its transformations.
        let transformationName: String

        /// The resource of a sample model of the source metamodel.
        let sampleFile: String

        /// The file name under which the tutorial saves the sample model.
        let sampleName: String

        /// The features of the target metamodel, with their types and multiplicities.
        let features: [ExpectedFeature]

        var testDescription: String { targetFile }
    }

    /// The tutorials on collections and on OCL expressions, which give their target metamodels.
    static let targetMetamodels = [
        TargetMetamodel(
            tutorial: 3, tutorialFile: "ATL-03-collections.tutorial", sourceName: "University.ecore",
            sourceFile: "atl-03-step-01-university-metamodel.ecore", targetName: "Catalog.ecore",
            targetFile: "atl-03-step-02-catalog-metamodel.ecore", transformationName: "UniversityTransform.atl",
            sampleFile: universitySample, sampleName: "university.xmi",
            features: [
                ExpectedFeature(className: "Program", name: "name", type: "//EString", isMany: false),
                ExpectedFeature(className: "Program", name: "type", type: "//EString", isMany: false),
                ExpectedFeature(className: "Program", name: "totalCredits", type: "//EInt", isMany: false),
            ]),
        TargetMetamodel(
            tutorial: 5, tutorialFile: "ATL-05-ocl-expressions.tutorial", sourceName: "Organisation.ecore",
            sourceFile: "atl-05-step-01-organisation-metamodel.ecore", targetName: "Report.ecore",
            targetFile: "atl-05-step-02-report-metamodel.ecore", transformationName: "OrganisationTransform.atl",
            sampleFile: "atl-05-step-06-sample-organisation.xmi", sampleName: "organisation.xmi",
            features: [
                ExpectedFeature(className: "DepartmentReport", name: "name", type: "//EString", isMany: false),
                ExpectedFeature(className: "DepartmentReport", name: "statistics", type: "//EString", isMany: false),
                ExpectedFeature(className: "DepartmentReport", name: "employees", type: "//EString", isMany: true),
            ]),
    ]

    /// The sample university of the tutorial on collections.
    static let universitySample = "atl-03-step-10-sample-university.xmi"

    /// The steps that end the tutorial on collections by running the complete transformation, in
    /// order, each with the name under which the tutorial shows it and its resource.
    static let collectionsRunCodes: [(name: String, file: String)] = [
        ("UniversityTransform.atl", "atl-03-step-09-complete-transformation.atl"),
        ("university.xmi", universitySample),
        ("Terminal", "atl-03-step-11-run-complete.sh"),
        ("catalog.xmi", "atl-03-step-12-catalog.xmi"),
    ]

    /// A module of a tutorial that gives its target metamodel, as a test argument.
    struct TargetModule: Sendable, CustomTestStringConvertible {
        /// The tutorial and its metamodels.
        let metamodel: TargetMetamodel

        /// The resource of the module.
        let file: String

        /// Lines that the target model must contain, in this order.
        let expectedLines: [String]

        var testDescription: String { file }
    }

    /// The ATL modules of a tutorial, as resource names, leaving out query units.
    ///
    /// - Parameter tutorial: The number of the tutorial.
    /// - Returns: The resources of its ATL files that declare a module, in step order.
    static func modules(of tutorial: Int) -> [String] {
        atlFiles(in: directory(of: tutorial)).filter { file in
            (try? text(of: file, in: tutorial)).map { lines(of: $0).contains { $0.hasPrefix("module ") } } ?? false
        }
    }

    /// The lines that the target model of a complete transformation must contain, by resource.
    static let completeTargetLines: [String: [String]] = [
        "atl-03-step-09-complete-transformation.atl": [
            "<cat:Program name=\"Physics\" type=\"Graduate\" totalCredits=\"14\"/>",
            "<cat:Program name=\"History\" type=\"Undergraduate\" totalCredits=\"6\"/>",
        ],
        "atl-05-step-14-complete-transformation.atl": [
            "name=\"Engineering\" statistics=\"Total: 3, Managers: 2, Developers: 1\">",
            "<employees>Aiko Tanaka (ID: 1) - Manager of 4 people</employees>",
            "<employees>Ben Okafor (ID: 2) - Develops in Swift</employees>",
            "<employees>Carla Mendes (ID: 3) - Manager of 2 people</employees>",
        ],
    ]

    /// Every module of the tutorials that give their target metamodels.
    static let targetModules: [TargetModule] = targetMetamodels.flatMap { metamodel in
        modules(of: metamodel.tutorial).map {
            TargetModule(metamodel: metamodel, file: $0, expectedLines: completeTargetLines[$0] ?? [])
        }
    }

    /// The classes of an Ecore metamodel, each with the opening tags of its structural features by name.
    ///
    /// - Parameter ecore: The text of the metamodel.
    /// - Returns: The features of each class.
    /// - Throws: An error if a pattern is invalid.
    static func classes(in ecore: String) throws -> [String: [String: String]] {
        let classPattern = try NSRegularExpression(
            pattern: #"<eClassifiers xsi:type="ecore:EClass" name="(\w+)"[^>]*?(/>|>(.*?)</eClassifiers>)"#,
            options: [.dotMatchesLineSeparators])
        let featurePattern = try NSRegularExpression(pattern: #"<eStructuralFeatures [^>]*?name="(\w+)"[^>]*>"#)
        var classes: [String: [String: String]] = [:]
        let text = ecore as NSString
        for match in classPattern.matches(in: ecore, range: NSRange(location: 0, length: text.length)) {
            let name = text.substring(with: match.range(at: 1))
            var features: [String: String] = [:]
            if match.range(at: 3).location != NSNotFound {
                let body = text.substring(with: match.range(at: 3))
                let bodyText = body as NSString
                for feature in featurePattern.matches(in: body, range: NSRange(location: 0, length: bodyText.length)) {
                    features[bodyText.substring(with: feature.range(at: 1))] = bodyText.substring(with: feature.range)
                }
            }
            classes[name] = features
        }
        return classes
    }

    /// The classes of a target metamodel that an ATL module instantiates, each with the features it binds.
    ///
    /// - Parameter atl: The text of the module.
    /// - Returns: The bound features of each instantiated class of the model that the module creates.
    /// - Throws: An error if a pattern is invalid.
    static func boundFeatures(in atl: String) throws -> [String: Set<String>] {
        let text = atl[...]
        guard let create = text.range(of: #"create\s+\w+\s*:\s*(\w+)"#, options: .regularExpression) else { return [:] }
        let target = String(text[create].split(whereSeparator: { $0 == ":" || $0.isWhitespace }).last ?? "")
        return try boundFeatures(in: atl, of: target)
    }

    /// The classes of a metamodel that an ATL module instantiates, each with the features it binds.
    ///
    /// - Parameters:
    ///   - atl: The text of the module.
    ///   - target: The name of the metamodel, as the module header gives it, such as `Target`.
    /// - Returns: The bound features of each class of the metamodel that a pattern of the module creates.
    /// - Throws: An error if a pattern is invalid.
    static func boundFeatures(in atl: String, of target: String) throws -> [String: Set<String>] {
        let text = atl[...]
        let binding = try NSRegularExpression(pattern: #"(\w+)\s*<-"#)
        var bound: [String: Set<String>] = [:]
        var rest = text
        while let element = rest.range(of: target + #"!(\w+)\s*\("#, options: .regularExpression) {
            let className = String(
                text[element].dropFirst(target.count + 1).prefix { $0 == "_" || $0.isLetter || $0.isNumber })
            guard let body = block(in: text, from: element.lowerBound, opening: "(", closing: ")") else { break }
            let inner = String(text[element.upperBound..<body.endIndex])
            let innerText = inner as NSString
            let names = binding.matches(in: inner, range: NSRange(location: 0, length: innerText.length)).map {
                innerText.substring(with: $0.range(at: 1))
            }
            bound[className, default: []].formUnion(names)
            rest = text[body.endIndex...]
        }
        return bound
    }

    /// Expects the target metamodel of a tutorial to validate with swift-ecore.
    ///
    /// - Parameter metamodel: The tutorial and its metamodels.
    /// - Throws: An error if the tool cannot be run.
    @MainActor
    static func expectTargetMetamodelValidates(_ metamodel: TargetMetamodel) async throws {
        let result = try await executeSwiftEcore(
            command: "validate", arguments: [Self.resource(metamodel.targetFile, of: metamodel.tutorial).path])
        #expect(result.succeeded, "\(metamodel.targetName) should validate: \(result.stdout)\(result.stderr)")
    }

    /// Expects the sample model of a tutorial to conform to its source metamodel.
    ///
    /// - Parameter metamodel: The tutorial and its metamodels.
    /// - Throws: An error if the tool cannot be run.
    @MainActor
    static func expectSampleValidates(_ metamodel: TargetMetamodel) async throws {
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [
                Self.resource(metamodel.sampleFile, of: metamodel.tutorial).path,
                "--metamodel", Self.resource(metamodel.sourceFile, of: metamodel.tutorial).path,
            ])
        #expect(result.succeeded, "\(metamodel.sampleName) should validate: \(result.stdout)\(result.stderr)")
    }

    /// Expects the target metamodel of a tutorial to declare exactly the classes and features that
    /// the modules of the tutorial create and bind, with the types and multiplicities expected.
    ///
    /// - Parameter metamodel: The tutorial and its metamodels.
    /// - Throws: An error if a resource cannot be read or a class is missing.
    static func expectTargetMetamodelDeclaresBindings(_ metamodel: TargetMetamodel) throws {
        let classes = try Self.classes(in: try Self.text(of: metamodel.targetFile, in: metamodel.tutorial))
        var instantiated = Set<String>()
        let modules = Self.modules(of: metamodel.tutorial)
        #expect(!modules.isEmpty)
        for module in modules {
            for (className, features) in try Self.boundFeatures(in: try Self.text(of: module, in: metamodel.tutorial)) {
                instantiated.insert(className)
                let declared = try #require(classes[className], "\(metamodel.targetName) should declare \(className)")
                for feature in features {
                    #expect(declared[feature] != nil, "\(className) should declare \(feature), which \(module) binds")
                }
            }
        }
        #expect(!instantiated.isEmpty)
        #expect(Set(classes.keys) == instantiated, "Every class should be one that a transformation creates")
        for feature in metamodel.features {
            let tag = try #require(classes[feature.className]?[feature.name], "\(feature.className).\(feature.name)")
            #expect(tag.contains("eType=\"ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#\(feature.type)\""), "\(tag)")
            #expect(tag.contains("upperBound=\"-1\"") == feature.isMany, "\(tag)")
        }
        let declaredFeatures = classes.flatMap { className, features in features.keys.map { "\(className).\($0)" } }
        #expect(Set(declaredFeatures) == Set(metamodel.features.map { "\($0.className).\($0.name)" }))
    }

    /// Expects a module of a tutorial to run on the sample model and to write the lines expected.
    ///
    /// - Parameter module: The module, with its tutorial and the lines its target model must contain.
    /// - Throws: An error if a file cannot be copied or read or the tool cannot be run.
    @MainActor
    static func expectModuleRuns(_ module: TargetModule) async throws {
        let metamodel = module.metamodel
        let workspace = try Self.makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }
        try Self.copy(
            [
                (resource: metamodel.sourceFile, name: metamodel.sourceName),
                (resource: metamodel.targetFile, name: metamodel.targetName),
                (resource: module.file, name: metamodel.transformationName),
                (resource: metamodel.sampleFile, name: metamodel.sampleName),
            ], of: metamodel.tutorial, to: workspace)
        let result = try await ATLAdvanced02Tests.execute(
            tool: "swift-atl",
            arguments: [
                "transform", metamodel.transformationName, "--source", "IN=\(metamodel.sampleName)",
                "--target", "OUT=target.xmi",
            ], in: workspace)
        #expect(result.succeeded, "\(module.file) should run: \(result.stdout)\(result.stderr)")
        let target = try String(contentsOf: workspace.appendingPathComponent("target.xmi"), encoding: .utf8)
        var remaining = Self.lines(of: target)[...]
        for line in module.expectedLines {
            guard let index = remaining.firstIndex(where: { $0.contains(line) }) else {
                Issue.record("The target model of \(module.file) lacks \(line):\n\(target)")
                break
            }
            remaining = remaining[remaining.index(after: index)...]
        }
    }

    /// Expects the modules of each tutorial to include enough steps and a complete transformation
    /// whose target model is checked.
    ///
    /// - Parameters:
    ///   - metamodels: The tutorials and their metamodels.
    ///   - modules: The modules of these tutorials.
    static func expectModulesFound(for metamodels: [TargetMetamodel], in modules: [TargetModule]) {
        for metamodel in metamodels {
            let modules = modules.filter { $0.metamodel.tutorial == metamodel.tutorial }
            #expect(modules.count >= 7, "\(metamodel.tutorialFile)")
            #expect(modules.contains { !$0.expectedLines.isEmpty }, "\(metamodel.tutorialFile)")
        }
    }

    /// Expects the target metamodel of a tutorial to be shown once, in the second step, directly after
    /// the source metamodel in the first, with a caption that names each of its features.
    ///
    /// - Parameter metamodel: The tutorial and its metamodels.
    /// - Throws: An error if the tutorial cannot be read or a step is missing.
    static func expectTargetMetamodelPosition(_ metamodel: TargetMetamodel) throws {
        let tutorial = try String(
            contentsOf: Self.tutorialsPath.appendingPathComponent(metamodel.tutorialFile), encoding: .utf8)
        let codes = TutorialCatalogue.codes(in: tutorial).map { "\($0.name): \($0.file)" }
        let source = try #require(codes.firstIndex(of: "\(metamodel.sourceName): \(metamodel.sourceFile)"))
        #expect(source == 0)
        #expect(codes.dropFirst(source + 1).first == "\(metamodel.targetName): \(metamodel.targetFile)")
        #expect(codes.filter { $0.hasPrefix("\(metamodel.targetName): ") }.count == 1)
        let steps = Self.blocks("@Step", in: tutorial[...])
        let step = try #require(steps.first { $0.contains("file: \(metamodel.targetFile)") })
        Self.expectStepShape(step)
        #expect(steps.firstIndex(of: step) == 1)
        for feature in metamodel.features {
            #expect(step.contains("`\(feature.name)`"), "The caption should name \(feature.name)")
        }
    }

    /// Expects a section of a tutorial to end with the given code steps, each of the expected shape.
    ///
    /// - Parameters:
    ///   - tutorialFile: The tutorial file within ``tutorialsPath``.
    ///   - sectionTitle: The title of the section.
    ///   - runCodes: The names and resources of the last code steps of the section, in order.
    /// - Throws: An error if the tutorial cannot be read or the section is missing.
    static func expectSectionEnds(
        _ tutorialFile: String, section sectionTitle: String, with runCodes: [(name: String, file: String)]
    ) throws {
        let tutorial = try String(contentsOf: Self.tutorialsPath.appendingPathComponent(tutorialFile), encoding: .utf8)
        let heading = try #require(tutorial.range(of: "@Section(title: \"\(sectionTitle)\")"))
        let section = try #require(Self.block(in: tutorial[...], from: heading.lowerBound))
        let codes = TutorialCatalogue.codes(in: String(section)).map { "\($0.name): \($0.file)" }
        let expected = runCodes.map { "\($0.name): \($0.file)" }
        #expect(Array(codes.suffix(expected.count)) == expected)
        for step in Self.blocks("@Step", in: section).suffix(expected.count) {
            Self.expectStepShape(step)
        }
    }

    /// Replays every code step of a tutorial and expects the commands and written models it documents.
    ///
    /// - Parameters:
    ///   - tutorialFile: The tutorial file within ``tutorialsPath``.
    ///   - tutorial: The number of the tutorial.
    ///   - commands: The least number of commands that the replay must run.
    ///   - reports: The number of written files that the tutorial shows.
    /// - Throws: An error if a file cannot be read or copied or a tool cannot be run.
    @MainActor
    static func expectReplay(_ tutorialFile: String, of tutorial: Int, commands: Int, reports: Int) async throws {
        let text = try String(contentsOf: Self.tutorialsPath.appendingPathComponent(tutorialFile), encoding: .utf8)
        let workspace = try Self.makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }
        let (commandCount, reportCount) = try await Self.replay(
            TutorialCatalogue.codes(in: text), of: tutorial, in: workspace)
        #expect(commandCount >= commands)
        #expect(reportCount == reports)
    }

    @Test("CLI: The target metamodel of the tutorial validates", arguments: targetMetamodels)
    @MainActor
    func testTargetMetamodelValidates(_ metamodel: TargetMetamodel) async throws {
        try await Self.expectTargetMetamodelValidates(metamodel)
    }

    @Test("CLI: The sample model conforms to the source metamodel of the tutorial", arguments: targetMetamodels)
    @MainActor
    func testTargetSampleValidates(_ metamodel: TargetMetamodel) async throws {
        try await Self.expectSampleValidates(metamodel)
    }

    @Test(
        "Content: The target metamodel declares every class and feature that the transformations bind",
        arguments: targetMetamodels)
    func testTargetMetamodelDeclaresBindings(_ metamodel: TargetMetamodel) throws {
        try Self.expectTargetMetamodelDeclaresBindings(metamodel)
    }

    @Test("CLI: Every transformation of the tutorial runs on the sample model with the target metamodel", arguments: targetModules)
    @MainActor
    func testTargetModuleRuns(_ module: TargetModule) async throws {
        try await Self.expectModuleRuns(module)
    }

    @Test("Resources: Each tutorial that gives its target metamodel has a complete transformation to check")
    func testTargetModulesFound() {
        Self.expectModulesFound(for: Self.targetMetamodels, in: Self.targetModules)
    }

    @Test("Tutorial: The target metamodel is shown directly after the source metamodel", arguments: targetMetamodels)
    func testTargetMetamodelPosition(_ metamodel: TargetMetamodel) throws {
        try Self.expectTargetMetamodelPosition(metamodel)
    }

    @Test("Tutorial: The tutorial on collections ends its last section by running the complete transformation")
    func testCollectionsRunSteps() throws {
        try Self.expectSectionEnds(
            "ATL-03-collections.tutorial", section: "Advanced Collection Operations", with: Self.collectionsRunCodes)
    }

    @Test("CLI: Replaying the tutorial on collections prints the documented output and writes the catalogue shown")
    @MainActor
    func testCollectionsReplay() async throws {
        try await Self.expectReplay("ATL-03-collections.tutorial", of: 3, commands: 3, reports: 1)
    }
}
