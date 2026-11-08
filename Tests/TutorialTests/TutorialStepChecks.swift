//
// TutorialStepChecks.swift
// TutorialTests
//
// Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// One invocation of a tool during a Terminal step, as its wrapper recorded it.
struct ToolInvocationRecord: Sendable, Equatable {
    /// The name of the tool.
    let tool: String

    /// The arguments of the invocation, separated by spaces.
    let arguments: String

    /// The exit status of the tool, or `nil` if the invocation did not finish.
    let status: Int32?

    /// What the tool wrote on its standard error, whether or not the script showed it.
    ///
    /// When the standard output of the tool led to the same place as its standard error, the
    /// text also holds the standard output, in the order in which the tool wrote both.
    let standardError: String

    /// The command line of the invocation, for messages.
    var commandLine: String {
        arguments.isEmpty ? tool : "\(tool) \(arguments)"
    }

    /// The first line of the standard error that reports an error, if any.
    var firstErrorLine: String? {
        standardError.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { $0.hasPrefix(TutorialReplayConfiguration.errorPrefix) }
    }
}

/// The logs in which the wrappers of the tools record their invocations during a step.
///
/// A wrapper creates an empty file named after the tool with a unique suffix when the tool starts,
/// copies the standard error of the tool, together with its standard output if both lead to the
/// same place, into a file with the extension
/// ``TutorialReplayConfiguration/toolLogStandardErrorExtension``, and writes the exit status and
/// the arguments into a file with the extension ``TutorialReplayConfiguration/toolLogStatusExtension``
/// when the tool has finished.
enum ToolInvocationLog {
    /// Reads the invocations recorded in a log directory, in the order in which they started.
    ///
    /// - Parameter directory: The log directory of a step.
    /// - Returns: The recorded invocations; none if the directory does not exist.
    static func records(in directory: URL) -> [ToolInvocationRecord] {
        let manager = FileManager.default
        guard
            let names = try? manager.contentsOfDirectory(atPath: directory.path)
        else { return [] }
        let dated = names.filter(isRecordName).map { name -> (Date, String) in
            let attributes = try? manager.attributesOfItem(atPath: directory.appendingPathComponent(name).path)
            return ((attributes?[.modificationDate] as? Date) ?? .distantPast, name)
        }
        return dated.sorted { $0 < $1 }.map { _, name in
            let base = directory.appendingPathComponent(name)
            let status = (try? String(
                contentsOf: base.appendingPathExtension(TutorialReplayConfiguration.toolLogStatusExtension),
                encoding: .utf8)) ?? ""
            let error = (try? String(
                contentsOf: base.appendingPathExtension(TutorialReplayConfiguration.toolLogStandardErrorExtension),
                encoding: .utf8)) ?? ""
            let firstBreak = status.firstIndex(of: "\n") ?? status.endIndex
            let code = Int32(status[..<firstBreak].trimmingCharacters(in: .whitespaces))
            let arguments = status[firstBreak...].trimmingCharacters(in: .whitespacesAndNewlines)
            return ToolInvocationRecord(
                tool: String(name.prefix { $0 != "." }), arguments: arguments, status: code, standardError: error)
        }
    }

    /// Whether a file name is that of the start file of an invocation rather than one of its companions.
    ///
    /// - Parameter name: A file name in a log directory.
    /// - Returns: `true` if the name has no companion extension.
    private static func isRecordName(_ name: String) -> Bool {
        let companions = [
            TutorialReplayConfiguration.toolLogStandardErrorExtension,
            TutorialReplayConfiguration.toolLogStatusExtension,
        ]
        return !companions.contains { name.hasSuffix("." + $0) }
    }
}

/// The checks that decide whether a Terminal step failed, beyond the exit status of its script.
///
/// A script may hide the failure of a command, for example in `export X="$(command)"`, behind
/// `|| true`, or by sending its standard error to `/dev/null`. The step therefore also fails when
/// its output shows that the shell could not run a command or that a tool rejected its command
/// line, and when a wrapped tool exited with a non-zero status or reported an error, unless the
/// script carries ``TutorialReplayConfiguration/expectedErrorMarker``.
enum TutorialStepChecks {
    /// Whether a script marks itself as demonstrating an expected error.
    ///
    /// - Parameter script: The text of a script.
    /// - Returns: `true` if a line of the script starts with the marker.
    static func expectsError(_ script: String) -> Bool {
        script.split(whereSeparator: \.isNewline).contains {
            $0.trimmingCharacters(in: .whitespaces).hasPrefix(TutorialReplayConfiguration.expectedErrorMarker)
        }
    }

    /// The lines of an output that show a failure to use a command.
    ///
    /// These are the messages of the shell that it found no command (`command not found`) or could
    /// not run one (a message about a script line that ends in `No such file or directory` or
    /// `Permission denied`), the errors with which the argument parser rejects a command line, and
    /// a usage line that directly follows an error line.
    ///
    /// - Parameter output: The combined standard output and standard error of a step.
    /// - Returns: The offending lines, in output order.
    static func usageFailures(inOutput output: String) -> [String] {
        let lines = output.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        var failures: [String] = []
        var previousWasError = false
        for line in lines {
            if isShellFailure(line)
                || TutorialReplayConfiguration.argumentErrorPrefixes.contains(where: { line.hasPrefix($0) })
                || (previousWasError && line.hasPrefix(TutorialReplayConfiguration.usagePrefix))
            {
                failures.append(line)
            }
            previousWasError = line.hasPrefix(TutorialReplayConfiguration.errorPrefix)
        }
        return failures
    }

    /// Whether a line is a message of the shell that it could not run a command.
    ///
    /// - Parameter line: A line of an output without surrounding white space.
    /// - Returns: `true` for a `command not found` message, or for a message about a script line
    ///   that ends with one of ``TutorialReplayConfiguration/shellCommandFailures``.
    static func isShellFailure(_ line: String) -> Bool {
        let notFound = TutorialReplayConfiguration.shellCommandFailures[0]
        if line.contains(": " + notFound) { return true }
        guard let marker = line.range(of: TutorialReplayConfiguration.shellLineMarker),
            line[marker.upperBound...].first?.isNumber == true
        else { return false }
        return TutorialReplayConfiguration.shellCommandFailures.contains { line.hasSuffix(": " + $0) }
    }

    /// The first line of a script that names a tool although the script ran no tool.
    ///
    /// A script that only prints command lines, for example with `echo "swift-ecore validate …"`,
    /// passes every other check without showing that the commands work, so a script that names one
    /// of ``TutorialReplayConfiguration/toolNames`` outside a comment must invoke at least one tool.
    ///
    /// - Parameters:
    ///   - script: The text of a script.
    ///   - records: The recorded tool invocations of its run.
    /// - Returns: The number and text of the first line that names a tool, or `nil` if the script
    ///   invoked a tool or names none.
    static func toolNamedButNotRun(in script: String, records: [ToolInvocationRecord]) -> (line: Int, text: String)? {
        guard records.isEmpty else { return nil }
        for (offset, rawLine) in script.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.first != TutorialReplayConfiguration.commentCharacter else { continue }
            if TutorialReplayConfiguration.toolNames.contains(where: { names(line, $0) }) {
                return (offset + 1, line)
            }
        }
        return nil
    }

    /// Whether a line names a tool as a word of its own.
    ///
    /// - Parameters:
    ///   - line: A line of a script.
    ///   - tool: The name of a tool.
    /// - Returns: `true` if the name occurs with no letter, digit, hyphen or dot directly before or after it.
    static func names(_ line: String, _ tool: String) -> Bool {
        func isNamePart(_ character: Character?) -> Bool {
            guard let character else { return false }
            return character.isLetter || character.isNumber || character == "-" || character == "."
        }
        var searchStart = line.startIndex
        while let range = line.range(of: tool, range: searchStart..<line.endIndex) {
            let before = range.lowerBound > line.startIndex ? line[line.index(before: range.lowerBound)] : nil
            let after = range.upperBound < line.endIndex ? line[range.upperBound] : nil
            if !isNamePart(before) && !isNamePart(after) { return true }
            searchStart = range.upperBound
        }
        return false
    }

    /// The failures of the tools that a step invoked.
    ///
    /// Without the expected-error marker, every invocation that exited with a non-zero status or did
    /// not finish is a failure, and so is an invocation that exited with status 0 but reported an
    /// error. With the marker, at least one invocation must fail, as the script demonstrates an error.
    ///
    /// - Parameters:
    ///   - records: The recorded invocations of the step.
    ///   - expectingError: Whether the script demonstrates an expected error.
    ///   - scriptFailed: Whether the script itself exited with a non-zero status.
    /// - Returns: A description of every failure.
    static func toolFailures(
        _ records: [ToolInvocationRecord], expectingError: Bool, scriptFailed: Bool
    ) -> [String] {
        if expectingError {
            let failed = scriptFailed || records.contains { $0.status != 0 }
            return failed
                ? []
                : ["the script is marked '\(TutorialReplayConfiguration.expectedErrorMarker)', but no tool failed"]
        }
        return records.compactMap { record in
            let reason = record.firstErrorLine.map { ": \($0)" } ?? ""
            switch record.status {
            case 0?:
                return record.firstErrorLine.map { "'\(record.commandLine)' exited with status 0 but reported \($0)" }
            case let status?:
                return "'\(record.commandLine)' exited with status \(status)\(reason)"
            case nil:
                return "'\(record.commandLine)' did not finish\(reason)"
            }
        }
    }
}
