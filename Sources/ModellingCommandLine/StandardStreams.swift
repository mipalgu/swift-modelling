//
// StandardStreams.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(ucrt)
    import ucrt
#elseif canImport(WASILibc)
    import WASILibc
#endif
import Foundation

/// Writes to standard error in step with what a command has printed on standard output.
///
/// Text printed on standard output is held in a buffer when standard output is not a
/// terminal, whereas text written on standard error is not. When both streams lead to the
/// same place, such as one pipe or one log file, a warning could therefore appear before
/// lines that the command printed earlier. Writing through ``writeToStandardError(_:)``
/// keeps the order in which the command wrote its lines, wherever the streams lead.
public enum StandardStreams {
    /// Writes text to standard error after everything printed so far.
    ///
    /// All buffered output streams, standard output among them, are written first, so the
    /// text follows every line that the command printed before it.
    ///
    /// - Parameter text: The text to write, unchanged.
    public static func writeToStandardError(_ text: String) {
        fflush(nil)
        FileHandle.standardError.write(Data(text.utf8))
    }
}
