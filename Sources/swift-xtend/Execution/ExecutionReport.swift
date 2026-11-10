//
// ExecutionReport.swift
// swift-xtend
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Xtend

extension SwiftXtendError {
    /// Wraps the failure of a library call.
    ///
    /// - Parameter error: The error that was thrown.
    /// - Returns: ``executionFailed(_:)`` with the report of an Xtend error, one line per
    ///   diagnostic, or with the description of any other error.
    static func execution(_ error: any Error) -> SwiftXtendError {
        if let error = error as? SwiftXtendError { return error }
        if let error = error as? XtendError { return .executionFailed(error.description) }
        return .executionFailed(String(describing: error))
    }
}
