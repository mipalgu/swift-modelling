//
//  MTLFootprintExtractor.swift
//  ModelTyping
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import AQL
import EMFBase
import MTL

/// Extracts the metamodel footprint of MTL template modules.
///
/// The extractor visits every template, query and macro of a module (and of
/// the modules it imports or extends, if they are linked), binding the typed
/// parameters and the variables of `for` and `let` blocks, and visits every
/// embedded AQL expression as ``AQLFootprintExtractor`` does. Classes named by
/// parameter and variable types are recorded with read access. Calls of the
/// module's own queries are typed by their declared return types.
public struct MTLFootprintExtractor: Sendable {
    /// The metamodels the module was written against.
    public let bindings: [MetamodelBinding]

    /// Creates an extractor.
    ///
    /// - Parameter bindings: The metamodels the module was written against, in lookup order.
    public init(bindings: [MetamodelBinding]) {
        self.bindings = bindings
    }

    /// Extracts the footprint of a module.
    ///
    /// - Parameter module: The parsed module.
    /// - Returns: The footprint.
    public func footprint(of module: MTLModule) -> Footprint {
        let walker = MTLTypeWalker(recorder: FootprintRecorder(bindings: bindings), module: module)
        walker.visitModuleTree(module)
        return walker.recorder.footprint
    }

    /// Parses a module and extracts its footprint.
    ///
    /// - Parameter source: The MTL module text.
    /// - Returns: The footprint.
    /// - Throws: ``FootprintExtractionError/parseFailed(_:)`` if the module cannot be parsed.
    public func footprint(ofSource source: String) async throws -> Footprint {
        do {
            return footprint(of: try await MTLParser().parse(source))
        } catch {
            throw FootprintExtractionError.parseFailed(String(describing: error))
        }
    }
}

/// Visits MTL modules, extending the AQL walker with MTL invocations.
final class MTLTypeWalker: AQLTypeWalker {
    /// The return types of the queries of the visited modules, indexed by query name.
    private var queryReturnTypes: [String: String] = [:]
    /// The names of the templates of the visited modules.
    private var templateNames: Set<String> = []

    /// Creates a walker for a module.
    init(recorder: FootprintRecorder, module: MTLModule) {
        super.init(recorder: recorder)
        collectSignatures(of: module, visited: [])
    }

    /// Indexes the query and template signatures of a module and the modules it links.
    private func collectSignatures(of module: MTLModule, visited: Set<String>) {
        guard !visited.contains(module.name) else { return }
        for query in Self.queries(of: module) where queryReturnTypes[query.name] == nil {
            queryReturnTypes[query.name] = query.returnType
        }
        templateNames.formUnion(Self.templates(of: module).map(\.name))
        for linked in Self.linkedModules(of: module) {
            collectSignatures(of: linked, visited: visited.union([module.name]))
        }
    }

    /// Visits a module and the modules it imports or extends.
    func visitModuleTree(_ module: MTLModule) {
        var visited: Set<String> = []
        var pending = [module]
        while let next = pending.popLast() {
            guard visited.insert(next.name).inserted else { continue }
            visitModule(next)
            pending.append(contentsOf: Self.linkedModules(of: next))
        }
    }

    /// Every template of a module, including overloads.
    private static func templates(of module: MTLModule) -> [MTLTemplate] {
        module.templateOverloads.isEmpty ? Array(module.templates.values) : module.templateOverloads
    }

    /// Every query of a module, including overloads.
    private static func queries(of module: MTLModule) -> [MTLQuery] {
        module.queryOverloads.isEmpty ? Array(module.queries.values) : module.queryOverloads
    }

    /// The modules a module imports or extends.
    private static func linkedModules(of module: MTLModule) -> [MTLModule] {
        module.importedModules + (module.extendedModule.map { [$0] } ?? [])
    }

    /// Visits the templates, queries and macros of one module.
    private func visitModule(_ module: MTLModule) {
        for template in Self.templates(of: module) {
            let scope = parameterScope(template.parameters, at: template.origin)
            if let guardExpression = template.guard { _ = visit(guardExpression.aqlExpression, in: scope) }
            if let post = template.post {
                _ = visit(post.aqlExpression,
                          in: scope.binding(ModelTypingVocabulary.selfVariable, to: .dataValue(CanonicalDataType.string.rawValue)))
            }
            visit(template.body, in: scope)
        }
        for query in Self.queries(of: module) {
            let scope = parameterScope(query.parameters, at: query.origin)
            _ = visit(query.body.aqlExpression, in: scope)
        }
        for macro in module.macros.values {
            var scope = parameterScope(macro.parameters, at: macro.origin)
            if let bodyParameter = macro.bodyParameter {
                scope = scope.binding(bodyParameter, to: .dataValue(CanonicalDataType.string.rawValue))
            }
            visit(macro.body, in: scope)
        }
    }

    /// Binds typed parameters, recording the classes their types name.
    private func parameterScope(_ parameters: [MTLVariable], at origin: SourceOrigin) -> AQLScope {
        var scope = AQLScope()
        for parameter in parameters {
            scope = scope.binding(parameter.name, to: recorder.resolve(written: parameter.type, access: .read, at: origin))
        }
        return scope
    }

    /// The static type of a declared variable, preferring an explicit metamodel type.
    private func declaredType(_ variable: MTLVariable, inferred: StaticType, at origin: SourceOrigin) -> StaticType {
        let written = WrittenTypeName(variable.type)
        if written.isPrimitive && !inferred.isUnknown { return inferred }
        let declared = recorder.resolve(written: variable.type, access: .read, at: origin)
        return declared.isUnknown ? inferred : declared
    }

    /// Visits the statements of a block.
    private func visit(_ block: MTLBlock, in scope: AQLScope) {
        for statement in block.statements { visit(statement, in: scope) }
    }

    /// Visits one statement.
    private func visit(_ statement: any MTLStatement, in scope: AQLScope) {
        switch statement {
        case let node as MTLExpressionStatement:
            _ = visit(node.expression.aqlExpression, in: scope)
        case let node as MTLForStatement:
            let collection = visit(node.binding.initExpression.aqlExpression, in: scope)
            for part in [node.separator, node.before, node.after].compactMap({ $0 }) {
                _ = visit(part.aqlExpression, in: scope)
            }
            let element = declaredType(node.binding.variable, inferred: collection.elementType, at: node.origin)
            visit(node.body, in: scope.binding(node.binding.variable.name, to: element))
        case let node as MTLIfStatement:
            _ = visit(node.condition.aqlExpression, in: scope)
            visit(node.thenBlock, in: scope)
            for (condition, block) in node.elseIfBlocks {
                _ = visit(condition.aqlExpression, in: scope)
                visit(block, in: scope)
            }
            if let elseBlock = node.elseBlock { visit(elseBlock, in: scope) }
        case let node as MTLLetStatement:
            var inner = scope
            for binding in node.variables {
                let value = visit(binding.initExpression.aqlExpression, in: inner)
                inner = inner.binding(binding.variable.name, to: declaredType(binding.variable, inferred: value, at: node.origin))
            }
            visit(node.body, in: inner)
        case let node as MTLFileStatement:
            for part in [node.url, node.modeExpression, node.charset].compactMap({ $0 }) {
                _ = visit(part.aqlExpression, in: scope)
            }
            visit(node.body, in: scope)
        case let node as MTLProtectedArea:
            for part in [node.id, node.startTagPrefix, node.endTagPrefix].compactMap({ $0 }) {
                _ = visit(part.aqlExpression, in: scope)
            }
            visit(node.body, in: scope)
        case let node as MTLTrace:
            _ = visit(node.sourceExpression.aqlExpression, in: scope)
            visit(node.body, in: scope)
        case let node as MTLMacroInvocation:
            for argument in node.arguments { _ = visit(argument.aqlExpression, in: scope) }
            if let body = node.bodyContent { visit(body, in: scope) }
        default:
            break
        }
    }

    /// Types calls of templates and queries; other invocations fall back to the AQL service call.
    override func visitExtension(_ expression: any AQLExpression, in scope: AQLScope) -> StaticType? {
        guard let node = expression as? MTLInvocationExpression else { return nil }
        if let returnType = queryReturnTypes[node.name] {
            if let receiver = node.receiver { _ = visit(receiver, in: scope) }
            for argument in node.arguments { _ = visit(argument, in: scope) }
            return recorder.resolve(written: returnType, access: nil, at: node.origin)
        }
        if templateNames.contains(node.name) {
            if let receiver = node.receiver { _ = visit(receiver, in: scope) }
            for argument in node.arguments { _ = visit(argument, in: scope) }
            return .dataValue(CanonicalDataType.string.rawValue)
        }
        return call(node.fallback, in: scope)
    }
}
