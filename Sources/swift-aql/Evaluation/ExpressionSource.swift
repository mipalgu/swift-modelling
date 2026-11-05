//
// ExpressionSource.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

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
    /// - Returns: The expression as given, or the contents of the file.
    /// - Throws: ``SwiftAQLError/expressionFileNotFound(_:)`` if the file cannot be read, and
    ///   ``SwiftAQLError/emptyExpression`` if the expression holds nothing but white space.
    func text() throws -> String {
        let text: String
        switch self {
        case .text(let expression):
            text = expression
        case .file(let path):
            guard let contents = try? String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8) else {
                throw SwiftAQLError.expressionFileNotFound(path)
            }
            text = contents
        }
        guard !text.allSatisfy(\.isWhitespace) else { throw SwiftAQLError.emptyExpression }
        return text
    }
}
