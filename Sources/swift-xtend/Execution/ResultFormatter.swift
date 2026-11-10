//
// ResultFormatter.swift
// swift-xtend
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Xtend

/// Prints the result of a method as text.
///
/// Strings and numbers are printed as they are, as Xtend's `toString` would. A model object is
/// printed as its class name followed by its name in parentheses, such as `Book(Dune)`. Lists
/// and sets are printed in square brackets, maps in braces, and a pair as `key->value`.
@MainActor
struct ResultFormatter {
    /// The models in which objects are looked up when their value does not name a resource.
    let models: [Resource]

    /// Formats a value.
    ///
    /// - Parameter value: The value.
    /// - Returns: The text.
    func format(_ value: XtendHostValue) async -> String {
        typealias Display = SwiftXtendVocabulary.Display
        switch value {
        case .list(let elements), .set(let elements):
            var texts: [String] = []
            for element in elements { texts.append(await format(element)) }
            return Display.collectionOpening + texts.joined(separator: Display.separator) + Display.collectionClosing
        case .map(let entries):
            var texts: [String] = []
            for entry in entries {
                texts.append(await format(entry.key) + Display.association + (await format(entry.value)))
            }
            return Display.mapOpening + texts.joined(separator: Display.separator) + Display.mapClosing
        case .pair(let key, let element):
            return await format(key) + "->" + format(element)
        case .object(let id, let holder):
            for resource in (holder.map { [$0] } ?? []) + models {
                if let object = await resource.resolve(id) { return describe(object) }
            }
            return value.description
        default:
            return value.description
        }
    }

    /// Describes an object by its class name and its label.
    ///
    /// - Parameter object: The object.
    /// - Returns: The text, such as `Book(Dune)`, or just the class name without a label.
    func describe(_ object: any EObject) -> String {
        typealias Display = SwiftXtendVocabulary.Display
        let className = object.eClass.name
        guard let label = ArgumentBinder.label(of: object) else { return className }
        return className + Display.labelOpening + label + Display.labelClosing
    }
}
