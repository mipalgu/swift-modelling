import Foundation
import Testing

@testable import ModellingGenerators

@Suite("Template overrides and new languages")
struct TemplateOverrideTests {
    @MainActor
    static func library() async throws -> GeneratedProject {
        try await GeneratedProject.make(
            "library", stem: "library", options: GenModelImportOptions(basePackage: "org.example"))
    }

    @Test("A template path overrides a single bundled module")
    @MainActor
    func overridesModule() async throws {
        let generated = try await Self.library()
        let scratch = try ScratchDirectory()
        defer {
            generated.remove()
            scratch.remove()
        }
        try scratch.write(
            """
            [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
            [template public header(element : OclAny)]/** Custom header */[/template]
            """, to: "Header.mtl")
        try await generated.generate(options: GenerationOptions(templatePaths: [scratch.url]))

        let customised = try generated.text("org/example/library/BookCategory.java")
        let expected = try String(
            contentsOf: generated.project.javaExpectation("org/example/library/BookCategory.java"),
            encoding: .utf8)
        let header = "/**\n * Copyright 2026 Example Pty Ltd\n */"
        #expect(customised.hasPrefix("/** Custom header */\npackage "))
        #expect(expected.hasPrefix(header))
        #expect(customised.dropFirst("/** Custom header */".count) == expected.dropFirst(header.count))
    }

    @Test("A language directory in a template path adds a language without code changes")
    @MainActor
    func newLanguage() async throws {
        let generated = try await Self.library()
        let scratch = try ScratchDirectory()
        defer {
            generated.remove()
            scratch.remove()
        }
        try scratch.write(
            #"""
            {"name": "outline", "summary": "A class list", "mainModule": "main", "mainTemplate": "main",
             "options": {"lineDelimiter": "\n"}}
            """#, to: "outline/templateset.json")
        try scratch.write(
            """
            [module main('http://www.eclipse.org/emf/2002/GenModel')/]
            [template public main(genModel : GenModel)]
            [file ('outline.txt')]
            [for (c : GenClass | genModel.allGenPackages().genClasses)]
            [c.name()/]: [c.allGenFeatures()->collect(f | f.name())->join(', ')/]
            [/for]
            [/file]
            [/template]
            """, to: "outline/main.mtl")
        let result = try await generated.generate(
            language: "outline", options: GenerationOptions(templatePaths: [scratch.url]))
        #expect(result.language == "outline")
        let text = try generated.text("outline.txt")
        #expect(text.contains("Book: name, loanDays, onLoan, pages, category, isbn, author, library\n"))
        #expect(text.contains("Writer: name, aliases, books\n"))
    }

    @Test("A missing generator model is reported")
    @MainActor
    func missingGenModel() async throws {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("absent.genmodel")
        await #expect(throws: GenerationError.sourceModelNotFound(missing.standardizedFileURL.path)) {
            try await GenerationPipeline.generate(
                genModelURL: missing, language: "java", outputDirectory: missing)
        }
    }

    @Test("A document that is not a generator model is reported")
    @MainActor
    func notAGenModel() async throws {
        let generated = try await Self.library()
        defer { generated.remove() }
        let ecore = generated.project.model("library.ecore")
        await #expect(throws: GenerationError.self) {
            try await GenerationPipeline.generate(
                genModelURL: ecore, language: "java", outputDirectory: generated.output)
        }
    }

    @Test("An unknown language is reported before any file is written")
    @MainActor
    func unknownLanguage() async throws {
        let generated = try await Self.library()
        defer { generated.remove() }
        await #expect(throws: GenerationError.self) {
            try await generated.generate(language: "cobol")
        }
        #expect(!FileManager.default.fileExists(atPath: generated.output.path))
    }

    @Test("Templates that cannot be parsed are reported as an invalid set")
    @MainActor
    func brokenTemplate() async throws {
        let generated = try await Self.library()
        let scratch = try ScratchDirectory()
        defer {
            generated.remove()
            scratch.remove()
        }
        try scratch.write("[template broken(", to: "EnumClass.mtl")
        do {
            try await generated.generate(options: GenerationOptions(templatePaths: [scratch.url]))
            Issue.record("generation should have failed")
        } catch let error as GenerationError {
            guard case .templateSetInvalid("java", _) = error else {
                Issue.record("unexpected error \(error)")
                return
            }
        }
    }

    @Test("Templates that fail while running are reported")
    @MainActor
    func failingTemplate() async throws {
        let generated = try await Self.library()
        defer { generated.remove() }
        let harness = TemplateHarness(generated: generated)
        do {
            _ = try await harness.run("[genModel.noSuchService()/]")
            Issue.record("generation should have failed")
        } catch let error as GenerationError {
            guard case .generationFailed = error else {
                Issue.record("unexpected error \(error)")
                return
            }
        }
    }

    @Test("A set may omit the file count and still generate")
    @MainActor
    func withoutFileCount() async throws {
        let generated = try await Self.library()
        let scratch = try ScratchDirectory()
        defer {
            generated.remove()
            scratch.remove()
        }
        try scratch.write(
            #"{"name": "plain", "mainModule": "main", "mainTemplate": "main"}"#, to: "plain/templateset.json")
        try scratch.write(
            """
            [module main('http://www.eclipse.org/emf/2002/GenModel')/]
            [template public main(genModel : GenModel)]
            [file ('one.txt')]one[/file]
            [/template]
            """, to: "plain/main.mtl")
        let collector = ProgressCollector()
        try await generated.generate(
            language: "plain", options: GenerationOptions(templatePaths: [scratch.url]),
            progress: { collector.add($0) })
        #expect(try generated.text("one.txt") == "one")
        #expect(collector.updates.filter { $0.message.hasPrefix("Generated") }.allSatisfy { $0.total == nil })
    }

    @Test("A file count template that is missing is reported")
    @MainActor
    func missingFileCountTemplate() async throws {
        let generated = try await Self.library()
        let scratch = try ScratchDirectory()
        defer {
            generated.remove()
            scratch.remove()
        }
        try scratch.write(
            #"{"name": "counted", "mainModule": "main", "mainTemplate": "main", "fileCountTemplate": "nope"}"#,
            to: "counted/templateset.json")
        try scratch.write(
            "[module main('http://www.eclipse.org/emf/2002/GenModel')/][template public main(genModel : GenModel)]x[/template]",
            to: "counted/main.mtl")
        await #expect(throws: GenerationError.templateSetInvalid("counted", "the file count template 'nope' is missing")) {
            try await generated.generate(language: "counted", options: GenerationOptions(templatePaths: [scratch.url]))
        }
    }

    @Test("Line delimiters from the options are written")
    @MainActor
    func lineDelimiters() async throws {
        let generated = try await Self.library()
        defer { generated.remove() }
        try await generated.generate(options: GenerationOptions(lineDelimiter: "\r\n"))
        let text = try generated.text("org/example/library/BookCategory.java")
        #expect(text.contains("\r\n"))
        #expect(!text.replacingOccurrences(of: "\r\n", with: "").contains("\n"))
    }
}
