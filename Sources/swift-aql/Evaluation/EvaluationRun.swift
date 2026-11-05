//
// EvaluationRun.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import EMFBase
import Foundation
import ModellingCommandLine

/// One evaluation of an expression against models, as a command of swift-aql performs it.
///
/// The run resolves the settings of the semantics options, loads the models with their
/// metamodels, selects the context object, evaluates the expression and returns its text.
struct EvaluationRun: Sendable {
    /// The paths of the models, as given on the command line.
    let models: [String]

    /// Where the expression comes from.
    let source: ExpressionSource

    /// The options that every command shares.
    let options: EvaluationOptions

    /// Creates a run.
    ///
    /// - Parameters:
    ///   - models: The paths of the models, as given on the command line.
    ///   - source: Where the expression comes from.
    ///   - options: The options that every command shares.
    init(models: [String], source: ExpressionSource, options: EvaluationOptions) {
        self.models = models
        self.source = source
        self.options = options
    }

    /// Evaluates the expression.
    ///
    /// - Parameters:
    ///   - environment: The environment variables from which the preset may come.
    ///   - currentDirectory: The directory from which the configuration file is found.
    /// - Returns: The value of the expression, or `nil` for null.
    /// - Throws: ``SwiftAQLError`` if the expression cannot be read, parsed or evaluated, or
    ///   its context object cannot be found, and the errors of the settings and of loading.
    @MainActor
    func value(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        currentDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    ) async throws -> (any EcoreValue)? {
        let text = try source.text()
        let settings = try options.semanticsOptions.settings(
            environment: environment, currentDirectory: currentDirectory)
        let loaded = try await ModelLoader(metamodels: options.metamodelOptions.metamodels, settings: settings)
            .load(models)
        let evaluator = await ExpressionEvaluator(
            models: loaded, options: options.aqlSemanticsOptions.aqlOptions(settings: settings),
            unsetFeatureReads: options.unsetFeatureOptions.unsetFeatures(settings: settings))
        guard let key = options.context else { return try await evaluator.evaluate(text) }
        return try await evaluator.evaluate(text, self: try await evaluator.contextObject(for: key))
    }

    /// Evaluates the expression and returns the text that the command prints.
    ///
    /// - Returns: The value of the expression, formatted by ``ResultFormatter``.
    /// - Throws: The errors of ``value(environment:currentDirectory:)``.
    @MainActor
    func output() async throws -> String {
        ResultFormatter().format(try await value())
    }
}
