//
// EventBFormulaPrinter.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// Prints typed OCL terms as Event-B predicates in the Unicode notation of Rodin.
///
/// Every feature is a relation from the class that declares it to its type: a total function
/// for a required single value, a partial function for an optional one and a relation for many
/// values. Navigation applies a function where the value is known to exist, and takes the
/// relational image otherwise, so that the predicates are well defined. Event-B has no strings,
/// so string literals and conditional values are outside the translatable subset for this target.
struct EventBFormulaPrinter {
    /// The target, which names the identifiers.
    let target: VerificationTarget

    /// The identifiers of classes and features that are written with a prime.
    let primed: Set<String>

    private let conjunction = " ∧ "

    /// Prints an invariant, quantified over the instances of its class.
    ///
    /// - Parameters:
    ///   - term: The checked body of the invariant.
    ///   - className: The name of the class.
    /// - Returns: The predicate.
    /// - Throws: ``TranslationError`` if a construct has no Event-B counterpart.
    func invariant(_ term: OCLTerm, className: String) throws -> String {
        let name = VerificationVocabulary.selfName
        return "∀\(name)·\(name) ∈ \(classSet(className)) ⇒ \(try wrapped(term))"
    }

    private func classSet(_ className: String) -> String {
        let name = target.identifier(className)
        return primed.contains(name) ? name + "'" : name
    }

    private func relation(_ feature: FeatureInfo) -> String {
        let name = target.feature(className: feature.owner, feature: feature.name)
        return primed.contains(name) ? name + "'" : name
    }

    private func formula(_ term: OCLTerm) throws -> String {
        switch term.node {
        case .boolean(let value): return value ? "⊤" : "⊥"
        case .variable, .navigation:
            let value = try self.value(term)
            return conjoin(value.definedness + ["\(value.text) = TRUE"], with: conjunction)
        case .not(let operand): return "¬\(try wrapped(operand))"
        case .binary(let op, let left, let right) where op.isLogical:
            let l = try wrapped(left)
            let r = try wrapped(right)
            switch op {
            case .and: return "\(l) ∧ \(r)"
            case .or: return "\(l) ∨ \(r)"
            case .implies: return "\(l) ⇒ \(r)"
            default: return "¬(\(l) ⇔ \(r))"
            }
        case .binary(let op, let left, let right):
            let symbols: [BinaryOperator: String] = [.less: "<", .lessOrEqual: "≤", .greater: ">", .greaterOrEqual: "≥"]
            return try compare(left, right, symbols[op]!)
        case .equality(let left, let right, let negated):
            if left.kind == .boolean {
                let text = "\(try wrapped(left)) ⇔ \(try wrapped(right))"
                return negated ? "¬(\(text))" : text
            }
            return try compare(left, right, negated ? "≠" : "=")
        case .undefined(let operand, let negated), .isEmpty(let operand, let negated):
            if operand.multiplicity != .collection, try value(operand).definedness.isEmpty {
                return negated ? "⊤" : "⊥"
            }
            return "\(try set(operand)) \(negated ? "≠" : "=") ∅"
        case .includes(let collection, let element, let negated):
            let value = try self.value(element)
            return conjoin(value.definedness + ["\(value.text) \(negated ? "∉" : "∈") \(try set(collection))"], with: conjunction)
        case .quantified(let quantifier, let variable, let source, let body):
            let name = target.identifier(variable)
            let domain = try set(source)
            switch quantifier {
            case .all: return "∀\(name)·\(name) ∈ \(domain) ⇒ \(try wrapped(body))"
            case .some: return "∃\(name)·\(name) ∈ \(domain) ∧ \(try wrapped(body))"
            case .one: return "card({\(name) ∣ \(name) ∈ \(domain) ∧ \(try wrapped(body))}) = 1"
            }
        case .unique(let variable, let source, let body):
            let (first, second) = OCLTerm.uniquenessCopies(of: variable)
            let differ = OCLTerm(
                .equality(body.renaming(variable, to: first), body.renaming(variable, to: second), negated: true),
                kind: .boolean)
            let a = target.identifier(first)
            let b = target.identifier(second)
            let domain = try set(source)
            return "∀\(a), \(b)·\(a) ∈ \(domain) ∧ \(b) ∈ \(domain) ∧ \(a) ≠ \(b) ⇒ \(try wrapped(differ))"
        case .kindOf(let operand, let className):
            let value = try self.value(operand)
            return conjoin(value.definedness + ["\(value.text) ∈ \(classSet(className))"], with: conjunction)
        case .conditional(let condition, let then, let otherwise):
            let c = try wrapped(condition)
            return "(\(c) ⇒ \(try wrapped(then))) ∧ (¬\(c) ⇒ \(try wrapped(otherwise)))"
        default:
            throw TranslationError("the expression cannot be written as an Event-B predicate")
        }
    }

    private func wrapped(_ term: OCLTerm) throws -> String {
        "(\(try formula(term)))"
    }

    private func compare(_ left: OCLTerm, _ right: OCLTerm, _ op: String) throws -> String {
        let l = try value(left)
        let r = try value(right)
        return conjoin(l.definedness + r.definedness + ["\(l.text) \(op) \(r.text)"], with: conjunction)
    }

    private func value(_ term: OCLTerm) throws -> GuardedValue {
        switch term.node {
        case .variable(let name): return GuardedValue(text: target.identifier(name))
        case .boolean(let value): return GuardedValue(text: value ? "TRUE" : "FALSE")
        case .integer(let value): return GuardedValue(text: value < 0 ? "−\(-value)" : String(value))
        case .string: throw TranslationError("Event-B has no string values")
        case .enumLiteral(let enumeration, let literal):
            return GuardedValue(text: target.literal(enumeration: enumeration, literal: literal))
        case .navigation(let source, let feature):
            let base = try value(source)
            let function = relation(feature)
            return GuardedValue(
                text: "\(function)(\(base.text))", guards: base.definedness,
                presence: feature.isOptional ? "\(base.text) ∈ dom(\(function))" : nil)
        case .negate(let operand):
            let base = try value(operand)
            return GuardedValue(text: "(−\(base.text))", guards: base.definedness)
        case .binary(let op, let left, let right) where !op.isLogical && !op.isComparison:
            let l = try value(left)
            let r = try value(right)
            let symbols: [BinaryOperator: String] = [.add: "+", .subtract: "−", .multiply: "∗", .divide: "÷", .modulo: "mod"]
            return GuardedValue(text: "(\(l.text) \(symbols[op]!) \(r.text))", guards: l.definedness + r.definedness)
        case .size(let operand): return GuardedValue(text: "card(\(try set(operand)))")
        case .not, .binary, .equality, .undefined, .isEmpty, .includes, .quantified, .unique, .kindOf, .conditional:
            if term.kind == .boolean { return GuardedValue(text: "bool(\(try formula(term)))") }
            throw TranslationError("Event-B has no conditional values")
        default:
            throw TranslationError("a collection is used where a single value is expected")
        }
    }

    private func set(_ term: OCLTerm) throws -> String {
        switch term.node {
        case .variable(let name): return "{\(target.identifier(name))}"
        case .navigation(let source, let feature), .collectedNavigation(let source, let feature):
            return "\(relation(feature))[\(try set(source))]"
        case .filtered(let variable, let source, let body, let keeps):
            let name = target.identifier(variable)
            let condition = keeps ? try wrapped(body) : "¬\(try wrapped(body))"
            return "{\(name) ∣ \(name) ∈ \(try set(source)) ∧ \(condition)}"
        case .allInstances(let className): return classSet(className)
        default:
            let single = try value(term)
            guard single.definedness.isEmpty else {
                throw TranslationError("a value that may be absent is used as a collection")
            }
            return "{\(single.text)}"
        }
    }
}
