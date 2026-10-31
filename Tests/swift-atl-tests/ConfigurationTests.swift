//
// ConfigurationTests.swift
// swift-atl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for the environment variable, the configuration file and `--container-scope` of the
/// commands of `swift-atl`.
@Suite("swift-atl - environment and configuration file", .serialized)
struct ConfigurationTests {
    /// A command that reads ATL source, and how it is run on a file.
    enum Command: String, CaseIterable, Sendable {
        case parse, validate, analyze, compile, test, transform, query
    }

    /// The name of the configuration file.
    static let configurationFile = ".swift-modelling.json"

    /// The text that the parser reports for a range in the syntax of Eclipse ATL.
    static let rejection = "not supported by Eclipse ATL"

    /// A transformation whose only rule writes the size of a range.
    static let transformation = """
        -- @nsURI Ecore=http://www.eclipse.org/emf/2002/Ecore
        -- @nsURI GenModel=http://www.eclipse.org/emf/2002/GenModel
        module Range;
        create OUT : GenModel from IN : Ecore;

        entrypoint rule Root() {
            to m : GenModel!GenModel (
                modelName <- Sequence{1..3}->size().toString()
            )
        }
        """

    /// A query that computes the size of a range.
    static let query = """
        -- @nsURI Ecore=http://www.eclipse.org/emf/2002/Ecore
        query Range = Sequence{0, 2..4}->size().toString();
        """

    /// A repository with the library fixture, a transformation, a query and a nested working
    /// directory.
    struct Workspace {
        /// The copy of the library fixture, whose scratch directory is the root.
        let fixture: LibraryFixture

        /// The root of the repository.
        var root: URL { fixture.scratch }

        /// The directory the tool runs in, two levels below the root.
        var workingDirectory: URL { root.appendingPathComponent("work/nested") }

        /// Creates the repository.
        init() throws {
            fixture = try LibraryFixture.make()
            try FileManager.default.createDirectory(
                at: fixture.scratch.appendingPathComponent(".git"), withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true)
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

        /// Runs a command on ATL source that uses a range, from the working directory.
        ///
        /// - Parameters:
        ///   - command: The command to run.
        ///   - extra: The options after the arguments of the command.
        ///   - environment: The environment variables to set.
        /// - Returns: The result of the command and whether it accepted the source.
        @MainActor
        func run(_ command: Command, _ extra: [String] = [], environment: [String: String?] = [:]) async throws
            -> (result: SubprocessResult, accepted: Bool)
        {
            let atl = try write(command == .query ? ConfigurationTests.query : ConfigurationTests.transformation, to: "Range.atl")
            let target = root.appendingPathComponent("range.genmodel")
            let arguments: [String]
            switch command {
            case .parse, .validate, .analyze:
                arguments = [atl.path]
            case .compile:
                arguments = [atl.path, "--output", root.appendingPathComponent("Range.atlc").path]
            case .test:
                arguments = [atl.path, "--timeout", "5"]
            case .transform:
                arguments = [atl.path, "--source", "IN=\(fixture.ecore.path)", "--target", "OUT=\(target.path)"]
            case .query:
                arguments = [atl.path, "--source", fixture.ecore.path]
            }
            let result = try await executeSwiftATL(
                command: command.rawValue, arguments: arguments + extra, workingDirectory: workingDirectory,
                environment: environment)
            let accepted = result.succeeded && !(result.stdout + result.stderr).contains(ConfigurationTests.rejection)
            return (result, accepted)
        }

        /// Removes the repository.
        func remove() { fixture.remove() }
    }

    // MARK: - Environment

    @Test("follows the semantics of the environment variable", arguments: Command.allCases)
    @MainActor
    func environmentVariable(command: Command) async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let standard = try await workspace.run(command, environment: [semanticsVariable: "standard"])
        let legacy = try await workspace.run(command, environment: [semanticsVariable: "legacy"])
        let overridden = try await workspace.run(
            command, ["--semantics", "standard"], environment: [semanticsVariable: "legacy"])

        #expect(standard.accepted, "\(command): \(standard.result.stdout)\(standard.result.stderr)")
        #expect(!legacy.accepted, "\(command): \(legacy.result.stdout)\(legacy.result.stderr)")
        #expect(overridden.accepted, "\(command): \(overridden.result.stdout)\(overridden.result.stderr)")
    }

    @Test("rejects an invalid value of the environment variable, naming it and the accepted values", arguments: Command.allCases)
    @MainActor
    func invalidEnvironmentVariable(command: Command) async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (result, _) = try await workspace.run(command, environment: [semanticsVariable: "0.6"])

        #expect(!result.succeeded)
        for expected in [semanticsVariable, "'0.6'", "standard", "legacy"] {
            #expect(result.stderr.contains(expected), "\(command): \(expected) is missing from: \(result.stderr)")
        }
    }

    // MARK: - Configuration file

    @Test("reads the configuration file of a parent directory", arguments: Command.allCases)
    @MainActor
    func parentConfiguration(command: Command) async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "collection-range-syntax": "eclipse", "block-line-breaks": "kept" }"#)

        let configured = try await workspace.run(command)
        let ignored = try await workspace.run(command, ["--no-config"])
        let overridden = try await workspace.run(command, ["--collection-range-syntax", "ocl"])

        #expect(!configured.accepted, "\(command): \(configured.result.stdout)\(configured.result.stderr)")
        #expect(ignored.accepted, "\(command): \(ignored.result.stdout)\(ignored.result.stderr)")
        #expect(overridden.accepted, "\(command): \(overridden.result.stdout)\(overridden.result.stderr)")
    }

    @Test("lets the semantics of the configuration file give way to the environment variable")
    @MainActor
    func environmentOverridesConfiguration() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "semantics": "legacy" }"#)

        let configured = try await workspace.run(.query)
        let overridden = try await workspace.run(.query, environment: [semanticsVariable: "standard"])

        #expect(!configured.accepted, "\(configured.result.stdout)\(configured.result.stderr)")
        #expect(overridden.accepted, "\(overridden.result.stdout)\(overridden.result.stderr)")
        #expect(overridden.result.stdout.contains("4"))
    }

    @Test("reads the file given with --config")
    @MainActor
    func explicitConfiguration() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        let file = try workspace.write(#"{ "semantics": "legacy" }"#, to: "settings/custom.json")

        let (result, accepted) = try await workspace.run(.parse, ["--config", file.path])
        let missing = try await workspace.run(.parse, ["--config", file.path + ".missing"])

        #expect(!accepted, "\(result.stdout)\(result.stderr)")
        #expect(!missing.result.succeeded)
        #expect(missing.result.stderr.contains("custom.json.missing"), "\(missing.result.stderr)")
    }

    @Test("rejects an unknown key, naming the file and the key", arguments: Command.allCases)
    @MainActor
    func unknownKey(command: Command) async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "colour": "blue" }"#)

        let (result, _) = try await workspace.run(command)

        #expect(!result.succeeded)
        #expect(result.stderr.contains(Self.configurationFile), "\(command): \(result.stderr)")
        #expect(result.stderr.contains("colour"), "\(command): \(result.stderr)")
    }

    // MARK: - Container scope

    @Test("documents --container-scope, --config and --no-config in the help", arguments: Command.allCases.map(\.rawValue) + ["generate"])
    @MainActor
    func help(command: String) async throws {
        let result = try await executeSwiftATL(command: command, arguments: ["--help"])

        #expect(result.succeeded)
        for text in [
            "--container-scope <any-resource|this-resource>", "--config <file>", "--no-config", semanticsVariable,
            Self.configurationFile,
        ] {
            #expect(result.stdout.contains(text), "\(command): \(text) is missing from the help")
        }
    }

    @Test("accepts each container scope", arguments: ["any-resource", "this-resource"])
    @MainActor
    func containerScope(scope: String) async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let transform = try await workspace.run(.transform, ["--container-scope", scope])
        let query = try await workspace.run(.query, ["--container-scope", scope])
        try workspace.write(#"{ "container-scope": "\#(scope)" }"#)
        let configured = try await workspace.run(.query)

        for run in [transform, query, configured] {
            #expect(run.accepted, "\(run.result.stdout)\(run.result.stderr)")
        }
    }

    @Test("rejects a container scope that does not exist")
    @MainActor
    func invalidContainerScope() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (result, _) = try await workspace.run(.query, ["--container-scope", "everywhere"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("everywhere"))
    }
}
