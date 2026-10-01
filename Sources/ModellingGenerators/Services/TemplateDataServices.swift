//
// TemplateDataServices.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Foundation

/// Offers the data models of a template set to templates.
///
/// A template set can bundle small data models, for example a table that maps model types to
/// types of the target language. This provider makes the root objects of each data model
/// available by name through the service `templateData('name')`.
///
/// ## Example
///
/// ```swift
/// let services = TemplateDataServices(roots: ["types": [typeMappingRoot]])
/// ```
public struct TemplateDataServices: AQLServiceProvider {
    /// The root objects of each data model, keyed by the name that the template set gives it.
    public let roots: [String: [DynamicEObject]]

    /// Creates the services for the data models of a template set.
    ///
    /// - Parameter roots: The root objects of each data model by name.
    public init(roots: [String: [DynamicEObject]]) {
        self.roots = roots
    }

    /// The services offered to templates.
    public var services: [AQLService] {
        let roots = self.roots
        return [
            AQLService(GenModelServiceName.templateData, receiver: .standalone, arity: 1) { call in
                let name = try call.string(0)
                guard let objects = roots[name] else {
                    throw AQLExecutionError.invalidOperation("The template set has no data model '\(name)'")
                }
                return AQLValues.collection(objects)
            }
        ]
    }
}
