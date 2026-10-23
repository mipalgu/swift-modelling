//
// TemplateSetOptionTests.swift
// swift-mtl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@Suite("swift-mtl generate - template sets")
struct TemplateSetOptionTests {
    /// Writes a text file, creating its directory.
    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    /// The text of a file.
    private func text(of url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    /// Writes a template set whose main template takes a company and writes `company.txt`.
    ///
    /// - Parameters:
    ///   - scratch: The directory that receives the set.
    ///   - descriptor: Extra members of the descriptor, as JSON text after the required ones.
    ///   - body: The body of the file block.
    ///   - header: Declarations between the module header and the main template.
    /// - Returns: The directory of the set.
    private func writeSet(
        in scratch: URL, descriptor: String = "", body: String = "[c.name/]", header: String = ""
    ) throws -> URL {
        let set = scratch.appendingPathComponent("sets/report")
        let extra = descriptor.isEmpty ? "" : ", " + descriptor
        try write(
            """
            { "name": "report", "mainModule": "generate", "mainTemplate": "generate"\(extra) }
            """, to: set.appendingPathComponent("templateset.json"))
        try write(
            """
            [module generate('http://www.example.org/company')]
            \(header)
            [template public generate(c : Company)]
            [file ('company.txt')]\(body)[/file]
            done
            [/template]
            """, to: set.appendingPathComponent("generate.mtl"))
        return set
    }

    /// The arguments that pass the company model and its metamodel.
    private func modelArguments() throws -> [String] {
        let metamodel = try loadTestResource(named: "company.ecore", subdirectory: "models")
        let model = try loadTestResource(named: "simple-model.xmi", subdirectory: "models")
        return ["--metamodel", metamodel.path, "--model", model.path]
    }

    @Test("runs the main template of a template set directory with the models and parameters")
    @MainActor
    func runsSetDirectory() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let set = try writeSet(in: scratch, body: "[c.name/] [suffix/]")
        let output = scratch.appendingPathComponent("out")

        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: ["--template-set", set.path, "--output", output.path, "--param", "suffix=Ltd"]
                + (try modelArguments()))

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(try text(of: output.appendingPathComponent("company.txt")) == "Tech Innovations Ltd Ltd")
        #expect(try text(of: output.appendingPathComponent("stdout")).contains("done"))
    }

    @Test("imports the shared modules that the descriptor lists")
    @MainActor
    func sharedImports() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        try write(
            """
            [module quoting('http://www.example.org/company')]
            [template public quoted(text : String)]'[text/]'[/template]
            """, to: scratch.appendingPathComponent("sets/shared/quoting.mtl"))
        let set = try writeSet(
            in: scratch, descriptor: #""imports": ["../shared"]"#, body: "[quoted(c.name)/]",
            header: "[import shared::quoting/]")
        let output = scratch.appendingPathComponent("out")

        let result = try await executeSwiftMTL(
            command: "generate", arguments: ["--template-set", set.path, "--output", output.path] + (try modelArguments()))

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(try text(of: output.appendingPathComponent("company.txt")) == "'Tech Innovations Ltd'")
    }

    @Test("applies a code style of the set and rejects an unknown one")
    @MainActor
    func codeStyles() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let set = try writeSet(
            in: scratch, descriptor: #""styles": { "tabs": { "sourceIndent": "  ", "targetIndent": "\t" } }"#,
            body: "{\n  [c.name/]\n}")
        let output = scratch.appendingPathComponent("out")
        let base = ["--template-set", set.path, "--output", output.path, "--force-overwrite"] + (try modelArguments())

        let plain = try await executeSwiftMTL(command: "generate", arguments: base)
        let plainText = try text(of: output.appendingPathComponent("company.txt"))
        let styled = try await executeSwiftMTL(command: "generate", arguments: base + ["--code-style", "tabs"])
        let styledText = try text(of: output.appendingPathComponent("company.txt"))
        let unknown = try await executeSwiftMTL(command: "generate", arguments: base + ["--code-style", "wide"])

        #expect(plain.succeeded, "\(plain.stdout)\(plain.stderr)")
        #expect(plainText == "{\n  Tech Innovations Ltd\n}")
        #expect(styled.succeeded, "\(styled.stdout)\(styled.stderr)")
        #expect(styledText == "{\n\tTech Innovations Ltd\n}")
        #expect(!unknown.succeeded)
        #expect(unknown.stderr.contains("wide"))
    }

    @Test("replaces files of the set with those of the template paths")
    @MainActor
    func templatePathOverrides() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let set = try writeSet(in: scratch)
        let overrides = scratch.appendingPathComponent("overrides")
        try write(
            """
            [module generate('http://www.example.org/company')]
            [template public generate(c : Company)][file ('company.txt')]custom [c.name/][/file][/template]
            """, to: overrides.appendingPathComponent("generate.mtl"))
        let output = scratch.appendingPathComponent("out")

        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: ["--template-set", set.path, "--template-path", overrides.path, "--output", output.path]
                + (try modelArguments()))

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(try text(of: output.appendingPathComponent("company.txt")) == "custom Tech Innovations Ltd")
    }

    @Test("rejects an unknown bundled language, listing the bundled ones")
    @MainActor
    func unknownLanguage() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }

        let result = try await executeSwiftMTL(
            command: "generate", arguments: ["--template-set", "llvm", "--output", scratch.path])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("llvm"))
        #expect(result.stderr.contains("java"))
    }

    @Test("rejects a template file together with a template set, and neither")
    @MainActor
    func exclusiveTemplates() async throws {
        let templateURL = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let set = try writeSet(in: scratch)

        let both = try await executeSwiftMTL(
            command: "generate", arguments: [templateURL.path, "--template-set", set.path])
        let neither = try await executeSwiftMTL(command: "generate", arguments: ["--output", scratch.path])
        let styleWithFile = try await executeSwiftMTL(
            command: "generate", arguments: [templateURL.path, "--code-style", "tabs"])
        let templateWithSet = try await executeSwiftMTL(
            command: "generate", arguments: ["--template-set", set.path, "--template", "main"])

        #expect(!both.succeeded)
        #expect(both.stderr.contains("not both"))
        #expect(!neither.succeeded)
        #expect(neither.stderr.contains("--template-set"))
        #expect(!styleWithFile.succeeded)
        #expect(styleWithFile.stderr.contains("--code-style"))
        #expect(!templateWithSet.succeeded)
        #expect(templateWithSet.stderr.contains("--template"))
    }

    @Test("runs the template set of the MTL tutorial")
    @MainActor
    func tutorialSet() async throws {
        let resources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/SwiftModelling/SwiftModelling.docc/Resources")
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let set = scratch.appendingPathComponent("SwiftGenerator")
        try FileManager.default.createDirectory(at: set, withIntermediateDirectories: true)
        try FileManager.default.copyItem(
            at: resources.appendingPathComponent("mtl-step-41-templateset.json"),
            to: set.appendingPathComponent("templateset.json"))
        try FileManager.default.copyItem(
            at: resources.appendingPathComponent("mtl-step-39-class-helper.mtl"),
            to: set.appendingPathComponent("SwiftGenerator.mtl"))
        let output = scratch.appendingPathComponent("generated")

        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                "--template-set", set.path, "--model",
                resources.appendingPathComponent("step-04-company-class.ecore").path, "--output", output.path,
            ])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let generated = try text(of: output.appendingPathComponent("company.swift"))
        #expect(generated.contains("// Generated from company"))
        #expect(generated.contains("struct Person {"))
    }

    @Test("lists the template set options in the help")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftMTL(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        for option in ["--template-set", "--code-style", "templateset.json"] {
            #expect(result.stdout.contains(option), "\(option) is missing from the help")
        }
    }
}
