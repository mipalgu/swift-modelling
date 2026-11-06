//
// BagRepresentationTests.swift
// swift-atl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for `--bag-representation` and `--semantics` on the commands of `swift-atl` that run
/// ATL source, which choose whether a Bag is a collection kind of its own or a Sequence.
@Suite("swift-atl - Bag representation")
struct BagRepresentationTests {
    /// A command that runs ATL source.
    enum Command: String, CaseIterable, Sendable {
        case transform, query
    }

    /// A command that reads ATL source and offers the options of the ATL language.
    enum ReadingCommand: String, CaseIterable, Sendable {
        case parse, validate, analyze, compile, test, transform, query, generate
    }

    /// What the commands report for a Bag: the receiver of a helper and the type of a Bag
    /// literal for `transform`, and the text of the Bag that `collect` on a Set gives for `query`.
    struct Report: Sendable, Equatable {
        /// What `transform` writes to the model.
        let transform: String

        /// What `query` prints.
        let query: String

        /// The report of the command.
        ///
        /// - Parameter command: The command that reports.
        /// - Returns: The text that the command reports.
        func text(of command: Command) -> String {
            switch command {
            case .transform: return transform
            case .query: return query
            }
        }

        /// The report when Bags are a collection kind of their own.
        static let bag = Report(transform: "Bag Bag", query: "Bag{0, 0}")

        /// The report when Bags are Sequences.
        static let sequence = Report(transform: "Sequence Sequence", query: "Sequence{0, 0}")
    }

    /// A transformation whose only rule names the model after the helper that a Bag receives
    /// and the type of a Bag literal.
    private static let transformation = """
        -- @nsURI Ecore=http://www.eclipse.org/emf/2002/Ecore
        -- @nsURI GenModel=http://www.eclipse.org/emf/2002/GenModel
        module Bags;
        create OUT : GenModel from IN : Ecore;

        helper context Bag(Integer) def : kind : String = 'Bag';
        helper context Sequence(Integer) def : kind : String = 'Sequence';

        entrypoint rule Root() {
            to m : GenModel!GenModel (
                modelName <- Set{1, 2}->collect(e | 0)->kind + ' ' + Bag{1, 1}->oclType().toString()
            )
        }
        """

    /// A query whose value is the collection that `collect` on a Set gives.
    private static let query = """
        -- @nsURI Ecore=http://www.eclipse.org/emf/2002/Ecore
        query Bags = Set{1, 2}->collect(e | 0);
        """

    /// Runs a command on ATL source that makes Bags.
    ///
    /// - Parameters:
    ///   - command: The command to run.
    ///   - extra: The options after the arguments of the command.
    ///   - configuration: The contents of a configuration file in the directory the command runs
    ///     in, or `nil` for none.
    /// - Returns: The result of the command and what it wrote to a model or its standard output.
    @MainActor
    private func run(_ command: Command, _ extra: [String], configuration: String? = nil) async throws
        -> (result: SubprocessResult, report: String)
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
        let atl = fixture.scratch.appendingPathComponent("Bags.atl")
        try (command == .query ? Self.query : Self.transformation).write(to: atl, atomically: true, encoding: .utf8)
        let target = fixture.scratch.appendingPathComponent("bags.genmodel")
        let arguments: [String]
        switch command {
        case .transform:
            arguments = [atl.path, "--source", "IN=\(fixture.ecore.path)", "--target", "OUT=\(target.path)"]
        case .query:
            arguments = [atl.path, "--source", fixture.ecore.path]
        }
        let result = try await executeSwiftATL(
            command: command.rawValue, arguments: arguments + extra, workingDirectory: fixture.scratch)
        let report: String
        switch command {
        case .transform:
            let text = (try? String(contentsOf: target, encoding: .utf8)) ?? ""
            let name = text.range(of: #"modelName="[^"]*""#, options: .regularExpression).map { String(text[$0]) }
            report = name?.dropFirst("modelName=\"".count).dropLast().description ?? ""
        case .query:
            report = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return (result, report)
    }

    @Test(
        "keeps Bags a kind of their own by default, with bag, and with bag over the legacy preset",
        arguments: Command.allCases)
    @MainActor
    func bag(command: Command) async throws {
        for extra in [[], ["--bag-representation", "bag"], ["--semantics", "legacy", "--bag-representation", "bag"]] {
            let (result, report) = try await run(command, extra)

            #expect(result.succeeded, "\(command) \(extra): \(result.stdout)\(result.stderr)")
            #expect(report == Report.bag.text(of: command), "\(command) \(extra): \(result.stdout)\(result.stderr)")
        }
    }

    @Test(
        "makes Bags Sequences with sequence, with the legacy preset, and with sequence over the standard preset",
        arguments: Command.allCases)
    @MainActor
    func sequence(command: Command) async throws {
        for extra in [
            ["--bag-representation", "sequence"], ["--semantics", "legacy"],
            ["--semantics", "standard", "--bag-representation", "sequence"],
        ] {
            let (result, report) = try await run(command, extra)

            #expect(result.succeeded, "\(command) \(extra): \(result.stdout)\(result.stderr)")
            #expect(
                report == Report.sequence.text(of: command), "\(command) \(extra): \(result.stdout)\(result.stderr)")
        }
    }

    @Test(
        "reads the Bag representation from the configuration file unless the option overrides it",
        arguments: Command.allCases)
    @MainActor
    func configuration(command: Command) async throws {
        let file = #"{ "bag-representation": "sequence" }"#

        let configured = try await run(command, [], configuration: file)
        let overridden = try await run(command, ["--bag-representation", "bag"], configuration: file)
        let ignored = try await run(command, ["--no-config"], configuration: file)
        let overPreset = try await run(command, [], configuration: #"{ "semantics": "legacy", "bag-representation": "bag" }"#)

        #expect(configured.report == Report.sequence.text(of: command), "\(configured.result.stderr)")
        #expect(overridden.report == Report.bag.text(of: command), "\(overridden.result.stderr)")
        #expect(ignored.report == Report.bag.text(of: command), "\(ignored.result.stderr)")
        #expect(overPreset.report == Report.bag.text(of: command), "\(overPreset.result.stderr)")
    }

    @Test("describes the option in the help", arguments: ReadingCommand.allCases)
    @MainActor
    func help(command: ReadingCommand) async throws {
        let result = try await executeSwiftATL(command: command.rawValue, arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("--bag-representation <bag|sequence>"), "\(result.stdout)")
    }

    @Test("rejects a Bag representation that does not exist", arguments: Command.allCases)
    @MainActor
    func rejectsUnknownRepresentation(command: Command) async throws {
        let result = try await executeSwiftATL(
            command: command.rawValue, arguments: ["Bags.atl", "--bag-representation", "set"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("'set'"), "\(result.stderr)")
    }
}
