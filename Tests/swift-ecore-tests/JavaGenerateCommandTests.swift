import Foundation
import Testing

@Suite("swift-ecore generate - Java from generator models")
struct JavaGenerateCommandTests {
    /// The fixtures shared with the generator library tests.
    private static let fixtureRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ModellingGeneratorsTests/Resources")

    /// The generated enumeration of the library fixture, relative to the output directory.
    private static let bookCategory = "org/example/library/BookCategory.java"

    /// Copies the library fixture into a scratch directory and writes its generator model.
    ///
    /// - Returns: The scratch directory, the project directory and the generator model.
    @MainActor
    private func libraryProject() async throws -> (scratch: URL, project: URL, genModel: URL) {
        let scratch = try createTemporaryDirectory()
        let project = scratch.appendingPathComponent("library")
        try FileManager.default.copyItem(
            at: Self.fixtureRoot.appendingPathComponent("library"), to: project)
        for expectation in ["expected", "expected-java"] {
            try? FileManager.default.removeItem(at: project.appendingPathComponent(expectation))
        }
        let created = try await executeSwiftEcore(
            command: "genmodel",
            arguments: [
                project.appendingPathComponent("model/library.ecore").path, "--base-package", "org.example",
                "--copyright", "Copyright 2026 Example Pty Ltd",
            ])
        #expect(created.succeeded)
        return (scratch, project, project.appendingPathComponent("model/library.genmodel"))
    }

    private func expectedBookCategory() throws -> String {
        try String(
            contentsOf: Self.fixtureRoot.appendingPathComponent(
                "library/expected-java/\(Self.bookCategory)"),
            encoding: .utf8)
    }

    @Test("generates Java that matches the reviewed expectation")
    @MainActor
    func generatesJava() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")

        let result = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "java", genModel.path, "-o", output.path])

        #expect(result.succeeded)
        #expect(result.stdout.contains("Generated 3 files in:"))
        #expect(
            try String(contentsOf: output.appendingPathComponent(Self.bookCategory), encoding: .utf8)
                == expectedBookCategory())
    }

    @Test("imports an Ecore model on the way")
    @MainActor
    func generatesFromEcore() async throws {
        let (scratch, project, _) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                "--language", "java", project.appendingPathComponent("model/library.ecore").path, "-o",
                output.path,
            ])

        #expect(result.succeeded)
        #expect(
            FileManager.default.fileExists(
                atPath: output.appendingPathComponent("library/BookCategory.java").path))
    }

    @Test("writes below the model directory on request")
    @MainActor
    func modelDirectoryLayout() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "java", genModel.path, "-o", output.path, "--model-directory"])

        #expect(result.succeeded)
        #expect(
            FileManager.default.fileExists(
                atPath: output.appendingPathComponent("library/src/\(Self.bookCategory)").path))
    }

    @Test("keeps hand edits unless the overwrite is forced")
    @MainActor
    func mergeAndForce() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")
        let file = output.appendingPathComponent(Self.bookCategory)
        _ = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "java", genModel.path, "-o", output.path])

        var edited = try String(contentsOf: file, encoding: .utf8)
        let closing = try #require(edited.range(of: "}", options: .backwards))
        edited.replaceSubrange(closing, with: "\n  public int answer()\n  {\n    return 42;\n  }\n}")
        try edited.write(to: file, atomically: true, encoding: .utf8)

        let merged = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "java", genModel.path, "-o", output.path])
        #expect(merged.succeeded)
        #expect(try String(contentsOf: file, encoding: .utf8).contains("public int answer()"))

        let forced = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "java", genModel.path, "-o", output.path, "--force-overwrite"])
        #expect(forced.succeeded)
        #expect(try String(contentsOf: file, encoding: .utf8) == expectedBookCategory())
    }

    @Test("writes beside existing files with the diff option")
    @MainActor
    func diffOption() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")
        let file = output.appendingPathComponent(Self.bookCategory)
        _ = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "java", genModel.path, "-o", output.path])
        let damaged = try String(contentsOf: file, encoding: .utf8)
            .replacingOccurrences(of: "return literal;", with: "return null;")
        try damaged.write(to: file, atomically: true, encoding: .utf8)

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "java", genModel.path, "-o", output.path, "--diff"])

        #expect(result.succeeded)
        #expect(try String(contentsOf: file, encoding: .utf8) == damaged)
        let redirected = output.appendingPathComponent("org/example/library/.BookCategory.java.new")
        #expect(try String(contentsOf: redirected, encoding: .utf8) == expectedBookCategory())
    }

    @Test("applies the templates of a template path")
    @MainActor
    func templatePath() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")
        let templates = scratch.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templates, withIntermediateDirectories: true)
        try """
        [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
        [template public header(element : OclAny)]/** Customised */[/template]
        """.write(to: templates.appendingPathComponent("Header.mtl"), atomically: true, encoding: .utf8)

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                "--language", "java", genModel.path, "-o", output.path, "--template-path", templates.path,
            ])

        #expect(result.succeeded)
        let text = try String(contentsOf: output.appendingPathComponent(Self.bookCategory), encoding: .utf8)
        #expect(text.hasPrefix("/** Customised */\npackage org.example.library;"))
    }

    @Test("shows a progress bar with counts in verbose mode")
    @MainActor
    func verboseProgress() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "java", genModel.path, "-o", output.path, "--verbose"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("[========================] 3/3 Generated "))
        #expect(result.stdout.contains("Assembling the java templates"))
    }

    @Test("reports an unknown language with the known ones")
    @MainActor
    func unknownLanguage() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "cobol", genModel.path, "-o", scratch.appendingPathComponent("x").path])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("cobol"))
        #expect(result.stderr.contains("java"))
    }

    @Test("asks for a generator model when a built-in language is given one")
    @MainActor
    func builtInLanguageWithGenModel() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "swift", genModel.path, "-o", scratch.appendingPathComponent("x").path])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("generator model"))
    }

    @Test("reports a template path that is not a directory")
    @MainActor
    func badTemplatePath() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let missing = scratch.appendingPathComponent("missing")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                "--language", "java", genModel.path, "-o", scratch.appendingPathComponent("x").path,
                "--template-path", missing.path,
            ])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("not a directory"))
    }
}
