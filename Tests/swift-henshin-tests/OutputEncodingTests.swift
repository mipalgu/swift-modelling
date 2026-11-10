//
// OutputEncodingTests.swift
// swift-henshin-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Foundation
import Testing

@testable import swift_henshin

/// Runs swift-henshin with `--output-encoding`.
@Suite("swift-henshin output encoding")
struct OutputEncodingTests {
    /// Copies the depot fixture with the name that `addParcel` matches fixed to a text.
    ///
    /// - Parameter name: The text of the name, which Henshin Text keeps in a string literal.
    /// - Returns: The directory.
    /// - Throws: An error if the files cannot be written.
    private static func depot(matchingBinNamed name: String) throws -> URL {
        let directory = try Fixture.copyDepot()
        let url = directory.appendingPathComponent(Fixture.textModule)
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("name = binName"))
        try text.replacingOccurrences(of: "name = binName", with: "name = \"\(name)\"")
            .write(to: url, atomically: true, encoding: .utf8)
        return directory
    }

    /// Gives the depot of a directory a name that Latin-1 cannot hold.
    private static func renameDepot(in directory: URL) throws {
        let url = directory.appendingPathComponent(Fixture.model)
        let text = try String(contentsOf: url, encoding: .utf8)
        try text.replacingOccurrences(of: "name=\"Central\"", with: "name=\"Caf&#xE9; &#x20AC;\"")
            .write(to: url, atomically: true, encoding: .utf8)
    }

    @Test("convert writes UTF-8 by default and ISO-8859-1 on request")
    func convert() async throws {
        let directory = try Self.depot(matchingBinNamed: "Caf\u{E9}")
        defer { try? FileManager.default.removeItem(at: directory) }
        let plain = try await runSwiftHenshin(["convert", Fixture.textModule, "plain.henshin_text"], in: directory)
        #expect(plain.succeeded, "\(plain.error)")
        let explicit = try await runSwiftHenshin(
            ["convert", Fixture.textModule, "explicit.henshin_text", "--output-encoding", "UTF-8"], in: directory)
        #expect(explicit.succeeded, "\(explicit.error)")
        let utf8 = try Data(contentsOf: directory.appendingPathComponent("plain.henshin_text"))
        #expect(utf8 == (try Data(contentsOf: directory.appendingPathComponent("explicit.henshin_text"))))
        let text = try #require(String(data: utf8, encoding: .utf8))
        #expect(text.contains("name = 'Caf\u{E9}'"))

        let latin1 = try await runSwiftHenshin(
            ["convert", Fixture.textModule, "-o", "latin.henshin_text", "--output-encoding", "latin1"], in: directory)
        #expect(latin1.succeeded, "\(latin1.error)")
        #expect(try Data(contentsOf: directory.appendingPathComponent("latin.henshin_text")) == text.data(using: .isoLatin1))
        let onStandardOutput = try await runSwiftHenshin(
            ["convert", Fixture.textModule, "--output-encoding", "latin1"], in: directory)
        #expect(onStandardOutput.output == text)
    }

    @Test("convert reports a character that the encoding cannot hold and leaves no file")
    func convertUnrepresentable() async throws {
        let directory = try Self.depot(matchingBinNamed: "\u{3BC}")
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(
            ["convert", Fixture.textModule, "out.henshin_text", "--output-encoding", "latin1"], in: directory)
        #expect(run.status == 1)
        #expect(run.error.contains("out.henshin_text"), "\(run.error)")
        #expect(run.error.contains("U+03BC"), "\(run.error)")
        #expect(run.error.contains("line "), "\(run.error)")
        #expect(run.error.contains("column "), "\(run.error)")
        #expect(run.error.contains("ISO-8859-1"), "\(run.error)")
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("out.henshin_text").path))
    }

    @Test("apply writes an XML model with the declaration and character references, and JSON as UTF-8")
    func apply() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Self.renameDepot(in: directory)
        let arguments = ["apply", Fixture.module, Fixture.model, "-u", "clearBin", "--param", "target=A"]
        let plain = try await runSwiftHenshin(arguments + ["-o", "plain.xmi"], in: directory)
        let explicit = try await runSwiftHenshin(arguments + ["-o", "explicit.xmi", "--output-encoding", "utf8"], in: directory)
        #expect(plain.succeeded && explicit.succeeded, "\(plain.error)\(explicit.error)")
        let utf8 = try Data(contentsOf: directory.appendingPathComponent("plain.xmi"))
        #expect(utf8 == (try Data(contentsOf: directory.appendingPathComponent("explicit.xmi"))))
        #expect(String(data: utf8, encoding: .utf8)?.contains("\u{20AC}") == true)

        let latin1 = try await runSwiftHenshin(arguments + ["-o", "latin.xmi", "--output-encoding", "latin1"], in: directory)
        #expect(latin1.succeeded, "\(latin1.error)")
        let bytes = try Data(contentsOf: directory.appendingPathComponent("latin.xmi"))
        let text = try #require(String(data: bytes, encoding: .isoLatin1))
        #expect(text.hasPrefix("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>"), "\(text.prefix(80))")
        #expect(text.contains("&#x20AC;"))
        #expect(bytes.contains(0xE9))

        let json = try await runSwiftHenshin(arguments + ["-o", "out.json", "--output-encoding", "latin1"], in: directory)
        #expect(json.succeeded, "\(json.error)")
        #expect(json.error.contains("out.json: JSON is always written in UTF-8, not ISO-8859-1"), "\(json.error)")
        #expect(try Fixture.read("out.json", in: directory).contains("\u{20AC}"))

        let printed = try await runSwiftHenshin(arguments + ["--output-encoding", "latin1"], in: directory)
        #expect(printed.succeeded, "\(printed.error)")
        #expect(printed.output.contains("encoding=\"UTF-8\""))
        #expect(printed.output.contains("\u{20AC}"))
    }

    @Test("explore writes the Graphviz file in the encoding named")
    func explore() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let arguments = ["explore", Fixture.module, Fixture.model, "--rules", "move", "--deadlock"]
        let plain = try await runSwiftHenshin(arguments + ["--dot", "plain.dot"], in: directory)
        #expect(plain.succeeded, "\(plain.error)")
        let utf8 = try Data(contentsOf: directory.appendingPathComponent("plain.dot"))
        let latin1 = try await runSwiftHenshin(arguments + ["--dot", "latin.dot", "--output-encoding", "latin1"], in: directory)
        #expect(latin1.succeeded, "\(latin1.error)")
        #expect(try Data(contentsOf: directory.appendingPathComponent("latin.dot")) == utf8)
        let wide = try await runSwiftHenshin(arguments + ["--dot", "wide.dot", "--output-encoding", "utf-16"], in: directory)
        #expect(wide.succeeded, "\(wide.error)")
        let bytes = try Data(contentsOf: directory.appendingPathComponent("wide.dot"))
        #expect(bytes != utf8)
        #expect(String(data: bytes, encoding: .utf16) == String(data: utf8, encoding: .utf8))
    }

    @Test("An unknown encoding name is a usage error, and the commands that write describe the option")
    func invalidNameAndHelp() async throws {
        let run = try await runSwiftHenshin(["convert", Fixture.module, "--output-encoding", "EBCDIC"])
        #expect(run.status == ExitCode.validationFailure.rawValue)
        #expect(run.error.contains("--output-encoding"), "\(run.error)")
        for command in ["apply", "convert", "explore"] {
            let help = try await runSwiftHenshin([command, "--help"])
            #expect(help.output.contains("--output-encoding"), "\(command)")
        }
    }
}
