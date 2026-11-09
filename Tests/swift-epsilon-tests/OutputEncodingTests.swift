//
// OutputEncodingTests.swift
// swift-epsilon-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@testable import swift_epsilon

/// Runs swift-epsilon with `--output-encoding` and the configuration key of the same name.
@Suite("swift-epsilon output encoding")
struct OutputEncodingTests {
    /// The text that the template renders for a title, with the three accounts of the fixture.
    private static func rendered(title: String, bank: String = "River Bank") -> String {
        "\(title) of \(bank)\n- savings: 120\n- cheque: -30\n- holiday: 0\n"
    }

    /// The arguments that render the accounts template into a file.
    private static func template(title: String, output: String = "out/accounts.txt") -> [String] {
        ["egl", "generate", "accounts.egl", "--param", "title=\(title)", "-o", output] + bankArguments
    }

    /// Replaces text in the model of a copy of the fixture.
    private static func edit(_ directory: URL, replacing old: String, with new: String) throws {
        let url = directory.appendingPathComponent(Fixture.bankModel)
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains(old))
        try text.replacingOccurrences(of: old, with: new).write(to: url, atomically: true, encoding: .utf8)
    }

    @Test("A template is written as UTF-8 without the option, and exactly so with UTF-8 named")
    func defaultBytes() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let expected = Data(Self.rendered(title: "Caf\u{E9} \u{20AC}").utf8)
        let plain = try await runSwiftEpsilon(Self.template(title: "Caf\u{E9} \u{20AC}"), in: directory)
        #expect(plain.succeeded, "\(plain.error)")
        #expect(try Data(contentsOf: directory.appendingPathComponent("out/accounts.txt")) == expected)
        let explicit = try await runSwiftEpsilon(
            Self.template(title: "Caf\u{E9} \u{20AC}", output: "out/explicit.txt") + ["--output-encoding", "UTF-8"],
            in: directory)
        #expect(explicit.succeeded, "\(explicit.error)")
        #expect(try Data(contentsOf: directory.appendingPathComponent("out/explicit.txt")) == expected)
    }

    @Test("A template is written in ISO-8859-1, and standard output stays UTF-8")
    func templateLatin1() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let text = Self.rendered(title: "Caf\u{E9}")
        let run = try await runSwiftEpsilon(
            Self.template(title: "Caf\u{E9}") + ["--output-encoding", "latin1"], in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(try Data(contentsOf: directory.appendingPathComponent("out/accounts.txt")) == text.data(using: .isoLatin1))
        let stdout = try await runSwiftEpsilon(
            ["egl", "generate", "accounts.egl", "--param", "title=Caf\u{E9} \u{20AC}", "--output-encoding", "latin1"]
                + bankArguments, in: directory)
        #expect(stdout.succeeded, "\(stdout.error)")
        #expect(stdout.output == Self.rendered(title: "Caf\u{E9} \u{20AC}"))
    }

    @Test("A character that the encoding cannot hold is an error that names the file, line and column")
    func templateUnrepresentable() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftEpsilon(
            Self.template(title: "Price \u{20AC}") + ["--output-encoding", "latin1"], in: directory)
        #expect(run.status == 1)
        #expect(run.error.contains("out/accounts.txt"), "\(run.error)")
        #expect(run.error.contains("U+20AC"), "\(run.error)")
        #expect(run.error.contains("line 1, column 7"), "\(run.error)")
        #expect(run.error.contains("ISO-8859-1"), "\(run.error)")
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("out/accounts.txt").path))
    }

    @Test("EGX rules write their files in the encoding, and fail without leaving the file")
    func coordination() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Self.edit(directory, replacing: "owner=\"Alice\"", with: "owner=\"Zo&#xEB;\"")
        let arguments = ["egl", "generate", "accounts.egx", "--output", "generated"] + bankArguments
        let latin1 = try await runSwiftEpsilon(arguments + ["--output-encoding", "ISO-8859-1"], in: directory)
        #expect(latin1.succeeded, "\(latin1.error)")
        let expected = "Account savings\nOwner: Zo\u{EB}\nBalance: 120"
        let bytes = try Data(contentsOf: directory.appendingPathComponent("generated/accounts/savings.txt"))
        #expect(bytes.starts(with: try #require(expected.data(using: .isoLatin1))))
        #expect(bytes.contains(0xEB))
        let utf8 = try await runSwiftEpsilon(["egl", "generate", "accounts.egx", "--output", "utf8"] + bankArguments, in: directory)
        #expect(utf8.succeeded, "\(utf8.error)")
        let utf8Bytes = try Data(contentsOf: directory.appendingPathComponent("utf8/accounts/savings.txt"))
        #expect(utf8Bytes.starts(with: Data(expected.utf8)))

        try Self.edit(directory, replacing: "owner=\"Zo&#xEB;\"", with: "owner=\"&#x20AC;\"")
        let failing = try await runSwiftEpsilon(
            ["egl", "generate", "accounts.egx", "--output", "failed", "--output-encoding", "latin1"] + bankArguments,
            in: directory)
        #expect(failing.status == 1)
        #expect(failing.error.contains("accounts/savings.txt"), "\(failing.error)")
        #expect(failing.error.contains("line 2, column 8"), "\(failing.error)")
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("failed/accounts/savings.txt").path))
    }

    @Test("Stored XML models name the encoding and use character references, and JSON stays UTF-8 with a warning")
    func storedModels() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Self.edit(directory, replacing: "name=\"River Bank\"", with: "name=\"Caf&#xE9; &#x20AC;\"")
        let arguments = ["egl", "generate", "accounts.egl", "--param", "title=T", "--output-encoding", "latin1"] + bankArguments
        let xml = try await runSwiftEpsilon(arguments + ["--store", "Bank=stored.xmi"], in: directory)
        #expect(xml.succeeded, "\(xml.error)")
        #expect(xml.output == Self.rendered(title: "T", bank: "Caf\u{E9} \u{20AC}"))
        let bytes = try Data(contentsOf: directory.appendingPathComponent("stored.xmi"))
        let text = try #require(String(data: bytes, encoding: .isoLatin1))
        #expect(text.hasPrefix("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>"), "\(text.prefix(80))")
        #expect(text.contains("&#x20AC;"))
        #expect(bytes.contains(0xE9))
        #expect(!text.contains("\u{20AC}"))

        let json = try await runSwiftEpsilon(arguments + ["--store", "Bank=stored.json"], in: directory)
        #expect(json.succeeded, "\(json.error)")
        #expect(json.error.contains("stored.json: JSON is always written in UTF-8, not ISO-8859-1"), "\(json.error)")
        let jsonText = try String(contentsOf: directory.appendingPathComponent("stored.json"), encoding: .utf8)
        #expect(jsonText.contains("Caf\u{E9} \u{20AC}"))

        let quiet = try await runSwiftEpsilon(
            ["egl", "generate", "accounts.egl", "--param", "title=T", "--store", "Bank=plain.json"] + bankArguments,
            in: directory)
        #expect(quiet.succeeded, "\(quiet.error)")
        #expect(quiet.error.isEmpty, "\(quiet.error)")
    }

    @Test("The model of eol run and the target of etl transform are written in the encoding")
    func otherCommands() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Self.edit(directory, replacing: "name=\"River Bank\"", with: "name=\"Caf&#xE9; &#x20AC;\"")
        let eol = try await runSwiftEpsilon(
            ["eol", "run", "greeting.eol", "--param", "greeting=Hi", "--param", "reader=A", "--param", "factor=2",
             "--store", "Bank=eol.xmi", "--output-encoding", "latin1"] + bankArguments,
            in: directory)
        #expect(eol.succeeded, "\(eol.error)")
        let eolText = try #require(String(data: try Data(contentsOf: directory.appendingPathComponent("eol.xmi")), encoding: .isoLatin1))
        #expect(eolText.contains("encoding=\"ISO-8859-1\"") && eolText.contains("&#x20AC;"))

        let etl = try await runSwiftEpsilon(
            ["etl", "transform", "bank2ledger.etl", "--target", "Ledger=ledger.xmi", "--output-encoding", "latin1"]
                + bankArguments, in: directory)
        #expect(etl.succeeded, "\(etl.error)")
        let ledger = try #require(String(data: try Data(contentsOf: directory.appendingPathComponent("ledger.xmi")), encoding: .isoLatin1))
        #expect(ledger.contains("encoding=\"ISO-8859-1\""))
    }

    @Test("The configuration key names the encoding, and the option overrides it")
    func configuration() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        try #"{ "output-encoding": "latin1" }"#.write(
            to: directory.appendingPathComponent("epsilon.json"), atomically: true, encoding: .utf8)
        let text = Self.rendered(title: "Caf\u{E9}")
        let configured = try await runSwiftEpsilon(
            Self.template(title: "Caf\u{E9}", output: "configured.txt") + ["--config", "epsilon.json"], in: directory)
        #expect(configured.succeeded, "\(configured.error)")
        #expect(try Data(contentsOf: directory.appendingPathComponent("configured.txt")) == text.data(using: .isoLatin1))
        let overridden = try await runSwiftEpsilon(
            Self.template(title: "Caf\u{E9}", output: "overridden.txt") + ["--config", "epsilon.json", "--output-encoding", "utf-8"],
            in: directory)
        #expect(overridden.succeeded, "\(overridden.error)")
        #expect(try Data(contentsOf: directory.appendingPathComponent("overridden.txt")) == Data(text.utf8))
    }

    @Test("An unknown encoding name is a usage error")
    func invalidName() async throws {
        let run = try await runSwiftEpsilon(["eol", "run", "greeting.eol", "--output-encoding", "EBCDIC"])
        #expect(run.status == 64)
        #expect(run.error.contains("--output-encoding"), "\(run.error)")
    }

    @Test("Every command that writes describes the option")
    func help() async throws {
        for command in [["eol", "run"], ["evl", "validate"], ["etl", "transform"], ["egl", "generate"]] {
            let run = try await runSwiftEpsilon(command + ["--help"])
            #expect(run.output.contains("--output-encoding"), "\(command)")
        }
    }
}
