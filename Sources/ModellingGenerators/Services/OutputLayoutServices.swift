//
// OutputLayoutServices.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import Foundation

/// Tells templates how the output location relates to the source directory of the generator model.
///
/// A template set that writes files outside the source directory, such as project descriptions that
/// belong to the parent of the source directory, needs to know whether the output location is the
/// source directory itself or a directory above it. This provider offers that fact through the
/// service `layoutIncludesSourceRoot()`.
///
/// ## Example
///
/// ```swift
/// let services = OutputLayoutServices(includesSourceRoot: true)
/// ```
public struct OutputLayoutServices: AQLServiceProvider {
    /// Whether the output location includes the source directory of the generator model.
    public let includesSourceRoot: Bool

    /// Creates the services for an output layout.
    ///
    /// - Parameter includesSourceRoot: Whether the output location is the source directory of the generator model.
    public init(includesSourceRoot: Bool) {
        self.includesSourceRoot = includesSourceRoot
    }

    /// The services offered to templates.
    public var services: [AQLService] {
        let includes = includesSourceRoot
        return [
            AQLService(GenModelServiceName.layoutIncludesSourceRoot, receiver: .standalone, arity: 0) { _ in
                includes
            }
        ]
    }
}
