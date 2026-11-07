//
// ExpressionSource.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation
import ModellingCommandLine

/// Where the text of an expression comes from.
enum ExpressionSource: Sendable, Equatable {
    /// The expression as given on the command line.
    case text(String)

    /// A file that holds the expression, by its path as given on the command line.
    case file(String)

    /// The source that a command line names, if it names exactly one.
    ///
    /// - Parameters:
    ///   - candidates: The expression texts given on the command line, such as an argument and
    ///     an option, `nil` for those not given.
    ///   - file: The path of the expression file given on the command line, if any.
    /// - Returns: The source, or `nil` if the command line names no source or more than one.
    static func select(texts candidates: [String?], file: String?) -> ExpressionSource? {
        let sources = candidates.compactMap { $0.map(ExpressionSource.text) } + [file.map(ExpressionSource.file)].compactMap { $0 }
        return sources.count == 1 ? sources.first : nil
    }

    /// The text of the expression.
    ///
    /// A file is read in the given encoding or, without one, as UTF-8; a file that is not valid
    /// UTF-8 is then read as ISO-8859-1, and a warning that names the file is written to
    /// standard error (see `FileDiagnosticReport`).
    ///
    /// - Parameter encoding: The encoding of a file, or `nil` (the default) to read UTF-8 and
    ///   fall back to ISO-8859-1.
    /// - Returns: The expression as given, or the contents of the file.
    /// - Throws: ``SwiftAQLError/expressionFileNotFound(_:)`` if the file cannot be read,
    ///   `SourceFileError.malformed(path:encoding:)` if it is not valid in the given encoding,
    ///   and ``SwiftAQLError/emptyExpression`` if the expression holds nothing but white space.
    func text(encoding: TextEncoding? = nil) throws -> String {
        let text: String
        switch self {
        case .text(let expression):
            text = expression
        case .file(let path):
            let decoded: DecodedText
            do {
                decoded = try SourceFile.read(path, encoding: encoding)
            } catch let error as SourceFileError {
                throw error
            } catch {
                throw SwiftAQLError.expressionFileNotFound(path)
            }
            if let warning = decoded.warning { FileDiagnosticReport.write([warning], file: path) }
            text = decoded.text
        }
        guard !text.allSatisfy(\.isWhitespace) else { throw SwiftAQLError.emptyExpression }
        return text
    }
}
