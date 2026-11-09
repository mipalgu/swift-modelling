//
// EVLValidateCommand.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ModellingCommandLine

/// The command that validates models against Epsilon Validation Language constraints.
struct EVLValidateCommand: AsyncParsableCommand {
    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: SwiftEpsilonVocabulary.Command.validate,
        abstract: "Validate models against EVL constraints and critiques",
        discussion: """
            Every constraint and critique of the module is checked for each element of its \
            context type, and each one that an element does not satisfy is printed on standard \
            output, followed by the fixes that are offered for it and a summary. An unsatisfied \
            constraint is an error and an unsatisfied critique a warning:
              error: constraint <name> on <element>: <message>
                fix: <title>
              warning: critique <name> on <element>: <message>

            With --\(SwiftEpsilonVocabulary.OptionName.fix), the first fix offered for each \
            unsatisfied constraint or critique is applied, the models are validated again and \
            what remains is printed; give --\(SwiftEpsilonVocabulary.OptionName.store) to keep \
            the repaired models.

            \(SwiftEpsilonCommand.modelDiscussion)

            \(SwiftEpsilonCommand.parameterDiscussion)

            Examples:
              swift-epsilon evl validate rules.evl --model Bank=bank.xmi \\
                  -m Bank.ecore
              swift-epsilon evl validate rules.evl --model Bank=bank.xmi \\
                  -m Bank.ecore --strict
              swift-epsilon evl validate rules.evl --model Bank=bank.xmi \\
                  -m Bank.ecore --fix --store Bank=repaired.xmi

            \(SourceEncodingOptions.discussion(reader: "the module and the modules it imports"))

            \(OutputEncodingOptions.discussion(writer: "the stored models"))

            \(SwiftEpsilonCommand.exitDiscussion) The command exits with status \
            \(SwiftEpsilonVocabulary.ExitStatus.unsatisfied) if a constraint is unsatisfied, or \
            with --\(SwiftEpsilonVocabulary.OptionName.strict) a critique, after it has printed \
            the results and stored the models.
            """
    )

    /// The path of the EVL module.
    @Argument(help: ArgumentHelp("The EVL module to check", valueName: SwiftEpsilonVocabulary.ValueName.constraints))
    var constraints: String

    /// Whether the fixes that are offered are applied.
    @Flag(
        name: .customLong(SwiftEpsilonVocabulary.OptionName.fix),
        help: "Apply the first fix offered for each unsatisfied constraint or critique, then validate again")
    var fix: Bool = false

    /// Whether unsatisfied critiques fail validation as well, as given on the command line, if
    /// at all.
    ///
    /// `--strict` turns it on and `--no-strict` off, whatever the configuration file says.
    @Flag(
        name: .customLong(SwiftEpsilonVocabulary.OptionName.strict), inversion: .prefixedNo,
        help: "Fail when a critique is unsatisfied as well as when a constraint is")
    var explicitStrict: Bool?

    /// Whether `--strict` was given on the command line.
    ///
    /// The strictness of a run also depends on the `strict` key of the configuration file.
    var strict: Bool { explicitStrict ?? false }

    /// The models to validate.
    @OptionGroup(title: "Models")
    var modelOptions: ModelOptions

    /// The options that control the run.
    @OptionGroup var executionOptions: ExecutionOptions

    /// Checks the models and parameters.
    ///
    /// - Throws: A validation error if a binding or parameter is not valid.
    func validate() throws {
        try CommandLineCheck.check(models: modelOptions, execution: executionOptions)
    }

    /// Validates the models, prints the results and stores the models that `--store` names.
    ///
    /// - Throws: The errors of loading the models, of reading, parsing and running the module,
    ///   and of storing the models, and `ExitCode` with status
    ///   ``SwiftEpsilonVocabulary/ExitStatus/unsatisfied`` if validation fails.
    func run() async throws {
        let configuration = try RunConfiguration(models: modelOptions, execution: executionOptions)
        let workspace = try await ModelWorkspace.load(configuration)
        let activity = ActivityIndicator(
            SwiftEpsilonVocabulary.Activity.validating + " " + constraints, verbose: configuration.verbose)
        activity.start()
        let outcome: ValidationOutcome
        do {
            outcome = try await EVLRun.validate(constraints: constraints, workspace: workspace, applyingFixes: fix)
            activity.finish()
        } catch {
            activity.finish()
            throw error
        }
        Console.writeLines(outcome.lines)
        try await workspace.store()
        let strict = explicitStrict ?? configuration.settings.configuration.strict ?? false
        if outcome.fails(strict: strict) { throw ExitCode(SwiftEpsilonVocabulary.ExitStatus.unsatisfied) }
    }
}
