//
// ATLSourceReading.swift
// swift-atl
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ModellingCommandLine

/// A command that reads ATL source files in the encoding that its options choose.
///
/// The encoding is the one given with `--encoding`, else the `encoding` of the configuration
/// file, else UTF-8 with a fallback to ISO-8859-1 that is reported on standard error (see
/// ``ModellingCommandLine/SourceEncodingOptions``).
protocol ATLSourceReading {
    /// The preset of the behaviours and the configuration file.
    var semanticsOptions: SemanticsOptions { get }

    /// The encoding of the source files.
    var encodingOptions: SourceEncodingOptions { get }
}

extension ATLSourceReading {
    /// Reads the text of an ATL source file.
    ///
    /// - Parameter path: The path of the file, as given on the command line.
    /// - Returns: The text of the file.
    /// - Throws: The errors of the settings and of ``ModellingCommandLine/SourceFile/text(at:encoding:)``.
    func readATLSource(at path: String) throws -> String {
        try SourceFile.text(at: path, encoding: encodingOptions.encoding(settings: try semanticsOptions.settings()))
    }
}
