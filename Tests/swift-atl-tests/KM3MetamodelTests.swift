//
// KM3MetamodelTests.swift
// swift-atl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for metamodels in KM3 with the commands of `swift-atl`.
@Suite("swift-atl - KM3 metamodels", .serialized)
struct KM3MetamodelTests {
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

    /// A query over the model.
    static let query = """
        query Pages = Library!Book.allInstances()->collect(b | b.pages + 1)->first().toString();

        """

    @Test("binds a KM3 metamodel given with --metamodel", arguments: ["ecore", "declared"])
    @MainActor
    func query(primitives: String) async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        try FileManager.default.createDirectory(at: directory.appendingPathComponent(".git"), withIntermediateDirectories: true)
        for (text, name) in [(Self.library, "Library.km3"), (Self.book, "book.xmi"), (Self.query, "Pages.atl")] {
            try text.write(to: directory.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }

        let result = try await executeSwiftATL(
            command: "query",
            arguments: [
                "Pages.atl", "--metamodel", "Library=Library.km3", "--source", "book.xmi",
                "--km3-primitives", primitives,
            ],
            workingDirectory: directory)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stderr.contains("registered under its name"), "\(result.stderr)")
        if primitives == "ecore" { #expect(result.stdout == consoleText("121\n"), "\(result.stdout)") }
    }
}
