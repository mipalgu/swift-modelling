//
// SourceReader.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import EOL
import Foundation
import ModellingCommandLine

/// Reads and parses the source files of a run: programs, constraints, transformations,
/// templates, coordination modules and the modules they import.
///
/// Every file is read in the encoding of the run or, without one, as UTF-8, falling back to
/// ISO-8859-1 with a warning on standard error for a file that is not valid UTF-8. The problems
/// that the parser reports are written to standard error, each with its file, line and column.
struct SourceReader: Sendable {
    /// The encoding of the files, or `nil` to read UTF-8 and fall back to ISO-8859-1.
    let encoding: TextEncoding?

    /// Creates a reader.
    ///
    /// - Parameter encoding: The encoding of the files, or `nil` (the default) to detect it.
    init(encoding: TextEncoding? = nil) {
        self.encoding = encoding
    }

    /// Reads the text of a source file.
    ///
    /// - Parameter path: The path of the file.
    /// - Returns: The text of the file.
    /// - Throws: ``SwiftEpsilonError/sourceNotFound(_:)`` if the file cannot be read, and
    ///   `SourceFileError.malformed(path:encoding:)` if it is not valid in the given encoding.
    func text(at path: String) throws -> String {
        do {
            return try SourceFile.text(at: path, encoding: encoding)
        } catch let error as SourceFileError {
            throw error
        } catch {
            throw SwiftEpsilonError.sourceNotFound(path)
        }
    }

    /// Reads and parses a source file.
    ///
    /// Warnings of the parser are reported and do not stop the run; errors are reported and then
    /// stop it.
    ///
    /// - Parameters:
    ///   - path: The path of the file, which names the document in diagnostics.
    ///   - parse: The parser of the language, given the text and the document.
    ///   - report: What receives the diagnostics of the parser (standard error by default).
    /// - Returns: The parsed module.
    /// - Throws: The errors of ``text(at:)``, and ``SwiftEpsilonError/invalidSource(_:_:)`` if
    ///   the parser reports errors.
    func module<Module: Sendable>(
        at path: String, parse: (String, String) -> EOLParseResult<Module>,
        report: ([SourceDiagnostic], String) -> Void = { FileDiagnosticReport.write($0, file: $1) }
    ) throws -> Module {
        let result = parse(try text(at: path), path)
        report(result.diagnostics, path)
        let errors = result.diagnostics.filter { $0.severity == .error }.count
        guard errors == 0 else { throw SwiftEpsilonError.invalidSource(path, errors) }
        return result.module
    }

    /// The loader that reads the modules and templates that a source file refers to.
    var moduleLoader: SourceModuleLoader { SourceModuleLoader(encoding: encoding) }
}

/// Reads the modules that programs import and the templates that EGX rules name.
///
/// A relative path is resolved against the directory of the document that refers to it, and
/// the file is read in the encoding of the run, as ``SourceReader`` reads source files.
struct SourceModuleLoader: EOLModuleLoading, Sendable {
    /// The encoding of the files, or `nil` to read UTF-8 and fall back to ISO-8859-1.
    let encoding: TextEncoding?

    /// Reads an imported module or a template.
    ///
    /// - Parameters:
    ///   - path: The path as the source file writes it.
    ///   - document: The source file that refers to it, if known.
    /// - Returns: The text and the path of the file, which names it in diagnostics.
    /// - Throws: The errors of ``SourceReader/text(at:)``.
    func load(_ path: String, relativeTo document: String?) throws -> (text: String, document: String) {
        let resolved = Self.resolve(path, relativeTo: document)
        return (try SourceReader(encoding: encoding).text(at: resolved), resolved)
    }

    /// Resolves the path of a file that a source file refers to.
    ///
    /// - Parameters:
    ///   - path: The path as the source file writes it, or a `file:` URL.
    ///   - document: The path or `file:` URL of the source file that refers to it, if known.
    /// - Returns: The path itself if it is absolute or there is no document, and the path within
    ///   the directory of the document otherwise.
    static func resolve(_ path: String, relativeTo document: String?) -> String {
        let reference = filePath(path)
        guard let document, !NSString(string: reference).isAbsolutePath else { return reference }
        let directory = NSString(string: filePath(document)).deletingLastPathComponent
        guard !directory.isEmpty else { return reference }
        return NSString(string: directory).appendingPathComponent(reference)
    }

    /// The path that a path or a `file:` URL names.
    ///
    /// - Parameter text: A path or a `file:` URL.
    /// - Returns: The path of the URL, or the text itself.
    private static func filePath(_ text: String) -> String {
        guard let url = URL(string: text), url.isFileURL else { return text }
        return url.path
    }
}
