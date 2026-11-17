//
// DocumentURIOptionsTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import ModellingCommandLine
import Testing

/// Tests for the option that chooses how a written model writes the URIs of other documents.
@Suite("Document URI option")
struct DocumentURIOptionsTests {
    @Test("names the option and lists its values")
    func names() {
        #expect(DocumentURIOptions.optionName == "document-uris")
        #expect(DocumentURIStyle.allCases.map(\.rawValue) == ["relative", "absolute"])
        #expect(DocumentURIOptions.valueList == "relative|absolute")
    }

    @Test("writes relative URIs when the command line names no style")
    func relativeByDefault() throws {
        let options = try DocumentURIOptions.parse([])
        #expect(options.explicitStyle == nil)
        #expect(options.style == .relative)
        #expect(DocumentURIOptions.defaultStyle == .relative)
    }

    @Test("reads each style from the command line", arguments: DocumentURIStyle.allCases)
    func parses(style: DocumentURIStyle) throws {
        let options = try DocumentURIOptions.parse(["--document-uris", style.rawValue])
        #expect(options.style == style)
    }

    @Test("rejects a value that is not a style")
    func rejects() {
        #expect(throws: (any Error).self) { try DocumentURIOptions.parse(["--document-uris", "sideways"]) }
    }

    @Test("switches relative URIs and keeps the layout of the options it applies to")
    func applies() throws {
        let relative = try DocumentURIOptions.parse([])
        let absolute = try DocumentURIOptions.parse(["--document-uris", "absolute"])

        var legacy = XMISerializationOptions.legacy
        relative.apply(to: &legacy)
        var expected = XMISerializationOptions.legacy
        expected.relativeURIs = true
        #expect(legacy == expected)
        absolute.apply(to: &legacy)
        #expect(legacy == .legacy)

        var emf = XMISerializationOptions.emf
        relative.apply(to: &emf)
        #expect(emf == .emf)
        absolute.apply(to: &emf)
        #expect(emf.relativeURIs == false)
        emf.relativeURIs = true
        #expect(emf == .emf)
    }

    @Test("sets the style as if on the command line")
    func setsStyle() throws {
        var options = try DocumentURIOptions.parse([])
        options.style = .absolute
        #expect(options.explicitStyle == .absolute)
        #expect(options.style == .absolute)
    }

    @Test("describes the option for the discussion of a command")
    func discussion() {
        let text = DocumentURIOptions.discussion(written: "target models")
        #expect(text.contains("--document-uris"))
        #expect(text.contains("target models"))
        #expect(text.contains(DocumentURIStyle.relative.rawValue))
        #expect(text.contains(DocumentURIStyle.absolute.rawValue))
    }

    // MARK: - Configuration file

    /// The location that the parsed text pretends to come from.
    private static let file = URL(fileURLWithPath: "/projects/example/.swift-modelling.json")

    /// The settings whose configuration file holds a text.
    ///
    /// - Parameter text: The contents of the file.
    /// - Returns: The settings.
    /// - Throws: ``ModellingConfigurationError`` if the text is not a valid configuration.
    private static func settings(_ text: String) throws -> SemanticsSettings {
        SemanticsSettings(configuration: try ModellingConfiguration(data: Data(text.utf8), url: file))
    }

    /// The error that reading a text throws, if any.
    ///
    /// - Parameter text: The contents of the file.
    /// - Returns: The error, or `nil` if the text is a valid configuration.
    private static func error(_ text: String) -> ModellingConfigurationError? {
        configurationError { () throws(ModellingConfigurationError) in
            try ModellingConfiguration(data: Data(text.utf8), url: file)
        }
    }

    @Test("is a key of the configuration file")
    func key() {
        #expect(ModellingConfiguration.keys.contains(DocumentURIOptions.optionName))
    }

    @Test("reads each style from the configuration file", arguments: DocumentURIStyle.allCases)
    func readsKey(style: DocumentURIStyle) throws {
        let settings = try Self.settings(#"{ "document-uris": "\#(style.rawValue)" }"#)
        #expect(settings.configuration.documentURIs == style)
        #expect(try DocumentURIOptions.parse([]).style(settings: settings) == style)
    }

    @Test("leaves the style open without the key")
    func absentKey() throws {
        let settings = try Self.settings("{}")
        #expect(settings.configuration.documentURIs == nil)
        #expect(try DocumentURIOptions.parse([]).style(settings: settings) == .relative)
        #expect(try DocumentURIOptions.parse([]).style(settings: SemanticsSettings()) == .relative)
    }

    @Test(
        "lets the command line override the key of the file",
        arguments: DocumentURIStyle.allCases, DocumentURIStyle.allCases)
    func precedence(inFile: DocumentURIStyle, onCommandLine: DocumentURIStyle) throws {
        let settings = try Self.settings(#"{ "document-uris": "\#(inFile.rawValue)" }"#)
        let options = try DocumentURIOptions.parse(["--document-uris", onCommandLine.rawValue])
        #expect(options.style(settings: settings) == onCommandLine)
    }

    @Test("rejects a value of the key that is not a style, naming the accepted values")
    func invalidKey() {
        #expect(
            Self.error(#"{ "document-uris": "sideways" }"#)
                == .invalidValue("sideways", key: "document-uris", accepted: ["relative", "absolute"], path: Self.file.path))
    }

    @Test("rejects a value of the key that is not a string", arguments: [#"{ "document-uris": true }"#, #"{ "document-uris": ["relative"] }"#])
    func wrongTypeKey(text: String) {
        #expect(Self.error(text) == .wrongType(key: "document-uris", expected: .string, path: Self.file.path))
    }

    @Test("applies the style of a run and keeps the layout of the options it applies to")
    func appliesWithSettings() throws {
        let configured = try Self.settings(#"{ "document-uris": "absolute" }"#)
        let none = try DocumentURIOptions.parse([])
        let relative = try DocumentURIOptions.parse(["--document-uris", "relative"])

        var fromFile = XMISerializationOptions.emf
        none.apply(to: &fromFile, settings: configured)
        #expect(fromFile.relativeURIs == false)
        fromFile.relativeURIs = true
        #expect(fromFile == .emf)

        var overridden = XMISerializationOptions.legacy
        relative.apply(to: &overridden, settings: configured)
        #expect(overridden.relativeURIs)
        overridden.relativeURIs = false
        #expect(overridden == .legacy)
    }

    @Test("writes the default layout with the style of a run")
    func serializationOptions() throws {
        var relative = XMISerializationOptions.legacy
        relative.relativeURIs = true
        let configured = try Self.settings(#"{ "document-uris": "absolute" }"#)

        #expect(try DocumentURIOptions.parse([]).serializationOptions(settings: SemanticsSettings()) == relative)
        #expect(try DocumentURIOptions.parse([]).serializationOptions(settings: configured) == .legacy)
        #expect(
            try DocumentURIOptions.parse(["--document-uris", "relative"]).serializationOptions(settings: configured)
                == relative)
    }

    @Test("combines the reference style and the document URIs of a run")
    func combinedWithReferenceStyle() throws {
        let configured = try Self.settings(#"{ "reference-style": "plain", "document-uris": "absolute" }"#)
        let noStyle = try ReferenceStyleOptions.parse([])
        let none = try DocumentURIOptions.parse([])

        var encodedRelative = XMISerializationOptions.legacy
        encodedRelative.relativeURIs = true
        #expect(noStyle.serializationOptions(settings: SemanticsSettings(), documentURIs: none) == encodedRelative)

        var plainAbsolute = try ReferenceStyleOptions.parse(["--reference-style", "plain"]).serializationOptions
        plainAbsolute.relativeURIs = false
        #expect(noStyle.serializationOptions(settings: configured, documentURIs: none) == plainAbsolute)

        let explicit = try DocumentURIOptions.parse(["--document-uris", "relative"])
        let encoded = try ReferenceStyleOptions.parse(["--reference-style", "encoded"])
        #expect(encoded.serializationOptions(settings: configured, documentURIs: explicit) == encodedRelative)
    }
}

/// Tests for the URI that a written model has, against which it refers to other documents.
@Suite("Document URI of an output file")
struct OutputDocumentURITests {
    @Test("gives a file named by an absolute path its file URI")
    func absolutePath() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("output-uri")
        let path = directory.appendingPathComponent("notes.xmi").path
        let uri = OutputFile.documentURI(ofPath: path)
        #expect(uri == URIReference.canonicalise(URL(fileURLWithPath: path).absoluteString))
        #expect(uri.hasPrefix("file:///"))
        #expect(uri.hasSuffix("/output-uri/notes.xmi"))
    }

    @Test(
        "resolves a file named by a relative path against the current directory",
        arguments: ["output/notes.xmi", "./output/notes.xmi", "models/../output/notes.xmi"])
    func relativePath(path: String) throws {
        let current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        let expected = URIReference.canonicalise(current.appendingPathComponent("output/notes.xmi").absoluteString)
        let uri = OutputFile.documentURI(ofPath: path)
        #expect(uri == expected)
        #expect(uri.hasPrefix("file:///"))
        #expect(!uri.contains("/./"))
        #expect(!uri.contains("/../"))
    }

    @Test("relativises the URI of another document against the written file")
    func relativises() {
        let written = OutputFile.documentURI(ofPath: "output/notes.xmi")
        let other = OutputFile.documentURI(ofPath: "models/tasks.xmi")
        #expect(URIReference.relativise(other, against: written) == "../models/tasks.xmi")
    }
}
