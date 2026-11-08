//
// AnalyseTests.swift
// swift-henshin-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Henshin
import HenshinAnalysis
import Testing

@testable import swift_henshin

/// Runs `swift-henshin analyse` as a reader would.
@Suite("swift-henshin analyse")
struct AnalyseTests {
    @Test("Conflicts are reported as a matrix and details", arguments: [Fixture.module, Fixture.textModule])
    func conflicts(module: String) async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(["analyse", module, "--rules", "addParcel,removeParcel"], in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output.hasPrefix("""
            Conflicts:
                         | 0 1
            addParcel    | . .
            removeParcel | . 1
            removeParcel conflicts with removeParcel: delete-use
              atoms: 1

            """))
        #expect(!run.output.contains("Dependencies:"))
    }

    @Test("Dependencies depend on the dangling condition")
    func dependencies() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let arguments = ["analyse", Fixture.module, "--rules", "addParcel", "--rules", "removeParcel", "--direction", "dependency"]
        let checked = try await runSwiftHenshin(arguments, in: directory)
        #expect(checked.succeeded, "\(checked.error)")
        #expect(checked.output.hasSuffix("removeParcel | . .\nnone\n"))
        let unchecked = try await runSwiftHenshin(arguments + ["--no-dangling-check", "--granularity", "critical-pairs"], in: directory)
        #expect(unchecked.succeeded, "\(unchecked.error)")
        #expect(unchecked.output.contains("addParcel enables removeParcel: produce-use\n"))
        #expect(unchecked.output.contains("  critical pairs: 1\n    produce-use (essential) RHS~LHS"))
    }

    @Test("Both directions are reported, conflicts first")
    func both() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(
            ["analyse", Fixture.module, "--rules", "move", "--direction", "both", "--granularity", "binary"], in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output == """
            Conflicts:
                 | 0
            move | x
            move conflicts with move: change-use
              note: the attribute conditions of move are ignored, which may report more interactions

            Dependencies:
                 | 0
            move | x
            move enables move: change-use
              note: the attribute conditions of move are ignored, which may report more interactions

            """)
    }

    @Test("Every rule is analysed by default, and JSON is available")
    func json() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(
            ["analyse", Fixture.module, "--format", "json", "--granularity", "atoms", "--essential", "--no-multiplicities"],
            in: directory)
        #expect(run.succeeded, "\(run.error)")
        let report = try JSONDecoder().decode(AnalysisReport.self, from: Data(run.output.utf8))
        #expect(report.granularity == "atoms")
        #expect(report.tables.map(\.direction) == ["conflict"])
        let rules = ["addParcel", "removeParcel", "move", "drain", "emptyBin", "clearBin", "touch"]
        #expect(report.tables[0].rules == rules)
        #expect(report.tables[0].pairs.count == rules.count * rules.count)
        let removal = try #require(report.tables[0].pairs.first { $0.first == "removeParcel" && $0.second == "removeParcel" })
        #expect(removal.interacts)
        #expect(removal.kinds == ["delete-use"])
        #expect(removal.atoms.count == 1)
        #expect(removal.minimalReasons.isEmpty)
    }

    @Test("Unknown rules and units that are not rules are errors", arguments: ["nothing", "restock"])
    func unknownRule(name: String) async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(["analyse", Fixture.module, "--rules", name], in: directory)
        #expect(run.status == 1)
        #expect(run.error.contains("The module has no rule named '\(name)' (available: addParcel, removeParcel, move"))
    }

    @Test("Invalid values of the options are usage errors", arguments: [["--direction", "sideways"], ["--granularity", "fine"], ["--format", "xml"]])
    func usage(arguments: [String]) async throws {
        let run = try await runSwiftHenshin(["analyse", "depot.henshin"] + arguments)
        #expect(run.status == 64)
    }

    @Test("A module without rules has nothing to analyse")
    func noRules() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Fixture.write("ePackageImport depot\n", named: "empty.henshin_text", in: directory)
        let run = try await runSwiftHenshin(["analyse", "empty.henshin_text"], in: directory)
        #expect(run.status == 1)
        #expect(run.error.contains("The module has no rules to work with"))
    }

    @Test("The options of the analysis follow the command line")
    func options() throws {
        let defaults = try AnalyseCommand.parse(["m.henshin"])
        #expect(defaults.analysisOptions == AnalysisOptions())
        #expect(defaults.directions == [.conflict])
        #expect(defaults.granularity.level == .minimalReasons)
        let all = try AnalyseCommand.parse(
            ["m.henshin", "--essential", "--no-multiplicities", "--check-dangling", "--direction", "both"])
        #expect(all.analysisOptions == AnalysisOptions(respectsMultiplicities: false, checkDangling: true, essentialOnly: true))
        #expect(all.directions == [.conflict, .dependency])
        #expect(try AnalyseCommand.parse(["m.henshin", "--direction", "dependency"]).directions == [.dependency])
        #expect(SwiftHenshinVocabulary.Granularity.allCases.map(\.level) == AnalysisGranularity.allCases)
        #expect(SwiftHenshinVocabulary.Granularity.allCases.map(\.rawValue) == AnalysisGranularity.allCases.map(\.description))
    }
}
