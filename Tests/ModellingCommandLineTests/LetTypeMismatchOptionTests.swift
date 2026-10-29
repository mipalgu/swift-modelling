//
// LetTypeMismatchOptionTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import EMFBase
import MTL
import ModellingCommandLine
import ModellingGenerators
import Testing

@Suite("Typed let mismatch option and generation warnings")
struct LetTypeMismatchOptionTests {
    @Test("treats mismatches as errors unless told otherwise")
    func defaultIsError() throws {
        let options = try LetTypeMismatchOptions.parse([])
        #expect(options.letTypeMismatches == .error)
    }

    @Test("parses each mode by its spelling", arguments: MTLLetTypeMismatches.allCases)
    func parsesModes(mode: MTLLetTypeMismatches) throws {
        let options = try LetTypeMismatchOptions.parse(["--\(LetTypeMismatchOptions.optionName)", mode.rawValue])
        #expect(options.letTypeMismatches == mode)
    }

    @Test("rejects a value that is not a mode")
    func rejectsUnknownMode() {
        #expect(throws: (any Error).self) {
            try LetTypeMismatchOptions.parse(["--\(LetTypeMismatchOptions.optionName)", "sometimes"])
        }
    }

    @Test("names the option and its values")
    func names() {
        #expect(LetTypeMismatchOptions.optionName == "let-type-mismatches")
        #expect(LetTypeMismatchOptions.valueList == "error|skip")
        let discussion = LetTypeMismatchOptions.discussion(reader: "the templates")
        #expect(discussion.contains("--let-type-mismatches"))
        #expect(discussion.contains("the templates"))
        #expect(discussion.contains("Acceleo"))
    }

    @Test("copies the mode to generation options")
    func appliesToGenerationOptions() throws {
        let options = try LetTypeMismatchOptions.parse(["--\(LetTypeMismatchOptions.optionName)", "skip"])
        var generation = GenerationOptions()
        options.apply(to: &generation)
        #expect(generation.letTypeMismatches == .skip)
    }

    @Test("reports each distinct warning once with its position")
    func warningLines() {
        let range = SourceRange(
            start: SourcePosition(utf8Offset: 10, line: 3, column: 5),
            end: SourcePosition(utf8Offset: 20, line: 3, column: 15))
        let located = SourceDiagnostic(severity: .warning, code: "mtl.letTypeMismatch", message: "first", range: range)
        let unlocated = SourceDiagnostic(severity: .warning, code: "mtl.letTypeMismatch", message: "second")

        let lines = GenerationWarningReport.lines(for: [located, unlocated, located])

        #expect(lines == ["warning: line 3, column 5: first", "warning: second"])
        #expect(GenerationWarningReport.lines(for: []).isEmpty)
    }
}
