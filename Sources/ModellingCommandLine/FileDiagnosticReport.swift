//
// FileDiagnosticReport.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation

/// Reports the warnings and errors of reading a file on standard error.
///
/// A diagnostic concerns a file as a whole, such as a metamodel package without a namespace
/// URI, or a place in it, such as the first byte of a source file that is not valid UTF-8 and
/// was therefore read as ISO-8859-1, or a syntax error in a KM3 metamodel. Each distinct
/// diagnostic is written once, as a line that starts with ``ConversionWarningReport/warningPrefix``
/// or ``errorPrefix`` and names the file, followed by the line and column of the place when
/// they are known:
///
/// ```
/// warning: Families.atl: line 3, column 12: The text is not valid UTF-8 and was read as ISO-8859-1
/// warning: Library.ecore: The package 'Types' has no 'nsURI' and is not registered under a namespace
/// error: Library.km3: line 4, column 9: Expected '{'
/// ```
///
/// Informational diagnostics are left out. Results and completion messages stay on standard
/// output, and the report does not change the exit status of a command.
public enum FileDiagnosticReport {
    /// The text that starts the line of an error.
    public static let errorPrefix = "error: "

    /// The text that separates the name of the file from the rest of a line.
    static let fileSeparator = ": "

    /// The lines that report the diagnostics of reading a file.
    ///
    /// - Parameters:
    ///   - diagnostics: The diagnostics, in the order in which they were reported.
    ///   - file: The file as the user named it, or `nil` to name the document of each
    ///     diagnostic: the path of a file URL, or the document as it is otherwise.
    /// - Returns: One line for each distinct warning or error, in order; no lines if there is none.
    public static func lines(for diagnostics: [SourceDiagnostic], file: String? = nil) -> [String] {
        var lines: [String] = []
        var seen = Set<String>()
        for diagnostic in diagnostics {
            guard let prefix = prefix(of: diagnostic.severity) else { continue }
            let name = (file ?? diagnostic.document.map(displayName)).map { $0 + fileSeparator } ?? ""
            let line = prefix + name + GenerationWarningReport.location(of: diagnostic) + diagnostic.message
            if seen.insert(line).inserted { lines.append(line) }
        }
        return lines
    }

    /// Writes the diagnostics of reading a file to standard error.
    ///
    /// - Parameters:
    ///   - diagnostics: The diagnostics, in the order in which they were reported.
    ///   - file: The file as the user named it, or `nil` to name the document of each diagnostic.
    public static func write(_ diagnostics: [SourceDiagnostic], file: String? = nil) {
        write(diagnostics, file: file, to: writeToStandardError)
    }

    /// Writes the diagnostics of reading a file through a writer.
    ///
    /// The writer receives the lines of ``lines(for:file:)`` as one text, each line ending in
    /// a newline. It is not called if there is no warning or error to report.
    ///
    /// - Parameters:
    ///   - diagnostics: The diagnostics, in the order in which they were reported.
    ///   - file: The file as the user named it, or `nil` to name the document of each diagnostic.
    ///   - output: The writer that receives the text of the report, such as
    ///     ``writeToStandardError(_:)``.
    public static func write(_ diagnostics: [SourceDiagnostic], file: String? = nil, to output: (String) -> Void) {
        let lines = lines(for: diagnostics, file: file)
        guard !lines.isEmpty else { return }
        output(lines.joined(separator: "\n") + "\n")
    }

    /// Writes text to standard error.
    ///
    /// This is the writer through which the diagnostics of reading a file are reported, unless
    /// a caller supplies another one. The text follows everything that the command printed
    /// on standard output before it, see ``StandardStreams/writeToStandardError(_:)``.
    ///
    /// - Parameter text: The text to write, unchanged.
    public static func writeToStandardError(_ text: String) {
        StandardStreams.writeToStandardError(text)
    }

    /// The text that starts the line of a diagnostic of a severity.
    ///
    /// - Parameter severity: The severity of the diagnostic.
    /// - Returns: The prefix of a warning or an error, or `nil` for information.
    private static func prefix(of severity: DiagnosticSeverity) -> String? {
        switch severity {
        case .error: return errorPrefix
        case .warning: return ConversionWarningReport.warningPrefix
        case .information: return nil
        }
    }

    /// The name under which a document is shown.
    ///
    /// - Parameter document: The URI or other identifier of the document.
    /// - Returns: The path of a file URL, or the identifier itself.
    private static func displayName(_ document: String) -> String {
        guard let url = URL(string: document), url.isFileURL else { return document }
        return url.path
    }
}
