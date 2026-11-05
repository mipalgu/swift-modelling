//
// MetamodelDiscoveryTests.swift
// swift-aql-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@testable import swift_aql

/// Tests how the metamodels beside a model are found.
@Suite("Metamodel discovery")
struct MetamodelDiscoveryTests {
    let discovery = MetamodelDiscovery()

    /// The text of a minimal metamodel with a namespace URI.
    func metamodel(_ uri: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="p" nsURI="\(uri)" nsPrefix="p"/>
        """
    }

    @Test("The namespace URI of a metamodel is its first nsURI attribute")
    func namespaceURI() {
        #expect(discovery.namespaceURI(declaredIn: metamodel("urn:shop")) == "urn:shop")
        #expect(discovery.namespaceURI(declaredIn: "<p nsURI = 'urn:a' x='1'/><q nsURI=\"urn:b\"/>") == "urn:a")
        #expect(discovery.namespaceURI(declaredIn: "<p nsURIx/><q nsURI=\"urn:b\"/>") == "urn:b")
        #expect(discovery.namespaceURI(declaredIn: "<p nsURI=urn:a/>") == nil)
        #expect(discovery.namespaceURI(declaredIn: "<p nsURI=\"\"/>") == nil)
        #expect(discovery.namespaceURI(declaredIn: "<p name=\"x\"/>") == nil)
    }

    @Test("A model refers to a namespace that is quoted or followed by a fragment")
    func references() {
        #expect(discovery.refers("xmlns:s=\"urn:shop\"", to: "urn:shop"))
        #expect(discovery.refers("{\"eClass\": \"urn:shop#//Item\"}", to: "urn:shop"))
        #expect(discovery.refers("xmlns:s='urn:shop'", to: "urn:shop"))
        #expect(!discovery.refers("xmlns:s=\"urn:shopping\"", to: "urn:shop"))
        #expect(!discovery.refers("no namespace here", to: "urn:shop"))
    }

    @Test("The metamodels beside a model whose namespaces it uses are found")
    func discoversSiblings() throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try metamodel("urn:shop").write(to: directory.appendingPathComponent("B.ecore"), atomically: true, encoding: .utf8)
        try metamodel("urn:other").write(to: directory.appendingPathComponent("A.ecore"), atomically: true, encoding: .utf8)
        try metamodel("urn:base").write(to: directory.appendingPathComponent("C.ECORE"), atomically: true, encoding: .utf8)
        try "not a metamodel".write(to: directory.appendingPathComponent("D.ecore"), atomically: true, encoding: .utf8)
        let model = directory.appendingPathComponent("m.xmi")
        try "<x xmlns:s=\"urn:shop\" xmlns:b=\"urn:base\"/>".write(to: model, atomically: true, encoding: .utf8)
        let found = try discovery.metamodels(for: [model.path]).map { URL(fileURLWithPath: $0).lastPathComponent }
        #expect(found == ["B.ecore", "C.ECORE"])
    }

    @Test("Several metamodels that declare a namespace a model uses are reported")
    func ambiguous() throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try metamodel("urn:shop").write(to: directory.appendingPathComponent("A.ecore"), atomically: true, encoding: .utf8)
        try metamodel("urn:shop").write(to: directory.appendingPathComponent("B.ecore"), atomically: true, encoding: .utf8)
        let model = directory.appendingPathComponent("m.xmi")
        try "<x xmlns:s=\"urn:shop\"/>".write(to: model, atomically: true, encoding: .utf8)
        #expect(throws: SwiftAQLError.self) { try discovery.metamodels(for: [model.path]) }
        do {
            _ = try discovery.metamodels(for: [model.path])
        } catch let SwiftAQLError.ambiguousMetamodels(uri, paths) {
            #expect(uri == "urn:shop")
            #expect(paths.map { URL(fileURLWithPath: $0).lastPathComponent } == ["A.ecore", "B.ecore"])
        }
    }

    @Test("A model that is itself an Ecore file, and an unreadable model, contribute nothing")
    func modelsThemselves() throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let ecore = directory.appendingPathComponent("A.ecore")
        try metamodel("urn:shop").write(to: ecore, atomically: true, encoding: .utf8)
        #expect(try discovery.metamodels(for: [ecore.path]).isEmpty)
        #expect(try discovery.metamodels(for: [directory.appendingPathComponent("missing.xmi").path]).isEmpty)
    }

    @Test("A metamodel shared by several models is found once")
    func sharedMetamodel() throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try metamodel("urn:shop").write(to: directory.appendingPathComponent("A.ecore"), atomically: true, encoding: .utf8)
        var models: [String] = []
        for name in ["m.xmi", "n.xmi"] {
            let model = directory.appendingPathComponent(name)
            try "<x xmlns:s=\"urn:shop\"/>".write(to: model, atomically: true, encoding: .utf8)
            models.append(model.path)
        }
        #expect(try discovery.metamodels(for: models).count == 1)
    }
}
