//
// OCLTerm.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// How many values an expression denotes.
enum Multiplicity: Equatable, Sendable {
    /// Exactly one value.
    case required
    /// At most one value, which may be absent.
    case optional
    /// A collection of values, which the exports treat as a set.
    case collection
}

/// The quantifiers of the translatable subset of OCL.
enum Quantifier: String, Equatable, Sendable {
    /// Every element satisfies the body (`forAll`).
    case all
    /// Some element satisfies the body (`exists`).
    case some
    /// Exactly one element satisfies the body (`one`).
    case one
}

/// The binary operators of the translatable subset of OCL, apart from equality.
enum BinaryOperator: String, Equatable, Sendable {
    /// Integer addition.
    case add = "+"
    /// Integer subtraction.
    case subtract = "-"
    /// Integer multiplication.
    case multiply = "*"
    /// Integer division (`div`).
    case divide = "div"
    /// Integer remainder (`mod`).
    case modulo = "mod"
    /// Less than.
    case less = "<"
    /// Less than or equal to.
    case lessOrEqual = "<="
    /// Greater than.
    case greater = ">"
    /// Greater than or equal to.
    case greaterOrEqual = ">="
    /// Conjunction.
    case and
    /// Disjunction.
    case or
    /// Exclusive disjunction.
    case xor
    /// Implication.
    case implies

    /// Whether the operator combines truth values.
    var isLogical: Bool { [.and, .or, .xor, .implies].contains(self) }

    /// Whether the operator compares integers.
    var isComparison: Bool { [.less, .lessOrEqual, .greater, .greaterOrEqual].contains(self) }
}

/// A typed expression of the translatable subset of OCL.
///
/// The type checker builds terms from parsed OCL, resolving every navigation against the
/// metamodel, so that the printers of the targets know the kind and multiplicity of every
/// sub-expression. Variables bound by `let` are replaced by their values.
struct OCLTerm: Sendable {
    /// The expression itself.
    let node: Node
    /// The kind of the value or of the elements that the expression denotes.
    let kind: ValueKind
    /// How many values the expression denotes.
    let multiplicity: Multiplicity

    /// Creates a typed term.
    ///
    /// - Parameters:
    ///   - node: The expression.
    ///   - kind: The kind of its values.
    ///   - multiplicity: How many values it denotes.
    init(_ node: Node, kind: ValueKind, multiplicity: Multiplicity = .required) {
        self.node = node
        self.kind = kind
        self.multiplicity = multiplicity
    }

    /// The expressions of the translatable subset of OCL.
    indirect enum Node: Sendable {
        /// A variable: `self`, an iterator or a `let` variable.
        case variable(String)
        /// A truth value literal.
        case boolean(Bool)
        /// An integer literal.
        case integer(Int)
        /// A string literal.
        case string(String)
        /// An enumeration literal.
        case enumLiteral(enumeration: String, literal: String)
        /// Navigation of a feature from one object.
        case navigation(OCLTerm, FeatureInfo)
        /// Navigation of a feature from each object of a collection, collecting the results.
        case collectedNavigation(OCLTerm, FeatureInfo)
        /// Logical negation.
        case not(OCLTerm)
        /// Integer negation.
        case negate(OCLTerm)
        /// A binary operation other than equality.
        case binary(BinaryOperator, OCLTerm, OCLTerm)
        /// Equality, or inequality if negated.
        case equality(OCLTerm, OCLTerm, negated: Bool)
        /// Whether a value is absent (`oclIsUndefined()` or `= null`), or present if negated.
        case undefined(OCLTerm, negated: Bool)
        /// The number of elements of a collection.
        case size(OCLTerm)
        /// Whether a collection is empty, or not empty if negated.
        case isEmpty(OCLTerm, negated: Bool)
        /// Whether a collection includes a value, or excludes it if negated.
        case includes(OCLTerm, OCLTerm, negated: Bool)
        /// A quantification over the elements of a collection.
        case quantified(Quantifier, variable: String, source: OCLTerm, body: OCLTerm)
        /// The elements of a collection that satisfy the body (`select`), or that do not (`reject`).
        case filtered(variable: String, source: OCLTerm, body: OCLTerm, keeps: Bool)
        /// Whether the body gives a different value for each element of a collection.
        case unique(variable: String, source: OCLTerm, body: OCLTerm)
        /// Whether an object is an instance of a class or of one of its subclasses.
        case kindOf(OCLTerm, String)
        /// All instances of a class.
        case allInstances(String)
        /// A conditional expression.
        case conditional(OCLTerm, OCLTerm, OCLTerm)
    }
}
