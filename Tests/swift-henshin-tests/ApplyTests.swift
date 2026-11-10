//
// ApplyTests.swift
// swift-henshin-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import Foundation
import Henshin
import Testing

@testable import swift_henshin

/// Runs `swift-henshin apply` as a reader would.
@Suite("swift-henshin apply")
struct ApplyTests {
    /// The modules in both formats, which the tests run alike.
    static let modules = [Fixture.module, Fixture.textModule]

    @Test("A rule with typed parameters is applied and the model printed", arguments: modules)
    func printsModel(module: String) async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(
            ["apply", module, Fixture.model, "-u", "addParcel", "--param", "binName=B", "--param", "code=P3",
             "--param", "weight=4"], in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output.hasPrefix("<?xml"))
        #expect(run.output.contains("<parcels code=\"P3\" weight=\"4\"/>"))
        #expect(run.output.contains("<holds href=\"#//@parcels.2\"/>"))
        #expect(run.error == "binName = \"B\"\ncode = \"P3\"\nweight = 4\n")
        #expect(try Fixture.read(Fixture.model, in: directory) == (try String(contentsOf: Fixture.depot(Fixture.model), encoding: .utf8)))
    }

    @Test("--output writes the model in the format of its extension", arguments: ["out.xmi", "out.json"])
    func output(file: String) async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(
            ["apply", Fixture.module, Fixture.model, "--unit", "clearBin", "--param", "target=A", "-o", file],
            in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == "target = Bin(A)\n")
        let written = try Fixture.read(file, in: directory)
        if file.hasSuffix("json") {
            #expect(written.contains("\"tokens\" : 0"))
            #expect(!written.contains("\"tokens\" : 2"))
        } else {
            #expect(written.contains("<bins name=\"A\" tokens=\"0\">"))
        }
    }

    @Test("Objects are named by label or by fragment path", arguments: [("A", "Bin(A)"), ("//@bins.1", "Bin(B)")])
    func objectParameters(reference: String, expected: String) async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(
            ["apply", Fixture.textModule, Fixture.model, "-u", "clearBin", "--param", "target=\(reference)", "--dry-run"],
            in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == "target = \(expected)\n")
    }

    @Test("--trace lists the applications and --dry-run writes nothing")
    func traceAndDryRun() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(
            ["apply", Fixture.module, Fixture.model, "-u", "move", "--trace", "--dry-run"], in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == "")
        #expect(run.error == "applied move(source=Bin(A), target=Bin(B), m=0, n=2): created 0, deleted 0\n")
        let units = try await runSwiftHenshin(
            ["apply", Fixture.module, Fixture.model, "-u", "restock", "--param", "binName=A", "--param", "code=P4",
             "--param", "weight=1", "--trace", "--dry-run"], in: directory)
        #expect(units.succeeded, "\(units.error)")
        #expect(units.error.contains("applied addParcel("))
        #expect(units.error.contains("applied move(source=Bin(A), target=Bin(B), m=0, n=2)"))
    }

    @Test("A unit that does not apply exits with status 2 and writes nothing")
    func notApplied() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(
            ["apply", Fixture.module, Fixture.model, "-u", "removeParcel", "--param", "code=P1", "-o", "out.xmi"],
            in: directory)
        #expect(run.status == 2)
        #expect(run.output == "")
        #expect(run.error == "error: the unit 'removeParcel' could not be applied to depot.xmi; nothing was written\n")
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("out.xmi").path))
    }

    @Test("The dangling condition can be turned off or forced", arguments: ["--no-dangling-check", "--no-dangling"])
    func dangling(flag: String) async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(
            ["apply", Fixture.module, Fixture.model, "-u", "removeParcel", "--param", "code=P1", flag, "--trace",
             "-o", "out.xmi"], in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.error.contains("applied removeParcel(store=Depot(Central), parcel=Parcel (deleted), code=\"P1\"): created 0, deleted 1"))
        let written = try Fixture.read("out.xmi", in: directory)
        #expect(!written.contains("P1"))
        #expect(!written.contains("<holds"))
        let forced = try await runSwiftHenshin(
            ["apply", Fixture.module, Fixture.model, "-u", "removeParcel", "--param", "code=P1", "--check-dangling",
             "--dry-run"], in: directory)
        #expect(forced.status == 2)
        let free = try await runSwiftHenshin(
            ["apply", Fixture.module, Fixture.model, "-u", "removeParcel", "--param", "code=P2", "--check-dangling",
             "--dry-run"], in: directory)
        #expect(free.succeeded, "\(free.error)")
    }

    @Test("Injective matching can be turned off or forced")
    func injectivity() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let ring = try Fixture.read(Fixture.model, in: directory)
            .replacingOccurrences(of: "next=\"//@bins.1\"", with: "next=\"//@bins.0\"")
        try Fixture.write(ring, named: "loop.xmi", in: directory)
        let injective = try await runSwiftHenshin(
            ["apply", Fixture.module, "loop.xmi", "-u", "move", "--dry-run", "--injective"], in: directory)
        #expect(injective.status == 2)
        let loose = try await runSwiftHenshin(
            ["apply", Fixture.module, "loop.xmi", "-u", "move", "--dry-run", "--trace", "--non-injective"], in: directory)
        #expect(loose.succeeded, "\(loose.error)")
        #expect(loose.error == "applied move(source=Bin(A), target=Bin(A), m=2, n=2): created 0, deleted 0\n")
        let both = try await runSwiftHenshin(
            ["apply", Fixture.module, "loop.xmi", "-u", "move", "--injective", "--non-injective"], in: directory)
        #expect(both.status == ExitCode.validationFailure.rawValue)
    }

    @Test("--iteration-limit stops a loop unit with a warning")
    func iterationLimit() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(
            ["apply", Fixture.module, Fixture.model, "-u", "spin", "--iteration-limit", "3", "--trace", "--dry-run"],
            in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.error.hasPrefix("warning: depot.henshin: Loop unit 'spin' stopped after 3 iteration(s)\n"))
        #expect(run.error.components(separatedBy: "applied touch(store=Depot(Central))").count == 4)
        let invalid = try await runSwiftHenshin(
            ["apply", Fixture.module, Fixture.model, "-u", "spin", "--iteration-limit", "0"], in: directory)
        #expect(invalid.status == ExitCode.validationFailure.rawValue)
        #expect(invalid.error.contains("--iteration-limit must be at least 1"))
    }

    @Test("Seeded non-deterministic matching is reproducible")
    func seed() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let arguments = ["apply", Fixture.module, Fixture.model, "-u", "drain", "--trace", "--dry-run"]
        let first = try await runSwiftHenshin(arguments + ["--seed", "7"], in: directory)
        let second = try await runSwiftHenshin(arguments + ["--seed", "7"], in: directory)
        #expect(first.succeeded, "\(first.error)")
        #expect(first.error == second.error)
        #expect(first.error.hasPrefix("applied drain(bin=Bin(A), n=2)"))
        let random = try await runSwiftHenshin(arguments + ["--nondeterministic"], in: directory)
        #expect(random.succeeded, "\(random.error)")
        #expect(random.error.hasPrefix("applied drain(bin=Bin(A), n=2)"))
    }

    @Test("An explicit metamodel is used", arguments: modules)
    func explicitMetamodel(module: String) async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(
            ["apply", module, Fixture.model, "-m", Fixture.metamodel, "-u", "clearBin", "--param", "target=B",
             "--dry-run", "--verbose"], in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == "target = Bin(B)\n")
        #expect(run.error.contains("note: registering the metamodel Depot.ecore\n"))
        #expect(run.error.contains("note: reading the module \(module)\n"))
        #expect(run.error.contains("note: applying clearBin\n"))
    }

    @Test(
        "Errors are reported with status 1",
        arguments: [
            (["-u", "nothing"], "The module has no unit or rule named 'nothing' (available: addParcel"),
            (["-u", "addParcel", "--param", "binName=A"], "addParcel: parameter 'code' must be given a value"),
            (["-u", "addParcel", "--param", "weight=heavy"],
             "Invalid value 'heavy' for the parameter 'weight': expected a value of type EInt"),
            (["-u", "addParcel", "--param", "colour=red"], "Unknown parameter 'colour': expected one of binName, code, weight"),
            (["-u", "addParcel", "--param", "binName"], "Invalid parameter 'binName': expected name=value"),
            (["-u", "clearBin", "--param", "target=Z"], "No object of the model matches 'Z' for the parameter 'target'"),
        ])
    func errors(arguments: [String], message: String) async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(["apply", Fixture.module, Fixture.model] + arguments, in: directory)
        #expect(run.status == 1)
        #expect(run.error.contains(message), "\(run.error)")
        #expect(run.output == "")
    }

    @Test("Missing files are reported")
    func missingFiles() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let module = try await runSwiftHenshin(["apply", "missing.henshin", Fixture.model, "-u", "move"], in: directory)
        #expect(module.status == 1)
        #expect(module.error.contains("File not found: missing.henshin"))
        let model = try await runSwiftHenshin(["apply", Fixture.module, "missing.xmi", "-u", "move"], in: directory)
        #expect(model.status == 1)
        #expect(model.error.contains("File not found: missing.xmi"))
        let format = try await runSwiftHenshin(["apply", Fixture.model, Fixture.model, "-u", "move"], in: directory)
        #expect(format.status == 1)
        #expect(format.error.contains("Cannot tell the format of depot.xmi"))
    }

    @Test("--dry-run cannot be combined with --output, and --unit is required")
    func usage() async throws {
        let dry = try await runSwiftHenshin(
            ["apply", Fixture.module, Fixture.model, "-u", "move", "--dry-run", "-o", "out.xmi"])
        #expect(dry.status == ExitCode.validationFailure.rawValue)
        #expect(dry.error.contains("--dry-run cannot be combined with --output"))
        let unit = try await runSwiftHenshin(["apply", Fixture.module, Fixture.model])
        #expect(unit.status == ExitCode.validationFailure.rawValue)
    }

    @Test("A Henshin Text module in ISO-8859-1 is read with a warning, or quietly with --encoding")
    func encoding() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        var text = try Fixture.read(Fixture.textModule, in: directory)
        text = "// D\u{E9}p\u{F4}t rules\n" + text
        try text.data(using: .isoLatin1)!.write(to: directory.appendingPathComponent("latin.henshin_text"))
        let arguments = ["apply", "latin.henshin_text", Fixture.model, "-u", "move", "--dry-run"]
        let detected = try await runSwiftHenshin(arguments, in: directory)
        #expect(detected.succeeded, "\(detected.error)")
        #expect(detected.error.contains("warning: latin.henshin_text: line 1, column 5: "))
        let explicit = try await runSwiftHenshin(arguments + ["--encoding", "latin1"], in: directory)
        #expect(explicit.succeeded, "\(explicit.error)")
        #expect(explicit.error == "")
    }

    @Test("A trace line names the matched objects and parameter values")
    @MainActor
    func traceLine() async throws {
        let loaded = try await ModuleLoader(metamodels: [], encoding: nil, log: RecordingLog().log())
            .load(try Fixture.depot(Fixture.module).path)
        let model = try await ModelFile.load(
            try Fixture.depot(Fixture.model).path, into: loaded.resourceSet, log: RecordingLog().log())
        let result = try await HenshinEngine().apply(unitNamed: "move", of: loaded.module, to: model.resource)
        let formatter = await ValueFormatter.current(model.resource)
        let line = ApplyCommand.traceLine(try #require(result.appliedRules.first), module: loaded.module, formatter: formatter)
        #expect(line == "applied move(source=Bin(A), target=Bin(B), m=0, n=2): created 0, deleted 0")
        #expect(ApplyCommand.parameterLines(["b": 1, "a": "x"], formatter: formatter) == ["a = \"x\"", "b = 1"])
    }

    @Test("Engine options follow the command line")
    func engineOptions() throws {
        let defaults = try ApplyCommand.parse(["m.henshin", "x.xmi", "-u", "move"]).engineOptions
        #expect(defaults == EngineOptions())
        let seeded = try ApplyCommand.parse(
            ["m.henshin", "x.xmi", "-u", "move", "--seed", "3", "--no-dangling", "--non-injective", "--iteration-limit", "5"]
        ).engineOptions
        #expect(seeded == EngineOptions(
            deterministic: false, randomSeed: 3, injectiveMatching: false, checkDangling: false, iterationLimit: 5))
        let forced = try ApplyCommand.parse(
            ["m.henshin", "x.xmi", "-u", "move", "--nondeterministic", "--check-dangling", "--injective"]).engineOptions
        #expect(forced == EngineOptions(deterministic: false, injectiveMatching: true, checkDangling: true))
    }
}
