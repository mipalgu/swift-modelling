//
// SwiftHenshinError.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation

/// An error that stops swift-henshin from doing what the command line asks.
///
/// Each case describes the problem in terms of what was given on the command line, so that
/// the message the tool prints tells the reader what to change.
enum SwiftHenshinError: Error, Equatable, CustomStringConvertible, LocalizedError {
    /// A file named on the command line does not exist.
    ///
    /// The associated value is the path as given on the command line.
    case fileNotFound(String)

    /// A module file has an extension that names no Henshin document format.
    ///
    /// The associated value is the path as given on the command line.
    case unknownModuleFormat(String)

    /// A Henshin Text document has errors, so that no module is read from it.
    ///
    /// The associated values are the path and the number of errors.
    case invalidText(String, Int)

    /// The module has no unit or rule of the given name.
    ///
    /// The associated values are the name and the names that the module has.
    case unknownUnit(String, [String])

    /// The module has no rule of the given name.
    ///
    /// The associated values are the name and the names of the rules that the module has.
    case unknownRule(String, [String])

    /// A parameter value names an object that the model does not hold.
    ///
    /// The associated values are the parameter and the value as given.
    case objectNotFound(parameter: String, value: String)

    /// A parameter value names several objects of the model.
    ///
    /// The associated values are the parameter, the value as given and the number of objects.
    case ambiguousObject(parameter: String, value: String, count: Int)

    /// The output file exists and `--force` was not given.
    ///
    /// The associated value is the path as given on the command line.
    case outputExists(String)

    /// The conversion that the extensions of the files ask for is not available.
    ///
    /// The associated values are the input and the output path.
    case unsupportedConversion(String, String)

    /// The module has no rules to analyse or explore.
    case noRules

    /// A JavaScript expression cannot be translated.
    ///
    /// The associated values are the expression and the reason.
    case untranslatable(String, String)

    /// A description of the error for the reader of the command line.
    var description: String {
        typealias Key = SwiftHenshinVocabulary.OptionName
        typealias Extension = SwiftHenshinVocabulary.FileExtension
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .unknownModuleFormat(let path):
            return "Cannot tell the format of \(path): a module is a .\(Extension.henshin) or a "
                + ".\(Extension.henshinText) document"
        case .invalidText(let path, let count):
            return "\(path) is not valid Henshin Text (\(count) error(s))"
        case .unknownUnit(let name, let known):
            return "The module has no unit or rule named '\(name)'" + Self.list(known)
        case .unknownRule(let name, let known):
            return "The module has no rule named '\(name)'" + Self.list(known)
        case .objectNotFound(let parameter, let value):
            return "No object of the model matches '\(value)' for the parameter '\(parameter)'; "
                + "give the value of its name attribute or a fragment path such as //@bins.0"
        case .ambiguousObject(let parameter, let value, let count):
            return "\(count) objects of the model match '\(value)' for the parameter '\(parameter)'; "
                + "give a fragment path such as //@bins.0 instead"
        case .outputExists(let path):
            return "The output file exists: \(path); give --\(Key.force) to replace it"
        case .unsupportedConversion(let input, let output):
            return "Cannot convert \(input) to \(output): Henshin documents are read from "
                + ".\(Extension.henshin) and .\(Extension.henshinText) files and written as "
                + ".\(Extension.henshinText) only"
        case .noRules:
            return "The module has no rules to work with"
        case .untranslatable(let expression, let reason):
            return "Cannot translate '\(expression)': \(reason); declare the names that the "
                + "expression uses with --\(Key.variables)"
        }
    }

    /// The localised description of the error, which is its ``description``.
    var errorDescription: String? { description }

    /// The names that a module has, as the end of a message.
    ///
    /// - Parameter names: The names.
    /// - Returns: A clause that lists the names, or an empty text if there are none.
    private static func list(_ names: [String]) -> String {
        names.isEmpty ? "" : " (available: \(names.joined(separator: ", ")))"
    }
}
