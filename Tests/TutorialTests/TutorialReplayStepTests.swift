//
// TutorialReplayStepTests.swift
// TutorialTests
//
// Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Replays a small self-authored catalogue to test how the replay judges Terminal steps.
///
/// The catalogue runs the `swift-ecore` executable of this build through its wrapper, so these
/// tests also check that the wrappers record invocations whose standard error a script discards.
@Suite(
    "Tutorial replay steps",
    .enabled(if: TutorialReplayConfiguration.canReplayShellScripts, TutorialReplayConfiguration.windowsReason))
struct TutorialReplayStepTests {
    /// The scripts and texts of the catalogue, by resource name.
    static let resources: [String: String] = [
        "hello.sh": "echo 'Hello, world'\n",
        "hello-output.txt": "Hello, world\n",
        "goodbye.sh": "echo 'Goodbye'\n",
        "goodbye-output.txt": "Hello again\n",
        "masked.sh": "swift-ecore no-such-command 2>/dev/null || true\n",
        "expected.sh": "\(TutorialReplayConfiguration.expectedErrorMarker): the file does not exist\n"
            + "swift-ecore validate missing-model.xmi\n",
        "unexpected.sh": "\(TutorialReplayConfiguration.expectedErrorMarker)\nswift-ecore --version\n",
        "hidden.sh": "export RESULT=\"$(./no-such-script.sh)\"\n",
        "orphan-output.txt": "Nothing ran before this\n",
        "echo-only.sh": "echo 'Run: swift-ecore validate model.ecore'\n",
    ]

    /// The tutorial of the catalogue.
    static let tutorial = """
        @Tutorial(time: 1) {
            @Code(name: "Output", file: orphan-output.txt)
            @Code(name: "Terminal", file: hello.sh)
            @Code(name: "Output", file: hello-output.txt)
            @Code(name: "Terminal", file: goodbye.sh)
            @Code(name: "Output", file: goodbye-output.txt)
            @Code(name: "Terminal", file: masked.sh)
            @Code(name: "Terminal", file: expected.sh)
            @Code(name: "Terminal", file: unexpected.sh)
            @Code(name: "Terminal", file: hidden.sh)
            @Code(name: "Terminal", file: echo-only.sh)
        }
        """

    @Test("Output blocks, masked and hidden failures, expected errors and echoed commands are judged")
    func judgedSteps() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let catalogue = root.appendingPathComponent("Example.docc")
        let tutorials = catalogue.appendingPathComponent("Tutorials/Series")
        let resources = catalogue.appendingPathComponent("Resources")
        for directory in [tutorials, resources, root.appendingPathComponent("work")] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try Self.tutorial.write(
            to: tutorials.appendingPathComponent("Steps.tutorial"), atomically: true, encoding: .utf8)
        for (name, text) in Self.resources {
            try text.write(to: resources.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }
        let loaded = try TutorialCatalogue(root: catalogue)
        let document = try #require(loaded.tutorials.first)
        let replayer = TutorialReplayer(
            catalogue: loaded, environment: try TutorialReplayEnvironment.shared.get(),
            directory: root.appendingPathComponent("work").resolvingSymlinksInPath(),
            logDirectory: root.appendingPathComponent("logs"))

        let report = try await replayer.replay(document, earlierFailures: [])

        #expect(report.terminalSteps == 7)
        #expect(report.passedSteps == 2)
        let failures = Dictionary(report.failures.map { ($0.code.file, $0) }, uniquingKeysWith: { first, _ in first })
        #expect(Set(failures.keys) == [
                "orphan-output.txt", "goodbye-output.txt", "masked.sh", "unexpected.sh", "hidden.sh", "echo-only.sh",
            ])
        #expect(failures["orphan-output.txt"]?.problem == "the output block follows no Terminal step")
        #expect(failures["goodbye-output.txt"]?.problem.contains("\"Hello again\"") == true)
        #expect(failures["goodbye-output.txt"]?.terminalPosition?.index == 2)
        #expect(failures["masked.sh"]?.problem.hasPrefix("'swift-ecore no-such-command' exited with status 64") == true)
        #expect(failures["unexpected.sh"]?.problem.contains("no tool failed") == true)
        #expect(failures["hidden.sh"]?.problem.hasSuffix("./no-such-script.sh: No such file or directory") == true)
        #expect(failures["echo-only.sh"]?.problem.hasPrefix("the script runs none of the tools") == true)
        let message = TutorialReplayMessage.describe(try #require(failures["goodbye-output.txt"]), in: report)
        #expect(message.contains("Output block after Terminal step 2 of 7"))
        #expect(message.contains("  | Goodbye"))
    }
}
