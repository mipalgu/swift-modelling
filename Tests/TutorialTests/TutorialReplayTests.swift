//
// TutorialReplayTests.swift
// TutorialTests
//
// Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Replays every tutorial of the documentation catalogue as a reader would follow it.
///
/// Each tutorial is one test case. Its steps run in document order in the working directory of
/// its series: files are saved under the names the tutorial shows, and Terminal scripts run with
/// the tools of this build first on the search path. A Terminal step passes when its script exits
/// with status 0 and prints the output that the script documents in its `# Output:` comments.
@Suite(
    "Tutorial replay",
    .enabled(if: TutorialReplayConfiguration.canReplayShellScripts, TutorialReplayConfiguration.windowsReason))
struct TutorialReplayTests {
    /// Replays one tutorial, after the earlier tutorials of its series, and reports every failing step.
    ///
    /// - Parameter replayCase: The tutorial to replay.
    /// - Throws: An error if the catalogue cannot be read or a script cannot be started.
    @Test("Replay a tutorial in the working directory of its series", arguments: try TutorialReplayCase.all())
    func replay(_ replayCase: TutorialReplayCase) async throws {
        let catalogue = try TutorialCatalogue.shared.get()
        let environment = try TutorialReplayEnvironment.shared.get()
        let report = try await TutorialReplayCoordinator.shared.report(
            for: replayCase.tutorial, in: catalogue, environment: environment)
        for failure in report.failures {
            Issue.record(Comment(rawValue: TutorialReplayMessage.describe(failure, in: report)))
        }
        if !report.failures.isEmpty {
            Issue.record(
                "\(report.tutorial.identifier): \(report.passedSteps) of \(report.terminalSteps) Terminal steps passed")
        }
    }
}

/// Checks that the code directives and the table of contents of the tutorials resolve.
@Suite("Tutorial resource integrity")
struct TutorialResourceIntegrityTests {
    /// Checks that every resource that a code directive names resolves to exactly one file.
    ///
    /// DocC finds a resource by its file name anywhere below the resources directory, so a name
    /// that matches no file shows nothing, and a name that matches several files may show either.
    ///
    /// - Throws: An error if the catalogue cannot be read.
    @Test("Every resource that a tutorial names resolves to exactly one file")
    func resourcesResolve() throws {
        let catalogue = try TutorialCatalogue.shared.get()
        for tutorial in catalogue.tutorials {
            let text = try String(contentsOf: tutorial.url, encoding: .utf8)
            for reference in TutorialCatalogue.referencedFiles(in: text) {
                let location = "\(TutorialReplayMessage.relativePath(tutorial.url)):\(reference.line)"
                switch catalogue.resources.resolve(reference.file) {
                case .found:
                    continue
                case .missing:
                    Issue.record("\(location): the resource '\(reference.file)' does not exist")
                case .ambiguous(let urls):
                    let paths = urls.map(TutorialReplayMessage.relativePath).joined(separator: ", ")
                    Issue.record("\(location): the resource name '\(reference.file)' matches \(urls.count) files: \(paths)")
                }
            }
        }
    }

    /// Checks that every resource of the catalogue is used, as ``TutorialResourceUsage`` defines it.
    ///
    /// A resource that nothing uses is not published as part of any tutorial, so it is either left
    /// over from an earlier version or used only by a test, which should then keep its own fixture.
    ///
    /// - Throws: An error if the catalogue cannot be read.
    @Test("Every resource of the catalogue is used by a tutorial, an article or another used resource")
    func resourcesAreUsed() throws {
        let catalogue = try TutorialCatalogue.shared.get()
        let resources = TutorialReplayConfiguration.tutorialCatalogue + "/" + TutorialReplayConfiguration.resourcesDirectory
        for path in try TutorialResourceUsage.unusedResources(inCatalogue: catalogue.root) {
            Issue.record("\(resources)/\(path) is used by no tutorial, article or used resource")
        }
    }

    /// Checks that every tutorial that the table of contents refers to exists exactly once.
    ///
    /// - Throws: An error if the catalogue cannot be read.
    @Test("Every tutorial of the table of contents exists exactly once")
    func tableOfContentsResolves() throws {
        let catalogue = try TutorialCatalogue.shared.get()
        #expect(!catalogue.tableOfContents.isEmpty, "The catalogue has no table of contents")
        for name in catalogue.tableOfContents {
            let matches = catalogue.tutorials.filter { $0.name == name }
            #expect(
                matches.count == 1,
                "The table of contents refers to '\(name)', which matches \(matches.count) tutorial files")
        }
    }
}

/// A document whose command lines are checked, as a test argument.
struct DocumentedCommandDocument: Sendable, CustomTestStringConvertible {
    /// The location of the document.
    let url: URL

    /// The path of the document relative to the repository root, shown in test reports.
    var testDescription: String { TutorialReplayMessage.relativePath(url) }

    /// The read-me file and every article of the documentation catalogues.
    ///
    /// - Returns: A test argument for every document.
    /// - Throws: An error if the sources directory cannot be read.
    static func all() throws -> [DocumentedCommandDocument] {
        try DocumentedCommands.documents().map(DocumentedCommandDocument.init)
    }
}

/// Checks that the command lines that the read-me file and the articles show are accepted by the tools.
@Suite("Documented command lines")
struct DocumentedCommandLineTests {
    /// Checks that each documented invocation names an existing subcommand and listed long options.
    ///
    /// - Parameter document: The document to check.
    /// - Throws: An error if the document cannot be read or a tool cannot be started.
    @Test("Documented invocations use existing subcommands and options", arguments: try DocumentedCommandDocument.all())
    func invocationsParse(_ document: DocumentedCommandDocument) async throws {
        let products = URL(fileURLWithPath: try swiftEcoreExecutablePath()).deletingLastPathComponent()
        let text = try String(contentsOf: document.url, encoding: .utf8)
        for (line, command) in DocumentedCommands.shellLines(inMarkdown: text) {
            for invocation in DocumentedCommands.invocations(in: command, at: line) {
                let problems = try await DocumentedCommands.problems(of: invocation) { tool, subcommand in
                    try await CommandLineHelp.shared.page(
                        tool: tool, subcommand: subcommand, productsDirectory: products)
                }
                for problem in problems {
                    Issue.record("\(document.testDescription):\(invocation.line): \(problem)\n  | \(invocation.text)")
                }
            }
        }
    }
}
