import Foundation
import Testing

@Suite("swift-mtl generate - template path, parameters and existing files")
struct GenerateOptionsTests {
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

    // MARK: - Template path

    @Test("finds imported modules in the template path directories")
    @MainActor
    func templatePathImports() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let main = scratch.appendingPathComponent("main/Main.mtl")
        let library = scratch.appendingPathComponent("library")
        let output = scratch.appendingPathComponent("out")
        try write(
            """
            [module Main('http://example.com')]
            [import Greetings/]
            [template public main()]
            [file ('greeting.txt')][greeting('Template')/][/file]
            [/template]
            """, to: main)
        try write(
            """
            [module Greetings('http://example.com')]
            [template public greeting(name : String)]Hello, [name/] from the library![/template]
            """, to: library.appendingPathComponent("Greetings.mtl"))

        let without = try await executeSwiftMTL(
            command: "generate", arguments: [main.path, "--output", output.path])
        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [main.path, "--template-path", library.path, "--output", output.path])

        #expect(!without.succeeded, "the import cannot be found without the template path")
        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(
            try text(of: output.appendingPathComponent("greeting.txt")) == "Hello, Template from the library!")
    }

    @Test("searches several template paths in order")
    @MainActor
    func severalTemplatePaths() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let main = scratch.appendingPathComponent("Main.mtl")
        let output = scratch.appendingPathComponent("out")
        try write(
            """
            [module Main('http://example.com')]
            [import First/]
            [import Second/]
            [template public main()]
            [file ('both.txt')][first()/] and [second()/][/file]
            [/template]
            """, to: main)
        try write(
            "[module First('http://example.com')]\n[template public first()]one[/template]",
            to: scratch.appendingPathComponent("a/First.mtl"))
        try write(
            "[module Second('http://example.com')]\n[template public second()]two[/template]",
            to: scratch.appendingPathComponent("b/Second.mtl"))

        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                main.path, "--template-path", scratch.appendingPathComponent("a").path, "--template-path",
                scratch.appendingPathComponent("b").path, "--output", output.path,
            ])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(try text(of: output.appendingPathComponent("both.txt")) == "one and two")
    }

    @Test("rejects a template path that is not a directory")
    @MainActor
    func badTemplatePath() async throws {
        let templateURL = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }

        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                templateURL.path, "--template-path", scratch.appendingPathComponent("missing").path,
                "--output", scratch.path,
            ])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("is not a directory"))
    }

    // MARK: - Parameters

    @Test("gives templates the parameters through parameter() and hasParameter()")
    @MainActor
    func parameters() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let main = scratch.appendingPathComponent("Main.mtl")
        let output = scratch.appendingPathComponent("out")
        try write(
            """
            [module Main('http://example.com')]
            [template public main()]
            [file ('params.txt')]package=[parameter('package')/]
            count=[parameter('count') + 1/]
            equation=[parameter('equation')/]
            [if (parameter('verbose'))]verbose[else]quiet[/if]
            [if (hasParameter('package'))]has package[/if]
            [if (hasParameter('absent'))]has absent[else]no absent[/if]
            [/file]
            [/template]
            """, to: main)

        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                main.path, "--output", output.path, "--param", "package=org.example", "--param", "count=41",
                "--param", "verbose=true", "--param", "equation=a=b",
            ])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let generated = try text(of: output.appendingPathComponent("params.txt"))
        #expect(generated.contains("package=org.example"))
        #expect(generated.contains("count=42"))
        #expect(generated.contains("equation=a=b"))
        #expect(generated.contains("verbose"))
        #expect(!generated.contains("quiet"))
        #expect(generated.contains("has package"))
        #expect(generated.contains("no absent"))
    }

    @Test("lets a later parameter replace an earlier one of the same name")
    @MainActor
    func laterParameterWins() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let main = scratch.appendingPathComponent("Main.mtl")
        let output = scratch.appendingPathComponent("out")
        try write(
            """
            [module Main('http://example.com')]
            [template public main()]
            [file ('p.txt')][parameter('name')/][/file]
            [/template]
            """, to: main)

        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [main.path, "--output", output.path, "--param", "name=first", "--param", "name=second"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(try text(of: output.appendingPathComponent("p.txt")) == "second")
    }

    @Test("rejects parameters that are not name=value")
    @MainActor
    func badParameters() async throws {
        let templateURL = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }

        for argument in ["novalue", "=value"] {
            let result = try await executeSwiftMTL(
                command: "generate",
                arguments: [templateURL.path, "--output", scratch.path, "--param", argument])

            #expect(!result.succeeded, "'\(argument)' is not a parameter")
            #expect(result.stderr.contains("expected name=value"))
        }
    }

    // MARK: - Existing files

    /// Writes a template with one file and returns its location with the output directory.
    private func fileTemplate(_ scratch: URL, content: String) throws -> (main: URL, output: URL) {
        let main = scratch.appendingPathComponent("Main.mtl")
        try write(
            """
            [module Main('http://example.com')]
            [template public main()]
            [file ('notes/result.txt')]\(content)[/file]
            [/template]
            """, to: main)
        return (main, scratch.appendingPathComponent("out"))
    }

    @Test("replaces existing files by default and with --force-overwrite")
    @MainActor
    func overwrite() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let (main, output) = try fileTemplate(scratch, content: "generated")
        let file = output.appendingPathComponent("notes/result.txt")
        try write("edited", to: file)

        let plain = try await executeSwiftMTL(command: "generate", arguments: [main.path, "-o", output.path])
        #expect(plain.succeeded, "\(plain.stdout)\(plain.stderr)")
        #expect(try text(of: file) == "generated")

        try write("edited again", to: file)
        let forced = try await executeSwiftMTL(
            command: "generate", arguments: [main.path, "-o", output.path, "--force-overwrite"])
        #expect(forced.succeeded, "\(forced.stdout)\(forced.stderr)")
        #expect(try text(of: file) == "generated")
    }

    @Test("writes beside existing files with --diff and leaves them alone")
    @MainActor
    func diff() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let (main, output) = try fileTemplate(scratch, content: "generated")
        let file = output.appendingPathComponent("notes/result.txt")
        try write("edited", to: file)

        let result = try await executeSwiftMTL(
            command: "generate", arguments: [main.path, "-o", output.path, "--diff"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(try text(of: file) == "edited")
        #expect(try text(of: output.appendingPathComponent("notes/.result.txt.new")) == "generated")
    }

    @Test("writes a new file normally with --diff")
    @MainActor
    func diffWithoutExistingFile() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let (main, output) = try fileTemplate(scratch, content: "generated")

        let result = try await executeSwiftMTL(
            command: "generate", arguments: [main.path, "-o", output.path, "--diff"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(try text(of: output.appendingPathComponent("notes/result.txt")) == "generated")
    }

    @Test("lets --force-overwrite take precedence over --diff")
    @MainActor
    func forceBeatsDiff() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let (main, output) = try fileTemplate(scratch, content: "generated")
        let file = output.appendingPathComponent("notes/result.txt")
        try write("edited", to: file)

        let result = try await executeSwiftMTL(
            command: "generate", arguments: [main.path, "-o", output.path, "--diff", "--force-overwrite"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(try text(of: file) == "generated")
        #expect(!FileManager.default.fileExists(atPath: output.appendingPathComponent("notes/.result.txt.new").path))
    }

    @Test("lists the new options in the help")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftMTL(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        for option in ["--template-path", "--param", "--force-overwrite", "--diff"] {
            #expect(result.stdout.contains(option), "\(option) is missing from the help")
        }
    }
}
