//
// LeanFormulaPrinter.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// Prints typed OCL terms as Lean 4 propositions over a model `m`.
///
/// The exported Lean file represents an object by an identifier, a single value as an `Option`,
/// which is `none` when the value is absent, and many values as a `List`. Truth values are
/// computed as `Bool`, so that the propositions are decidable and a model can be checked with
/// `decide`. A comparison involving an absent value is false, as an invariant over an invalid
/// value is not satisfied in OCL. The helper functions that the formulas use (`optEq`, `optGe`,
/// `allDistinct`, `Model.one`, `Model.many` and so on) are part of every exported metamodel.
struct LeanFormulaPrinter {
    /// The target, which names the identifiers.
    let target: VerificationTarget

    /// Prints an invariant, quantified over the instances of its class.
    ///
    /// - Parameters:
    ///   - term: The checked body of the invariant.
    ///   - className: The name of the class.
    /// - Returns: The proposition.
    /// - Throws: ``TranslationError`` if a construct has no Lean counterpart.
    func invariant(_ term: OCLTerm, className: String) throws -> String {
        let name = VerificationVocabulary.selfName
        let body = try boolean(term)
        return "∀ \(name) ∈ m.instancesOf \(membership(className)), \(body.hasPrefix("!") ? "(\(body))" : body) = true"
    }

    private func membership(_ className: String) -> String {
        "Obj." + target.identifier("is" + className)
    }

    private func accessor(_ feature: FeatureInfo) -> String {
        "Obj." + target.feature(className: feature.owner, feature: feature.name)
    }

    private func boolean(_ term: OCLTerm) throws -> String {
        switch term.node {
        case .boolean(let value): return value ? "true" : "false"
        case .variable, .navigation: return "optEq \(try single(term)) (some true)"
        case .not(let operand): return "!\(try parenthesised(operand))"
        case .binary(let op, let left, let right) where op.isLogical:
            let l = try boolean(left)
            let r = try boolean(right)
            switch op {
            case .and: return "(\(l) && \(r))"
            case .or: return "(\(l) || \(r))"
            case .implies: return "(!\(try parenthesised(left)) || \(r))"
            default: return "(\(try parenthesised(left)) != \(try parenthesised(right)))"
            }
        case .binary(let op, let left, let right):
            let names: [BinaryOperator: String] = [.less: "optLt", .lessOrEqual: "optLe", .greater: "optGt", .greaterOrEqual: "optGe"]
            return "\(names[op]!) \(try single(left)) \(try single(right))"
        case .equality(let left, let right, let negated):
            if left.kind == .boolean, !isSingleValue(left) || !isSingleValue(right) {
                let text = "(\(try parenthesised(left)) == \(try parenthesised(right)))"
                return negated ? "!\(text)" : text
            }
            return "\(negated ? "optNe" : "optEq") \(try single(left)) \(try single(right))"
        case .undefined(let operand, let negated):
            return "\(try single(operand)).\(negated ? "isSome" : "isNone")"
        case .isEmpty(let operand, let negated):
            if operand.multiplicity != .collection {
                return try boolean(OCLTerm(.undefined(operand, negated: negated), kind: .boolean))
            }
            return "\(negated ? "!" : "")(\(try list(operand))).isEmpty"
        case .includes(let collection, let element, let negated):
            return "\(negated ? "!" : "")(optContains (\(try list(collection))) \(try single(element)))"
        case .quantified(let quantifier, let variable, let source, let body):
            let lambda = "(fun \(target.identifier(variable)) => \(try boolean(body)))"
            switch quantifier {
            case .all: return "(\(try list(source))).all \(lambda)"
            case .some: return "(\(try list(source))).any \(lambda)"
            case .one: return "(((\(try list(source))).filter \(lambda)).length == 1)"
            }
        case .unique(let variable, let source, let body):
            return "allDistinct ((\(try list(source))).map (fun \(target.identifier(variable)) => \(bare(try single(body)))))"
        case .kindOf(let operand, let className):
            return "m.isKindOf \(membership(className)) \(try single(operand))"
        case .conditional(let condition, let then, let otherwise):
            return "(if \(try boolean(condition)) then \(try boolean(then)) else \(try boolean(otherwise)))"
        default:
            throw TranslationError("the expression cannot be written as a Lean truth value")
        }
    }

    private func bare(_ text: String) -> String {
        guard text.hasPrefix("("), text.hasSuffix(")") else { return text }
        var depth = 0
        for (offset, character) in text.enumerated() {
            if character == "(" { depth += 1 }
            if character == ")" { depth -= 1 }
            if depth == 0 && offset < text.count - 1 { return text }
        }
        return String(text.dropFirst().dropLast())
    }

    private func isSingleValue(_ term: OCLTerm) -> Bool {
        switch term.node {
        case .variable, .navigation, .boolean: return true
        default: return false
        }
    }

    private func parenthesised(_ term: OCLTerm) throws -> String {
        let text = try boolean(term)
        return text.hasPrefix("(") || !text.contains(" ") ? text : "(\(text))"
    }

    private func single(_ term: OCLTerm) throws -> String {
        switch term.node {
        case .variable(let name): return "(some \(target.identifier(name)))"
        case .boolean(let value): return "(some \(value))"
        case .integer(let value): return "(some \(value < 0 ? "(\(value))" : String(value)))"
        case .string(let value):
            return "(some \(target.stringLiteral(value)))"
        case .enumLiteral(let enumeration, let literal):
            return "(some \(target.literal(enumeration: enumeration, literal: literal)))"
        case .navigation(let source, let feature):
            return "(m.one \(accessor(feature)) \(try single(source)))"
        case .negate(let operand): return "(optNeg \(try single(operand)))"
        case .binary(let op, let left, let right) where !op.isLogical && !op.isComparison:
            let names: [BinaryOperator: String] = [.add: "optAdd", .subtract: "optSub", .multiply: "optMul", .divide: "optDiv", .modulo: "optMod"]
            return "(\(names[op]!) \(try single(left)) \(try single(right)))"
        case .size(let operand): return "(some ((\(try list(operand))).length : Int))"
        case .conditional(let condition, let then, let otherwise):
            return "(if \(try boolean(condition)) then \(try single(then)) else \(try single(otherwise)))"
        case .not, .binary, .equality, .undefined, .isEmpty, .includes, .quantified, .unique, .kindOf:
            return "(some \(try parenthesised(term)))"
        default:
            throw TranslationError("a collection is used where a single value is expected")
        }
    }

    private func list(_ term: OCLTerm) throws -> String {
        switch term.node {
        case .navigation(let source, let feature) where feature.isMany:
            return "m.many \(accessor(feature)) \(try single(source))"
        case .collectedNavigation(let source, let feature):
            return "m.\(feature.isMany ? "manyAll" : "oneAll") \(accessor(feature)) (\(try list(source)))"
        case .filtered(let variable, let source, let body, let keeps):
            let condition = keeps ? try boolean(body) : "!\(try parenthesised(body))"
            return "(\(try list(source))).filter (fun \(target.identifier(variable)) => \(condition))"
        case .allInstances(let className): return "m.instancesOf \(membership(className))"
        default: return "(\(try single(term))).toList"
        }
    }
}
