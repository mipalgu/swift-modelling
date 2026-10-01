//
// GenerationError.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// The errors that the generation pipeline reports.
///
/// Every case carries the location or detail needed to tell the user what to correct.
public enum GenerationError: Error, Sendable, Equatable, CustomStringConvertible {
    /// No source model was given.
    case noSourceModels

    /// A source model does not exist.
    ///
    /// The associated value is the path of the missing file.
    case sourceModelNotFound(String)

    /// A source model could not be read.
    ///
    /// The first associated value is the path, the second a description of the cause.
    case sourceModelUnreadable(String, String)

    /// A source model has no root package.
    ///
    /// The associated value is the path of the offending file.
    case noRootPackage(String)

    /// The generator model to reload does not exist or cannot be read.
    ///
    /// The first associated value is the path, the second a description of the cause.
    case reloadModelUnreadable(String, String)

    /// The bundled transformation could not be found or parsed.
    ///
    /// The associated value describes the cause.
    case transformationUnavailable(String)

    /// The transformation failed while running.
    ///
    /// The associated value describes the cause.
    case transformationFailed(String)

    /// The generator model could not be written.
    ///
    /// The first associated value is the path, the second a description of the cause.
    case outputFailed(String, String)

    /// A description of the error for display to the user.
    public var description: String {
        switch self {
        case .noSourceModels:
            return "No Ecore model was given"
        case .sourceModelNotFound(let path):
            return "The Ecore model '\(path)' does not exist"
        case .sourceModelUnreadable(let path, let cause):
            return "The Ecore model '\(path)' cannot be read: \(cause)"
        case .noRootPackage(let path):
            return "The Ecore model '\(path)' contains no package"
        case .reloadModelUnreadable(let path, let cause):
            return "The generator model '\(path)' cannot be reloaded: \(cause)"
        case .transformationUnavailable(let cause):
            return "The Ecore to generator model transformation is unavailable: \(cause)"
        case .transformationFailed(let cause):
            return "The Ecore to generator model transformation failed: \(cause)"
        case .outputFailed(let path, let cause):
            return "The generator model '\(path)' cannot be written: \(cause)"
        }
    }
}
