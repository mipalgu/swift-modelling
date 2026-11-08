//
// Console.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import ModellingGenerators

/// Writes the results of the tool to standard output and its reports to standard error.
///
/// Programs write to standard output as they run, without buffering, so the tool writes its own
/// results in the same way, and they appear in the order in which they were produced.
enum Console {
    /// Writes text to standard output, unchanged.
    ///
    /// - Parameter text: The text.
    static func write(_ text: String) {
        FileHandle.standardOutput.write(Data(text.utf8))
    }

    /// Writes lines to standard output, each followed by a line break.
    ///
    /// - Parameter lines: The lines; nothing is written if there are none.
    static func writeLines(_ lines: [String]) {
        guard !lines.isEmpty else { return }
        write(lines.joined(separator: "\n") + "\n")
    }

    /// Writes a line to standard error.
    ///
    /// - Parameter line: The line, without its line break.
    static func report(_ line: String) {
        FileHandle.standardError.write(Data((line + "\n").utf8))
    }
}

/// Reports the steps of a run on standard error when `--verbose` is given.
struct VerboseLog: Sendable {
    /// Whether the steps are reported.
    let isEnabled: Bool

    /// Reports a step.
    ///
    /// - Parameter message: The description of the step, which is only built if it is reported.
    func callAsFunction(_ message: @autoclosure () -> String) {
        if isEnabled { Console.report(message()) }
    }
}

/// Shows on an interactive terminal that a run is in progress.
///
/// The indicator writes one line on standard error, which it removes again when the run
/// finishes, and only if standard error is a terminal and verbose output is off, so that
/// neither redirected output nor the verbose report is cluttered.
struct ActivityIndicator: Sendable {
    /// Whether the indicator writes anything.
    let isShown: Bool

    /// What the run is doing, such as `Validating rules.evl`.
    let message: String

    /// Creates an indicator.
    ///
    /// - Parameters:
    ///   - message: What the run is doing.
    ///   - verbose: Whether verbose output is on, which hides the indicator.
    init(_ message: String, verbose: Bool) {
        self.message = message
        isShown = !verbose && GenerationProgressBar.standardErrorIsTerminal
    }

    /// Shows the indicator.
    func start() {
        if isShown { FileHandle.standardError.write(Data(("\r\u{1B}[K" + message + SwiftEpsilonVocabulary.Activity.ellipsis).utf8)) }
    }

    /// Removes the indicator.
    func finish() {
        if isShown { FileHandle.standardError.write(Data("\r\u{1B}[K".utf8)) }
    }
}
