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
/// advanced rules tutorial runs on the sample project of the reference solution of its exercises
/// and writes the report that the tutorial describes, and that the behaviour the tutorials describe
/// for `collect` and `oclAsType` is the behaviour of the tool.
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

    /// The ATL files of the three tutorials, as paths relative to ``codePath``.
    static let atlFiles: [String] = tutorialDirectories.values.sorted().flatMap { directory in
        ((try? FileManager.default.contentsOfDirectory(
            atPath: codePath.appendingPathComponent(directory).path)) ?? [])
            .filter { $0.hasSuffix(".atl") }
            .sorted()
            .map { "\(directory)/\($0)" }
    }

    /// The location of a resource of a tutorial.
    ///
    /// - Parameters:
    ///   - name: The file name of the resource.
    ///   - tutorial: The number of the tutorial.
    /// - Returns: The location of the resource.
    static func resource(_ name: String, of tutorial: Int) -> URL {
        codePath.appendingPathComponent(tutorialDirectories[tutorial] ?? "").appendingPathComponent(name)
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

    // MARK: - Tutorial 04: reference solution of the exercises

    /// The directory that holds the reference solution of the exercises of the advanced rules
    /// tutorial: the target metamodel, a sample project and the reports that the transformations
    /// write for it.
    static let fixturesPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/ATL-Tutorial-04")

    /// The location of a fixture of the advanced rules tutorial.
    ///
    /// - Parameter name: The file name of the fixture.
    /// - Returns: The location of the fixture.
    static func fixture(_ name: String) -> URL {
        fixturesPath.appendingPathComponent(name)
    }

    /// The text of a fixture of the advanced rules tutorial.
    ///
    /// - Parameter name: The file name of the fixture.
    /// - Returns: The text of the fixture.
    /// - Throws: An error if the fixture cannot be read.
    static func fixtureText(_ name: String) throws -> String {
        try String(contentsOf: fixture(name), encoding: .utf8)
    }

    /// Runs a transformation of the advanced rules tutorial on the sample project.
    ///
    /// The working directory receives the source metamodel of the tutorial, the transformation
    /// under the name that the tutorial gives it, the sample project and a target metamodel.
    ///
    /// - Parameters:
    ///   - resource: The resource of the transformation.
    ///   - name: The file name under which the tutorial saves the transformation.
    ///   - report: The text of the target metamodel, by default that of the reference solution.
    /// - Returns: The result of the command and the report it wrote, if any.
    /// - Throws: An error if a file cannot be prepared or the tool cannot be run.
    @MainActor
    static func runReport(_ resource: String, as name: String, report: String? = nil) async throws
        -> (result: SubprocessResult, report: String?)
    {
        let workspace = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }
        try copy(
            [(resource: "atl-04-step-01-project-metamodel.ecore", name: "Project.ecore"), (resource: resource, name: name)],
            of: 4, to: workspace)
        try FileManager.default.copyItem(at: fixture("project.xmi"), to: workspace.appendingPathComponent("project.xmi"))
        try (report ?? fixtureText("Report.ecore"))
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
        let result = try await executeSwiftEcore(command: "validate", arguments: [Self.fixture("Report.ecore").path])
        #expect(result.succeeded, "Report.ecore should validate: \(result.stdout)\(result.stderr)")
    }

    @Test("CLI: The sample project conforms to the Project metamodel")
    @MainActor
    func testSampleProjectValidates() async throws {
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [
                Self.fixture("project.xmi").path,
                "--metamodel", Self.resource("atl-04-step-01-project-metamodel.ecore", of: 4).path,
            ])
        #expect(result.succeeded, "project.xmi should validate: \(result.stdout)\(result.stderr)")
    }

    @Test("Content: The sample project is the example project that the tutorial describes")
    func testSampleProjectMatchesTutorial() throws {
        let content = try Self.fixtureText("project.xmi")
        #expect(content.contains("priority=\"8\" completed=\"true\""))
        #expect(content.contains("priority=\"6\" completed=\"false\""))
        #expect(content.contains("priority=\"2\" completed=\"false\""))
        #expect(content.components(separatedBy: "<resources ").count - 1 == 2)
    }

    @Test("Content: The reference metamodel declares every class and feature that the transformations bind")
    func testReportMetamodelFeatures() throws {
        let content = try Self.fixtureText("Report.ecore")
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

        /// The fixture that holds the report the transformation writes, if there is one.
        let expectedReport: String?

        /// Lines that the report must contain, in this order.
        let expectedLines: [String]

        var testDescription: String { resource }
    }

    /// The transformations of the advanced rules tutorial in step order.
    static let reportRuns = [
        ReportRun(
            resource: "atl-04-step-02-lazy-rule.atl", name: "ProjectTransform.atl", expectedReport: nil,
            expectedLines: ["<xmi:XMI xmi:version=\"2.0\" xmlns:xmi=\"http://www.omg.org/XMI\"/>"]),
        ReportRun(
            resource: "atl-04-step-03-calling-lazy.atl", name: "ProjectTransform.atl",
            expectedReport: "report-calling-lazy.xmi",
            expectedLines: [
                "<summaries title=\"Pour slab\" status=\"Done\"/>",
                "<summaries title=\"Frame walls\" status=\"Pending\"/>",
            ]),
        ReportRun(
            resource: "atl-04-step-06-multiple-lazy.atl", name: "ProjectTransform.atl", expectedReport: nil,
            expectedLines: [
                "<summaries xsi:type=\"rep:DetailedSummary\" title=\"Pour slab\" status=\"Done\" priorityLevel=\"8\" description=\"Priority 8 task\"/>",
                "<summaries xsi:type=\"rep:DetailedSummary\" title=\"Frame walls\" status=\"Pending\" priorityLevel=\"6\" description=\"Priority 6 task\"/>",
                "<summaries title=\"Paint trim\" status=\"Pending\"/>",
            ]),
        ReportRun(
            resource: "atl-04-step-07-matched-rule.atl", name: "ProjectTransformMatched.atl",
            expectedReport: "report-matched.xmi", expectedLines: []),
        ReportRun(
            resource: "atl-04-step-08-lazy-called-twice.atl", name: "ProjectHighlights.atl",
            expectedReport: "report-highlights.xmi", expectedLines: []),
        ReportRun(
            resource: "atl-04-step-09-unique-lazy.atl", name: "ProjectHighlights.atl",
            expectedReport: "report-unique.xmi",
            expectedLines: ["<highlights href=\"#//@summaries.0\"/>", "<highlights href=\"#//@summaries.1\"/>"]),
        ReportRun(
            resource: "atl-04-step-10-called-rule.atl", name: "ProjectTransform.atl", expectedReport: nil,
            expectedLines: ["<xmi:XMI xmi:version=\"2.0\" xmlns:xmi=\"http://www.omg.org/XMI\"/>"]),
        ReportRun(
            resource: "atl-04-step-11-do-block.atl", name: "ProjectTransform.atl", expectedReport: nil,
            expectedLines: ["name=\"Garden Shed\" completionRate=\"33\"/>"]),
        ReportRun(
            resource: "atl-04-step-12-combined-rules.atl", name: "ProjectTransform.atl", expectedReport: nil,
            expectedLines: [
                "<summaries title=\"Paint trim\" status=\"Pending\"/>",
                "<rep:StatusReport projectName=\"Garden Shed\" totalTasks=\"3\"/>",
            ]),
        ReportRun(
            resource: "atl-04-step-13-complete-transformation.atl", name: "ProjectTransform.atl",
            expectedReport: "report-complete.xmi",
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
            #expect(actual == Self.lines(of: try Self.fixtureText(expectedReport)))
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

    @Test("Content: The reports differ as the comparison section describes")
    func testComparisonReports() throws {
        func count(_ text: String, _ marker: String) -> Int { text.components(separatedBy: marker).count - 1 }
        let lazy = try Self.fixtureText("report-calling-lazy.xmi")
        let matched = try Self.fixtureText("report-matched.xmi")
        let twice = try Self.fixtureText("report-highlights.xmi")
        let unique = try Self.fixtureText("report-unique.xmi")
        let complete = try Self.fixtureText("report-complete.xmi")
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
        let reference = try Self.fixtureText("Report.ecore")
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

    @Test("Tutorial: The advanced rules tutorial leaves the metamodel, model and runs as exercises")
    func testExercises() throws {
        let tutorial = try String(
            contentsOf: Self.tutorialsPath.appendingPathComponent("ATL-04-advanced-rules.tutorial"), encoding: .utf8)
        #expect(!tutorial.contains("resolveLazy"))
        #expect(tutorial.contains("thisModule.TaskSummary(task)"))
        #expect(!tutorial.contains("name: \"Report.ecore\""))
        #expect(!tutorial.contains("name: \"Terminal\""))
        #expect(!tutorial.contains("name: \"Output\""))
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
        let content = try Self.text(of: "atl-05-step-04-type-casting.atl", in: 5)
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
                Self.resource("atl-05-step-05-sample-organisation.xmi", of: 5).path,
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
                (resource: "atl-05-step-05-sample-organisation.xmi", name: "organisation.xmi"),
                (resource: "atl-05-step-06-guarded-query.atl", name: "TeamSizes.atl"),
                (resource: "atl-05-step-08-unchecked-query.atl", name: "UncheckedTeamSizes.atl"),
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
                (resource: "atl-05-step-05-sample-organisation.xmi", name: "organisation.xmi"),
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
        #expect(tutorial.contains("file: atl-05-step-09-run-unchecked.sh"))
    }
}
