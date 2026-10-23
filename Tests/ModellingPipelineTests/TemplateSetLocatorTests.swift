//
// TemplateSetLocatorTests.swift
// ModellingPipelineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import ModellingGenerators
import ModellingPipeline
import Testing

@Suite("TemplateSetLocator - client roots, directories and imports")
@MainActor
struct TemplateSetLocatorTests {
    /// Writes a template set of a language below a root.
    ///
    /// - Parameters:
    ///   - language: The language of the set.
    ///   - root: The directory that holds template sets.
    ///   - descriptor: Extra members of the descriptor, as JSON text after the required ones.
    ///   - body: The body of the main template, which writes `result.txt`.
    ///   - header: Declarations between the module header and the main template.
    ///   - fixture: The fixture that writes the files.
    /// - Returns: The directory of the set.
    @discardableResult
    private func writeSet(
        _ language: String, in root: URL, descriptor: String = "", body: String,
        header: String = "", fixture: PipelineFixture
    ) throws -> URL {
        let directory = root.appendingPathComponent(language)
        let extra = descriptor.isEmpty ? "" : ", " + descriptor
        try fixture.write(
            """
            { "name": "\(language)", "mainModule": "generate", "mainTemplate": "generate"\(extra) }
            """, to: directory.appendingPathComponent(TemplateSetConstants.descriptorFileName))
        try fixture.write(
            """
            [module generate('http://example.com')]
            \(header)
            [template public generate()]
            [file ('result.txt')]\(body)[/file]
            [/template]
            """, to: directory.appendingPathComponent("generate.mtl"))
        return directory
    }

    /// Runs the set of a reference with a locator and returns the text of `result.txt`.
    private func generate(
        _ reference: String, locator: TemplateSetLocator, codeStyle: String? = nil,
        templatePaths: [URL] = [], fixture: PipelineFixture
    ) async throws -> String {
        let output = fixture.directory.appendingPathComponent("out-\(UUID().uuidString)")
        let result = try await GenerationStep(
            templates: .templateSet(reference, locator: locator, codeStyle: codeStyle),
            templatePaths: templatePaths, outputDirectory: output
        ).run(arguments: [])
        return try fixture.text(of: try #require(result.files.first))
    }

    @Test("searches the bundled template sets by default")
    func defaultRoots() {
        let locator = TemplateSetLocator()
        #expect(locator.bundledRoots == TemplateSet.defaultBundledRoots)
        #expect(locator.availableLanguages() == TemplateSet.availableLanguages())
        #expect(locator.availableLanguages().contains("java"))
        #expect(locator.codeStyles().map(\.language) == TemplateSet.bundledCodeStyles().map(\.language))
    }

    @Test("finds the template sets of a client root beside the bundled ones")
    func clientRoot() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let root = fixture.directory.appendingPathComponent("Templates")
        try writeSet("greeting", in: root, body: "hello", fixture: fixture)

        let alone = TemplateSetLocator(bundledRoots: [root])
        let both = TemplateSetLocator(bundledRoots: TemplateSet.defaultBundledRoots + [root])

        #expect(alone.availableLanguages() == ["greeting"])
        #expect(both.availableLanguages().contains("greeting"))
        #expect(both.availableLanguages().contains("java"))
        #expect(try await generate("greeting", locator: both, fixture: fixture) == "hello")
        #expect(throws: GenerationError.unknownLanguage("java", ["greeting"])) {
            try alone.assemble(language: "java")
        }
    }

    @Test("lets a later root replace the files of an earlier one")
    func laterRootWins() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let first = fixture.directory.appendingPathComponent("first")
        let second = fixture.directory.appendingPathComponent("second")
        try writeSet("greeting", in: first, body: "first", fixture: fixture)
        try writeSet("greeting", in: second, body: "second", fixture: fixture)

        let locator = TemplateSetLocator(bundledRoots: [first, second])
        #expect(try await generate("greeting", locator: locator, fixture: fixture) == "second")
    }

    @Test("assembles a set named by its directory")
    func setDirectory() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let directory = try writeSet(
            "local", in: fixture.directory.appendingPathComponent("sets"), body: "local", fixture: fixture)

        let locator = TemplateSetLocator(bundledRoots: [])
        #expect(try await generate(directory.path, locator: locator, fixture: fixture) == "local")
        #expect(TemplateSetLocator.isTemplateSet(directory))
        #expect(!TemplateSetLocator.isTemplateSet(fixture.directory))
    }

    @Test("rejects a path without a template set and an unknown language")
    func rejectsUnknownSets() throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let locator = TemplateSetLocator()

        #expect {
            try locator.assemble(templateSet: fixture.directory.path)
        } throws: { error in
            guard case GenerationError.templateSetInvalid(let name, _) = error else { return false }
            return name == fixture.directory.path
        }
        #expect {
            try locator.assemble(templateSet: "no/such/set")
        } throws: { error in
            guard case GenerationError.templateSetInvalid = error else { return false }
            return true
        }
        #expect {
            try locator.assemble(templateSet: "llvm")
        } throws: { error in
            guard case GenerationError.unknownLanguage("llvm", _) = error else { return false }
            return true
        }
    }

    @Test("copies imported directories beside the set and searches them")
    func imports() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let root = fixture.directory.appendingPathComponent("Templates")
        try fixture.write(
            """
            [module c('http://example.com')]
            [template public literal(text : String)]"[text/]"[/template]
            """, to: root.appendingPathComponent("expressions/c.mtl"))
        try writeSet(
            "c", in: root, descriptor: #""imports": ["../expressions"]"#, body: "[literal('x')/]",
            header: "[import expressions::c/]", fixture: fixture)

        let locator = TemplateSetLocator(bundledRoots: [root])
        let set = try locator.assemble(language: "c")
        defer { set.remove() }

        #expect(set.descriptor.imports == ["../expressions"])
        #expect(set.searchPaths.map(\.standardizedFileURL.path)
            == [set.directory, set.directory.deletingLastPathComponent()].map(\.standardizedFileURL.path))
        #expect(locator.availableLanguages() == ["c"])
        #expect(try await generate("c", locator: locator, fixture: fixture) == "\"x\"")
    }

    @Test("rejects imports that are missing or that clash with the set")
    func badImports() throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let root = fixture.directory.appendingPathComponent("Templates")
        try writeSet("missing", in: root, descriptor: #""imports": ["../nowhere"]"#, body: "", fixture: fixture)
        try writeSet("clash", in: root, descriptor: #""imports": ["."]"#, body: "", fixture: fixture)
        let locator = TemplateSetLocator(bundledRoots: [root])

        #expect {
            try locator.assemble(language: "missing")
        } throws: { error in
            guard case GenerationError.templateSetInvalid("missing", let cause) = error else { return false }
            return cause.contains("../nowhere")
        }
        #expect {
            try locator.assemble(language: "clash")
        } throws: { error in
            guard case GenerationError.templateSetInvalid("clash", _) = error else { return false }
            return true
        }
    }

    @Test("applies the code styles of a client set")
    func clientCodeStyles() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let root = fixture.directory.appendingPathComponent("Templates")
        try writeSet(
            "styled", in: root,
            descriptor: #""styles": { "tabs": { "sourceIndent": "  ", "targetIndent": "\t" } }"#,
            body: "{\n  x\n}", fixture: fixture)
        let locator = TemplateSetLocator(bundledRoots: [root])

        #expect(locator.codeStyles().map(\.language) == ["styled"])
        #expect(locator.codeStyles().first?.styles == ["tabs"])
        #expect(try await generate("styled", locator: locator, fixture: fixture) == "{\n  x\n}")
        #expect(try await generate("styled", locator: locator, codeStyle: "tabs", fixture: fixture) == "{\n\tx\n}")
        await #expect(throws: GenerationError.unknownCodeStyle("wide", "styled", ["tabs"])) {
            _ = try await generate("styled", locator: locator, codeStyle: "wide", fixture: fixture)
        }
    }

    @Test("replaces files of a set with those of the template paths")
    func templatePathOverrides() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let root = fixture.directory.appendingPathComponent("Templates")
        try writeSet("greeting", in: root, body: "bundled", fixture: fixture)
        let overrides = fixture.directory.appendingPathComponent("overrides")
        try writeSet("greeting", in: overrides, body: "override", fixture: fixture)

        let locator = TemplateSetLocator(bundledRoots: [root])
        #expect(try await generate("greeting", locator: locator, templatePaths: [overrides], fixture: fixture)
            == "override")
    }

    @Test("reads descriptors with and without imports")
    func descriptorCompatibility() throws {
        let plain = try JSONDecoder().decode(
            TemplateSetDescriptor.self,
            from: Data(#"{ "name": "x", "mainModule": "m", "mainTemplate": "t" }"#.utf8))
        let shared = try JSONDecoder().decode(
            TemplateSetDescriptor.self,
            from: Data(#"{ "name": "x", "mainModule": "m", "mainTemplate": "t", "imports": ["../a"] }"#.utf8))

        #expect(plain.imports.isEmpty)
        #expect(plain == TemplateSetDescriptor(name: "x", mainModule: "m", mainTemplate: "t"))
        #expect(shared.imports == ["../a"])
        #expect(shared == TemplateSetDescriptor(name: "x", mainModule: "m", mainTemplate: "t", imports: ["../a"]))
        let encoded = try JSONDecoder().decode(TemplateSetDescriptor.self, from: JSONEncoder().encode(shared))
        #expect(encoded == shared)
    }
}
