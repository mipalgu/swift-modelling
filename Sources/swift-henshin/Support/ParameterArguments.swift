//
// ParameterArguments.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import Henshin
import ModellingCommandLine

/// The value of a parameter as given on the command line, typed by the parameter.
enum ParameterArgument: Sendable {
    /// A value of a data type, such as an integer or a text.
    case value(any EcoreValue)
    /// An object of the model, named by its label or by a fragment path.
    case object(String)
}

/// The reason why the text of a parameter value does not suit the declared type.
struct ParameterTypeMismatch: Error, CustomStringConvertible {
    /// The name of the declared type.
    let typeName: String

    /// A phrase that names the expected value.
    var description: String { "expected a value of type \(typeName)" }
}

/// Reads parameter values given as `name=value` and types them by their parameters.
///
/// The value of a parameter whose declared type is an Ecore integer type is read as an
/// integer, of a real type as a real number, of a Boolean type as `true` or `false`, and of a
/// text type as the text as given. A parameter whose type is a class of the metamodels names
/// an object of the model, by the value of its label attribute (such as its `name`) or by a
/// fragment path such as `//@bins.0`. A parameter without a type takes the value as an
/// integer, a real number or a Boolean value if it reads as one, and as text otherwise.
enum ParameterArguments {
    /// The family of `name=value` options for the input parameters of a unit.
    ///
    /// - Parameters:
    ///   - parameters: The parameters of the unit.
    ///   - classNames: The names of the classes of the metamodels.
    /// - Returns: The family, which allows the names of the parameters that accept input.
    static func family(for parameters: [UnitParameter], classNames: Set<String>) -> KeyValueOption<ParameterArgument> {
        let accepted = parameters.filter(\.kind.acceptsInput)
        let types = Dictionary(accepted.map { ($0.name, $0.typeName) }, uniquingKeysWith: { first, _ in first })
        return KeyValueOption(
            noun: SwiftHenshinVocabulary.Noun.parameter, allowedKeys: accepted.map(\.name)
        ) { key, text in
            try argument(text, typeName: types[key] ?? nil, classNames: classNames)
        }
    }

    /// Types the text of a value by the declared type of its parameter.
    ///
    /// - Parameters:
    ///   - text: The text of the value.
    ///   - typeName: The name of the declared type, if any.
    ///   - classNames: The names of the classes of the metamodels.
    /// - Returns: The typed value, or the name of an object for a parameter of a class type.
    /// - Throws: ``ParameterTypeMismatch`` if the text does not suit the declared data type.
    static func argument(_ text: String, typeName: String?, classNames: Set<String>) throws -> ParameterArgument {
        guard let typeName else { return .value(inferred(text)) }
        if let type = EcoreDataType(rawValue: typeName) {
            return .value(try value(text, of: type))
        }
        return classNames.contains(typeName) ? .object(text) : .value(text)
    }

    /// Reads the text of a value of an Ecore data type.
    ///
    /// - Parameters:
    ///   - text: The text of the value.
    ///   - type: The data type.
    /// - Returns: The value.
    /// - Throws: ``ParameterTypeMismatch`` if the text is not a value of the type.
    static func value(_ text: String, of type: EcoreDataType) throws -> any EcoreValue {
        let mismatch = ParameterTypeMismatch(typeName: type.rawValue)
        switch type {
        case .eInt, .eIntegerObject, .eLong, .eLongObject, .eShort, .eShortObject, .eByte, .eByteObject, .eBigInteger:
            guard let value = Int(text) else { throw mismatch }
            return value
        case .eDouble, .eDoubleObject, .eFloat, .eFloatObject, .eBigDecimal:
            guard let value = Double(text) else { throw mismatch }
            return value
        case .eBoolean, .eBooleanObject:
            guard let value = boolean(text) else { throw mismatch }
            return value
        default:
            return text
        }
    }

    /// Reads the text of a value of a parameter without a type.
    ///
    /// - Parameter text: The text of the value.
    /// - Returns: An integer, a real number or a Boolean value if the text reads as one, and
    ///   the text itself otherwise.
    static func inferred(_ text: String) -> any EcoreValue {
        if let integer = Int(text) { return integer }
        if let real = Double(text) { return real }
        if let truth = boolean(text) { return truth }
        return text
    }

    /// Reads a Boolean value.
    ///
    /// - Parameter text: The text.
    /// - Returns: `true` or `false` for the texts that name them, `nil` otherwise.
    static func boolean(_ text: String) -> Bool? {
        switch text {
        case SwiftHenshinVocabulary.BooleanText.true: return true
        case SwiftHenshinVocabulary.BooleanText.false: return false
        default: return nil
        }
    }

    /// Turns typed arguments into the parameter values of the engine, finding the objects
    /// that they name in a model.
    ///
    /// - Parameters:
    ///   - arguments: The typed arguments by parameter name.
    ///   - parameters: The parameters of the unit, whose types restrict the objects.
    ///   - resource: The resource that holds the model.
    /// - Returns: The values, with objects given as their identities.
    /// - Throws: ``SwiftHenshinError/objectNotFound(parameter:value:)`` or
    ///   ``SwiftHenshinError/ambiguousObject(parameter:value:count:)`` if an argument names no
    ///   object or several objects.
    static func values(
        _ arguments: [String: ParameterArgument], parameters: [UnitParameter], in resource: Resource
    ) async throws -> ParameterValues {
        var values: ParameterValues = [:]
        for (name, argument) in arguments {
            switch argument {
            case .value(let value):
                values[name] = value
            case .object(let reference):
                let typeName = parameters.first { $0.name == name }?.typeName
                values[name] = try await object(reference, typeName: typeName, parameter: name, in: resource).id
            }
        }
        return values
    }

    /// Finds the object that the value of a parameter names.
    ///
    /// - Parameters:
    ///   - reference: A fragment path such as `//@bins.0`, or the label of an object.
    ///   - typeName: The name of the class that the object must have or specialise, if any.
    ///   - parameter: The name of the parameter, for the error.
    ///   - resource: The resource that holds the model.
    /// - Returns: The object.
    /// - Throws: ``SwiftHenshinError/objectNotFound(parameter:value:)`` or
    ///   ``SwiftHenshinError/ambiguousObject(parameter:value:count:)``.
    static func object(
        _ reference: String, typeName: String?, parameter: String, in resource: Resource
    ) async throws -> any EObject {
        if reference.first == SwiftHenshinVocabulary.Separator.fragment {
            let fragments = await PositionalFragments.index(of: resource)
            guard let identity = fragments.first(where: { $0.value == reference })?.key,
                let object = await resource.resolve(identity)
            else {
                throw SwiftHenshinError.objectNotFound(parameter: parameter, value: reference)
            }
            return object
        }
        let candidates = await resource.getAllObjectsIncludingContents().filter { object in
            guard ValueFormatter.label(of: object) == reference else { return false }
            guard let typeName, let eClass = object.eClass as? EClass else { return true }
            return eClass.name == typeName || eClass.allSuperTypes.contains { $0.name == typeName }
        }
        guard let first = candidates.first else {
            throw SwiftHenshinError.objectNotFound(parameter: parameter, value: reference)
        }
        guard candidates.count == 1 else {
            throw SwiftHenshinError.ambiguousObject(parameter: parameter, value: reference, count: candidates.count)
        }
        return first
    }
}
