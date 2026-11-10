//
// ParameterValue.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EGL
import EOL
import ModellingCommandLine

/// The value of a parameter that the command line passes to a program with `--param`.
///
/// The text after the first `=` is typed: `true` and `false` are Booleans, a whole number is an
/// Integer, another number, such as `2.5`, is a Real, and anything else is a String.
enum ParameterValue: Sendable, Equatable {
    /// A truth value.
    case boolean(Bool)

    /// A whole number.
    case integer(Int64)

    /// A real number.
    case real(Double)

    /// A character string.
    case string(String)

    /// The family of `name=value` options that pass parameters.
    static let option = KeyValueOption<ParameterValue>(noun: SwiftEpsilonVocabulary.Noun.parameter) { _, text in
        ParameterValue(text: text)
    }

    /// Creates the value that a text denotes.
    ///
    /// - Parameter text: The text after the `=` of a parameter.
    init(text: String) {
        switch text {
        case SwiftEpsilonVocabulary.ParameterLiteral.trueText:
            self = .boolean(true)
        case SwiftEpsilonVocabulary.ParameterLiteral.falseText:
            self = .boolean(false)
        default:
            if let integer = Int64(text) {
                self = .integer(integer)
            } else if let real = Double(text), real.isFinite {
                self = .real(real)
            } else {
                self = .string(text)
            }
        }
    }

    /// The value as the Epsilon Object Language sees it.
    var eolValue: EOLValue {
        switch self {
        case .boolean(let value): return .boolean(value)
        case .integer(let value): return .integer(value)
        case .real(let value): return .real(value)
        case .string(let value): return .string(value)
        }
    }

    /// The variables that the languages bind themselves, which a parameter cannot replace.
    static let reservedNames: Set<String> = [
        EOLLanguage.Variable.receiver, EOLLanguage.Variable.loopCount, EOLLanguage.Variable.hasMore,
        EGLLanguage.Variable.out, EGLLanguage.Variable.generated,
    ]

    /// Whether a name may name a parameter.
    ///
    /// - Parameter name: The name.
    /// - Returns: `true` if the name is an identifier that is neither a keyword of the Epsilon
    ///   Object Language nor a variable that the languages bind themselves, such as `self`.
    static func isValidName(_ name: String) -> Bool {
        Identifier.isValid(name) && !EOLLanguage.Keyword.all.contains(name) && !reservedNames.contains(name)
    }

    /// Reads the parameters given on the command line.
    ///
    /// - Parameter arguments: The values of `--param`, in command line order.
    /// - Returns: The typed values by name; a later parameter replaces an earlier one of the same name.
    /// - Throws: `KeyValueOptionError` if an argument is not `name=value`, and
    ///   ``SwiftEpsilonError/invalidParameterName(_:)`` if a name is not valid (see ``isValidName(_:)``).
    static func parameters(from arguments: [String]) throws -> [String: ParameterValue] {
        let values = try option.values(from: arguments)
        for name in values.keys where !isValidName(name) {
            throw SwiftEpsilonError.invalidParameterName(name)
        }
        return values
    }
}
