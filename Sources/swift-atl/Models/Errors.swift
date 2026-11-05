//
// Errors.swift
// swift-atl
//
//  Created by Rene Hexel on 6/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import Foundation
import ModellingCommandLine

// MARK: - Validation Error

/// Represents validation errors for command-line arguments and input data.
///
/// This error type is used throughout the swift-atl tool to report
/// validation failures with descriptive messages for user feedback.
struct ValidationError: Error, LocalizedError {
    /// The descriptive error message explaining the validation failure.
    let message: String

    /// Initialises a validation error with a descriptive message.
    ///
    /// - Parameter message: A human-readable description of the validation failure
    init(_ message: String) {
        self.message = message
    }

    /// Provides a localised description of the error.
    ///
    /// - Returns: The error message suitable for display to the user
    var errorDescription: String? {
        return message
    }
}

// MARK: - Transformation Errors

/// Errors that occur during ATL model transformation operations.
///
/// These errors represent various failure conditions that can occur when
/// loading, transforming, or saving models during ATL transformation execution.
/// Each case provides detailed context about the specific failure scenario.
enum TransformationError: Error, LocalizedError {
    /// The specified model file was not found at the given path.
    ///
    /// - Parameter path: The file path that could not be located
    case modelFileNotFound(String)

    /// Invalid model argument format was provided.
    ///
    /// Occurs when model arguments don't follow the expected ALIAS=path format
    /// or contain invalid characters.
    ///
    /// - Parameter message: Description of what was invalid about the argument
    case invalidModelArgument(String)

    /// Target model was not found after transformation execution.
    ///
    /// Indicates that a expected target model wasn't produced by the transformation,
    /// which may suggest a rule matching or execution failure.
    ///
    /// - Parameter alias: The alias of the missing target model
    case targetModelNotFound(String)

    /// Unsupported model format was specified.
    ///
    /// Thrown when attempting to load or save a model in a format
    /// that isn't currently supported by the transformation engine.
    ///
    /// - Parameter format: The unsupported format that was requested
    case unsupportedFormat(String)

    /// A module parameter was not given as `name=value`.
    ///
    /// - Parameter argument: The argument as it was given on the command line
    case invalidParameterArgument(String)

    /// A metamodel file was not given in a form that binds a metamodel of the module.
    ///
    /// - Parameter message: Description of what was wrong with the metamodel files
    case invalidMetamodelArgument(String)

    /// A metamodel of the module is bound neither by a metamodel file nor by a directive.
    ///
    /// - Parameter name: The name that the module header gives the metamodel
    case unboundMetamodel(String)

    /// The transformation refers to types or features that its metamodels do not define.
    ///
    /// - Parameter problems: One sentence for each problem, in the order of the module
    case invalidTransformation([String])

    /// Provides a localised description of the transformation error.
    ///
    /// Generates user-friendly error messages with context about the failure,
    /// suitable for display in command-line output or error logs.
    ///
    /// - Returns: A descriptive error message for the specific failure case
    var errorDescription: String? {
        switch self {
        case .modelFileNotFound(let path):
            return "Model file not found: \(path)"
        case .invalidModelArgument(let message):
            return "Invalid model argument: \(message)"
        case .targetModelNotFound(let alias):
            return "Target model '\(alias)' not found after transformation"
        case .unsupportedFormat(let format):
            return "Unsupported model format: \(format)"
        case .invalidParameterArgument(let argument):
            return "Invalid parameter '\(argument)': expected name=value"
        case .invalidMetamodelArgument(let message):
            return "Invalid metamodel argument: \(message)"
        case .unboundMetamodel(let name):
            return "No file or directive gives the metamodel '\(name)': give it with --\(TransformMetamodelOptions.sourceOptionName), --\(TransformMetamodelOptions.targetOptionName) or --\(MetamodelOptions.optionName), or with an -- @path or -- @nsURI directive"
        case .invalidTransformation(let problems):
            return "The transformation is not valid:\n" + problems.map { "  - \($0)" }.joined(separator: "\n")
        }
    }
}
