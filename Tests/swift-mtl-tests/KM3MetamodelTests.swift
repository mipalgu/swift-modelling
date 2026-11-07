//
// KM3MetamodelTests.swift
// swift-mtl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for metamodels in KM3 with `swift-mtl generate`.
@Suite("swift-mtl generate - KM3 metamodels", .serialized)
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

    /// A module that writes the title and the number of pages after the last one.
    static let template = """
        [module Pages('Library')]

        [template public main(b : Library::Book)]
        [file ('pages.txt', 'overwrite', 'UTF-8')]
        [b.title/]: [b.pages + 1/]
        [/file]
        [/template]

        """

    @Test("reads a model with a KM3 metamodel given with --metamodel or --model")
    @MainActor
    func generate() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        try FileManager.default.createDirectory(at: directory.appendingPathComponent(".git"), withIntermediateDirectories: true)
        for (text, name) in [(Self.library, "Library.km3"), (Self.book, "book.xmi"), (Self.template, "Pages.mtl")] {
            try text.write(to: directory.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }
        let output = directory.appendingPathComponent("out")

        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                directory.appendingPathComponent("Pages.mtl").path,
                "--metamodel", directory.appendingPathComponent("Library.km3").path,
                "--model", directory.appendingPathComponent("book.xmi").path, "--output", output.path,
            ],
            workingDirectory: directory)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stderr.contains("registered under its name"), "\(result.stderr)")
        let text = try? String(contentsOf: output.appendingPathComponent("pages.txt"), encoding: .utf8)
        #expect(text == "Field Notes: 121\n")
    }
}
