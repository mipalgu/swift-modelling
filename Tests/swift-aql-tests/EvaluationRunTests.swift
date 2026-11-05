//
// EvaluationRunTests.swift
// swift-aql-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@testable import swift_aql

/// Tests a whole evaluation as a command performs it.
@Suite("Evaluation runs")
@MainActor
struct EvaluationRunTests {
    /// The options of a command line, as the commands parse them.
    func options(_ arguments: [String]) throws -> EvaluationOptions {
        try EvaluateCommand.parse(["-e", "self"] + arguments).evaluationOptions
    }

    @Test("A run evaluates against the models, with or without a context")
    func run() async throws {
        let model = try Fixture.shop(Fixture.shopModel).path
        let directory = FileManager.default.temporaryDirectory
        let plain = EvaluationRun(models: [model], source: .text("self.name"), options: try options(["--no-config"]))
        #expect(ResultFormatter().format(try await plain.value(environment: [:], currentDirectory: directory)) == "\"Corner Shop\"")
        let context = EvaluationRun(
            models: [model], source: .text("self.name"), options: try options(["--no-config", "--context", "Kiosk"]))
        #expect(ResultFormatter().format(try await context.value(environment: [:], currentDirectory: directory)) == "\"Kiosk\"")
    }

    @Test("A run reads the preset from a configuration file")
    func configuration() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("settings.json")
        try "{\"semantics\": \"sometimes\"}".write(to: file, atomically: true, encoding: .utf8)
        let run = EvaluationRun(models: [], source: .text("1"), options: try options(["--config", file.path]))
        await #expect(throws: (any Error).self) { try await run.value(environment: [:], currentDirectory: directory) }
    }

    @Test("A run reports an empty expression before it loads models")
    func emptyExpression() async throws {
        let run = EvaluationRun(models: ["missing.xmi"], source: .text(" "), options: try options(["--no-config"]))
        await #expect(throws: SwiftAQLError.emptyExpression) { try await run.value(environment: [:]) }
    }
}
