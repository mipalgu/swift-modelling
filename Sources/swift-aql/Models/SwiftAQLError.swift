//
// SwiftAQLError.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation

/// An error that stops swift-aql from evaluating an expression.
///
/// Each case describes the problem in terms of what was given on the command line, so that the
/// message the tool prints tells the reader what to change.
enum SwiftAQLError: Error, Equatable, CustomStringConvertible, LocalizedError {
    /// A model file does not exist.
    ///
    /// The associated value is the path as given on the command line.
    case modelNotFound(String)

    /// An expression file does not exist or cannot be read.
    ///
    /// The associated value is the path as given on the command line.
    case expressionFileNotFound(String)

    /// The expression is empty.
    case emptyExpression

    /// The expression is not valid AQL.
    ///
    /// The associated value lists the problems that the parser reported, one per line.
    case invalidExpression([String])

    /// The expression could not be evaluated.
    ///
    /// The associated value describes the problem that evaluation reported.
    case evaluationFailed(String)

    /// No object of the models has the identifier or name that `--context` gives.
    ///
    /// The associated value is the identifier or name as given on the command line.
    case contextNotFound(String)

    /// Several objects of the models have the name that `--context` gives.
    ///
    /// The associated values are the name and the number of objects that have it.
    case ambiguousContext(String, Int)

    /// Several metamodels beside a model declare the namespace that the model uses.
    ///
    /// The associated values are the namespace URI and the paths of the metamodel files.
    case ambiguousMetamodels(String, [String])

    /// A description of the error for the reader of the command line.
    var description: String {
        switch self {
        case .modelNotFound(let path):
            return "Model file not found: \(path)"
        case .expressionFileNotFound(let path):
            return "Expression file not found or not readable: \(path)"
        case .emptyExpression:
            return "The expression is empty"
        case .invalidExpression(let problems):
            return "Invalid AQL expression:\n" + problems.map { "  \($0)" }.joined(separator: "\n")
        case .evaluationFailed(let problem):
            return "Evaluation failed: \(problem)"
        case .contextNotFound(let key):
            return "No object has the identifier or name '\(key)'"
        case .ambiguousContext(let key, let count):
            return "\(count) objects have the name '\(key)'; select one by its identifier instead"
        case .ambiguousMetamodels(let uri, let paths):
            return "Several metamodels declare \(uri): \(paths.joined(separator: ", ")); "
                + "choose one with --metamodel"
        }
    }

    /// The localised description of the error, which is its ``description``.
    var errorDescription: String? { description }

    /// Describes a problem that the parser reported.
    ///
    /// - Parameter diagnostic: The problem.
    /// - Returns: The message, preceded by the line and column at which the problem starts if
    ///   the parser reported a position.
    static func describe(_ diagnostic: SourceDiagnostic) -> String {
        guard let start = diagnostic.range?.start else { return diagnostic.message }
        return "line \(start.line), column \(start.column): \(diagnostic.message)"
    }
}
