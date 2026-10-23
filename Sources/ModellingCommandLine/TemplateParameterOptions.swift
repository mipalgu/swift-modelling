//
// TemplateParameterOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import EMFBase
import Foundation
import MTL

/// The command line option that passes named parameters to templates.
///
/// Each `--param name=value` becomes a parameter of the templates: they read it as the
/// variable `[name/]` or with the service `parameter('name')`, and test for it with
/// `hasParameter('name')`. The value is everything after the first `=`, typed as a boolean for
/// `true` or `false`, as an integer for a whole number and as a string otherwise. A name must
/// be an identifier that is not a reserved word of the template syntax.
///
/// Commands include the option with `@OptionGroup`, and obtain the services to register with
/// a generator from ``services`` or the typed values from ``values`` when they run.
public struct TemplateParameterOptions: ParsableArguments, Sendable {
    /// The long name of the option.
    public static let optionName = "param"

    /// The parameters as given on the command line, each as `name=value`.
    @Option(
        name: .customLong(TemplateParameterOptions.optionName),
        help: """
            A parameter for the templates as name=value (can be specified multiple times). \
            Templates read it as the variable [name/] or with parameter('name'), and test for \
            it with hasParameter('name'). The name must be an identifier that is not a reserved \
            keyword.
            """
    )
    public var arguments: [String] = []

    /// Creates the option with no parameters.
    public init() {}

    /// Whether at least one parameter was given on the command line.
    public var isGiven: Bool { !arguments.isEmpty }

    /// The services that give templates access to the parameters.
    ///
    /// Register them with a generator and bind them as global variables with
    /// `MTLParameterServices.bind(to:)`.
    ///
    /// - Throws: ``TemplateParameterError`` if an argument is not `name=value`, or has a name that
    ///   is not an identifier or is a reserved word.
    public var services: MTLParameterServices {
        get throws { try MTLParameterServices(values: values) }
    }

    /// The typed values of the parameters by name.
    ///
    /// A later argument replaces an earlier one with the same name.
    ///
    /// - Throws: ``TemplateParameterError`` if an argument is not `name=value`, or has a name that
    ///   is not an identifier or is a reserved word.
    public var values: [String: any EcoreValue] {
        get throws {
            var values: [String: any EcoreValue] = [:]
            for argument in arguments {
                do {
                    let (name, value) = try MTLParameterServices.parse(argument)
                    values[name] = value
                } catch let error as MTLParameterError {
                    throw TemplateParameterError(error)
                }
            }
            return values
        }
    }
}

/// A problem with a template parameter given on the command line.
public enum TemplateParameterError: Error, Equatable, Sendable, CustomStringConvertible {
    /// The argument is not of the form `name=value`.
    ///
    /// The associated value is the argument as given.
    case invalidParameter(String)

    /// The name of the parameter is not an identifier.
    ///
    /// The associated value is the name as given.
    case invalidParameterName(String)

    /// The name of the parameter is a reserved word of the template syntax.
    ///
    /// The associated value is the name as given.
    case reservedParameterName(String)

    /// Creates the command line error for a problem that the parameter services report.
    ///
    /// - Parameter error: The problem found by `MTLParameterServices`.
    public init(_ error: MTLParameterError) {
        switch error {
        case .invalidParameter(let text): self = .invalidParameter(text)
        case .invalidParameterName(let name): self = .invalidParameterName(name)
        case .reservedParameterName(let name): self = .reservedParameterName(name)
        }
    }

    /// A sentence that names the argument and says what is wrong with it.
    public var description: String {
        switch self {
        case .invalidParameter(let argument):
            return "Invalid parameter '\(argument)': expected name=value"
        case .invalidParameterName(let name):
            return "Invalid parameter name '\(name)': it is not a valid identifier"
        case .reservedParameterName(let name):
            return "Invalid parameter name '\(name)': it is a reserved keyword of MTL or AQL"
        }
    }
}

extension TemplateParameterError: LocalizedError {
    /// The ``description`` of the error.
    public var errorDescription: String? { description }
}
