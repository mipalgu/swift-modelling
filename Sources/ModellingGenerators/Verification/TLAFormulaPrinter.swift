//
// TLAFormulaPrinter.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// Prints typed OCL terms as TLA+ formulas over the object store `obj`.
///
/// The state of the exported module maps every object identifier to a record of its feature
/// values. A single-valued feature holds a value, or `Null` if it is optional and absent; a
/// many-valued feature holds a set. Navigation through a value that may be absent is guarded by
/// the condition that it is present, see ``GuardedValue``.
struct TLAFormulaPrinter {
    /// The target, which names the identifiers.
    let target: VerificationTarget

    private let conjunction = " /\\ "
    private let null = "Null"

    /// Prints an invariant, quantified over the instances of its class.
    ///
    /// - Parameters:
    ///   - term: The checked body of the invariant.
    ///   - className: The name of the class.
    /// - Returns: The formula.
    /// - Throws: ``TranslationError`` if a construct has no TLA+ counterpart.
    func invariant(_ term: OCLTerm, className: String) throws -> String {
        "\\A \(VerificationVocabulary.selfName) \\in \(target.identifier(className)) : " + (try formula(term))
    }

    private func formula(_ term: OCLTerm) throws -> String {
        switch term.node {
        case .boolean(let value): return value ? "TRUE" : "FALSE"
        case .variable, .navigation:
            let value = try self.value(term)
            return conjoin(value.definedness + [value.text], with: conjunction)
        case .not(let operand): return "~\(try wrapped(operand))"
        case .binary(let op, let left, let right) where op.isLogical:
            let l = try wrapped(left)
            let r = try wrapped(right)
            switch op {
            case .and: return "\(l) /\\ \(r)"
            case .or: return "\(l) \\/ \(r)"
            case .implies: return "\(l) => \(r)"
            default: return "~(\(l) <=> \(r))"
            }
        case .binary(let op, let left, let right):
            return try compare(left, right, op == .lessOrEqual ? "=<" : op.rawValue)
        case .equality(let left, let right, let negated):
            if left.kind == .boolean {
                let text = "\(try wrapped(left)) <=> \(try wrapped(right))"
                return negated ? "~(\(text))" : text
            }
            return try compare(left, right, negated ? "#" : "=")
        case .undefined(let operand, let negated):
            let value = try self.value(operand)
            let defined = value.definedness
            if defined.isEmpty { return negated ? "TRUE" : "FALSE" }
            if value.guards.isEmpty, operand.multiplicity == .optional {
                return "\(value.text) \(negated ? "#" : "=") \(null)"
            }
            let text = conjoin(defined, with: conjunction)
            return negated ? text : "~(\(text))"
        case .isEmpty(let operand, let negated):
            if operand.multiplicity != .collection {
                return try formula(OCLTerm(.undefined(operand, negated: negated), kind: .boolean))
            }
            return "\(try set(operand)) \(negated ? "#" : "=") {}"
        case .includes(let collection, let element, let negated):
            let value = try self.value(element)
            return conjoin(value.definedness + ["\(value.text) \(negated ? "\\notin" : "\\in") \(try set(collection))"], with: conjunction)
        case .quantified(let quantifier, let variable, let source, let body):
            let name = target.identifier(variable)
            let domain = try set(source)
            switch quantifier {
            case .all: return "\\A \(name) \\in \(domain) : \(try formula(body))"
            case .some: return "\\E \(name) \\in \(domain) : \(try formula(body))"
            case .one: return "Cardinality({\(name) \\in \(domain) : \(try formula(body))}) = 1"
            }
        case .unique(let variable, let source, let body):
            let (first, second) = OCLTerm.uniquenessCopies(of: variable)
            let differ = OCLTerm(
                .equality(body.renaming(variable, to: first), body.renaming(variable, to: second), negated: true),
                kind: .boolean)
            let a = target.identifier(first)
            let b = target.identifier(second)
            return "\\A \(a), \(b) \\in \(try set(source)) : (\(a) # \(b)) => \(try wrapped(differ))"
        case .kindOf(let operand, let className):
            let value = try self.value(operand)
            return conjoin(value.definedness + ["\(value.text) \\in \(target.identifier(className))"], with: conjunction)
        case .conditional(let condition, let then, let otherwise):
            return "IF \(try formula(condition)) THEN \(try formula(then)) ELSE \(try formula(otherwise))"
        default:
            throw TranslationError("the expression cannot be written as a TLA+ formula")
        }
    }

    private func wrapped(_ term: OCLTerm) throws -> String {
        let text = try formula(term)
        if case .quantified = term.node { return "(\(text))" }
        return text.first == "(" && text.last == ")" && !text.contains(") ") ? text : "(\(text))"
    }

    private func compare(_ left: OCLTerm, _ right: OCLTerm, _ op: String) throws -> String {
        let l = try value(left)
        let r = try value(right)
        return conjoin(l.definedness + r.definedness + ["\(l.text) \(op) \(r.text)"], with: conjunction)
    }

    private func field(_ feature: FeatureInfo) -> String {
        target.feature(className: feature.owner, feature: feature.name)
    }

    private func value(_ term: OCLTerm) throws -> GuardedValue {
        switch term.node {
        case .variable(let name): return GuardedValue(text: target.identifier(name))
        case .boolean(let value): return GuardedValue(text: value ? "TRUE" : "FALSE")
        case .integer(let value): return GuardedValue(text: String(value))
        case .string(let value):
            return GuardedValue(text: target.stringLiteral(value))
        case .enumLiteral(let enumeration, let literal):
            return GuardedValue(text: target.literal(enumeration: enumeration, literal: literal))
        case .navigation(let source, let feature):
            let base = try value(source)
            let text = "obj[\(base.text)].\(field(feature))"
            return GuardedValue(text: text, guards: base.definedness, presence: feature.isOptional ? "\(text) # \(null)" : nil)
        case .negate(let operand):
            let base = try value(operand)
            return GuardedValue(text: "-\(base.text)", guards: base.definedness)
        case .binary(let op, let left, let right) where !op.isLogical && !op.isComparison:
            let l = try value(left)
            let r = try value(right)
            let symbols: [BinaryOperator: String] = [.add: "+", .subtract: "-", .multiply: "*", .divide: "\\div", .modulo: "%"]
            return GuardedValue(text: "(\(l.text) \(symbols[op]!) \(r.text))", guards: l.definedness + r.definedness)
        case .size(let operand): return GuardedValue(text: "Cardinality(\(try set(operand)))")
        case .conditional(let condition, let then, let otherwise):
            let t = try value(then)
            let e = try value(otherwise)
            let c = try formula(condition)
            var guards: [String] = []
            if !t.definedness.isEmpty { guards.append("(\(c)) => \(conjoin(t.definedness, with: conjunction))") }
            if !e.definedness.isEmpty { guards.append("~(\(c)) => \(conjoin(e.definedness, with: conjunction))") }
            return GuardedValue(text: "(IF \(c) THEN \(t.text) ELSE \(e.text))", guards: guards)
        case .not, .binary, .equality, .undefined, .isEmpty, .includes, .quantified, .unique, .kindOf:
            return GuardedValue(text: try formula(term))
        default:
            throw TranslationError("a collection is used where a single value is expected")
        }
    }

    private func set(_ term: OCLTerm) throws -> String {
        switch term.node {
        case .navigation(let source, let feature) where feature.isMany:
            let base = try value(source)
            let text = "obj[\(base.text)].\(field(feature))"
            let defined = base.definedness
            return defined.isEmpty ? text : "(IF \(conjoin(defined, with: conjunction)) THEN \(text) ELSE {})"
        case .collectedNavigation(let source, let feature):
            let element = "x_"
            let image = "{obj[\(element)].\(field(feature)) : \(element) \\in \(try set(source))}"
            if feature.isMany { return "UNION \(image)" }
            return feature.isOptional ? "(\(image) \\ {\(null)})" : image
        case .filtered(let variable, let source, let body, let keeps):
            let condition = keeps ? try formula(body) : "~\(try wrapped(body))"
            return "{\(target.identifier(variable)) \\in \(try set(source)) : \(condition)}"
        case .allInstances(let className): return target.identifier(className)
        default:
            let single = try value(term)
            let defined = single.definedness
            return defined.isEmpty ? "{\(single.text)}" : "(IF \(conjoin(defined, with: conjunction)) THEN {\(single.text)} ELSE {})"
        }
    }
}
