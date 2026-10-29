//
// CollectionRangeSyntaxTests.swift
// swift-atl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for `--collection-range-syntax` and `--semantics` on the commands of `swift-atl` that
/// read ATL source, which choose whether collection literals accept integer ranges.
@Suite("swift-atl - collection range syntax")
struct CollectionRangeSyntaxTests {
    /// A command that reads ATL source, and how it is run on a file.
    enum Command: String, CaseIterable, Sendable {
        case parse, validate, analyze, compile, test, transform, query
    }

    /// The text that the parser reports for a range in the syntax of Eclipse ATL.
    private static let rejection = "not supported by Eclipse ATL"

    /// A transformation whose only rule writes the size of a range.
    private static let transformation = """
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
    private static let query = """
        -- @nsURI Ecore=http://www.eclipse.org/emf/2002/Ecore
        query Range = Sequence{0, 2..4}->size().toString();
        """

    /// Runs a command on ATL source that uses a range.
    ///
    /// - Parameters:
    ///   - command: The command to run.
    ///   - extra: The options after the arguments of the command.
    /// - Returns: The result of the command, whether it accepted the source, and what it wrote
    ///   to a model or its standard output.
    @MainActor
    private func run(_ command: Command, _ extra: [String]) async throws
        -> (result: SubprocessResult, accepted: Bool, output: String)
    {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let atl = fixture.scratch.appendingPathComponent("Range.atl")
        try (command == .query ? Self.query : Self.transformation).write(to: atl, atomically: true, encoding: .utf8)
        let target = fixture.scratch.appendingPathComponent("range.genmodel")
        let arguments: [String]
        switch command {
        case .parse, .validate, .analyze:
            arguments = [atl.path]
        case .compile:
            arguments = [atl.path, "--output", fixture.scratch.appendingPathComponent("Range.atlc").path]
        case .test:
            arguments = [atl.path, "--timeout", "5"]
        case .transform:
            arguments = [atl.path, "--source", "IN=\(fixture.ecore.path)", "--target", "OUT=\(target.path)"]
        case .query:
            arguments = [atl.path, "--source", fixture.ecore.path]
        }
        let result = try await executeSwiftATL(command: command.rawValue, arguments: arguments + extra)
        let text = result.stdout + result.stderr
        let accepted = result.succeeded && !text.contains(Self.rejection)
        let output: String
        switch command {
        case .transform: output = (try? String(contentsOf: target, encoding: .utf8)) ?? ""
        default: output = result.stdout
        }
        return (result, accepted, output)
    }

    @Test("accepts ranges by default, with ocl, and with ocl over the legacy preset", arguments: Command.allCases)
    @MainActor
    func accepts(command: Command) async throws {
        for extra in [[], ["--collection-range-syntax", "ocl"], ["--semantics", "legacy", "--collection-range-syntax", "ocl"]] {
            let (result, accepted, output) = try await run(command, extra)

            #expect(accepted, "\(command) \(extra): \(result.stdout)\(result.stderr)")
            switch command {
            case .transform: #expect(output.contains("modelName=\"3\""), "\(output)")
            case .query: #expect(output.contains("4"), "\(output)")
            default: break
            }
        }
    }

    @Test("rejects ranges with eclipse, with the legacy preset, and with eclipse over the standard preset", arguments: Command.allCases)
    @MainActor
    func rejects(command: Command) async throws {
        for extra in [
            ["--collection-range-syntax", "eclipse"], ["--semantics", "legacy"],
            ["--semantics", "standard", "--collection-range-syntax", "eclipse"],
        ] {
            let (result, accepted, _) = try await run(command, extra)

            #expect(!accepted, "\(command) \(extra): \(result.stdout)\(result.stderr)")
            if command == .validate { #expect(result.stdout.contains("INVALID"), "\(result.stdout)") }
            if command != .test && command != .validate {
                #expect((result.stdout + result.stderr).contains(Self.rejection), "\(command) \(extra)")
            }
        }
    }

    @Test("describes the options in the help", arguments: Command.allCases)
    @MainActor
    func help(command: Command) async throws {
        let result = try await executeSwiftATL(command: command.rawValue, arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("--collection-range-syntax <ocl|eclipse>"))
        #expect(result.stdout.contains("--semantics <standard|legacy>"))
    }

    @Test("rejects a range syntax that does not exist", arguments: Command.allCases)
    @MainActor
    func rejectsUnknownSyntax(command: Command) async throws {
        let result = try await executeSwiftATL(
            command: command.rawValue, arguments: ["Range.atl", "--collection-range-syntax", "sometimes"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("sometimes"))
    }
}
