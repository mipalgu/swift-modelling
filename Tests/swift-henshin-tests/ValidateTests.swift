//
// ValidateTests.swift
// swift-henshin-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation
import Testing

@testable import swift_henshin

/// Runs `swift-henshin validate` as a reader would.
@Suite("swift-henshin validate")
struct ValidateTests {
    /// A Henshin Text module with an error and clean-up warnings.
    static let flawed = """
        ePackageImport depot

        rule lonely(IN unused:EInt, VAR ghost:EInt) {
        \tgraph {
        \t\tnode bin:Bin
        \t}
        }
        """

    /// A Henshin Text module with syntax errors.
    static let malformed = """
        ePackageImport depot

        rule bad( {
        \tgraph {
        \t\tnode bin:Bin
        \t}
        }
        """

    @Test("A clean module has no findings", arguments: [Fixture.module, Fixture.textModule])
    func clean(module: String) async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(["validate", module], in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == "\(module): 0 error(s), 0 warning(s)\n")
    }

    @Test("Errors and clean-up warnings are reported with their codes")
    func findings() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Fixture.write(Self.flawed, named: "flawed.henshin_text", in: directory)
        let run = try await runSwiftHenshin(["validate", "flawed.henshin_text"], in: directory)
        #expect(run.status == 1)
        #expect(
            run.output == """
                error: flawed.henshin_text: Rule 'lonely' never matches its VAR parameter 'ghost' in its left-hand side [henshin.var-parameter-not-in-lhs]
                warning: flawed.henshin_text: Rule 'lonely' declares parameter 'unused' but uses it nowhere [henshin.unused-parameter]
                warning: flawed.henshin_text: Rule 'lonely' declares parameter 'ghost' but uses it nowhere [henshin.unused-parameter]
                flawed.henshin_text: 1 error(s), 2 warning(s)

                """)
    }

    @Test("Syntax errors are reported with their positions")
    func syntaxErrors() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Fixture.write(Self.malformed, named: "bad.henshin_text", in: directory)
        let run = try await runSwiftHenshin(["validate", "bad.henshin_text"], in: directory)
        #expect(run.status == 1)
        #expect(run.output.hasPrefix(
            "error: bad.henshin_text: line 3, column 11: Expected a name of a parameter, found '{' [henshin-text.unexpected-token]\n"))
        #expect(run.output.hasSuffix("bad.henshin_text: 3 error(s), 0 warning(s)\n"))
        let apply = try await runSwiftHenshin(["apply", "bad.henshin_text", Fixture.model, "-u", "bad"], in: directory)
        #expect(apply.status == 1)
        #expect(apply.error.contains("error: bad.henshin_text: line 3, column 11: Expected a name of a parameter, found '{'\n"))
        #expect(apply.error.contains("bad.henshin_text is not valid Henshin Text (3 error(s))"))
    }

    @Test("Imports are checked against the metamodels")
    func imports() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let unused = try Fixture.read(Fixture.module, in: directory).replacingOccurrences(
            of: "<imports href=\"Depot.ecore#/\"/>", with: "")
        try Fixture.write(unused, named: "noimport.henshin", in: directory)
        let run = try await runSwiftHenshin(["validate", "noimport.henshin", "-m", Fixture.metamodel], in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output.contains(
            "warning: noimport.henshin: The module uses classes of the package 'http://example.org/depot' without importing it [henshin.missing-import]"))
    }

    @Test("A missing module is an error")
    func missing() async throws {
        let run = try await runSwiftHenshin(["validate", "missing.henshin_text"])
        #expect(run.status == 1)
        #expect(run.error.contains("File not found: missing.henshin_text"))
    }

    @Test("Findings are formatted with their severity, place and code")
    func formatting() {
        let range = SourceRange(start: SourcePosition(utf8Offset: 10, line: 2, column: 3), end: SourcePosition(utf8Offset: 11, line: 2, column: 4))
        let error = SourceDiagnostic(severity: .error, code: "x.y", message: "Bad", range: range)
        let note = SourceDiagnostic(severity: .information, code: "x.z", message: "Fine")
        #expect(FindingFormatter.line(error, file: "m.henshin") == "error: m.henshin: line 2, column 3: Bad [x.y]")
        #expect(FindingFormatter.line(note, file: "m.henshin") == "note: m.henshin: Fine [x.z]")
        #expect(FindingFormatter.summary([error, note], file: "m.henshin") == "m.henshin: 1 error(s), 0 warning(s)")
    }

    @Test("Informational findings are printed with --verbose")
    func verbose() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(["validate", Fixture.module, "--verbose"], in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.error.contains("note: reading the module depot.henshin\n"))
    }
}
