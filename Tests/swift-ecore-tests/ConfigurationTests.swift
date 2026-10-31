//
// ConfigurationTests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for the environment variable, the configuration file and `--container-scope` of
/// `swift-ecore generate`.
@Suite("swift-ecore generate - environment and configuration file", .serialized)
struct ConfigurationTests {
    /// The name of the configuration file.
    static let configurationFile = ".swift-modelling.json"

    /// The fixtures shared with the generator library tests.
    static let fixtureRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ModellingGeneratorsTests/Resources")

    /// A header module whose output shows two behaviours that the presets choose differently.
    static let probe = """
        [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
        [template public header(element : OclAny, fileName : String)]
        // args=[Sequence{'a'}->append(Sequence{'b', 'c'})->flatten()->size()/]
        // kinds=[OrderedSet{'a'}->including('a')->size()/]
        [/template]
        """

    /// The start of a generated file with the behaviour of this release.
    static let standardHeader = "// args=3\n// kinds=1\n"

    /// The start of a generated file with the behaviour of version 0.6.
    static let legacyHeader = "// args=2\n// kinds=2\n"

    /// A repository with the library model, the header module and a nested working directory.
    struct Workspace {
        /// The root of the repository.
        let root: URL

        /// The directory the tool runs in, two levels below the root.
        var workingDirectory: URL { root.appendingPathComponent("work/nested") }

        /// The output directory.
        var output: URL { root.appendingPathComponent("swift") }

        /// Creates the repository.
        init() throws {
            root = try createTemporaryDirectory()
            try FileManager.default.createDirectory(
                at: root.appendingPathComponent(".git"), withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true)
            try FileManager.default.copyItem(
                at: ConfigurationTests.fixtureRoot.appendingPathComponent("library"),
                to: root.appendingPathComponent("library"))
            let templates = root.appendingPathComponent("templates")
            try FileManager.default.createDirectory(at: templates, withIntermediateDirectories: true)
            try ConfigurationTests.probe.write(
                to: templates.appendingPathComponent("Header.mtl"), atomically: true, encoding: .utf8)
        }

        /// Writes a file below the root.
        ///
        /// - Parameters:
        ///   - text: The contents of the file.
        ///   - path: The path of the file relative to the root.
        /// - Returns: The file.
        @discardableResult
        func write(_ text: String, to path: String = ConfigurationTests.configurationFile) throws -> URL {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        }

        /// Generates Swift from the library model from the working directory.
        ///
        /// - Parameters:
        ///   - extra: The arguments after the model, output directory and template path.
        ///   - environment: The environment variables to set.
        /// - Returns: The result of the command and the text of one generated file, if any.
        @MainActor
        func generate(_ extra: [String] = [], environment: [String: String?] = [:]) async throws
            -> (result: SubprocessResult, text: String?)
        {
            try? FileManager.default.removeItem(at: output)
            let result = try await executeSwiftEcore(
                command: "generate",
                arguments: [
                    "--language", "swift", root.appendingPathComponent("library/model/library.ecore").path,
                    "-o", output.path, "--template-path", root.appendingPathComponent("templates").path,
                ] + extra,
                workingDirectory: workingDirectory, environment: environment)
            let text = try? String(contentsOf: output.appendingPathComponent("library/Book.swift"), encoding: .utf8)
            return (result, text)
        }

        /// Removes the repository.
        func remove() {
            cleanupTemporaryDirectory(root)
        }
    }

    @Test("follows the semantics of the environment variable")
    @MainActor
    func environmentVariable() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let standard = try await workspace.generate()
        let legacy = try await workspace.generate(environment: [semanticsVariable: "legacy"])
        let overridden = try await workspace.generate(["--semantics", "standard"], environment: [semanticsVariable: "legacy"])

        for (run, header) in [(standard, Self.standardHeader), (legacy, Self.legacyHeader), (overridden, Self.standardHeader)] {
            #expect(run.result.succeeded, "\(run.result.stderr)")
            #expect(run.text?.hasPrefix(header) == true, "\(run.text ?? "no output")")
        }
    }

    @Test("rejects an invalid value of the environment variable, naming it and the accepted values")
    @MainActor
    func invalidEnvironmentVariable() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (result, text) = try await workspace.generate(environment: [semanticsVariable: "0.6"])

        #expect(!result.succeeded)
        #expect(text == nil)
        for expected in [semanticsVariable, "'0.6'", "standard", "legacy"] {
            #expect(result.stderr.contains(expected), "\(expected) is missing from: \(result.stderr)")
        }
    }

    @Test("reads the configuration file of a parent directory unless told not to")
    @MainActor
    func parentConfiguration() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "semantics": "legacy", "collection-kinds": "distinguished" }"#)

        let configured = try await workspace.generate()
        let ignored = try await workspace.generate(["--no-config"])
        let explicit = try await workspace.generate(
            ["--config", try workspace.write(#"{ "collection-arguments": "first-element" }"#, to: "custom.json").path])

        #expect(configured.result.succeeded, "\(configured.result.stderr)")
        #expect(configured.text?.hasPrefix("// args=2\n// kinds=1\n") == true, "\(configured.text ?? "no output")")
        #expect(ignored.text?.hasPrefix(Self.standardHeader) == true, "\(ignored.text ?? "no output")")
        #expect(explicit.text?.hasPrefix("// args=2\n// kinds=1\n") == true, "\(explicit.text ?? "no output")")
    }

    @Test("rejects an unknown key, naming the file and the key")
    @MainActor
    func unknownKey() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "semantics": "legacy", "colour": "blue" }"#)

        let (result, text) = try await workspace.generate()

        #expect(!result.succeeded)
        #expect(text == nil)
        #expect(result.stderr.contains(Self.configurationFile), "\(result.stderr)")
        #expect(result.stderr.contains("colour"), "\(result.stderr)")
    }

    @Test("documents --container-scope, --config, --no-config, the variable and the file in the help")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftEcore(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        for text in [
            "--container-scope <any-resource|this-resource>", "--config <file>", "--no-config", semanticsVariable,
            Self.configurationFile,
        ] {
            #expect(result.stdout.contains(text), "\(text) is missing from the help")
        }
    }

    @Test("accepts each container scope", arguments: ["any-resource", "this-resource"])
    @MainActor
    func containerScope(scope: String) async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (result, text) = try await workspace.generate(["--container-scope", scope])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(text?.hasPrefix(Self.standardHeader) == true, "\(text ?? "no output")")
    }
}
