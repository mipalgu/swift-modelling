//
// ModelPlan.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//

/// The models that a command line binds, checked against each other.
///
/// The plan reads the values of `--model`, `--target` and `--store`, and checks that every name
/// and alias is given once and that every stored model is one that `--model` reads.
struct ModelPlan: Sendable, Equatable {
    /// The models that are read from their files, in command line order.
    let sources: [ModelBinding]

    /// The models that are created empty and stored in their files, in command line order.
    let targets: [ModelBinding]

    /// The models read from files that are stored after the run.
    let stores: [StoreRequest]

    /// Every binding, the sources before the targets, which is the order in which programs look
    /// up unqualified type names.
    var bindings: [ModelBinding] { sources + targets }

    /// Creates a plan from bindings that have been read already.
    ///
    /// - Parameters:
    ///   - sources: The models read from their files.
    ///   - targets: The models created empty (default: none).
    ///   - stores: The models stored after the run (default: none).
    /// - Throws: ``SwiftEpsilonError/duplicateModelName(_:)`` if a name or alias is given twice,
    ///   and ``SwiftEpsilonError/unknownStoredModel(_:)`` if a stored model is not a source.
    init(sources: [ModelBinding], targets: [ModelBinding] = [], stores: [StoreRequest] = []) throws {
        var seen = Set<String>()
        for name in (sources + targets).flatMap(\.names) where !seen.insert(name).inserted {
            throw SwiftEpsilonError.duplicateModelName(name)
        }
        for store in stores where !sources.contains(where: { $0.names.contains(store.name) }) {
            throw SwiftEpsilonError.unknownStoredModel(store.name)
        }
        self.sources = sources
        self.targets = targets
        self.stores = stores
    }

    /// Creates a plan from the values of the command line options.
    ///
    /// - Parameters:
    ///   - models: The values of `--model`.
    ///   - targets: The values of `--target` (default: none).
    ///   - stores: The values of `--store` (default: none).
    /// - Throws: The errors of reading a ``ModelBinding`` or a ``StoreRequest``, and those of
    ///   ``init(sources:targets:stores:)``.
    init(models: [String], targets: [String] = [], stores: [String] = []) throws {
        try self.init(
            sources: models.map(ModelBinding.init(parsing:)), targets: targets.map(ModelBinding.init(parsing:)),
            stores: stores.map(StoreRequest.init(parsing:)))
    }
}
