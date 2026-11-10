//
// ExploreTests.swift
// swift-henshin-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Foundation
import Henshin
import HenshinStateSpace
import Testing

@testable import swift_henshin

/// Runs `swift-henshin explore` as a reader would.
@Suite("swift-henshin explore")
struct ExploreTests {
    /// An invariant that every state of the fixture satisfies.
    static let nonNegative = "self.bins->forAll(b | b.tokens >= 0)"

    /// A property of the state in which bin B holds both tokens.
    static let allInB = "self.bins->forAll(b | b.name = 'A' or b.tokens = 2)"

    @Test("Properties are checked and a violation exits with status 2", arguments: [Fixture.module, Fixture.textModule])
    func properties(module: String) async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(
            ["explore", module, Fixture.model, "--rules", "move", "--deadlock", "--invariant", Self.nonNegative,
             "--reach", Self.allInB, "--forbid", "emptyBin"], in: directory)
        #expect(run.status == 2, "\(run.error)")
        #expect(run.output == """
            state space: 3 states, 4 transitions, complete
            deadlocks: 0
            expanded states: 3, applications: 4
            invariant aql(\(Self.nonNegative)): holds
            invariant not pattern emptyBin: does not hold
              state 0 after 0 step(s)
            reachable aql(\(Self.allInB)): holds
              state 2 after 2 step(s)
                1. 0 -> 1: move(source=Bin(A), target=Bin(B))
                2. 1 -> 2: move(source=Bin(A), target=Bin(B))
            deadlock freedom: holds

            """)
    }

    @Test("Properties that hold exit with status 0, and --dot writes the graph")
    func holds() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(
            ["explore", Fixture.module, Fixture.model, "--rules", "move", "--deadlock", "--reach", Self.allInB,
             "--dot", "space.dot"], in: directory)
        #expect(run.succeeded, "\(run.error)")
        let dot = try Fixture.read("space.dot", in: directory)
        #expect(dot.hasPrefix("digraph \"statespace\" {\n  node [shape=circle];\n"))
        #expect(dot.contains("  s0 [label=\"0\", shape=doublecircle, style=\"bold\"];\n"))
        #expect(dot.contains("  s0 -> s1 [label=\"move\"];\n"))
        #expect(dot.hasSuffix("}\n"))
    }

    @Test("A deadlock is reported with the path to it")
    func deadlock() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(
            ["explore", Fixture.textModule, Fixture.model, "--rules", "move,drain", "--deadlock", "--verbose"],
            in: directory)
        #expect(run.status == 2)
        #expect(run.output.hasPrefix("state space: 6 states, 12 transitions, complete\ndeadlocks: 1\n"))
        #expect(run.output.hasSuffix("""
            deadlock freedom: does not hold
              state 5 after 2 step(s)
                1. 0 -> 2: drain(bin=Bin(A))
                2. 2 -> 5: drain(bin=Bin(A))

            """))
        #expect(run.error.contains("note: exploring the state space\n"))
        #expect(run.error.contains("note: finished exploring the state space ("))
    }

    @Test("Bounds leave the state space incomplete, which makes outcomes inconclusive")
    func inconclusive() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let states = try await runSwiftHenshin(
            ["explore", Fixture.module, Fixture.model, "--rules", "move", "--max-states", "2", "--invariant", Self.nonNegative],
            in: directory)
        #expect(states.status == 3)
        #expect(states.output.hasPrefix("state space: 2 states, 2 transitions, 1 open\n"))
        #expect(states.output.contains("holds (inconclusive: state space incomplete)\n"))
        let depth = try await runSwiftHenshin(
            ["explore", Fixture.module, Fixture.model, "--rules", "move", "--max-depth", "0", "--reach", "self.bins->isEmpty()"],
            in: directory)
        #expect(depth.status == 3)
        #expect(depth.output.contains("does not hold (inconclusive: state space incomplete)\n"))
        let objects = try await runSwiftHenshin(
            ["explore", Fixture.module, Fixture.model, "--rules", "move", "--max-objects", "1"], in: directory)
        #expect(objects.succeeded)
        #expect(objects.output.hasPrefix("state space: 1 states, 0 transitions, 1 open\n"))
    }

    @Test("A reachability property that fails in a complete state space exits with status 2")
    func unreachable() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(
            ["explore", Fixture.module, Fixture.model, "--rules", "move", "--reach", "self.bins->isEmpty()"], in: directory)
        #expect(run.status == 2)
        #expect(run.output.hasSuffix("reachable aql(self.bins->isEmpty()): does not hold\n"))
    }

    @Test("Units are applied as atomic steps with the given parameters and identity")
    func units() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(
            ["explore", Fixture.module, Fixture.model, "--units", "restock", "--param", "restock.binName=B",
             "--param", "restock.code=P9", "--param", "restock.weight=1", "--max-depth", "2", "--identity", "identity",
             "--workers", "1", "--reach", "self.parcels->size() = 4"], in: directory)
        #expect(run.succeeded, "\(run.error)")
        #expect(run.output.hasPrefix("state space: 3 states, 2 transitions, 1 open\n"))
        #expect(run.output.contains("    1. 0 -> 1: restock(binName=\"B\", code=\"P9\", weight=1)\n"))
        let objects = try await runSwiftHenshin(
            ["explore", Fixture.module, Fixture.model, "--rules", "clearBin", "--param", "clearBin.target=A", "--deadlock"],
            in: directory)
        #expect(objects.succeeded, "\(objects.error)")
        #expect(objects.output == """
            state space: 2 states, 2 transitions, complete
            deadlocks: 0
            expanded states: 2, applications: 2
            deadlock freedom: holds

            """)
    }

    @Test(
        "Errors are reported with status 1",
        arguments: [
            (["--rules", "nothing"], "The module has no rule named 'nothing'"),
            (["--units", "nothing"], "The module has no unit or rule named 'nothing'"),
            (["--forbid", "restock"], "The module has no rule named 'restock'"),
            (["--rules", "addParcel"], "addParcel needs a value for its parameter code"),
            (["--rules", "move", "--param", "binName=x"], "Invalid parameter 'binName': expected unit.name=value"),
            (["--rules", "move", "--param", "nothing.x=1"], "The module has no unit or rule named 'nothing'"),
            (["--rules", "move", "--param", "addParcel.weight=heavy"], "expected a value of type EInt"),
            (["--rules", "move", "--invariant", "self.nonsense("], "The property cannot be evaluated"),
        ])
    func errors(arguments: [String], message: String) async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let run = try await runSwiftHenshin(["explore", Fixture.module, Fixture.model] + arguments, in: directory)
        #expect(run.status == 1)
        #expect(run.error.contains(message), "\(run.error)")
    }

    @Test(
        "Bounds must be positive",
        arguments: [["--max-states", "0"], ["--max-objects", "0"], ["--workers", "0"], ["--max-depth", "-1"], ["--identity", "same"]])
    func usage(arguments: [String]) async throws {
        let run = try await runSwiftHenshin(["explore", "m.henshin", "m.xmi"] + arguments)
        #expect(run.status == ExitCode.validationFailure.rawValue)
    }

    @Test("Exit statuses follow the outcomes")
    func exitStatus() {
        let space = StateSpace(
            states: [], transitions: [], equivalence: .isomorphism, statistics: ExplorationStatistics())
        let holds = CheckResult(property: "p", holds: true, state: nil, path: [], isConclusive: true)
        let fails = CheckResult(property: "p", holds: false, state: 0, path: [], isConclusive: true)
        let unsure = CheckResult(property: "p", holds: true, state: nil, path: [], isConclusive: false)
        #expect(ExplorationReport(space: space, results: []).exitStatus == 0)
        #expect(ExplorationReport(space: space, results: [holds]).exitStatus == 0)
        #expect(ExplorationReport(space: space, results: [holds, unsure]).exitStatus == 3)
        #expect(ExplorationReport(space: space, results: [unsure, fails]).exitStatus == 2)
        #expect(ExplorationReport(space: space, results: [fails]).highlightedStates == [0])
        #expect(StateEquivalence.allCases.map(\.rawValue) == SwiftHenshinVocabulary.StateIdentity.allCases.map(\.rawValue))
        #expect(SwiftHenshinVocabulary.StateIdentity.allCases.map(\.equivalence) == StateEquivalence.allCases)
    }
}
