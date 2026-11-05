//
// StandardOutput.swift
// swift-ecore
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
#endif

/// Controls when printed text reaches standard output.
enum StandardOutput {
    /// Writes everything printed so far to standard output.
    ///
    /// A command calls this before it fails, so that its report precedes the error message on
    /// standard error even when standard output is not a terminal.
    static func flush() {
        fflush(stdout)
    }
}
