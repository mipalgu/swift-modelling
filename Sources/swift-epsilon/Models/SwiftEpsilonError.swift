//
// SwiftEpsilonError.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation

/// An error that stops swift-epsilon from running a program.
///
/// Each case describes the problem in terms of what was given on the command line, so that the
/// message the tool prints tells the reader what to change. Errors that a program raises while
/// it runs are reported as the Epsilon languages report them, with the file, line and column of
/// the construct that failed.
enum SwiftEpsilonError: Error, Equatable, CustomStringConvertible, LocalizedError {
    /// A model file does not exist.
    ///
    /// The associated value is the path as given on the command line.
    case modelNotFound(String)

    /// A source file, such as a program, a template or a module that one imports, does not exist
    /// or cannot be read.
    ///
    /// The associated value is the path of the file.
    case sourceNotFound(String)

    /// A source file has syntax errors.
    ///
    /// The associated values are the path of the file and the number of errors, which have been
    /// reported on standard error.
    case invalidSource(String, Int)

    /// The name or an alias of a model is not an identifier.
    ///
    /// The associated value is the name as given on the command line.
    case invalidModelName(String)

    /// Several models, or a model and an alias, have the same name.
    ///
    /// The associated value is the name.
    case duplicateModelName(String)

    /// `--store` names a model that no `--model` binds.
    ///
    /// The associated value is the name as given on the command line.
    case unknownStoredModel(String)

    /// The name of a parameter is not an identifier, or is a keyword of the Epsilon Object Language
    /// or a variable that the languages bind themselves, such as `self`.
    ///
    /// The associated value is the name as given on the command line.
    case invalidParameterName(String)

    /// A target model cannot be created because no metamodel is given.
    ///
    /// The associated value is the name of the model.
    case targetWithoutMetamodel(String)

    /// The output of an EGX module is not a directory.
    ///
    /// The associated value is the path as given on the command line.
    case outputNotDirectory(String)

    /// An existing output file is not valid text in the encoding of the files written.
    ///
    /// The associated values are the path of the file and the encoding.
    case notDecodable(String, TextEncoding)

    /// A description of the error for the reader of the command line.
    var description: String {
        switch self {
        case .modelNotFound(let path):
            return "Model file not found: \(path)"
        case .sourceNotFound(let path):
            return "Source file not found or not readable: \(path)"
        case .invalidSource(let path, let count):
            return "\(path) has \(count) syntax error\(count == 1 ? "" : SwiftEpsilonVocabulary.Validation.pluralSuffix)"
        case .invalidModelName(let name):
            return "Invalid model name '\(name)': a model name must be an identifier"
        case .duplicateModelName(let name):
            return "The model name '\(name)' is given more than once"
        case .unknownStoredModel(let name):
            return "Cannot store '\(name)': no --\(SwiftEpsilonVocabulary.OptionName.model) has that name"
        case .invalidParameterName(let name):
            return "Invalid parameter name '\(name)': it must be an identifier that is neither a keyword nor a reserved variable"
        case .targetWithoutMetamodel(let name):
            return "The target model '\(name)' needs a metamodel: give it with --metamodel"
        case .outputNotDirectory(let path):
            return "The output of an EGX module must be a directory: \(path)"
        case .notDecodable(let path, let encoding):
            return "Cannot merge into \(path): it is not valid \(encoding.name) text"
        }
    }

    /// The localised description of the error, which is its ``description``.
    var errorDescription: String? { description }
}
