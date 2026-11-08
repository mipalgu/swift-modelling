//
// GenerateCommand.swift
// swift-xtend
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Foundation
import ModellingCommandLine
import ModellingGenerators
import Xtend

/// The command that runs an Xtend generator over a model.
struct GenerateCommand: AsyncParsableCommand {
    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: SwiftXtendVocabulary.Command.generate,
        abstract: "Run an Xtend generator over a model",
        discussion: """
            Runs the generator over the first model and writes the files it generates below the \
            directory that --\(SwiftXtendVocabulary.OptionName.output) names. The generator is \
            the class that --\(SwiftXtendVocabulary.OptionName.className) names or else the first \
            class with a doGenerate or generate method that takes the model as a resource and a \
            file system access (IFileSystemAccess), optionally followed by a generator context, \
            which is passed as null.

            A generator can write to a named output configuration with \
            fsa.generateFile(path, "name", contents). Map each such name to a directory with \
            --\(SwiftXtendVocabulary.OptionName.outputConfiguration) name=directory; writing to \
            a name that is not mapped is an error. Files written without a name go to the \
            --\(SwiftXtendVocabulary.OptionName.output) directory. Missing directories are \
            created, and generated paths cannot leave their directory.

            Each file that is written is listed on standard output, unless \
            --\(SwiftXtendVocabulary.OptionName.quiet) is given. Progress is reported on \
            standard error.

            Examples:
              swift-xtend generate Catalogue.xtend --model library.xmi --metamodel Library.ecore --output out
              swift-xtend generate Catalogue.xtend --model library.xmi --output out --output-configuration docs=out/docs
              swift-xtend generate Catalogue.xtend --model library.xmi --class SwiftGenerator --output out

            \(SourceEncodingOptions.discussion(reader: "the Xtend source files"))

            \(SemanticsOptions.discussion())

            \(SwiftXtendCommand.statusDiscussion)
            """
    )

    /// The source, models, metamodels and class.
    @OptionGroup var programOptions: ProgramOptions

    /// The directory of the default output configuration.
    @Option(
        name: [.customShort("o"), .customLong(SwiftXtendVocabulary.OptionName.output)],
        help: ArgumentHelp(
            "The directory that receives the generated files", valueName: SwiftXtendVocabulary.ValueName.outputDirectory))
    var output: String

    /// The directories of the named output configurations, as `name=directory`.
    @Option(
        name: .customLong(SwiftXtendVocabulary.OptionName.outputConfiguration),
        help: ArgumentHelp(
            "Map a named output configuration to a directory (can be specified multiple times)",
            valueName: SwiftXtendVocabulary.ValueName.outputConfiguration))
    var outputConfigurations: [String] = []

    /// Whether the list of written files is suppressed.
    @Flag(
        name: [.customShort("q"), .customLong(SwiftXtendVocabulary.OptionName.quiet)],
        help: "Do not list the generated files")
    var quiet: Bool = false

    /// The parser of the `--output-configuration` values.
    static let configurationOption = KeyValueOption<String>(
        noun: SwiftXtendVocabulary.outputConfigurationNoun, keyPlaceholder: "name"
    ) { _, text in text }

    /// Checks that a model is given and the output configurations are well formed.
    ///
    /// - Throws: A validation error if no model is given or an output configuration is not
    ///   written as `name=directory`.
    func validate() throws {
        guard !programOptions.models.isEmpty else {
            throw ArgumentParser.ValidationError(
                "Give the model to generate from with --\(SwiftXtendVocabulary.OptionName.model)")
        }
        do {
            _ = try Self.configurationOption.values(from: outputConfigurations)
        } catch {
            throw ArgumentParser.ValidationError(String(describing: error))
        }
        if quiet && programOptions.verbose {
            throw ArgumentParser.ValidationError(
                "--\(SwiftXtendVocabulary.OptionName.quiet) cannot be combined with "
                    + "--\(SwiftXtendVocabulary.OptionName.verbose)")
        }
    }

    /// Runs the generator and lists the files it wrote.
    ///
    /// - Throws: ``SwiftXtendError`` if the program cannot be run or the generator fails.
    @MainActor
    func run() async throws {
        let bar = GenerationProgressBar(verbose: false)
        defer { bar.finish() }
        do {
            let session = try await XtendSession.open(programOptions)
            let selected = try session.selectClass(named: programOptions.className)
            let directories = try Self.configurationOption.values(from: outputConfigurations)
            let access = XtendDirectoryFileSystemAccess(
                outputDirectory: URL(fileURLWithPath: output),
                outputConfigurations: directories.mapValues { URL(fileURLWithPath: $0) })
            let verbose = programOptions.verbose
            let log = GeneratedFileLog { update in
                if verbose {
                    XtendSession.report(GenerationProgressBar.render(update))
                } else {
                    bar.show(update)
                }
            }
            let interpreter = try XtendInterpreter(program: session.program, resources: session.models)
            guard let model = session.models.first else { return }
            if programOptions.verbose { XtendSession.report("Running \(selected.qualifiedName)") }
            try await interpreter.generate(
                resource: model, fileSystem: LoggingFileSystemAccess(base: access, log: log),
                className: programOptions.className == nil ? nil : selected.qualifiedName)
            bar.finish()
            let printed = await interpreter.standardOutput
            if !printed.isEmpty { print(printed, terminator: printed.hasSuffix("\n") ? "" : "\n") }
            let files = await log.files
            if files.isEmpty { XtendSession.report("warning: the generator wrote no files") }
            if !quiet {
                for file in files { print(listing(of: file, directories: directories)) }
            }
        } catch {
            bar.finish()
            throw SwiftXtendError.execution(error)
        }
    }

    /// The line that lists a written file.
    ///
    /// - Parameters:
    ///   - file: The file.
    ///   - directories: The directories of the named output configurations.
    /// - Returns: The path of the file below its directory, preceded by the name of its
    ///   output configuration if it has one.
    func listing(of file: WrittenFile, directories: [String: String]) -> String {
        let isDefault = file.outputConfiguration == XtendLanguage.defaultOutputConfiguration
        let directory = isDefault ? output : (directories[file.outputConfiguration] ?? output)
        let base = directory.hasSuffix("/") ? String(directory.dropLast()) : directory
        let path = base + "/" + file.path
        return isDefault ? path : file.outputConfiguration + SwiftXtendVocabulary.Display.configurationSeparator + path
    }
}
