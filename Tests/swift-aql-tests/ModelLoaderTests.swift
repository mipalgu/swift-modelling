//
// ModelLoaderTests.swift
// swift-aql-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import ModellingCommandLine
import Testing

@testable import swift_aql

/// Tests how models and metamodels are loaded.
@Suite("Model loading")
@MainActor
struct ModelLoaderTests {
    @Test("A missing model is reported")
    func missingModel() async throws {
        await #expect(throws: SwiftAQLError.modelNotFound("missing.xmi")) {
            try await ModelLoader(metamodels: [], settings: .init()).load(["missing.xmi"])
        }
    }

    @Test("A missing metamodel is reported")
    func missingMetamodel() async throws {
        let model = try Fixture.shop(Fixture.shopModel).path
        await #expect(throws: MetamodelRegistrationError.self) {
            try await ModelLoader(metamodels: ["missing.ecore"], settings: .init()).load([model])
        }
    }

    @Test("Metamodels given on the command line replace discovery")
    func effectiveMetamodels() throws {
        let model = try Fixture.shop(Fixture.shopModel).path
        #expect(try ModelLoader(metamodels: ["X.ecore"], settings: .init()).effectiveMetamodels(for: [model]) == ["X.ecore"])
        let discovered = try ModelLoader(metamodels: [], settings: .init()).effectiveMetamodels(for: [model])
        #expect(discovered.map { URL(fileURLWithPath: $0).lastPathComponent } == [Fixture.shopMetamodel])
    }

    @Test("A model is loaded with its roots and identifiers")
    func loadsModel() async throws {
        let loaded = try await ModelLoader(metamodels: [], settings: .init()).load([try Fixture.shop(Fixture.shopModel).path])
        let model = try #require(loaded.first)
        #expect(model.roots.count == 2)
        #expect(model.identifiers.path(of: "tea") == ContainmentPath(fragment: "/0/@items.0"))
    }

    @Test("An Ecore file can be queried as a model")
    func ecoreModel() async throws {
        let loaded = try await ModelLoader(metamodels: [], settings: .init()).load([try Fixture.shop(Fixture.shopMetamodel).path])
        let evaluator = await ExpressionEvaluator(models: loaded, options: .standard)
        #expect(ResultFormatter().format(try await evaluator.evaluate("self.name")) == "\"shop\"")
        #expect(
            ResultFormatter().format(try await evaluator.evaluate("self.eClassifiers.name"))
                == "[\"Size\", \"Shop\", \"Item\", \"Order\", \"Marker\"]")
    }

    @Test("A model in JSON is loaded")
    func jsonModel() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.copyItem(
            at: try Fixture.shop(Fixture.shopMetamodel), to: directory.appendingPathComponent(Fixture.shopMetamodel))
        let json = directory.appendingPathComponent("shop.json")
        try """
            {"eClass": "http://www.example.org/shop#//Shop", "name": "Stall", "founded": 2020,
             "items": [{"eClass": "http://www.example.org/shop#//Item", "title": "Mug", "price": 7.5}]}
            """.write(to: json, atomically: true, encoding: .utf8)
        let loaded = try await ModelLoader(metamodels: [], settings: .init()).load([json.path])
        let evaluator = await ExpressionEvaluator(models: loaded, options: .standard)
        #expect(ResultFormatter().format(try await evaluator.evaluate("shop.name + ' ' + shop.founded.toString()")) == "\"Stall 2020\"")
        #expect(ResultFormatter().format(try await evaluator.evaluate("shop.items.price")) == "[7.5]")
    }
}
