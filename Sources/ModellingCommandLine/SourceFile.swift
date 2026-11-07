//
// SourceFile.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation

/// Reads the source files that commands parse, such as ATL transformations and AQL expressions.
///
/// A file is read as UTF-8 unless an encoding is given. A file that is not valid UTF-8 is read
/// as ISO-8859-1 instead, so that sources written with older tools still load; the substitution
/// is reported as a warning. Text that is valid UTF-8 is read exactly as before.
public enum SourceFile {
    /// Reads and decodes a source file.
    ///
    /// - Parameters:
    ///   - path: The path of the file, as given on the command line.
    ///   - encoding: The encoding of the file, or `nil` (the default) to read UTF-8 and fall
    ///     back to ISO-8859-1.
    /// - Returns: The text with the encoding in which it was read and, if it was read as
    ///   ISO-8859-1 instead of UTF-8, a warning.
    /// - Throws: The error of the file system if the file cannot be read, or
    ///   ``SourceFileError/malformed(path:encoding:)`` if it is not valid in an explicit encoding.
    public static func read(_ path: String, encoding: TextEncoding? = nil) throws -> DecodedText {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        do {
            return try DecodedText(decoding: data, encoding: encoding, document: url.absoluteString)
        } catch {
            throw SourceFileError.malformed(path: path, encoding: encoding ?? .utf8)
        }
    }

    /// Reads the text of a source file, writing a warning to standard error if the file was
    /// read as ISO-8859-1 instead of UTF-8.
    ///
    /// The warning names the file as given and the place of the first byte that is not UTF-8
    /// (see ``FileDiagnosticReport``).
    ///
    /// - Parameters:
    ///   - path: The path of the file, as given on the command line.
    ///   - encoding: The encoding of the file, or `nil` (the default) to read UTF-8 and fall
    ///     back to ISO-8859-1.
    /// - Returns: The text of the file.
    /// - Throws: The errors of ``read(_:encoding:)``.
    public static func text(at path: String, encoding: TextEncoding? = nil) throws -> String {
        let decoded = try read(path, encoding: encoding)
        if let warning = decoded.warning { FileDiagnosticReport.write([warning], file: path) }
        return decoded.text
    }
}

/// An error that prevents a source file from being read.
public enum SourceFileError: Error, Sendable, Equatable, LocalizedError {
    /// The file is not valid text in the encoding that was given for it.
    ///
    /// - Parameters:
    ///   - path: The path of the file, as given on the command line.
    ///   - encoding: The encoding in which the file was read.
    case malformed(path: String, encoding: TextEncoding)

    /// A message that names the file and the encoding.
    public var errorDescription: String? {
        switch self {
        case .malformed(let path, let encoding):
            return "Cannot read \(path): the file is not valid \(encoding.name) text"
        }
    }
}
