//
// EVLRun.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EOL
import EVL

/// A constraint or critique that an element does not satisfy, as `evl validate` reports it.
struct ValidationFinding: Sendable, Equatable {
    /// Whether the finding is a critique, which is a warning, rather than a constraint, which is
    /// an error.
    let isCritique: Bool

    /// The name of the constraint or critique.
    let constraint: String

    /// The type name of the context that declares it.
    let context: String

    /// The label of the element, such as `Account(cheque)`.
    let element: String

    /// The message of the constraint, or a default one.
    let message: String

    /// The titles of the fixes that are offered, in declaration order.
    let fixes: [String]

    /// The lines that report the finding: one for the finding, followed by one for each fix.
    ///
    /// A finding is reported as, for example,
    /// `error: constraint NotOverdrawn on Account(cheque): Account cheque is overdrawn by 30`.
    var lines: [String] {
        let vocabulary = SwiftEpsilonVocabulary.Validation.self
        let prefix = isCritique ? vocabulary.warningPrefix : vocabulary.errorPrefix
        let kind = isCritique ? vocabulary.critique : vocabulary.constraint
        let line = prefix + kind + " " + constraint + vocabulary.elementSeparator + element + vocabulary.messageSeparator
            + message
        return [line] + fixes.map { vocabulary.fixPrefix + $0 }
    }
}

/// The outcome of validating models against an EVL module.
struct ValidationOutcome: Sendable, Equatable {
    /// The unsatisfied constraints and critiques, in the order in which they were found.
    var findings: [ValidationFinding] = []

    /// The titles of the fixes that were applied, in order.
    var applied: [String] = []

    /// The number of unsatisfied constraints, which are errors.
    var errorCount: Int { findings.filter { !$0.isCritique }.count }

    /// The number of unsatisfied critiques, which are warnings.
    var warningCount: Int { findings.filter(\.isCritique).count }

    /// Whether the outcome fails validation.
    ///
    /// - Parameter strict: Whether unsatisfied critiques fail validation as well.
    /// - Returns: `true` if a constraint is unsatisfied, or with `strict` a critique.
    func fails(strict: Bool) -> Bool { errorCount > 0 || (strict && warningCount > 0) }

    /// The lines that report the outcome: the fixes applied, the findings and a summary.
    var lines: [String] {
        let applied = self.applied.map { SwiftEpsilonVocabulary.Validation.appliedPrefix + $0 }
        guard !findings.isEmpty else { return applied + [SwiftEpsilonVocabulary.Validation.allSatisfied] }
        let vocabulary = SwiftEpsilonVocabulary.Validation.self
        let summary = Self.count(errorCount, vocabulary.errorNoun) + vocabulary.countSeparator
            + Self.count(warningCount, vocabulary.warningNoun)
        return applied + findings.flatMap(\.lines) + [summary]
    }

    /// A number followed by a noun in the singular or plural.
    ///
    /// - Parameters:
    ///   - number: The number.
    ///   - noun: The noun in the singular.
    /// - Returns: For example `1 error` or `2 warnings`.
    private static func count(_ number: Int, _ noun: String) -> String {
        "\(number) \(noun)\(number == 1 ? "" : SwiftEpsilonVocabulary.Validation.pluralSuffix)"
    }
}

/// Validates the models of a workspace against an Epsilon Validation Language module.
enum EVLRun {
    /// Reads and parses a module and checks its constraints and critiques.
    ///
    /// With `applyingFixes`, the first fix offered for each unsatisfied constraint or critique is
    /// applied, and the models are validated again, so that the outcome reports what remains.
    ///
    /// - Parameters:
    ///   - constraints: The path of the module.
    ///   - workspace: The models of the run.
    ///   - applyingFixes: Whether to apply the fixes that are offered (default `false`).
    ///   - output: Where the module prints (standard output by default).
    ///   - errorOutput: Where the module prints errors (standard error by default).
    /// - Returns: The outcome.
    /// - Throws: The errors of reading and parsing the module, and the `EOLError` that the module
    ///   or a fix raises.
    static func validate(
        constraints: String, workspace: ModelWorkspace, applyingFixes: Bool = false,
        output: any EOLOutputStream = EOLStandardOutput(), errorOutput: any EOLOutputStream = EOLStandardOutput(error: true)
    ) async throws -> ValidationOutcome {
        let module = try SourceReader(encoding: workspace.configuration.encoding).module(at: constraints) {
            EVLSyntax.parse($0, document: $1)
        }
        workspace.log("Validating with \(constraints)")
        let validator = EVLValidator(interpreter: workspace.makeInterpreter(output: output, errorOutput: errorOutput))
        var result = try await validator.validate(module)
        var outcome = ValidationOutcome()
        if applyingFixes {
            for unsatisfied in result.unsatisfied {
                guard let offer = unsatisfied.fixes.first else { continue }
                workspace.log("Applying fix: \(offer.title)")
                try await validator.apply(offer)
                outcome.applied.append(offer.title)
            }
            if !outcome.applied.isEmpty { result = try await validator.validate(module) }
        }
        for unsatisfied in result.unsatisfied {
            outcome.findings.append(
                ValidationFinding(
                    isCritique: unsatisfied.isCritique, constraint: unsatisfied.constraint, context: unsatisfied.context,
                    element: await validator.interpreter.string(of: unsatisfied.element), message: unsatisfied.message,
                    fixes: applyingFixes ? [] : unsatisfied.fixes.map(\.title)))
        }
        workspace.log("Found \(outcome.errorCount) unsatisfied constraints and \(outcome.warningCount) critiques")
        return outcome
    }
}
