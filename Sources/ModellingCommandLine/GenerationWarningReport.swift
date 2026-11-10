//
// GenerationWarningReport.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation

/// Reports the warnings of a template run or of an expression evaluation on standard error.
///
/// Each distinct warning is written once, as a line that starts with
/// ``ConversionWarningReport/warningPrefix``, followed by the line and column of the construct
/// that caused it when they are known. Results and completion messages stay on standard output.
/// Warnings do not change the exit status of a command.
public enum GenerationWarningReport {
    /// The lines that report the warnings of a template run.
    ///
    /// - Parameter warnings: The warnings, in the order in which they were reported.
    /// - Returns: One line for each distinct warning, in order; no lines if there is no warning.
    public static func lines(for warnings: [SourceDiagnostic]) -> [String] {
        var lines: [String] = []
        var seen = Set<String>()
        for warning in warnings {
            let line = ConversionWarningReport.warningPrefix + location(of: warning) + warning.message
            if seen.insert(line).inserted { lines.append(line) }
        }
        return lines
    }

    /// The line and column at which a warning starts, as they precede its message.
    ///
    /// - Parameter warning: The warning.
    /// - Returns: For example `line 3, column 7: `, or an empty text if the place is not known.
    static func location(of warning: SourceDiagnostic) -> String {
        warning.range.map { "line \($0.start.line), column \($0.start.column): " } ?? ""
    }

    /// Writes the warnings of a template run to standard error.
    ///
    /// The warnings follow everything that the command printed on standard output before
    /// them, see ``StandardStreams/writeToStandardError(_:)``.
    ///
    /// - Parameter warnings: The warnings, in the order in which they were reported.
    public static func write(_ warnings: [SourceDiagnostic]) {
        let lines = lines(for: warnings)
        guard !lines.isEmpty else { return }
        StandardStreams.writeToStandardError(lines.joined(separator: "\n") + "\n")
    }
}
