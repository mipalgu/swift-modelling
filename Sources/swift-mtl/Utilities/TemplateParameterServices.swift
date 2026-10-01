//
// TemplateParameterServices.swift
// swift-mtl
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Foundation

/// The names of the services that give templates access to command line parameters.
enum TemplateParameterServiceName {
    /// The service `parameter('name')`, which returns the value of a parameter.
    static let parameter = "parameter"

    /// The service `hasParameter('name')`, which tells whether a parameter was given.
    static let hasParameter = "hasParameter"
}

/// Gives templates access to the values given with `--param name=value`.
///
/// The values are offered through two standalone services:
/// - `parameter('name')` returns the value of the parameter, or `null` if it was not given.
/// - `hasParameter('name')` returns `true` if the parameter was given.
///
/// A value is a boolean when its text is `true` or `false`, an integer when its text is a whole
/// number in canonical form, and a string otherwise. In a template, `[parameter('package')/]`
/// writes the value and `[if (parameter('verbose'))]` tests a flag.
///
/// ## Example
///
/// ```swift
/// let services = TemplateParameterServices(arguments: ["package=org.example", "verbose=true"])
/// ```
struct TemplateParameterServices: AQLServiceProvider {
    /// The parameter values by name.
    let values: [String: any EcoreValue]

    /// Creates the services for parameter arguments.
    ///
    /// - Parameter arguments: The arguments as `name=value`; the value is everything after the
    ///   first `=`, and a later argument replaces an earlier one of the same name.
    /// - Throws: ``ValidationError/invalidParameter(_:)`` if an argument has no name or no `=`.
    init(arguments: [String]) throws {
        var values: [String: any EcoreValue] = [:]
        for argument in arguments {
            guard let separator = argument.firstIndex(of: "="), separator != argument.startIndex else {
                throw ValidationError.invalidParameter(argument)
            }
            let text = String(argument[argument.index(after: separator)...])
            values[String(argument[..<separator])] = Self.value(of: text)
        }
        self.values = values
    }

    /// Converts parameter text to a boolean, an integer or a string.
    ///
    /// - Parameter text: The text of the value.
    /// - Returns: The typed value.
    static func value(of text: String) -> any EcoreValue {
        switch text {
        case "true": return true
        case "false": return false
        default:
            if let integer = Int(text), String(integer) == text { return integer }
            return text
        }
    }

    /// The services offered to templates.
    var services: [AQLService] {
        let values = self.values
        return [
            AQLService(TemplateParameterServiceName.parameter, receiver: .standalone, arity: 1) { call in
                values[try call.string(0)]
            },
            AQLService(TemplateParameterServiceName.hasParameter, receiver: .standalone, arity: 1) { call in
                values[try call.string(0)] != nil
            },
        ]
    }
}
