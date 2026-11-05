//
// WorkflowErrors.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// Errors that can occur while two documents are compared.
enum ComparisonError: Error, LocalizedError, Equatable {
    /// One file is a metamodel and the other a model.
    ///
    /// The associated values are the name of the metamodel file and the name of the model file.
    case mixedKinds(metamodel: String, model: String)

    /// A localised description of the error.
    var errorDescription: String? {
        switch self {
        case .mixedKinds(let metamodel, let model):
            return "Cannot compare a metamodel with a model: \(metamodel) is a metamodel, \(model) is a model"
        }
    }
}

/// Errors that can occur while several files are validated.
enum BatchValidationError: Error, LocalizedError, Equatable {
    /// At least one file did not pass validation or could not be read.
    ///
    /// The associated values are the paths of the invalid files, as given on the command line,
    /// and the number of files validated.
    case invalidFiles([String], of: Int)

    /// A localised description of the error.
    var errorDescription: String? {
        switch self {
        case .invalidFiles(let paths, let total):
            return "Validation failed for \(paths.count) of \(total) files: " + paths.joined(separator: ", ")
        }
    }
}
