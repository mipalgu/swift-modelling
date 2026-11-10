//
// OutputEncodingGenerationTests.swift
// ModellingGeneratorsTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation
import Testing

@testable import ModellingGenerators

/// Tests for the character encoding in which the generation pipelines write generator models
/// and generated files.
///
/// Files are written in UTF-8 unless the options name another encoding. A generator model is
/// XML, which names the encoding in its declaration and refers to a character that the
/// encoding cannot hold by number. A template file that names no charset is written in the
/// encoding of the options, and one that names a charset keeps it.
@Suite("Generation - output encodings")
struct OutputEncodingGenerationTests {
    /// A metamodel whose class name has a character outside US-ASCII but inside ISO-8859-1.
    static let metamodel = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" \
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" \
        xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="shop" \
        nsURI="http://www.example.org/shop" nsPrefix="shop">
          <eClassifiers xsi:type="ecore:EClass" name="Caf\u{E9}">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" \
        eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
          </eClassifiers>
        </ecore:EPackage>

        """

    /// A copyright text with a character inside ISO-8859-1 and one outside it.
    static let copyright = "\u{A9} Caf\u{E9} \u{20AC}"

    /// The XML declaration of a document in ISO-8859-1.
    static let latin1Declaration = #"<?xml version="1.0" encoding="ISO-8859-1"?>"#

    /// A scratch directory holding ``metamodel`` as `shop.ecore`.
    struct Workspace {
        /// The scratch directory.
        let scratch: ScratchDirectory

        /// The metamodel.
        var model: URL { scratch.url.appendingPathComponent("shop.ecore") }

        /// Creates the directory and the metamodel.
        init() throws {
            scratch = try ScratchDirectory()
            try scratch.write(OutputEncodingGenerationTests.metamodel, to: "shop.ecore")
        }

        /// Imports the metamodel into a generator model.
        ///
        /// - Parameters:
        ///   - name: The path of the generator model, relative to the scratch directory.
        ///   - encoding: The encoding to write it in, or `nil` to leave the default.
        /// - Returns: The bytes of the generator model.
        @MainActor
        func genModel(_ name: String, encoding: TextEncoding?) async throws -> Data {
            var options = GenModelImportOptions(atlOptions: .standard)
            options.copyright = OutputEncodingGenerationTests.copyright
            options.output = scratch.url.appendingPathComponent(name)
            if let encoding { options.outputEncoding = encoding }
            let result = try await GenerationPipeline.ecoreToGenModel(ecoreURLs: [model], options: options)
            return try Data(contentsOf: result.url)
        }

        /// Generates code from the metamodel.
        ///
        /// - Parameters:
        ///   - language: The language of the template set.
        ///   - directory: The output directory, relative to the scratch directory.
        ///   - options: The options of the generation.
        /// - Returns: The bytes of every generated file, by path relative to the output directory.
        @MainActor
        func generate(
            _ language: String, into directory: String, options: GenerationOptions
        ) async throws -> [String: Data] {
            let output = scratch.url.appendingPathComponent(directory)
            _ = try await GenerationPipeline.generate(
                inputURL: model, language: language, outputDirectory: output,
                importOptions: GenModelImportOptions(atlOptions: .standard), options: options)
            return try OutputEncodingGenerationTests.files(below: output)
        }

        /// Removes the directory.
        func remove() { scratch.remove() }
    }

    /// The regular files below a directory.
    ///
    /// - Parameter directory: The directory.
    /// - Returns: The bytes of every file, by path relative to the directory.
    static func files(below directory: URL) throws -> [String: Data] {
        var files: [String: Data] = [:]
        let base = directory.standardizedFileURL.resolvingSymlinksInPath().path
        let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey])
        while let url = enumerator?.nextObject() as? URL {
            guard try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else { continue }
            let path = url.standardizedFileURL.resolvingSymlinksInPath().path
            files[String(path.dropFirst(base.count))] = try Data(contentsOf: url)
        }
        return files
    }

    @Test("the options write UTF-8 by default")
    func defaults() {
        #expect(GenerationOptions(mtlOptions: .standard).outputEncoding == .utf8)
        #expect(GenModelImportOptions(atlOptions: .standard).outputEncoding == .utf8)
    }

    @Test("a generator model is written in UTF-8 by default, byte for byte as with UTF-8 named")
    @MainActor
    func genModelDefault() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let implicit = try await workspace.genModel("implicit/shop.genmodel", encoding: nil)
        let explicit = try await workspace.genModel("explicit/shop.genmodel", encoding: .utf8)

        let text = try #require(String(data: implicit, encoding: .utf8))
        #expect(text.contains(Self.copyright))
        #expect(implicit == explicit)
    }

    @Test("a generator model in ISO-8859-1 names it and refers to other characters by number")
    @MainActor
    func genModelLatin1() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let data = try await workspace.genModel("shop.genmodel", encoding: .isoLatin1)

        let text = try #require(String(data: data, encoding: .isoLatin1))
        #expect(text.hasPrefix(Self.latin1Declaration), "\(text.prefix(80))")
        #expect(text.contains("\u{A9} Caf\u{E9} &#x20AC;"), "\(text)")
        #expect(String(data: data, encoding: .utf8) == nil)
    }

    @Test("generated code is written in the encoding of the options")
    @MainActor
    func generatedLatin1() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        var options = GenerationOptions(mtlOptions: .standard)

        let implicit = try await workspace.generate("swift", into: "implicit", options: options)
        options.outputEncoding = .utf8
        let explicit = try await workspace.generate("swift", into: "explicit", options: options)
        options.outputEncoding = .isoLatin1
        let latin1 = try await workspace.generate("swift", into: "latin1", options: options)

        #expect(!implicit.isEmpty)
        #expect(implicit == explicit)
        #expect(Set(latin1.keys) == Set(implicit.keys))
        for (path, data) in implicit {
            let text = try #require(String(data: data, encoding: .utf8), "\(path)")
            #expect(latin1[path] == text.data(using: .isoLatin1), "\(path)")
        }
        #expect(latin1.values.contains { $0.contains(0xE9) })
    }

    @Test("a character that the encoding cannot hold stops the generation, naming the file, line and column")
    @MainActor
    func generatedUnrepresentable() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        var options = GenerationOptions(mtlOptions: .standard)
        options.outputEncoding = .usASCII

        let error = await #expect(throws: GenerationError.self) {
            _ = try await workspace.generate("swift", into: "ascii", options: options)
        }

        let message = String(describing: error)
        #expect(message.contains("line "), "\(message)")
        #expect(message.contains("column "), "\(message)")
        #expect(message.contains("U+00E9"), "\(message)")
        let written = try Self.files(below: workspace.scratch.url.appendingPathComponent("ascii"))
        for (path, data) in written {
            #expect(!data.contains { $0 >= 0x80 }, "\(path) was written in part")
        }
    }

    @Test("a template file without a charset follows the options, and one with a charset keeps it")
    @MainActor
    func templateCharsets() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.scratch.write(
            #"""
            {"name": "outline", "mainModule": "main", "mainTemplate": "main", "options": {"lineDelimiter": "\n"}}
            """#, to: "templates/outline/templateset.json")
        try workspace.scratch.write(
            """
            [module main('http://www.eclipse.org/emf/2002/GenModel')/]
            [template public main(genModel : GenModel)]
            [file ('default.txt')]Caf\u{E9}[/file]
            [file ('named.txt', false, 'UTF-8')]Caf\u{E9}[/file]
            [/template]
            """, to: "templates/outline/main.mtl")
        var options = GenerationOptions(
            templatePaths: [workspace.scratch.url.appendingPathComponent("templates")], mtlOptions: .standard)
        options.outputEncoding = .isoLatin1

        let files = try await workspace.generate("outline", into: "outline", options: options)

        let defaulted = try #require(files.first { $0.key.hasSuffix("default.txt") }?.value)
        let named = try #require(files.first { $0.key.hasSuffix("named.txt") }?.value)
        #expect(defaulted == Data([0x43, 0x61, 0x66, 0xE9]))
        #expect(named == Data("Caf\u{E9}".utf8))
    }
}
