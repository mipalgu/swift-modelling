//
// ExpressionEvaluatorTests.swift
// swift-aql-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Foundation
import Testing

@testable import swift_aql

/// Tests the variables that expressions see, the context object and the errors of evaluation.
@Suite("Expression evaluation")
@MainActor
struct ExpressionEvaluatorTests {
    let formatter = ResultFormatter()

    /// Evaluates an expression against the shop fixture and formats its value.
    func evaluate(_ expression: String, context: String? = nil) async throws -> String {
        let evaluator = try await shopEvaluator()
        guard let context else { return formatter.format(try await evaluator.evaluate(expression)) }
        let selfObject = try await evaluator.contextObject(for: context)
        return formatter.format(try await evaluator.evaluate(expression, self: selfObject))
    }

    @Test("Variable names are class names with a lower-case first letter")
    func variableNames() {
        #expect(ExpressionEvaluator.variableName(ofClass: "Company") == "company")
        #expect(ExpressionEvaluator.variableName(ofClass: "ShopItem") == "shopItem")
        #expect(ExpressionEvaluator.variableName(ofClass: "x") == "x")
        #expect(ExpressionEvaluator.variableName(ofClass: "") == "")
    }

    @Test("self and the first root object of each class are bound")
    func bindings() async throws {
        let evaluator = try await shopEvaluator()
        let names = evaluator.bindings(self: nil).map(\.name)
        #expect(names == ["self", "shop"])
        #expect(try await evaluate("self.name") == "\"Corner Shop\"")
        #expect(try await evaluate("shop.name") == "\"Corner Shop\"")
        #expect(try await evaluate("shop.founded") == "2001")
    }

    @Test("Attributes have the types that the discovered metamodel declares")
    func typedAttributes() async throws {
        #expect(try await evaluate("shop.items.price") == "[4.5, 25.0]")
        #expect(try await evaluate("shop.items.available") == "[true, false]")
        #expect(try await evaluate("shop.items->select(i | i.size = shop::Size::LARGE).title") == "[\"Teapot\"]")
        #expect(try await evaluate("shop.orders->first().item.title") == "\"Green \\\"Sencha\\\" Tea\"")
    }

    @Test("An explicit metamodel is used instead of discovery")
    func explicitMetamodel() async throws {
        let evaluator = try await shopEvaluator(metamodels: [try Fixture.shop(Fixture.shopMetamodel).path])
        #expect(formatter.format(try await evaluator.evaluate("shop.items.stock->sum()")) == "15")
    }

    @Test("All models are visible to whole-model services")
    func allInstances() async throws {
        #expect(try await evaluate("shop::Shop.allInstances().name") == "[\"Corner Shop\", \"Kiosk\"]")
    }

    @Test("The context is found by identifier, fragment path and name")
    func contexts() async throws {
        #expect(try await evaluate("self.name", context: "corner") == "\"Corner Shop\"")
        #expect(try await evaluate("self.title", context: "tea") == "\"Green \\\"Sencha\\\" Tea\"")
        #expect(try await evaluate("self.quantity", context: "first-order") == "2")
        #expect(try await evaluate("self.title", context: "/0/@items.1") == "\"Teapot\"")
        #expect(try await evaluate("self.name", context: "/1") == "\"Kiosk\"")
        #expect(try await evaluate("self.name", context: "Kiosk") == "\"Kiosk\"")
        #expect(try await evaluate("self.price", context: "Teapot") == "25.0")
        #expect(try await evaluate("shop.name", context: "Kiosk") == "\"Corner Shop\"")
    }

    @Test("A context that matches no object is reported")
    func missingContext() async throws {
        let evaluator = try await shopEvaluator()
        await #expect(throws: SwiftAQLError.contextNotFound("nobody")) { try await evaluator.contextObject(for: "nobody") }
        await #expect(throws: SwiftAQLError.contextNotFound("/0/@items.9")) {
            try await evaluator.contextObject(for: "/0/@items.9")
        }
        await #expect(throws: SwiftAQLError.contextNotFound("/5")) { try await evaluator.contextObject(for: "/5") }
    }

    @Test("A name shared by several objects is reported")
    func ambiguousContext() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = try Fixture.copyShop(to: directory)
        let text = try String(contentsOf: model, encoding: .utf8).replacingOccurrences(of: "Kiosk", with: "Corner Shop")
        try text.write(to: model, atomically: true, encoding: .utf8)
        let loaded = try await ModelLoader(metamodels: [], settings: .init()).load([model.path])
        let evaluator = await ExpressionEvaluator(models: loaded, options: .standard)
        await #expect(throws: SwiftAQLError.ambiguousContext("Corner Shop", 2)) {
            try await evaluator.contextObject(for: "Corner Shop")
        }
    }

    @Test("Invalid expressions are reported with their positions")
    func invalidExpression() async throws {
        let evaluator = try await shopEvaluator()
        do {
            _ = try await evaluator.evaluate("shop.items->select(i | )")
            Issue.record("The expression should not parse")
        } catch let SwiftAQLError.invalidExpression(problems) {
            #expect(!problems.isEmpty)
            #expect(problems.allSatisfy { $0.hasPrefix("line 1, column ") })
        }
    }

    @Test("Unknown variables and failing operations are reported")
    func evaluationErrors() async throws {
        let evaluator = try await shopEvaluator()
        await #expect(throws: SwiftAQLError.evaluationFailed("Variable 'warehouse' not found")) {
            try await evaluator.evaluate("warehouse.name")
        }
        await #expect(throws: SwiftAQLError.self) { try await evaluator.evaluate("'a' - 1") }
    }

    @Test("A string joined with a number gives the text of both, as in Eclipse AQL")
    func stringConcatenation() async throws {
        let evaluator = await ExpressionEvaluator(models: [], options: .standard)
        #expect(formatter.format(try await evaluator.evaluate("'a' + 1")) == "\"a1\"")
    }

    @Test("Without models, expressions see null as self")
    func noModels() async throws {
        let evaluator = await ExpressionEvaluator(models: [], options: .standard)
        #expect(formatter.format(try await evaluator.evaluate("Sequence{1, 2, 3}->sum()")) == "6")
        #expect(formatter.format(try await evaluator.evaluate("self")) == "null")
    }

    @Test("Engine aliases keep models with the same file name apart")
    func aliases() async throws {
        let loaded = try await ModelLoader(metamodels: [], settings: .init()).load([try Fixture.shop(Fixture.shopModel).path])
        let model = try #require(loaded.first)
        #expect(ExpressionEvaluator.alias(of: model, at: 0) != ExpressionEvaluator.alias(of: model, at: 1))
    }
}
