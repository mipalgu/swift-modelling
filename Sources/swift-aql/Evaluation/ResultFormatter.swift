//
// ResultFormatter.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Foundation

/// Prints the value of an expression as text for the reader.
///
/// The text distinguishes the kinds of values at a glance:
///
/// - null prints as `null`;
/// - a string prints in double quotes, with quotes, backslashes and control characters
///   escaped, as in `"Acme Corp"`;
/// - an integer prints as its digits, as in `42`, and a real number always with a fraction
///   or an exponent, as in `500000.0`;
/// - a Boolean prints as `true` or `false`;
/// - a model object prints as the name of its class followed by its label in parentheses, as
///   in `Employee(Alice Smith)`, or as the name of its class alone if it has no label;
/// - a collection prints its elements in order, separated by commas, in square brackets, as in
///   `["Engineering", "Marketing"]`, whatever its kind;
/// - a type prints as its qualified name;
/// - a reference that could not be resolved prints as `unresolved(` followed by the URI and
///   fragment it names and `)`.
///
/// The label of an object is the value of its label attribute, which is chosen as the
/// reflective item providers of the Eclipse Modeling Framework choose it: the single-valued
/// attribute called `name` (ignoring case) if the class has one, else its first single-valued
/// attribute of type string, else its first single-valued attribute.
struct ResultFormatter: Sendable {
    /// Creates a formatter.
    init() {}

    /// The text of a value.
    ///
    /// - Parameter value: The value of an expression, or `nil` for null.
    /// - Returns: The text that represents the value.
    func format(_ value: (any EcoreValue)?) -> String {
        typealias Display = SwiftAQLVocabulary.Display
        guard let value else { return Display.null }
        if let string = value as? String { return quoted(string) }
        if let elements = AQLValues.elements(of: value) {
            return Display.collectionOpening + elements.map { format($0) }.joined(separator: Display.separator)
                + Display.collectionClosing
        }
        if let object = value as? any EObject { return describe(object) }
        if let type = value as? AQLTypeDescriptor { return type.qualifiedName }
        if let proxy = value as? ResourceProxy {
            return Display.unresolved + Display.labelOpening + proxy.uri + Display.fragmentSeparator + proxy.fragment
                + Display.labelClosing
        }
        return String(describing: value)
    }

    /// A string in double quotes, with quotes, backslashes and control characters escaped.
    ///
    /// - Parameter string: The string.
    /// - Returns: The quoted string.
    func quoted(_ string: String) -> String {
        typealias Display = SwiftAQLVocabulary.Display
        var text = String(Display.quote)
        for character in string {
            if character == Display.quote || character == Display.escape {
                text.append(Display.escape)
                text.append(character)
            } else if let escaped = Display.controlEscapes[character] {
                text += escaped
            } else {
                text.append(character)
            }
        }
        text.append(Display.quote)
        return text
    }

    /// The name of the class of an object followed by its label, if it has one.
    ///
    /// - Parameter object: The object.
    /// - Returns: The text, such as `Employee(Alice Smith)` or `Employee`.
    func describe(_ object: any EObject) -> String {
        typealias Display = SwiftAQLVocabulary.Display
        let className = object.eClass.name
        guard let label = label(of: object) else { return className }
        return className + Display.labelOpening + label + Display.labelClosing
    }

    /// The label of an object.
    ///
    /// - Parameter object: The object.
    /// - Returns: The value of its label attribute as text, or `nil` if its class has no label
    ///   attribute or the object does not set it.
    func label(of object: any EObject) -> String? {
        guard let eClass = object.eClass as? EClass, let attribute = Self.labelAttribute(of: eClass),
            let value = object.eGet(attribute)
        else { return nil }
        if let string = value as? String { return string }
        return format(value)
    }

    /// The attribute whose value labels the objects of a class.
    ///
    /// - Parameter eClass: The class.
    /// - Returns: The single-valued attribute called `name` (ignoring case), else the first
    ///   single-valued attribute of type string, else the first single-valued attribute, or
    ///   `nil` if the class has no single-valued attribute.
    static func labelAttribute(of eClass: EClass) -> EAttribute? {
        let candidates = eClass.allAttributes.filter { !$0.isMany }
        if let named = candidates.first(where: {
            $0.name.caseInsensitiveCompare(SwiftAQLVocabulary.labelAttributeName) == .orderedSame
        }) {
            return named
        }
        return candidates.first { AQLBuiltInType.strings.contains($0.eType.name) } ?? candidates.first
    }
}
