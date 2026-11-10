//
// SupportTests.swift
// swift-henshin-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import Henshin
import Synchronization
import Testing

@testable import swift_henshin

/// Tests the support types of the tool on their own.
@Suite("swift-henshin support")
struct SupportTests {
    @Test("Module formats follow the file extension")
    func moduleFormats() {
        #expect(ModuleFormat(path: "a/b.henshin") == .xmi)
        #expect(ModuleFormat(path: "b.HENSHIN") == .xmi)
        #expect(ModuleFormat(path: "b.henshin_text") == .text)
        #expect(ModuleFormat(path: "b.xmi") == nil)
        #expect(ModuleFormat(path: "henshin") == nil)
    }

    @Test("Errors describe what to change")
    func errors() {
        #expect(SwiftHenshinError.fileNotFound("x").description == "File not found: x")
        #expect(SwiftHenshinError.unknownUnit("u", []).description == "The module has no unit or rule named 'u'")
        #expect(SwiftHenshinError.unknownRule("r", ["a", "b"]).description == "The module has no rule named 'r' (available: a, b)")
        #expect(SwiftHenshinError.invalidText("m.henshin_text", 2).description == "m.henshin_text is not valid Henshin Text (2 error(s))")
        #expect(SwiftHenshinError.noRules.errorDescription == "The module has no rules to work with")
        #expect(SwiftHenshinError.ambiguousObject(parameter: "p", value: "A", count: 2).description.hasPrefix(
            "2 objects of the model match 'A' for the parameter 'p'"))
        #expect(SwiftHenshinError.unknownModuleFormat("m.txt").description.hasPrefix("Cannot tell the format of m.txt"))
    }

    @Test("Values are formatted for the reader")
    func values() {
        let formatter = ValueFormatter { _ in nil }
        #expect(formatter.format(nil) == "null")
        #expect(formatter.format("a") == "\"a\"")
        #expect(formatter.format(3) == "3")
        #expect(formatter.format(true) == "true")
        #expect(formatter.format(EUUID()) == "(deleted)")
        #expect(formatter.bindings(["b": 2, "a": "x"]) == ["a=\"x\"", "b=2"])
    }

    @Test("Objects are described by class and label")
    @MainActor
    func objects() async throws {
        let loaded = try await ModuleLoader(metamodels: [], encoding: nil, log: RecordingLog().log())
            .load(try Fixture.depot(Fixture.module).path)
        let model = try await ModelFile.load(
            try Fixture.depot(Fixture.model).path, into: loaded.resourceSet, log: RecordingLog().log())
        let objects = await model.resource.getAllObjectsIncludingContents()
        #expect(objects.map(ValueFormatter.describe) == ["Depot(Central)", "Bin(A)", "Bin(B)", "Parcel(P1)", "Parcel(P2)"])
        let formatter = await ValueFormatter.current(model.resource)
        #expect(formatter.format(objects[1].id) == "Bin(A)")
        #expect(formatter.format(objects[1]) == "Bin(A)")
        let snapshot = ValueFormatter.snapshot(await model.resource.snapshot())
        #expect(snapshot.format(objects[2].id) == "Bin(B)")
        let parcel = try #require(objects[3].eClass as? EClass)
        #expect(ValueFormatter.labelAttribute(of: parcel)?.name == "code")
    }

    @Test("The module loader reads both formats into one resource set with their metamodels")
    @MainActor
    func loader() async throws {
        let recorder = RecordingLog()
        let loader = ModuleLoader(
            metamodels: [try Fixture.depot(Fixture.metamodel).path], encoding: nil, log: recorder.log(verbose: true))
        for name in [Fixture.module, Fixture.textModule] {
            let loaded = try await loader.load(try Fixture.depot(name).path)
            #expect(loaded.unitNames == ["addParcel", "removeParcel", "move", "drain", "emptyBin", "clearBin", "touch", "restock", "spin"])
            #expect(loaded.ruleNames.count == 7)
            #expect(loaded.packages.map(\.nsURI) == ["http://example.org/depot"])
            #expect(loaded.classNames == ["Depot", "Bin", "Parcel"])
            #expect(try loaded.unit(named: "restock").name == "restock")
            #expect(throws: SwiftHenshinError.unknownRule("restock", loaded.ruleNames)) { try loaded.rule(named: "restock") }
            #expect(throws: SwiftHenshinError.unknownUnit("x", loaded.unitNames)) { try loaded.unit(named: "x") }
        }
        #expect(recorder.text.contains("note: registering the metamodel "))
        #expect(recorder.text.contains("note: read 9 unit(s), 7 of them rules\n"))
    }

    @Test("Problems of a Henshin Text document are returned by read and thrown by load")
    @MainActor
    func invalidText() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = try Fixture.write("ePackageImport depot\nrule r( {\n", named: "bad.henshin_text", in: directory).path
        let recorder = RecordingLog()
        let loader = ModuleLoader(metamodels: [], encoding: nil, log: recorder.log())
        let read = try await loader.read(path)
        #expect(!read.errors.isEmpty)
        #expect(recorder.text == "")
        await #expect(throws: SwiftHenshinError.invalidText(path, read.errors.count)) { _ = try await loader.load(path) }
        #expect(recorder.text.hasPrefix("error: \(path): line 2, column "))
        await #expect(throws: SwiftHenshinError.fileNotFound("missing.henshin")) { _ = try await loader.read("missing.henshin") }
        await #expect(throws: SwiftHenshinError.unknownModuleFormat(path + ".txt")) {
            try Fixture.write("", named: "bad.henshin_text.txt", in: directory)
            _ = try await loader.read(path + ".txt")
        }
    }

    @Test("The log writes warnings, errors and verbose progress")
    func log() {
        let recorder = RecordingLog()
        let quiet = recorder.log()
        quiet.progress("hidden")
        quiet.warning("w")
        quiet.error("e")
        quiet.report([SourceDiagnostic(severity: .warning, code: "c", message: "m")], file: "f")
        #expect(recorder.text == "warning: w\nerror: e\nwarning: f: m\n")
        let loud = RecordingLog()
        loud.log(verbose: true).progress("shown")
        #expect(loud.text == "note: shown\n")
    }

    @Test("Matching options override the rules only when given")
    func matching() throws {
        #expect(try MatchingOptions.parse([]).engineOptions() == EngineOptions())
        let options = try MatchingOptions.parse(["--no-dangling", "--injective"])
        #expect(options.engineOptions() == EngineOptions(injectiveMatching: true, checkDangling: false))
        #expect(DanglingCondition.help(for: .checkDangling) != nil)
        #expect(Injectivity.help(for: .nonInjective) != nil)
    }

    @Test("The progress ticker writes lines in verbose mode and nothing otherwise")
    func ticker() async throws {
        let written = Mutex<[String]>([])
        let verbose = ProgressTicker(verbose: true, interactive: false) { text in written.withLock { $0.append(text) } }
        let value = try await verbose.run("working") { 42 }
        #expect(value == 42)
        let lines = written.withLock { $0 }
        #expect(lines.first == "note: working\n")
        #expect(lines.last?.hasPrefix("note: finished working (0 s)") == true)
        written.withLock { $0 = [] }
        let silent = ProgressTicker(verbose: false, interactive: false) { text in written.withLock { $0.append(text) } }
        #expect(try await silent.run("working") { "done" } == "done")
        #expect(written.withLock { $0 }.isEmpty)
        let interactive = ProgressTicker(verbose: false, interactive: true) { text in written.withLock { $0.append(text) } }
        _ = try await interactive.run("working") { 1 }
        #expect(written.withLock { $0 }.last == ProgressTicker.clearLine)
        #expect(ProgressTicker.text("phase", elapsed: .seconds(12)) == "phase (12 s)")
    }

    @Test("Model files are written in the format of their extension")
    @MainActor
    func modelFiles() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let loaded = try await ModuleLoader(metamodels: [], encoding: nil, log: RecordingLog().log())
            .load(directory.appendingPathComponent(Fixture.module).path)
        let model = try await ModelFile.load(
            directory.appendingPathComponent(Fixture.model).path, into: loaded.resourceSet, log: RecordingLog().log())
        #expect(model.format == .xmi)
        let json = directory.appendingPathComponent("copy.json").path
        try await ModelFile.save(model.resource, to: json)
        #expect(try String(contentsOfFile: json, encoding: .utf8).hasPrefix("{"))
        #expect(try await ModelFile.text(of: model).hasPrefix("<?xml"))
        await #expect(throws: SwiftHenshinError.fileNotFound("missing.xmi")) {
            _ = try await ModelFile.load("missing.xmi", into: loaded.resourceSet, log: RecordingLog().log())
        }
    }
}
