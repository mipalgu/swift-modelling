//
// ArgumentBinder.swift
// swift-xtend
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import Xtend

/// Binds the models and literal arguments of the command line to the parameters of a method.
///
/// Each parameter takes its value from its declared type. A parameter of type `Resource` takes
/// the first model. A parameter whose type is a class of a metamodel, or `EObject`, takes the
/// first instance of that class in the models, or the instance whose name `--object` gives. A
/// parameter of a list or collection type of such a class takes all instances. A parameter of
/// type `String`, a number or a Boolean takes the next literal `--argument`, converted to its
/// type. A parameter without a declared type takes the next literal argument, converted to a
/// whole number, a floating point number or a Boolean where it reads as one, or else the first
/// model object.
@MainActor
struct ArgumentBinder {
    /// The models, in command line order.
    let models: [Resource]

    /// The literal arguments, in command line order.
    let literals: [String]

    /// The name that selects the object for parameters of a model class, if any.
    let objectName: String?

    /// Binds the arguments to the parameters of a method.
    ///
    /// - Parameters:
    ///   - parameters: The parameters of the method.
    ///   - method: The name of the method, for messages.
    /// - Returns: The values, one for each parameter.
    /// - Throws: ``SwiftXtendError/argumentBinding(_:_:)`` if a parameter cannot be bound or
    ///   literal arguments remain unused.
    func bind(_ parameters: [XtendParameter], method: String) async throws -> [XtendHostValue] {
        var remaining = literals[...]
        var values: [XtendHostValue] = []
        for parameter in parameters {
            values.append(try await value(for: parameter, method: method, remaining: &remaining))
        }
        guard remaining.isEmpty else {
            throw SwiftXtendError.argumentBinding(
                method, "\(remaining.count) of the arguments given with --\(SwiftXtendVocabulary.OptionName.argument) "
                    + "match no parameter")
        }
        return values
    }

    /// Finds the value for one parameter.
    ///
    /// - Parameters:
    ///   - parameter: The parameter.
    ///   - method: The name of the method, for messages.
    ///   - remaining: The literal arguments not yet used; the first is removed if it is used.
    /// - Returns: The value.
    /// - Throws: ``SwiftXtendError/argumentBinding(_:_:)`` if the parameter cannot be bound.
    private func value(
        for parameter: XtendParameter, method: String, remaining: inout ArraySlice<String>
    ) async throws -> XtendHostValue {
        typealias Types = SwiftXtendVocabulary.ParameterType
        guard let type = parameter.type else {
            if let literal = remaining.popFirst() { return Self.inferred(literal) }
            return try await instance(of: nil, for: parameter, method: method)
        }
        let name = type.simpleName
        if Types.resources.contains(name) {
            guard let model = models.first else { throw missingModel(parameter, method) }
            return .resource(model)
        }
        if Types.fileSystems.contains(name) {
            throw SwiftXtendError.argumentBinding(
                method, "the parameter '\(parameter.name)' needs a file system access; use the "
                    + "\(SwiftXtendVocabulary.Command.generate) command for generators")
        }
        if Types.collections.contains(name) {
            let element = type.arguments.first?.simpleName
            var all: [XtendHostValue] = []
            for (resource, object) in await candidates(matching: element) { all.append(.object(object.id, resource)) }
            return .list(all)
        }
        if Types.strings.contains(name) || Types.integers.contains(name) || Types.doubles.contains(name)
            || Types.booleans.contains(name)
        {
            guard let literal = remaining.popFirst() else {
                throw SwiftXtendError.argumentBinding(
                    method, "the parameter '\(parameter.name)' of type \(name) needs a value given with "
                        + "--\(SwiftXtendVocabulary.OptionName.argument)")
            }
            return try Self.converted(literal, to: name, parameter: parameter.name, method: method)
        }
        return try await instance(of: Types.anyObject.contains(name) ? nil : name, for: parameter, method: method)
    }

    /// Finds the model object for a parameter.
    ///
    /// - Parameters:
    ///   - className: The name of the class that the object must be an instance of, or `nil` for any.
    ///   - parameter: The parameter.
    ///   - method: The name of the method, for messages.
    /// - Returns: The object, as a host value.
    /// - Throws: ``SwiftXtendError/argumentBinding(_:_:)`` if no model has such an object.
    private func instance(of className: String?, for parameter: XtendParameter, method: String) async throws -> XtendHostValue {
        guard !models.isEmpty else { throw missingModel(parameter, method) }
        let found = await candidates(matching: className)
        let selected = objectName.map { name in found.first { Self.label(of: $0.1) == name } } ?? found.first
        guard let (resource, object) = selected else {
            let described = className.map { "an instance of \($0)" } ?? "an object"
            let named = objectName.map { " named '\($0)'" } ?? ""
            throw SwiftXtendError.argumentBinding(
                method, "the models have no \(described)\(named) for the parameter '\(parameter.name)'")
        }
        return .object(object.id, resource)
    }

    /// The objects of the models that are instances of a class, in document order.
    ///
    /// - Parameter className: The simple name of the class, or `nil` for all objects.
    /// - Returns: The objects with the resources that hold them.
    private func candidates(matching className: String?) async -> [(Resource, any EObject)] {
        var result: [(Resource, any EObject)] = []
        for resource in models {
            for object in await resource.getAllObjectsIncludingContents() where Self.conforms(object, to: className) {
                result.append((resource, object))
            }
        }
        return result
    }

    /// Reports whether an object is an instance of a class.
    ///
    /// - Parameters:
    ///   - object: The object.
    ///   - className: The simple name of the class, or `nil` for any class.
    /// - Returns: `true` if the class of the object or one of its supertypes has that name.
    static func conforms(_ object: any EObject, to className: String?) -> Bool {
        guard let className else { return true }
        guard let eClass = object.eClass as? EClass else { return object.eClass.name == className }
        return eClass.name == className || eClass.allSuperTypes.contains { $0.name == className }
    }

    /// The label of an object.
    ///
    /// - Parameter object: The object.
    /// - Returns: The value of its `name` attribute (ignoring case) or else of its first
    ///   single-valued string attribute as text, or `nil` if the object has no such attribute
    ///   or does not set it.
    static func label(of object: any EObject) -> String? {
        guard let eClass = object.eClass as? EClass else { return nil }
        let attributes = eClass.allAttributes.filter { !$0.isMany }
        let attribute =
            attributes.first {
                $0.name.caseInsensitiveCompare(SwiftXtendVocabulary.labelAttributeName) == .orderedSame
            } ?? attributes.first { SwiftXtendVocabulary.stringTypeNames.contains($0.eType.name) }
        guard let attribute, let value = object.eGet(attribute) else { return nil }
        return (value as? String) ?? "\(value)"
    }

    /// The error for a parameter that needs a model when there is none.
    private func missingModel(_ parameter: XtendParameter, _ method: String) -> SwiftXtendError {
        .argumentBinding(
            method, "the parameter '\(parameter.name)' needs a model; give one with "
                + "--\(SwiftXtendVocabulary.OptionName.model)")
    }

    /// Converts a literal to the value of a declared type.
    ///
    /// - Parameters:
    ///   - literal: The text from the command line.
    ///   - type: The simple name of the declared type.
    ///   - parameter: The name of the parameter, for messages.
    ///   - method: The name of the method, for messages.
    /// - Returns: The value.
    /// - Throws: ``SwiftXtendError/argumentBinding(_:_:)`` if the text is not a value of the type.
    static func converted(_ literal: String, to type: String, parameter: String, method: String) throws -> XtendHostValue {
        typealias Types = SwiftXtendVocabulary.ParameterType
        let failure = SwiftXtendError.argumentBinding(
            method, "'\(literal)' is not a valid \(type) for the parameter '\(parameter)'")
        if Types.integers.contains(type) {
            guard let value = Int(literal) else { throw failure }
            return .int(value)
        }
        if Types.doubles.contains(type) {
            guard let value = Double(literal) else { throw failure }
            return .double(value)
        }
        if Types.booleans.contains(type) {
            switch literal {
            case SwiftXtendVocabulary.BooleanText.yes: return .bool(true)
            case SwiftXtendVocabulary.BooleanText.no: return .bool(false)
            default: throw failure
            }
        }
        return .string(literal)
    }

    /// Converts a literal for a parameter without a declared type.
    ///
    /// - Parameter literal: The text from the command line.
    /// - Returns: A whole number, a floating point number or a Boolean where the text reads as
    ///   one, and otherwise the text.
    static func inferred(_ literal: String) -> XtendHostValue {
        if let value = Int(literal) { return .int(value) }
        if let value = Double(literal) { return .double(value) }
        if literal == SwiftXtendVocabulary.BooleanText.yes { return .bool(true) }
        if literal == SwiftXtendVocabulary.BooleanText.no { return .bool(false) }
        return .string(literal)
    }
}
