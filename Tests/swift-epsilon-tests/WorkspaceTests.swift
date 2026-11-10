//
// WorkspaceTests.swift
// swift-epsilon-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EOL
import Foundation
import Testing

@testable import swift_epsilon

/// Tests how the models of a run are loaded, typed and stored.
@Suite("Model workspace")
struct WorkspaceTests {
    @Test("A source model is typed by the metamodels that its file uses")
    func sourceTyping() async throws {
        let workspace = try await bankWorkspace()
        #expect(workspace.models.count == 1)
        let bank = try #require(workspace.model(named: "Bank"))
        #expect(bank.packages.map(\.name) == ["bank"])
        #expect(await bank.resource.count() == 4)
    }

    @Test("A target model is typed by the metamodels that no source uses")
    func targetTyping() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let workspace = try await bankWorkspace(targets: ["Ledger,L=" + directory.appendingPathComponent("l.xmi").path])
        #expect(workspace.models.map(\.name) == ["Bank", "Ledger"])
        let ledger = try #require(workspace.model(named: "L"))
        #expect(ledger.packages.map(\.name) == ["ledger"])
        #expect(ledger.aliases == ["L"])
        #expect(await ledger.resource.count() == 0)
    }

    @Test("A target model is typed by every metamodel when every one is used")
    func targetOfSameMetamodel() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let workspace = try await bankWorkspace(
            targets: ["Copy=" + directory.appendingPathComponent("c.xmi").path], metamodels: [Fixture.bankMetamodel])
        #expect(workspace.model(named: "Copy")?.packages.map(\.name) == ["bank"])
    }

    @Test("A target model needs a metamodel")
    func targetWithoutMetamodel() async throws {
        await #expect(throws: SwiftEpsilonError.targetWithoutMetamodel("Ledger")) {
            _ = try await bankWorkspace(targets: ["Ledger=l.xmi"], metamodels: [])
        }
    }

    @Test("A missing model file is reported by its path")
    func missingModel() async throws {
        await #expect(throws: SwiftEpsilonError.modelNotFound("missing.xmi")) {
            _ = try await bankWorkspace(models: ["Bank=missing.xmi"])
        }
    }

    @Test("A metamodel file given as a model is typed by the Ecore metamodel")
    func metamodelAsModel() async throws {
        let workspace = try await bankWorkspace(models: ["MM=" + Fixture.bank(Fixture.bankMetamodel).path], metamodels: [])
        let output = EOLStringOutput()
        let module = try EOLSyntax.parse("EClass.all.collect(c | c.name).println();").get()
        try await workspace.makeInterpreter(output: output).run(module)
        #expect(output.text == "Sequence {Bank, Account}\n")
    }

    @Test("An interpreter sees the parameters and the call depth limit of the run")
    func interpreter() async throws {
        var configuration = RunConfiguration(plan: try ModelPlan(sources: []))
        configuration.parameters = ["reader": .string("Alice"), "limit": .integer(3)]
        configuration.maximumCallDepth = 7
        let workspace = try await ModelWorkspace.load(configuration)
        let interpreter = workspace.makeInterpreter()
        #expect(interpreter.maximumCallDepth == 7)
        #expect(interpreter.variable("reader") == .string("Alice"))
        #expect(interpreter.variable("limit") == .integer(3))
        #expect(workspace.variables == ["reader": .string("Alice"), "limit": .integer(3)])
    }

    @Test("Targets and stored models are written in the format of their extension")
    func store() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let ledger = directory.appendingPathComponent("out/ledger.json").path
        let copy = directory.appendingPathComponent("copy.xmi").path
        let workspace = try await bankWorkspace(
            targets: ["Ledger=" + ledger], stores: ["Bank=" + copy], in: directory)
        let module = try EOLSyntax.parse("var l = new Ledger!Ledger; l.title = 'Summary'; Account.all.first().balance = 7;").get()
        try await workspace.makeInterpreter().run(module)
        let written = try await workspace.store()
        #expect(written == [ledger, copy])
        let json = try String(contentsOfFile: ledger, encoding: .utf8)
        #expect(json.contains("\"title\" : \"Summary\""))
        let xmi = try String(contentsOfFile: copy, encoding: .utf8)
        #expect(xmi.contains("balance=\"7\""))
        let original = try String(contentsOf: directory.appendingPathComponent(Fixture.bankModel), encoding: .utf8)
        #expect(original.contains("balance=\"120\""))
    }

    @Test("A stored model is written back to its own file unless another is given")
    func storeInPlace() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = directory.appendingPathComponent(Fixture.bankModel).path
        let workspace = try await bankWorkspace(models: ["Bank,B=" + model], stores: ["B"], in: directory)
        try await workspace.makeInterpreter().run(EOLSyntax.parse("Bank.all.first().name = 'Hill Bank';").get())
        #expect(try await workspace.store() == [model])
        #expect(try String(contentsOfFile: model, encoding: .utf8).contains("name=\"Hill Bank\""))
    }
}

/// Tests how source files are read and parsed.
@Suite("Source files")
struct SourceReaderTests {
    @Test("A source file is parsed with its path as the document")
    func parse() throws {
        let path = try Fixture.bank("report.eol").path
        let module = try SourceReader().module(at: path) { EOLSyntax.parse($0, document: $1) }
        #expect(module.document == path)
        #expect(!module.statements.isEmpty)
    }

    @Test("A missing source file is reported by its path")
    func missing() {
        #expect(throws: SwiftEpsilonError.sourceNotFound("missing.eol")) {
            _ = try SourceReader().module(at: "missing.eol") { EOLSyntax.parse($0, document: $1) }
        }
    }

    @Test("The syntax errors of a source file are reported and stop the run")
    func syntaxErrors() throws {
        let path = try Fixture.bank("invalid.eol").path
        var reported: [String] = []
        #expect(throws: SwiftEpsilonError.invalidSource(path, 1)) {
            _ = try SourceReader().module(at: path, parse: { EOLSyntax.parse($0, document: $1) }) { diagnostics, file in
                reported = diagnostics.map { file + ": " + $0.message }
            }
        }
        #expect(reported == [path + ": Expected an expression but found ';'"])
    }

    @Test("A file that is not valid in the encoding given is an error")
    func malformed() throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("latin1.eol")
        try Data("'Gr\u{F6}\u{DF}e'.println();".unicodeScalars.map { UInt8($0.value) }).write(to: file)
        #expect(throws: (any Error).self) { _ = try SourceReader(encoding: .utf8).text(at: file.path) }
        #expect(try SourceReader(encoding: .isoLatin1).text(at: file.path) == "'Größe'.println();")
    }

    @Test("The files that a source file refers to are found beside it", arguments: [
        ("lib.eol", "dir/main.eol", "dir/lib.eol"),
        ("lib.eol", "main.eol", "lib.eol"),
        ("lib.eol", nil, "lib.eol"),
        ("../lib.eol", "dir/main.eol", "dir/../lib.eol"),
        ("/abs/lib.eol", "dir/main.eol", "/abs/lib.eol"),
        ("sub/t.egl", "file:///work/rules.egx", "/work/sub/t.egl"),
        ("file:///work/t.egl", "dir/main.eol", "/work/t.egl"),
    ] as [(String, String?, String)])
    func resolve(path: String, document: String?, expected: String) {
        #expect(SourceModuleLoader.resolve(path, relativeTo: document) == expected)
    }

    @Test("Imported modules are read in the encoding of the run")
    func imports() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("operation greet() : String { return 'Gr\u{FC}\u{DF}e'; }".unicodeScalars.map { UInt8($0.value) })
            .write(to: directory.appendingPathComponent("lib.eol"))
        try "import 'lib.eol';\ngreet().println();\n".write(
            to: directory.appendingPathComponent("main.eol"), atomically: true, encoding: .utf8)
        var configuration = RunConfiguration(plan: try ModelPlan(sources: []))
        configuration.encoding = .isoLatin1
        let workspace = try await ModelWorkspace.load(configuration)
        let output = EOLStringOutput()
        try await EOLRun.run(program: directory.appendingPathComponent("main.eol").path, workspace: workspace, output: output)
        #expect(output.text == "Grüße\n")
        let loaded = try SourceModuleLoader(encoding: .isoLatin1).load("lib.eol", relativeTo: directory.appendingPathComponent("main.eol").path)
        #expect(loaded.document == directory.appendingPathComponent("lib.eol").path)
    }
}
