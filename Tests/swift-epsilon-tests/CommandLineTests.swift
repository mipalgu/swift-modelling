//
// CommandLineTests.swift
// swift-epsilon-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import Foundation
import Testing

@testable import swift_epsilon

/// Tests how the command lines of the tool are parsed and checked.
@Suite("Command line parsing")
struct CommandLineTests {
    @Test("The tool groups its commands by language")
    func groups() {
        let configuration = SwiftEpsilonCommand.configuration
        #expect(configuration.commandName == "swift-epsilon")
        #expect(configuration.version == "0.8.1")
        let groups = configuration.subcommands.map { $0.configuration.commandName }
        #expect(groups == ["eol", "evl", "etl", "egl"])
        #expect(EOLCommand.configuration.subcommands.map { $0.configuration.commandName } == ["run"])
        #expect(EVLCommand.configuration.subcommands.map { $0.configuration.commandName } == ["validate"])
        #expect(ETLCommand.configuration.subcommands.map { $0.configuration.commandName } == ["transform"])
        #expect(EGLCommand.configuration.subcommands.map { $0.configuration.commandName } == ["generate"])
    }

    @Test("eol run takes a program, models, targets, stores and parameters")
    func eolRun() throws {
        let command = try EOLRunCommand.parse([
            "report.eol", "--model", "Bank=bank.xmi", "--model", "Old,O=old.xmi", "--target", "Ledger=ledger.xmi",
            "--store", "Bank", "-m", "Bank.ecore", "--metamodel", "Ledger.ecore", "--param", "reader=Alice",
            "--max-call-depth", "50", "-v", "--encoding", "latin1",
        ])
        #expect(command.program == "report.eol")
        #expect(command.modelOptions.models == ["Bank=bank.xmi", "Old,O=old.xmi"])
        #expect(command.targetOptions.targets == ["Ledger=ledger.xmi"])
        #expect(command.modelOptions.stores == ["Bank"])
        #expect(command.modelOptions.metamodelOptions.metamodels == ["Bank.ecore", "Ledger.ecore"])
        #expect(command.executionOptions.parameters == ["reader=Alice"])
        #expect(command.executionOptions.maximumCallDepth == 50)
        #expect(command.executionOptions.verbose)
        #expect(command.executionOptions.encodingOptions.explicitEncoding == .isoLatin1)
    }

    @Test("The defaults leave every option unset")
    func defaults() throws {
        let command = try EOLRunCommand.parse(["report.eol"])
        #expect(command.modelOptions.models.isEmpty)
        #expect(command.modelOptions.stores.isEmpty)
        #expect(command.targetOptions.targets.isEmpty)
        #expect(command.executionOptions.parameters.isEmpty)
        #expect(command.executionOptions.maximumCallDepth == 1_000)
        #expect(!command.executionOptions.verbose)
        #expect(command.modelOptions.referenceStyleOptions.referenceStyle == .encoded)
    }

    @Test("A command needs its source file")
    func missingSource() {
        #expect(throws: (any Error).self) { try EOLRunCommand.parse([]) }
        #expect(throws: (any Error).self) { try EVLValidateCommand.parse([]) }
        #expect(throws: (any Error).self) { try ETLTransformCommand.parse([]) }
        #expect(throws: (any Error).self) { try EGLGenerateCommand.parse([]) }
    }

    @Test("Invalid bindings and parameters are rejected before the run", arguments: [
        ["p.eol", "--model", "bank.xmi"],
        ["p.eol", "--model", "1Bank=bank.xmi"],
        ["p.eol", "--model", "Bank=a.xmi", "--target", "Bank=b.xmi"],
        ["p.eol", "--model", "Bank=a.xmi", "--store", "Ledger"],
        ["p.eol", "--param", "reader"],
        ["p.eol", "--param", "for=1"],
        ["p.eol", "--max-call-depth", "0"],
        ["p.eol", "--max-call-depth", "deep"],
        ["p.eol", "--config", "c.json", "--no-config"],
        ["p.eol", "--encoding", "klingon"],
    ])
    func invalidCommandLines(arguments: [String]) {
        #expect(throws: (any Error).self) { try EOLRunCommand.parse(arguments) }
    }

    @Test("The checks of a command line exit with the status of a usage error")
    func usageStatus() {
        do {
            _ = try EOLRunCommand.parse(["p.eol", "--model", "1Bank=bank.xmi"])
            Issue.record("The command line was accepted")
        } catch {
            #expect(EOLRunCommand.exitCode(for: error) == ExitCode.validationFailure)
            #expect(EOLRunCommand.message(for: error).contains("Invalid model name '1Bank'"))
        }
    }

    @Test("evl validate takes the fix and strict flags")
    func evlValidate() throws {
        let command = try EVLValidateCommand.parse(["rules.evl", "--model", "Bank=bank.xmi", "--fix", "--strict", "--store", "Bank=r.xmi"])
        #expect(command.constraints == "rules.evl")
        #expect(command.fix)
        #expect(command.strict)
        #expect(command.modelOptions.stores == ["Bank=r.xmi"])
        let plain = try EVLValidateCommand.parse(["rules.evl"])
        #expect(!plain.fix)
        #expect(!plain.strict)
        #expect(throws: (any Error).self) { try EVLValidateCommand.parse(["rules.evl", "--target", "L=l.xmi"]) }
    }

    @Test("etl transform takes targets, the trace flag and the reference style")
    func etlTransform() throws {
        let command = try ETLTransformCommand.parse([
            "t.etl", "--model", "Bank=bank.xmi", "--target", "Ledger=l.xmi", "--trace", "--reference-style", "plain",
        ])
        #expect(command.transformation == "t.etl")
        #expect(command.targetOptions.targets == ["Ledger=l.xmi"])
        #expect(command.trace)
        #expect(command.modelOptions.referenceStyleOptions.referenceStyle == .plain)
        #expect(!(try ETLTransformCommand.parse(["t.etl"])).trace)
    }

    @Test("egl generate takes an output and the flags of templates and EGX modules")
    func eglGenerate() throws {
        let template = try EGLGenerateCommand.parse(["a.egl", "-o", "a.txt", "--no-merge"])
        #expect(template.template == "a.egl")
        #expect(template.output == "a.txt")
        #expect(template.noMerge)
        #expect(!template.isCoordination)
        let coordination = try EGLGenerateCommand.parse(["a.EGX", "--output", "out", "--allow-outside-output"])
        #expect(coordination.isCoordination)
        #expect(coordination.output == "out")
        #expect(coordination.allowOutsideOutput)
        #expect(throws: (any Error).self) { try EGLGenerateCommand.parse(["a.egx", "--no-merge"]) }
        #expect(throws: (any Error).self) { try EGLGenerateCommand.parse(["a.egl", "--allow-outside-output"]) }
        #expect(throws: (any Error).self) { try EGLGenerateCommand.parse(["a.egl", "--target", "L=l.xmi"]) }
    }

    @Test("A configuration resolves the options of a command line")
    func configuration() throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let command = try EOLRunCommand.parse([
            "p.eol", "--model", "Bank=bank.xmi", "--target", "Ledger=l.xmi", "--store", "Bank", "-m", "Bank.ecore",
            "--param", "n=3", "--max-call-depth", "9", "-v", "--reference-style", "plain", "--container-scope",
            "this-resource", "--encoding", "windows-1252", "--km3-primitives", "declared",
        ])
        let configuration = try RunConfiguration(
            models: command.modelOptions, execution: command.executionOptions, targets: command.targetOptions.targets,
            environment: [:], currentDirectory: directory)
        #expect(configuration.plan.sources == [ModelBinding(name: "Bank", path: "bank.xmi")])
        #expect(configuration.plan.targets == [ModelBinding(name: "Ledger", path: "l.xmi")])
        #expect(configuration.plan.stores == [StoreRequest(name: "Bank")])
        #expect(configuration.metamodels == ["Bank.ecore"])
        #expect(configuration.parameters == ["n": .integer(3)])
        #expect(configuration.maximumCallDepth == 9)
        #expect(configuration.verbose)
        #expect(configuration.encoding == .windows1252)
        #expect(configuration.settings.containerLookupScope == .thisResource)
        #expect(configuration.xmiOptions.referenceStyle == .plain)
        #expect(configuration.metamodelLoadOptions != EcoreLoadOptions())
    }

    @Test("A configuration takes the encoding from the configuration file unless the option is given")
    func configurationFile() throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try #"{ "encoding": "ISO-8859-1" }"#.write(
            to: directory.appendingPathComponent(".swift-modelling.json"), atomically: true, encoding: .utf8)
        let configured = try EOLRunCommand.parse(["p.eol"])
        #expect(
            try RunConfiguration(
                models: configured.modelOptions, execution: configured.executionOptions, environment: [:],
                currentDirectory: directory
            ).encoding == .isoLatin1)
        let ignored = try EOLRunCommand.parse(["p.eol", "--no-config"])
        #expect(
            try RunConfiguration(
                models: ignored.modelOptions, execution: ignored.executionOptions, environment: [:],
                currentDirectory: directory
            ).encoding == nil)
    }
}
