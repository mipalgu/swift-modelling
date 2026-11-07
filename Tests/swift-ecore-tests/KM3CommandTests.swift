//
// KM3CommandTests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for metamodels in KM3: reading, converting, and using them with `--metamodel`.
@Suite("swift-ecore - KM3 metamodels", .serialized)
struct KM3CommandTests {
    /// A KM3 metamodel of a small library.
    static let library = """
        package Library {
            class Book {
                attribute title : String;
                attribute pages : Integer;
                reference author : Writer;
            }
            class Writer {
                attribute name : String;
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

    /// The warning that the package is registered under its name.
    static let registeredUnderName = "The package 'Library' has no 'nsURI' and is registered under its name"

    /// A directory with the metamodel and the model.
    struct Files {
        /// The directory.
        let directory: URL

        /// The KM3 metamodel.
        var metamodel: URL { directory.appendingPathComponent("Library.km3") }

        /// The model.
        var model: URL { directory.appendingPathComponent("book.xmi") }

        /// Creates the files.
        init() throws {
            directory = try createTemporaryDirectory()
            try KM3CommandTests.library.write(to: metamodel, atomically: true, encoding: .utf8)
            try KM3CommandTests.book.write(to: model, atomically: true, encoding: .utf8)
        }

        /// A file in the directory.
        func file(_ name: String) -> URL { directory.appendingPathComponent(name) }

        /// Removes the directory.
        func remove() { cleanupTemporaryDirectory(directory) }
    }

    @Test("inspects a KM3 metamodel, with its primitive types as the options say")
    @MainActor
    func inspect() async throws {
        let files = try Files()
        defer { files.remove() }

        let standard = try await executeSwiftEcore(command: "inspect", arguments: [files.metamodel.path])
        let declared = try await executeSwiftEcore(
            command: "inspect", arguments: [files.metamodel.path, "--km3-primitives", "declared"])

        #expect(standard.succeeded, "\(standard.stdout)\(standard.stderr)")
        #expect(standard.stdout.hasPrefix("Metamodel: Library.km3 (KM3)\n"), "\(standard.stdout)")
        #expect(standard.stdout.contains("  Class Book\n"), "\(standard.stdout)")
        #expect(!standard.stdout.contains("Package PrimitiveTypes"), "\(standard.stdout)")
        #expect(standard.stderr.contains("warning: \(files.metamodel.path): \(Self.registeredUnderName)"))
        #expect(declared.succeeded, "\(declared.stdout)\(declared.stderr)")
        #expect(declared.stdout.contains("Package PrimitiveTypes"), "\(declared.stdout)")
    }

    @Test("queries a KM3 metamodel")
    @MainActor
    func query() async throws {
        let files = try Files()
        defer { files.remove() }

        let result = try await executeSwiftEcore(command: "query", arguments: [files.metamodel.path, "--query", "classes"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.contains("* Book\n* Writer\n"), "\(result.stdout)")
    }

    @Test("validates a model against a KM3 metamodel given with --metamodel")
    @MainActor
    func validateModel() async throws {
        let files = try Files()
        defer { files.remove() }

        let inspection = try await executeSwiftEcore(
            command: "inspect", arguments: [files.model.path, "--metamodel", files.metamodel.path])
        let validation = try await executeSwiftEcore(
            command: "validate", arguments: [files.model.path, "--metamodel", files.metamodel.path])

        #expect(inspection.succeeded, "\(inspection.stdout)\(inspection.stderr)")
        #expect(inspection.stdout.contains("Metamodels: Library\n"), "\(inspection.stdout)")
        #expect(!validation.succeeded)
        #expect(validation.stdout.contains("Feature 'author' needs at least 1 value(s)"), "\(validation.stdout)")
    }

    @Test("converts KM3 to Ecore and JSON, and back to KM3")
    @MainActor
    func convert() async throws {
        let files = try Files()
        defer { files.remove() }
        let ecore = files.file("Library.ecore")
        let json = files.file("Library.json")
        let km3 = files.file("Library-copy.km3")

        let toEcore = try await executeSwiftEcore(command: "convert", arguments: [files.metamodel.path, ecore.path])
        let toJSON = try await executeSwiftEcore(command: "convert", arguments: [files.metamodel.path, json.path])
        let toKM3 = try await executeSwiftEcore(command: "convert", arguments: [ecore.path, km3.path])
        let fromJSON = try await executeSwiftEcore(command: "inspect", arguments: [json.path])
        let model = try await executeSwiftEcore(command: "convert", arguments: [files.model.path, files.file("book.km3").path])

        for result in [toEcore, toJSON, toKM3, fromJSON] {
            #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        }
        let ecoreText = try String(contentsOf: ecore, encoding: .utf8)
        #expect(ecoreText.contains("name=\"Book\""), "\(ecoreText)")
        #expect(ecoreText.contains("EInt"), "\(ecoreText)")
        let km3Text = try String(contentsOf: km3, encoding: .utf8)
        #expect(km3Text.contains("package Library {"), "\(km3Text)")
        #expect(km3Text.contains("attribute pages : Integer;"), "\(km3Text)")
        #expect(fromJSON.stdout.contains("  Class Writer\n"), "\(fromJSON.stdout)")
        #expect(!model.succeeded)
        #expect(model.stderr.contains("is a model, which cannot be written as km3"), "\(model.stderr)")
    }
}
