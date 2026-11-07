//
// Errors.swift
// swift-ecore
//
//  Created by Rene Hexel on 3/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//

import ECore
import Foundation
import ModellingCommandLine

// MARK: - Error Types

/// Errors that can occur during model validation.
enum ValidationError: Error, LocalizedError {
    /// The specified file was not found.
    case fileNotFound(String)

    /// The file format is not supported.
    case unsupportedFormat(String)

    /// Parsing failed with details.
    case parsingFailed(String, String)

    /// The document does not pass validation.
    ///
    /// The associated values are the numbers of errors and warnings, and whether warnings
    /// count as errors.
    case failed(errors: Int, warnings: Int, strict: Bool)

    /// A localised description of the error.
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .unsupportedFormat(let format):
            return DocumentError.unsupportedFormatDescription(format)
        case .parsingFailed(let format, let details):
            return "Failed to parse \(format): \(details)"
        case .failed(let errors, let warnings, let strict):
            let counted = strict ? " (strict: warnings count as errors)" : ""
            return "Validation failed: \(errors) error(s), \(warnings) warning(s)\(counted)"
        }
    }
}

/// Errors that can occur during format conversion.
enum ConversionError: Error, LocalizedError {
    /// The input file was not found.
    case fileNotFound(String)

    /// The output file already exists.
    case outputExists(String)

    /// The input format is not supported.
    case unsupportedInputFormat(String)

    /// The output format is not supported.
    case unsupportedOutputFormat(String)

    /// No output file was given, or it was given both as an argument and as an option.
    case outputRequired

    /// The model does not pass validation, so no output was written.
    ///
    /// The associated value is the number of errors.
    case invalidModel(Int)

    /// A metamodel was to be written in a format that holds only models.
    ///
    /// - Parameters:
    ///   - input: The name of the metamodel file.
    ///   - format: The name of the output format.
    case metamodelOutputFormat(String, format: String)

    /// A model was to be written in a format that holds only metamodels.
    ///
    /// - Parameters:
    ///   - input: The name of the model file.
    ///   - format: The name of the output format.
    case modelOutputFormat(String, format: String)

    /// A document was to be written in a format that is only read, such as Langium.
    ///
    /// - Parameters:
    ///   - input: The name of the input file.
    ///   - format: The output format.
    ///   - isMetamodel: Whether the input is a metamodel rather than a model.
    case readOnlyOutputFormat(String, format: ModelFormat, isMetamodel: Bool)

    /// A level was given for an input that holds no multi-level model.
    ///
    /// The associated value is the name of the input file.
    case levelWithoutDeepModel(String)

    /// A multi-level model was to be written in a metamodel format without a level.
    ///
    /// - Parameters:
    ///   - input: The name of the input file.
    ///   - format: The name of the output format.
    ///   - levels: The levels of the model, from the top down.
    case deepModelNeedsLevel(String, format: String, levels: [Int])

    /// The multi-level model has no level of that number.
    ///
    /// - Parameters:
    ///   - level: The level given.
    ///   - levels: The levels of the model, from the top down.
    case noSuchLevel(Int, levels: [Int])

    /// The advice to convert a document to one of the formats that can hold it.
    ///
    /// - Parameter isMetamodel: Whether the document is a metamodel rather than a model.
    /// - Returns: For example `convert it to one of: ecore, json, km3, emf (Emfatic)`, listing
    ///   the formats of the registry that can write the document.
    private static func advice(isMetamodel: Bool) -> String {
        let formats = isMetamodel ? ConvertCommand.metamodelFormats : ConvertCommand.modelFormats
        return "convert it to one of: " + MetamodelRegistration.formatList(formats)
    }

    /// Lists the levels of a multi-level model.
    ///
    /// - Parameter levels: The levels, from the top down.
    /// - Returns: The levels separated by commas, such as `2, 1, 0`.
    private static func levelList(_ levels: [Int]) -> String {
        levels.map(String.init).joined(separator: ", ")
    }

    /// A localised description of the error.
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Input file not found: \(path)"
        case .outputExists(let path):
            return "Output file already exists: \(path) (use --force to overwrite)"
        case .unsupportedInputFormat(let format):
            return "Unsupported input format: \(format)"
        case .unsupportedOutputFormat(let format):
            return "Unsupported output format: \(format)"
        case .outputRequired:
            return "Give the output file either as the second argument or with --output, not both"
        case .invalidModel(let errors):
            return "The model has \(errors) validation error(s); no output was written"
        case .metamodelOutputFormat(let input, let format):
            return "\(input) is a metamodel, which cannot be written as \(format): " + Self.advice(isMetamodel: true)
        case .modelOutputFormat(let input, let format):
            return "\(input) is a model, which cannot be written as \(format): " + Self.advice(isMetamodel: false)
        case .levelWithoutDeepModel(let input):
            return "\(input) holds no multi-level model, so --\(ConvertCommand.levelOption) does not apply"
        case .deepModelNeedsLevel(let input, let format, let levels):
            return "\(input) is a multi-level model: give --\(ConvertCommand.levelOption) <level> to write the "
                + "metamodel of one level as \(format) (levels: \(Self.levelList(levels))), or convert it to one of: "
                + MetamodelRegistration.formatList(ConvertCommand.modelFormats)
        case .noSuchLevel(let level, let levels):
            return "The multi-level model has no level \(level) (levels: \(Self.levelList(levels)))"
        case .readOnlyOutputFormat(let input, let format, let isMetamodel):
            return "\(input) cannot be written as \(format.rawValue): \(format.description) documents are "
                + "only read, not written; " + Self.advice(isMetamodel: isMetamodel)
        }
    }
}

/// Errors that can occur during code generation.
enum GenerationError: Error, LocalizedError {
    /// The input file was not found.
    case fileNotFound(String)

    /// The file format is not supported.
    case unsupportedFormat(String)

    /// No template set exists for the language.
    ///
    /// The first associated value is the language, the second the languages that have a template set.
    case unknownLanguage(String, [String])

    /// A localised description of the error.
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Input file not found: \(path)"
        case .unsupportedFormat(let format):
            return "Unsupported format: \(format)"
        case .unknownLanguage(let language, let available):
            return "Unsupported language: \(language). Supported: " + available.joined(separator: ", ")
        }
    }
}

/// Errors that can occur during query execution.
enum QueryError: Error, LocalizedError {
    /// The specified file was not found.
    case fileNotFound(String)

    /// The file format is not supported.
    case unsupportedFormat(String)

    /// The query is invalid.
    case invalidQuery(String)

    /// The query type is not supported.
    case unsupportedQuery(String)

    /// A localised description of the error.
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .unsupportedFormat(let format):
            return DocumentError.unsupportedFormatDescription(format)
        case .invalidQuery(let details):
            return "Invalid query: \(details)"
        case .unsupportedQuery(let query):
            return "Unsupported query: \(query)"
        }
    }
}

/// Errors that can occur while a model is created.
enum CreationError: Error, LocalizedError, Equatable {
    /// The output file already exists.
    case outputExists(String)

    /// No metamodel defines a class of that name.
    ///
    /// The associated values are the name and the classes that can be instantiated.
    case unknownClass(String, [String])

    /// The class is abstract or an interface, so it cannot be instantiated.
    case abstractClass(String)

    /// The output format cannot hold a model.
    case unsupportedFormat(String)

    /// A localised description of the error.
    var errorDescription: String? {
        switch self {
        case .outputExists(let path):
            return "Output file already exists: \(path) (use --force to overwrite)"
        case .unknownClass(let name, let available):
            return "No metamodel defines the class \(name). Classes: " + available.joined(separator: ", ")
        case .abstractClass(let name):
            return "The class \(name) is abstract and cannot be instantiated"
        case .unsupportedFormat(let format):
            return "Unsupported output format: \(format)"
        }
    }
}
