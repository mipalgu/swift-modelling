import Foundation
import Subprocess
import Testing

#if canImport(System)
    import System
#else
    import SystemPackage
#endif

/// Test suite for ATL Advanced Tutorial 02: Container Navigation and Reflection
/// Validates the resources, parses both transformations and runs the final one through the swift-atl CLI
@Suite("Advanced Tutorial: Container Navigation and Reflection")
struct ATLAdvanced02Tests {

    static let sourceRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")
        .appendingPathComponent("SwiftModelling")
        .appendingPathComponent("SwiftModelling.docc")

    static let tutorialCodePath = sourceRoot
        .appendingPathComponent("Resources")
        .appendingPathComponent("Code")
        .appendingPathComponent("ATL-Advanced-02")

    static let tutorialPath = sourceRoot
        .appendingPathComponent("Tutorials")
        .appendingPathComponent("ATL-Advanced")
        .appendingPathComponent("ATL-Advanced-02-container-navigation.tutorial")

    /// The files that the tutorial presents, which must all exist and all be mentioned by the tutorial text.
    static let resourceNames = [
        "organisation.ecore",
        "directory.ecore",
        "organisation2directory.atl",
        "organisation2directory-threaded.atl",
        "sample-company.xmi",
        "expected-output.xmi",
        "atl-advanced-02-run.sh",
        "organisation2dot.atl",
        "atl-advanced-02-query.sh",
        "expected-organisation.dot",
    ]

    static func resource(_ name: String) -> URL {
        tutorialCodePath.appendingPathComponent(name)
    }

    static func text(of name: String) throws -> String {
        try String(contentsOf: resource(name), encoding: .utf8)
    }

    /// Runs a tool that sits beside swift-ecore in the build products.
    @MainActor
    static func execute(tool: String, arguments: [String], in directory: URL? = nil) async throws
        -> SubprocessResult
    {
        #if os(Windows)
        let executableName = "\(tool).exe"
        #else
        let executableName = tool
        #endif
        let toolDirectory = URL(fileURLWithPath: try swiftEcoreExecutablePath()).deletingLastPathComponent()
        let executable = toolDirectory.appendingPathComponent(executableName).path
        guard FileManager.default.fileExists(atPath: executable) else {
            throw TestError.executableNotFound(executable)
        }
        let result = try await Subprocess.run(
            .path(FilePath(executable)),
            arguments: Arguments(arguments),
            workingDirectory: directory.map { FilePath($0.path) },
            output: .string(limit: 1_048_576),
            error: .string(limit: 1_048_576)
        )
        return SubprocessResult(
            terminationStatus: result.terminationStatus,
            stdout: result.standardOutput ?? "",
            stderr: result.standardError ?? ""
        )
    }

    /// The `entries` elements of a directory document as attribute dictionaries, in document order.
    static func entries(in xml: String) -> [[String: String]] {
        var found: [[String: String]] = []
        for line in xml.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("<entries ") else { continue }
            var attributes: [String: String] = [:]
            var rest = Substring(trimmed.dropFirst("<entries ".count))
            while let equals = rest.firstIndex(of: "=") {
                let name = rest[..<equals].trimmingCharacters(in: .whitespaces)
                let afterQuote = rest.index(equals, offsetBy: 2)
                guard let closing = rest[afterQuote...].firstIndex(of: "\"") else { break }
                attributes[name] = String(rest[afterQuote..<closing])
                rest = rest[rest.index(after: closing)...]
            }
            found.append(attributes)
        }
        return found
    }

    // MARK: - Resources

    @Test("Resources: Every tutorial resource exists")
    func testResourcesExist() {
        for name in Self.resourceNames {
            #expect(FileManager.default.fileExists(atPath: Self.resource(name).path), "\(name) should exist")
        }
    }

    @Test("Tutorial: The tutorial text references each resource")
    func testTutorialReferencesResources() throws {
        let tutorial = try String(contentsOf: Self.tutorialPath, encoding: .utf8)
        for name in Self.resourceNames {
            #expect(tutorial.contains("file: \(name)"), "The tutorial should reference \(name)")
        }
    }

    @Test("Tutorial: The tutorial is registered after the first advanced tutorial")
    func testTutorialRegistered() throws {
        let tableOfContents = try String(
            contentsOf: Self.sourceRoot.appendingPathComponent("Tutorials/Tutorials.tutorial"), encoding: .utf8)
        let first = try #require(tableOfContents.range(of: "doc:ATL-Advanced-01-class2relational"))
        let second = try #require(tableOfContents.range(of: "doc:ATL-Advanced-02-container-navigation"))
        #expect(first.lowerBound < second.lowerBound)
    }

    // MARK: - CLI Validation of Models

    @Test("CLI: Validate Organisation metamodel via swift-ecore")
    @MainActor
    func testCLIValidateOrganisationMetamodel() async throws {
        let result = try await executeSwiftEcore(
            command: "validate", arguments: [Self.resource("organisation.ecore").path])
        #expect(result.succeeded, "Organisation metamodel should validate successfully: \(result.stderr)")
    }

    @Test("CLI: Validate Directory metamodel via swift-ecore")
    @MainActor
    func testCLIValidateDirectoryMetamodel() async throws {
        let result = try await executeSwiftEcore(
            command: "validate", arguments: [Self.resource("directory.ecore").path])
        #expect(result.succeeded, "Directory metamodel should validate successfully: \(result.stderr)")
    }

    @Test("CLI: Validate sample company via swift-ecore")
    @MainActor
    func testCLIValidateSampleInput() async throws {
        let result = try await executeSwiftEcore(
            command: "validate", arguments: [Self.resource("sample-company.xmi").path])
        #expect(result.succeeded, "Sample company should validate successfully: \(result.stderr)")
    }

    @Test("CLI: Validate expected output via swift-ecore")
    @MainActor
    func testCLIValidateExpectedOutput() async throws {
        let result = try await executeSwiftEcore(
            command: "validate", arguments: [Self.resource("expected-output.xmi").path])
        #expect(result.succeeded, "Expected output should validate successfully: \(result.stderr)")
    }

    // MARK: - Metamodel Content

    @Test("Content: Organisation metamodel has containment only, with no opposite references")
    func testOrganisationHasNoOpposites() throws {
        let content = try Self.text(of: "organisation.ecore")
        #expect(content.contains("nsURI=\"http://www.example.org/organisation\""))
        for name in ["Company", "Department", "Team", "Employee"] {
            #expect(content.contains("name=\"\(name)\""))
        }
        for name in ["departments", "teams", "members", "role"] {
            #expect(content.contains("name=\"\(name)\""))
        }
        #expect(!content.contains("eOpposite"), "The source metamodel must have no path upwards")
        #expect(content.components(separatedBy: "containment=\"true\"").count - 1 == 3)
    }

    @Test("Content: Directory metamodel has the entry features")
    func testDirectoryFeatures() throws {
        let content = try Self.text(of: "directory.ecore")
        #expect(content.contains("nsURI=\"http://www.example.org/directory\""))
        for name in ["Directory", "Entry", "entries", "team", "department", "company", "headcount", "description"] {
            #expect(content.contains("name=\"\(name)\""))
        }
    }

    // MARK: - Transformation Parsing

    @Test("CLI: Parse the reflective transformation via swift-atl")
    @MainActor
    func testCLIParseTransformation() async throws {
        let result = try await Self.execute(
            tool: "swift-atl", arguments: ["parse", Self.resource("organisation2directory.atl").path])
        #expect(result.succeeded, "The transformation should parse: \(result.stdout)\(result.stderr)")
    }

    @Test("CLI: Parse the threaded transformation via swift-atl")
    @MainActor
    func testCLIParseThreadedTransformation() async throws {
        let result = try await Self.execute(
            tool: "swift-atl", arguments: ["parse", Self.resource("organisation2directory-threaded.atl").path])
        #expect(result.succeeded, "The threaded transformation should parse: \(result.stdout)\(result.stderr)")
    }

    @Test("CLI: Validate both transformations via swift-atl")
    @MainActor
    func testCLIValidateTransformations() async throws {
        let result = try await Self.execute(
            tool: "swift-atl",
            arguments: [
                "validate", Self.resource("organisation2directory.atl").path,
                Self.resource("organisation2directory-threaded.atl").path,
            ])
        #expect(result.succeeded, "Both transformations should validate: \(result.stdout)\(result.stderr)")
    }

    // MARK: - Transformation Content

    @Test("ATL: The reflective transformation navigates and reflects")
    func testReflectiveTransformationContent() throws {
        let content = try Self.text(of: "organisation2directory.atl")
        #expect(content.contains("module Organisation2Directory"))
        #expect(content.contains("create OUT: Directory from IN: Organisation"))
        #expect(content.contains("helper context Organisation!Employee def : team : Organisation!Team ="))
        #expect(content.contains("self.refImmediateComposite()"))
        #expect(content.contains("self.team.refImmediateComposite()"))
        #expect(content.contains("name <- e.refGetValue('name')"))
        #expect(content.contains("e.refInvokeOperation('describe', Sequence{})"))
        #expect(content.contains("entry.refSetValue('headcount',"))
    }

    @Test("ATL: The threaded transformation uses no reflection")
    func testThreadedTransformationContent() throws {
        let content = try Self.text(of: "organisation2directory-threaded.atl")
        #expect(content.contains("module Organisation2DirectoryThreaded"))
        #expect(content.contains("thisModule.Entry(e, t, dep, c)"))
        #expect(!content.contains("refImmediateComposite"))
        #expect(!content.contains("refGetValue"))
        #expect(!content.contains("refSetValue"))
        #expect(!content.contains("refInvokeOperation"))
    }

    // MARK: - Expected Output Content

    @Test("Content: Expected output has one entry per employee")
    func testExpectedOutputEntries() throws {
        let content = try Self.text(of: "expected-output.xmi")
        #expect(content.contains("name=\"Harbour Logistics\""))
        let entries = Self.entries(in: content)
        #expect(entries.count == 5)
        let payroll = try #require(entries.first { $0["name"] == "Kofi Mensah" })
        #expect(payroll["team"] == "Payroll")
        #expect(payroll["department"] == "Finance")
        #expect(payroll["company"] == "Harbour Logistics")
        #expect(payroll["headcount"] == "2")
        #expect(payroll["description"] == "Kofi Mensah (Analyst) in Payroll")
        let fleet = try #require(entries.first { $0["name"] == "Maria Rossi" })
        #expect(fleet["headcount"] == "1")
    }

    // MARK: - Execution

    @Test("CLI: The transformation produces the expected directory")
    @MainActor
    func testCLITransformMatchesExpectedOutput() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .resolvingSymlinksInPath()
            .appendingPathComponent("swift-modelling-tutorial-tests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        for name in Self.resourceNames where name.hasSuffix(".ecore") || name.hasSuffix(".atl")
            || name == "sample-company.xmi"
        {
            try FileManager.default.copyItem(at: Self.resource(name), to: workspace.appendingPathComponent(name))
        }

        let result = try await Self.execute(
            tool: "swift-atl",
            arguments: [
                "transform", "organisation2directory.atl",
                "--source", "IN=sample-company.xmi",
                "--target", "OUT=output-directory.xmi",
            ],
            in: workspace)
        #expect(result.succeeded, "The transformation should run: \(result.stdout)\(result.stderr)")

        let actual = try String(
            contentsOf: workspace.appendingPathComponent("output-directory.xmi"), encoding: .utf8)
        let expected = try Self.text(of: "expected-output.xmi")
        #expect(actual.contains("name=\"Harbour Logistics\""))
        #expect(Self.entries(in: actual) == Self.entries(in: expected))
    }

    @Test("CLI: The threaded transformation produces the same directory")
    @MainActor
    func testCLIThreadedTransformMatchesExpectedOutput() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .resolvingSymlinksInPath()
            .appendingPathComponent("swift-modelling-tutorial-tests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        for name in ["organisation.ecore", "directory.ecore", "organisation2directory-threaded.atl", "sample-company.xmi"] {
            try FileManager.default.copyItem(at: Self.resource(name), to: workspace.appendingPathComponent(name))
        }

        let result = try await Self.execute(
            tool: "swift-atl",
            arguments: [
                "transform", "organisation2directory-threaded.atl",
                "--source", "IN=sample-company.xmi",
                "--target", "OUT=output-directory.xmi",
            ],
            in: workspace)
        #expect(result.succeeded, "The threaded transformation should run: \(result.stdout)\(result.stderr)")

        let actual = try String(
            contentsOf: workspace.appendingPathComponent("output-directory.xmi"), encoding: .utf8)
        let expected = try Self.text(of: "expected-output.xmi")
        #expect(Self.entries(in: actual) == Self.entries(in: expected))
    }

    // MARK: - Query

    @Test("ATL: The query is a query unit that writes a dot file")
    func testQueryContent() throws {
        let content = try Self.text(of: "organisation2dot.atl")
        #expect(content.contains("query Organisation2Dot ="))
        #expect(!content.contains("module "))
        #expect(!content.contains("create "))
        #expect(content.contains("-- @path Organisation=organisation.ecore"))
        #expect(content.contains(".writeTo('organisation.dot')"))
        #expect(content.contains("helper context Organisation!Named def : edge(child : Organisation!Named) : String ="))
    }

    @Test("CLI: Validate the query via swift-atl")
    @MainActor
    func testCLIValidateQuery() async throws {
        let result = try await Self.execute(
            tool: "swift-atl", arguments: ["validate", Self.resource("organisation2dot.atl").path])
        #expect(result.succeeded, "The query should validate: \(result.stdout)\(result.stderr)")
    }

    @Test("CLI: The query writes the expected organisation chart")
    @MainActor
    func testCLIQueryMatchesExpectedChart() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .resolvingSymlinksInPath()
            .appendingPathComponent("swift-modelling-tutorial-tests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        for name in ["organisation.ecore", "organisation2dot.atl", "sample-company.xmi"] {
            try FileManager.default.copyItem(at: Self.resource(name), to: workspace.appendingPathComponent(name))
        }

        let result = try await Self.execute(
            tool: "swift-atl",
            arguments: [
                "query", "organisation2dot.atl",
                "--source", "sample-company.xmi",
                "--output-directory", "charts",
            ],
            in: workspace)
        #expect(result.succeeded, "The query should run: \(result.stdout)\(result.stderr)")
        #expect(result.stdout == consoleText("true\n"))

        let actual = try String(
            contentsOf: workspace.appendingPathComponent("charts/organisation.dot"), encoding: .utf8)
        #expect(actual == (try Self.text(of: "expected-organisation.dot")))
    }

    @Test("Script: The query script uses the documented command")
    func testQueryScript() throws {
        let content = try Self.text(of: "atl-advanced-02-query.sh")
        #expect(content.contains("swift-atl query organisation2dot.atl"))
        #expect(content.contains("--source sample-company.xmi"))
        #expect(content.contains("--output-directory charts"))
        #expect(content.contains("charts/organisation.dot"))
    }

    @Test("Script: The run script uses the documented command")
    func testRunScript() throws {
        let content = try Self.text(of: "atl-advanced-02-run.sh")
        #expect(content.contains("swift-atl transform organisation2directory.atl"))
        #expect(content.contains("--source IN=sample-company.xmi"))
        #expect(content.contains("--target OUT=output-directory.xmi"))
    }
}
