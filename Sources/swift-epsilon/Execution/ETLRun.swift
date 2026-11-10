//
// ETLRun.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EOL
import ETL

/// One rule application of a transformation, as `--trace` prints it.
struct TraceEntry: Sendable, Equatable {
    /// The name of the rule.
    let rule: String

    /// The label of the source element, such as `Account(savings)`.
    let source: String

    /// The labels of the target elements.
    let targets: [String]

    /// The line that prints the entry, such as `Account2Entry: Account(savings) -> Entry`.
    var line: String {
        rule + SwiftEpsilonVocabulary.Trace.ruleSeparator + source + SwiftEpsilonVocabulary.Trace.arrow
            + targets.joined(separator: SwiftEpsilonVocabulary.Trace.targetSeparator)
    }
}

/// Runs an Epsilon Transformation Language transformation on the models of a workspace.
enum ETLRun {
    /// Reads, parses and runs a transformation.
    ///
    /// The transformation reads its source models and fills its target models; storing them is
    /// left to the caller.
    ///
    /// - Parameters:
    ///   - transformation: The path of the transformation.
    ///   - workspace: The models of the run.
    ///   - output: Where the transformation prints (standard output by default).
    ///   - errorOutput: Where the transformation prints errors (standard error by default).
    /// - Returns: The rule applications, in the order in which they happened.
    /// - Throws: The errors of reading and parsing the transformation, and the `EOLError` that
    ///   the transformation raises.
    static func transform(
        transformation: String, workspace: ModelWorkspace, output: any EOLOutputStream = EOLStandardOutput(),
        errorOutput: any EOLOutputStream = EOLStandardOutput(error: true)
    ) async throws -> [TraceEntry] {
        let module = try SourceReader(encoding: workspace.configuration.encoding).module(at: transformation) {
            ETLSyntax.parse($0, document: $1)
        }
        workspace.log("Transforming with \(transformation)")
        let interpreter = workspace.makeInterpreter(output: output, errorOutput: errorOutput)
        let transformer = ETLTransformer(module: module, interpreter: interpreter)
        try await transformer.transform()
        var entries: [TraceEntry] = []
        for link in transformer.trace.links {
            var targets: [String] = []
            for target in link.targets { targets.append(await interpreter.string(of: .element(target))) }
            entries.append(
                TraceEntry(rule: link.rule, source: await interpreter.string(of: .element(link.source)), targets: targets))
        }
        workspace.log("Applied \(entries.count) rule\(entries.count == 1 ? "" : SwiftEpsilonVocabulary.Validation.pluralSuffix)")
        return entries
    }
}
