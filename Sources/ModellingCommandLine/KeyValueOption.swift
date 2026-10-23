//
// KeyValueOption.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// The syntax that every family of `name=value` options shares.
public enum KeyValueOptionSyntax {
    /// The character that separates a name from its value, such as in `package=org.example`.
    public static let separator: Character = "="

    /// The word that stands for a value in the usage and in messages.
    public static let valuePlaceholder = "value"

    /// The word that stands for a name in the usage and in messages, unless a family names its own.
    public static let defaultKeyPlaceholder = "name"
}

/// A parser for a family of command line values given as `name=value` pairs.
///
/// Several tools take an option that can be repeated, each time with a name and a value, such
/// as `--param package=org.example`. A family of such options fixes the word it uses in messages
/// (such as `parameter`), optionally the names that are allowed, and how the text of a value is
/// converted to a typed value. The value is everything after the first
/// ``KeyValueOptionSyntax/separator``, so it can itself contain the separator, and a later pair
/// with the same name replaces an earlier one.
///
/// Commands declare the option as an array of text values with `@Option`, and convert the
/// arguments with ``values(from:)`` when they run.
///
/// ## Example
///
/// ```swift
/// let levels = KeyValueOption<Int>(noun: "level", allowedKeys: ["debug", "release"])
/// let values = try levels.values(from: ["debug=0", "release=3"])
/// // values == ["debug": 0, "release": 3]
/// ```
public struct KeyValueOption<Value: Sendable>: Sendable {
    /// Converts the text of a value into a typed value.
    ///
    /// The closure receives the name and the text of the value, and throws an error that
    /// explains why the text is not a valid value; the error is reported as
    /// ``KeyValueOptionError/invalidValue(noun:key:value:reason:)``.
    public typealias Conversion = @Sendable (_ key: String, _ text: String) throws -> Value

    /// The word that names a member of the family in messages, such as `parameter`.
    public let noun: String

    /// The word that stands for the name of a pair in messages, such as `name`.
    public let keyPlaceholder: String

    /// The names that are allowed, in the order in which they are documented.
    ///
    /// `nil` allows every name that is not empty.
    public let allowedKeys: [String]?

    /// The conversion of the text of a value into a typed value.
    public let convert: Conversion

    /// Creates a family of `name=value` options.
    ///
    /// - Parameters:
    ///   - noun: The word that names a member of the family in messages, such as `parameter`.
    ///   - keyPlaceholder: The word that stands for the name of a pair in messages (default
    ///     ``KeyValueOptionSyntax/defaultKeyPlaceholder``).
    ///   - allowedKeys: The names that are allowed, or `nil` (the default) to allow any name.
    ///   - convert: The conversion of the text of a value into a typed value.
    public init(
        noun: String, keyPlaceholder: String = KeyValueOptionSyntax.defaultKeyPlaceholder,
        allowedKeys: [String]? = nil, convert: @escaping Conversion
    ) {
        self.noun = noun
        self.keyPlaceholder = keyPlaceholder
        self.allowedKeys = allowedKeys
        self.convert = convert
    }

    /// The form of a pair, as text for the help and for messages, such as `name=value`.
    public var usage: String {
        keyPlaceholder + String(KeyValueOptionSyntax.separator) + KeyValueOptionSyntax.valuePlaceholder
    }

    /// The allowed names as text for the help of an option.
    ///
    /// - Returns: The allowed names separated by commas, or `nil` if every name is allowed.
    public var allowedKeyList: String? {
        allowedKeys?.joined(separator: ", ")
    }

    /// Reads one `name=value` pair.
    ///
    /// - Parameter text: The pair as given on the command line.
    /// - Returns: The name and the converted value.
    /// - Throws: ``KeyValueOptionError/missingSeparator(noun:text:usage:)`` if the text has no
    ///   name or no separator, ``KeyValueOptionError/unknownKey(noun:key:allowed:)`` if the name
    ///   is not one of ``allowedKeys``, and ``KeyValueOptionError/invalidValue(noun:key:value:reason:)``
    ///   if the conversion rejects the value.
    public func pair(_ text: String) throws -> (key: String, value: Value) {
        guard let separator = text.firstIndex(of: KeyValueOptionSyntax.separator),
            separator != text.startIndex
        else {
            throw KeyValueOptionError.missingSeparator(noun: noun, text: text, usage: usage)
        }
        let key = String(text[..<separator])
        if let allowedKeys, !allowedKeys.contains(key) {
            throw KeyValueOptionError.unknownKey(noun: noun, key: key, allowed: allowedKeys)
        }
        let valueText = String(text[text.index(after: separator)...])
        do {
            return (key, try convert(key, valueText))
        } catch let error as KeyValueOptionError {
            throw error
        } catch {
            throw KeyValueOptionError.invalidValue(
                noun: noun, key: key, value: valueText, reason: String(describing: error))
        }
    }

    /// Reads a list of `name=value` pairs.
    ///
    /// - Parameter arguments: The pairs in command line order.
    /// - Returns: The converted values by name; a later pair replaces an earlier one of the same name.
    /// - Throws: The error of ``pair(_:)`` for the first pair that cannot be read.
    public func values(from arguments: [String]) throws -> [String: Value] {
        var values: [String: Value] = [:]
        for argument in arguments {
            let (key, value) = try pair(argument)
            values[key] = value
        }
        return values
    }
}

extension KeyValueOption where Value: LosslessStringConvertible {
    /// Creates a family whose values are read with the text initialiser of their type.
    ///
    /// The values of a `String` family are the texts as given; an `Int`, `Double` or `Bool`
    /// family accepts the texts that the type itself reads, such as `42`, `0.5` or `true`.
    ///
    /// - Parameters:
    ///   - noun: The word that names a member of the family in messages, such as `parameter`.
    ///   - keyPlaceholder: The word that stands for the name of a pair in messages (default
    ///     ``KeyValueOptionSyntax/defaultKeyPlaceholder``).
    ///   - allowedKeys: The names that are allowed, or `nil` (the default) to allow any name.
    public init(
        noun: String, keyPlaceholder: String = KeyValueOptionSyntax.defaultKeyPlaceholder,
        allowedKeys: [String]? = nil
    ) {
        self.init(noun: noun, keyPlaceholder: keyPlaceholder, allowedKeys: allowedKeys) { _, text in
            guard let value = Value(text) else { throw KeyValueOptionConversionFailure(type: "\(Value.self)") }
            return value
        }
    }
}

/// The reason why the text of a value cannot be read as a value of its type.
struct KeyValueOptionConversionFailure: Error, CustomStringConvertible {
    /// The name of the type that the value should have.
    let type: String

    /// A phrase that names the expected type.
    var description: String { "expected a value of type \(type)" }
}

/// The problems found when reading `name=value` pairs.
public enum KeyValueOptionError: Error, Equatable, Sendable, CustomStringConvertible {
    /// The text has no name or no separator.
    ///
    /// The associated values are the word that names a member of the family, the text as
    /// given, and the form of a pair, such as `name=value`.
    case missingSeparator(noun: String, text: String, usage: String)

    /// The name is not one of the allowed names.
    ///
    /// The associated values are the word that names a member of the family, the name as
    /// given, and the allowed names.
    case unknownKey(noun: String, key: String, allowed: [String])

    /// The conversion rejected the text of a value.
    ///
    /// The associated values are the word that names a member of the family, the name, the
    /// text of the value and the reason given by the conversion.
    case invalidValue(noun: String, key: String, value: String, reason: String)

    /// A sentence that describes the problem and how to correct it.
    public var description: String {
        switch self {
        case .missingSeparator(let noun, let text, let usage):
            return "Invalid \(noun) '\(text)': expected \(usage)"
        case .unknownKey(let noun, let key, let allowed):
            return "Unknown \(noun) '\(key)': expected one of \(allowed.joined(separator: ", "))"
        case .invalidValue(let noun, let key, let value, let reason):
            return "Invalid value '\(value)' for the \(noun) '\(key)': \(reason)"
        }
    }
}

extension KeyValueOptionError: LocalizedError {
    /// The ``description`` of the error.
    public var errorDescription: String? { description }
}
