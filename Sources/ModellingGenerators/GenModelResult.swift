//
// GenModelResult.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation

/// The outcome of importing Ecore models into a generator model.
///
/// The result names the file that was written and summarises what it holds, and keeps
/// the resource set so that the generator model can be inspected or processed further.
public struct GenModelResult: Sendable {
    /// The generator model file that was written.
    public let url: URL

    /// The resource set holding the generator model and the source models it describes.
    public let resourceSet: ResourceSet

    /// The resource holding the generator model.
    public let resource: Resource

    /// The number of generator packages, including nested ones.
    public let packageCount: Int

    /// The number of generator classes.
    public let classCount: Int

    /// The number of generator enumerations.
    public let enumCount: Int

    /// The number of generator data types.
    public let dataTypeCount: Int

    /// The number of generator features.
    public let featureCount: Int

    /// The number of generator operations.
    public let operationCount: Int

    /// Whether the settings of an existing generator model were reconciled.
    public let reloaded: Bool
}
