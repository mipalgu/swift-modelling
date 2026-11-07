//
// SourceEncodingTests.swift
// swift-atl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for the character encoding in which the commands of `swift-atl` read ATL source.
///
/// A file that is not valid UTF-8 is read as ISO-8859-1 with a warning on standard error;
/// `--encoding` and the `encoding` key of the configuration file name the encoding instead.
@Suite("swift-atl - source encodings", .serialized)
struct SourceEncodingTests {
    /// The commands that read ATL source.
    typealias Command = ConfigurationTests.Command

    /// The comment whose accented letter makes the source differ between encodings.
    static let comment = "-- Transformation für Café\n"

    /// The warning that a file was read as ISO-8859-1.
    static let fallbackWarning = "The text is not valid UTF-8 and was read as ISO-8859-1"

    /// Encodes text in ISO-8859-1.
    ///
    /// - Parameter text: Text whose characters are all below U+0100.
    /// - Returns: One byte per character.
    static func latin1(_ text: String) -> Data {
        Data(text.unicodeScalars.map { UInt8($0.value) })
    }

    /// Runs a command on ATL source written in ISO-8859-1.
    ///
    /// - Parameters:
    ///   - command: The command to run.
    ///   - workspace: The repository with the library fixture.
    ///   - extra: The options after the arguments of the command.
    ///   - utf8: Whether the source is written in UTF-8 instead.
    /// - Returns: The path of the source and the result of the command.
    @MainActor
    static func run(
        _ command: Command, in workspace: ConfigurationTests.Workspace, _ extra: [String] = [], utf8: Bool = false
    ) async throws -> (path: String, result: SubprocessResult) {
        let text = comment + (command == .query ? ConfigurationTests.query : ConfigurationTests.transformation)
        let atl = workspace.root.appendingPathComponent("Encoded.atl")
        try (utf8 ? Data(text.utf8) : latin1(text)).write(to: atl)
        let target = workspace.root.appendingPathComponent("encoded.genmodel")
        let arguments: [String]
        switch command {
        case .parse, .validate, .analyze:
            arguments = [atl.path]
        case .compile:
            arguments = [atl.path, "--output", workspace.root.appendingPathComponent("Encoded.atlc").path]
        case .test:
            arguments = [atl.path, "--timeout", "5"]
        case .transform:
            arguments = [atl.path, "--source", "IN=\(workspace.fixture.ecore.path)", "--target", "OUT=\(target.path)"]
        case .query:
            arguments = [atl.path, "--source", workspace.fixture.ecore.path]
        }
        let result = try await executeSwiftATL(
            command: command.rawValue, arguments: arguments + extra, workingDirectory: workspace.workingDirectory)
        return (atl.path, result)
    }

    @Test("reads a file that is not UTF-8 as ISO-8859-1, with a warning naming the file", arguments: Command.allCases)
    @MainActor
    func latin1Fallback(command: Command) async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }

        let (path, result) = try await Self.run(command, in: workspace)

        #expect(result.succeeded, "\(command): \(result.stdout)\(result.stderr)")
        #expect(
            result.stderr.contains("warning: \(path): line 1, column 20: \(Self.fallbackWarning)"),
            "\(command): \(result.stderr)")
        #expect(!result.stdout.contains(Self.fallbackWarning), "\(command): \(result.stdout)")
    }

    @Test("reads a UTF-8 file without a warning", arguments: Command.allCases)
    @MainActor
    func utf8(command: Command) async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }

        let (_, result) = try await Self.run(command, in: workspace, utf8: true)

        #expect(result.succeeded, "\(command): \(result.stdout)\(result.stderr)")
        #expect(!result.stderr.contains("warning:"), "\(command): \(result.stderr)")
    }

    @Test("reads the encoding given with --encoding without a warning", arguments: Command.allCases)
    @MainActor
    func explicitEncoding(command: Command) async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }

        let (_, result) = try await Self.run(command, in: workspace, ["--encoding", "ISO-8859-1"])

        #expect(result.succeeded, "\(command): \(result.stdout)\(result.stderr)")
        #expect(!result.stderr.contains(Self.fallbackWarning), "\(command): \(result.stderr)")
    }

    @Test("reads the encoding of the configuration file, which --encoding overrides", arguments: Command.allCases)
    @MainActor
    func configuredEncoding(command: Command) async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "encoding": "latin1" }"#)

        let configured = try await Self.run(command, in: workspace)
        let overridden = try await Self.run(command, in: workspace, ["--encoding", "US-ASCII"])

        #expect(configured.result.succeeded, "\(command): \(configured.result.stdout)\(configured.result.stderr)")
        #expect(!configured.result.stderr.contains(Self.fallbackWarning), "\(command): \(configured.result.stderr)")
        let output = overridden.result.stdout + overridden.result.stderr
        if command == .validate {
            // validate reports the number of errors of each file, not their messages
            #expect(!overridden.result.succeeded, "\(command): \(output)")
        } else {
            #expect(output.contains("not valid US-ASCII"), "\(command): \(output)")
            #expect(output.contains(overridden.path), "\(command): \(output)")
        }
    }

    @Test("rejects an unknown encoding, listing the supported ones")
    @MainActor
    func unknownEncoding() async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }

        let (_, result) = try await Self.run(.parse, in: workspace, ["--encoding", "EBCDIC"])

        #expect(!result.succeeded)
        for name in ["EBCDIC", "UTF-8", "ISO-8859-1", "windows-1252"] {
            #expect(result.stderr.contains(name), "\(name) is missing from: \(result.stderr)")
        }
    }
}
