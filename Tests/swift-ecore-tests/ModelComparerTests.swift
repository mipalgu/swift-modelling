//
// ModelComparerTests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import Testing

@testable import swift_ecore

/// Tests for how the comparer describes references that lead to no object of the compared model.
///
/// The readers keep a reference that they cannot resolve as a proxy, so these references are
/// set on models in memory.
@Suite("swift-ecore compare - References to objects outside the model")
@MainActor
struct ModelComparerTests {
    /// Reads a fixture of the comparison tests into a resource set.
    ///
    /// - Parameters:
    ///   - name: The file name of the model.
    ///   - resourceSet: The resource set that receives the model.
    /// - Returns: The document of the model, read with the version 1 shop metamodel.
    private func document(_ name: String, in resourceSet: ResourceSet) async throws -> ModelDocument {
        let metamodel = try loadTestResource(named: "shop-v1.ecore", subdirectory: "compare")
        let url = try loadTestResource(named: name, subdirectory: "compare")
        let packages = try await ModelIO.registerMetamodels(at: [metamodel], in: resourceSet)
        let loaded = try await ModelIO.load(url: url, resourceSet: resourceSet)
        return ModelDocument(
            path: url.path, url: url, format: loaded.format, resource: loaded.resource, resourceSet: resourceSet,
            packages: [], metamodels: packages, diagnostics: loaded.diagnostics)
    }

    /// The identifier of the object of a model whose `name` or `number` is a value.
    ///
    /// - Parameters:
    ///   - value: The value that names the object.
    ///   - document: The model.
    /// - Returns: The identifier of the object.
    private func identifier(of value: String, in document: ModelDocument) async throws -> EUUID {
        let objects = await document.resource.getAllObjects().compactMap { $0 as? DynamicEObject }
        let object = objects.first { ($0.eGet("name") as? String) == value || ($0.eGet("number") as? String) == value }
        return try #require(object).id
    }

    /// Compares the shop model with a copy whose first order refers to a customer.
    ///
    /// - Parameter customer: Gives the identifier of the customer of the first order of the copy.
    /// - Returns: The text of the change of the customer of the first order, if there is one.
    private func changedCustomer(
        _ customer: (ModelDocument, ResourceSet) async throws -> EUUID
    ) async throws -> String? {
        let original = try await document("shop-v1.xmi", in: ResourceSet())
        let revisedSet = ResourceSet()
        let revised = try await document("shop-v1.xmi", in: revisedSet)
        let order = try await identifier(of: "A-1", in: revised)
        let target = try await customer(revised, revisedSet)
        #expect(await revised.resource.eSet(objectId: order, feature: "customer", value: target))

        let outcome = await ModelComparer(
            original: await ModelCatalogue.build(for: original), revised: await ModelCatalogue.build(for: revised),
            filter: ComparisonFilter([])
        ).compare()
        withExtendedLifetime((original, revised, revisedSet)) {}
        return outcome.differences.first { $0.property == "customer" }?.text
    }

    @Test("describes a reference to an object that exists nowhere as an unresolved object")
    func danglingIdentifier() async throws {
        let text = try await changedCustomer { _, _ in EUUID() }

        #expect(text == "~ object Order 'A-1' (//@orders.0) customer: Customer 'Ada' -> unresolved object")
    }

    @Test("describes a reference to an object of another document with that document")
    func objectOfAnotherDocument() async throws {
        let text = try await changedCustomer { _, resourceSet in
            let other = try await document("shop-v1-revised.xmi", in: resourceSet)
            return try await identifier(of: "Grace", in: other)
        }

        #expect(text == "~ object Order 'A-1' (//@orders.0) customer: Customer 'Ada' -> Customer 'Grace' in shop-v1-revised.xmi")
    }
}
