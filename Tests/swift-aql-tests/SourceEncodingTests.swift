//
// SourceEncodingTests.swift
// swift-aql-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for the character encoding in which swift-aql reads expression files, and for models
/// whose file extension names no format.
@Suite("swift-aql - source encodings and model formats", .serialized)
struct SourceEncodingTests {
    /// An expression whose comment and string are encoded differently in UTF-8 and ISO-8859-1.
    static let expression = "-- Größe des Lagers\nshop.items.stock->sum().toString() + ' Stück'\n"

    /// The value of ``expression`` for the shop fixture.
    static let value = "\"15 Stück\"\n"

    /// The warning that a file was read as ISO-8859-1.
    static let fallbackWarning = "The text is not valid UTF-8 and was read as ISO-8859-1"

    /// Creates a directory with the shop fixture and the expression in ISO-8859-1.
    ///
    /// - Returns: The directory.
    /// - Throws: An error if a file cannot be written.
    static func directory() throws -> URL {
        let directory = try Fixture.temporaryDirectory()
        try Fixture.copyShop(to: directory)
        try FileManager.default.createDirectory(at: directory.appendingPathComponent(".git"), withIntermediateDirectories: true)
        try Data(expression.unicodeScalars.map { UInt8($0.value) })
            .write(to: directory.appendingPathComponent("stock.aql"))
        return directory
    }

    @Test("reads an expression file that is not UTF-8 as ISO-8859-1, with a warning", arguments: [true, false])
    func latin1Fallback(query: Bool) async throws {
        let directory = try Self.directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let arguments = query
            ? ["query", Fixture.shopModel, "--query-file", "stock.aql", "--context", "corner"]
            : ["evaluate", "--model", Fixture.shopModel, "--expression-file", "stock.aql"]

        let run = try await runSwiftAQL(arguments, in: directory)

        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == Self.value)
        #expect(run.error.contains("warning: stock.aql: line 1, column 6: \(Self.fallbackWarning)"), "\(run.error)")
    }

    @Test("reads an expression file in the encoding given with --encoding or the configuration file")
    func explicitEncoding() async throws {
        let directory = try Self.directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let arguments = ["evaluate", "--model", Fixture.shopModel, "--expression-file", "stock.aql"]

        let explicit = try await runSwiftAQL(arguments + ["--encoding", "windows-1252"], in: directory)
        try #"{ "encoding": "ISO-8859-1" }"#.write(
            to: directory.appendingPathComponent(".swift-modelling.json"), atomically: true, encoding: .utf8)
        let configured = try await runSwiftAQL(arguments, in: directory)
        let overridden = try await runSwiftAQL(arguments + ["--encoding", "UTF-8"], in: directory)

        #expect(explicit.succeeded, "\(explicit.error)")
        #expect(explicit.output == Self.value)
        #expect(!explicit.error.contains(Self.fallbackWarning), "\(explicit.error)")
        #expect(configured.succeeded, "\(configured.error)")
        #expect(configured.output == Self.value)
        #expect(!configured.error.contains(Self.fallbackWarning), "\(configured.error)")
        #expect(!overridden.succeeded)
        #expect(overridden.error.contains("stock.aql"), "\(overridden.error)")
        #expect(overridden.error.contains("not valid UTF-8"), "\(overridden.error)")
    }

    @Test("reads a model whose extension names no format in the format of its contents")
    func modelWithUnknownExtension() async throws {
        let directory = try Self.directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.copyItem(
            at: directory.appendingPathComponent(Fixture.shopModel), to: directory.appendingPathComponent("shop.model"))
        try "Corner Shop: 2 items\n".write(
            to: directory.appendingPathComponent("shop.txt"), atomically: true, encoding: .utf8)

        let known = try await runSwiftAQL(
            ["query", "shop.model", "self.items->size()", "--metamodel", Fixture.shopMetamodel], in: directory)
        let unknown = try await runSwiftAQL(
            ["query", "shop.txt", "self", "--metamodel", Fixture.shopMetamodel], in: directory)

        #expect(known.succeeded, "\(known.error)")
        #expect(known.output == "2\n")
        #expect(!unknown.succeeded)
        for format in ["xmi", "json", "ecore", "shop.txt"] {
            #expect(unknown.error.contains(format), "\(format) is missing from: \(unknown.error)")
        }
    }
}
