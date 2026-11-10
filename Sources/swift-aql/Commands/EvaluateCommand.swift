//
// EvaluateCommand.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ModellingCommandLine

/// The command that evaluates an AQL expression against the models given with `--model`.
struct EvaluateCommand: AsyncParsableCommand {
    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: SwiftAQLVocabulary.Command.evaluate,
        abstract: "Evaluate an AQL expression against models",
        discussion: """
            The expression is given with --\(SwiftAQLVocabulary.OptionName.expression) or read \
            from the file that --\(SwiftAQLVocabulary.OptionName.expressionFile) names. \
            \(SwiftAQLCommand.bindingDiscussion)

            \(SwiftAQLCommand.metamodelDiscussion)

            \(SwiftAQLCommand.outputDiscussion)

            Examples:
              swift-aql evaluate --model company.xmi --expression "company.departments.name"
              swift-aql evaluate --model company.xmi --expression-file report.aql
              swift-aql evaluate --expression "Sequence{1, 2, 3}->sum()"

            \(SourceEncodingOptions.discussion(reader: "an expression file"))

            \(SemanticsOptions.discussion())
            """
    )

    /// The models against which the expression is evaluated.
    @Option(
        name: .customLong(SwiftAQLVocabulary.OptionName.model),
        help: ArgumentHelp(
            "A model to evaluate the expression against (can be specified multiple times)",
            valueName: SwiftAQLVocabulary.ValueName.model))
    var models: [String] = []

    /// The expression, as given on the command line.
    @Option(
        name: [.customShort("e"), .customLong(SwiftAQLVocabulary.OptionName.expression)],
        help: ArgumentHelp("The AQL expression to evaluate", valueName: SwiftAQLVocabulary.ValueName.expression))
    var expression: String?

    /// The file that holds the expression.
    @Option(
        name: [.customShort("f"), .customLong(SwiftAQLVocabulary.OptionName.expressionFile)],
        help: ArgumentHelp(
            "A file that holds the AQL expression to evaluate", valueName: SwiftAQLVocabulary.ValueName.expressionFile))
    var expressionFile: String?

    /// The options that every command shares.
    @OptionGroup var evaluationOptions: EvaluationOptions

    /// The source of the expression that the command line names.
    var source: ExpressionSource? { ExpressionSource.select(texts: [expression], file: expressionFile) }

    /// Checks that the command line names exactly one expression.
    ///
    /// - Throws: A validation error if neither or both of the expression options are given.
    func validate() throws {
        guard source != nil else {
            throw ArgumentParser.ValidationError(
                "Give either --\(SwiftAQLVocabulary.OptionName.expression) or "
                    + "--\(SwiftAQLVocabulary.OptionName.expressionFile), but not both")
        }
    }

    /// Evaluates the expression and prints its value.
    ///
    /// - Throws: ``SwiftAQLError`` if the expression cannot be evaluated.
    @MainActor
    func run() async throws {
        guard let source else { return }
        print(try await EvaluationRun(models: models, source: source, options: evaluationOptions).output())
    }
}
