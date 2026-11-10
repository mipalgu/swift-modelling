//
// OutputEncodingTests.swift
// swift-xtend-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Foundation
import Testing

@testable import swift_xtend

/// Runs swift-xtend with `--output-encoding` and the configuration key of the same name.
@Suite("swift-xtend output encoding")
struct OutputEncodingTests {
    /// The arguments that bind the library model and its metamodel.
    private static let library = ["--model", "library.xmi", "--metamodel", "Library.ecore"]

    /// An Xtend generator that writes one file with a given content.
    private static func generator(file: String, contents: String) -> String {
        """
        import org.eclipse.emf.ecore.resource.Resource
        import org.eclipse.xtext.generator.IFileSystemAccess

        class Enc {
            def doGenerate(Resource resource, IFileSystemAccess fsa) {
                fsa.generateFile('\(file)', '\(contents)')
            }
        }
        """
    }

    /// Writes an Xtend generator into the directory.
    private static func writeGenerator(in directory: URL, file: String, contents: String) throws {
        try generator(file: file, contents: contents).write(
            to: directory.appendingPathComponent("Enc.xtend"), atomically: true, encoding: .utf8)
    }

    @Test("Generated files are UTF-8 by default, and exactly so with UTF-8 named")
    func defaultBytes() async throws {
        try await withFixtures { directory in
            try Self.writeGenerator(in: directory, file: "a.txt", contents: "Caf\u{E9} \u{20AC}")
            let plain = try await runSwiftXtend(["generate", "Enc.xtend", "-o", "plain"] + Self.library, in: directory)
            #expect(plain.succeeded, "\(plain.error)")
            let explicit = try await runSwiftXtend(
                ["generate", "Enc.xtend", "-o", "explicit", "--output-encoding", "UTF-8"] + Self.library, in: directory)
            #expect(explicit.succeeded, "\(explicit.error)")
            let expected = Data("Caf\u{E9} \u{20AC}".utf8)
            #expect(try Data(contentsOf: directory.appendingPathComponent("plain/a.txt")) == expected)
            #expect(try Data(contentsOf: directory.appendingPathComponent("explicit/a.txt")) == expected)
        }
    }

    @Test("Generated files are written in ISO-8859-1, and the listing stays on standard output")
    func latin1() async throws {
        try await withFixtures { directory in
            try Self.writeGenerator(in: directory, file: "a.txt", contents: "Caf\u{E9}")
            let run = try await runSwiftXtend(
                ["generate", "Enc.xtend", "-o", "out", "--output-encoding", "latin1"] + Self.library, in: directory)
            #expect(run.succeeded, "\(run.error)")
            #expect(try Data(contentsOf: directory.appendingPathComponent("out/a.txt")) == Data([0x43, 0x61, 0x66, 0xE9]))
            #expect(run.output.contains("out/a.txt"))
        }
    }

    @Test("A character the encoding cannot hold is an error that names the file, line and column")
    func unrepresentable() async throws {
        try await withFixtures { directory in
            try Self.writeGenerator(in: directory, file: "dir/a.txt", contents: "Price \u{20AC}")
            let run = try await runSwiftXtend(
                ["generate", "Enc.xtend", "-o", "out", "--output-encoding", "latin1"] + Self.library, in: directory)
            #expect(run.status == 1)
            #expect(run.error.contains("a.txt"), "\(run.error)")
            #expect(run.error.contains("U+20AC"), "\(run.error)")
            #expect(run.error.contains("line 1, column 7"), "\(run.error)")
            #expect(run.error.contains("ISO-8859-1"), "\(run.error)")
            #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("out/dir/a.txt").path))
        }
    }

    @Test("run writes an XML model with the declaration and character references, and JSON as UTF-8")
    func runModel() async throws {
        try await withFixtures { directory in
            let model = directory.appendingPathComponent("library.xmi")
            let original = try String(contentsOf: model, encoding: .utf8)
            try original.replacingOccurrences(of: "City Library", with: "Caf&#xE9; &#x20AC;")
                .write(to: model, atomically: true, encoding: .utf8)
            let arguments = ["run", "Report.xtend", "--method", "retire"] + Self.library
            let xml = try await runSwiftXtend(arguments + ["-o", "retired.xmi", "--output-encoding", "latin1"], in: directory)
            #expect(xml.succeeded, "\(xml.error)")
            let bytes = try Data(contentsOf: directory.appendingPathComponent("retired.xmi"))
            let text = try #require(String(data: bytes, encoding: .isoLatin1))
            #expect(text.hasPrefix("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>"), "\(text.prefix(80))")
            #expect(text.contains("&#x20AC;"))
            #expect(bytes.contains(0xE9))

            let utf8 = try await runSwiftXtend(arguments + ["-o", "plain.xmi"], in: directory)
            let explicit = try await runSwiftXtend(arguments + ["-o", "explicit.xmi", "--output-encoding", "utf8"], in: directory)
            #expect(utf8.succeeded && explicit.succeeded, "\(utf8.error)\(explicit.error)")
            let plain = try Data(contentsOf: directory.appendingPathComponent("plain.xmi"))
            #expect(plain == (try Data(contentsOf: directory.appendingPathComponent("explicit.xmi"))))
            #expect(String(data: plain, encoding: .utf8)?.contains("\u{20AC}") == true)

            let json = try await runSwiftXtend(arguments + ["-o", "retired.json", "--output-encoding", "latin1"], in: directory)
            #expect(json.succeeded, "\(json.error)")
            #expect(json.error.contains("retired.json: JSON is always written in UTF-8, not ISO-8859-1"), "\(json.error)")
            #expect(try String(contentsOf: directory.appendingPathComponent("retired.json"), encoding: .utf8).contains("\u{20AC}"))
        }
    }

    @Test("The configuration key names the encoding, and the option overrides it")
    func configuration() async throws {
        try await withFixtures { directory in
            try Self.writeGenerator(in: directory, file: "a.txt", contents: "Caf\u{E9}")
            try #"{ "output-encoding": "latin1" }"#.write(
                to: directory.appendingPathComponent("xtend.json"), atomically: true, encoding: .utf8)
            let configured = try await runSwiftXtend(
                ["generate", "Enc.xtend", "-o", "configured", "--config", "xtend.json"] + Self.library, in: directory)
            #expect(configured.succeeded, "\(configured.error)")
            #expect(try Data(contentsOf: directory.appendingPathComponent("configured/a.txt")) == Data([0x43, 0x61, 0x66, 0xE9]))
            let overridden = try await runSwiftXtend(
                ["generate", "Enc.xtend", "-o", "overridden", "--config", "xtend.json", "--output-encoding", "utf-8"]
                    + Self.library, in: directory)
            #expect(overridden.succeeded, "\(overridden.error)")
            #expect(try Data(contentsOf: directory.appendingPathComponent("overridden/a.txt")) == Data("Caf\u{E9}".utf8))
        }
    }

    @Test("An unknown encoding name is a usage error, and both commands describe the option")
    func invalidNameAndHelp() async throws {
        let run = try await runSwiftXtend(["generate", "Enc.xtend", "-o", "out", "--output-encoding", "EBCDIC"])
        #expect(run.status == ExitCode.validationFailure.rawValue)
        #expect(run.error.contains("--output-encoding"), "\(run.error)")
        for command in ["run", "generate"] {
            let help = try await runSwiftXtend([command, "--help"])
            #expect(help.output.contains("--output-encoding"), "\(command)")
        }
    }
}
