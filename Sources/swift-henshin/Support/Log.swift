//
// Log.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation
import ModellingCommandLine

/// Writes the messages of the tool that are not results to standard error.
///
/// Results go to standard output; progress, warnings, traces and errors go to standard
/// error, so that the output of a command can be redirected without them.
struct Log: Sendable {
    /// Whether progress and details are reported.
    let verbose: Bool

    /// The writer that receives each line, followed by a newline.
    let write: @Sendable (String) -> Void

    /// Creates a log.
    ///
    /// - Parameters:
    ///   - verbose: Whether progress and details are reported.
    ///   - write: The writer of the text (default: standard error).
    init(verbose: Bool, write: @escaping @Sendable (String) -> Void = FileDiagnosticReport.writeToStandardError) {
        self.verbose = verbose
        self.write = write
    }

    /// Writes a line.
    ///
    /// - Parameter line: The line, without a trailing newline.
    func line(_ line: String) {
        write(line + "\n")
    }

    /// Writes a line of progress if the log is verbose.
    ///
    /// - Parameter message: The message, which is prefixed with
    ///   ``SwiftHenshinVocabulary/Display/verbosePrefix``.
    func progress(_ message: @autoclosure () -> String) {
        guard verbose else { return }
        line(SwiftHenshinVocabulary.Display.verbosePrefix + message())
    }

    /// Writes a warning.
    ///
    /// - Parameter message: The message, which is prefixed with
    ///   ``SwiftHenshinVocabulary/Display/warningPrefix``.
    func warning(_ message: String) {
        line(SwiftHenshinVocabulary.Display.warningPrefix + message)
    }

    /// Writes an error that does not stop the command by itself.
    ///
    /// - Parameter message: The message, which is prefixed with
    ///   ``SwiftHenshinVocabulary/Display/errorPrefix``.
    func error(_ message: String) {
        line(SwiftHenshinVocabulary.Display.errorPrefix + message)
    }

    /// Writes the warnings and errors among diagnostics, naming the file they concern.
    ///
    /// - Parameters:
    ///   - diagnostics: The diagnostics.
    ///   - file: The file as given on the command line.
    func report(_ diagnostics: [SourceDiagnostic], file: String) {
        FileDiagnosticReport.write(diagnostics, file: file, to: write)
    }
}
