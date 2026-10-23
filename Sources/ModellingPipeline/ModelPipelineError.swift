//
// ModelPipelineError.swift
// ModellingPipeline
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// The problems that the steps of a model pipeline report.
///
/// Problems with template sets are reported as ``ModellingGenerators/GenerationError``; the
/// cases here concern transformations, single template modules and the models of a pipeline.
/// Every case carries the location or name needed to tell the user what to correct.
public enum ModelPipelineError: Error, Sendable, Equatable {
    /// A transformation module cannot be read or parsed.
    ///
    /// The associated values are the path of the module and the cause.
    case transformationUnreadable(String, String)

    /// A transformation failed while it ran.
    ///
    /// The associated values are the name of the module and the cause.
    case transformationFailed(String, String)

    /// A template module cannot be read or parsed.
    ///
    /// The associated values are the path of the module and the cause.
    case templatesUnreadable(String, String)

    /// A template module holds no templates.
    ///
    /// The associated value is the name of the module.
    case noTemplates(String)

    /// The template to run is not a template of the module.
    ///
    /// The associated values are the name of the template and the name of the module.
    case templateNotFound(String, String)

    /// A step names a model that the pipeline does not hold.
    ///
    /// The associated values are the name of the model and the names of the models the
    /// pipeline holds.
    case unknownModel(String, [String])
}

extension ModelPipelineError: CustomStringConvertible, LocalizedError {
    /// A sentence that describes the problem and names what is involved.
    public var description: String {
        switch self {
        case .transformationUnreadable(let path, let cause):
            return "The transformation '\(path)' cannot be read: \(cause)"
        case .transformationFailed(let module, let cause):
            return "The transformation '\(module)' failed: \(cause)"
        case .templatesUnreadable(let path, let cause):
            return "The templates '\(path)' cannot be read: \(cause)"
        case .noTemplates(let module):
            return "The module '\(module)' holds no templates"
        case .templateNotFound(let template, let module):
            return "The template '\(template)' is not a template of the module '\(module)'"
        case .unknownModel(let name, let available):
            let list = available.isEmpty ? "none" : available.sorted().joined(separator: ", ")
            return "The pipeline holds no model named '\(name)'; it holds: \(list)"
        }
    }

    /// The ``description`` of the error.
    public var errorDescription: String? { description }
}
