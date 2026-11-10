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
        #expect(version.output == "0.8.0\n")
        let evaluateHelp = try await runSwiftAQL(["help", "evaluate"])
        for option in ["--model", "--expression", "--expression-file", "--context", "--metamodel", "--semantics"] {
            #expect(evaluateHelp.output.contains(option), "\(option)")
        }
    }
}

/// Tests for `--strict-aql`, which makes expressions reject what Eclipse AQL rejects.
@Suite("swift-aql strict expressions")
struct StrictAQLTests {
    /// Expressions that Eclipse AQL rejects, with their values outside strict mode.
    static let rejected = [
        ("Sequence{'a'}->union(OrderedSet{'b'})", "[\"a\", \"b\"]\n"),
        ("Sequence{'a'}->concat('b')", "[\"a\", \"b\"]\n"),
    ]

    @Test("accepts a mixed-kind union and a single value passed to concat by default", arguments: rejected)
    func acceptsByDefault(expression: String, value: String) async throws {
        let run = try await runSwiftAQL(["evaluate", "-e", expression, "--no-config"])

        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == value)
    }

    @Test("rejects a mixed-kind union and a single value passed to concat with --strict-aql", arguments: rejected)
    func rejectsWhenStrict(expression: String, value: String) async throws {
        for command in [["evaluate", "-e", expression], ["query", try Fixture.shop(Fixture.shopModel).path, expression]] {
            let run = try await runSwiftAQL(command + ["--no-config", "--strict-aql"])

            #expect(!run.succeeded, "\(command): \(run.output)")
            #expect(run.error.contains("Type error"), "\(run.error)")
        }
    }

    @Test("describes --strict-aql in the help of both commands")
    func help() async throws {
        for command in ["evaluate", "query"] {
            let run = try await runSwiftAQL([command, "--help"])

            #expect(run.output.contains("--strict-aql"), "\(command)")
        }
    }
}

/// Tests for `--sequence-union`, `--null-addition` and `--text-form`.
@Suite("swift-aql union, null addition and text form")
struct ExpressionFormTests {
    /// Each option with a value, the expression whose value it changes, and the value it gives.
    static let cases: [(arguments: [String], expression: String, value: String)] = [
        ([], "Sequence{'a', 'b'}->union(Sequence{'b'})->size()", "3\n"),
        (["--sequence-union", "distinct"], "Sequence{'a', 'b'}->union(Sequence{'b'})->size()", "2\n"),
        (["--semantics", "legacy"], "Sequence{'a', 'b'}->union(Sequence{'b'})->size()", "2\n"),
        (["--semantics", "legacy", "--sequence-union", "concatenation"], "Sequence{'a', 'b'}->union(Sequence{'b'})->size()", "3\n"),
        ([], "null + 'x'", "\"x\"\n"),
        (["--null-addition", "null"], "null + 'x'", "null\n"),
        (["--semantics", "legacy", "--null-addition", "empty-text"], "null + 'x'", "\"x\"\n"),
        ([], "'=' + Sequence{'a', 'b'}", "\"=ab\"\n"),
        (["--text-form", "bracketed"], "'=' + Sequence{'a', 'b'}", "\"=[a, b]\"\n"),
        (["--semantics", "legacy", "--text-form", "joined"], "'=' + Sequence{'a', 'b'}", "\"=ab\"\n"),
    ]

    @Test("selects each value of each option over the preset", arguments: cases.indices)
    func option(index: Int) async throws {
        let (arguments, expression, value) = Self.cases[index]
        let run = try await runSwiftAQL(["evaluate", "--no-config", "-e", expression] + arguments)

        #expect(run.succeeded, "\(arguments): \(run.error)")
        #expect(run.output == value, "\(arguments)")
    }

    @Test("reads the options from the configuration file")
    func configuration() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(
            at: directory.appendingPathComponent(".git"), withIntermediateDirectories: true)
        try #"{ "sequence-union": "distinct", "null-addition": "null", "text-form": "bracketed" }"#.write(
            to: directory.appendingPathComponent(".swift-modelling.json"), atomically: true, encoding: .utf8)

        let run = try await runSwiftAQL(
            ["evaluate", "-e", "Sequence{Sequence{'a', 'b'}->union(Sequence{'b'})->size().toString(), ((null + 'x') = null).toString(), '=' + Sequence{'a'}}"],
            in: directory)

        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == "[\"2\", \"true\", \"=[a]\"]\n", "\(run.output)")
    }
}

/// Tests for `--dot-calls`, which chooses what a call written with a dot does on a collection,
/// and for the warnings about such calls.
@Suite("swift-aql dot calls")
struct DotCallTests {
    /// The expression whose value the option changes.
    static let expression = "Sequence{'a', 'b'}.size()"

    /// Each set of options, with the value of ``expression`` that they give.
    static let cases: [(arguments: [String], value: String)] = [
        ([], "[1, 1]\n"),
        (["--dot-calls", "each-element"], "[1, 1]\n"),
        (["--dot-calls", "collection"], "2\n"),
        (["--semantics", "legacy"], "2\n"),
        (["--semantics", "legacy", "--dot-calls", "each-element"], "[1, 1]\n"),
        (["--semantics", "standard", "--dot-calls", "collection"], "2\n"),
    ]

    @Test("applies a dot call on a collection to each element unless told otherwise", arguments: cases.indices)
    func option(index: Int) async throws {
        let (arguments, value) = Self.cases[index]
        let run = try await runSwiftAQL(["evaluate", "--no-config", "-e", Self.expression] + arguments)

        #expect(run.succeeded, "\(arguments): \(run.error)")
        #expect(run.output == value, "\(arguments)")
    }

    @Test("gives the size of the collection with an arrow call whatever the options", arguments: [
        [], ["--dot-calls", "collection"], ["--semantics", "legacy"],
    ])
    func arrow(arguments: [String]) async throws {
        let run = try await runSwiftAQL(["evaluate", "--no-config", "-e", "Sequence{'a', 'b'}->size()"] + arguments)

        #expect(run.succeeded, "\(arguments): \(run.error)")
        #expect(run.output == "2\n", "\(arguments)")
    }

    @Test("follows the environment and the dot-calls key of the configuration file")
    func configuration() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(
            at: directory.appendingPathComponent(".git"), withIntermediateDirectories: true)
        try #"{ "dot-calls": "collection" }"#.write(
            to: directory.appendingPathComponent(".swift-modelling.json"), atomically: true, encoding: .utf8)

        let fromFile = try await runSwiftAQL(["evaluate", "-e", Self.expression], in: directory)
        let overridden = try await runSwiftAQL(
            ["evaluate", "-e", Self.expression, "--dot-calls", "each-element"], in: directory)
        let fromEnvironment = try await runSwiftAQL(
            ["evaluate", "--no-config", "-e", Self.expression], environment: ["SWIFT_MODELLING_SEMANTICS": "legacy"])

        #expect(fromFile.output == "2\n", "\(fromFile.error)")
        #expect(overridden.output == "[1, 1]\n", "\(overridden.error)")
        #expect(fromEnvironment.output == "2\n", "\(fromEnvironment.error)")
    }

    @Test("warns on standard error when the elements lack the service of the collection, and succeeds")
    func warning() async throws {
        for command in [
            ["evaluate", "-e", "Sequence{1, 2}.size()"],
            ["query", try Fixture.shop(Fixture.shopModel).path, "Sequence{1, 2}.size()"],
        ] {
            let run = try await runSwiftAQL(command + ["--no-config"])

            #expect(run.succeeded, "\(command): \(run.error)")
            #expect(run.output == "[]\n", "\(command)")
            let lines = run.error.split(separator: "\n", omittingEmptySubsequences: true)
            #expect(lines.count == 1, "\(command): \(run.error)")
            #expect(run.error.hasPrefix("warning: line 1, column "), "\(command): \(run.error)")
            #expect(run.error.contains("->size()"), "\(command): \(run.error)")
        }
    }

    @Test("does not warn about an arrow call, a call on single values or dot calls on the collection", arguments: [
        (["-e", "Sequence{1, 2}->size()"], "2\n"),
        (["-e", "Sequence{'a', 'bc'}.size()"], "[1, 2]\n"),
        (["-e", "Sequence{1, 2}.size()", "--dot-calls", "collection"], "2\n"),
        (["-e", "Sequence{1, 2}.size()", "--semantics", "legacy"], "2\n"),
    ])
    func noWarning(arguments: [String], value: String) async throws {
        let run = try await runSwiftAQL(["evaluate", "--no-config"] + arguments)

        #expect(run.succeeded, "\(arguments): \(run.error)")
        #expect(run.output == value, "\(arguments)")
        #expect(run.error.isEmpty, "\(arguments): \(run.error)")
    }

    @Test("reports the warning before failing in strict mode")
    func strictWarning() async throws {
        let run = try await runSwiftAQL(["evaluate", "--no-config", "--strict-aql", "-e", "Sequence{1, 2}.size()"])

        #expect(!run.succeeded)
        #expect(run.error.contains("warning: "), "\(run.error)")
    }

    @Test("describes --dot-calls in the help of both commands")
    func help() async throws {
        for command in ["evaluate", "query"] {
            let run = try await runSwiftAQL([command, "--help"])

            #expect(run.output.contains("--dot-calls <each-element|collection>"), "\(command)")
        }
    }
}
