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
    /// The warnings of the evaluation, such as a call written with a dot on a collection whose
    /// elements lack the service that the collection has, are passed to `report` once the
    /// expression has been evaluated, and also when its evaluation fails. They do not make the
    /// evaluation fail.
    ///
    /// - Parameters:
    ///   - environment: The environment variables from which the preset may come.
    ///   - currentDirectory: The directory from which the configuration file is found.
    ///   - report: What receives the warnings of the evaluation, if there are any; by default
    ///     ``GenerationWarningReport/write(_:)``, which writes them to standard error.
    /// - Returns: The value of the expression, or `nil` for null.
    /// - Throws: ``SwiftAQLError`` if the expression cannot be read, parsed or evaluated, or
    ///   its context object cannot be found, and the errors of the settings and of loading.
    @MainActor
    func value(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        currentDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true),
        reportingWarningsTo report: @MainActor ([SourceDiagnostic]) -> Void = GenerationWarningReport.write
    ) async throws -> (any EcoreValue)? {
        let settings = try options.semanticsOptions.settings(
            environment: environment, currentDirectory: currentDirectory)
        let text = try source.text(encoding: options.encodingOptions.encoding(settings: settings))
        var loader = ModelLoader(
            metamodels: options.metamodelOptions.metamodels, settings: settings,
            metamodelOptions: options.formatOptions.ecoreLoadOptions(
                settings: settings, encodingOptions: options.encodingOptions))
        loader.deepViewLevel = options.deepViewOptions.level
        let loaded = try await loader.load(models)
        let evaluator = await ExpressionEvaluator(
            models: loaded, options: options.aqlSemanticsOptions.aqlOptions(settings: settings),
            unsetFeatureReads: options.unsetFeatureOptions.unsetFeatures(settings: settings))
        defer {
            let warnings = evaluator.warnings
            if !warnings.isEmpty { report(warnings) }
        }
        guard let key = options.context else { return try await evaluator.evaluate(text) }
        return try await evaluator.evaluate(text, self: try await evaluator.contextObject(for: key))
    }

    /// Evaluates the expression and returns the text that the command prints.
    ///
    /// The warnings of the evaluation are written to standard error.
    ///
    /// - Returns: The value of the expression, formatted by ``ResultFormatter``.
    /// - Throws: The errors of ``value(environment:currentDirectory:)``.
    @MainActor
    func output() async throws -> String {
        ResultFormatter().format(try await value())
    }
}
