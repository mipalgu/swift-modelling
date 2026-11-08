//
// ETLTransformCommand.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ModellingCommandLine

/// The command that transforms source models into target models with an Epsilon
/// Transformation Language transformation.
struct ETLTransformCommand: AsyncParsableCommand {
    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: SwiftEpsilonVocabulary.Command.transform,
        abstract: "Transform source models into target models with ETL",
        discussion: """
            The source models are read with --\(SwiftEpsilonVocabulary.OptionName.model), and \
            each target model given with --\(SwiftEpsilonVocabulary.OptionName.target) starts \
            empty, is filled by the rules of the transformation and is written to its file, in \
            the format of its extension, once the transformation has succeeded. A rule names \
            the models of its types, as in transform a : Bank!Account to e : Ledger!Entry. With \
            --\(SwiftEpsilonVocabulary.OptionName.trace), every rule application is printed on \
            standard output, as in:
              Account2Entry: Account(savings) -> Entry

            \(SwiftEpsilonCommand.modelDiscussion)

            \(SwiftEpsilonCommand.parameterDiscussion)

            Examples:
              swift-epsilon etl transform bank2ledger.etl --model Bank=bank.xmi \\
                  --target Ledger=ledger.xmi -m Bank.ecore -m Ledger.ecore
              swift-epsilon etl transform bank2ledger.etl --model Bank=bank.xmi \\
                  --target Ledger=ledger.json -m Bank.ecore -m Ledger.ecore \\
                  --trace

            \(ReferenceStyleOptions.discussion(written: "target models"))

            \(SourceEncodingOptions.discussion(reader: "the transformation and the modules it imports"))

            \(SwiftEpsilonCommand.exitDiscussion)
            """
    )

    /// The path of the transformation.
    @Argument(help: ArgumentHelp("The ETL transformation to run", valueName: SwiftEpsilonVocabulary.ValueName.transformation))
    var transformation: String

    /// Whether the rule applications are printed.
    @Flag(
        name: .customLong(SwiftEpsilonVocabulary.OptionName.trace),
        help: "Print every rule application with its source and target elements")
    var trace: Bool = false

    /// The source models.
    @OptionGroup(title: "Models")
    var modelOptions: ModelOptions

    /// The target models.
    @OptionGroup(title: "Models")
    var targetOptions: TargetOptions

    /// The options that control the run.
    @OptionGroup var executionOptions: ExecutionOptions

    /// Checks the models and parameters.
    ///
    /// - Throws: A validation error if a binding or parameter is not valid.
    func validate() throws {
        try CommandLineCheck.check(models: modelOptions, execution: executionOptions, targets: targetOptions.targets)
    }

    /// Runs the transformation and stores the target models and the models that `--store` names.
    ///
    /// - Throws: The errors of loading the models, of reading, parsing and running the
    ///   transformation, and of storing the models.
    func run() async throws {
        let configuration = try RunConfiguration(
            models: modelOptions, execution: executionOptions, targets: targetOptions.targets)
        let workspace = try await ModelWorkspace.load(configuration)
        let activity = ActivityIndicator(
            SwiftEpsilonVocabulary.Activity.transforming + " " + transformation, verbose: configuration.verbose)
        activity.start()
        let entries: [TraceEntry]
        do {
            entries = try await ETLRun.transform(transformation: transformation, workspace: workspace)
            activity.finish()
        } catch {
            activity.finish()
            throw error
        }
        if trace { Console.writeLines(entries.map(\.line)) }
        try await workspace.store()
    }
}
