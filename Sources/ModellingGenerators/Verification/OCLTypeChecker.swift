//
// OCLTypeChecker.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import Foundation

/// The reason why an invariant cannot be exported.
struct TranslationError: Error, Equatable, CustomStringConvertible, Sendable {
    /// A description of the construct that is outside the translatable subset.
    let reason: String

    /// Creates an error.
    ///
    /// - Parameter reason: A description of the construct that cannot be translated.
    init(_ reason: String) { self.reason = reason }

    /// The reason, as text.
    var description: String { reason }
}

/// Parses OCL invariants and checks them against a metamodel.
///
/// OCL is parsed with the AQL parser, whose grammar follows OCL for the translatable subset:
/// navigation, the logical, comparison and integer operators, `if`, `let`, enumeration literals,
/// the collection operations `size`, `isEmpty`, `notEmpty`, `includes`, `excludes`, `forAll`,
/// `exists`, `one`, `select`, `reject`, `collect` of a navigation, and `isUnique`, and the
/// operations `oclIsKindOf`, `oclAsType`, `oclIsUndefined` and `allInstances`. Anything else,
/// such as string and real number operations, operation calls, tuples and `iterate`, is reported
/// as a ``TranslationError``.
struct OCLTypeChecker: Sendable {
    /// The metamodel that navigations are resolved against.
    let index: MetamodelIndex

    /// Creates a type checker.
    ///
    /// - Parameter index: The metamodel.
    init(index: MetamodelIndex) { self.index = index }

    /// Parses and checks the body of an invariant.
    ///
    /// - Parameters:
    ///   - text: The OCL text of the invariant.
    ///   - className: The class that the invariant constrains, which is the type of `self`.
    /// - Returns: The typed term, which denotes a truth value.
    /// - Throws: ``TranslationError`` if the text cannot be parsed or is outside the subset.
    func check(_ text: String, context className: String) throws -> OCLTerm {
        let parsed = AQLParser().parse(text)
        guard let expression = parsed.expression else {
            let message = parsed.diagnostics.first?.message ?? "the text is not an expression"
            throw TranslationError("the invariant cannot be parsed: \(message)")
        }
        let term = try check(
            expression,
            environment: [VerificationVocabulary.selfName: OCLTerm(.variable(VerificationVocabulary.selfName), kind: .object(className))])
        guard term.kind == .boolean, term.multiplicity != .collection else {
            throw TranslationError("the invariant does not denote a truth value")
        }
        return term
    }

    private typealias Environment = [String: OCLTerm]

    private func check(_ expression: any AQLExpression, environment: Environment) throws -> OCLTerm {
        switch expression {
        case let variable as AQLVariableExpression:
            guard let bound = environment[variable.name] else {
                throw TranslationError("the name '\(variable.name)' is not a variable")
            }
            return bound
        case let literal as AQLLiteralExpression:
            return try checkLiteral(literal)
        case let navigation as AQLNavigationExpression:
            return try navigate(try check(navigation.source, environment: environment), navigation.property)
        case let unary as AQLUnaryExpression:
            let operand = try check(unary.operand, environment: environment)
            switch unary.op {
            case .not:
                try expect(operand, .boolean, "not")
                return OCLTerm(.not(operand), kind: .boolean)
            case .negate:
                try expect(operand, .integer, "-")
                return OCLTerm(.negate(operand), kind: .integer)
            }
        case let binary as AQLBinaryExpression:
            return try checkBinary(binary, environment: environment)
        case let enumeration as AQLEnumLiteralExpression:
            return try enumLiteral(enumeration.enumName, enumeration.literal)
        case let type as AQLTypeLiteralExpression:
            if let packageName = type.packageName, index.enumerations[packageName] != nil {
                return try enumLiteral(packageName, type.typeName)
            }
            throw TranslationError("the type '\(type.typeName)' is used as a value")
        case let conditional as AQLConditionalExpression:
            let condition = try check(conditional.condition, environment: environment)
            try expect(condition, .boolean, "if")
            let then = try check(conditional.thenExpression, environment: environment)
            let otherwise = try check(conditional.elseExpression, environment: environment)
            guard then.kind == otherwise.kind, then.multiplicity != .collection,
                otherwise.multiplicity != .collection, then.kind == .boolean || then.kind == .integer
            else { throw TranslationError("only truth values and integers can be chosen by 'if'") }
            return OCLTerm(.conditional(condition, then, otherwise), kind: then.kind)
        case let binding as AQLLetExpression:
            var inner = environment
            for (name, value) in binding.bindings {
                inner[name] = try check(value, environment: inner)
            }
            return try check(binding.body, environment: inner)
        case let collection as AQLCollectionExpression:
            return try checkCollection(collection, environment: environment)
        case let call as AQLCallExpression:
            return try checkCall(call, environment: environment)
        default:
            throw TranslationError("the expression '\(type(of: expression))' is outside the translatable subset")
        }
    }

    private func checkLiteral(_ literal: AQLLiteralExpression) throws -> OCLTerm {
        switch literal.value {
        case let value as Bool: return OCLTerm(.boolean(value), kind: .boolean)
        case let value as Int: return OCLTerm(.integer(value), kind: .integer)
        case let value as String: return OCLTerm(.string(value), kind: .string)
        case nil: throw TranslationError("'null' is only supported in comparisons with '=' and '<>'")
        default: throw TranslationError("real number literals are not supported")
        }
    }

    private func enumLiteral(_ enumeration: String, _ literal: String) throws -> OCLTerm {
        guard let literals = index.enumerations[enumeration], literals.contains(literal) else {
            throw TranslationError("'\(enumeration)::\(literal)' is not an enumeration literal")
        }
        return OCLTerm(.enumLiteral(enumeration: enumeration, literal: literal), kind: .enumeration(enumeration))
    }

    private func navigate(_ source: OCLTerm, _ property: String) throws -> OCLTerm {
        guard case .object(let className) = source.kind else {
            throw TranslationError("'\(property)' is applied to a value that is not an object")
        }
        guard let feature = index.feature(named: property, in: className) else {
            throw TranslationError("'\(className)' has no feature '\(property)'")
        }
        guard !feature.isDerived else {
            throw TranslationError("the derived feature '\(property)' is not exported")
        }
        if case .uninterpreted(let name) = feature.kind {
            throw TranslationError("values of the data type '\(name)' are not interpreted")
        }
        if source.multiplicity == .collection {
            guard feature.isReference else {
                throw TranslationError("collecting the attribute '\(property)' would need a bag")
            }
            return OCLTerm(.collectedNavigation(source, feature), kind: feature.kind, multiplicity: .collection)
        }
        let multiplicity: Multiplicity
        if feature.isMany {
            multiplicity = .collection
        } else if feature.isOptional || source.multiplicity == .optional {
            multiplicity = .optional
        } else {
            multiplicity = .required
        }
        return OCLTerm(.navigation(source, feature), kind: feature.kind, multiplicity: multiplicity)
    }

    private func checkBinary(_ binary: AQLBinaryExpression, environment: Environment) throws -> OCLTerm {
        if binary.op == .equals || binary.op == .notEquals {
            let negated = binary.op == .notEquals
            if isNull(binary.right) {
                return OCLTerm(.undefined(try single(binary.left, environment), negated: negated), kind: .boolean)
            }
            if isNull(binary.left) {
                return OCLTerm(.undefined(try single(binary.right, environment), negated: negated), kind: .boolean)
            }
            let left = try single(binary.left, environment)
            let right = try single(binary.right, environment)
            guard compatible(left.kind, right.kind) else {
                throw TranslationError("values of different types are compared")
            }
            return OCLTerm(.equality(left, right, negated: negated), kind: .boolean)
        }
        let left = try single(binary.left, environment)
        let right = try single(binary.right, environment)
        let op: BinaryOperator
        switch binary.op {
        case .add: op = .add
        case .subtract: op = .subtract
        case .multiply: op = .multiply
        case .div: op = .divide
        case .mod: op = .modulo
        case .divide: throw TranslationError("real division '/' is not supported; use 'div'")
        case .lessThan: op = .less
        case .lessOrEqual: op = .lessOrEqual
        case .greaterThan: op = .greater
        case .greaterOrEqual: op = .greaterOrEqual
        case .and: op = .and
        case .or: op = .or
        case .xor: op = .xor
        case .implies: op = .implies
        case .equals, .notEquals: fatalError("handled above")
        }
        let operandKind: ValueKind = op.isLogical ? .boolean : .integer
        try expect(left, operandKind, op.rawValue)
        try expect(right, operandKind, op.rawValue)
        let kind: ValueKind = op.isLogical || op.isComparison ? .boolean : .integer
        return OCLTerm(.binary(op, left, right), kind: kind)
    }

    private func compatible(_ left: ValueKind, _ right: ValueKind) -> Bool {
        if case .object(let a) = left, case .object(let b) = right {
            return index.conforms(a, to: b) || index.conforms(b, to: a)
                || !Set(index.concreteSubclasses(of: a)).isDisjoint(with: index.concreteSubclasses(of: b))
        }
        return left == right
    }

    private func isNull(_ expression: any AQLExpression) -> Bool {
        guard let literal = expression as? AQLLiteralExpression else { return false }
        return literal.value == nil
    }

    private func single(_ expression: any AQLExpression, _ environment: Environment) throws -> OCLTerm {
        let term = try check(expression, environment: environment)
        guard term.multiplicity != .collection else {
            throw TranslationError("a collection is used where a single value is expected")
        }
        return term
    }

    private func expect(_ term: OCLTerm, _ kind: ValueKind, _ operation: String) throws {
        guard term.kind == kind, term.multiplicity != .collection else {
            throw TranslationError("'\(operation)' is applied to a value of an unsupported type")
        }
    }

    private func checkCollection(_ collection: AQLCollectionExpression, environment: Environment) throws -> OCLTerm {
        let source = try check(collection.source, environment: environment)
        switch collection.operation {
        case .size:
            guard source.multiplicity == .collection || source.kind != .string else {
                throw TranslationError("string operations are not supported")
            }
            return OCLTerm(.size(source), kind: .integer)
        case .isEmpty:
            return OCLTerm(.isEmpty(source, negated: false), kind: .boolean)
        case .notEmpty:
            return OCLTerm(.isEmpty(source, negated: true), kind: .boolean)
        case .forAll, .exists, .select, .reject, .collect:
            guard let iterator = collection.iterator, let body = collection.body else {
                throw TranslationError("'\(collection.operation.rawValue)' needs a body")
            }
            return try iterate(collection.operation.rawValue, source: source, iterator: iterator, body: body, environment: environment)
        default:
            throw TranslationError("the collection operation '\(collection.operation.rawValue)' is not supported")
        }
    }

    private func iterate(
        _ name: String, source: OCLTerm, iterator: String, body: any AQLExpression, environment: Environment
    ) throws -> OCLTerm {
        guard case .object = source.kind else {
            throw TranslationError("'\(name)' over values that are not objects is not supported")
        }
        var inner = environment
        inner[iterator] = OCLTerm(.variable(iterator), kind: source.kind)
        let checked = try check(body, environment: inner)
        switch name {
        case "forAll", "exists", "one":
            try expect(checked, .boolean, name)
            let quantifier: Quantifier = name == "forAll" ? .all : (name == "exists" ? .some : .one)
            return OCLTerm(.quantified(quantifier, variable: iterator, source: source, body: checked), kind: .boolean)
        case "select", "reject":
            try expect(checked, .boolean, name)
            return OCLTerm(
                .filtered(variable: iterator, source: source, body: checked, keeps: name == "select"),
                kind: source.kind, multiplicity: .collection)
        case "isUnique":
            guard checked.multiplicity != .collection else {
                throw TranslationError("'isUnique' needs a body with a single value")
            }
            return OCLTerm(.unique(variable: iterator, source: source, body: checked), kind: .boolean)
        case "collect":
            guard case .navigation(let base, let feature) = checked.node, case .variable(iterator) = base.node,
                feature.isReference
            else { throw TranslationError("'collect' is only supported for navigating a reference") }
            return OCLTerm(.collectedNavigation(source, feature), kind: feature.kind, multiplicity: .collection)
        default:
            throw TranslationError("the collection operation '\(name)' is not supported")
        }
    }

    private func checkCall(_ call: AQLCallExpression, environment: Environment) throws -> OCLTerm {
        let name = call.methodName
        if name == "allInstances", let source = call.source, let className = typeName(source, environment) {
            return OCLTerm(.allInstances(className), kind: .object(className), multiplicity: .collection)
        }
        guard let sourceExpression = call.source else {
            throw TranslationError("the operation '\(name)' is not supported")
        }
        let source = try check(sourceExpression, environment: environment)
        switch name {
        case "oclIsKindOf", "oclAsType":
            guard call.arguments.count == 1, let className = typeName(call.arguments[0], environment),
                index.classes[className] != nil
            else { throw TranslationError("'\(name)' needs the name of a class") }
            guard case .object = source.kind, source.multiplicity != .collection else {
                throw TranslationError("'\(name)' is applied to a value that is not an object")
            }
            if name == "oclAsType" {
                return OCLTerm(source.node, kind: .object(className), multiplicity: source.multiplicity)
            }
            return OCLTerm(.kindOf(source, className), kind: .boolean)
        case "oclIsUndefined":
            guard source.multiplicity != .collection else {
                throw TranslationError("'oclIsUndefined' is applied to a collection")
            }
            return OCLTerm(.undefined(source, negated: false), kind: .boolean)
        case "includes", "excludes":
            guard call.arguments.count == 1 else { throw TranslationError("'\(name)' needs one argument") }
            let element = try single(call.arguments[0], environment)
            guard compatible(element.kind, source.kind) else {
                throw TranslationError("'\(name)' compares values of different types")
            }
            return OCLTerm(.includes(source, element, negated: name == "excludes"), kind: .boolean)
        case "one", "isUnique", "forAll", "exists", "select", "reject", "collect":
            guard call.arguments.count == 1, let lambda = call.arguments[0] as? AQLLambdaExpression,
                lambda.iterators.count == 1
            else { throw TranslationError("'\(name)' needs a body with one iterator") }
            return try iterate(name, source: source, iterator: lambda.iterators[0], body: lambda.body, environment: environment)
        case "size", "isEmpty", "notEmpty":
            if source.kind == .string && source.multiplicity != .collection {
                throw TranslationError("string operations are not supported")
            }
            throw TranslationError("'\(name)' is not supported here")
        default:
            if source.kind == .string { throw TranslationError("string operations are not supported") }
            throw TranslationError("the operation '\(name)' is not supported")
        }
    }

    private func typeName(_ expression: any AQLExpression, _ environment: Environment) -> String? {
        if let type = expression as? AQLTypeLiteralExpression { return type.typeName }
        if let variable = expression as? AQLVariableExpression, environment[variable.name] == nil,
            index.classes[variable.name] != nil
        {
            return variable.name
        }
        return nil
    }
}
