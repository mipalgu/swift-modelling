//
// LanguageRunTests.swift
// swift-epsilon-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EGL
import EOL
import Foundation
import Testing

@testable import swift_epsilon

/// Tests how programs of each Epsilon language run against the models of a workspace.
@Suite("Running the Epsilon languages")
struct LanguageRunTests {
    @Test("An EOL program prints to its output")
    func eol() async throws {
        let output = EOLStringOutput()
        try await EOLRun.run(program: try Fixture.bank("report.eol").path, workspace: try await bankWorkspace(), output: output)
        #expect(output.text == "Alice: 120\nBob: -30\n: 0\n")
    }

    @Test("An EOL program reads the parameters as global variables")
    func eolParameters() async throws {
        let output = EOLStringOutput()
        let workspace = try await bankWorkspace(
            parameters: ["greeting": .string("Hello"), "reader": .string("Alice"), "factor": .integer(2)])
        try await EOLRun.run(program: try Fixture.bank("greeting.eol").path, workspace: workspace, output: output)
        #expect(output.text == "Hello, Alice!\n6\n")
    }

    @Test("An EOL program stops at the call depth limit")
    func eolCallDepth() async throws {
        var configuration = RunConfiguration(plan: try ModelPlan(sources: []))
        let program = try Fixture.bank("recursion.eol").path
        let output = EOLStringOutput()
        try await EOLRun.run(program: program, workspace: try await ModelWorkspace.load(configuration), output: output)
        #expect(output.text == "0\n")
        configuration.maximumCallDepth = 5
        let limit = configuration
        await #expect(throws: EOLError.self) {
            try await EOLRun.run(program: program, workspace: try await ModelWorkspace.load(limit), output: EOLStringOutput())
        }
    }

    @Test("An error that an EOL program raises is located in the program")
    func eolError() async throws {
        let program = try Fixture.bank("failing.eol").path
        let output = EOLStringOutput()
        do {
            try await EOLRun.run(program: program, workspace: try await bankWorkspace(), output: output)
            Issue.record("The program did not fail")
        } catch let error as EOLError {
            #expect(error.description == program + ":2:1: The ledger is closed")
        }
        #expect(output.text == "before\n")
    }

    @Test("EVL reports unsatisfied constraints as errors and critiques as warnings, with their fixes")
    func evl() async throws {
        let outcome = try await EVLRun.validate(
            constraints: try Fixture.bank("rules.evl").path, workspace: try await bankWorkspace())
        #expect(outcome.errorCount == 1)
        #expect(outcome.warningCount == 1)
        #expect(outcome.applied.isEmpty)
        #expect(
            outcome.findings == [
                ValidationFinding(
                    isCritique: false, constraint: "NotOverdrawn", context: "Account", element: "Account(cheque)",
                    message: "Account cheque is overdrawn by 30", fixes: ["Clear the balance of cheque"]),
                ValidationFinding(
                    isCritique: true, constraint: "HasOwner", context: "Account", element: "Account(holiday)",
                    message: "Account holiday has no owner", fixes: []),
            ])
        #expect(
            outcome.lines == [
                "error: constraint NotOverdrawn on Account(cheque): Account cheque is overdrawn by 30",
                "  fix: Clear the balance of cheque",
                "warning: critique HasOwner on Account(holiday): Account holiday has no owner",
                "1 error, 1 warning",
            ])
        #expect(outcome.fails(strict: false))
        #expect(outcome.fails(strict: true))
    }

    @Test("Critiques fail validation only when it is strict")
    func evlCritiques() async throws {
        let outcome = try await EVLRun.validate(
            constraints: try Fixture.bank("critiques.evl").path, workspace: try await bankWorkspace())
        #expect(outcome.lines.last == "0 errors, 1 warning")
        #expect(!outcome.fails(strict: false))
        #expect(outcome.fails(strict: true))
    }

    @Test("Satisfied constraints are reported as such")
    func evlValid() async throws {
        let outcome = try await EVLRun.validate(constraints: try Fixture.bank("valid.evl").path, workspace: try await bankWorkspace())
        #expect(outcome.findings.isEmpty)
        #expect(outcome.lines == ["All constraints are satisfied"])
        #expect(!outcome.fails(strict: true))
    }

    @Test("Fixes are applied and the models validated again")
    func evlFix() async throws {
        let workspace = try await bankWorkspace()
        let outcome = try await EVLRun.validate(
            constraints: try Fixture.bank("rules.evl").path, workspace: workspace, applyingFixes: true)
        #expect(outcome.applied == ["Clear the balance of cheque"])
        #expect(outcome.errorCount == 0)
        #expect(outcome.warningCount == 1)
        #expect(outcome.lines.first == "applied: Clear the balance of cheque")
        let output = EOLStringOutput()
        try await workspace.makeInterpreter(output: output).run(
            EOLSyntax.parse("Account.all.collect(a | a.balance).println();").get())
        #expect(output.text == "Sequence {120, 0, 0}\n")
    }

    @Test("An ETL transformation fills the target model and returns its trace")
    func etl() async throws {
        let workspace = try await bankWorkspace(targets: ["Ledger=ledger.xmi"])
        let entries = try await ETLRun.transform(transformation: try Fixture.bank("bank2ledger.etl").path, workspace: workspace)
        #expect(
            entries.map(\.line) == [
                "Bank2Ledger: Bank(River Bank) -> Ledger",
                "Account2Entry: Account(savings) -> Entry",
                "Account2Entry: Account(cheque) -> Entry",
                "Account2Entry: Account(holiday) -> Entry",
            ])
        let output = EOLStringOutput()
        try await workspace.makeInterpreter(output: output).run(
            EOLSyntax.parse("Ledger!Ledger.all.first().entries.collect(e | e.label + '=' + e.overdrawn).println();").get())
        #expect(output.text == "Sequence {Alice (savings)=false, Bob (cheque)=true,  (holiday)=false}\n")
    }

    @Test("A trace entry joins several targets")
    func traceLine() {
        #expect(TraceEntry(rule: "R", source: "A(x)", targets: ["B", "C(y)"]).line == "R: A(x) -> B, C(y)")
    }

    @Test("An EGL template renders with the parameters as variables")
    func egl() async throws {
        let workspace = try await bankWorkspace(parameters: ["title": .string("Accounts")])
        let text = try await EGLRun.render(template: try Fixture.bank("accounts.egl").path, workspace: workspace)
        #expect(text == "Accounts of River Bank\n- savings: 120\n- cheque: -30\n- holiday: 0\n")
    }

    @Test("An EGX module is recognised by its extension")
    func coordination() {
        #expect(EGLRun.isCoordination("rules.egx"))
        #expect(EGLRun.isCoordination("dir/RULES.EGX"))
        #expect(!EGLRun.isCoordination("accounts.egl"))
        #expect(!EGLRun.isCoordination("egx"))
    }

    @Test("Generated text keeps the protected regions of an existing file unless merging is off")
    func write() throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("out/notes.txt").path
        let generated = "head\n// protected region notes on begin\nnone\n// protected region notes end\n"
        let created = try EGLRun.write(generated, to: path, merging: true)
        #expect(created.status == .created)
        #expect(try EGLRun.write(generated, to: path, merging: true).status == .unchanged)
        let edited = generated.replacingOccurrences(of: "none", with: "my notes")
        try edited.write(toFile: path, atomically: true, encoding: .utf8)
        let merged = try EGLRun.write(generated.replacingOccurrences(of: "head", with: "top"), to: path, merging: true)
        #expect(merged.status == .updated)
        #expect(try String(contentsOfFile: path, encoding: .utf8) == edited.replacingOccurrences(of: "head", with: "top"))
        let replaced = try EGLRun.write(generated, to: path, merging: false)
        #expect(replaced.status == .updated)
        #expect(try String(contentsOfFile: path, encoding: .utf8) == generated)
    }

    @Test("A lost protected region is reported")
    func lostRegion() throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("notes.txt").path
        try "// protected region old on begin\nkeep me\n// protected region old end\n".write(
            toFile: path, atomically: true, encoding: .utf8)
        let written = try EGLRun.write("plain\n", to: path, merging: true)
        #expect(written.status == .updated)
        #expect(written.diagnostics.count == 1)
        #expect(written.diagnostics.first?.severity == .warning)
    }

    @Test("EGX rules write their files below the output directory and report each one")
    func egx() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("generated").path
        var counts: [Int] = []
        let result = try await EGLRun.generate(
            coordination: try Fixture.bank("accounts.egx").path, workspace: try await bankWorkspace(),
            outputDirectory: output, allowsPathsOutsideOutput: false, progress: { counts.append($0) })
        #expect(result.files.map(\.path) == ["accounts/savings.txt", "accounts/cheque.txt", "accounts/holiday.txt"])
        #expect(result.files.allSatisfy { $0.status == .created })
        #expect(counts == [1, 2, 3])
        let cheque = try String(contentsOfFile: output + "/accounts/cheque.txt", encoding: .utf8)
        #expect(cheque == "Account cheque\nOwner: Bob\nBalance: -30\n")
        let again = try await EGLRun.generate(
            coordination: try Fixture.bank("accounts.egx").path, workspace: try await bankWorkspace(),
            outputDirectory: output, allowsPathsOutsideOutput: false)
        #expect(again.files.allSatisfy { $0.status == .unchanged })
    }

    @Test("EGX rules may write outside the output directory only when allowed")
    func egxConfinement() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.copyItem(at: try Fixture.bank("account.egl"), to: directory.appendingPathComponent("account.egl"))
        let module = directory.appendingPathComponent("escape.egx").path
        try """
            rule Escape transform account : Account {
              guard : account.name = 'savings'
              parameters : Map{"account" = account}
              template : "account.egl"
              target : "../escaped.txt"
            }
            """.write(toFile: module, atomically: true, encoding: .utf8)
        let output = directory.appendingPathComponent("out").path
        await #expect(throws: EOLError.self) {
            _ = try await EGLRun.generate(
                coordination: module, workspace: try await bankWorkspace(), outputDirectory: output,
                allowsPathsOutsideOutput: false)
        }
        let result = try await EGLRun.generate(
            coordination: module, workspace: try await bankWorkspace(), outputDirectory: output,
            allowsPathsOutsideOutput: true)
        #expect(result.files.map(\.status) == [.created])
        #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("escaped.txt").path))
    }

    @Test("The output of an EGX module must be a directory")
    func egxOutputFile() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("file.txt").path
        try "x".write(toFile: file, atomically: true, encoding: .utf8)
        await #expect(throws: SwiftEpsilonError.outputNotDirectory(file)) {
            _ = try await EGLRun.generate(
                coordination: try Fixture.bank("accounts.egx").path, workspace: try await bankWorkspace(),
                outputDirectory: file, allowsPathsOutsideOutput: false)
        }
    }

    @Test("The status of a generated file is printed as a word")
    func statusWords() {
        let words = [EGXFileStatus.created, .updated, .unchanged, .skipped, .notWritten].map(SwiftEpsilonVocabulary.FileStatus.word(for:))
        #expect(words == ["created", "updated", "unchanged", "skipped", "not written"])
    }
}
