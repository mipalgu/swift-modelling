//
// EndToEndTests.swift
// swift-epsilon-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Runs the built swift-epsilon executable as a reader would.
@Suite("swift-epsilon end to end", .serialized)
struct EndToEndTests {
    /// The warning that a source file was read as ISO-8859-1.
    static let fallbackWarning = "The text is not valid UTF-8 and was read as ISO-8859-1"

    @Test("The help lists the command groups and the version is reported")
    func help() async throws {
        let run = try await runSwiftEpsilon(["--help"])
        #expect(run.succeeded)
        for group in ["eol", "evl", "etl", "egl"] { #expect(run.output.contains(group), "\(group)") }
        let version = try await runSwiftEpsilon(["--version"])
        #expect(version.output == "0.7.0\n")
        let group = try await runSwiftEpsilon(["evl", "--help"])
        #expect(group.output.contains("validate"))
    }

    @Test("The help of every subcommand describes its options and exit statuses", arguments: [
        (["eol", "run"], ["--model", "--target", "--store", "--param", "--max-call-depth", "--metamodel", "--encoding", "--verbose", "status 64"]),
        (["evl", "validate"], ["--fix", "--strict", "--store", "status 2", "critique"]),
        (["etl", "transform"], ["--target", "--trace", "--reference-style", "Bank!Account"]),
        (["egl", "generate"], ["--output", "--no-merge", "--allow-outside-output", "protected regions", "not written"]),
    ])
    func subcommandHelp(command: [String], phrases: [String]) async throws {
        let run = try await runSwiftEpsilon(command + ["--help"])
        #expect(run.succeeded)
        let text = run.output.replacingOccurrences(of: "\n", with: " ").split(separator: " ").joined(separator: " ")
        for phrase in phrases { #expect(text.contains(phrase), "\(phrase) is missing from the help of \(command)") }
    }

    @Test("eol run prints the output of a program on standard output")
    func eolRun() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftEpsilon(["eol", "run", "report.eol"] + bankArguments, in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == "Alice: 120\nBob: -30\n: 0\n")
        #expect(run.error.isEmpty, "\(run.error)")
    }

    @Test("eol run passes typed parameters and binds aliases")
    func eolParameters() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftEpsilon(
            ["eol", "run", "greeting.eol", "--model", "Bank,Money=bank.xmi", "-m", "Bank.ecore",
             "--param", "greeting=Hello", "--param", "reader=Alice", "--param", "factor=2.5"], in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == "Hello, Alice!\n7.5\n")
        try "Money!Account.all.size().println();".write(
            to: directory.appendingPathComponent("alias.eol"), atomically: true, encoding: .utf8)
        let alias = try await runSwiftEpsilon(
            ["eol", "run", "alias.eol", "--model", "Bank,Money=bank.xmi", "-m", "Bank.ecore"], in: directory)
        #expect(alias.output == "3\n", "\(alias.error)")
    }

    @Test("eol run creates and stores target models, and stores a changed model")
    func eolStore() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let summary = try await runSwiftEpsilon(
            ["eol", "run", "summary.eol", "--target", "Ledger=out/ledger.xmi"] + bankArguments, in: directory)
        #expect(summary.succeeded, "\(summary.error)")
        #expect(summary.output.isEmpty)
        let ledger = try String(contentsOf: directory.appendingPathComponent("out/ledger.xmi"), encoding: .utf8)
        #expect(ledger.contains("title=\"Summary\""))
        #expect(ledger.contains("label=\"cheque\" overdrawn=\"true\""))

        let deposit = try await runSwiftEpsilon(["eol", "run", "deposit.eol", "--store", "Bank"] + bankArguments, in: directory)
        #expect(deposit.succeeded, "\(deposit.error)")
        let bank = try String(contentsOf: directory.appendingPathComponent(Fixture.bankModel), encoding: .utf8)
        #expect(bank.contains("balance=\"130\""))
        #expect(bank.contains("balance=\"-30\""))
    }

    @Test("A model is not written unless it is stored, and nothing is stored after a failure")
    func noStore() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let original = try String(contentsOf: directory.appendingPathComponent(Fixture.bankModel), encoding: .utf8)
        let run = try await runSwiftEpsilon(["eol", "run", "deposit.eol"] + bankArguments, in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(try String(contentsOf: directory.appendingPathComponent(Fixture.bankModel), encoding: .utf8) == original)
        let failed = try await runSwiftEpsilon(
            ["eol", "run", "failing.eol", "--target", "Ledger=ledger.xmi"] + bankArguments, in: directory)
        #expect(failed.status == 1)
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("ledger.xmi").path))
    }

    @Test("eol run reports the errors of a program on standard error with status 1")
    func eolErrors() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let failing = try await runSwiftEpsilon(["eol", "run", "failing.eol"], in: directory)
        #expect(failing.status == 1)
        #expect(failing.output == "before\n")
        #expect(failing.error.contains("failing.eol:2:1: The ledger is closed"), "\(failing.error)")

        let invalid = try await runSwiftEpsilon(["eol", "run", "invalid.eol"], in: directory)
        #expect(invalid.status == 1)
        #expect(invalid.error.contains("error: invalid.eol: line 1, column 9: Expected an expression but found ';'"), "\(invalid.error)")
        #expect(invalid.error.contains("invalid.eol has 1 syntax error"))

        let missing = try await runSwiftEpsilon(["eol", "run", "missing.eol"], in: directory)
        #expect(missing.status == 1)
        #expect(missing.error.contains("Source file not found or not readable: missing.eol"))

        let model = try await runSwiftEpsilon(["eol", "run", "report.eol", "--model", "Bank=missing.xmi"], in: directory)
        #expect(model.status == 1)
        #expect(model.error.contains("Model file not found: missing.xmi"))

        let depth = try await runSwiftEpsilon(["eol", "run", "recursion.eol", "--max-call-depth", "5"], in: directory)
        #expect(depth.status == 1)
        #expect(depth.error.contains("nested more than 5 levels deep"), "\(depth.error)")
        let deep = try await runSwiftEpsilon(["eol", "run", "recursion.eol"], in: directory)
        #expect(deep.output == "0\n", "\(deep.error)")
    }

    @Test("Invalid command lines exit with status 64", arguments: [
        ["eol", "run", "report.eol", "--model", "bank.xmi"],
        ["eol", "run", "report.eol", "--model", "Bank=a.xmi", "--model", "Bank=b.xmi"],
        ["eol", "run", "report.eol", "--store", "Ledger"],
        ["eol", "run", "report.eol", "--param", "for=1"],
        ["eol", "run", "report.eol", "--max-call-depth", "0"],
        ["evl", "validate"],
        ["egl", "generate", "accounts.egx", "--no-merge"],
        ["egl", "generate", "accounts.egl", "--allow-outside-output"],
    ])
    func usageErrors(arguments: [String]) async throws {
        let run = try await runSwiftEpsilon(arguments)
        #expect(run.status == 64, "\(run.error)")
        #expect(run.output.isEmpty)
    }

    @Test("A target needs a metamodel, and a model without one is reported with a hint")
    func metamodels() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let target = try await runSwiftEpsilon(
            ["eol", "run", "summary.eol", "--model", "Bank=bank.xmi", "--target", "Ledger=l.xmi"], in: directory)
        #expect(target.status == 1)
        #expect(target.error.contains("The target model 'Ledger' needs a metamodel"), "\(target.error)")
        let untyped = try await runSwiftEpsilon(["eol", "run", "report.eol", "--model", "Bank=bank.xmi"], in: directory)
        #expect(untyped.status == 1)
        #expect(untyped.error.contains("hint: give the metamodel of the model with --metamodel"), "\(untyped.error)")
    }

    @Test("A metamodel can be the model of a program")
    func metamodelAsModel() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        try "EClass.all.collect(c | c.name).println();".write(
            to: directory.appendingPathComponent("classes.eol"), atomically: true, encoding: .utf8)
        let run = try await runSwiftEpsilon(["eol", "run", "classes.eol", "--model", "MM=Bank.ecore"], in: directory)
        #expect(run.output == "Sequence {Bank, Account}\n", "\(run.error)")
    }

    @Test("--verbose reports each step on standard error only")
    func verbose() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftEpsilon(
            ["eol", "run", "summary.eol", "--target", "Ledger=ledger.json", "-v"] + bankArguments, in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output.isEmpty)
        for phrase in ["Loading metamodel Bank.ecore", "Loaded model Bank from bank.xmi (4 objects)",
                       "Created target model Ledger", "Running summary.eol", "Stored model Ledger in ledger.json"] {
            #expect(run.error.contains(phrase), "\(phrase) is missing from: \(run.error)")
        }
        let json = try String(contentsOf: directory.appendingPathComponent("ledger.json"), encoding: .utf8)
        #expect(json.contains("\"eClass\" : \"http://www.example.org/ledger#//Ledger\""))
    }

    @Test("Source files that are not UTF-8 are read as ISO-8859-1 with a warning, or in the encoding given")
    func encodings() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("// Grüße\n'Größe'.println();\n".unicodeScalars.map { UInt8($0.value) })
            .write(to: directory.appendingPathComponent("latin1.eol"))
        let fallback = try await runSwiftEpsilon(["eol", "run", "latin1.eol"], in: directory)
        #expect(fallback.succeeded, "\(fallback.error)")
        #expect(fallback.output == "Größe\n")
        #expect(fallback.error.contains("warning: latin1.eol: line 1, column 6: \(Self.fallbackWarning)"), "\(fallback.error)")

        let explicit = try await runSwiftEpsilon(["eol", "run", "latin1.eol", "--encoding", "ISO-8859-1"], in: directory)
        #expect(explicit.output == "Größe\n")
        #expect(explicit.error.isEmpty, "\(explicit.error)")

        let strict = try await runSwiftEpsilon(["eol", "run", "latin1.eol", "--encoding", "UTF-8"], in: directory)
        #expect(strict.status == 1)
        #expect(strict.error.contains("not valid UTF-8"), "\(strict.error)")

        try #"{ "encoding": "latin1" }"#.write(
            to: directory.appendingPathComponent("epsilon.json"), atomically: true, encoding: .utf8)
        let configured = try await runSwiftEpsilon(["eol", "run", "latin1.eol", "--config", "epsilon.json"], in: directory)
        #expect(configured.output == "Größe\n")
        #expect(configured.error.isEmpty, "\(configured.error)")
    }

    @Test("evl validate prints the results and exits with status 2 when a constraint is unsatisfied")
    func evlValidate() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftEpsilon(["evl", "validate", "rules.evl"] + bankArguments, in: directory)
        #expect(run.status == 2, "\(run.error)")
        #expect(
            run.output == """
                error: constraint NotOverdrawn on Account(cheque): Account cheque is overdrawn by 30
                  fix: Clear the balance of cheque
                warning: critique HasOwner on Account(holiday): Account holiday has no owner
                1 error, 1 warning

                """)
        let valid = try await runSwiftEpsilon(["evl", "validate", "valid.evl"] + bankArguments, in: directory)
        #expect(valid.succeeded, "\(valid.error)")
        #expect(valid.output == "All constraints are satisfied\n")
    }

    @Test("Critiques fail validation only with --strict")
    func evlStrict() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let lenient = try await runSwiftEpsilon(["evl", "validate", "critiques.evl"] + bankArguments, in: directory)
        #expect(lenient.status == 0, "\(lenient.error)")
        #expect(lenient.output.hasSuffix("0 errors, 1 warning\n"))
        let strict = try await runSwiftEpsilon(["evl", "validate", "critiques.evl", "--strict"] + bankArguments, in: directory)
        #expect(strict.status == 2)
    }

    @Test("evl validate applies fixes and stores the repaired model")
    func evlFix() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftEpsilon(
            ["evl", "validate", "rules.evl", "--fix", "--store", "Bank=repaired.xmi"] + bankArguments, in: directory)
        #expect(run.status == 0, "\(run.error)")
        #expect(
            run.output == """
                applied: Clear the balance of cheque
                warning: critique HasOwner on Account(holiday): Account holiday has no owner
                0 errors, 1 warning

                """)
        let repaired = try String(contentsOf: directory.appendingPathComponent("repaired.xmi"), encoding: .utf8)
        #expect(repaired.contains("name=\"cheque\" owner=\"Bob\" balance=\"0\""))
        let again = try await runSwiftEpsilon(
            ["evl", "validate", "rules.evl", "--model", "Bank=repaired.xmi", "-m", "Bank.ecore"], in: directory)
        #expect(again.status == 0, "\(again.output)")
    }

    @Test("evl validate stores a model even when validation fails")
    func evlStoreOnFailure() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftEpsilon(
            ["evl", "validate", "rules.evl", "--store", "Bank=copy.xmi"] + bankArguments, in: directory)
        #expect(run.status == 2)
        #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("copy.xmi").path))
    }

    @Test("evl validate reports an error of the module with status 1")
    func evlError() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        try "context Unknown { constraint C { check : true } }".write(
            to: directory.appendingPathComponent("unknown.evl"), atomically: true, encoding: .utf8)
        let run = try await runSwiftEpsilon(["evl", "validate", "unknown.evl"] + bankArguments, in: directory)
        #expect(run.status == 1)
        #expect(run.error.contains("unknown.evl:1:"), "\(run.error)")
        #expect(run.output.isEmpty)
    }

    @Test("etl transform writes the target models and prints the trace on request")
    func etlTransform() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let quiet = try await runSwiftEpsilon(
            ["etl", "transform", "bank2ledger.etl", "--target", "Ledger=ledger.xmi"] + bankArguments, in: directory)
        #expect(quiet.succeeded, "\(quiet.error)")
        #expect(quiet.output.isEmpty)
        let xmi = try String(contentsOf: directory.appendingPathComponent("ledger.xmi"), encoding: .utf8)
        #expect(xmi.contains("<ledger:Ledger"))
        #expect(xmi.contains("title=\"River Bank\""))
        #expect(xmi.contains("label=\"Bob (cheque)\" overdrawn=\"true\""))

        let traced = try await runSwiftEpsilon(
            ["etl", "transform", "bank2ledger.etl", "--target", "Ledger=ledger.json", "--trace", "--reference-style", "plain"]
                + bankArguments, in: directory)
        #expect(traced.succeeded, "\(traced.error)")
        #expect(
            traced.output == """
                Bank2Ledger: Bank(River Bank) -> Ledger
                Account2Entry: Account(savings) -> Entry
                Account2Entry: Account(cheque) -> Entry
                Account2Entry: Account(holiday) -> Entry

                """)
        let json = try String(contentsOf: directory.appendingPathComponent("ledger.json"), encoding: .utf8)
        #expect(json.contains("\"label\" : \"Alice (savings)\""))
    }

    @Test("etl transform reports a failing transformation with status 1 and stores nothing")
    func etlError() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftEpsilon(
            ["etl", "transform", "bank2ledger.etl", "--model", "Bank=bank.xmi", "-m", "Bank.ecore"], in: directory)
        #expect(run.status == 1)
        #expect(run.error.contains("bank2ledger.etl:"), "\(run.error)")
    }

    @Test("egl generate renders a template to standard output or a file")
    func eglTemplate() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let text = "Accounts of River Bank\n- savings: 120\n- cheque: -30\n- holiday: 0\n"
        let stdout = try await runSwiftEpsilon(
            ["egl", "generate", "accounts.egl", "--param", "title=Accounts"] + bankArguments, in: directory)
        #expect(stdout.succeeded, "\(stdout.error)")
        #expect(stdout.output == text)

        let file = try await runSwiftEpsilon(
            ["egl", "generate", "accounts.egl", "--param", "title=Accounts", "-o", "out/accounts.txt"] + bankArguments,
            in: directory)
        #expect(file.output == "created: out/accounts.txt\n", "\(file.error)")
        #expect(try String(contentsOf: directory.appendingPathComponent("out/accounts.txt"), encoding: .utf8) == text)
        let again = try await runSwiftEpsilon(
            ["egl", "generate", "accounts.egl", "--param", "title=Accounts", "--output", "out/accounts.txt"] + bankArguments,
            in: directory)
        #expect(again.output == "unchanged: out/accounts.txt\n")
    }

    @Test("egl generate keeps protected regions unless --no-merge is given")
    func eglProtectedRegions() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        try "[%= Bank.all.first().name %]\n[%= out.preserve('//', '', 'notes', true, 'none') %]\n".write(
            to: directory.appendingPathComponent("notes.egl"), atomically: true, encoding: .utf8)
        let arguments = ["egl", "generate", "notes.egl", "-o", "notes.txt"] + bankArguments
        #expect(try await runSwiftEpsilon(arguments, in: directory).output == "created: notes.txt\n")
        let path = directory.appendingPathComponent("notes.txt")
        let edited = try String(contentsOf: path, encoding: .utf8).replacingOccurrences(of: "\nnone\n", with: "\nmy notes\n")
        try edited.write(to: path, atomically: true, encoding: .utf8)
        let merged = try await runSwiftEpsilon(arguments, in: directory)
        #expect(merged.output == "unchanged: notes.txt\n", "\(merged.error)")
        #expect(try String(contentsOf: path, encoding: .utf8).contains("my notes"))
        let replaced = try await runSwiftEpsilon(arguments + ["--no-merge"], in: directory)
        #expect(replaced.output == "updated: notes.txt\n")
        #expect(!(try String(contentsOf: path, encoding: .utf8)).contains("my notes"))
    }

    @Test("egl generate runs EGX rules that write files below the output directory")
    func egx() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftEpsilon(["egl", "generate", "accounts.egx", "--output", "generated"] + bankArguments, in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == "created: accounts/savings.txt\ncreated: accounts/cheque.txt\ncreated: accounts/holiday.txt\n")
        let savings = try String(contentsOf: directory.appendingPathComponent("generated/accounts/savings.txt"), encoding: .utf8)
        #expect(savings == "Account savings\nOwner: Alice\nBalance: 120\n")

        let here = try await runSwiftEpsilon(["egl", "generate", "accounts.egx"] + bankArguments, in: directory)
        #expect(here.succeeded, "\(here.error)")
        #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("accounts/holiday.txt").path))
        let again = try await runSwiftEpsilon(["egl", "generate", "accounts.egx", "-o", "generated"] + bankArguments, in: directory)
        #expect(again.output.hasPrefix("unchanged: accounts/savings.txt\n"))
    }

    @Test("EGX rules write outside the output directory only with --allow-outside-output")
    func egxConfinement() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        try """
            rule Escape transform account : Account {
              guard : account.name = 'savings'
              parameters : Map{"account" = account}
              template : "account.egl"
            target : "../escaped.txt"
            }
            rule Preview transform account : Account {
              guard : account.name = 'cheque'
              parameters : Map{"account" = account}
              template : "account.egl"
            }
            """.write(to: directory.appendingPathComponent("escape.egx"), atomically: true, encoding: .utf8)
        let confined = try await runSwiftEpsilon(["egl", "generate", "escape.egx", "-o", "out"] + bankArguments, in: directory)
        #expect(confined.status == 1)
        #expect(confined.error.contains("leads outside the output directory"), "\(confined.error)")
        let allowed = try await runSwiftEpsilon(
            ["egl", "generate", "escape.egx", "-o", "out", "--allow-outside-output"] + bankArguments, in: directory)
        #expect(allowed.succeeded, "\(allowed.error)")
        #expect(allowed.output == "created: ../escaped.txt\nnot written: Preview\n")
        #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("escaped.txt").path))
    }

    @Test("egl generate reports a failing template with status 1")
    func eglError() async throws {
        let directory = try Fixture.bankDirectoryCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftEpsilon(["egl", "generate", "accounts.egl"] + bankArguments, in: directory)
        #expect(run.status == 1)
        #expect(run.error.contains("accounts.egl:1:"), "\(run.error)")
        let output = try await runSwiftEpsilon(["egl", "generate", "accounts.egx", "-o", "bank.xmi"] + bankArguments, in: directory)
        #expect(output.status == 1)
        #expect(output.error.contains("must be a directory"), "\(output.error)")
    }
}
