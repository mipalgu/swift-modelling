//
// ConversionWarningReport.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation

/// Reports the warnings of reading and writing a model on standard error.
///
/// Each warning is written once, as a line that starts with ``warningPrefix``. When a model was
/// converted without a metamodel and any warning was produced, a line that starts with
/// ``hintPrefix`` follows, suggesting the metamodel option, with which the classes and
/// references of the model are read and written faithfully. Results and completion messages
/// stay on standard output.
public enum ConversionWarningReport {
    /// The text that starts the line of a warning.
    public static let warningPrefix = "warning: "

    /// The text that starts the line of the hint.
    public static let hintPrefix = "hint: "

    /// The hint that follows the warnings of a conversion without a metamodel.
    public static let metamodelHint = hintPrefix
        + "give the metamodel of the model with --\(MetamodelOptions.optionName) "
        + "<\(MetamodelOptions.valueName)> to keep its classes and references"

    /// The lines that report the warnings of a conversion.
    ///
    /// - Parameters:
    ///   - diagnostics: The warnings of reading and writing the model.
    ///   - metamodelGiven: Whether a metamodel of the model was given on the command line.
    /// - Returns: One line for each distinct warning, followed by ``metamodelHint`` if there is any
    ///   warning and no metamodel was given; no lines if there is no warning.
    public static func lines(for diagnostics: ConversionDiagnostics, metamodelGiven: Bool) -> [String] {
        var lines: [String] = []
        var seen = Set<String>()
        for warning in diagnostics.warnings {
            let line = warningPrefix + warning.message
            if seen.insert(line).inserted { lines.append(line) }
        }
        if !lines.isEmpty && !metamodelGiven { lines.append(metamodelHint) }
        return lines
    }

    /// Writes the warnings of a conversion to standard error.
    ///
    /// - Parameters:
    ///   - diagnostics: The warnings of reading and writing the model.
    ///   - metamodelGiven: Whether a metamodel of the model was given on the command line.
    public static func write(_ diagnostics: ConversionDiagnostics, metamodelGiven: Bool) {
        let lines = lines(for: diagnostics, metamodelGiven: metamodelGiven)
        guard !lines.isEmpty else { return }
        FileHandle.standardError.write(Data((lines.joined(separator: "\n") + "\n").utf8))
    }
}
