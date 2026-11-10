//
//  AQLFootprintExtractor.swift
//  ModelTyping
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import AQL
import ECore
import EMFBase

/// Extracts the metamodel footprint of AQL expressions.
///
/// The extractor infers static types along the expression: variables typed by
/// the caller, navigations, iterator bodies, type literals, casts, type filters,
/// `allInstances` and the standard services with well-known result types. Every
/// class, feature and enumeration literal reached this way is recorded with read
/// access. Where a type cannot be inferred, the uses that can still be identified
/// are recorded as uncertain and the gap is reported.
public struct AQLFootprintExtractor: Sendable {
    /// The metamodels the expressions were written against.
    public let bindings: [MetamodelBinding]

    /// Creates an extractor.
    ///
    /// - Parameter bindings: The metamodels the expressions were written against, in lookup order.
    public init(bindings: [MetamodelBinding]) {
        self.bindings = bindings
    }

    /// Extracts the footprint of an expression.
    ///
    /// - Parameters:
    ///   - expression: The parsed expression.
    ///   - variables: The written types of the free variables, such as `["self": "library::Library"]`.
    /// - Returns: The footprint.
    public func footprint(of expression: any AQLExpression, variables: [String: String] = [:]) -> Footprint {
        let walker = AQLTypeWalker(recorder: FootprintRecorder(bindings: bindings))
        let scope = walker.scope(declaring: variables)
        _ = walker.visit(expression, in: scope)
        return walker.recorder.footprint
    }

    /// Parses an expression and extracts its footprint.
    ///
    /// - Parameters:
    ///   - source: The AQL expression text.
    ///   - variables: The written types of the free variables.
    /// - Returns: The footprint.
    /// - Throws: ``FootprintExtractionError/parseFailed(_:)`` if the expression cannot be parsed.
    public func footprint(ofSource source: String, variables: [String: String] = [:]) throws -> Footprint {
        let result = AQLParser().parse(source)
        guard let expression = result.expression else {
            throw FootprintExtractionError.parseFailed(result.diagnostics.map(\.message).joined(separator: "; "))
        }
        return footprint(of: expression, variables: variables)
    }
}

/// A problem that prevents footprint extraction.
public enum FootprintExtractionError: Error, Sendable, Hashable {
    /// The module or expression could not be parsed; the associated text describes why.
    case parseFailed(String)
}

/// The variables visible at a point of an AQL expression.
struct AQLScope {
    /// The static types of the bound variables.
    var variables: [String: StaticType] = [:]

    /// Returns a scope with an additional variable binding.
    func binding(_ name: String, to type: StaticType) -> AQLScope {
        var scope = self
        scope.variables[name] = type
        return scope
    }
}

/// Visits AQL expressions, inferring static types and recording the footprint.
///
/// Hosting languages such as MTL extend AQL with their own expression nodes;
/// they subclass the walker and override ``visitExtension(_:in:)``.
class AQLTypeWalker {
    /// The recorder that accumulates the footprint.
    var recorder: FootprintRecorder

    /// Creates a walker.
    init(recorder: FootprintRecorder) {
        self.recorder = recorder
    }

    /// Builds a scope from written variable types.
    func scope(declaring variables: [String: String]) -> AQLScope {
        var scope = AQLScope()
        for (name, written) in variables.sorted(by: { $0.key < $1.key }) {
            scope.variables[name] = recorder.resolve(written: written, access: .read, at: nil)
        }
        return scope
    }

    /// Visits an expression node of a hosting language.
    ///
    /// - Returns: The static type of the node, or `nil` if the node is not recognised.
    func visitExtension(_ expression: any AQLExpression, in scope: AQLScope) -> StaticType? { nil }

    /// Visits an expression and returns its static type.
    func visit(_ expression: any AQLExpression, in scope: AQLScope) -> StaticType {
        switch expression {
        case let node as AQLVariableExpression:
            return variable(node.name, in: scope, at: node.origin)
        case let node as AQLNavigationExpression:
            let source = visit(node.source, in: scope)
            return recorder.navigate(source, feature: node.property, access: .read, at: node.origin)
        case let node as AQLLiteralExpression:
            return Self.literalType(node.value)
        case is AQLStringInterpolationExpression:
            return .dataValue(CanonicalDataType.string.rawValue)
        case let node as AQLCallExpression:
            return call(node, in: scope)
        case let node as AQLCollectionExpression:
            return collection(node, in: scope)
        case let node as AQLBinaryExpression:
            let left = visit(node.left, in: scope)
            _ = visit(node.right, in: scope)
            switch node.op {
            case .add, .subtract, .multiply, .divide, .mod, .div: return left
            default: return .dataValue(CanonicalDataType.boolean.rawValue)
            }
        case let node as AQLUnaryExpression:
            let operand = visit(node.operand, in: scope)
            return node.op == .not ? .dataValue(CanonicalDataType.boolean.rawValue) : operand
        case let node as AQLConditionalExpression:
            _ = visit(node.condition, in: scope)
            let then = visit(node.thenExpression, in: scope)
            let otherwise = visit(node.elseExpression, in: scope)
            return then == otherwise ? then : .unknown
        case let node as AQLLetExpression:
            var inner = scope
            for (name, value) in node.bindings {
                inner = inner.binding(name, to: visit(value, in: inner))
            }
            return visit(node.body, in: inner)
        case let node as AQLLambdaExpression:
            var inner = scope
            for iterator in node.iterators { inner = inner.binding(iterator, to: .unknown) }
            _ = visit(node.body, in: inner)
            return .unknown
        case let node as AQLCollectionLiteralExpression:
            let types = node.elements.map { visit($0, in: scope) }
            return .collection(Set(types).count == 1 ? types[0] : .unknown)
        case let node as AQLEnumLiteralExpression:
            let metamodel = node.packageName.flatMap { recorder.metamodel(forQualifier: $0) }
            let resolvedMetamodel = metamodel ?? recorder.bindings.first {
                $0.modelType.enumerations[node.enumName] != nil
            }?.name
            recorder.literal(node.literal, enumeration: node.enumName, metamodel: resolvedMetamodel,
                             access: .read, at: node.origin)
            return resolvedMetamodel.map { .enumeration(metamodel: $0, name: node.enumName) } ?? .unknown
        case let node as AQLTypeLiteralExpression:
            let type = recorder.resolveClassifier(
                qualifier: node.packageName, name: node.typeName, access: .read, at: node.origin)
            if case .object(let metamodel, let className) = type {
                return .typeLiteral(metamodel: metamodel, className: className)
            }
            return type
        default:
            if let type = visitExtension(expression, in: scope) { return type }
            recorder.note(.unknownOperation, "unsupported expression kind '\(type(of: expression))'", at: expression.origin)
            return .unknown
        }
    }

    /// Resolves a variable, treating an unbound name inside an implicit iterator as a feature of `self`.
    func variable(_ name: String, in scope: AQLScope, at origin: SourceOrigin) -> StaticType {
        if let type = scope.variables[name] { return type }
        if let receiver = scope.variables[ModelTypingVocabulary.selfVariable] {
            return recorder.navigate(receiver, feature: name, access: .read, at: origin)
        }
        recorder.note(.unknownVariable, "variable '\(name)' is not bound", at: origin)
        return .unknown
    }

    /// The static type of a literal value.
    static func literalType(_ value: (any EcoreValue)?) -> StaticType {
        switch value {
        case is String: return .dataValue(CanonicalDataType.string.rawValue)
        case is Bool: return .dataValue(CanonicalDataType.boolean.rawValue)
        case is Int: return .dataValue(CanonicalDataType.integer32.rawValue)
        case is Double: return .dataValue(CanonicalDataType.real64.rawValue)
        default: return .unknown
        }
    }

    /// Visits a dedicated collection operation node.
    private func collection(_ node: AQLCollectionExpression, in scope: AQLScope) -> StaticType {
        let source = visit(node.source, in: scope)
        let element = source.elementType
        var bodyType = StaticType.unknown
        if let body = node.body {
            let inner = node.iterator.map { scope.binding($0, to: element) } ?? scope
            bodyType = visit(body, in: inner)
        }
        switch node.operation {
        case .select, .reject, .sortedBy, .closure: return .collection(element)
        case .collect: return bodyType.isUnknown ? .unknown : bodyType.flattenedCollection
        case .any, .first, .last: return element
        case .forAll, .exists, .isEmpty, .notEmpty, .one, .isUnique:
            return .dataValue(CanonicalDataType.boolean.rawValue)
        case .size, .indexOf: return .dataValue(CanonicalDataType.integer32.rawValue)
        }
    }

    /// Visits a service call.
    func call(_ node: AQLCallExpression, in scope: AQLScope) -> StaticType {
        let source = node.source.map { visit($0, in: scope) }
        var argumentTypes: [StaticType] = []
        var lambdaTypes: [StaticType] = []
        for argument in node.arguments {
            if let lambda = argument as? AQLLambdaExpression {
                var inner = scope
                for iterator in lambda.iterators { inner = inner.binding(iterator, to: source?.elementType ?? .unknown) }
                lambdaTypes.append(visit(lambda.body, in: inner))
            } else {
                argumentTypes.append(visit(argument, in: scope))
            }
        }
        return Self.resultType(
            of: node.methodName, source: source, arguments: argumentTypes, lambdaBodies: lambdaTypes,
            recorder: &recorder, at: node.origin)
    }

    /// The result type of a standard operation, recording the classes it enumerates.
    ///
    /// The table is shared by the AQL and ATL walkers.
    static func resultType(
        of name: String, source: StaticType?, arguments: [StaticType], lambdaBodies: [StaticType],
        recorder: inout FootprintRecorder, at origin: SourceOrigin?
    ) -> StaticType {
        let vocabulary = ModelTypingVocabulary.self
        let typeArgument: StaticType? = arguments.first.flatMap {
            if case .typeLiteral(let metamodel, let className) = $0 {
                return .object(metamodel: metamodel, className: className)
            }
            return nil
        }
        if vocabulary.allInstancesOperations.contains(name) {
            if case .typeLiteral(let metamodel, let className)? = source {
                recorder.recordClass(className, in: metamodel, Usage(.read))
                return .collection(.object(metamodel: metamodel, className: className))
            }
            recorder.note(.unknownReceiverType, "'\(name)' applied to an expression that is not a known type", at: origin)
            return .unknown
        }
        if vocabulary.typeTestOperations.contains(name) || vocabulary.booleanOperations.contains(name) {
            return .dataValue(CanonicalDataType.boolean.rawValue)
        }
        if vocabulary.typeCastOperations.contains(name) { return typeArgument ?? .unknown }
        if vocabulary.typeFilterOperations.contains(name) { return typeArgument.map { .collection($0) } ?? .unknown }
        if vocabulary.typedTraversalOperations.contains(name) {
            return .collection(typeArgument ?? .unknown)
        }
        if vocabulary.containerOperations.contains(name) { return typeArgument ?? .unknown }
        let element = source?.elementType ?? .unknown
        if vocabulary.elementPreservingIterators.contains(name) || vocabulary.elementPreservingOperations.contains(name) {
            return source == nil ? .unknown : .collection(element)
        }
        if vocabulary.collectingIterators.contains(name) {
            guard let body = lambdaBodies.first, !body.isUnknown else { return .unknown }
            return body.flattenedCollection
        }
        if vocabulary.elementSelectingIterators.contains(name) || vocabulary.elementSelectingOperations.contains(name) {
            return element
        }
        if vocabulary.flatteningOperations.contains(name) { return source == nil ? .unknown : .collection(element) }
        if vocabulary.integerOperations.contains(name) { return .dataValue(CanonicalDataType.integer32.rawValue) }
        if vocabulary.stringOperations.contains(name) { return .dataValue(CanonicalDataType.string.rawValue) }
        return .unknown
    }
}
