//
// ExpressionSourceTests.swift
// swift-aql-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
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

    @Test("An empty expression is reported")
    func empty() {
        #expect(throws: SwiftAQLError.emptyExpression) { try ExpressionSource.text("  \n ").text() }
        #expect(throws: SwiftAQLError.emptyExpression) { try ExpressionSource.text("").text() }
    }
}
