//
// ResultFormatterTests.swift
// swift-aql-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Testing

@testable import swift_aql

/// Tests how values are printed.
@Suite("Result formatting")
struct ResultFormatterTests {
    let formatter = ResultFormatter()

    @Test("Null prints as null")
    func null() {
        #expect(formatter.format(nil) == "null")
    }

    @Test("Strings print in double quotes with escapes")
    func strings() {
        #expect(formatter.format("Acme Corp") == "\"Acme Corp\"")
        #expect(formatter.format("say \"hi\"") == "\"say \\\"hi\\\"\"")
        #expect(formatter.format("a\\b") == "\"a\\\\b\"")
        #expect(formatter.format("one\ntwo\tthree\r") == "\"one\\ntwo\\tthree\\r\"")
        #expect(formatter.format("") == "\"\"")
    }

    @Test("Numbers and Booleans print as they are")
    func numbersAndBooleans() {
        #expect(formatter.format(42) == "42")
        #expect(formatter.format(-7) == "-7")
        #expect(formatter.format(500000.0) == "500000.0")
        #expect(formatter.format(3.14159) == "3.14159")
        #expect(formatter.format(Float(1.5)) == "1.5")
        #expect(formatter.format(true) == "true")
        #expect(formatter.format(false) == "false")
    }

    @Test("Collections print their elements in square brackets, whatever their kind")
    func collections() {
        #expect(formatter.format(EcoreValueArray([] as [any EcoreValue])) == "[]")
        #expect(formatter.format(EcoreValueArray(["a", "b"] as [any EcoreValue])) == "[\"a\", \"b\"]")
        let nested = EcoreValueArray([EcoreValueArray([1, 2] as [any EcoreValue]), 3] as [any EcoreValue], kind: .set)
        #expect(formatter.format(nested) == "[[1, 2], 3]")
        #expect(formatter.format(EcoreValueArray([1, 2.5] as [any EcoreValue], kind: .orderedSet)) == "[1, 2.5]")
    }

    @Test("Types print as their qualified names")
    func types() {
        #expect(formatter.format(AQLTypeDescriptor(packageName: "shop", typeName: "Item")) == "shop::Item")
        #expect(formatter.format(AQLTypeDescriptor(typeName: "String")) == "String")
    }

    @Test("Unresolved references print their URI and fragment")
    func unresolvedReferences() {
        let proxy = ResourceProxy(uri: "other.xmi", fragment: "//@items.0")
        #expect(formatter.format(proxy) == "unresolved(other.xmi#//@items.0)")
    }

    @Test("Objects print their class and label")
    @MainActor
    func objects() async throws {
        let evaluator = try await shopEvaluator()
        #expect(formatter.format(try await evaluator.evaluate("self")) == "Shop(Corner Shop)")
        #expect(
            formatter.format(try await evaluator.evaluate("self.items"))
                == "[Item(Green \"Sencha\" Tea), Item(Teapot)]")
        #expect(formatter.format(try await evaluator.evaluate("self.orders->first()")) == "Order(2)")
        #expect(formatter.format(try await evaluator.evaluate("self.markers->first()")) == "Marker")
    }

    @Test("The label attribute is name, else the first string attribute, else the first attribute")
    @MainActor
    func labelAttributes() async throws {
        let evaluator = try await shopEvaluator()
        let shop = try #require(try await evaluator.evaluate("self") as? any EObject)
        let item = try #require(try await evaluator.evaluate("self.items->first()") as? any EObject)
        let order = try #require(try await evaluator.evaluate("self.orders->first()") as? any EObject)
        let marker = try #require(try await evaluator.evaluate("self.markers->first()") as? any EObject)
        #expect(ResultFormatter.labelAttribute(of: try #require(shop.eClass as? EClass))?.name == "name")
        #expect(ResultFormatter.labelAttribute(of: try #require(item.eClass as? EClass))?.name == "title")
        #expect(ResultFormatter.labelAttribute(of: try #require(order.eClass as? EClass))?.name == "quantity")
        #expect(ResultFormatter.labelAttribute(of: try #require(marker.eClass as? EClass)) == nil)
        #expect(formatter.label(of: marker) == nil)
    }
}
