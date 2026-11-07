//
// ExpressionSourceTests.swift
// swift-aql-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation
import ModellingCommandLine
import Testing

@testable import swift_aql

/// Tests where expressions come from.
@Suite("Expression sources")
struct ExpressionSourceTests {
    @Test("Exactly one source is selected")
    func selection() {
        #expect(ExpressionSource.select(texts: ["a"], file: nil) == .text("a"))
        #expect(ExpressionSource.select(texts: [nil, "b"], file: nil) == .text("b"))
        #expect(ExpressionSource.select(texts: [nil], file: "q.aql") == .file("q.aql"))
        #expect(ExpressionSource.select(texts: [nil, nil], file: nil) == nil)
        #expect(ExpressionSource.select(texts: ["a", "b"], file: nil) == nil)
        #expect(ExpressionSource.select(texts: ["a"], file: "q.aql") == nil)
    }

    @Test("Text is returned as given")
    func text() throws {
        #expect(try ExpressionSource.text("self.name").text() == "self.name")
    }

    @Test("A file is read")
    func file() throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("query.aql")
        try "self.items\n  ->size()\n".write(to: url, atomically: true, encoding: .utf8)
        #expect(try ExpressionSource.file(url.path).text() == "self.items\n  ->size()\n")
    }

    @Test("A missing file is reported")
    func missingFile() {
        #expect(throws: SwiftAQLError.expressionFileNotFound("missing.aql")) {
            try ExpressionSource.file("missing.aql").text()
        }
    }

    @Test("A file that is not UTF-8 is read as ISO-8859-1")
    func latin1File() throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("query.aql")
        let expression = "self.name = 'Café'\n"
        try Data(expression.unicodeScalars.map { UInt8($0.value) }).write(to: url)
        #expect(try ExpressionSource.file(url.path).text() == expression)
        #expect(try ExpressionSource.file(url.path).text(encoding: .isoLatin1) == expression)
        #expect(try ExpressionSource.file(url.path).text(encoding: .windows1252) == expression)
        #expect(throws: SourceFileError.malformed(path: url.path, encoding: .utf8)) {
            try ExpressionSource.file(url.path).text(encoding: .utf8)
        }
    }

    @Test("A missing file is reported whatever the encoding")
    func missingFileWithEncoding() {
        #expect(throws: SwiftAQLError.expressionFileNotFound("missing.aql")) {
            try ExpressionSource.file("missing.aql").text(encoding: .isoLatin1)
        }
    }

    @Test("An empty expression is reported")
    func empty() {
        #expect(throws: SwiftAQLError.emptyExpression) { try ExpressionSource.text("  \n ").text() }
        #expect(throws: SwiftAQLError.emptyExpression) { try ExpressionSource.text("").text() }
    }
}
