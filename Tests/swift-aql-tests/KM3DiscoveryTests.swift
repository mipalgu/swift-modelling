//
// KM3DiscoveryTests.swift
// swift-aql-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@testable import swift_aql

/// Tests for metamodels in formats other than Ecore: discovery beside a model, `--metamodel`
/// and `--km3-primitives`.
@Suite("swift-aql - KM3 and JSON metamodels", .serialized)
struct KM3DiscoveryTests {
    /// A KM3 metamodel of a small library.
    static let library = """
        package Library {
            class Book {
                attribute title : String;
                attribute pages : Integer;
            }
        }

        package PrimitiveTypes {
            datatype String;
            datatype Integer;
        }

        """

    /// A model of ``library`` that refers to the package by its name.
    static let book = """
        <?xml version="1.0" encoding="UTF-8"?>
        <Library:Book xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:Library="Library"
            title="Field Notes" pages="120"/>

        """

    /// A JSON metamodel with a namespace URI.
    static let jsonMetamodel = #"""
        { "eClass": "http://www.eclipse.org/emf/2002/Ecore#//EPackage", "name": "shop",
          "nsURI": "urn:example:shop", "nsPrefix": "shop" }
        """#

    /// Creates a directory with the metamodel and the model.
    static func directory() throws -> URL {
        let directory = try Fixture.temporaryDirectory()
        try FileManager.default.createDirectory(at: directory.appendingPathComponent(".git"), withIntermediateDirectories: true)
        try library.write(to: directory.appendingPathComponent("Library.km3"), atomically: true, encoding: .utf8)
        try book.write(to: directory.appendingPathComponent("book.xmi"), atomically: true, encoding: .utf8)
        return directory
    }

    @Test("A package without a namespace URI is referred to only by a namespace declaration")
    func declarations() {
        let discovery = MetamodelDiscovery()
        #expect(discovery.declares(#"<a xmlns:Library="Library"/>"#, namespace: "Library"))
        #expect(discovery.declares(#"<a xmlns = 'Library'/>"#, namespace: "Library"))
        #expect(discovery.declares(#"{"eClass": "Library#//Book"}"#, namespace: "Library"))
        #expect(!discovery.declares(#"<a name="Library"/>"#, namespace: "Library"))
        #expect(!discovery.declares(#"<a xmlns:l="Library.v2"/>"#, namespace: "Library"))
    }

    @Test("The namespaces of KM3 and JSON metamodels are found")
    func namespaces() async throws {
        let directory = try Self.directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let json = directory.appendingPathComponent("shop.json")
        try Self.jsonMetamodel.write(to: json, atomically: true, encoding: .utf8)
        let discovery = MetamodelDiscovery()
        #expect(
            await discovery.namespaces(ofMetamodelAt: directory.appendingPathComponent("Library.km3"))
                == [.init(uri: "Library", isName: true)])
        #expect(await discovery.namespaces(ofMetamodelAt: json) == [.init(uri: "urn:example:shop", isName: false)])
        #expect(discovery.namespaceURIs(declaredInJSON: Data(#"[{"eClass": "urn:x#//A"}]"#.utf8)).isEmpty)
        #expect(
            await discovery.metamodelFiles(in: directory).map(\.lastPathComponent) == ["Library.km3", "shop.json"])
    }

    @Test("A KM3 metamodel beside a model is found and registered under its name")
    func discoversKM3() async throws {
        let directory = try Self.directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try "<x name=\"Library\"/>".write(to: directory.appendingPathComponent("other.xmi"), atomically: true, encoding: .utf8)
        let discovery = MetamodelDiscovery()
        let found = try await discovery.metamodels(for: [directory.appendingPathComponent("book.xmi").path])
        let unrelated = try await discovery.metamodels(for: [directory.appendingPathComponent("other.xmi").path])
        #expect(found.map { URL(fileURLWithPath: $0).lastPathComponent } == ["Library.km3"])
        #expect(unrelated.isEmpty)
    }

    @Test("A model is read with the KM3 metamodel beside it, or given with --metamodel")
    func evaluatesWithKM3() async throws {
        let directory = try Self.directory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let discovered = try await runSwiftAQL(["query", "book.xmi", "self.pages + 1"], in: directory)
        let explicit = try await runSwiftAQL(
            ["query", "book.xmi", "self.title", "--metamodel", "Library.km3", "--km3-primitives", "declared"],
            in: directory)

        #expect(discovered.succeeded, "\(discovered.error)")
        #expect(discovered.output == "121\n")
        #expect(discovered.error.contains("registered under its name"), "\(discovered.error)")
        #expect(explicit.succeeded, "\(explicit.error)")
        #expect(explicit.output == "\"Field Notes\"\n")
    }

    @Test("A KM3 metamodel can be queried as a model")
    func queriesKM3() async throws {
        let directory = try Self.directory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let run = try await runSwiftAQL(["query", "Library.km3", "self.eClassifiers.name"], in: directory)

        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == "[\"Book\"]\n")
    }
}
