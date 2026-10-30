//
// GenerationWarningReport.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation

/// Reports the warnings of a template run on standard error.
///
/// Each distinct warning is written once, as a line that starts with
/// ``ConversionWarningReport/warningPrefix``, followed by the line and column of the construct
/// that caused it when they are known. Results and completion messages stay on standard output.
public enum GenerationWarningReport {
    /// The lines that report the warnings of a template run.
    ///
    /// - Parameter warnings: The warnings, in the order in which they were reported.
    /// - Returns: One line for each distinct warning, in order; no lines if there is no warning.
    public static func lines(for warnings: [SourceDiagnostic]) -> [String] {
        var lines: [String] = []
        var seen = Set<String>()
        for warning in warnings {
            let location = warning.range.map { "line \($0.start.line), column \($0.start.column): " } ?? ""
            let line = ConversionWarningReport.warningPrefix + location + warning.message
            if seen.insert(line).inserted { lines.append(line) }
        }
        return lines
    }

    /// Writes the warnings of a template run to standard error.
    ///
    /// - Parameter warnings: The warnings, in the order in which they were reported.
    public static func write(_ warnings: [SourceDiagnostic]) {
        let lines = lines(for: warnings)
        guard !lines.isEmpty else { return }
        FileHandle.standardError.write(Data((lines.joined(separator: "\n") + "\n").utf8))
    }
}
