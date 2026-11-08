//
// EOLRun.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EOL

/// Runs an Epsilon Object Language program against the models of a workspace.
enum EOLRun {
    /// Reads, parses and runs a program.
    ///
    /// What the program prints with `print` and `println` goes to `output`, and what it prints
    /// with `err` and `errln` to `errorOutput`.
    ///
    /// - Parameters:
    ///   - program: The path of the program.
    ///   - workspace: The models of the run.
    ///   - output: Where the program prints (standard output by default).
    ///   - errorOutput: Where the program prints errors (standard error by default).
    /// - Returns: The value of a top-level `return`, or undefined.
    /// - Throws: The errors of reading and parsing the program, and the `EOLError` that the
    ///   program raises.
    @discardableResult
    static func run(
        program: String, workspace: ModelWorkspace, output: any EOLOutputStream = EOLStandardOutput(),
        errorOutput: any EOLOutputStream = EOLStandardOutput(error: true)
    ) async throws -> EOLValue {
        let module = try SourceReader(encoding: workspace.configuration.encoding).module(at: program) {
            EOLSyntax.parse($0, document: $1)
        }
        workspace.log("Running \(program)")
        return try await workspace.makeInterpreter(output: output, errorOutput: errorOutput).run(module)
    }
}
