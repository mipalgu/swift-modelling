//
// TutorialReplayHarnessTests.swift
// TutorialTests
//
// Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests of the parts of the tutorial replay that read tutorials, scripts, help pages and documents.
@Suite("Tutorial replay harness")
struct TutorialReplayHarnessTests {
    // MARK: - Directives

    @Test("Directive arguments may be quoted, contain parentheses, or be bare words")
    func directiveArguments() {
        let text = """
            @Step {
                @Code(name: "Book.java (excerpt)", file: book-excerpt.java)
            }
            @Code(name: "Terminal", file: "run.sh")
            """
        let codes = TutorialCatalogue.codes(in: text)
        #expect(
            codes == [
                TutorialCode(name: "Book.java (excerpt)", file: "book-excerpt.java", line: 2),
                TutorialCode(name: "Terminal", file: "run.sh", line: 4),
            ])
        #expect(codes.map(\.kind) == [.display, .terminal])
    }

    @Test("Referenced files include previous files")
    func referencedFiles() {
        let text = #"@Code(name: "A.ecore", file: a-2.ecore, previousFile: a-1.ecore)"#
        let files = TutorialCatalogue.referencedFiles(in: text).map(\.file)
        #expect(files == ["a-2.ecore", "a-1.ecore"])
    }

    @Test("Display labels are output blocks and names with a remark in parentheses")
    func displayLabels() {
        #expect(TutorialCode.isDisplayLabel("Output"))
        #expect(TutorialCode.isDisplayLabel("Files (abridged)"))
        #expect(!TutorialCode.isDisplayLabel("Company.ecore"))
        #expect(!TutorialCode.isDisplayLabel("queries/all.aql"))
        #expect(!TutorialCode.isDisplayLabel("f(x)"))
    }

    @Test("The table of contents yields tutorial names in order")
    func tableOfContents() {
        let text = """
            @Tutorials(name: "Example") {
                @Chapter(name: "One") {
                    @TutorialReference(tutorial: "doc:Second")
                    @TutorialReference(tutorial: "doc:First")
                }
            }
            """
        #expect(TutorialCatalogue.tutorialReferences(in: text) == ["Second", "First"])
    }

    @Test("Reading order follows the table of contents within a series, then file names")
    func readingOrder() {
        func document(_ series: String, _ name: String) -> TutorialDocument {
            TutorialDocument(url: URL(fileURLWithPath: "/\(name)"), series: series, name: name, codes: [])
        }
        let documents = [document("B", "b1"), document("A", "a2"), document("A", "a1"), document("A", "extra")]
        let ordered = TutorialCatalogue.readingOrder(of: documents, tableOfContents: ["b1", "a2", "a1"])
        #expect(ordered.map(\.identifier) == ["B/b1", "A/a2", "A/a1", "A/extra"])
    }

    // MARK: - Documented output

    @Test("Output headers with and without a qualifier are recognised")
    func outputHeaders() {
        #expect(DocumentedOutput.outputHeaderRemainder("# Output: true") == " true")
        #expect(DocumentedOutput.outputHeaderRemainder("# Output:") == "")
        #expect(DocumentedOutput.outputHeaderRemainder("# Output (sample):") == "")
        #expect(DocumentedOutput.outputHeaderRemainder("# Output files go here") == nil)
        #expect(DocumentedOutput.outputHeaderRemainder("echo '# Output:'") == nil)
    }

    @Test("Output blocks end at the first line that is not a comment")
    func outputBlocks() {
        let script = """
            tool run
            # Output: "Example"

            # Explain the next command
            tool list
              # Output:
              # first line
              #
              # ...
              # second line
            echo done
            # Not output
            """
        let expected = DocumentedOutput.expectedLines(inScript: script)
        #expect(
            expected == [
                ExpectedOutputLine(text: "\"Example\"", scriptLine: 2),
                ExpectedOutputLine(text: "first line", scriptLine: 7),
                ExpectedOutputLine(text: "second line", scriptLine: 10),
            ])
    }

    @Test("Volatile values are normalised on both sides")
    func normalisation() {
        let output = "\u{1B}[32mRun 123e4567-e89b-12d3-a456-426614174000 at 2026-11-05T10:20:30Z took 12ms in /tmp/w/x\u{1B}[0m"
        #expect(
            DocumentedOutput.normalised(output, workingDirectories: ["/tmp/w"])
                == "Run <uuid> at <timestamp> took <duration> in <workdir>/x")
        #expect(DocumentedOutput.normalised("backup_20240120_143022 [15:01:30]") == "backup_<timestamp> [<time>]")
        #expect(DocumentedOutput.normalised("  4   sources  ") == "4 sources")
    }

    @Test("Expected lines must appear in order, each in its own output line")
    func orderedContainment() {
        let expected = [
            ExpectedOutputLine(text: "Package: Company", scriptLine: 1),
            ExpectedOutputLine(text: "Classes: 2", scriptLine: 2),
        ]
        #expect(DocumentedOutput.firstUnmatched(expected, in: "[info] Package:  Company\nClasses: 2\n") == nil)
        let reversed = DocumentedOutput.firstUnmatched(expected, in: "Classes: 2\nPackage: Company\n")
        #expect(reversed?.line.scriptLine == 2)
        #expect(reversed?.matched == 1)
    }

    @Test("An elision within an expected line matches any text in between")
    func inlineElision() {
        let expected = [ExpectedOutputLine(text: "[\"A\", \"B\", ...]", scriptLine: 1)]
        #expect(DocumentedOutput.firstUnmatched(expected, in: "[\"A\", \"B\", \"C\"]") == nil)
        #expect(DocumentedOutput.firstUnmatched(expected, in: "[\"B\", \"A\"]") != nil)
    }

    // MARK: - Environment

    @Test("The search path puts the wrappers and the products before every other directory")
    func searchPath() {
        let path = TutorialReplayEnvironment.searchPath(
            tools: "/tmp/tools", products: "/build/debug",
            inherited: ["/opt/tools/bin", "/usr/bin", "/build/debug", ""])
        #expect(path == "/tmp/tools:/build/debug:/usr/bin:/bin:/usr/sbin:/sbin:/opt/tools/bin")
    }

    @Test("The stand-in for a missing tool reports it and exits as for an unknown command")
    func standIn() {
        let script = TutorialReplayEnvironment.wrapperScript(for: "swift-aql", executable: nil, shell: "/bin/bash")
        #expect(script.hasPrefix("#!/bin/bash\n"))
        #expect(script.contains("swift-aql: \(TutorialReplayConfiguration.missingToolMessage)"))
        #expect(script.contains("exit \(TutorialReplayConfiguration.missingToolStatus)"))
    }

    @Test("A wrapper runs the executable of this build and records the invocation")
    func wrapper() {
        let script = TutorialReplayEnvironment.wrapperScript(
            for: "swift-ecore", executable: "/build/it's/swift-ecore", shell: "/bin/bash")
        #expect(script.contains("'/build/it'\\''s/swift-ecore' \"$@\""))
        #expect(script.contains(TutorialReplayConfiguration.toolLogVariable))
        #expect(script.contains("PIPESTATUS[0]"))
    }

    // MARK: - Step checks

    @Test("The expected-error marker is a comment line of its own")
    func expectedErrorMarker() {
        #expect(TutorialStepChecks.expectsError("ls\n  # Expected error: the model is invalid\nswift-ecore validate x"))
        #expect(!TutorialStepChecks.expectsError("# An expected error would be shown here"))
    }

    @Test("Usage failures are found in an output, and other error text is not")
    func usageFailures() {
        let output = """
            Converting...
            Usage: is fine without an error before it
            /work/step.sh: line 6: swift-json: command not found
            /work/step.sh: line 1: Scripts/fetch.sh: No such file or directory
            swift-aql: command not found (this build has no executable of that name)
            Error: Unknown option '--detail'
            Usage: swift-ecore query <input-path>
            Error: Unexpected argument 'document'
            Error: Missing expected argument '<input-path>'
            Error: File not found: x.xmi
            ls: missing: No such file or directory
            """
        #expect(
            TutorialStepChecks.usageFailures(inOutput: output) == [
                "/work/step.sh: line 6: swift-json: command not found",
                "/work/step.sh: line 1: Scripts/fetch.sh: No such file or directory",
                "swift-aql: command not found (this build has no executable of that name)",
                "Error: Unknown option '--detail'",
                "Usage: swift-ecore query <input-path>",
                "Error: Unexpected argument 'document'",
                "Error: Missing expected argument '<input-path>'",
            ])
    }

    @Test("A script that names a tool must run one")
    func toolNamedButNotRun() {
        let script = "# swift-ecore in a comment\necho \"Run: swift-ecore validate m.ecore\"\n"
        let record = ToolInvocationRecord(tool: "swift-ecore", arguments: "info", status: 0, standardError: "")
        #expect(TutorialStepChecks.toolNamedButNotRun(in: script, records: [])?.line == 2)
        #expect(TutorialStepChecks.toolNamedButNotRun(in: script, records: [record]) == nil)
        #expect(TutorialStepChecks.toolNamedButNotRun(in: "ls swift-ecore.wasm my-swift-ecore\n", records: []) == nil)
        #expect(TutorialStepChecks.names("/opt/bin/swift-mtl --help", "swift-mtl"))
    }

    @Test("Failed or erroring tool invocations fail a step unless it expects an error")
    func toolFailures() {
        let ok = ToolInvocationRecord(tool: "swift-ecore", arguments: "info", status: 0, standardError: "")
        let failed = ToolInvocationRecord(
            tool: "swift-ecore", arguments: "document x", status: 64,
            standardError: "Error: Unexpected argument 'document'\nUsage: swift-ecore <subcommand>\n")
        let erring = ToolInvocationRecord(tool: "swift-mtl", arguments: "", status: 0, standardError: "Error: odd\n")
        #expect(TutorialStepChecks.toolFailures([ok], expectingError: false, scriptFailed: false).isEmpty)
        #expect(
            TutorialStepChecks.toolFailures([ok, failed, erring], expectingError: false, scriptFailed: false) == [
                "'swift-ecore document x' exited with status 64: Error: Unexpected argument 'document'",
                "'swift-mtl' exited with status 0 but reported Error: odd",
            ])
        #expect(TutorialStepChecks.toolFailures([ok, failed], expectingError: true, scriptFailed: false).isEmpty)
        #expect(TutorialStepChecks.toolFailures([ok], expectingError: true, scriptFailed: true).isEmpty)
        #expect(TutorialStepChecks.toolFailures([ok], expectingError: true, scriptFailed: false).count == 1)
    }

    @Test("Tool invocation logs are read with their status, arguments and standard error")
    func toolInvocationLogs() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let record = directory.appendingPathComponent("swift-ecore.AbC123")
        try Data().write(to: record)
        try "64\nvalidate --detail full \n".write(
            to: record.appendingPathExtension(TutorialReplayConfiguration.toolLogStatusExtension),
            atomically: true, encoding: .utf8)
        try "Error: Unknown option '--detail'\n".write(
            to: record.appendingPathExtension(TutorialReplayConfiguration.toolLogStandardErrorExtension),
            atomically: true, encoding: .utf8)
        try Data().write(to: directory.appendingPathComponent("swift-mtl.XyZ789"))
        let records = ToolInvocationLog.records(in: directory).sorted { $0.tool < $1.tool }
        #expect(
            records == [
                ToolInvocationRecord(
                    tool: "swift-ecore", arguments: "validate --detail full", status: 64,
                    standardError: "Error: Unknown option '--detail'\n"),
                ToolInvocationRecord(tool: "swift-mtl", arguments: "", status: nil, standardError: ""),
            ])
        #expect(ToolInvocationLog.records(in: directory.appendingPathComponent("absent")).isEmpty)
    }

    @Test("Every non-empty line of an output block is expected, except elisions")
    func outputBlockLines() {
        #expect(
            DocumentedOutput.expectedLines(inOutputBlock: "Wrote a.genmodel\n\n...\n  Done  \n") == [
                ExpectedOutputLine(text: "Wrote a.genmodel", scriptLine: 1),
                ExpectedOutputLine(text: "Done", scriptLine: 4),
            ])
    }

    // MARK: - Documented command lines

    @Test("Help pages yield subcommands, the default subcommand and long options")
    func helpPages() {
        let text = """
            USAGE: tool <subcommand>

            OPTIONS:
              --version               Show the version.
              -h, --help              Show help information.
              -o, --output <output>   Output directory
              --cache/--no-cache      Whether to cache
              --[no-]check            Whether to check
                    --not-an-option is mentioned in a discussion
            --also-not-an-option at the start of a line

            SUBCOMMANDS:
              generate (default)      Generate text
              parse                   Parse

              See 'tool help <subcommand>' for detailed help.
            """
        let page = CommandHelpPage(text: text)
        #expect(page.subcommands == ["generate", "parse"])
        #expect(page.defaultSubcommand == "generate")
        #expect(
            page.longOptions
                == ["--version", "--help", "--output", "--cache", "--no-cache", "--check", "--no-check"])
    }

    @Test("Shell blocks yield joined command lines without prompts and comments")
    func shellLines() {
        let markdown = """
            ```swift
            swift-ecore ignored --swift
            ```

            ```bash
            # A comment
            $ swift-ecore validate model.xmi \\
                --verbose
            ```
            """
        let lines = DocumentedCommands.shellLines(inMarkdown: markdown)
        #expect(lines.count == 1)
        #expect(lines.first?.line == 7)
        #expect(lines.first?.text == "swift-ecore validate model.xmi  --verbose")
    }

    @Test("Command lines split into invocations of the tools")
    func invocations() {
        let line = #"cd x && FOO=1 swift-ecore query "a b" --query 'c d' 2>&1 | swift run swift-mtl --help # note"#
        let found = DocumentedCommands.invocations(in: line, at: 3)
        #expect(found.map(\.tool) == ["swift-ecore", "swift-mtl"])
        #expect(found.first?.arguments == ["query", "a b", "--query", "c d", "2>&1"])
        #expect(found.last?.arguments == ["--help"])
    }

    @Test("Unknown subcommands and unlisted options are reported, defaults and placeholders accepted")
    func invocationProblems() async throws {
        let root = CommandHelpPage(text: "SUBCOMMANDS:\n  validate\n  query\n")
        let validate = CommandHelpPage(text: "OPTIONS:\n  --verbose   Verbose\n")
        let help: (String, String?) async throws -> CommandHelpPage? = { tool, subcommand in
            guard tool == "swift-ecore" else { return nil }
            return subcommand == nil ? root : validate
        }
        func problems(_ line: String) async throws -> [String] {
            let invocation = try #require(DocumentedCommands.invocations(in: line, at: 1).first)
            return try await DocumentedCommands.problems(of: invocation, help: help)
        }
        #expect(try await problems("swift-ecore validate m.xmi --verbose").isEmpty)
        #expect(try await problems("swift-ecore <command> --help").isEmpty)
        #expect(try await problems("swift-ecore help validate").isEmpty)
        #expect(try await problems("swift-ecore inspect m.ecore").count == 1)
        #expect(try await problems("swift-ecore validate m.xmi --detail=full --verbose").count == 1)
        #expect(try await problems("swift-aql evaluate").first?.contains("not an executable") == true)
        let defaulted = CommandHelpPage(text: "SUBCOMMANDS:\n  generate (default)\n")
        let generate = CommandHelpPage(text: "OPTIONS:\n  --model <model>   Model\n")
        let invocation = try #require(DocumentedCommands.invocations(in: "swift-mtl t.mtl --model m.xmi", at: 1).first)
        let found = try await DocumentedCommands.problems(of: invocation) { _, subcommand in
            subcommand == nil ? defaulted : generate
        }
        #expect(found.isEmpty)
    }
}
