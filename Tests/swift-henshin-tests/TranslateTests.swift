//
// TranslateTests.swift
// swift-henshin-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Henshin
import Testing

@testable import swift_henshin

/// Runs `swift-henshin translate` as a reader would.
@Suite("swift-henshin translate")
struct TranslateTests {
    @Test("An expression given as an argument is translated")
    func argument() async throws {
        let run = try await runSwiftHenshin(["translate", "n > 0 && s.length < 5", "--variables", "n,s"])
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == "((n > 0) and (s.size() < 5))\n")
    }

    @Test("An expression given with the option takes repeated variables, and --verbose describes it")
    func option() async throws {
        let run = try await runSwiftHenshin(
            ["translate", "-e", "a / b", "--variables", "a", "--variables", " b ", "--verbose"])
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == "((a * 1.0) / b)\nvariables: a, b\nform: query\n")
        let literal = try await runSwiftHenshin(["translate", "'text'", "-v"])
        #expect(literal.output == "'text'\nvariables: \nform: literal\n")
        let variable = try await runSwiftHenshin(["translate", "x", "--variables", "x", "-v"])
        #expect(variable.output == "x\nvariables: x\nform: variable\n")
    }

    @Test("--table prints every entry of the translation table")
    func table() async throws {
        let run = try await runSwiftHenshin(["translate", "--table"])
        #expect(run.succeeded, "\(run.error)")
        let lines = run.output.split(separator: "\n", omittingEmptySubsequences: false).dropLast()
        #expect(lines.count == JavaScriptTranslator.translationTable.count)
        #expect(lines.first == "42\t42\tinteger literal")
        #expect(lines.contains("a / b\t((a * 1.0) / b)\talways real division, as in JavaScript"))
    }

    @Test(
        "Untranslatable expressions are errors with the reason",
        arguments: [
            ("x + 1", "Cannot translate 'x + 1': 'x' is not a parameter of the unit"),
            ("a = 1", "Cannot translate 'a = 1': "),
            ("new Date()", "Cannot translate 'new Date()': "),
        ])
    func errors(expression: String, message: String) async throws {
        let run = try await runSwiftHenshin(["translate", expression, "--variables", "a"])
        #expect(run.status == 1)
        #expect(run.error.contains(message), "\(run.error)")
    }

    @Test(
        "The command line names exactly one thing to do",
        arguments: [["translate"], ["translate", "a", "-e", "b"], ["translate", "--table", "a"]])
    func usage(arguments: [String]) async throws {
        let run = try await runSwiftHenshin(arguments)
        #expect(run.status == ExitCode.validationFailure.rawValue)
    }

    @Test("Names of list options are split at commas")
    func names() {
        #expect(NameList.names(["a,b", " c ", "", "d,,e"]) == ["a", "b", "c", "d", "e"])
        #expect([Int]().nilIfEmpty == nil)
        #expect([1].nilIfEmpty == [1])
    }

    @Test("Translation reports the reason of the translator")
    func translation() throws {
        #expect(try TranslateCommand.translate("a + 1", variables: ["a"]).aql == "(a + 1)")
        #expect(throws: SwiftHenshinError.untranslatable("b", "'b' is not a parameter of the unit")) {
            try TranslateCommand.translate("b", variables: ["a"])
        }
        #expect(TranslateCommand.describe(.query) == "query")
        #expect(TranslateCommand.tableLines().count == JavaScriptTranslator.translationTable.count)
    }
}
