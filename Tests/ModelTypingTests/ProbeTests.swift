//
//  ProbeTests.swift
//  ModelTypingTests
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import AQL
import ATL
import Foundation
import MTL
import Testing

/// Pins the parser output shapes that footprint extraction relies on.
///
/// If one of these fails after a dependency update, the extractors need to
/// learn the new shape before their own tests can be trusted.
@Suite("Parser output shapes")
struct ProbeTests {
    /// The AQL tree printer used to describe parsed expressions.
    private let printer = AQLTreePrinter()

    /// Parses an AQL expression and prints its tree.
    private func tree(_ source: String) throws -> String {
        printer.print(try #require(AQLParser().parse(source).expression))
    }

    @Test("AQL implicit iterators bind 'self' and leave bare features as variables")
    func aqlImplicitIterator() throws {
        #expect(try tree("self.books->select(pages > 1)")
            == "collection(select, nav(var(self), books, nullSafe: true), iterator: self, body: binary(>, var(pages), lit(int(1))))")
    }

    @Test("AQL allInstances is a call on a type literal")
    func aqlAllInstances() throws {
        #expect(try tree("library::Book.allInstances()")
            == "call(type(library, Book), allInstances, arrow: false, args: [])")
    }

    @Test("AQL generic arrow operations keep lambdas as arguments")
    func aqlGenericArrow() throws {
        #expect(try tree("self.books->sortedBy(b | b.title)")
            == "call(nav(var(self), books, nullSafe: true), sortedBy, arrow: true, args: [lambda(b, nav(var(b), title, nullSafe: true))])")
    }

    @Test("MTL query and template calls are invocation expressions")
    func mtlInvocation() async throws {
        let module = try await MTLParser().parse("""
            [module m('http://example.org/library/1.0')/]
            [template public main(b : library::Book)][b.render()/][/template]
            [template public render(b : library::Book)][b.title/][/template]
            """)
        let statement = try #require(module.templates["main"]?.body.statements.first as? MTLExpressionStatement)
        #expect(statement.expression.aqlExpression is MTLInvocationExpression)
    }

    @Test("ATL collection operations are method calls with lambda arguments")
    func atlLambdas() async throws {
        let module = try await ATLParser(options: .standard).parseContent("""
            module M;
            create OUT : B from IN : A;
            helper context A!X def: n : Integer = self.ys->select(y | y.ok)->size();
            """, filename: "m.atl")
        let helper = try #require(module.helpers["n"] as? ATLHelperWrapper)
        let size = try #require(helper.bodyExpression as? ATLMethodCallExpression)
        let select = try #require(size.receiver as? ATLMethodCallExpression)
        #expect(select.methodName == "select")
        #expect(select.arguments.first is ATLLambdaExpression)
        #expect(module.declaredMetamodelNames == ["IN": "A", "OUT": "B"])
    }
}
