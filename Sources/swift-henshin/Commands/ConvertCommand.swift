//
// ConvertCommand.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Foundation
import Henshin

/// The command that converts a module into Henshin Text.
///
/// A `.henshin` document or a `.henshin_text` document is read and written as a Henshin Text
/// document in canonical form. What Henshin Text cannot express, or what the writer has to
/// change to express it, is reported on standard error.
struct ConvertCommand: AsyncParsableCommand {
    /// Shorthand for the option names.
    private typealias Key = SwiftHenshinVocabulary.OptionName
    /// Shorthand for the value names.
    private typealias Placeholder = SwiftHenshinVocabulary.ValueName
    /// Shorthand for the file extensions.
    private typealias Extension = SwiftHenshinVocabulary.FileExtension

    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: SwiftHenshinVocabulary.Command.convert,
        abstract: "Convert a module into Henshin Text",
        discussion: """
            Reads a module from a .\(Extension.henshin) or a .\(Extension.henshinText) document \
            and writes it as a .\(Extension.henshinText) document in canonical form: reading \
            the document back gives a module with the same behaviour. The formats follow from \
            the extensions of the files. The output file is the second argument or the value \
            of --\(Key.output); without either, the document is printed on standard output. \
            An existing output file is replaced only with --\(Key.force).

            Writing .\(Extension.henshin) documents is not supported: modules are read from \
            both formats but written as Henshin Text only, so converting into a \
            .\(Extension.henshin) file is an error.

            What Henshin Text cannot express, such as positions of edges, and what the writer \
            changes to express a module, is reported on standard error as warning: lines.

            \(SwiftHenshinCommand.metamodelDiscussion)

            \(SwiftHenshinCommand.encodingDiscussion)

            Exit statuses: 0 on success, 1 if the module cannot be read, the output exists or \
            the conversion is not supported, and 64 for an invalid command line.

            Examples:
              swift-henshin convert depot.henshin depot.henshin_text
              swift-henshin convert depot.henshin_text --force -o depot.henshin_text
              swift-henshin convert depot.henshin
            """
    )

    /// The module file to read.
    @Argument(help: ArgumentHelp("The module to convert (.henshin or .henshin_text)", valueName: Placeholder.module))
    var input: String

    /// The file to write, as given as an argument.
    @Argument(help: ArgumentHelp("The Henshin Text file to write (or give it with --output)", valueName: Placeholder.output))
    var outputArgument: String?

    /// The file to write, as given with the option.
    @Option(
        name: [.customShort("o"), .customLong(Key.output)],
        help: ArgumentHelp("The Henshin Text file to write, instead of the second argument", valueName: Placeholder.output))
    var output: String?

    /// Whether an existing output file is replaced.
    @Flag(name: .customLong(Key.force), help: "Replace the output file if it exists")
    var force = false

    /// The options with which the module is read.
    @OptionGroup var moduleOptions: ModuleOptions

    /// The output file that the command line names, if any.
    var outputPath: String? { outputArgument ?? output }

    /// Checks that at most one output file is named.
    ///
    /// - Throws: A validation error if the output is given both as an argument and as an
    ///   option.
    func validate() throws {
        if outputArgument != nil && output != nil {
            throw ValidationError("Give the output file as the second argument or with --\(Key.output), not both")
        }
    }

    /// Converts the module.
    ///
    /// - Throws: ``SwiftHenshinError/unsupportedConversion(_:_:)`` if the output is not a
    ///   Henshin Text file, ``SwiftHenshinError/outputExists(_:)`` if it exists without
    ///   `--force`, and the errors of reading the module.
    @MainActor
    func run() async throws {
        if let outputPath {
            guard ModuleFormat(path: outputPath) == .text else {
                throw SwiftHenshinError.unsupportedConversion(input, outputPath)
            }
            if FileManager.default.fileExists(atPath: outputPath) && !force {
                throw SwiftHenshinError.outputExists(outputPath)
            }
        }
        let loader = moduleOptions.loader
        let loaded = try await loader.load(input)
        let writing = HenshinText.write(loaded.module, packages: loaded.packages)
        loader.log.report(writing.diagnostics, file: input)
        guard let outputPath else {
            print(writing.text, terminator: writing.text.hasSuffix("\n") ? "" : "\n")
            return
        }
        try writing.text.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
        loader.log.progress("wrote \(outputPath)")
    }
}
