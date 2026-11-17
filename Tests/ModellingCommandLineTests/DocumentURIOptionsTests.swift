//
// DocumentURIOptionsTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
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
}
