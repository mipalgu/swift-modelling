//
// DebugOptions.swift
// swift-mtl
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser

/// The command line option that turns on the traces of the parsers a command uses.
///
/// `--verbose` reports the progress of a command, such as the templates it parsed and the
/// models it loaded. The parsers can also trace their work token by token and element by
/// element; that trace is meant for diagnosing the parsers themselves, so it is printed to
/// standard output only when `--debug` is given. The two options are independent and can be
/// combined.
///
/// Commands include the option with `@OptionGroup`.
struct DebugOptions: ParsableArguments, Sendable {
    /// The long name of the option.
    static let optionName = "debug"

    /// Whether the parsers that the command uses print their traces to standard output.
    @Flag(
        name: .customLong(DebugOptions.optionName),
        help: "Print the traces of the parsers that the command uses")
    var debug: Bool = false

    /// Creates the option, with debugging turned off.
    init() {}
}
