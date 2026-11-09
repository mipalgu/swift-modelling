//
// EGLGenerateCommand.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import EGL
import EMFBase
import ModellingCommandLine
import ModellingGenerators

/// The command that renders an Epsilon Generation Language template, or runs the rules of an
/// EGX coordination module that write files.
struct EGLGenerateCommand: AsyncParsableCommand {
    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: SwiftEpsilonVocabulary.Command.generate,
        abstract: "Render an EGL template, or run EGX rules that write files",
        discussion: """
            A template is rendered once, with the parameters as variables, and its text is \
            written to standard output, or to the file that \
            --\(SwiftEpsilonVocabulary.OptionName.output) names. An existing file keeps the \
            contents of its enabled protected regions unless \
            --\(SwiftEpsilonVocabulary.OptionName.noMerge) is given, and a warning names each \
            region whose contents are lost.

            A file with the extension .\(SwiftEpsilonVocabulary.FileExtension.coordination) is \
            an EGX module, whose rules render their templates, which are read relative to the \
            module, and write the files that their targets name below the directory that \
            --\(SwiftEpsilonVocabulary.OptionName.output) names, or below the current \
            directory. A target that leads outside that directory is an error unless \
            --\(SwiftEpsilonVocabulary.OptionName.allowOutsideOutput) is given. Each file is \
            printed with what happened to it, as in:
              created: accounts/savings.txt
            where the status is created, updated, unchanged, skipped (the rule does not \
            overwrite an existing file) or not written (the rule has no target).

            \(SwiftEpsilonCommand.modelDiscussion)

            \(SwiftEpsilonCommand.parameterDiscussion)

            Examples:
              swift-epsilon egl generate accounts.egl --model Bank=bank.xmi \\
                  -m Bank.ecore --param title=Accounts
              swift-epsilon egl generate accounts.egl --model Bank=bank.xmi \\
                  -m Bank.ecore --param title=Accounts -o accounts.txt
              swift-epsilon egl generate accounts.egx --model Bank=bank.xmi \\
                  -m Bank.ecore --output generated

            \(SourceEncodingOptions.discussion(reader: "the template, the EGX module and the templates it names"))

            \(OutputEncodingOptions.discussion(writer: "the generated files and the stored models"))

            \(SwiftEpsilonCommand.exitDiscussion)
            """
    )

    /// The path of the template or EGX module.
    @Argument(help: ArgumentHelp("The EGL template or EGX module to run", valueName: SwiftEpsilonVocabulary.ValueName.template))
    var template: String

    /// The output file of a template, or the output directory of an EGX module.
    @Option(
        name: [.customShort("o"), .customLong(SwiftEpsilonVocabulary.OptionName.output)],
        help: ArgumentHelp(
            "The file that receives the text of a template (default: standard output), or the "
                + "directory below which EGX rules write their files (default: the current directory)",
            valueName: SwiftEpsilonVocabulary.ValueName.output))
    var output: String?

    /// Whether an existing output file of a template is replaced without keeping its protected regions.
    @Flag(
        name: .customLong(SwiftEpsilonVocabulary.OptionName.noMerge),
        help: "Replace an existing output file of a template without keeping its protected regions")
    var noMerge: Bool = false

    /// Whether EGX rules may write files outside the output directory.
    @Flag(
        name: .customLong(SwiftEpsilonVocabulary.OptionName.allowOutsideOutput),
        help: "Let EGX rules write files outside the output directory")
    var allowOutsideOutput: Bool = false

    /// The models that the template reads.
    @OptionGroup(title: "Models")
    var modelOptions: ModelOptions

    /// The options that control the run.
    @OptionGroup var executionOptions: ExecutionOptions

    /// Whether the command runs an EGX module rather than a template.
    var isCoordination: Bool { EGLRun.isCoordination(template) }

    /// Checks the models and parameters, and that the flags suit the kind of file.
    ///
    /// - Throws: A validation error if a binding or parameter is not valid, if
    ///   `--no-merge` is given for an EGX module, or `--allow-outside-output` for a template.
    func validate() throws {
        try CommandLineCheck.check(models: modelOptions, execution: executionOptions)
        if isCoordination && noMerge {
            throw ValidationError(
                "--\(SwiftEpsilonVocabulary.OptionName.noMerge) applies to a template; the rules of an EGX module choose with merge")
        }
        if !isCoordination && allowOutsideOutput {
            throw ValidationError("--\(SwiftEpsilonVocabulary.OptionName.allowOutsideOutput) applies to an EGX module")
        }
    }

    /// Renders the template or runs the EGX module, and stores the models that `--store` names.
    ///
    /// - Throws: The errors of loading the models, of reading, parsing and running the template
    ///   or module, of writing the files, and of storing the models.
    func run() async throws {
        let configuration = try RunConfiguration(models: modelOptions, execution: executionOptions)
        let workspace = try await ModelWorkspace.load(configuration)
        if isCoordination {
            try await generateFiles(workspace: workspace)
        } else {
            let text = try await EGLRun.render(template: template, workspace: workspace)
            if let output {
                let written = try EGLRun.write(
                    text, to: output, merging: !noMerge, encoding: workspace.configuration.outputEncoding)
                FileDiagnosticReport.write(written.diagnostics)
                Console.writeLines([SwiftEpsilonVocabulary.FileStatus.word(for: written.status) + SwiftEpsilonVocabulary.FileStatus.separator + output])
            } else {
                Console.write(text)
            }
        }
        try await workspace.store()
    }

    /// Runs the EGX module and prints what happened to each file.
    ///
    /// On an interactive terminal, a progress bar counts the files as they are written.
    ///
    /// - Parameter workspace: The models of the run.
    /// - Throws: The errors of reading, parsing and running the module and of writing the files.
    private func generateFiles(workspace: ModelWorkspace) async throws {
        let bar = GenerationProgressBar(verbose: false)
        let message = SwiftEpsilonVocabulary.Activity.generating + " " + template
        let showsProgress = !workspace.configuration.verbose
        let result: EGXResult
        do {
            result = try await EGLRun.generate(
                coordination: template, workspace: workspace,
                outputDirectory: output ?? SwiftEpsilonVocabulary.defaultOutputDirectory,
                allowsPathsOutsideOutput: allowOutsideOutput, encoding: workspace.configuration.outputEncoding,
                progress: { count in
                    if showsProgress { bar.show(GenerationProgressUpdate(message: message, completed: count)) }
                })
            bar.finish()
        } catch {
            bar.finish()
            throw error
        }
        FileDiagnosticReport.write(result.diagnostics)
        Console.writeLines(
            result.files.map { file in
                SwiftEpsilonVocabulary.FileStatus.word(for: file.status) + SwiftEpsilonVocabulary.FileStatus.separator
                    + (file.path ?? file.rule)
            })
    }
}
