//
// ContainmentPathTests.swift
// swift-aql-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@testable import swift_aql

/// Tests fragment paths and the identifiers of XMI documents.
@Suite("Containment paths")
struct ContainmentPathTests {
    typealias Step = ContainmentPath.Step

    @Test("Fragment paths name a root and the steps from it")
    func fragments() {
        #expect(ContainmentPath(fragment: "/") == ContainmentPath(root: 0, steps: []))
        #expect(ContainmentPath(fragment: "/1") == ContainmentPath(root: 1, steps: []))
        #expect(
            ContainmentPath(fragment: "//@departments.0/@employees.2")
                == ContainmentPath(root: 0, steps: [Step(feature: "departments", index: 0), Step(feature: "employees", index: 2)]))
        #expect(
            ContainmentPath(fragment: "/1/@items.3")
                == ContainmentPath(root: 1, steps: [Step(feature: "items", index: 3)]))
        #expect(ContainmentPath(fragment: "/0/@owner") == ContainmentPath(root: 0, steps: [Step(feature: "owner", index: 0)]))
    }

    @Test("Text that is not a fragment path is rejected", arguments: [
        "company1", "", "/-1", "/0/items.1", "/0/@items.x", "/0/@.1", "/0/@items.1.2", "/0/@items.-1",
    ])
    func invalidFragments(_ text: String) {
        #expect(ContainmentPath(fragment: text) == nil)
    }

    @Test("A path describes itself as a fragment path")
    func description() {
        let path = ContainmentPath(root: 1, steps: [Step(feature: "items", index: 0), Step(feature: "parts", index: 2)])
        #expect(path.description == "/1/@items.0/@parts.2")
        #expect(ContainmentPath(fragment: path.description) == path)
    }

    @Test("Identifiers are indexed within a document with several roots")
    func wrappedDocument() {
        let xmi = """
            <?xml version="1.0"?>
            <xmi:XMI xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:s="urn:s">
              <s:Shop xmi:id="a"><items xmi:id="b"/><orders/><items xmi:id="c"><parts xmi:id="d"/></items></s:Shop>
              <s:Shop xmi:id="e"><orders xmi:id="f"/></s:Shop>
            </xmi:XMI>
            """
        let index = XMIIdentifierIndex(data: Data(xmi.utf8))
        #expect(index.path(of: "a") == ContainmentPath(root: 0, steps: []))
        #expect(index.path(of: "b") == ContainmentPath(root: 0, steps: [Step(feature: "items", index: 0)]))
        #expect(
            index.path(of: "d")
                == ContainmentPath(root: 0, steps: [Step(feature: "items", index: 1), Step(feature: "parts", index: 0)]))
        #expect(index.path(of: "e") == ContainmentPath(root: 1, steps: []))
        #expect(index.path(of: "f") == ContainmentPath(root: 1, steps: [Step(feature: "orders", index: 0)]))
        #expect(index.path(of: "missing") == nil)
    }

    @Test("Identifiers are indexed within a document with a single root")
    func singleRoot() {
        let xmi = """
            <s:Shop xmlns:xmi="http://www.omg.org/XMI" xmlns:s="urn:s" xmi:id="a"><items xmi:id="b"/></s:Shop>
            """
        let index = XMIIdentifierIndex(data: Data(xmi.utf8))
        #expect(index.path(of: "a") == ContainmentPath(root: 0, steps: []))
        #expect(index.path(of: "b") == ContainmentPath(root: 0, steps: [Step(feature: "items", index: 0)]))
    }

    @Test("A document that is not XML has no identifiers")
    func notXML() {
        #expect(XMIIdentifierIndex(data: Data("{\"json\": true}".utf8)).paths.isEmpty)
        #expect(XMIIdentifierIndex(data: Data()).paths.isEmpty)
    }
}
