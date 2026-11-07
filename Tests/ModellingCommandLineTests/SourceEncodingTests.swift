//
// SourceEncodingTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import EMFBase
import Foundation
import ModellingCommandLine
import Testing

/// Tests for the encoding option, its configuration key and the reading of source files.
@Suite("Source file encodings")
struct SourceEncodingTests {
    /// Text with a letter that is encoded differently in UTF-8 and ISO-8859-1.
    static let text = "-- Café\nmodule Encoded;\n"

    /// Encodes text in ISO-8859-1.
    ///
    /// - Parameter text: Text whose characters are all below U+0100.
    /// - Returns: One byte per character.
    static func latin1(_ text: String) -> Data {
        Data(text.unicodeScalars.map { UInt8($0.value) })
    }

    /// Writes bytes to a new file in a new temporary directory.
    ///
    /// - Parameter bytes: The contents of the file.
    /// - Returns: The path of the file.
    /// - Throws: Any error writing the file.
    static func write(_ bytes: Data) throws -> String {
        let directory = try ScratchDirectory()
        let url = directory.url.appendingPathComponent("Encoded.atl")
        try bytes.write(to: url)
        return url.path
    }

    /// Settings whose configuration file names an encoding, or none.
    ///
    /// - Parameter encoding: The value of the `encoding` key, or `nil` to leave it out.
    /// - Returns: The settings.
    /// - Throws: The error of reading the configuration.
    static func settings(encoding: String?) throws -> SemanticsSettings {
        let text = encoding.map { #"{ "encoding": "\#($0)" }"# } ?? "{}"
        let configuration = try ModellingConfiguration(
            data: Data(text.utf8), url: URL(fileURLWithPath: "/projects/example/.swift-modelling.json"))
        return SemanticsSettings(configuration: configuration)
    }

    // MARK: - Option

    @Test("names the option once and lists every supported encoding")
    func optionNames() {
        #expect(SourceEncodingOptions.optionName == "encoding")
        #expect(SourceEncodingOptions.valueList == TextEncoding.allCases.map(\.name).joined(separator: "|"))
    }

    @Test("accepts the name and the aliases of each encoding", arguments: TextEncoding.allCases)
    func parsesNames(encoding: TextEncoding) throws {
        for name in [encoding.name, encoding.name.lowercased()] + encoding.aliases {
            let options = try SourceEncodingOptions.parse(["--encoding", name])
            #expect(options.explicitEncoding == encoding, "\(name)")
        }
    }

    @Test("rejects an unknown encoding, listing the supported ones")
    func rejectsUnknown() {
        do {
            _ = try SourceEncodingOptions.parse(["--encoding", "EBCDIC"])
            Issue.record("Expected an error")
        } catch {
            let message = SourceEncodingOptions.message(for: error)
            #expect(message.contains("EBCDIC"), "\(message)")
            for encoding in TextEncoding.allCases {
                #expect(message.contains(encoding.name), "\(encoding.name) is missing from: \(message)")
            }
        }
        let help = SourceEncodingOptions.helpMessage()
        for encoding in TextEncoding.allCases {
            #expect(help.contains(encoding.name), "\(encoding.name) is missing from: \(help)")
        }
    }

    @Test("detects the encoding when nothing chooses one")
    func defaultEncoding() throws {
        let options = try SourceEncodingOptions.parse([])
        #expect(options.explicitEncoding == nil)
        #expect(options.encoding(settings: try Self.settings(encoding: nil)) == nil)
    }

    @Test("takes the encoding of the configuration file")
    func configuredEncoding() throws {
        let options = try SourceEncodingOptions.parse([])
        #expect(options.encoding(settings: try Self.settings(encoding: "latin1")) == .isoLatin1)
        #expect(options.encoding(settings: try Self.settings(encoding: "windows-1252")) == .windows1252)
    }

    @Test("lets the command line override the configuration file")
    func commandLineOverridesConfiguration() throws {
        let options = try SourceEncodingOptions.parse(["--encoding", "UTF-8"])
        #expect(options.encoding(settings: try Self.settings(encoding: "ISO-8859-1")) == .utf8)
    }

    @Test("describes the option for the discussion of a command")
    func discussion() {
        let text = SourceEncodingOptions.discussion(reader: "the transformation")
        #expect(text.contains("--\(SourceEncodingOptions.optionName)"))
        #expect(text.contains("the transformation"))
        #expect(text.contains(TextEncoding.utf8.name))
        #expect(text.contains(TextEncoding.isoLatin1.name))
        #expect(text.contains("configuration file"))
        #expect(!SourceEncodingOptions.discussion(reader: "x", configurable: false).contains("configuration file"))
    }

    // MARK: - Configuration key

    @Test("reads the encoding key of the configuration file by name or alias")
    func configurationKey() throws {
        #expect(ModellingConfiguration.keys.contains(SourceEncodingOptions.optionName))
        #expect(try Self.settings(encoding: "UTF-16LE").configuration.encoding == .utf16LittleEndian)
        #expect(try Self.settings(encoding: "cp1252").configuration.encoding == .windows1252)
        #expect(try Self.settings(encoding: nil).configuration.encoding == nil)
    }

    @Test("rejects an unknown encoding in the configuration file, listing the supported ones")
    func invalidConfigurationKey() {
        let file = URL(fileURLWithPath: "/projects/example/.swift-modelling.json")
        let error = configurationError { () throws(ModellingConfigurationError) in
            try ModellingConfiguration(data: Data(#"{ "encoding": "EBCDIC" }"#.utf8), url: file)
        }
        #expect(
            error == .invalidValue(
                "EBCDIC", key: SourceEncodingOptions.optionName, accepted: TextEncoding.allCases.map(\.name),
                path: file.path))
        let wrongType = configurationError { () throws(ModellingConfigurationError) in
            try ModellingConfiguration(data: Data(#"{ "encoding": 8 }"#.utf8), url: file)
        }
        #expect(wrongType == ModellingConfigurationError.wrongType(key: SourceEncodingOptions.optionName, expected: .string, path: file.path))
    }

    // MARK: - Reading

    @Test("reads a UTF-8 file exactly, without a warning")
    func readsUTF8() throws {
        let path = try Self.write(Data(Self.text.utf8))
        let decoded = try SourceFile.read(path)
        #expect(decoded.text == Self.text)
        #expect(decoded.encoding == .utf8)
        #expect(decoded.warning == nil)
    }

    @Test("reads a file that is not UTF-8 as ISO-8859-1 with a warning")
    func readsLatin1() throws {
        let path = try Self.write(Self.latin1(Self.text))
        let decoded = try SourceFile.read(path)
        #expect(decoded.text == Self.text)
        #expect(decoded.encoding == .isoLatin1)
        #expect(decoded.warning?.code == TextDecodingDiagnostic.decodedAsISOLatin1)
    }

    @Test("reads a file in an explicit encoding without a warning")
    func readsExplicitEncoding() throws {
        let path = try Self.write(Self.latin1(Self.text))
        let decoded = try SourceFile.read(path, encoding: .isoLatin1)
        #expect(decoded.text == Self.text)
        #expect(decoded.warning == nil)
    }

    @Test("rejects a file that is not valid in an explicit encoding, naming the file and the encoding")
    func rejectsMalformed() throws {
        let path = try Self.write(Self.latin1(Self.text))
        #expect(throws: SourceFileError.malformed(path: path, encoding: .usASCII)) {
            try SourceFile.read(path, encoding: .usASCII)
        }
        let description = SourceFileError.malformed(path: path, encoding: .usASCII).localizedDescription
        #expect(description.contains(path))
        #expect(description.contains(TextEncoding.usASCII.name))
    }

    @Test("reports a missing file as reading UTF-8 text did")
    func missingFile() throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".atl").path
        var expected: (any Error)?
        do {
            _ = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            expected = error
        }
        #expect(expected != nil)
        do {
            _ = try SourceFile.read(path)
            Issue.record("Expected an error")
        } catch {
            #expect(error.localizedDescription == expected?.localizedDescription)
        }
    }

    // MARK: - Warnings

    @Test("names the file and the place of a warning")
    func warningLines() throws {
        let path = try Self.write(Self.latin1(Self.text))
        let warning = try #require(try SourceFile.read(path).warning)
        let lines = FileDiagnosticReport.lines(for: [warning, warning], file: "Encoded.atl")
        #expect(lines == ["warning: Encoded.atl: line 1, column 7: \(warning.message)"])
    }

    @Test("names the document of a warning without a file", arguments: [true, false])
    func warningDocument(fileURL: Bool) {
        let document = fileURL ? URL(fileURLWithPath: "/models/Shop.ecore").absoluteString : "memory:shop"
        let warning = SourceDiagnostic(severity: .warning, code: "test", message: "Something", document: document)
        let expected = fileURL ? "/models/Shop.ecore" : "memory:shop"
        #expect(FileDiagnosticReport.lines(for: [warning]) == ["warning: \(expected): Something"])
        let anonymous = SourceDiagnostic(severity: .warning, code: "test", message: "Something")
        #expect(FileDiagnosticReport.lines(for: [anonymous]) == ["warning: Something"])
    }

    @Test("reports errors after their own prefix and leaves out information")
    func severities() {
        let error = SourceDiagnostic(severity: .error, code: "test", message: "Broken")
        let information = SourceDiagnostic(severity: .information, code: "test", message: "Note")
        #expect(FileDiagnosticReport.lines(for: [error, information], file: "x") == ["error: x: Broken"])
        #expect(FileDiagnosticReport.errorPrefix == "error: ")
    }
}
