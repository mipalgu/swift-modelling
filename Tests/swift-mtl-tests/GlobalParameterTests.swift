import Foundation
import Testing

@Suite("swift-mtl generate - parameters as global variables")
struct GlobalParameterTests {
    /// Writes a text file, creating its directory.
    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Runs a template with parameters and returns the content of the file it generates.
    @MainActor
    private func generate(_ body: String, parameters: [String]) async throws -> String {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let main = scratch.appendingPathComponent("Main.mtl")
        let output = scratch.appendingPathComponent("out")
        try write(
            """
            [module Main('http://example.com')]
            [query twice() : String = package + package/]
            [template public inner()]<[package/]>[/template]
            [template public main()]
            [file ('p.txt')]\(body)[/file]
            [/template]
            """, to: main)
        let arguments = [main.path, "--template", "main", "--output", output.path] + parameters.flatMap { ["--param", $0] }
        let result = try await executeSwiftMTL(command: "generate", arguments: arguments)
        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        return try String(contentsOf: output.appendingPathComponent("p.txt"), encoding: .utf8)
    }

    @Test("binds each parameter as a bare variable")
    @MainActor
    func bareVariables() async throws {
        let generated = try await generate(
            "[package/] [count + 1/] [if (verbose)]on[else]off[/if]",
            parameters: ["package=org.example", "count=41", "verbose=true"])
        #expect(generated == "org.example 42 on")
    }

    @Test("keeps the parameter services alongside the variables")
    @MainActor
    func servicesAndVariables() async throws {
        let generated = try await generate(
            "[parameter('package')/]=[package/] [hasParameter('package')/]",
            parameters: ["package=org.example"])
        #expect(generated == "org.example=org.example true")
    }

    @Test("makes the variables visible to queries and other templates")
    @MainActor
    func visibleEverywhere() async throws {
        let generated = try await generate(
            "[twice()/] [inner()/]", parameters: ["package=ab"])
        #expect(generated == "abab <ab>")
    }

    @Test("accepts underscores and digits in names")
    @MainActor
    func identifierNames() async throws {
        let generated = try await generate(
            "[_a1/][b_2/]", parameters: ["_a1=x", "b_2=y", "package=p"])
        #expect(generated == "xy")
    }

    @Test("rejects names that are not identifiers")
    @MainActor
    func rejectsBadNames() async throws {
        let templateURL = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }

        for argument in ["a.b=1", "my-param=1", "1abc=1", "a b=1"] {
            let result = try await executeSwiftMTL(
                command: "generate",
                arguments: [templateURL.path, "--output", scratch.path, "--param", argument])

            #expect(!result.succeeded, "'\(argument)' has an invalid name")
            #expect(result.stderr.contains("not a valid identifier"), "\(result.stderr)")
        }
    }

    @Test("rejects names that are AQL or MTL keywords")
    @MainActor
    func rejectsKeywords() async throws {
        let templateURL = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }

        for name in ["template", "if", "let", "self", "endif", "Sequence", "null"] {
            let result = try await executeSwiftMTL(
                command: "generate",
                arguments: [templateURL.path, "--output", scratch.path, "--param", "\(name)=1"])

            #expect(!result.succeeded, "'\(name)' is a keyword")
            #expect(result.stderr.contains("reserved keyword"), "\(result.stderr)")
            #expect(result.stderr.contains(name))
        }
    }

    @Test("documents the bare variables in the help")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftMTL(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("[name/]"))
    }
}
