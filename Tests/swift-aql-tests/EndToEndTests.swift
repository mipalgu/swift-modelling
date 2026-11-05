//
// EndToEndTests.swift
// swift-aql-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Runs the built swift-aql executable as a reader would.
@Suite("swift-aql end to end", .serialized)
struct EndToEndTests {
    @Test("evaluate prints the value of an expression against a model")
    func evaluate() async throws {
        let model = try Fixture.shop(Fixture.shopModel).path
        let run = try await runSwiftAQL(["evaluate", "--model", model, "--expression", "shop.items.title"])
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == "[\"Green \\\"Sencha\\\" Tea\", \"Teapot\"]\n")
    }

    @Test("evaluate works without a model")
    func evaluateWithoutModel() async throws {
        let run = try await runSwiftAQL(["evaluate", "-e", "'Hello' + ' ' + 'World'"])
        #expect(run.succeeded)
        #expect(run.output == "\"Hello World\"\n")
    }

    @Test("evaluate reads an expression file relative to the working directory")
    func expressionFile() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Fixture.copyShop(to: directory)
        try FileManager.default.createDirectory(
            at: directory.appendingPathComponent("queries"), withIntermediateDirectories: true)
        try "-- the total stock\nshop.items.stock->sum()\n".write(
            to: directory.appendingPathComponent("queries/stock.aql"), atomically: true, encoding: .utf8)
        let run = try await runSwiftAQL(
            ["evaluate", "--model", Fixture.shopModel, "--expression-file", "queries/stock.aql"], in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == "15\n")
    }

    @Test("query takes the query as an argument or an option, with a context")
    func query() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Fixture.copyShop(to: directory)
        let positional = try await runSwiftAQL(["query", Fixture.shopModel, "self.items->size()"], in: directory)
        #expect(positional.output == "2\n")
        let option = try await runSwiftAQL(
            ["query", Fixture.shopModel, "--query", "self.price", "--context", "tea"], in: directory)
        #expect(option.output == "4.5\n")
        let byName = try await runSwiftAQL(
            ["query", Fixture.shopModel, "-q", "self", "--context", "Kiosk"], in: directory)
        #expect(byName.output == "Shop(Kiosk)\n")
    }

    @Test("An explicit metamodel is used")
    func explicitMetamodel() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let metamodels = directory.appendingPathComponent("metamodels")
        try FileManager.default.createDirectory(at: metamodels, withIntermediateDirectories: true)
        try FileManager.default.copyItem(
            at: try Fixture.shop(Fixture.shopMetamodel), to: metamodels.appendingPathComponent(Fixture.shopMetamodel))
        try FileManager.default.copyItem(
            at: try Fixture.shop(Fixture.shopModel), to: directory.appendingPathComponent(Fixture.shopModel))
        let run = try await runSwiftAQL(
            ["evaluate", "--model", Fixture.shopModel, "-m", "metamodels/Shop.ecore", "-e", "shop.founded + 1"],
            in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == "2002\n")
    }

    @Test("Errors are reported on standard error with a non-zero status", arguments: [
        (["evaluate", "--model", "missing.xmi", "-e", "self"], "Model file not found: missing.xmi"),
        (["evaluate", "-f", "missing.aql"], "Expression file not found or not readable: missing.aql"),
        (["evaluate", "-e", "1 +"], "Invalid AQL expression:"),
        (["evaluate", "-e", "nothing.here"], "Evaluation failed: Variable 'nothing' not found"),
        (["evaluate", "-e", "   "], "The expression is empty"),
        (["evaluate", "--model", "m.xmi"], "--expression"),
        (["query", "m.xmi"], "--query"),
    ])
    func errors(_ arguments: [String], _ message: String) async throws {
        let run = try await runSwiftAQL(arguments)
        #expect(!run.succeeded)
        #expect(run.output.isEmpty)
        #expect(run.error.contains(message), "\(run.error)")
    }

    @Test("An unknown context is reported")
    func unknownContext() async throws {
        let model = try Fixture.shop(Fixture.shopModel).path
        let run = try await runSwiftAQL(["query", model, "self", "--context", "nobody"])
        #expect(!run.succeeded)
        #expect(run.error.contains("No object has the identifier or name 'nobody'"))
    }

    @Test("The legacy semantics come from the environment")
    func environmentSemantics() async throws {
        let expression = "Sequence{'a'}->asSet()->including('b')->asOrderedSet()->first()"
        let run = try await runSwiftAQL(
            ["evaluate", "-e", expression, "--no-config"], environment: ["SWIFT_MODELLING_SEMANTICS": "legacy"])
        #expect(run.succeeded, "\(run.error)")
        let invalid = try await runSwiftAQL(
            ["evaluate", "-e", "1", "--no-config"], environment: ["SWIFT_MODELLING_SEMANTICS": "sometimes"])
        #expect(!invalid.succeeded)
    }

    @Test("The help lists the subcommands and the version is reported")
    func helpAndVersion() async throws {
        let help = try await runSwiftAQL(["--help"])
        #expect(help.output.contains("evaluate"))
        #expect(help.output.contains("query"))
        let version = try await runSwiftAQL(["--version"])
        #expect(version.output == "0.6.4\n")
        let evaluateHelp = try await runSwiftAQL(["help", "evaluate"])
        for option in ["--model", "--expression", "--expression-file", "--context", "--metamodel", "--semantics"] {
            #expect(evaluateHelp.output.contains(option), "\(option)")
        }
    }
}
