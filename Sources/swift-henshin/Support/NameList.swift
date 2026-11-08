//
// NameList.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// Reads the names that list options give, such as `--rules move,drain`.
///
/// A list option can hold several names separated by commas, and can be repeated; the names
/// of all its values are taken in order.
enum NameList {
    /// Splits the values of a list option into names.
    ///
    /// - Parameter values: The values, each holding names separated by commas.
    /// - Returns: The names, without surrounding blanks and without empty names, in order.
    static func names(_ values: [String]) -> [String] {
        values.flatMap { $0.split(separator: SwiftHenshinVocabulary.Separator.list) }
            .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}

extension Array {
    /// The array, or `nil` if it is empty.
    var nilIfEmpty: [Element]? { isEmpty ? nil : self }
}
