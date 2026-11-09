//
// ATLOutputWriting.swift
// swift-atl
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import ModellingCommandLine

/// A command that writes files in the encoding that its options choose.
///
/// The encoding is the one given with `--output-encoding`, else the `output-encoding` of the
/// configuration file, else UTF-8 (see ``ModellingCommandLine/OutputEncodingOptions``).
protocol ATLOutputWriting {
    /// The preset of the behaviours and the configuration file.
    var semanticsOptions: SemanticsOptions { get }

    /// The encoding of the files written.
    var outputEncodingOptions: OutputEncodingOptions { get }
}

extension ATLOutputWriting {
    /// The encoding of the files that the command writes.
    ///
    /// - Returns: The encoding given on the command line, else the one of the configuration
    ///   file, else UTF-8.
    /// - Throws: An error that names the configuration file or the environment variable if
    ///   either is not valid.
    func outputEncoding() throws -> TextEncoding {
        outputEncodingOptions.encoding(settings: try semanticsOptions.settings())
    }

    /// Writes the text of a file in the encoding of the command.
    ///
    /// - Parameters:
    ///   - text: The text of the file.
    ///   - path: The path of the file, as given on the command line.
    ///   - kind: The kind of document that the text is.
    /// - Throws: ``ModellingCommandLine/OutputFileError/unrepresentable(path:_:)`` if the
    ///   encoding cannot hold a character of plain text, and the errors of the settings and
    ///   of the file system.
    func writeOutput(_ text: String, to path: String, kind: TextDocumentKind) throws {
        try OutputFile.write(text, to: path, encoding: try outputEncoding(), kind: kind)
    }
}
