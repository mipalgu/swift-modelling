import Foundation
import Testing

@Suite("swift-ecore generate - C++ from generator models and Ecore models")
struct CppGenerateCommandTests {
    /// The fixtures shared with the generator library tests.
    private static let fixtureRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ModellingGeneratorsTests/Resources")

    /// The files that generating the library fixture must write, relative to the output directory.
    private static let expectedLibraryFiles = [
        "EObject.hpp", "library/Book.hpp", "library/BookCategory.hpp", "library/ISBN.hpp", "library/Lendable.hpp",
        "library/Library.hpp", "library/LibraryFactory.hpp", "library/LibraryPackage.hpp", "library/Named.hpp",
        "library/Writer.hpp",
    ]

    /// The reviewed expectation of a file of the library fixture.
    private func expected(_ path: String) throws -> String {
        try String(
            contentsOf: Self.fixtureRoot.appendingPathComponent("library/expected-cpp/\(path)"),
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

    @Test("generates C++ from a generator model that matches the reviewed expectation")
    @MainActor
    func generatesFromGenModel() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("cpp")

        let result = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "cpp", genModel.path, "-o", output.path])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(result.stdout.range(of: #"Generated [0-9]+ files in:"#, options: .regularExpression) != nil)
        #expect(JavaChainTests.files(below: output) == Self.expectedLibraryFiles)
        for path in Self.expectedLibraryFiles {
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
            command: "generate", arguments: ["--language", "cpp", ecore.path, "-o", output.path])

        #expect(result.succeeded, "\(result.stderr)")
        for path in ["EObject.hpp", "library/Book.hpp", "library/LibraryPackage.hpp", "library/LibraryFactory.hpp"] {
            #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent(path).path), "\(path) is missing")
        }
    }

    @Test("writes below the model directory on request")
    @MainActor
    func modelDirectoryLayout() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("cpp")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "cpp", genModel.path, "-o", output.path, "--model-directory"])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent("library/src/library/Book.hpp").path))
        #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent("library/src/EObject.hpp").path))
    }

    @Test("keeps hand edits unless the overwrite is forced, and writes beside existing files with the diff option")
    @MainActor
    func mergeForceAndDiff() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("cpp")
        let file = output.appendingPathComponent("library/BookCategory.hpp")
        let arguments = ["--language", "cpp", genModel.path, "-o", output.path]
        _ = try await executeSwiftEcore(command: "generate", arguments: arguments)

        var edited = try String(contentsOf: file, encoding: .utf8)
        let closing = try #require(edited.range(of: "}", options: .backwards))
        edited.replaceSubrange(closing, with: "\ninline int answer() { return 42; }\n\n}")
        try edited.write(to: file, atomically: true, encoding: .utf8)

        let merged = try await executeSwiftEcore(command: "generate", arguments: arguments)
        #expect(merged.succeeded)
        #expect(try String(contentsOf: file, encoding: .utf8).contains("inline int answer() { return 42; }"))

        let diffed = try await executeSwiftEcore(command: "generate", arguments: arguments + ["--diff"])
        #expect(diffed.succeeded)
        #expect(try String(contentsOf: file, encoding: .utf8).contains("inline int answer() { return 42; }"))
        let redirected = output.appendingPathComponent("library/.BookCategory.hpp.new")
        #expect(try String(contentsOf: redirected, encoding: .utf8) == (try expected("library/BookCategory.hpp")))

        let forced = try await executeSwiftEcore(command: "generate", arguments: arguments + ["--force-overwrite"])
        #expect(forced.succeeded)
        #expect(try String(contentsOf: file, encoding: .utf8) == (try expected("library/BookCategory.hpp")))
    }

    @Test("applies the templates of a template path")
    @MainActor
    func templatePath() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("cpp")
        let templates = scratch.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templates, withIntermediateDirectories: true)
        try """
        [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
        [template public header(element : OclAny, fileName : String)]// Customised[/template]
        """.write(to: templates.appendingPathComponent("Header.mtl"), atomically: true, encoding: .utf8)

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                "--language", "cpp", genModel.path, "-o", output.path, "--template-path", templates.path,
            ])

        #expect(result.succeeded, "\(result.stderr)")
        let text = try String(contentsOf: output.appendingPathComponent("library/BookCategory.hpp"), encoding: .utf8)
        #expect(text.hasPrefix("#pragma once\n\n// Customised\n\n#include <cstdint>\n"))
    }

    @Test("shows a progress bar with counts in verbose mode")
    @MainActor
    func verboseProgress() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("cpp")

        let result = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "cpp", genModel.path, "-o", output.path, "--verbose"])

        #expect(result.succeeded)
        #expect(result.stdout.range(of: #"\[={24}\] ([0-9]+)/\1 Generated "#, options: .regularExpression) != nil)
        #expect(result.stdout.contains("Assembling the cpp templates"))
    }

    @Test("generates the names that C++ reserves with a trailing underscore from an Ecore model")
    @MainActor
    func reservedNames() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("cpp")
        let ecore = Self.fixtureRoot.appendingPathComponent("cnames/model/cnames.ecore")

        let result = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "cpp", ecore.path, "-o", output.path])

        #expect(result.succeeded, "\(result.stderr)")
        let keyword = try String(
            contentsOf: output.appendingPathComponent("cnames/static_.hpp"), encoding: .utf8)
        #expect(keyword.contains("class static_ final : public virtual EObject {"))
        let mode = try String(contentsOf: output.appendingPathComponent("cnames/Mode.hpp"), encoding: .utf8)
        #expect(mode.contains("    default_ = 1,\n"))
        #expect(mode.contains("    NULL_ = 3,\n"))
        let wheel = try String(
            contentsOf: output.appendingPathComponent("cnames/delete/Wheel.hpp"), encoding: .utf8)
        #expect(wheel.contains("\nnamespace cnames::delete_ {\n"))
    }

    @Test("the generator model defaults apply to C++ like to any template language")
    @MainActor
    func defaultsApplyToCpp() async throws {
        let (scratch, ecore, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }

        let fromEcore = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                "--language", "cpp", ecore.path, "--defaults", "wizard", "-o",
                scratch.appendingPathComponent("a").path,
            ])
        let fromGenModel = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                "--language", "cpp", genModel.path, "--defaults", "wizard", "-o",
                scratch.appendingPathComponent("b").path,
            ])

        #expect(fromEcore.succeeded, "\(fromEcore.stderr)")
        #expect(!fromGenModel.succeeded)
        #expect(fromGenModel.stderr.contains("only apply to an Ecore model"))
    }

    @Test("C++ offers no code styles")
    @MainActor
    func noCodeStyles() async throws {
        let (scratch, ecore, _) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("cpp")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "cpp", ecore.path, "-o", output.path, "--code-style", "emf"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("emf"))
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test("lists C++ as a template language")
    @MainActor
    func helpListsLanguages() async throws {
        let result = try await executeSwiftEcore(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        let line = try #require(
            result.stdout.components(separatedBy: "\n").first { $0.hasPrefix("Languages with a template set:") })
        #expect(line.contains("cpp"))
    }
}

@Suite("swift-ecore - from Ecore to C++ through the command line")
struct CppChainTests {
    /// The directory that holds the C++ files that generating the library fixture must produce.
    private static let expectedCpp = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ModellingGeneratorsTests/Resources/library/expected-cpp")

    @Test("genmodel then generate produces exactly the golden files")
    @MainActor
    func genModelThenGenerate() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let source = Self.expectedCpp.deletingLastPathComponent().appendingPathComponent("model/library.ecore")
        let project = scratch.appendingPathComponent("library/model")
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        let ecore = project.appendingPathComponent("library.ecore")
        try FileManager.default.copyItem(at: source, to: ecore)
        let output = scratch.appendingPathComponent("cpp")

        let created = try await executeSwiftEcore(
            command: "genmodel",
            arguments: [ecore.path, "--base-package", "org.example", "--copyright", "Copyright 2026 Example Pty Ltd"])
        #expect(created.succeeded, "\(created.stderr)")
        let genModel = ecore.deletingPathExtension().appendingPathExtension("genmodel")
        let generated = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "cpp", genModel.path, "-o", output.path])
        #expect(generated.succeeded, "\(generated.stderr)")

        let expected = JavaChainTests.files(below: Self.expectedCpp)
        #expect(!expected.isEmpty)
        #expect(JavaChainTests.files(below: output) == expected)
        for path in expected {
            let actual = try? String(contentsOf: output.appendingPathComponent(path), encoding: .utf8)
            let golden = try String(contentsOf: Self.expectedCpp.appendingPathComponent(path), encoding: .utf8)
            #expect(actual == golden, "\(path) differs from the golden file")
        }
    }
}
