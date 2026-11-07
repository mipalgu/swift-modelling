//
// SourceEncodingOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import EMFBase

/// Parses a command-line value into a character encoding.
///
/// The value may be the preferred IANA name of the encoding, such as `ISO-8859-1`, or one of
/// its aliases, such as `latin1`, in any case (see `TextEncoding.init(name:)`).
extension TextEncoding: @retroactive ExpressibleByArgument {
    /// Creates the encoding that a command-line value names.
    ///
    /// - Parameter argument: The name or an alias of the encoding.
    /// - Returns: The encoding, or `nil` if the value names no supported encoding.
    public init?(argument: String) {
        self.init(name: argument)
    }
}

/// The command line option that chooses the character encoding of source files.
///
/// Source files, such as ATL transformations, MTL templates and AQL expression files, are read
/// as UTF-8 by default. A file that is not valid UTF-8 is read as ISO-8859-1 instead, which
/// accepts every byte, and a warning on standard error names the file and the first byte that
/// is not UTF-8. `--encoding` names the encoding of the files instead; they are then read in
/// that encoding alone, without a warning, and a file that is not valid in it is an error.
///
/// The configuration file may name the encoding too, under the key ``optionName``; an option
/// given on the command line overrides it. The preset of ``SemanticsOptions`` does not change
/// the encoding.
///
/// Commands include the option with `@OptionGroup` and read their source files with
/// ``SourceFile/text(at:encoding:)`` in the ``encoding(settings:)`` that applies to the run.
public struct SourceEncodingOptions: ParsableArguments, Sendable {
    /// The long name of the option, and the key of the configuration file.
    public static let optionName = "encoding"

    /// The values of the option, separated as in the usage of a command.
    public static let valueList = TextEncoding.allCases.map(\.name).joined(separator: "|")

    /// The encoding given on the command line, if any.
    @Option(
        name: .customLong(SourceEncodingOptions.optionName),
        help: ArgumentHelp(
            "The character encoding of the source files (default: \(TextEncoding.utf8.name), or "
                + "\(TextEncoding.isoLatin1.name) with a warning for a file that is not valid "
                + "\(TextEncoding.utf8.name))",
            discussion: """
                Without this option, a source file is read as \(TextEncoding.utf8.name), and a file \
                that is not valid \(TextEncoding.utf8.name) is read as \(TextEncoding.isoLatin1.name) \
                with a warning on standard error. With it, every source file is read in the encoding \
                named, which may also be given by an alias such as latin1, and a file that is not \
                valid in that encoding is an error.
                """,
            valueName: SourceEncodingOptions.valueList))
    public var explicitEncoding: TextEncoding?

    /// Creates the option with nothing given, which detects the encoding unless the
    /// configuration file names one.
    public init() {}

    /// The encoding that applies to a run.
    ///
    /// The encoding does not depend on the preset: it is the encoding given on the command
    /// line, else the `encoding` of the configuration file, else `nil`, which reads UTF-8 and
    /// falls back to ISO-8859-1.
    ///
    /// - Parameter settings: The settings of the run, whose configuration file is consulted.
    /// - Returns: The encoding in which source files are read, or `nil` to detect it.
    public func encoding(settings: SemanticsSettings) -> TextEncoding? {
        explicitEncoding ?? settings.configuration.encoding
    }

    /// A paragraph that describes the option in the discussion of a command.
    ///
    /// - Parameters:
    ///   - reader: The source files that the option applies to, such as `the transformation`.
    ///   - configurable: Whether the command reads the configuration file, whose `encoding`
    ///     key then names the encoding too (default: `true`).
    /// - Returns: The paragraph, naming the option, the default and the fallback.
    public static func discussion(reader: String, configurable: Bool = true) -> String {
        let configuration = configurable
            ? " The \(optionName) key of the configuration file names the encoding as well, and the "
                + "option overrides it." : ""
        return "--\(optionName) names the character encoding of \(reader), such as "
            + "\(TextEncoding.isoLatin1.name) or \(TextEncoding.windows1252.name). Without it, a "
            + "source file is read as \(TextEncoding.utf8.name), and a file that is not valid "
            + "\(TextEncoding.utf8.name) is read as \(TextEncoding.isoLatin1.name) with a warning on "
            + "standard error." + configuration
    }
}
