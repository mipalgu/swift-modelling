//
// SwiftXtendError.swift
// swift-xtend
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// An error that stops swift-xtend from running a program.
///
/// Each case describes the problem in terms of what was given on the command line, so that the
/// message the tool prints tells the reader what to change.
enum SwiftXtendError: Error, Equatable, CustomStringConvertible, LocalizedError {
    /// An Xtend source file does not exist.
    ///
    /// The associated value is the path as given on the command line.
    case sourceNotFound(String)

    /// A model file does not exist.
    ///
    /// The associated value is the path as given on the command line.
    case modelNotFound(String)

    /// The Xtend sources have errors.
    ///
    /// The associated value is the number of errors, which have been reported on standard error.
    case invalidProgram(Int)

    /// The sources declare no class.
    case noClasses

    /// The sources declare several classes and none was chosen.
    ///
    /// The associated value lists the qualified names of the classes.
    case ambiguousClass([String])

    /// The class that `--class` names does not exist.
    ///
    /// The associated values are the name as given and the names of the classes that exist.
    case classNotFound(String, [String])

    /// The class declares no method of the name that `--method` gives.
    ///
    /// The associated values are the method name, the class and the names of its methods.
    case methodNotFound(String, String, [String])

    /// The arguments cannot be bound to the parameters of the method.
    ///
    /// The associated values are the method name and the reason.
    case argumentBinding(String, String)

    /// Running the program failed.
    ///
    /// The associated value is the report of the failure, one line per diagnostic.
    case executionFailed(String)

    /// A description of the error for the reader of the command line.
    var description: String {
        switch self {
        case .sourceNotFound(let path):
            return "Xtend source file not found or not readable: \(path)"
        case .modelNotFound(let path):
            return "Model file not found: \(path)"
        case .invalidProgram(let count):
            return "The Xtend source has \(count) error\(count == 1 ? "" : "s")"
        case .noClasses:
            return "The Xtend source declares no class"
        case .ambiguousClass(let names):
            return "The Xtend source declares several classes (\(names.joined(separator: ", "))); "
                + "choose one with --\(SwiftXtendVocabulary.OptionName.className)"
        case .classNotFound(let name, let names):
            return "The Xtend source declares no class '\(name)'" + Self.list("classes", names)
        case .methodNotFound(let method, let className, let names):
            return "The class '\(className)' declares no method '\(method)'" + Self.list("methods", names)
        case .argumentBinding(let method, let reason):
            return "Cannot call '\(method)': \(reason)"
        case .executionFailed(let report):
            return report
        }
    }

    /// The localised description of the error, which is its ``description``.
    var errorDescription: String? { description }

    /// Lists the names that exist, for a message about a name that does not.
    ///
    /// - Parameters:
    ///   - noun: The plural noun for the names.
    ///   - names: The names.
    /// - Returns: A parenthesised list, or nothing if there are no names.
    private static func list(_ noun: String, _ names: [String]) -> String {
        names.isEmpty ? "" : " (\(noun): \(names.joined(separator: ", ")))"
    }
}
