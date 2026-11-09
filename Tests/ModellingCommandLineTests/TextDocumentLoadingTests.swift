//
// TextDocumentLoadingTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingCommandLine
import Testing

/// Tests for reading models and metamodels in text formats in the character encoding of a run.
@Suite("Text documents in an encoding")
struct TextDocumentLoadingTests {
    /// A KM3 metamodel whose first line holds a character outside ASCII.
    static let metamodel = """
        -- Caf\u{E9} catalogue
        package shop {
          class Item {
            attribute name : String;
          }
        }
        package PrimitiveTypes {
          datatype String;
        }

        """

    /// A multi-level model whose first line holds a character outside ASCII.
    static let model = """
        // Caf\u{E9} catalogue
        Model Catalogue@1 {
          Node Drink {
            price : double = 1.0;
          }
        }

        Catalogue Menu {
          Drink tea {
            price = 2.5;
          }
        }

        """

    /// The message of the warning of reading a document as ISO-8859-1.
    static let fallback = "The text is not valid UTF-8 and was read as ISO-8859-1"

    /// Writes a text in ISO-8859-1 into a new scratch directory.
    ///
    /// - Parameters:
    ///   - text: The text.
    ///   - name: The file name.
    /// - Returns: The location of the file.
    static func writeLatin1(_ text: String, as name: String) throws -> URL {
        let url = try ScratchDirectory().url.appendingPathComponent(name)
        try text.write(to: url, atomically: true, encoding: .isoLatin1)
        return url
    }

    /// Removes the scratch directory of a file written by ``writeLatin1(_:as:)``.
    ///
    /// - Parameter url: The file.
    static func remove(_ url: URL) {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    /// A writer that collects the text it receives.
    final class Collector {
        /// The text received so far.
        var text = ""

        /// Appends text.
        ///
        /// - Parameter more: The text to append.
        func write(_ more: String) { text += more }
    }

    @Test("reads a MetaDepth document as ISO-8859-1 with a warning, or in the encoding given")
    @MainActor
    func metaDepthModel() async throws {
        let url = try Self.writeLatin1(Self.model, as: "menu.mdepth")
        defer { Self.remove(url) }
        await MultiLevelSupport.registerFormats()

        let detected = Collector()
        let fallback = try await TextDocumentLoading.load(
            url: url, path: "menu.mdepth", format: .metadepth, resourceSet: ResourceSet(), encoding: nil,
            diagnosticOutput: detected.write)
        #expect(await MultiLevelSupport.deepModel(in: fallback.resource) != nil)
        #expect(detected.text == "warning: menu.mdepth: line 1, column 7: \(Self.fallback)\n")

        let given = Collector()
        let latin1 = try await TextDocumentLoading.load(
            url: url, path: "menu.mdepth", format: .metadepth, resourceSet: ResourceSet(), encoding: .isoLatin1,
            diagnosticOutput: given.write)
        #expect(await MultiLevelSupport.deepModel(in: latin1.resource) != nil)
        #expect(given.text.isEmpty)

        await #expect(throws: SourceFileError.malformed(path: "menu.mdepth", encoding: .utf8)) {
            _ = try await TextDocumentLoading.load(
                url: url, path: "menu.mdepth", format: .metadepth, resourceSet: ResourceSet(), encoding: .utf8)
        }
    }

    @Test("leaves XMI documents to their own decoding rules, without a warning")
    @MainActor
    func xmiModel() async throws {
        let directory = try ScratchDirectory().url
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("item.xmi")
        try """
            <?xml version="1.0" encoding="UTF-8"?>
            <shop:Item xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:shop="shop" name="tea"/>

            """.write(to: url, atomically: true, encoding: .utf8)
        let collector = Collector()
        let loaded = try await TextDocumentLoading.load(
            url: url, format: .xmi, resourceSet: ResourceSet(), options: ModelIO.LoadOptions(requiresMetamodel: false),
            encoding: .isoLatin1, diagnosticOutput: collector.write)
        #expect(await loaded.resource.getRootObjects().count == 1)
        #expect(collector.text.isEmpty)
        #expect(TextDocumentLoading.decodingWarnings(in: await loaded.resource.loadDiagnostics).isEmpty)
    }

    @Test("reads a KM3 metamodel in the encoding of the load options, naming the file of an error")
    @MainActor
    func km3Metamodel() async throws {
        let url = try Self.writeLatin1(Self.metamodel, as: "Shop.km3")
        defer { Self.remove(url) }
        var options = EcoreLoadOptions()
        options.textEncoding = .isoLatin1
        #expect(try await MetamodelRegistration.loadPackages(at: url.path, options: options).first?.name == "shop")
        options.textEncoding = .utf8
        await #expect(throws: SourceFileError.malformed(path: url.path, encoding: .utf8)) {
            _ = try await MetamodelRegistration.loadPackages(at: url.path, options: options)
        }
        #expect(
            SourceFileError.malformed(path: "Shop.km3", encoding: .utf8).description
                == "Cannot read Shop.km3: the file is not valid UTF-8 text")
    }

    @Test("reads a multi-level model for a deep view in the encoding given")
    @MainActor
    func deepView() async throws {
        let url = try Self.writeLatin1(Self.model, as: "menu.mdepth")
        defer { Self.remove(url) }
        let loaded = try await MultiLevelSupport.views(
            ofFileAt: url, level: 0, encoding: .isoLatin1, in: ResourceSet())
        let views = try #require(loaded)
        #expect(views.view.package.name == "Catalogue")
        await #expect(throws: SourceFileError.self) {
            _ = try await MultiLevelSupport.views(ofFileAt: url, level: 0, encoding: .utf8, in: ResourceSet())
        }
    }
}
