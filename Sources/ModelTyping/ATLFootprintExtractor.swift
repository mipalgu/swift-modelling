//
//  ATLFootprintExtractor.swift
//  ModelTyping
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import ATL
import EMFBase

/// Extracts the metamodel footprints of ATL transformation modules and queries.
///
/// Source pattern types, helper context types and type literals are recorded
/// as read classes of the source metamodels; target pattern types are recorded
/// as instantiated classes, and property bindings and `do` block assignments as
/// written features of the target metamodels. Navigations in guards, bindings,
/// local variables, helpers and imperative blocks are typed statically: helper
/// attributes and operations are resolved by name and context type and typed
/// by their declared return types, so that they are not mistaken for features.
/// Enumeration literals (`#literal`) are attributed by the type of the feature
/// they are bound to or compared with.
public struct ATLFootprintExtractor: Sendable {
    /// The required metamodels, indexed by the metamodel names of the module header.
    public let metamodels: [String: ModelType]

    /// Creates an extractor.
    ///
    /// - Parameter metamodels: The required metamodels, indexed by the metamodel names
    ///   of the module header (for example `Families` in `IN : Families`).
    public init(metamodels: [String: ModelType]) {
        self.metamodels = metamodels
    }

    /// The part each metamodel of a module header plays.
    ///
    /// Metamodels of source models are read, metamodels of target models are
    /// written, and a metamodel of both (or of a refining module) is both.
    ///
    /// - Parameter module: The module.
    /// - Returns: The role of each metamodel, indexed by metamodel name.
    public static func roles(of module: ATLModule) -> [String: MetamodelRole] {
        var roles: [String: MetamodelRole] = [:]
        let names = module.declaredMetamodelNames
        for alias in module.sourceMetamodels.keys { roles[names[alias] ?? alias] = .source }
        for alias in module.targetMetamodels.keys {
            let name = names[alias] ?? alias
            roles[name] = roles[name] == nil ? .target : .sourceAndTarget
        }
        if module.isRefining {
            for name in roles.keys { roles[name] = .sourceAndTarget }
        }
        for name in names.values where roles[name] == nil { roles[name] = .source }
        return roles
    }

    /// Extracts the footprint of a module.
    ///
    /// Only metamodels that the module header names and that were given to the
    /// extractor are recorded; metamodels in the header without a model type
    /// are reported as uncertainties.
    ///
    /// - Parameter module: The parsed module.
    /// - Returns: The footprint.
    public func footprint(of module: ATLModule) -> Footprint {
        let roles = Self.roles(of: module)
        let ordered = roles.keys.sorted { lhs, rhs in
            let order: [MetamodelRole] = [.source, .sourceAndTarget, .target]
            let left = order.firstIndex(of: roles[lhs]!)!, right = order.firstIndex(of: roles[rhs]!)!
            return left == right ? lhs < rhs : left < right
        }
        var bindings: [MetamodelBinding] = []
        for name in ordered {
            if let modelType = metamodels[name] {
                bindings.append(MetamodelBinding(name: name, modelType: modelType, role: roles[name]!))
            }
        }
        let walker = ATLTypeWalker(recorder: FootprintRecorder(bindings: bindings), module: module)
        for name in ordered where metamodels[name] == nil {
            walker.recorder.note(.unknownType, "no model type was given for metamodel '\(name)'", at: module.origin)
        }
        walker.visitModule()
        return walker.recorder.footprint
    }

    /// Parses a module and extracts its footprint.
    ///
    /// - Parameter source: The ATL module text.
    /// - Returns: The footprint.
    /// - Throws: ``FootprintExtractionError/parseFailed(_:)`` if the module cannot be parsed.
    public func footprint(ofSource source: String) async throws -> Footprint {
        do {
            let module = try await ATLParser(options: .standard).parseContent(
                source, filename: "module.atl")
            return footprint(of: module)
        } catch {
            throw FootprintExtractionError.parseFailed(String(describing: error))
        }
    }
}

/// The signature of an ATL helper as needed for typing calls.
struct ATLHelperSignature {
    /// The resolved context type, or `nil` for a module-level helper.
    let context: StaticType?
    /// The helper as declared.
    let helper: any ATLHelperType
}

/// Visits an ATL module, inferring static types and recording the footprint.
final class ATLTypeWalker {
    /// The recorder that accumulates the footprint.
    var recorder: FootprintRecorder
    /// The module being visited.
    let module: ATLModule
    /// The helper signatures, indexed by helper name.
    private var helpers: [String: [ATLHelperSignature]] = [:]

    /// The roles of metamodels whose features can be written.
    private static let writableRoles: Set<MetamodelRole> = [.target, .sourceAndTarget]

    /// Creates a walker for a module.
    init(recorder: FootprintRecorder, module: ATLModule) {
        self.recorder = recorder
        self.module = module
        for (name, overloads) in module.helperOverloads {
            helpers[name] = overloads.map { helper in
                ATLHelperSignature(
                    context: helper.contextType.map { self.recorder.resolve(written: $0, access: .read, at: helper.origin) },
                    helper: helper)
            }
        }
    }

    /// Visits every helper, rule and query body of the module.
    func visitModule() {
        let variables = [ModelTypingVocabulary.thisModuleVariable: StaticType.module]
        for signatures in helpers.values.sorted(by: { $0[0].helper.name < $1[0].helper.name }) {
            for signature in signatures {
                var scope = variables
                if let context = signature.context { scope[ModelTypingVocabulary.selfVariable] = context }
                for parameter in signature.helper.parameters {
                    scope[parameter.name] = recorder.resolve(written: parameter.type, access: .read, at: parameter.origin)
                }
                if let body = signature.helper.expressionBody { _ = visit(body, in: scope) }
            }
        }
        for rule in module.matchedRules {
            var scope = variables
            for pattern in rule.sourcePatterns {
                scope[pattern.variableName] = recorder.resolve(written: pattern.type, access: .read, at: pattern.origin)
            }
            for pattern in rule.sourcePatterns {
                if let guardExpression = pattern.guard { _ = visit(guardExpression, in: scope) }
            }
            if let guardExpression = rule.guard { _ = visit(guardExpression, in: scope) }
            scope = visitLocals(rule.localVariables, in: scope)
            scope = visitTargets(rule.targetPatterns, in: scope)
            _ = visit(rule.doStatements, in: scope)
        }
        for rule in module.calledRules.values {
            var scope = variables
            for parameter in rule.parameters {
                scope[parameter.name] = recorder.resolve(written: parameter.type, access: .read, at: parameter.origin)
            }
            if let guardExpression = rule.guard { _ = visit(guardExpression, in: scope) }
            scope = visitLocals(rule.localVariables, in: scope)
            scope = visitTargets(rule.targetPatterns, in: scope)
            _ = visit(rule.body, in: scope)
        }
        if let query = module.queryBody { _ = visit(query, in: variables) }
    }

    /// Binds the `using` variables of a rule.
    private func visitLocals(_ locals: [ATLLocalVariable], in scope: [String: StaticType]) -> [String: StaticType] {
        var scope = scope
        for local in locals {
            let value = visit(local.expression, in: scope)
            scope[local.name] = declared(local.type, inferred: value, at: local.origin)
        }
        return scope
    }

    /// Records the instantiated classes and written features of target patterns.
    private func visitTargets(_ patterns: [ATLTargetPattern], in scope: [String: StaticType]) -> [String: StaticType] {
        var scope = scope
        for pattern in patterns {
            scope[pattern.variableName] = recorder.resolve(written: pattern.type, access: .instantiate, at: pattern.origin)
        }
        for pattern in patterns {
            let target = scope[pattern.variableName] ?? .unknown
            for binding in pattern.bindings {
                let expected = recorder.navigate(target, feature: binding.property, access: .write,
                                                 at: binding.origin, roles: Self.writableRoles)
                _ = visit(binding.expression, in: scope, expected: expected, literalAccess: .write)
            }
        }
        return scope
    }

    /// The type of a declared variable, preferring an explicit metamodel type.
    private func declared(_ written: String?, inferred: StaticType, at origin: SourceOrigin) -> StaticType {
        guard let written, !WrittenTypeName(written).isPrimitive || inferred.isUnknown else { return inferred }
        let type = recorder.resolve(written: written, access: .read, at: origin)
        return type.isUnknown ? inferred : type
    }

    // MARK: - Statements

    /// Visits imperative statements in order, threading variable declarations.
    private func visit(_ statements: [any ATLStatement], in scope: [String: StaticType]) -> [String: StaticType] {
        var scope = scope
        for statement in statements {
            switch statement {
            case let node as ATLExpressionStatement:
                _ = visit(node.expression, in: scope)
            case let node as ATLVariableDeclarationStatement:
                let value = node.initialiser.map { visit($0, in: scope) } ?? .unknown
                scope[node.name] = declared(node.type, inferred: value, at: node.origin)
            case let node as ATLAssignmentStatement:
                switch node.target {
                case .variable(let name):
                    _ = visit(node.value, in: scope, expected: scope[name])
                case .feature(let owner, let name):
                    let ownerType = visit(owner, in: scope)
                    let expected = recorder.navigate(ownerType, feature: name, access: .write,
                                                     at: node.origin, roles: Self.writableRoles)
                    _ = visit(node.value, in: scope, expected: expected, literalAccess: .write)
                }
            case let node as ATLConditionalStatement:
                _ = visit(node.condition, in: scope)
                _ = visit(node.thenStatements, in: scope)
                _ = visit(node.elseStatements, in: scope)
            case let node as ATLForStatement:
                let collection = visit(node.collection, in: scope)
                var inner = scope
                inner[node.variable] = collection.elementType
                _ = visit(node.body, in: inner)
            default:
                recorder.note(.unknownOperation, "unsupported statement kind '\(type(of: statement))'", at: statement.origin)
            }
        }
        return scope
    }

    // MARK: - Helpers and rules

    /// The return type of the helper of a name applicable to a receiver, if there is one.
    private func helperType(named name: String, receiver: StaticType, at origin: SourceOrigin) -> StaticType? {
        guard let signatures = helpers[name] else { return nil }
        let applicable = signatures.filter { signature in
            switch (signature.context, receiver) {
            case (nil, .module): return true
            case (nil, _), (_, .module): return false
            case (.object(let metamodel, let context)?, .object(let receiverMetamodel, let receiverClass)):
                return metamodel == receiverMetamodel
                    && (recorder.modelType(metamodel)?.conforms(receiverClass, to: context) ?? (context == receiverClass))
            case (_, .unknown): return true
            case (let context?, _): return context == receiver || context.elementType == receiver.elementType
            }
        }
        guard let signature = applicable.first else { return nil }
        return recorder.resolve(written: signature.helper.returnType, access: nil, at: origin)
    }

    /// The type created by a called rule, if a rule of that name exists.
    private func calledRuleType(named name: String, at origin: SourceOrigin) -> StaticType? {
        guard let rule = module.calledRules[name] else { return nil }
        guard let first = rule.targetPatterns.first else { return .unknown }
        return recorder.resolve(written: first.type, access: nil, at: origin)
    }

    // MARK: - Expressions

    /// Visits an expression and returns its static type.
    ///
    /// - Parameters:
    ///   - expression: The expression.
    ///   - scope: The static types of the visible variables.
    ///   - expected: The type the context expects, used to attribute enumeration literals.
    ///   - literalAccess: How enumeration literals in the expression are used.
    /// - Returns: The static type of the expression.
    func visit(
        _ expression: any ATLExpression, in scope: [String: StaticType], expected: StaticType? = nil,
        literalAccess: AccessMode = .read
    ) -> StaticType {
        switch expression {
        case let node as ATLVariableExpression:
            if let type = scope[node.name] { return type }
            recorder.note(.unknownVariable, "variable '\(node.name)' is not bound", at: node.origin)
            return .unknown
        case let node as ATLNavigationExpression:
            let source = visit(node.source, in: scope)
            if let type = helperType(named: node.property, receiver: source, at: node.origin) { return type }
            if source == .module {
                recorder.note(.unknownOperation, "module attribute '\(node.property)' is not declared", at: node.origin)
                return .unknown
            }
            return recorder.navigate(source, feature: node.property, access: .read, at: node.origin)
        case let node as ATLHelperCallExpression:
            for argument in node.arguments { _ = visit(argument, in: scope) }
            return helperType(named: node.helperName, receiver: .module, at: node.origin)
                ?? calledRuleType(named: node.helperName, at: node.origin) ?? .unknown
        case let node as ATLLiteralExpression:
            return AQLTypeWalker.literalType(node.value)
        case let node as ATLTypeLiteralExpression:
            let type = recorder.resolve(written: node.typeName, access: .read, at: node.origin)
            if case .object(let metamodel, let className) = type {
                return .typeLiteral(metamodel: metamodel, className: className)
            }
            return type
        case let node as ATLEnumLiteralExpression:
            if case .enumeration(let metamodel, let name)? = expected?.elementType {
                recorder.literal(node.name, enumeration: name, metamodel: metamodel, access: literalAccess, at: node.origin)
                return .enumeration(metamodel: metamodel, name: name)
            }
            recorder.literal(node.name, enumeration: nil, metamodel: nil, access: literalAccess, at: node.origin)
            return .unknown
        case let node as ATLBinaryExpression:
            let left: StaticType
            if node.left is ATLEnumLiteralExpression {
                let right = visit(node.right, in: scope)
                left = visit(node.left, in: scope, expected: right)
            } else {
                left = visit(node.left, in: scope)
                _ = visit(node.right, in: scope, expected: left)
            }
            switch node.operator {
            case .plus, .minus, .multiply, .divide, .modulo, .integerDivide: return left
            case .union, .intersection, .difference: return left
            default: return .dataValue(CanonicalDataType.boolean.rawValue)
            }
        case let node as ATLUnaryExpression:
            let operand = visit(node.operand, in: scope)
            return node.operator == .not ? .dataValue(CanonicalDataType.boolean.rawValue) : operand
        case let node as ATLConditionalExpression:
            _ = visit(node.condition, in: scope)
            let then = visit(node.thenExpression, in: scope, expected: expected, literalAccess: literalAccess)
            let otherwise = visit(node.elseExpression, in: scope, expected: expected, literalAccess: literalAccess)
            return then == otherwise ? then : (then.isUnknown ? otherwise : (otherwise.isUnknown ? then : .unknown))
        case let node as ATLLetExpression:
            let value = visit(node.initExpression, in: scope)
            var inner = scope
            inner[node.variableName] = declared(node.variableType, inferred: value, at: node.origin)
            return visit(node.inExpression, in: inner, expected: expected, literalAccess: literalAccess)
        case let node as ATLTupleExpression:
            for field in node.fields { _ = visit(field.value, in: scope) }
            return .unknown
        case let node as ATLMethodCallExpression:
            return call(node.methodName, receiver: node.receiver, arguments: node.arguments, in: scope, at: node.origin)
        case let node as ATLOperationExpression:
            return call(node.operationName, receiver: node.source, arguments: node.arguments, in: scope, at: node.origin)
        case let node as ATLLambdaExpression:
            var inner = scope
            for parameter in [node.parameter] + node.additionalParameters { inner[parameter] = .unknown }
            _ = visit(node.body, in: inner)
            return .unknown
        case let node as ATLIterateExpression:
            let source = visit(node.source, in: scope)
            let initial = visit(node.defaultValue, in: scope)
            var inner = scope
            inner[node.parameter] = source.elementType
            inner[node.accumulator] = declared(node.accumulatorType, inferred: initial, at: node.origin)
            _ = visit(node.body, in: inner)
            return inner[node.accumulator] ?? .unknown
        case let node as ATLCollectionExpression:
            let source = visit(node.source, in: scope)
            var bodyType = StaticType.unknown
            if let body = node.body {
                var inner = scope
                if let iterator = node.iterator { inner[iterator] = source.elementType }
                bodyType = visit(body, in: inner)
            }
            return AQLTypeWalker.resultType(
                of: node.operation.rawValue, source: source, arguments: [], lambdaBodies: [bodyType],
                recorder: &recorder, at: node.origin)
        case let node as ATLCollectionLiteralExpression:
            let types = node.elements.map { visit($0, in: scope, expected: expected, literalAccess: literalAccess) }
            return .collection(Set(types).count == 1 ? types[0] : .unknown)
        case let node as ATLCollectionRangeExpression:
            _ = visit(node.first, in: scope)
            _ = visit(node.last, in: scope)
            return .collection(.dataValue(CanonicalDataType.integer32.rawValue))
        default:
            recorder.note(.unknownOperation, "unsupported expression kind '\(type(of: expression))'", at: expression.origin)
            return .unknown
        }
    }

    /// Visits an operation call on a receiver.
    private func call(
        _ name: String, receiver: (any ATLExpression)?, arguments: [any ATLExpression],
        in scope: [String: StaticType], at origin: SourceOrigin
    ) -> StaticType {
        let source = receiver.map { visit($0, in: scope) }
        var argumentTypes: [StaticType] = []
        var lambdaTypes: [StaticType] = []
        for argument in arguments {
            if let lambda = argument as? ATLLambdaExpression {
                var inner = scope
                for parameter in [lambda.parameter] + lambda.additionalParameters {
                    inner[parameter] = source?.elementType ?? .unknown
                }
                lambdaTypes.append(visit(lambda.body, in: inner))
            } else {
                argumentTypes.append(visit(argument, in: scope))
            }
        }
        let receiverType = source ?? .module
        if let type = helperType(named: name, receiver: receiverType, at: origin) { return type }
        if receiverType == .module {
            if let type = calledRuleType(named: name, at: origin) { return type }
            return .unknown
        }
        return AQLTypeWalker.resultType(
            of: name, source: source, arguments: argumentTypes, lambdaBodies: lambdaTypes,
            recorder: &recorder, at: origin)
    }
}
