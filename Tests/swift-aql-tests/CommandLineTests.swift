//
// CommandLineTests.swift
// swift-aql-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ArgumentParser
import EMFBase
import Foundation
import ModellingCommandLine
import Testing

@testable import swift_aql

/// Tests how the command lines of the tool are parsed.
@Suite("Command line parsing")
struct CommandLineTests {
    @Test("evaluate takes models and an expression")
    func evaluate() throws {
        let command = try EvaluateCommand.parse(["--model", "a.xmi", "--model", "b.xmi", "--expression", "self"])
        #expect(command.models == ["a.xmi", "b.xmi"])
        #expect(command.source == .text("self"))
        #expect(try EvaluateCommand.parse(["-e", "1 + 2"]).source == .text("1 + 2"))
        #expect(try EvaluateCommand.parse(["-f", "q.aql"]).source == .file("q.aql"))
        #expect(try EvaluateCommand.parse(["--expression-file", "q.aql", "--model", "a.xmi"]).models == ["a.xmi"])
    }

    @Test("evaluate needs exactly one expression")
    func evaluateValidation() {
        #expect(throws: (any Error).self) { try EvaluateCommand.parse(["--model", "a.xmi"]) }
        #expect(throws: (any Error).self) { try EvaluateCommand.parse(["-e", "self", "-f", "q.aql"]) }
    }

    @Test("query takes a model and a query in one of three forms")
    func query() throws {
        let positional = try QueryCommand.parse(["m.xmi", "self.name"])
        #expect(positional.model == "m.xmi")
        #expect(positional.source == .text("self.name"))
        #expect(try QueryCommand.parse(["m.xmi", "--query", "self"]).source == .text("self"))
        #expect(try QueryCommand.parse(["m.xmi", "-q", "self"]).source == .text("self"))
        #expect(try QueryCommand.parse(["m.xmi", "--query-file", "q.aql"]).source == .file("q.aql"))
        let context = try QueryCommand.parse(["m.xmi", "-q", "self", "--context", "company1"])
        #expect(context.evaluationOptions.context == "company1")
    }

    @Test("query needs exactly one query")
    func queryValidation() {
        #expect(throws: (any Error).self) { try QueryCommand.parse(["m.xmi"]) }
        #expect(throws: (any Error).self) { try QueryCommand.parse(["m.xmi", "self", "--query", "self"]) }
        #expect(throws: (any Error).self) { try QueryCommand.parse([]) }
    }

    @Test("The shared options name metamodels and the context")
    func sharedOptions() throws {
        let command = try EvaluateCommand.parse(["-e", "self", "-m", "A.ecore", "--metamodel", "B.ecore", "--context", "/0"])
        #expect(command.evaluationOptions.metamodelOptions.metamodels == ["A.ecore", "B.ecore"])
        #expect(command.evaluationOptions.context == "/0")
    }

    @Test("The behaviours of expressions follow the preset unless an option is given")
    func semantics() throws {
        let defaults = try EvaluateCommand.parse(["-e", "self", "--no-config"]).evaluationOptions
        let settings = try defaults.semanticsOptions.settings(environment: [:])
        #expect(defaults.aqlSemanticsOptions.aqlOptions(settings: settings) == AQLOptions.standard)

        let legacy = try EvaluateCommand.parse(["-e", "self", "--no-config", "--semantics", "legacy"]).evaluationOptions
        let legacySettings = try legacy.semanticsOptions.settings(environment: [:])
        #expect(legacy.aqlSemanticsOptions.aqlOptions(settings: legacySettings) == AQLOptions.legacy)

        let mixed = try EvaluateCommand.parse([
            "-e", "self", "--no-config", "--semantics", "legacy", "--collection-kinds", "distinguished",
            "--collection-arguments", "whole", "--single-value-collections", "set", "--container-lookup", "resources",
        ]).evaluationOptions
        let options = mixed.aqlSemanticsOptions.aqlOptions(settings: try mixed.semanticsOptions.settings(environment: [:]))
        #expect(options.collectionKinds == .distinguished)
        #expect(options.collectionArguments == .whole)
        #expect(options.singleValueCollections == .set)
        #expect(options.containerLookup == .resources)
    }

    @Test("Strict mode is off in both presets and on with --strict-aql")
    func strict() throws {
        for preset in ["standard", "legacy"] {
            let lenient = try EvaluateCommand.parse(["-e", "self", "--no-config", "--semantics", preset]).evaluationOptions
            let strict = try EvaluateCommand.parse(
                ["-e", "self", "--no-config", "--semantics", preset, "--strict-aql"]).evaluationOptions
            #expect(!lenient.aqlSemanticsOptions.aqlOptions(settings: try lenient.semanticsOptions.settings(environment: [:])).strict)
            #expect(strict.aqlSemanticsOptions.aqlOptions(settings: try strict.semanticsOptions.settings(environment: [:])).strict)
        }
    }

    @Test("Strict mode follows the strict-aql key of the configuration file unless a flag overrides it")
    func strictFromConfiguration() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-aql-strict-configuration-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent(ModellingConfiguration.fileName)
        try #"{ "strict-aql": true }"#.write(to: file, atomically: true, encoding: .utf8)

        func strict(_ extra: [String]) throws -> Bool {
            let options = try EvaluateCommand.parse(["-e", "self", "--config", file.path] + extra).evaluationOptions
            return options.aqlSemanticsOptions.aqlOptions(settings: try options.semanticsOptions.settings(environment: [:])).strict
        }
        #expect(try strict([]))
        #expect(try !strict(["--no-strict-aql"]))
        #expect(try strict(["--strict-aql"]))
    }

    @Test("Unset features read as the command line says")
    func unsetFeatures() throws {
        let options = try EvaluateCommand.parse(["-e", "self", "--unset-features", "undefined"]).evaluationOptions
        #expect(options.unsetFeatureOptions.unsetFeatures == .undefined)
    }

    @Test("The tool names its subcommands and version")
    func configuration() {
        let configuration = SwiftAQLCommand.configuration
        #expect(configuration.commandName == SwiftAQLVocabulary.toolName)
        #expect(configuration.version == SwiftAQLVocabulary.version)
        #expect(configuration.subcommands.map { $0.configuration.commandName } == ["evaluate", "query"])
    }
}

/// Tests the messages of the errors.
@Suite("Error messages")
struct ErrorMessageTests {
    @Test("Each error describes its problem", arguments: [
        (SwiftAQLError.modelNotFound("m.xmi"), "Model file not found: m.xmi"),
        (.expressionFileNotFound("q.aql"), "Expression file not found or not readable: q.aql"),
        (.emptyExpression, "The expression is empty"),
        (.invalidExpression(["line 1, column 2: oops"]), "Invalid AQL expression:\n  line 1, column 2: oops"),
        (.evaluationFailed("bad"), "Evaluation failed: bad"),
        (.contextNotFound("x"), "No object has the identifier or name 'x'"),
        (.ambiguousContext("x", 2), "2 objects have the name 'x'; select one by its identifier instead"),
        (.ambiguousMetamodels("urn:a", ["A.ecore", "B.ecore"]), "Several metamodels declare urn:a: A.ecore, B.ecore; choose one with --metamodel"),
    ])
    func descriptions(_ error: SwiftAQLError, _ message: String) {
        #expect(error.description == message)
        #expect(error.errorDescription == message)
    }

    @Test("Parser problems are described with their position when they have one")
    func diagnostics() {
        let position = SourcePosition(utf8Offset: 4, line: 1, column: 5)
        let located = SourceDiagnostic(
            severity: .error, code: "aql", message: "oops", range: SourceRange(start: position, end: position))
        #expect(SwiftAQLError.describe(located) == "line 1, column 5: oops")
        #expect(SwiftAQLError.describe(SourceDiagnostic(severity: .error, code: "aql", message: "oops")) == "oops")
    }
}
