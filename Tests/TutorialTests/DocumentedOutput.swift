//
// DocumentedOutput.swift
// TutorialTests
//
// Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// A line of output that a tutorial script documents in an output comment block.
struct ExpectedOutputLine: Sendable, Equatable {
    /// The text of the line without its comment marker, as the script shows it.
    let text: String

    /// The line of the script on which the text appears.
    let scriptLine: Int
}

/// The output that a tutorial script documents, and the check that a run printed it.
///
/// A script documents what its commands print in comment blocks that start with
/// `# Output:`. The text after the colon, if any, is the first expected line, and every comment
/// line that directly follows is a further expected line, until the first line that is not a
/// comment. The marker may carry a qualifier in parentheses, as in `# Output (sample):`.
///
/// A run passes the check when every expected line appears, in order, in the combined standard
/// output and standard error of the step: each expected line must be contained in a separate line
/// of the output, later than the line that held the expected line before it. Both sides are
/// normalised first, see ``normalised(_:workingDirectories:)``.
enum DocumentedOutput {
    /// The expected lines that a script documents, in script order.
    ///
    /// Lines that are empty after normalisation and lines that only mark omitted output, such as
    /// `# ...`, are left out.
    ///
    /// - Parameter script: The text of a shell script.
    /// - Returns: The expected lines of all output blocks of the script.
    static func expectedLines(inScript script: String) -> [ExpectedOutputLine] {
        var expected: [ExpectedOutputLine] = []
        var inBlock = false
        for (offset, rawLine) in script.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if let remainder = outputHeaderRemainder(line) {
                inBlock = true
                append(remainder, line: offset + 1, to: &expected)
            } else if inBlock, line.first == TutorialReplayConfiguration.commentCharacter {
                append(String(line.dropFirst()), line: offset + 1, to: &expected)
            } else {
                inBlock = false
            }
        }
        return expected
    }

    /// The expected lines of the text of an output block, which shows what the preceding Terminal
    /// step printed.
    ///
    /// Every line of the text is an expected line, except lines that are empty after normalisation
    /// and lines that only mark omitted output.
    ///
    /// - Parameter text: The text of the resource of a code directive named
    ///   ``TutorialReplayConfiguration/outputCodeName``.
    /// - Returns: The expected lines, with their lines in the resource.
    static func expectedLines(inOutputBlock text: String) -> [ExpectedOutputLine] {
        var expected: [ExpectedOutputLine] = []
        for (offset, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            append(String(line), line: offset + 1, to: &expected)
        }
        return expected
    }

    /// The text after the marker of an output comment block, if a line starts such a block.
    ///
    /// - Parameter line: A line of a script without surrounding white space.
    /// - Returns: The text after the colon of the marker, or `nil` if the line starts no block.
    static func outputHeaderRemainder(_ line: String) -> String? {
        guard line.first == TutorialReplayConfiguration.commentCharacter else { return nil }
        var rest = line.dropFirst().drop { $0.isWhitespace }
        guard rest.hasPrefix(TutorialReplayConfiguration.outputMarker) else { return nil }
        rest = rest.dropFirst(TutorialReplayConfiguration.outputMarker.count).drop { $0.isWhitespace }
        if rest.first == "(" {
            guard let close = rest.firstIndex(of: ")") else { return nil }
            rest = rest[rest.index(after: close)...].drop { $0.isWhitespace }
        }
        guard rest.first == ":" else { return nil }
        return String(rest.dropFirst())
    }

    /// Normalises a text so that values which change from run to run compare equal.
    ///
    /// The normalisation removes terminal colour sequences, replaces the working directory of the
    /// replay with ``TutorialReplayConfiguration/workingDirectoryPlaceholder``, replaces
    /// universally unique identifiers, dates with an optional time, compact time stamps such as
    /// `20240120_143022`, times of day and durations such as `12ms` or `0.5 seconds` with
    /// placeholders, and collapses every run of white space to one space.
    ///
    /// - Parameters:
    ///   - text: The text to normalise.
    ///   - workingDirectories: The paths under which the working directory of the replay may appear.
    /// - Returns: The normalised text.
    static func normalised(_ text: String, workingDirectories: [String] = []) -> String {
        var result = text.replacing(#/\x1B\[[0-9;?]*[\x20-\x2F]*[\x40-\x7E]/#, with: "")
        for directory in workingDirectories.sorted(by: { $0.count > $1.count }) where !directory.isEmpty {
            result = result.replacingOccurrences(
                of: directory, with: TutorialReplayConfiguration.workingDirectoryPlaceholder)
        }
        result = result.replacing(
            #/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/#,
            with: TutorialReplayConfiguration.uuidPlaceholder)
        result = result.replacing(
            #/\d{4}-\d{2}-\d{2}(?:[T ]\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?(?:Z|[+-]\d{2}:?\d{2})?)?/#,
            with: TutorialReplayConfiguration.timestampPlaceholder)
        result = result.replacing(#/\d{8}[_T]\d{6}/#, with: TutorialReplayConfiguration.timestampPlaceholder)
        result = result.replacing(
            #/\b\d{1,2}:\d{2}(?::\d{2}(?:\.\d+)?)?\b/#, with: TutorialReplayConfiguration.timePlaceholder)
        result = result.replacing(
            #/\b\d+(?:\.\d+)?\s?(?:ns|µs|us|ms|s|secs?|seconds?|mins?|minutes?)\b/#,
            with: TutorialReplayConfiguration.durationPlaceholder)
        return result.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// The parts of a normalised expected line that must appear in order within one output line.
    ///
    /// An elision marker such as `...` within an expected line stands for omitted text, so it
    /// splits the line into parts.
    ///
    /// - Parameter line: A normalised expected line.
    /// - Returns: The non-empty parts of the line.
    static func fragments(of line: String) -> [String] {
        var parts = [line]
        for marker in TutorialReplayConfiguration.elisionMarkers {
            parts = parts.flatMap { $0.components(separatedBy: marker) }
        }
        return parts.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    /// Whether an output line contains the parts of an expected line in order.
    ///
    /// - Parameters:
    ///   - fragments: The parts of a normalised expected line.
    ///   - line: A normalised output line.
    /// - Returns: `true` if every part occurs in the line after the part before it.
    static func line(_ line: String, contains fragments: [String]) -> Bool {
        var remainder = line[...]
        for fragment in fragments {
            guard let range = remainder.range(of: fragment) else { return false }
            remainder = remainder[range.upperBound...]
        }
        return true
    }

    /// The first expected line that a run did not print in order, if any.
    ///
    /// - Parameters:
    ///   - expected: The expected lines of a script.
    ///   - output: The combined standard output and standard error of the run.
    ///   - workingDirectories: The paths under which the working directory of the replay may appear.
    /// - Returns: The first expected line that has no matching output line after the matches of
    ///   the lines before it, and how many expected lines matched before it, or `nil` if all match.
    static func firstUnmatched(
        _ expected: [ExpectedOutputLine], in output: String, workingDirectories: [String] = []
    ) -> (line: ExpectedOutputLine, matched: Int)? {
        let outputLines = output.split(omittingEmptySubsequences: true, whereSeparator: \.isNewline)
            .map { normalised(String($0), workingDirectories: workingDirectories) }
        var next = 0
        for (index, line) in expected.enumerated() {
            let parts = fragments(of: normalised(line.text))
            guard !parts.isEmpty else { continue }
            guard let match = outputLines[next...].firstIndex(where: { Self.line($0, contains: parts) }) else {
                return (line, index)
            }
            next = match + 1
        }
        return nil
    }

    /// Adds a documented line unless it is empty or only marks omitted output.
    ///
    /// - Parameters:
    ///   - text: The text of the line without its comment marker.
    ///   - line: The line of the script on which the text appears.
    ///   - expected: The expected lines found so far.
    private static func append(_ text: String, line: Int, to expected: inout [ExpectedOutputLine]) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !fragments(of: normalised(trimmed)).isEmpty else { return }
        expected.append(ExpectedOutputLine(text: trimmed, scriptLine: line))
    }
}
