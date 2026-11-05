//
// QueryCommand.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ModellingCommandLine

/// The command that evaluates an AQL query against a model given as an argument.
///
/// The command evaluates exactly as ``EvaluateCommand`` does; it suits scripts that query one
/// model, typically from a context object that `--context` selects.
struct QueryCommand: AsyncParsableCommand {
    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: SwiftAQLVocabulary.Command.query,
        abstract: "Evaluate an AQL query against a model",
        discussion: """
            The query is given as the argument after the model, with \
            --\(SwiftAQLVocabulary.OptionName.query), or read from the file that \
            --\(SwiftAQLVocabulary.OptionName.queryFile) names. \
            \(SwiftAQLCommand.bindingDiscussion)

            \(SwiftAQLCommand.metamodelDiscussion)

            \(SwiftAQLCommand.outputDiscussion)

            Examples:
              swift-aql query company.xmi "self.employees->size()"
              swift-aql query company.xmi --query "self.employees" --context company1
              swift-aql query company.xmi --query-file queries/all-employees.aql

            \(SemanticsOptions.discussion())
            """
    )

    /// The model against which the query is evaluated.
    @Argument(help: ArgumentHelp("The model to query", valueName: SwiftAQLVocabulary.ValueName.model))
    var model: String

    /// The query, as given as an argument.
    @Argument(help: ArgumentHelp("The AQL query to evaluate", valueName: SwiftAQLVocabulary.ValueName.expression))
    var queryArgument: String?

    /// The query, as given with the option.
    @Option(
        name: [.customShort("q"), .customLong(SwiftAQLVocabulary.OptionName.query)],
        help: ArgumentHelp("The AQL query to evaluate", valueName: SwiftAQLVocabulary.ValueName.expression))
    var query: String?

    /// The file that holds the query.
    @Option(
        name: [.customShort("f"), .customLong(SwiftAQLVocabulary.OptionName.queryFile)],
        help: ArgumentHelp(
            "A file that holds the AQL query to evaluate", valueName: SwiftAQLVocabulary.ValueName.expressionFile))
    var queryFile: String?

    /// The options that every command shares.
    @OptionGroup var evaluationOptions: EvaluationOptions

    /// The source of the query that the command line names.
    var source: ExpressionSource? { ExpressionSource.select(texts: [queryArgument, query], file: queryFile) }

    /// Checks that the command line names exactly one query.
    ///
    /// - Throws: A validation error if no query or more than one is given.
    func validate() throws {
        guard source != nil else {
            throw ArgumentParser.ValidationError(
                "Give the query as an argument, with --\(SwiftAQLVocabulary.OptionName.query) or with "
                    + "--\(SwiftAQLVocabulary.OptionName.queryFile), and only one of them")
        }
    }

    /// Evaluates the query and prints its value.
    ///
    /// - Throws: ``SwiftAQLError`` if the query cannot be evaluated.
    @MainActor
    func run() async throws {
        guard let source else { return }
        print(try await EvaluationRun(models: [model], source: source, options: evaluationOptions).output())
    }
}
