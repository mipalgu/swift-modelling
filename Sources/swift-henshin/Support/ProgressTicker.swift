//
// ProgressTicker.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// Shows that a long operation is still running, with the time it has taken so far.
///
/// The operations of the tool, such as exploring a state space, do not report how far they
/// have come, so the ticker shows the phase and the elapsed time. On an interactive terminal
/// the line is redrawn in place on standard error every second and cleared when the
/// operation ends; with `--verbose`, a line is written to standard error when the phase
/// starts, every few seconds while it runs, and when it ends. Otherwise nothing is shown.
/// Standard output is never used.
struct ProgressTicker: Sendable {
    /// The number of seconds between two redraws on a terminal.
    static let interactiveInterval: Duration = .seconds(1)

    /// The number of seconds between two lines of verbose output.
    static let verboseInterval: Duration = .seconds(5)

    /// The text that returns to the start of the line and clears it.
    static let clearLine = "\r\u{1B}[K"

    /// Whether lines are written as the operation runs.
    let verbose: Bool

    /// Whether standard error is an interactive terminal.
    let interactive: Bool

    /// The writer of the text.
    let write: @Sendable (String) -> Void

    /// Creates a ticker for the current terminal.
    ///
    /// - Parameters:
    ///   - verbose: Whether lines are written as the operation runs.
    ///   - interactive: Whether standard error is an interactive terminal (default: detected).
    ///   - write: The writer of the text (default: standard error).
    init(
        verbose: Bool, interactive: Bool = ProgressTicker.standardErrorIsTerminal,
        write: @escaping @Sendable (String) -> Void = { FileHandle.standardError.write(Data($0.utf8)) }
    ) {
        self.verbose = verbose
        self.interactive = interactive
        self.write = write
    }

    /// Whether standard error is attached to a terminal.
    static var standardErrorIsTerminal: Bool {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl)
            return isatty(STDERR_FILENO) != 0
        #else
            return false
        #endif
    }

    /// The text that shows a phase and its elapsed time.
    ///
    /// - Parameters:
    ///   - phase: What is being done, such as `exploring the state space`.
    ///   - elapsed: The time taken so far.
    /// - Returns: A text such as `exploring the state space (12 s)`.
    static func text(_ phase: String, elapsed: Duration) -> String {
        "\(phase) (\(elapsed.components.seconds) s)"
    }

    /// Runs an operation while showing its progress.
    ///
    /// - Parameters:
    ///   - phase: What the operation does, such as `exploring the state space`.
    ///   - isolation: The actor on which the operation runs, that of the caller.
    ///   - operation: The operation.
    /// - Returns: The result of the operation.
    /// - Throws: The error of the operation.
    func run<Result: Sendable>(
        _ phase: String, isolation: isolated (any Actor)? = #isolation, _ operation: () async throws -> Result
    ) async throws -> Result {
        guard verbose || interactive else { return try await operation() }
        let clock = ContinuousClock()
        let start = clock.now
        let prefix = SwiftHenshinVocabulary.Display.verbosePrefix
        if verbose { write(prefix + phase + "\n") }
        let ticker = Task { [verbose, write] in
            let interval = verbose ? Self.verboseInterval : Self.interactiveInterval
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                guard !Task.isCancelled else { break }
                let text = Self.text(phase, elapsed: clock.now - start)
                write(verbose ? prefix + text + "\n" : Self.clearLine + text)
            }
        }
        defer {
            ticker.cancel()
            if !verbose { write(Self.clearLine) }
        }
        let result = try await operation()
        if verbose { write(prefix + "finished " + Self.text(phase, elapsed: clock.now - start) + "\n") }
        return result
    }
}
