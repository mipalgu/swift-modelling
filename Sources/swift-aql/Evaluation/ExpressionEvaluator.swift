//
// ExpressionEvaluator.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Foundation

/// Evaluates AQL expressions against loaded models.
///
/// Before an expression is evaluated, the evaluator binds these variables:
///
/// - `self` holds the context object: the object that `--context` selects, or else the first
///   root object of the first model, or null if there is no model or it is empty;
/// - each root object of the models is bound to the name of its class with the first letter in
///   lower case, so that the root `Company` of a model is `company`. When several root objects
///   have classes of the same name, the first of them is bound. A variable never replaces
///   `self`.
///
/// All models are registered with the expression, so that services such as `allInstances()`
/// and `eContainer()` see every model.
@MainActor
final class ExpressionEvaluator {
    /// The models against which expressions are evaluated.
    let models: [LoadedModel]

    /// The execution context of the expressions.
    let context: AQLExecutionContext

    /// The formatter whose labels identify objects by name.
    let formatter = ResultFormatter()

    /// Creates an evaluator.
    ///
    /// - Parameters:
    ///   - models: The models against which expressions are evaluated.
    ///   - options: The behaviours of expressions.
    ///   - unsetFeatureReads: How expressions read features that a model does not set.
    init(models: [LoadedModel], options: AQLOptions, unsetFeatureReads: UnsetFeatureReads = .defaults) async {
        self.models = models
        let engine = ECoreExecutionEngine(models: [:], unsetFeatureReads: unsetFeatureReads)
        for (index, model) in models.enumerated() {
            await engine.registerResource(model.resource, alias: Self.alias(of: model, at: index))
        }
        context = AQLExecutionContext(executionEngine: engine, options: options)
        for model in models { context.addResource(model.resource) }
    }

    /// The name under which a model is registered with the execution engine.
    ///
    /// - Parameters:
    ///   - model: The model.
    ///   - index: The position of the model on the command line, from 0.
    /// - Returns: The name of the model file without its extension, followed by its position,
    ///   so that models whose files have the same name stay apart.
    static func alias(of model: LoadedModel, at index: Int) -> String {
        URL(fileURLWithPath: model.path).deletingPathExtension().lastPathComponent + "#\(index)"
    }

    /// The variables bound before an expression is evaluated, in binding order.
    ///
    /// - Parameter selfObject: The object bound to `self`, if any.
    /// - Returns: The names and values of the variables, starting with `self`.
    func bindings(self selfObject: (any EObject)?) -> [(name: String, value: (any EcoreValue)?)] {
        var bindings: [(name: String, value: (any EcoreValue)?)] = [
            (SwiftAQLVocabulary.Variable.selfName, selfObject ?? models.lazy.flatMap(\.roots).first)
        ]
        var names: Set<String> = [SwiftAQLVocabulary.Variable.selfName]
        for root in models.flatMap(\.roots) {
            let name = Self.variableName(ofClass: root.eClass.name)
            guard !name.isEmpty, names.insert(name).inserted else { continue }
            bindings.append((name, root))
        }
        return bindings
    }

    /// The name of the variable that holds a root object of a class.
    ///
    /// - Parameter className: The name of the class, such as `Company`.
    /// - Returns: The name with its first letter in lower case, such as `company`.
    static func variableName(ofClass className: String) -> String {
        guard let first = className.first else { return className }
        return first.lowercased() + className.dropFirst()
    }

    /// Finds the object that `--context` selects.
    ///
    /// The key is looked up as an identifier that a model declares with `xmi:id`, then, if it
    /// starts with a slash, as a fragment path, and finally as the label of an object.
    ///
    /// - Parameter key: The identifier, fragment path or name.
    /// - Returns: The object.
    /// - Throws: ``SwiftAQLError/contextNotFound(_:)`` if no object matches, and
    ///   ``SwiftAQLError/ambiguousContext(_:_:)`` if several objects have the name.
    func contextObject(for key: String) async throws -> any EObject {
        for model in models {
            if let path = model.identifiers.path(of: key), let object = try await object(at: path, in: model) {
                return object
            }
        }
        if let path = ContainmentPath(fragment: key) {
            for model in models {
                if let object = try await object(at: path, in: model) {
                    return object
                }
            }
        }
        var matches: [any EObject] = []
        for model in models {
            for object in await model.resource.getAllObjects() where formatter.label(of: object) == key {
                if !matches.contains(where: { $0.id == object.id }) { matches.append(object) }
            }
        }
        guard let match = matches.first else { throw SwiftAQLError.contextNotFound(key) }
        guard matches.count == 1 else { throw SwiftAQLError.ambiguousContext(key, matches.count) }
        return match
    }

    /// The object at a position within a model.
    ///
    /// - Parameters:
    ///   - path: The position.
    ///   - model: The model.
    /// - Returns: The object, or `nil` if the model has no object at the position.
    /// - Throws: An error if a containment reference cannot be read.
    func object(at path: ContainmentPath, in model: LoadedModel) async throws -> (any EObject)? {
        guard model.roots.indices.contains(path.root) else { return nil }
        var current: any EObject = model.roots[path.root]
        for step in path.steps {
            let value = try await context.navigate(from: current, property: step.feature)
            let elements = AQLValues.coerceToCollection(value)
            guard elements.indices.contains(step.index), let next = elements[step.index] as? any EObject else {
                return nil
            }
            current = next
        }
        return current
    }

    /// Parses and evaluates an expression.
    ///
    /// - Parameters:
    ///   - text: The expression.
    ///   - selfObject: The object to bind to `self`, or `nil` for the first root object.
    /// - Returns: The value of the expression, or `nil` for null.
    /// - Throws: ``SwiftAQLError/invalidExpression(_:)`` if the expression is not valid AQL, and
    ///   ``SwiftAQLError/evaluationFailed(_:)`` if it cannot be evaluated.
    func evaluate(_ text: String, self selfObject: (any EObject)? = nil) async throws -> (any EcoreValue)? {
        let parsed = AQLParser().parse(text)
        let problems = parsed.diagnostics.filter { $0.severity == .error }
        guard problems.isEmpty, let expression = parsed.expression else {
            throw SwiftAQLError.invalidExpression(problems.map(SwiftAQLError.describe))
        }
        for binding in bindings(self: selfObject) {
            context.setVariable(binding.name, value: binding.value)
        }
        do {
            return try await expression.evaluate(in: context)
        } catch let error as LocalizedError {
            throw SwiftAQLError.evaluationFailed(error.errorDescription ?? String(describing: error))
        } catch {
            throw SwiftAQLError.evaluationFailed(String(describing: error))
        }
    }
}
