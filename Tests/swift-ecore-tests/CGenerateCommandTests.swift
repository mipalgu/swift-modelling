import Foundation
import Testing

@Suite("swift-ecore generate - C from generator models and Ecore models")
struct CGenerateCommandTests {
    /// The fixtures shared with the generator library tests.
    private static let fixtureRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ModellingGeneratorsTests/Resources")

    /// The files that generating the library fixture must write, relative to the output directory.
    private static let expectedLibraryFiles = ["EObject.h", "library/library.c", "library/library.h"]

    /// The reviewed expectation of a file of the library fixture.
    private func expected(_ path: String) throws -> String {
        try String(
            contentsOf: Self.fixtureRoot.appendingPathComponent("library/expected-c/\(path)"),
            encoding: .utf8)
    }

    /// Copies the library fixture into a scratch directory and writes its generator model.
    ///
    /// - Returns: The scratch directory, the Ecore model and the generator model.
    @MainActor
    private func libraryProject() async throws -> (scratch: URL, ecore: URL, genModel: URL) {
        let scratch = try createTemporaryDirectory()
        let project = scratch.appendingPathComponent("library")
        try FileManager.default.copyItem(at: Self.fixtureRoot.appendingPathComponent("library"), to: project)
        for expectation in [
            "expected", "expected-java", "expected-swift", "swift-check", "expected-c", "c-check", "expected-cpp", "cpp-check",
        ] {
            try? FileManager.default.removeItem(at: project.appendingPathComponent(expectation))
        }
        let ecore = project.appendingPathComponent("model/library.ecore")
        let created = try await executeSwiftEcore(
            command: "genmodel",
            arguments: [ecore.path, "--base-package", "org.example", "--copyright", "Copyright 2026 Example Pty Ltd"])
        #expect(created.succeeded, "\(created.stderr)")
        return (scratch, ecore, project.appendingPathComponent("model/library.genmodel"))
    }

    @Test("generates C from a generator model that matches the reviewed expectation")
    @MainActor
    func generatesFromGenModel() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("c")

        let result = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "c", genModel.path, "-o", output.path])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(result.stdout.range(of: #"Generated [0-9]+ files in:"#, options: .regularExpression) != nil)
        for path in Self.expectedLibraryFiles {
            #expect(
                FileManager.default.fileExists(atPath: output.appendingPathComponent(path).path),
                "\(path) was not generated")
            #expect(
                try String(contentsOf: output.appendingPathComponent(path), encoding: .utf8) == (try expected(path)),
                "\(path) differs from the expectation")
        }
    }

    @Test("imports an Ecore model on the way")
    @MainActor
    func generatesFromEcore() async throws {
        let (scratch, ecore, _) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("named")

        let result = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "c", ecore.path, "-o", output.path])

        #expect(result.succeeded, "\(result.stderr)")
        for path in Self.expectedLibraryFiles {
            #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent(path).path), "\(path) was not generated")
        }
    }

    @Test("writes below the model directory on request")
    @MainActor
    func modelDirectoryLayout() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("c")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "c", genModel.path, "-o", output.path, "--model-directory"])

        #expect(result.succeeded)
        #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent("library/src/library/library.h").path))
        #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent("library/src/EObject.h").path))
    }

    @Test("keeps hand edits unless the overwrite is forced, and writes beside existing files with the diff option")
    @MainActor
    func mergeForceAndDiff() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("c")
        let file = output.appendingPathComponent("library/library.c")
        let arguments = ["--language", "c", genModel.path, "-o", output.path]
        _ = try await executeSwiftEcore(command: "generate", arguments: arguments)

        var edited = try String(contentsOf: file, encoding: .utf8)
        edited += "\nint answer(void) {\n    return 42;\n}\n"
        try edited.write(to: file, atomically: true, encoding: .utf8)

        let merged = try await executeSwiftEcore(command: "generate", arguments: arguments)
        #expect(merged.succeeded)
        #expect(try String(contentsOf: file, encoding: .utf8) == edited)

        let diffed = try await executeSwiftEcore(command: "generate", arguments: arguments + ["--diff"])
        #expect(diffed.succeeded)
        #expect(try String(contentsOf: file, encoding: .utf8) == edited)
        let redirected = output.appendingPathComponent("library/.library.c.new")
        #expect(try String(contentsOf: redirected, encoding: .utf8) == (try expected("library/library.c")))

        let forced = try await executeSwiftEcore(command: "generate", arguments: arguments + ["--force-overwrite"])
        #expect(forced.succeeded)
        #expect(try String(contentsOf: file, encoding: .utf8) == (try expected("library/library.c")))
    }

    @Test("applies the templates of a template path")
    @MainActor
    func templatePath() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("c")
        let templates = scratch.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templates, withIntermediateDirectories: true)
        try """
        [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
        [template public header(element : OclAny, fileName : String)]// Customised[/template]
        """.write(to: templates.appendingPathComponent("Header.mtl"), atomically: true, encoding: .utf8)

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                "--language", "c", genModel.path, "-o", output.path, "--template-path", templates.path,
            ])

        #expect(result.succeeded, "\(result.stderr)")
        let text = try String(contentsOf: output.appendingPathComponent("library/library.h"), encoding: .utf8)
        #expect(text.hasPrefix("// Customised\n\n#ifndef LIBRARY_LIBRARY_H\n"))
    }

    @Test("shows a progress bar with counts in verbose mode")
    @MainActor
    func verboseProgress() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("c")

        let result = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "c", genModel.path, "-o", output.path, "--verbose"])

        #expect(result.succeeded)
        #expect(result.stdout.range(of: #"\[={24}\] ([0-9]+)/\1 Generated "#, options: .regularExpression) != nil)
        #expect(result.stdout.contains("Assembling the c templates"))
    }

    @Test("generates the names of the C and C++ keywords with a trailing underscore from an Ecore model")
    @MainActor
    func keywordNames() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("c")
        let ecore = Self.fixtureRoot.appendingPathComponent("cnames/model/cnames.ecore")

        let result = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "c", ecore.path, "-o", output.path])

        #expect(result.succeeded, "\(result.stderr)")
        let header = try String(
            contentsOf: output.appendingPathComponent("cnames/cnames.h"), encoding: .utf8)
        #expect(header.contains("typedef struct static_ static_;\n"))
        #expect(header.contains("    int32_t int_;\n"))
        #expect(header.contains("    char *NULL_;\n"))
        #expect(header.contains("    Mode_default = 1,\n"))
        #expect(
            FileManager.default.fileExists(atPath: output.appendingPathComponent("cnames/delete/delete.h").path))
    }

    @Test("a language without a template set is reported with the languages that exist, also for a generator model")
    @MainActor
    func languageWithoutTemplateSetWithGenModel() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }

        for language in ["llvm", "cobol"] {
            let result = try await executeSwiftEcore(
                command: "generate",
                arguments: ["--language", language, genModel.path, "-o", scratch.appendingPathComponent("x").path])

            #expect(!result.succeeded)
            #expect(result.stderr.contains("Unsupported language: \(language)"))
            #expect(result.stderr.contains("c, cpp, java, swift"))
        }
    }

    @Test("the generator model defaults apply to C like to any template language")
    @MainActor
    func defaultsApplyToC() async throws {
        let (scratch, ecore, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }

        let fromEcore = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                "--language", "c", ecore.path, "--defaults", "wizard", "-o",
                scratch.appendingPathComponent("a").path,
            ])
        let fromGenModel = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                "--language", "c", genModel.path, "--defaults", "wizard", "-o",
                scratch.appendingPathComponent("b").path,
            ])

        #expect(fromEcore.succeeded, "\(fromEcore.stderr)")
        #expect(!fromGenModel.succeeded)
        #expect(fromGenModel.stderr.contains("only apply to an Ecore model"))
    }

    @Test("C offers no code styles, and says which languages do")
    @MainActor
    func noCodeStyles() async throws {
        let (scratch, ecore, _) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("c")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "c", ecore.path, "-o", output.path, "--code-style", "emf"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("emf"))
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test("lists C among the template languages")
    @MainActor
    func helpListsLanguages() async throws {
        let result = try await executeSwiftEcore(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("Languages with a template set: c, cpp, java, swift"))
    }
}

@Suite("swift-ecore - from Ecore to C through the command line")
struct CChainTests {
    /// The directory that holds the C files that generating the library fixture must produce.
    private static let expectedC = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ModellingGeneratorsTests/Resources/library/expected-c")

    @Test("genmodel then generate produces exactly the golden files")
    @MainActor
    func genModelThenGenerate() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let source = Self.expectedC.deletingLastPathComponent().appendingPathComponent("model/library.ecore")
        let project = scratch.appendingPathComponent("library/model")
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        let ecore = project.appendingPathComponent("library.ecore")
        try FileManager.default.copyItem(at: source, to: ecore)
        let output = scratch.appendingPathComponent("c")

        let created = try await executeSwiftEcore(
            command: "genmodel",
            arguments: [ecore.path, "--base-package", "org.example", "--copyright", "Copyright 2026 Example Pty Ltd"])
        #expect(created.succeeded, "\(created.stderr)")
        let genModel = ecore.deletingPathExtension().appendingPathExtension("genmodel")
        let generated = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "c", genModel.path, "-o", output.path])
        #expect(generated.succeeded, "\(generated.stderr)")

        let expected = JavaChainTests.files(below: Self.expectedC)
        #expect(!expected.isEmpty)
        #expect(JavaChainTests.files(below: output) == expected)
        for path in expected {
            let actual = try? String(contentsOf: output.appendingPathComponent(path), encoding: .utf8)
            let golden = try String(contentsOf: Self.expectedC.appendingPathComponent(path), encoding: .utf8)
            #expect(actual == golden, "\(path) differs from the golden file")
        }
    }
}
