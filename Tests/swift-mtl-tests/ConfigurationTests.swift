//
// ConfigurationTests.swift
// swift-mtl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for the environment variable, the configuration file and `--container-scope` of
/// `swift-mtl generate`.
@Suite("swift-mtl generate - environment and configuration file", .serialized)
struct ConfigurationTests {
    /// The name of the configuration file.
    static let configurationFile = ".swift-modelling.json"

    /// A module whose output shows two behaviours that the presets choose differently.
    static let probe = """
        [module Probe('http://www.eclipse.org/emf/2002/Ecore')]

        [template public main(p : ecore::EPackage)]
        [file ('result.txt', 'overwrite', 'UTF-8')]
        args=[Sequence{'a'}->append(Sequence{'b', 'c'})->flatten()->size()/]
        kinds=[OrderedSet{'a'}->including('a')->size()/]
        [/file]
        [/template]
        """

    /// An Ecore model with one class.
    static let model = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="lib"
            nsURI="http://www.example.org/lib" nsPrefix="lib">
          <eClassifiers xsi:type="ecore:EClass" name="Book"/>
        </ecore:EPackage>
        """

    /// The output of the probe with the behaviour of this release.
    static let standardOutput = "args=3\nkinds=1\n"

    /// The output of the probe with the behaviour of version 0.6.
    static let legacyOutput = "args=2\nkinds=2\n"

    /// A repository with a model, the probe and a nested working directory.
    struct Workspace {
        /// The root of the repository.
        let root: URL

        /// The directory the tool runs in, two levels below the root.
        var workingDirectory: URL { root.appendingPathComponent("work/nested") }

        /// The output directory.
        var output: URL { root.appendingPathComponent("out") }

        /// Creates the repository.
        init() throws {
            root = try createTemporaryDirectory()
            try FileManager.default.createDirectory(
                at: root.appendingPathComponent(".git"), withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true)
            try ConfigurationTests.model.write(
                to: root.appendingPathComponent("lib.ecore"), atomically: true, encoding: .utf8)
            try ConfigurationTests.probe.write(
                to: root.appendingPathComponent("Probe.mtl"), atomically: true, encoding: .utf8)
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

        /// Runs the probe from the working directory.
        ///
        /// - Parameters:
        ///   - extra: The arguments after the template, model and output directory.
        ///   - environment: The environment variables to set.
        /// - Returns: The result of the command and the generated text, if any.
        @MainActor
        func generate(_ extra: [String] = [], environment: [String: String?] = [:]) async throws
            -> (result: SubprocessResult, text: String?)
        {
            try? FileManager.default.removeItem(at: output)
            let result = try await executeSwiftMTL(
                command: "generate",
                arguments: [
                    root.appendingPathComponent("Probe.mtl").path, "--model",
                    root.appendingPathComponent("lib.ecore").path, "--output", output.path,
                ] + extra,
                workingDirectory: workingDirectory, environment: environment)
            let text = try? String(contentsOf: output.appendingPathComponent("result.txt"), encoding: .utf8)
            return (result, text)
        }

        /// Removes the repository.
        func remove() {
            cleanupTemporaryDirectory(root)
        }
    }

    // MARK: - Environment

    @Test("follows the semantics of the environment variable")
    @MainActor
    func environmentVariable() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        for (value, expected) in [
            (nil, Self.standardOutput), ("", Self.standardOutput), ("standard", Self.standardOutput),
            ("legacy", Self.legacyOutput),
        ] as [(String?, String)] {
            let (result, text) = try await workspace.generate(environment: [semanticsVariable: value])
            #expect(result.succeeded, "\(String(describing: value)): \(result.stderr)")
            #expect(text == expected, "\(String(describing: value))")
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

    @Test("lets --semantics override the environment variable")
    @MainActor
    func flagOverridesEnvironment() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let standard = try await workspace.generate(["--semantics", "standard"], environment: [semanticsVariable: "legacy"])
        let legacy = try await workspace.generate(["--semantics", "legacy"], environment: [semanticsVariable: "standard"])

        #expect(standard.text == Self.standardOutput, "\(standard.result.stderr)")
        #expect(legacy.text == Self.legacyOutput, "\(legacy.result.stderr)")
    }

    // MARK: - Configuration file

    @Test("reads the configuration file of a parent directory")
    @MainActor
    func parentConfiguration() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "semantics": "legacy" }"#)

        let (result, text) = try await workspace.generate()

        #expect(result.succeeded, "\(result.stderr)")
        #expect(text == Self.legacyOutput)
    }

    @Test("lets the environment variable override the semantics of the configuration file")
    @MainActor
    func environmentOverridesConfiguration() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "semantics": "legacy" }"#)

        let (result, text) = try await workspace.generate(environment: [semanticsVariable: "standard"])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(text == Self.standardOutput)
    }

    @Test("lets an option of the configuration file override --semantics and the environment variable")
    @MainActor
    func configurationOptionOverridesPresets() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "semantics": "legacy", "collection-arguments": "whole" }"#)

        let (result, text) = try await workspace.generate(
            ["--semantics", "legacy"], environment: [semanticsVariable: "legacy"])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(text == "args=3\nkinds=2\n")
    }

    @Test("lets an option on the command line override the configuration file")
    @MainActor
    func flagOverridesConfigurationOption() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "collection-arguments": "whole" }"#)

        let (result, text) = try await workspace.generate(
            ["--collection-arguments", "first-element"], environment: [semanticsVariable: "standard"])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(text == "args=2\nkinds=1\n")
    }

    @Test("ignores the configuration file with --no-config")
    @MainActor
    func noConfiguration() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "semantics": "legacy", "unknown": true }"#)

        let (result, text) = try await workspace.generate(["--no-config"])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(text == Self.standardOutput)
    }

    @Test("reads the file given with --config instead of the one it would find")
    @MainActor
    func explicitConfiguration() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "semantics": "standard" }"#)
        let file = try workspace.write(#"{ "semantics": "legacy" }"#, to: "settings/custom.json")

        let (result, text) = try await workspace.generate(["--config", file.path])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(text == Self.legacyOutput)
    }

    @Test("reports a file given with --config that does not exist, naming it")
    @MainActor
    func missingConfiguration() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        let file = workspace.root.appendingPathComponent("absent.json")

        let (result, text) = try await workspace.generate(["--config", file.path])

        #expect(!result.succeeded)
        #expect(text == nil)
        #expect(result.stderr.contains("absent.json"), "\(result.stderr)")
    }

    @Test("rejects --config together with --no-config")
    @MainActor
    func conflictingOptions() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        let file = try workspace.write("{}", to: "settings/custom.json")

        let (result, text) = try await workspace.generate(["--config", file.path, "--no-config"])

        #expect(!result.succeeded)
        #expect(text == nil)
        #expect(result.stderr.contains("--no-config"), "\(result.stderr)")
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

    @Test("rejects an invalid value in the configuration file, naming the file, key and value")
    @MainActor
    func invalidValue() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "container-scope": "everywhere" }"#)

        let (result, _) = try await workspace.generate()

        #expect(!result.succeeded)
        for expected in [Self.configurationFile, "container-scope", "everywhere", "any-resource", "this-resource"] {
            #expect(result.stderr.contains(expected), "\(expected) is missing from: \(result.stderr)")
        }
    }

    // MARK: - Container scope

    @Test("documents --container-scope, --config, --no-config, the variable and the file in the help")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftMTL(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        for text in [
            "--container-scope <any-resource|this-resource>", "--config <file>", "--no-config", semanticsVariable,
            Self.configurationFile,
        ] {
            #expect(result.stdout.contains(text), "\(text) is missing from the help")
        }
    }

    @Test("takes the container scope from the flag, the file and the presets")
    @MainActor
    func containerScope() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let line = "Container Scope: "
        let standard = try await workspace.generate(["--verbose"])
        let legacy = try await workspace.generate(["--verbose"], environment: [semanticsVariable: "legacy"])
        let flag = try await workspace.generate(
            ["--verbose", "--container-scope", "any-resource"], environment: [semanticsVariable: "legacy"])
        try workspace.write(#"{ "semantics": "legacy", "container-scope": "any-resource" }"#)
        let file = try await workspace.generate(["--verbose"])
        let flagOverFile = try await workspace.generate(["--verbose", "--container-scope", "this-resource"])

        for (run, scope) in [
            (standard, "any-resource"), (legacy, "this-resource"), (flag, "any-resource"), (file, "any-resource"),
            (flagOverFile, "this-resource"),
        ] {
            #expect(run.result.succeeded, "\(run.result.stderr)")
            #expect(run.result.stdout.contains(line + scope), "\(scope): \(run.result.stdout)")
        }
        #expect(file.text == Self.legacyOutput)
    }

    @Test("rejects a container scope that does not exist")
    @MainActor
    func invalidContainerScope() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (result, text) = try await workspace.generate(["--container-scope", "everywhere"])

        #expect(!result.succeeded)
        #expect(text == nil)
        #expect(result.stderr.contains("everywhere"))
    }
}
