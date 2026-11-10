//
// AlloyFormulaPrinter.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// Prints typed OCL terms as Alloy 6 formulas and expressions.
///
/// Alloy is relational, so navigation joins relations whether a feature holds one value or
/// many, and an absent value is the empty set. Truth-valued attributes hold atoms of the
/// signature `Bool` of the module `util/boolean`, and integers use the built-in integer functions.
/// An absent integer counts as zero in an integer comparison, unlike in OCL, where the comparison
/// would be invalid.
struct AlloyFormulaPrinter {
    /// The target, which names the identifiers.
    let target: VerificationTarget

    /// Prints an invariant, quantified over the instances of its class.
    ///
    /// - Parameters:
    ///   - term: The checked body of the invariant.
    ///   - className: The name of the class.
    /// - Returns: The formula.
    /// - Throws: ``TranslationError`` if a construct has no Alloy counterpart.
    func invariant(_ term: OCLTerm, className: String) throws -> String {
        "all \(VerificationVocabulary.selfName): \(target.identifier(className)) | " + (try formula(term))
    }

    private func formula(_ term: OCLTerm) throws -> String {
        switch term.node {
        case .boolean(let value): return value ? "(none = none)" : "(some none)"
        case .variable, .navigation: return "(\(try expression(term)) = True)"
        case .not(let operand): return "not \(try wrapped(operand))"
        case .binary(let op, let left, let right) where op.isLogical:
            let l = try wrapped(left)
            let r = try wrapped(right)
            switch op {
            case .and: return "\(l) and \(r)"
            case .or: return "\(l) or \(r)"
            case .implies: return "\(l) implies \(r)"
            default: return "not (\(l) iff \(r))"
            }
        case .binary(let op, let left, let right):
            return "\(try expression(left)) \(op.rawValue) \(try expression(right))"
        case .equality(let left, let right, let negated):
            if left.kind == .boolean {
                let text: String
                if case .boolean(let value) = right.node {
                    text = value ? try formula(left) : "not \(try wrapped(left))"
                } else if case .boolean(let value) = left.node {
                    text = value ? try formula(right) : "not \(try wrapped(right))"
                } else {
                    text = "\(try wrapped(left)) iff \(try wrapped(right))"
                }
                return negated ? "not (\(text))" : text
            }
            return "\(try expression(left)) \(negated ? "!=" : "=") \(try expression(right))"
        case .undefined(let operand, let negated), .isEmpty(let operand, let negated):
            return "\(negated ? "some" : "no") \(try expression(operand))"
        case .includes(let collection, let element, let negated):
            return "\(try expression(element)) \(negated ? "not in" : "in") \(try expression(collection))"
        case .quantified(let quantifier, let variable, let source, let body):
            return "\(quantifier.rawValue) \(target.identifier(variable)): \(try expression(source)) | \(try formula(body))"
        case .unique(let variable, let source, let body):
            let (first, second) = OCLTerm.uniquenessCopies(of: variable)
            let a = body.renaming(variable, to: first)
            let b = body.renaming(variable, to: second)
            let differ = OCLTerm(.equality(a, b, negated: true), kind: .boolean)
            return "all disj \(target.identifier(first)), \(target.identifier(second)): \(try expression(source)) | \(try formula(differ))"
        case .kindOf(let operand, let className):
            return "\(try expression(operand)) in \(target.identifier(className))"
        case .conditional(let condition, let then, let otherwise):
            return "\(try wrapped(condition)) implies \(try wrapped(then)) else \(try wrapped(otherwise))"
        default:
            throw TranslationError("the expression cannot be written as an Alloy formula")
        }
    }

    private func wrapped(_ term: OCLTerm) throws -> String {
        let text = try formula(term)
        return text.hasPrefix("(") && balanced(text) ? text : "(\(text))"
    }

    private func expression(_ term: OCLTerm) throws -> String {
        switch term.node {
        case .variable(let name): return target.identifier(name)
        case .boolean(let value): return value ? "True" : "False"
        case .integer(let value): return value < 0 ? "minus[0, \(-value)]" : String(value)
        case .string(let value): return target.stringLiteral(value)
        case .enumLiteral(let enumeration, let literal): return target.literal(enumeration: enumeration, literal: literal)
        case .navigation(let source, let feature), .collectedNavigation(let source, let feature):
            return "\(try expression(source)).\(target.feature(className: feature.owner, feature: feature.name))"
        case .negate(let operand): return "minus[0, \(try expression(operand))]"
        case .binary(let op, let left, let right) where !op.isLogical && !op.isComparison:
            let names: [BinaryOperator: String] = [.add: "plus", .subtract: "minus", .multiply: "mul", .divide: "div", .modulo: "rem"]
            return "\(names[op]!)[\(try expression(left)), \(try expression(right))]"
        case .size(let operand): return "#\(try expression(operand))"
        case .filtered(let variable, let source, let body, let keeps):
            let condition = keeps ? try formula(body) : "not \(try wrapped(body))"
            return "{\(target.identifier(variable)): \(try expression(source)) | \(condition)}"
        case .allInstances(let className): return target.identifier(className)
        case .conditional(let condition, let then, let otherwise):
            return "(\(try wrapped(condition)) implies \(try expression(then)) else \(try expression(otherwise)))"
        default:
            throw TranslationError("truth values computed by formulas cannot be used as Alloy values")
        }
    }

    private func balanced(_ text: String) -> Bool {
        var depth = 0
        for (offset, character) in text.enumerated() {
            if character == "(" { depth += 1 }
            if character == ")" { depth -= 1 }
            if depth == 0 && offset < text.count - 1 { return false }
        }
        return depth == 0
    }
}
