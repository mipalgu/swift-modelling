//
// ExplorationReport.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Henshin
import HenshinStateSpace

/// The report of a state-space exploration and of the properties checked on it.
///
/// The report starts with a summary of the state space and lists each property with its
/// outcome. A witness or counterexample follows its property as the state it reaches and
/// the shortest path to it, one step per line, with the objects of each match given by
/// class and label in the model of the state the step starts from.
struct ExplorationReport: Sendable {
    /// The state space.
    let space: StateSpace

    /// The outcomes of the checked properties, in the order in which they were checked.
    let results: [CheckResult]

    /// The lines that summarise the state space.
    var summaryLines: [String] {
        [
            "state space: \(space)",
            "deadlocks: \(space.deadlocks.count)",
            "expanded states: \(space.statistics.expandedStates), applications: \(space.statistics.applications)",
        ]
    }

    /// The lines that report the outcome of a property.
    ///
    /// - Parameter result: The outcome.
    /// - Returns: A line with the property and its outcome, followed by the state and the
    ///   path of a witness or counterexample if there is one.
    func lines(for result: CheckResult) -> [String] {
        var outcome = result.property + ": " + (result.holds ? "holds" : "does not hold")
        if !result.isConclusive { outcome += " (inconclusive: state space incomplete)" }
        var lines = [outcome]
        guard let state = result.state else { return lines }
        lines.append("  state \(state) after \(result.path.count) step(s)")
        lines += result.path.enumerated().map { index, step in "    \(index + 1). \(describe(step))" }
        return lines
    }

    /// All lines of the report.
    var lines: [String] { summaryLines + results.flatMap(lines(for:)) }

    /// Describes a step of a path.
    ///
    /// - Parameter step: The transition.
    /// - Returns: A text such as `0 -> 1: move(source=Bin(A), target=Bin(B), m=0, n=2)`, with
    ///   the matched objects by node name followed by the other parameter values, each in the
    ///   order of their names.
    func describe(_ step: StateTransition) -> String {
        typealias Display = SwiftHenshinVocabulary.Display
        let formatter = ValueFormatter.snapshot(space.states[step.source].model)
        let matched = step.match.keys.sorted().map { $0 + Display.binding + formatter.format(step.match[$0]) }
        let values = formatter.bindings(step.parameters.filter { step.match[$0.key] == nil })
        return "\(step.source) -> \(step.target): \(step.label)(" + (matched + values).joined(separator: Display.bindingSeparator) + ")"
    }

    /// The states that the witnesses and counterexamples pass through.
    var highlightedStates: Set<Int> {
        Set(results.flatMap { result in result.path.flatMap { [$0.source, $0.target] } + (result.state.map { [$0] } ?? []) })
    }

    /// The exit status that the outcomes call for.
    ///
    /// It is ``SwiftHenshinVocabulary/ExitStatus/negative`` if a property does not hold
    /// conclusively, else ``SwiftHenshinVocabulary/ExitStatus/inconclusive`` if an outcome is
    /// inconclusive, else ``SwiftHenshinVocabulary/ExitStatus/success``.
    var exitStatus: Int32 {
        typealias Status = SwiftHenshinVocabulary.ExitStatus
        if results.contains(where: { !$0.holds && $0.isConclusive }) { return Status.negative }
        if results.contains(where: { !$0.isConclusive }) { return Status.inconclusive }
        return Status.success
    }
}
