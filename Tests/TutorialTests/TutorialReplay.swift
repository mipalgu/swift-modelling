//
// TutorialReplay.swift
// TutorialTests
//
// Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// A tutorial to replay, as a test argument.
struct TutorialReplayCase: Sendable, CustomTestStringConvertible {
    /// The tutorial.
    let tutorial: TutorialDocument

    /// The identifier of the tutorial, such as `Ecore-CLI/01-first-metamodel`, shown in test reports.
    var testDescription: String { tutorial.identifier }

    /// The tutorials to replay, in reading order.
    ///
    /// When the environment variable ``TutorialReplayConfiguration/selectionVariable`` is set, only
    /// the tutorials whose identifier contains one of its comma-separated values are included.
    ///
    /// - Returns: A case for every selected tutorial of the catalogue.
    /// - Throws: An error if the catalogue cannot be read.
    static func all() throws -> [TutorialReplayCase] {
        let tutorials = try TutorialCatalogue.shared.get().tutorials
        let selection = (ProcessInfo.processInfo.environment[TutorialReplayConfiguration.selectionVariable] ?? "")
            .split(separator: TutorialReplayConfiguration.selectionSeparator)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return tutorials
            .filter { tutorial in selection.isEmpty || selection.contains { tutorial.identifier.contains($0) } }
            .map(TutorialReplayCase.init)
    }
}

/// What went wrong in one step of a replayed tutorial.
struct TutorialStepFailure: Sendable {
    /// The code directive of the step.
    let code: TutorialCode

    /// The resource of the step, if it could be resolved.
    let resource: URL?

    /// The position of the step among the Terminal steps of the tutorial, if it is one.
    let terminalPosition: (index: Int, count: Int)?

    /// A one-line summary of the problem.
    let problem: String

    /// Further detail, such as the output of a command.
    let detail: String

    /// The further problems of the step, after ``problem``.
    var otherProblems: [String] = []
}

/// The outcome of replaying one tutorial.
struct TutorialReplayReport: Sendable {
    /// The tutorial.
    let tutorial: TutorialDocument

    /// The working directory of its series.
    let directory: URL

    /// The number of Terminal steps of the tutorial.
    let terminalSteps: Int

    /// The number of Terminal steps that passed.
    let passedSteps: Int

    /// The failures of the steps of the tutorial, in step order.
    let failures: [TutorialStepFailure]

    /// The failures of the earlier tutorials of the series, as `tutorial: script` summaries.
    ///
    /// The files of a series build on each other, so a failure in an earlier tutorial may explain
    /// a failure in this one.
    let earlierFailures: [String]

    /// The failures of this tutorial and of the earlier tutorials of its series, as summaries.
    var failureSummaries: [String] {
        earlierFailures + failures.map { "\(tutorial.identifier): \($0.code.file) (\($0.problem))" }
    }
}

/// Replays tutorials in the working directories of their series.
///
/// The tutorials of a series run in reading order in one working directory that starts empty, as
/// a reader works through a series. Each tutorial is replayed once per test run: the replay of a
/// tutorial waits for the replay of the tutorial before it in its series, so replaying a single
/// tutorial also replays the earlier tutorials of its series. A working directory is removed once
/// the last tutorial of its series has passed every step, and kept for inspection otherwise.
actor TutorialReplayCoordinator {
    /// The coordinator shared by the tests of this target.
    static let shared = TutorialReplayCoordinator()

    /// The replays started so far, by tutorial identifier.
    private var replays: [String: Task<TutorialReplayReport, any Error>] = [:]

    /// The working directories of the series, by series.
    private var directories: [String: URL] = [:]

    /// The directory that holds the working directories of this test run.
    private let runDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(TutorialReplayConfiguration.workingDirectoryName)
        .appendingPathComponent(UUID().uuidString)

    /// The report of the replay of a tutorial, replaying it and the tutorials before it if needed.
    ///
    /// - Parameters:
    ///   - tutorial: The tutorial to replay.
    ///   - catalogue: The catalogue that holds the tutorial.
    ///   - environment: The environment in which the scripts run.
    /// - Returns: The report of the replay.
    /// - Throws: An error if a working directory cannot be prepared or a script cannot be started.
    func report(
        for tutorial: TutorialDocument, in catalogue: TutorialCatalogue, environment: TutorialReplayEnvironment
    ) async throws -> TutorialReplayReport {
        let series = catalogue.seriesPrefix(endingWith: tutorial)
        let isLast = catalogue.tutorials.last { $0.series == tutorial.series }?.identifier == tutorial.identifier
        let directory = try directory(for: tutorial.series)
        var previous: Task<TutorialReplayReport, any Error>?
        for (offset, member) in series.enumerated() {
            if let existing = replays[member.identifier] {
                previous = existing
                continue
            }
            let isSeriesEnd = isLast && offset == series.count - 1
            let earlier = previous
            let logs = runDirectory.appendingPathComponent(TutorialReplayConfiguration.toolLogsDirectoryName)
                .appendingPathComponent(directory.lastPathComponent)
            let task = Task {
                let earlierFailures = try await earlier?.value.failureSummaries ?? []
                let report = try await TutorialReplayer(
                    catalogue: catalogue, environment: environment, directory: directory, logDirectory: logs
                ).replay(member, earlierFailures: earlierFailures)
                if isSeriesEnd && report.failureSummaries.isEmpty {
                    try? FileManager.default.removeItem(at: directory)
                }
                return report
            }
            replays[member.identifier] = task
            previous = task
        }
        guard let replay = previous else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: tutorial.url.path])
        }
        return try await replay.value
    }

    /// The working directory of a series, created empty on first use.
    ///
    /// - Parameter series: The series.
    /// - Returns: The working directory.
    /// - Throws: An error if the directory cannot be created.
    private func directory(for series: String) throws -> URL {
        if let directory = directories[series] { return directory }
        let name = series.isEmpty ? "tutorials" : series.replacingOccurrences(of: "/", with: "_")
        let directory = runDirectory.appendingPathComponent(name).resolvingSymlinksInPath()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        directories[series] = directory
        return directory
    }
}

/// Replays the steps of a tutorial in a working directory.
struct TutorialReplayer: Sendable {
    /// The catalogue that holds the tutorial and its resources.
    let catalogue: TutorialCatalogue

    /// The environment in which the scripts run.
    let environment: TutorialReplayEnvironment

    /// The working directory of the series.
    let directory: URL

    /// The directory, outside the working directory, in which the tool invocations of the steps
    /// are recorded, one subdirectory per Terminal step.
    let logDirectory: URL

    /// Replays the steps of a tutorial in document order.
    ///
    /// A step that names a file writes its resource under that name, creating directories as
    /// needed. A Terminal step runs its script with the shell. It passes when the script exits
    /// with status 0, no tool that it invoked failed or reported an error, its output shows no
    /// failure to use a command, and it prints the output that it documents in `# Output:`
    /// comments; see ``TutorialStepChecks`` for the checks and for scripts that demonstrate an
    /// expected error. An output block that follows a Terminal step, a code directive named
    /// ``TutorialReplayConfiguration/outputCodeName``, must also appear in the output of that step,
    /// or the step fails. Any other code that is only shown is skipped. A failing step does not end
    /// the replay, so that later independent steps are still checked.
    ///
    /// - Parameters:
    ///   - tutorial: The tutorial to replay.
    ///   - earlierFailures: The failures of the earlier tutorials of the series.
    /// - Returns: The report of the replay.
    /// - Throws: An error if a script cannot be started.
    func replay(_ tutorial: TutorialDocument, earlierFailures: [String]) async throws -> TutorialReplayReport {
        let terminalCount = tutorial.codes.filter { $0.kind == .terminal }.count
        var terminalIndex = 0
        var passedSteps = Set<Int>()
        var failures: [TutorialStepFailure] = []
        var lastTerminal: (position: (index: Int, count: Int), output: String, passed: Bool)?
        for code in tutorial.codes {
            let position: (index: Int, count: Int)?
            if code.kind == .terminal {
                terminalIndex += 1
                position = (terminalIndex, terminalCount)
                lastTerminal = ((terminalIndex, terminalCount), "", false)
            } else {
                position = lastTerminal?.position
            }
            func fail(_ resource: URL?, _ problems: [String], _ detail: String = "") {
                failures.append(
                    TutorialStepFailure(
                        code: code, resource: resource, terminalPosition: position, problem: problems[0],
                        detail: detail, otherProblems: Array(problems.dropFirst())))
            }
            let isOutputBlock = code.name == TutorialReplayConfiguration.outputCodeName
            guard code.kind != .display || isOutputBlock else { continue }
            let resource: URL
            switch catalogue.resources.resolve(code.file) {
            case .found(let url):
                resource = url
            case .missing:
                fail(nil, ["the resource '\(code.file)' does not exist"])
                continue
            case .ambiguous(let urls):
                fail(nil, ["the resource name '\(code.file)' is ambiguous: \(urls.map(relativePath).joined(separator: ", "))"])
                continue
            }
            switch code.kind {
            case .file:
                do {
                    try write(resource, as: code.name)
                } catch {
                    fail(resource, ["the file '\(code.name)' could not be written"], "\(error)")
                }
            case .display:
                guard let terminal = lastTerminal else {
                    fail(resource, ["the output block follows no Terminal step"])
                    continue
                }
                guard terminal.passed else { continue }
                let expected = DocumentedOutput.expectedLines(
                    inOutputBlock: try String(contentsOf: resource, encoding: .utf8))
                if let unmatched = DocumentedOutput.firstUnmatched(
                    expected, in: terminal.output, workingDirectories: workingDirectoryPaths)
                {
                    fail(
                        resource,
                        [
                            "output block missing from the output of the step: \"\(unmatched.line.text)\" "
                                + "(line \(unmatched.line.scriptLine) of \(code.file); "
                                + "\(unmatched.matched) of \(expected.count) lines matched before it)"
                        ], terminal.output)
                    passedSteps.remove(terminal.position.index)
                }
            case .terminal:
                let log = logDirectory.appendingPathComponent("\(tutorial.name)-step-\(terminalIndex)")
                try FileManager.default.createDirectory(at: log, withIntermediateDirectories: true)
                let run = try await environment.run(script: resource, in: directory, toolLog: log)
                let problems = try problems(of: run, script: resource, toolLog: log)
                if problems.isEmpty {
                    passedSteps.insert(terminalIndex)
                } else {
                    fail(resource, problems, run.output)
                }
                lastTerminal = ((terminalIndex, terminalCount), run.output, problems.isEmpty)
            }
        }
        let passed = passedSteps.count
        return TutorialReplayReport(
            tutorial: tutorial, directory: directory, terminalSteps: terminalCount, passedSteps: passed,
            failures: failures, earlierFailures: earlierFailures)
    }

    /// The problems of a run of a Terminal script, in the order in which they are reported.
    ///
    /// These are the failures of the tools that the script invoked, the lines of the output that
    /// show a failure to use a command, a time-out or a non-zero exit status of the script, and,
    /// if there is no other problem, a script that names a tool but runs none, or else the first
    /// documented output line that the run did not print.
    ///
    /// - Parameters:
    ///   - run: The outcome of the run.
    ///   - script: The script that ran.
    ///   - toolLog: The directory in which the wrappers recorded the tool invocations of the run.
    /// - Returns: A description of every problem; none if the step passed.
    /// - Throws: An error if the script cannot be read.
    func problems(of run: ScriptRun, script: URL, toolLog: URL) throws -> [String] {
        let text = try String(contentsOf: script, encoding: .utf8)
        let expectingError = TutorialStepChecks.expectsError(text)
        let records = ToolInvocationLog.records(in: toolLog)
        var problems = TutorialStepChecks.toolFailures(
            records, expectingError: expectingError, scriptFailed: run.exitStatus != 0)
        problems += TutorialStepChecks.usageFailures(inOutput: run.output).map {
            "the output shows a failure to use a command: \($0)"
        }
        if run.timedOut {
            problems.append("did not finish within \(TutorialReplayConfiguration.stepTimeout) and was stopped")
        } else if run.exitStatus != 0 && !expectingError {
            problems.append(run.termination)
        }
        guard problems.isEmpty else { return problems }
        if let named = TutorialStepChecks.toolNamedButNotRun(in: text, records: records) {
            return ["the script runs none of the tools that it names (script line \(named.line): \(named.text))"]
        }
        let expected = DocumentedOutput.expectedLines(inScript: text)
        if let unmatched = DocumentedOutput.firstUnmatched(
            expected, in: run.output, workingDirectories: workingDirectoryPaths)
        {
            problems.append(
                "documented output missing: \"\(unmatched.line.text)\" (script line \(unmatched.line.scriptLine); "
                    + "\(unmatched.matched) of \(expected.count) documented lines matched before it)")
        }
        return problems
    }

    /// The paths under which the working directory may appear in an output.
    ///
    /// Besides the path itself, this includes the form with symbolic links resolved and, where the
    /// temporary directory is reached through a link below `/private`, the form that the system
    /// reports as the current directory.
    var workingDirectoryPaths: [String] {
        let paths = [directory.path, directory.resolvingSymlinksInPath().path, directory.standardizedFileURL.path]
        let aliases = paths.map { "/private" + $0 }.filter { FileManager.default.fileExists(atPath: $0) }
        return Array(Set(paths + aliases))
    }

    /// Writes a resource into the working directory under a relative path.
    ///
    /// - Parameters:
    ///   - resource: The resource to write.
    ///   - name: The relative path under which the tutorial shows the file.
    /// - Throws: An error if the path leaves the working directory or the file cannot be written.
    func write(_ resource: URL, as name: String) throws {
        let components = name.split(separator: "/")
        guard !name.hasPrefix("/"), !components.contains(".."), !components.isEmpty else {
            throw CocoaError(.fileWriteInvalidFileName, userInfo: [NSFilePathErrorKey: name])
        }
        let destination = components.reduce(directory) { $0.appendingPathComponent(String($1)) }
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(contentsOf: resource).write(to: destination, options: .atomic)
    }

    /// The path of a file relative to the repository root, for messages.
    ///
    /// - Parameter url: A file of the repository.
    /// - Returns: Its path relative to the repository root, or its full path if it lies elsewhere.
    func relativePath(_ url: URL) -> String {
        TutorialReplayMessage.relativePath(url)
    }
}

/// The texts with which the replay reports its findings.
enum TutorialReplayMessage {
    /// The path of a file relative to the repository root.
    ///
    /// - Parameter url: A file.
    /// - Returns: Its path relative to the repository root, or its full path if it lies elsewhere.
    static func relativePath(_ url: URL) -> String {
        let root = TutorialCatalogue.repositoryRoot.standardizedFileURL.path + "/"
        let path = url.standardizedFileURL.path
        return path.hasPrefix(root) ? String(path.dropFirst(root.count)) : path
    }

    /// Shortens a long output to its start and its end.
    ///
    /// - Parameter output: The output of a command.
    /// - Returns: The output, or its first and last characters with a note of how many were left out.
    static func excerpt(_ output: String) -> String {
        let limit = TutorialReplayConfiguration.reportedOutputCharacters
        guard output.count > 2 * limit else { return output }
        return "\(output.prefix(limit))\n[... \(output.count - 2 * limit) characters omitted ...]\n\(output.suffix(limit))"
    }

    /// The message for a failing step.
    ///
    /// - Parameters:
    ///   - failure: The failure.
    ///   - report: The report of the tutorial.
    /// - Returns: A message that names the tutorial, the step, its script, the problem and the output.
    static func describe(_ failure: TutorialStepFailure, in report: TutorialReplayReport) -> String {
        let terminal = failure.terminalPosition.map { "Terminal step \($0.index) of \($0.count)" }
        let step: String
        switch failure.code.kind {
        case .terminal: step = terminal ?? "Terminal step"
        case .display: step = "Output block" + (terminal.map { " after \($0)" } ?? "")
        case .file: step = "file step '\(failure.code.name)'"
        }
        var lines = [
            "Tutorial \(report.tutorial.identifier), \(step) (tutorial line \(failure.code.line)): \(failure.code.file)",
            "Problem: \(failure.problem)",
        ]
        lines += failure.otherProblems.map { "Also: \($0)" }
        if let resource = failure.resource {
            lines.append("\(failure.code.kind == .terminal ? "Script" : "Resource"): \(relativePath(resource))")
        }
        lines.append("Working directory: \(report.directory.path)")
        if !report.earlierFailures.isEmpty {
            lines.append("Earlier failures in this series: \(report.earlierFailures.joined(separator: "; "))")
        }
        if failure.code.kind != .file && failure.terminalPosition != nil {
            let output = failure.detail.isEmpty ? "(no output)" : excerpt(failure.detail)
            lines.append("Output:\n" + output.split(separator: "\n", omittingEmptySubsequences: false)
                .map { "  | \($0)" }.joined(separator: "\n"))
        } else if !failure.detail.isEmpty {
            lines.append("Detail: \(failure.detail)")
        }
        return lines.joined(separator: "\n")
    }
}
