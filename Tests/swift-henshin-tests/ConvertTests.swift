//
// ConvertTests.swift
// swift-henshin-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@testable import swift_henshin

/// Runs `swift-henshin convert` as a reader would.
@Suite("swift-henshin convert")
struct ConvertTests {
    @Test("Both documents of the fixture convert to the same Henshin Text")
    func sameText() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fromXMI = try await runSwiftHenshin(["convert", Fixture.module], in: directory)
        let fromText = try await runSwiftHenshin(["convert", Fixture.textModule], in: directory)
        #expect(fromXMI.succeeded, "\(fromXMI.error)")
        #expect(fromText.succeeded, "\(fromText.error)")
        #expect(fromXMI.output == fromText.output)
        #expect(fromXMI.output.hasPrefix("ePackageImport depot\n\nrule addParcel(IN binName:EString, IN code:EString, IN weight:EInt) {\n"))
        #expect(fromXMI.output.contains("unit spin() {\n\twhile {\n\t\ttouch()\n\t}\n}"))
    }

    @Test("The output file is the second argument or --output, and is replaced only with --force")
    func outputFile() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = try await runSwiftHenshin(["convert", Fixture.module, "out.henshin_text"], in: directory)
        #expect(first.succeeded, "\(first.error)")
        #expect(first.output == "")
        let written = try Fixture.read("out.henshin_text", in: directory)
        #expect(written.hasPrefix("ePackageImport depot\n"))
        let again = try await runSwiftHenshin(["convert", Fixture.module, "-o", "out.henshin_text"], in: directory)
        #expect(again.status == 1)
        #expect(again.error.contains("The output file exists: out.henshin_text; give --force to replace it"))
        let forced = try await runSwiftHenshin(
            ["convert", "out.henshin_text", "-o", "out.henshin_text", "--force", "--verbose"], in: directory)
        #expect(forced.succeeded, "\(forced.error)")
        #expect(forced.error.contains("note: wrote out.henshin_text\n"))
        #expect(try Fixture.read("out.henshin_text", in: directory) == written)
        let model = try await runSwiftHenshin(
            ["apply", "out.henshin_text", Fixture.model, "-u", "clearBin", "--param", "target=A", "--dry-run"],
            in: directory)
        #expect(model.output == "target = Bin(A)\n")
    }

    @Test("Writing a .henshin document is not supported", arguments: ["out.henshin", "out.xmi"])
    func unsupported(output: String) async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(["convert", Fixture.textModule, output], in: directory)
        #expect(run.status == 1)
        #expect(run.error.contains(
            "Cannot convert depot.henshin_text to \(output): Henshin documents are read from .henshin and "
                + ".henshin_text files and written as .henshin_text only"))
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent(output).path))
    }

    @Test("The output cannot be given twice")
    func usage() async throws {
        let run = try await runSwiftHenshin(["convert", "a.henshin", "b.henshin_text", "-o", "c.henshin_text"])
        #expect(run.status == 64)
    }

    @Test("What Henshin Text cannot express is reported as a warning")
    func notFaithful() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let indexed = try Fixture.read(Fixture.module, in: directory).replacingOccurrences(
            of: "<edges xmi:id=\"mv_l_e1\" source=\"mv_l_s\" target=\"mv_l_t\">",
            with: "<edges xmi:id=\"mv_l_e1\" source=\"mv_l_s\" target=\"mv_l_t\" index=\"0\">")
        try Fixture.write(indexed, named: "indexed.henshin", in: directory)
        let run = try await runSwiftHenshin(["convert", "indexed.henshin"], in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.error.hasPrefix("warning: indexed.henshin: "))
    }
}
