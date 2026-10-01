//
// GenerationProgressBar.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// Shows the progress of code generation as a text progress bar.
///
/// When the number of files is known the bar fills as files are written; otherwise only the number of
/// finished files is shown. On an interactive terminal the bar is redrawn in place on standard error;
/// in verbose mode every report is printed as a line on standard output.
public struct GenerationProgressBar: Sendable {
    /// The number of characters between the brackets of the bar.
    public static let width = 24

    /// The character that fills the finished part of the bar.
    public static let fill: Character = "="

    /// The character that fills the unfinished part of the bar.
    public static let blank: Character = " "

    /// Whether every report is printed on its own line.
    public let verbose: Bool

    /// Whether standard error is an interactive terminal.
    public let interactive: Bool

    /// Creates a progress bar for the current terminal.
    ///
    /// - Parameter verbose: Whether every report is printed on its own line.
    public init(verbose: Bool) {
        self.verbose = verbose
        self.interactive = Self.standardErrorIsTerminal
    }

    /// Whether standard error is attached to a terminal.
    public static var standardErrorIsTerminal: Bool {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl)
            return isatty(STDERR_FILENO) != 0
        #else
            return false
        #endif
    }

    /// The text of a bar for a progress report.
    ///
    /// - Parameter update: The report to show.
    /// - Returns: A bar with the counts and the message, or the count and message alone if the
    ///   total is unknown.
    public static func render(_ update: GenerationProgressUpdate) -> String {
        guard let total = update.total, let fraction = update.fraction else {
            return "\(update.message) (\(update.completed) files)"
        }
        let filled = Int((Double(width) * fraction).rounded(.down))
        let bar = String(repeating: fill, count: filled) + String(repeating: blank, count: width - filled)
        return "[\(bar)] \(update.completed)/\(total) \(update.message)"
    }

    /// Shows a progress report.
    ///
    /// - Parameter update: The report to show.
    public func show(_ update: GenerationProgressUpdate) {
        let text = Self.render(update)
        if verbose {
            print(text)
        } else if interactive {
            FileHandle.standardError.write(Data(("\r\u{1B}[K" + text).utf8))
        }
    }

    /// Ends an in-place bar so that later output starts on a fresh line.
    public func finish() {
        if !verbose && interactive { FileHandle.standardError.write(Data("\r\u{1B}[K".utf8)) }
    }

    /// A progress reporter that shows every report with this bar.
    ///
    /// Pass the reporter to ``GenerationPipeline`` functions that take a
    /// ``GenerationProgressReporter``.
    public var reporter: GenerationProgressReporter {
        { update in self.show(update) }
    }
}
