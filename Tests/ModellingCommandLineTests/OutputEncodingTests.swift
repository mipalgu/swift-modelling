//
// OutputEncodingTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import EMFBase
import Foundation
import ModellingCommandLine
import Testing

/// Tests for the output encoding option, its configuration key and the writing of files.
@Suite("Output file encodings")
struct OutputEncodingTests {
    /// Settings whose configuration file names an output encoding, or none.
    ///
    /// - Parameter encoding: The value of the `output-encoding` key, or `nil` to leave it out.
    /// - Returns: The settings.
    /// - Throws: The error of reading the configuration.
    static func settings(outputEncoding encoding: String?) throws -> SemanticsSettings {
        let text = encoding.map { #"{ "output-encoding": "\#($0)" }"# } ?? "{}"
        let configuration = try ModellingConfiguration(
            data: Data(text.utf8), url: URL(fileURLWithPath: "/projects/example/.swift-modelling.json"))
        return SemanticsSettings(configuration: configuration)
    }

    /// A metamodel with a character outside ISO-8859-1 in an attribute value.
    static let metamodel = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" \
        xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="caf\u{E9}" \
        nsURI="http://example.org/cafe" nsPrefix="cafe">
          <eAnnotations source="http://www.eclipse.org/emf/2002/GenModel">
            <details key="documentation" value="Costs 5 \u{20AC}"/>
          </eAnnotations>
        </ecore:EPackage>

        """

    // MARK: - Option

    @Test("names the option once, separately from the reading encoding, and lists every encoding")
    func optionNames() {
        #expect(OutputEncodingOptions.optionName == "output-encoding")
        #expect(OutputEncodingOptions.optionName != SourceEncodingOptions.optionName)
        #expect(OutputEncodingOptions.defaultEncoding == .utf8)
        #expect(OutputEncodingOptions.valueList == SourceEncodingOptions.valueList)
    }

    @Test("accepts the name and the aliases of each encoding", arguments: TextEncoding.allCases)
    func parsesNames(encoding: TextEncoding) throws {
        for name in [encoding.name, encoding.name.lowercased()] + encoding.aliases {
            let options = try OutputEncodingOptions.parse(["--output-encoding", name])
            #expect(options.explicitEncoding == encoding, "\(name)")
        }
    }

    @Test("rejects an unknown encoding, listing the supported ones")
    func rejectsUnknown() {
        do {
            _ = try OutputEncodingOptions.parse(["--output-encoding", "EBCDIC"])
            Issue.record("Expected an error")
        } catch {
            let message = OutputEncodingOptions.message(for: error)
            #expect(message.contains("EBCDIC"), "\(message)")
            #expect(message.contains("--output-encoding"), "\(message)")
            for encoding in TextEncoding.allCases {
                #expect(message.contains(encoding.name), "\(encoding.name) is missing from: \(message)")
            }
        }
    }

    @Test("writes UTF-8 when nothing chooses an encoding")
    func defaultEncoding() throws {
        let options = try OutputEncodingOptions.parse([])
        #expect(options.explicitEncoding == nil)
        #expect(options.encoding(settings: try Self.settings(outputEncoding: nil)) == .utf8)
        #expect(options.encoding(configuration: ModellingConfiguration()) == .utf8)
    }

    @Test("takes the encoding of the configuration file")
    func configuredEncoding() throws {
        let options = try OutputEncodingOptions.parse([])
        #expect(options.encoding(settings: try Self.settings(outputEncoding: "latin1")) == .isoLatin1)
        #expect(options.encoding(settings: try Self.settings(outputEncoding: "cp1252")) == .windows1252)
    }

    @Test("lets the command line override the configuration file")
    func commandLineOverridesConfiguration() throws {
        let options = try OutputEncodingOptions.parse(["--output-encoding", "UTF-8"])
        #expect(options.encoding(settings: try Self.settings(outputEncoding: "ISO-8859-1")) == .utf8)
        let latin = try OutputEncodingOptions.parse(["--output-encoding", "latin1"])
        #expect(latin.encoding(settings: try Self.settings(outputEncoding: "US-ASCII")) == .isoLatin1)
    }

    @Test("does not take the reading encoding of the configuration file")
    func independentOfReadingEncoding() throws {
        let configuration = try ModellingConfiguration(
            data: Data(#"{ "encoding": "ISO-8859-1" }"#.utf8), url: URL(fileURLWithPath: "/p/.swift-modelling.json"))
        #expect(try OutputEncodingOptions.parse([]).encoding(configuration: configuration) == .utf8)
        #expect(configuration.outputEncoding == nil)
    }

    @Test("describes the option for the discussion of a command")
    func discussion() {
        let text = OutputEncodingOptions.discussion(writer: "the converted model")
        #expect(text.contains("--\(OutputEncodingOptions.optionName)"))
        #expect(text.contains("the converted model"))
        #expect(text.contains(TextEncoding.utf8.name))
        #expect(text.contains("JSON"))
        #expect(text.contains("configuration file"))
        #expect(!text.contains("\u{2014}"))
        #expect(!OutputEncodingOptions.discussion(writer: "x", configurable: false).contains("configuration file"))
    }

    // MARK: - Configuration key

    @Test("reads the output-encoding key of the configuration file by name or alias")
    func configurationKey() throws {
        #expect(ModellingConfiguration.keys.contains(OutputEncodingOptions.optionName))
        #expect(try Self.settings(outputEncoding: "UTF-16LE").configuration.outputEncoding == .utf16LittleEndian)
        #expect(try Self.settings(outputEncoding: "windows-1252").configuration.outputEncoding == .windows1252)
        #expect(try Self.settings(outputEncoding: nil).configuration.outputEncoding == nil)
    }

    @Test("rejects an unknown encoding in the configuration file, listing the supported ones")
    func invalidConfigurationKey() {
        let file = URL(fileURLWithPath: "/projects/example/.swift-modelling.json")
        let error = configurationError { () throws(ModellingConfigurationError) in
            try ModellingConfiguration(data: Data(#"{ "output-encoding": "EBCDIC" }"#.utf8), url: file)
        }
        #expect(
            error == .invalidValue(
                "EBCDIC", key: OutputEncodingOptions.optionName, accepted: TextEncoding.allCases.map(\.name),
                path: file.path))
        let wrongType = configurationError { () throws(ModellingConfigurationError) in
            try ModellingConfiguration(data: Data(#"{ "output-encoding": true }"#.utf8), url: file)
        }
        #expect(wrongType == .wrongType(key: OutputEncodingOptions.optionName, expected: .string, path: file.path))
    }

    // MARK: - Writing text

    @Test("writes UTF-8 exactly as before", arguments: TextDocumentKind.allCases)
    func utf8Unchanged(kind: TextDocumentKind) throws {
        let directory = try ScratchDirectory()
        let text = "caf\u{E9} \u{2603}\r\nline two\n"
        let before = directory.url.appendingPathComponent("before.txt")
        let after = directory.url.appendingPathComponent("after.txt")
        try text.write(to: before, atomically: true, encoding: .utf8)
        var warnings: [String] = []
        try OutputFile.write(text, to: after.path, encoding: .utf8, kind: kind) { warnings.append($0) }
        #expect(try Data(contentsOf: after) == Data(contentsOf: before))
        #expect(warnings.isEmpty)
    }

    @Test("writes plain text in the encoding named")
    func latin1Text() throws {
        let directory = try ScratchDirectory()
        let path = directory.url.appendingPathComponent("plain.txt").path
        try OutputFile.write("caf\u{E9}\n", to: path, encoding: .isoLatin1)
        #expect(FileManager.default.contents(atPath: path) == Data([0x63, 0x61, 0x66, 0xE9, 0x0A]))
    }

    @Test("writes decomposed characters precomposed in ISO-8859-1 and unchanged in UTF-8")
    func precomposedText() throws {
        let directory = try ScratchDirectory()
        let latin = directory.url.appendingPathComponent("latin.txt").path
        let utf8 = directory.url.appendingPathComponent("utf8.txt").path
        try OutputFile.write("cafe\u{301}", to: latin, encoding: .isoLatin1)
        try OutputFile.write("cafe\u{301}", to: utf8, encoding: .utf8)
        #expect(FileManager.default.contents(atPath: latin) == Data([0x63, 0x61, 0x66, 0xE9]))
        #expect(FileManager.default.contents(atPath: utf8) == Data("cafe\u{301}".utf8))
    }

    @Test("rejects a character of plain text that the encoding cannot hold, naming the file, line and column, and leaves no file")
    func unrepresentableText() throws {
        let directory = try ScratchDirectory()
        let path = directory.url.appendingPathComponent("plain.txt").path
        do {
            try OutputFile.write("first\nsecond \u{20AC}\n", to: path, encoding: .isoLatin1)
            Issue.record("Expected an error")
        } catch {
            let message = String(describing: error)
            #expect(message.contains(path), "\(message)")
            #expect(message.contains("line 2, column 8"), "\(message)")
            #expect(message.contains("U+20AC"), "\(message)")
            #expect(message.contains(TextEncoding.isoLatin1.name), "\(message)")
            #expect(error.localizedDescription == message)
        }
        #expect(!FileManager.default.fileExists(atPath: path))
    }

    @Test("keeps an existing file when the new text cannot be written")
    func keepsExistingFile() throws {
        let directory = try ScratchDirectory()
        let path = directory.url.appendingPathComponent("plain.txt").path
        try "old".write(toFile: path, atomically: true, encoding: .utf8)
        #expect(throws: OutputFileError.self) { try OutputFile.write("\u{2603}", to: path, encoding: .usASCII) }
        #expect(try String(contentsOfFile: path, encoding: .utf8) == "old")
    }

    @Test("writes XML with its encoding declared and numeric character references")
    func latin1XML() throws {
        let directory = try ScratchDirectory()
        let path = directory.url.appendingPathComponent("doc.xml").path
        try OutputFile.write(Self.metamodel, to: path, encoding: .isoLatin1, kind: .xml)
        let data = try #require(FileManager.default.contents(atPath: path))
        let text = try #require(TextEncoding.isoLatin1.decode(data))
        #expect(text.hasPrefix("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>"))
        #expect(text.contains("value=\"Costs 5 &#x20AC;\""))
        #expect(data.contains(0xE9))
    }

    @Test("writes JSON in UTF-8 with one warning when another encoding is named")
    func jsonWarning() throws {
        let directory = try ScratchDirectory()
        let path = directory.url.appendingPathComponent("doc.json").path
        var warnings: [String] = []
        try OutputFile.write("{\"name\":\"\u{2603}\"}", to: path, encoding: .isoLatin1, kind: .json) { warnings.append($0) }
        #expect(FileManager.default.contents(atPath: path) == Data("{\"name\":\"\u{2603}\"}".utf8))
        #expect(warnings == [OutputFile.jsonWarning(path: path, requested: .isoLatin1)])
        let warning = try #require(warnings.first)
        #expect(warning.hasPrefix(ConversionWarningReport.warningPrefix))
        #expect(warning.contains(path))
        #expect(warning.contains("UTF-8"))
        #expect(warning.contains("ISO-8859-1"))
        #expect(warning.hasSuffix("\n"))
    }

    // MARK: - Saving models

    @Test("saves a model in UTF-8 exactly as ModelIO does, and in another encoding by the rules of its kind")
    func savesModels() async throws {
        let directory = try ScratchDirectory()
        let resource = try await ModelIO.load(
            data: Data(Self.metamodel.utf8), uri: "memory:/cafe.ecore", resourceSet: ResourceSet()).resource
        let plain = directory.url.appendingPathComponent("plain.ecore")
        let same = directory.url.appendingPathComponent("same.ecore")
        try await ModelIO.save(resource, to: plain)
        try await OutputFile.save(resource, to: same, encoding: .utf8)
        #expect(try Data(contentsOf: same) == Data(contentsOf: plain))

        let latin = directory.url.appendingPathComponent("latin.ecore")
        try await OutputFile.save(resource, to: latin, encoding: .isoLatin1)
        let text = try #require(TextEncoding.isoLatin1.decode(try Data(contentsOf: latin)))
        #expect(text.contains("encoding=\"ISO-8859-1\""))
        #expect(text.contains("&#x20AC;"))

        let emfatic = directory.url.appendingPathComponent("ascii.emf")
        do {
            try await OutputFile.save(resource, to: emfatic, encoding: .usASCII)
            Issue.record("Expected an error")
        } catch let error as OutputFileError {
            #expect(error.description.contains(emfatic.path))
            #expect(error.description.contains("line "))
        }
        #expect(!FileManager.default.fileExists(atPath: emfatic.path))

        var warnings: [String] = []
        let json = directory.url.appendingPathComponent("cafe.json")
        try await OutputFile.save(resource, to: json, encoding: .isoLatin1) { warnings.append($0) }
        #expect(warnings == [OutputFile.jsonWarning(path: json.path, requested: .isoLatin1)])
    }
}
