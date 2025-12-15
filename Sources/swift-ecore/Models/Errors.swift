//
// Errors.swift
// swift-ecore
//
//  Created by Rene Hexel on 3/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//

import Foundation

// MARK: - Error Types

/// Errors that can occur during model validation.
enum ValidationError: Error, LocalizedError {
    /// The specified file was not found.
    case fileNotFound(String)

    /// The file format is not supported.
    case unsupportedFormat(String)

    /// Parsing failed with details.
    case parsingFailed(String, String)

    /// A localised description of the error.
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .unsupportedFormat(let format):
            return "Unsupported format: \(format)"
        case .parsingFailed(let format, let details):
            return "Failed to parse \(format): \(details)"
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
        }
    }
}

/// Errors that can occur during code generation.
enum GenerationError: Error, LocalizedError {
    /// The input file was not found.
    case fileNotFound(String)

    /// The file format is not supported.
    case unsupportedFormat(String)

    /// The target language is not supported.
    case unsupportedLanguage(String)

    /// A localised description of the error.
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Input file not found: \(path)"
        case .unsupportedFormat(let format):
            return "Unsupported format: \(format)"
        case .unsupportedLanguage(let language):
            return "Unsupported language: \(language). Supported: swift, cpp, c, llvm"
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
            return "Unsupported format: \(format)"
        case .invalidQuery(let details):
            return "Invalid query: \(details)"
        case .unsupportedQuery(let query):
            return "Unsupported query: \(query)"
        }
    }
}
