//
// FindingFormatter.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase

/// Formats the findings of a validation, one line each.
///
/// A line starts with the severity, names the file and, where it is known, the line and
/// column, and ends with the code of the finding in brackets:
///
/// ```
/// error: depot.henshin_text: line 4, column 9: Unknown class 'Crate' [henshin-text.unknown-class]
/// warning: depot.henshin: Parameter 'x' of rule 'move' is never used [henshin.unused-parameter]
/// ```
enum FindingFormatter {
    /// The line of a finding.
    ///
    /// - Parameters:
    ///   - finding: The finding.
    ///   - file: The file as given on the command line.
    /// - Returns: The line.
    static func line(_ finding: SourceDiagnostic, file: String) -> String {
        let location = finding.range.map { "line \($0.start.line), column \($0.start.column): " } ?? ""
        return prefix(of: finding.severity) + file + ": " + location + finding.message + " [" + finding.code + "]"
    }

    /// The text that starts the line of a finding of a severity.
    ///
    /// - Parameter severity: The severity.
    /// - Returns: `error: `, `warning: ` or `note: `.
    static func prefix(of severity: DiagnosticSeverity) -> String {
        switch severity {
        case .error: return SwiftHenshinVocabulary.Display.errorPrefix
        case .warning: return SwiftHenshinVocabulary.Display.warningPrefix
        case .information: return SwiftHenshinVocabulary.Display.informationPrefix
        }
    }

    /// The line that summarises the findings of a file.
    ///
    /// - Parameters:
    ///   - findings: The findings.
    ///   - file: The file as given on the command line.
    /// - Returns: A line such as `depot.henshin: 0 error(s), 2 warning(s)`.
    static func summary(_ findings: [SourceDiagnostic], file: String) -> String {
        let errors = findings.filter { $0.severity == .error }.count
        let warnings = findings.filter { $0.severity == .warning }.count
        return "\(file): \(errors) error(s), \(warnings) warning(s)"
    }
}
