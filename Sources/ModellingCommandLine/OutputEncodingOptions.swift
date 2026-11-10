//
// OutputEncodingOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import EMFBase

/// The command line option that chooses the character encoding of the files that a command writes.
///
/// Files are written in UTF-8 by default. `--output-encoding` names another encoding, such as
/// `ISO-8859-1`, by its name or by an alias such as `latin1`, as for ``SourceEncodingOptions``.
/// An XML document, such as XMI or Ecore, names the encoding in its declaration and writes a
/// character that the encoding cannot hold as a numeric character reference. Plain text, such
/// as generated code or a textual notation, cannot hold such a character: the file is then not
/// written, and the error names the file, the line and the column. JSON is always written in
/// UTF-8, with a warning when another encoding is named (see ``OutputFile``). What a command
/// prints on standard output is not affected.
///
/// The configuration file may name the encoding too, under the key ``optionName``; an option
/// given on the command line overrides it. The preset of ``SemanticsOptions`` does not change
/// the encoding.
public struct OutputEncodingOptions: ParsableArguments, Sendable {
    /// The long name of the option, and the key of the configuration file.
    public static let optionName = "output-encoding"

    /// The encoding of written files when neither the command line nor the configuration names one.
    public static let defaultEncoding = TextEncoding.utf8

    /// The values of the option, separated as in the usage of a command.
    public static let valueList = SourceEncodingOptions.valueList

    /// The encoding given on the command line, if any.
    @Option(
        name: .customLong(OutputEncodingOptions.optionName),
        help: ArgumentHelp(
            "The character encoding of the files written (default: \(OutputEncodingOptions.defaultEncoding.name))",
            discussion: """
                XML documents name the encoding in their declaration and write a character that \
                the encoding cannot hold as a numeric character reference. In plain text, such a \
                character is an error. JSON is always written in \(TextEncoding.utf8.name).
                """,
            valueName: OutputEncodingOptions.valueList))
    public var explicitEncoding: TextEncoding?

    /// Creates the option with nothing given, which writes UTF-8 unless the configuration file
    /// names another encoding.
    public init() {}

    /// The encoding of the files written in a run.
    ///
    /// - Parameter settings: The settings of the run, whose configuration file is consulted.
    /// - Returns: The encoding given on the command line, else the `output-encoding` of the
    ///   configuration file, else UTF-8.
    public func encoding(settings: SemanticsSettings) -> TextEncoding {
        encoding(configuration: settings.configuration)
    }

    /// The encoding of the files written in a run, given its configuration.
    ///
    /// - Parameter configuration: The configuration file of the run, or an empty configuration
    ///   if the command reads none.
    /// - Returns: The encoding given on the command line, else the `output-encoding` of the
    ///   configuration, else UTF-8.
    public func encoding(configuration: ModellingConfiguration) -> TextEncoding {
        explicitEncoding ?? configuration.outputEncoding ?? Self.defaultEncoding
    }

    /// A paragraph that describes the option in the discussion of a command.
    ///
    /// - Parameters:
    ///   - writer: The files that the option applies to, such as `the converted model`.
    ///   - configurable: Whether the command reads the configuration file, whose
    ///     `output-encoding` key then names the encoding too (default: `true`).
    /// - Returns: The paragraph, naming the option, the default and the rules for XML, plain
    ///   text and JSON.
    public static func discussion(writer: String, configurable: Bool = true) -> String {
        let configuration = configurable
            ? " The \(optionName) key of the configuration file names the encoding as well, and the "
                + "option overrides it." : ""
        return "--\(optionName) names the character encoding of \(writer), such as "
            + "\(TextEncoding.isoLatin1.name) or \(TextEncoding.windows1252.name) (default: "
            + "\(defaultEncoding.name)). An XML document names the encoding in its declaration and "
            + "writes a character that the encoding cannot hold as a numeric character reference; in "
            + "plain text, such a character is an error that names the file, line and column, and the "
            + "file is not written. JSON is always written in \(TextEncoding.utf8.name). Standard "
            + "output is not affected." + configuration
    }
}
