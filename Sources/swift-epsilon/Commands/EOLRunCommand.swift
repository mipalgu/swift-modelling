//
// EOLRunCommand.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ModellingCommandLine

/// The command that runs an Epsilon Object Language program against models.
struct EOLRunCommand: AsyncParsableCommand {
    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: SwiftEpsilonVocabulary.Command.run,
        abstract: "Run an EOL program",
        discussion: """
            The program runs against the models given with \
            --\(SwiftEpsilonVocabulary.OptionName.model) and \
            --\(SwiftEpsilonVocabulary.OptionName.target), and what it prints with print and \
            println is written to standard output, what it prints with err and errln to \
            standard error. A target model starts empty, so that the program can create \
            elements in it, and is stored once the program has run.

            \(SwiftEpsilonCommand.modelDiscussion)

            \(SwiftEpsilonCommand.parameterDiscussion)

            Examples:
              swift-epsilon eol run report.eol --model Bank=bank.xmi -m Bank.ecore
              swift-epsilon eol run deposit.eol --model Bank=bank.xmi \\
                  -m Bank.ecore --store Bank
              swift-epsilon eol run summary.eol --model Bank=bank.xmi \\
                  --target Ledger=ledger.xmi -m Bank.ecore -m Ledger.ecore
              swift-epsilon eol run greeting.eol --param reader=Alice

            \(SourceEncodingOptions.discussion(reader: "the program and the modules it imports"))

            \(OutputEncodingOptions.discussion(writer: "the stored models"))

            \(SwiftEpsilonCommand.exitDiscussion)
            """
    )

    /// The path of the program.
    @Argument(help: ArgumentHelp("The EOL program to run", valueName: SwiftEpsilonVocabulary.ValueName.program))
    var program: String

    /// The models that the program reads and stores.
    @OptionGroup(title: "Models")
    var modelOptions: ModelOptions

    /// The models that the program creates.
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

    /// Runs the program and stores the target models and the models that `--store` names.
    ///
    /// - Throws: The errors of loading the models, of reading, parsing and running the program,
    ///   and of storing the models.
    func run() async throws {
        let configuration = try RunConfiguration(
            models: modelOptions, execution: executionOptions, targets: targetOptions.targets)
        let workspace = try await ModelWorkspace.load(configuration)
        try await EOLRun.run(program: program, workspace: workspace)
        try await workspace.store()
    }
}
