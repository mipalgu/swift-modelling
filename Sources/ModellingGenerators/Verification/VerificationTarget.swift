//
// VerificationTarget.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// A formal verification language that models and metamodels can be exported to.
///
/// Each target names a template set of the same name, and fixes the rules for the identifiers
/// that both the templates and the translation of invariants write, so that the two always agree.
///
/// ## Example
///
/// ```swift
/// let target = VerificationTarget(rawValue: "alloy")
/// print(target?.identifier("sig") ?? "")   // sig_
/// ```
public enum VerificationTarget: String, CaseIterable, Sendable {
    /// Alloy 6, a relational modelling language with a bounded analyser.
    case alloy

    /// TLA+, a specification language with the TLC model checker.
    case tla

    /// Event-B, a refinement-based formal method supported by the Rodin platform.
    case eventB = "eventb"

    /// Lean 4, a dependently typed programming language and interactive theorem prover.
    case lean

    /// The name of the template set that exports to this target.
    public var templateSetName: String { rawValue }

    /// Whether a language names the template set of a verification target.
    ///
    /// The tools use it to list the verification targets apart from the languages of code.
    ///
    /// - Parameter language: The name of a language, such as `alloy` or `java`.
    /// - Returns: `true` if a verification target exports with the template set of that name.
    public static func isTarget(_ language: String) -> Bool {
        allCases.contains { $0.templateSetName == language }
    }

    /// The words that cannot be used as identifiers in this target.
    ///
    /// The lists cover the keywords of each language, the names of built-in sets and operators,
    /// and the names that the exported text itself declares.
    public var reservedWords: Set<String> {
        switch self {
        case .alloy: return VerificationVocabulary.alloyReservedWords
        case .tla: return VerificationVocabulary.tlaReservedWords
        case .eventB: return VerificationVocabulary.eventBReservedWords
        case .lean: return VerificationVocabulary.leanReservedWords
        }
    }

    /// Makes a model name safe to use as an identifier of this target.
    ///
    /// A reserved word gets a trailing underscore; Lean keywords are enclosed in guillemets instead,
    /// which Lean accepts for any name, and names that the Lean export declares itself get a
    /// trailing underscore, since guillemets do not change a name.
    ///
    /// - Parameter name: The name of a model element.
    /// - Returns: The identifier that the exported text uses for the element.
    public func identifier(_ name: String) -> String {
        if self == .lean, VerificationVocabulary.leanDeclaredNames.contains(name) {
            return name + VerificationVocabulary.reservedSuffix
        }
        guard reservedWords.contains(name) else { return name }
        switch self {
        case .lean: return "«\(name)»"
        default: return name + VerificationVocabulary.reservedSuffix
        }
    }

    /// The identifier of an enumeration literal.
    ///
    /// Alloy and Event-B declare literals as global atoms or constants, so they are qualified by
    /// their enumeration; TLA+ represents literals as strings and Lean as constructors, which are
    /// qualified by the enumeration type where they are used.
    ///
    /// - Parameters:
    ///   - enumeration: The name of the enumeration.
    ///   - literal: The name of the literal.
    /// - Returns: The identifier or literal text that denotes the enumeration literal.
    public func literal(enumeration: String, literal: String) -> String {
        switch self {
        case .alloy, .eventB: return identifier(enumeration + VerificationVocabulary.qualifier + literal)
        case .tla: return "\"" + literal + "\""
        case .lean: return identifier(enumeration) + "." + identifier(literal)
        }
    }

    /// The identifier of a structural feature.
    ///
    /// Event-B identifiers share one name space per component, and Lean reads every feature through
    /// one accessor function of the object type, so both qualify features by the class that
    /// declares them; Alloy and TLA+ scope features by their signature or record.
    ///
    /// - Parameters:
    ///   - className: The name of the class that declares the feature.
    ///   - feature: The name of the feature.
    /// - Returns: The identifier of the feature.
    public func feature(className: String, feature: String) -> String {
        switch self {
        case .eventB, .lean: return identifier(className + VerificationVocabulary.qualifier + feature)
        default: return identifier(feature)
        }
    }

    /// The literal that denotes a string in this target.
    ///
    /// Alloy, TLA+ and Lean write strings in double quotes, with backslashes before double quotes
    /// and backslashes; line breaks and tabs are written as escapes. Event-B has no strings: its
    /// exports declare a constant for each string and use this form only in comments.
    ///
    /// - Parameter text: The string.
    /// - Returns: The literal.
    public func stringLiteral(_ text: String) -> String {
        var escaped = ""
        for character in text {
            switch character {
            case "\\": escaped += "\\\\"
            case "\"": escaped += "\\\""
            case "\n": escaped += "\\n"
            case "\t": escaped += "\\t"
            default: escaped.append(character)
            }
        }
        return "\"" + escaped + "\""
    }
}

