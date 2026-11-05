//
// IntegerDivisionTests.swift
// swift-atl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for `--integer-division` and `--semantics` on the commands of `swift-atl` that run
/// ATL source, which choose what `/` gives for two Integers.
@Suite("swift-atl - integer division")
struct IntegerDivisionTests {
    /// A command that runs ATL source.
    enum Command: String, CaseIterable, Sendable {
        case transform, query
    }

    /// A command that reads ATL source and offers the options of the ATL language.
    enum ReadingCommand: String, CaseIterable, Sendable {
        case parse, validate, analyze, compile, test, transform, query, generate
    }

    /// A transformation whose only rule names the model after a quotient of two Integers.
    private static let transformation = """
        -- @nsURI Ecore=http://www.eclipse.org/emf/2002/Ecore
        -- @nsURI GenModel=http://www.eclipse.org/emf/2002/GenModel
        module Division;
        create OUT : GenModel from IN : Ecore;

        entrypoint rule Root() {
            to m : GenModel!GenModel (
                modelName <- (7 / 2).toString()
            )
        }
        """

    /// A query that divides two Integers.
    private static let query = """
        -- @nsURI Ecore=http://www.eclipse.org/emf/2002/Ecore
        query Division = (7 / 2).toString();
        """

    /// Runs a command on ATL source that divides two Integers.
    ///
    /// - Parameters:
    ///   - command: The command to run.
    ///   - extra: The options after the arguments of the command.
    ///   - configuration: The contents of a configuration file in the directory the command runs
    ///     in, or `nil` for none.
    /// - Returns: The result of the command and the quotient it wrote to a model or its standard
    ///   output.
    @MainActor
    private func run(_ command: Command, _ extra: [String], configuration: String? = nil) async throws
        -> (result: SubprocessResult, quotient: String)
    {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        try FileManager.default.createDirectory(
            at: fixture.scratch.appendingPathComponent(".git"), withIntermediateDirectories: true)
        if let configuration {
            try configuration.write(
                to: fixture.scratch.appendingPathComponent(ConfigurationTests.configurationFile), atomically: true,
                encoding: .utf8)
        }
        let atl = fixture.scratch.appendingPathComponent("Division.atl")
        try (command == .query ? Self.query : Self.transformation).write(to: atl, atomically: true, encoding: .utf8)
        let target = fixture.scratch.appendingPathComponent("division.genmodel")
        let arguments: [String]
        switch command {
        case .transform:
            arguments = [atl.path, "--source", "IN=\(fixture.ecore.path)", "--target", "OUT=\(target.path)"]
        case .query:
            arguments = [atl.path, "--source", fixture.ecore.path]
        }
        let result = try await executeSwiftATL(
            command: command.rawValue, arguments: arguments + extra, workingDirectory: fixture.scratch)
        let quotient: String
        switch command {
        case .transform:
            let text = (try? String(contentsOf: target, encoding: .utf8)) ?? ""
            let name = text.range(of: #"modelName="[^"]*""#, options: .regularExpression).map { String(text[$0]) }
            quotient = name?.dropFirst("modelName=\"".count).dropLast().description ?? ""
        case .query:
            quotient = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return (result, quotient)
    }

    @Test(
        "divides two Integers into a Real by default, with real, and with real over the legacy preset",
        arguments: Command.allCases)
    @MainActor
    func real(command: Command) async throws {
        for extra in [[], ["--integer-division", "real"], ["--semantics", "legacy", "--integer-division", "real"]] {
            let (result, quotient) = try await run(command, extra)

            #expect(result.succeeded, "\(command) \(extra): \(result.stdout)\(result.stderr)")
            #expect(quotient == "3.5", "\(command) \(extra): \(result.stdout)\(result.stderr)")
        }
    }

    @Test(
        "truncates the quotient with truncating, with the legacy preset, and with truncating over the standard preset",
        arguments: Command.allCases)
    @MainActor
    func truncating(command: Command) async throws {
        for extra in [
            ["--integer-division", "truncating"], ["--semantics", "legacy"],
            ["--semantics", "standard", "--integer-division", "truncating"],
        ] {
            let (result, quotient) = try await run(command, extra)

            #expect(result.succeeded, "\(command) \(extra): \(result.stdout)\(result.stderr)")
            #expect(quotient == "3", "\(command) \(extra): \(result.stdout)\(result.stderr)")
        }
    }

    @Test("reads the division from the configuration file unless the option overrides it", arguments: Command.allCases)
    @MainActor
    func configuration(command: Command) async throws {
        let file = #"{ "integer-division": "truncating" }"#

        let configured = try await run(command, [], configuration: file)
        let overridden = try await run(command, ["--integer-division", "real"], configuration: file)
        let ignored = try await run(command, ["--no-config"], configuration: file)

        #expect(configured.quotient == "3", "\(configured.result.stdout)\(configured.result.stderr)")
        #expect(overridden.quotient == "3.5", "\(overridden.result.stdout)\(overridden.result.stderr)")
        #expect(ignored.quotient == "3.5", "\(ignored.result.stdout)\(ignored.result.stderr)")
    }

    @Test("describes the option in the help", arguments: ReadingCommand.allCases)
    @MainActor
    func help(command: ReadingCommand) async throws {
        let result = try await executeSwiftATL(command: command.rawValue, arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("--integer-division <real|truncating>"), "\(result.stdout)")
    }

    @Test("rejects a division that does not exist", arguments: Command.allCases)
    @MainActor
    func rejectsUnknownDivision(command: Command) async throws {
        let result = try await executeSwiftATL(
            command: command.rawValue, arguments: ["Division.atl", "--integer-division", "rounding"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("rounding"))
    }
}
