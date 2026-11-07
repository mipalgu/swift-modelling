//
// ModelFileFormatTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import ModellingCommandLine
import Testing

/// Tests for the format in which the tools read and write a model instance file.
///
/// A format given on the command line and the extensions of the supported formats decide as
/// before. A file with any other extension is read in the format of its contents, and a file
/// whose contents are neither XML nor JSON is reported as having an unsupported format; it is
/// still written as XMI, whatever it held before.
@Suite("Model file formats")
struct ModelFileFormatTests {
    /// The start of an XMI document.
    static let xmi = #"<?xml version="1.0" encoding="UTF-8"?>"# + "\n<shop:Shop xmlns:shop=\"http://example.org/shop\"/>\n"

    /// A JSON document.
    static let json = #"{ "eClass": "http://example.org/shop#//Shop" }"# + "\n"

    /// Text that is neither XML nor JSON.
    static let text = "Shop: Corner Store\n"

    /// Writes a file in a new temporary directory.
    ///
    /// - Parameters:
    ///   - contents: The contents of the file.
    ///   - name: The name of the file.
    /// - Returns: The location of the file.
    /// - Throws: Any error writing the file.
    static func write(_ contents: String, named name: String) throws -> URL {
        let url = try ScratchDirectory().url.appendingPathComponent(name)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @Test(
        "keeps the format of a known extension, whatever the contents",
        arguments: [("model.xmi", ModelFormat.xmi), ("model.json", .json), ("model.ecore", .xmi), ("MODEL.JSON", .json)])
    func knownExtension(name: String, format: ModelFormat) throws {
        for contents in [Self.xmi, Self.json, Self.text] {
            let url = try Self.write(contents, named: name)
            #expect(try ModelFileFormat.detectedInstanceFormat(of: url) == format)
            #expect(ModelFileFormat.instanceFormat(of: url) == format)
        }
    }

    @Test("keeps an explicit format, whatever the extension and contents", arguments: ["xmi", "json", "JSON"])
    func explicitFormat(name: String) throws {
        let expected: ModelFormat = name.lowercased() == "json" ? .json : .xmi
        for contents in [Self.xmi, Self.json, Self.text] {
            let url = try Self.write(contents, named: "model.dat")
            #expect(try ModelFileFormat.detectedInstanceFormat(of: url, explicit: name) == expected)
            #expect(ModelFileFormat.instanceFormat(of: url, explicit: name) == expected)
        }
    }

    @Test("reads XML with an unknown extension as XMI", arguments: ["model.model", "model.dat", "model"])
    func xmlContents(name: String) throws {
        let url = try Self.write(Self.xmi, named: name)
        #expect(try ModelFileFormat.detectedInstanceFormat(of: url) == .xmi)
        #expect(ModelFileFormat.instanceFormat(of: url) == .xmi)
    }

    @Test("reads an Ecore document with an unknown extension as XMI")
    func ecoreContents() throws {
        let ecore = """
            <?xml version="1.0" encoding="UTF-8"?>
            <ecore:EPackage xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="shop"/>

            """
        let url = try Self.write(ecore, named: "shop.metamodel")
        #expect(try ModelFileFormat.detectedInstanceFormat(of: url) == .xmi)
    }

    @Test("reads JSON with an unknown extension as JSON", arguments: ["model.model", "model.dat", "model"])
    func jsonContents(name: String) throws {
        let url = try Self.write(Self.json, named: name)
        #expect(try ModelFileFormat.detectedInstanceFormat(of: url) == .json)
        #expect(ModelFileFormat.instanceFormat(of: url) == .xmi)
    }

    @Test("reports contents that are neither XML nor JSON, listing the supported formats")
    func unsupportedContents() throws {
        let url = try Self.write(Self.text, named: "model.txt")
        #expect(throws: ModelFormatError.undetectableFormat(url.relativePath)) {
            try ModelFileFormat.detectedInstanceFormat(of: url)
        }
        let message = ModelFormatError.undetectableFormat(url.relativePath).localizedDescription
        for format in ModelFormat.allCases {
            #expect(message.contains(format.rawValue), "\(format) is missing from: \(message)")
        }
        #expect(ModelFileFormat.instanceFormat(of: url) == .xmi)
    }

    @Test("leaves a missing file to the reader")
    func missingFile() throws {
        let url = try ScratchDirectory().url.appendingPathComponent("missing.dat")
        #expect(try ModelFileFormat.detectedInstanceFormat(of: url) == .xmi)
        #expect(ModelFileFormat.instanceFormat(of: url) == .xmi)
    }
}
