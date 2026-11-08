//
// ExploreCommand.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import Foundation
import Henshin
import HenshinStateSpace
import ModellingCommandLine

extension SwiftHenshinVocabulary.StateIdentity: ExpressibleByArgument {
    /// How the explorer tells states apart for this value.
    var equivalence: StateEquivalence {
        switch self {
        case .isomorphism: return .isomorphism
        case .identity: return .identity
        }
    }
}

/// The command that explores the states that the rules of a module reach from a model.
///
/// States are identified up to isomorphism by default. The command prints a summary of the
/// state space and the outcome of each property it is asked to check, with the shortest
/// path to a witness or counterexample, and can write the state space as a Graphviz graph.
struct ExploreCommand: AsyncParsableCommand {
    /// Shorthand for the option names.
    private typealias Key = SwiftHenshinVocabulary.OptionName
    /// Shorthand for the value names.
    private typealias Placeholder = SwiftHenshinVocabulary.ValueName

    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: SwiftHenshinVocabulary.Command.explore,
        abstract: "Explore the state space of a model and check properties",
        discussion: """
            Applies the rules that --\(Key.rules) names at every match, and the units that \
            --\(Key.units) names as atomic steps, to every state reached from the model, \
            breadth first. Without either option, every active rule of the module is applied; \
            with --\(Key.units) alone, only the units are. A rule's parameters are bound by \
            matching where its left-hand side determines them; --\(Key.param) \
            unit.name=value gives a value for any other parameter, once per parameter, and \
            the values are typed as for apply. The model file is not changed.

            --\(Key.identity) isomorphism (the default) identifies models that differ only \
            in the identities and order of their objects; --\(Key.identity) identity keeps \
            states apart unless they have the same objects. --\(Key.maxStates) (default \
            100000), --\(Key.maxDepth) and --\(Key.maxObjects) bound the exploration; a \
            state cut off by a bound stays open and the state space is then incomplete. \
            --\(Key.workers) sets the number of states expanded at once (default 4).

            Properties, each of which can be given several times: --\(Key.reach) checks \
            that a state satisfying an AQL expression is reachable, --\(Key.invariant) \
            that every state satisfies an AQL expression, --\(Key.forbid) that no state \
            matches the left-hand side of the named rule (with its application conditions), \
            and --\(Key.deadlock) that no state is a deadlock. AQL expressions are \
            evaluated with self bound to the first root object of each state's model. A \
            witness of reachability, or a counterexample, is printed with the shortest path to \
            it. Without the state space being complete, a property for which no witness or \
            counterexample was found is inconclusive.

            --\(Key.dot) writes the state space as a Graphviz graph: the initial state as a \
            double circle, open states dashed, deadlocks as boxes, and the states of the \
            printed paths in bold. While the state space is explored, the elapsed time is \
            shown on standard error if it is a terminal, or reported every few seconds with \
            --verbose.

            \(SwiftHenshinCommand.matchingDiscussion)

            \(SwiftHenshinCommand.metamodelDiscussion)

            \(SwiftHenshinCommand.encodingDiscussion)

            Exit statuses: 0 if every property holds (or none is given), 2 if a property does \
            not hold, 3 if none fails but an outcome is inconclusive because the state space \
            is incomplete, 1 for any other error, and 64 for an invalid command line.

            Examples:
              swift-henshin explore depot.henshin depot.xmi --rules move --deadlock
              swift-henshin explore depot.henshin depot.xmi --rules move,drain \\
                --invariant "self.bins->forAll(b | b.tokens >= 0)" --forbid emptyBin \\
                --reach "self.bins->forAll(b | b.tokens = 0)" --dot depot.dot
            """
    )

    /// The module file.
    @Argument(help: ArgumentHelp("The module (.henshin or .henshin_text)", valueName: Placeholder.module))
    var module: String

    /// The model file.
    @Argument(help: ArgumentHelp("The model to start from", valueName: Placeholder.model))
    var model: String

    /// The names of the rules to apply at every match.
    @Option(
        name: .customLong(Key.rules),
        help: ArgumentHelp(
            "Rules to apply at every match, separated by commas (can be specified multiple times)",
            valueName: Placeholder.names))
    var rules: [String] = []

    /// The names of the units to apply as atomic steps.
    @Option(
        name: .customLong(Key.units),
        help: ArgumentHelp(
            "Units to apply as atomic steps, separated by commas (can be specified multiple times)",
            valueName: Placeholder.names))
    var units: [String] = []

    /// The parameter values, as `unit.name=value` pairs.
    @Option(
        name: .customLong(Key.param),
        help: ArgumentHelp(
            "A value for a parameter of a rule or unit (can be specified multiple times)", valueName: Placeholder.unitParam))
    var param: [String] = []

    /// The largest number of states.
    @Option(
        name: .customLong(Key.maxStates),
        help: ArgumentHelp("The largest number of states (default: 100000)", valueName: Placeholder.number))
    var maxStates: Int?

    /// The largest depth of a state.
    @Option(
        name: .customLong(Key.maxDepth),
        help: ArgumentHelp("The largest number of steps from the initial state", valueName: Placeholder.number))
    var maxDepth: Int?

    /// The largest number of objects of a state.
    @Option(
        name: .customLong(Key.maxObjects),
        help: ArgumentHelp("The largest number of objects of an explored state", valueName: Placeholder.number))
    var maxObjects: Int?

    /// How states are identified.
    @Option(
        name: .customLong(Key.identity), help: ArgumentHelp("How states are identified", valueName: Placeholder.identity))
    var identity: SwiftHenshinVocabulary.StateIdentity = .isomorphism

    /// The AQL expressions of states that must be reachable.
    @Option(
        name: .customLong(Key.reach),
        help: ArgumentHelp("Check that a state satisfying the AQL expression is reachable", valueName: Placeholder.aql))
    var reach: [String] = []

    /// The AQL expressions that every state must satisfy.
    @Option(
        name: .customLong(Key.invariant),
        help: ArgumentHelp("Check that every state satisfies the AQL expression", valueName: Placeholder.aql))
    var invariant: [String] = []

    /// The names of the rules whose patterns no state may match.
    @Option(
        name: .customLong(Key.forbid),
        help: ArgumentHelp("Check that no state matches the left-hand side of the rule", valueName: Placeholder.rule))
    var forbid: [String] = []

    /// Whether deadlock freedom is checked.
    @Flag(name: .customLong(Key.deadlock), help: "Check that no state is a deadlock")
    var deadlock = false

    /// The Graphviz file to write.
    @Option(
        name: .customLong(Key.dot),
        help: ArgumentHelp("Write the state space as a Graphviz graph", valueName: Placeholder.dot))
    var dot: String?

    /// The number of states expanded at once.
    @Option(
        name: .customLong(Key.workers),
        help: ArgumentHelp("The number of states expanded at once (default: 4)", valueName: Placeholder.number))
    var workers: Int?

    /// The overrides of matching.
    @OptionGroup(title: "Matching")
    var matchingOptions: MatchingOptions

    /// The options with which the module is read.
    @OptionGroup var moduleOptions: ModuleOptions

    /// Checks that the bounds are positive.
    ///
    /// - Throws: A validation error for a bound or a number of workers below 1, or a negative
    ///   depth.
    func validate() throws {
        for (name, value) in [(Key.maxStates, maxStates), (Key.maxObjects, maxObjects), (Key.workers, workers)] {
            if let value, value < 1 { throw ValidationError("--\(name) must be at least 1") }
        }
        if let maxDepth, maxDepth < 0 { throw ValidationError("--\(Key.maxDepth) must not be negative") }
    }

    /// Explores the state space, checks the properties and prints the report.
    ///
    /// - Throws: `ExitCode` 2 or 3 if a property does not hold or is inconclusive,
    ///   ``SwiftHenshinError`` for names that the module lacks, and the errors of the
    ///   exploration and of the checks.
    @MainActor
    func run() async throws {
        let loader = moduleOptions.loader
        let log = loader.log
        let loaded = try await loader.load(module)
        let ruleNames = NameList.names(rules)
        let unitNames = NameList.names(units)
        for name in ruleNames { _ = try loaded.rule(named: name) }
        for name in unitNames { _ = try loaded.unit(named: name) }
        let patterns = try forbid.map(loaded.rule(named:))
        let start = try await ModelFile.load(model, into: loaded.resourceSet, log: log)
        let options = ExplorationOptions(
            maximumStates: maxStates ?? ExplorationOptions().maximumStates, maximumDepth: maxDepth,
            maximumObjects: maxObjects, equivalence: identity.equivalence,
            parameterValues: try await parameterValues(of: loaded, in: start.resource),
            engineOptions: matchingOptions.engineOptions(), concurrency: workers ?? ExplorationOptions().concurrency)
        let explorer = try StateSpaceExplorer(
            module: loaded.module, rules: ruleNames.isEmpty && !unitNames.isEmpty ? [] : ruleNames.nilIfEmpty,
            units: unitNames, options: options)
        let ticker = ProgressTicker(verbose: moduleOptions.verbose)
        let space = try await ticker.run("exploring the state space") { try await explorer.explore(from: start.resource) }
        let checker = ModelChecker(
            stateSpace: space, resourceSet: loaded.resourceSet, engineOptions: matchingOptions.engineOptions())
        var results: [CheckResult] = []
        for expression in invariant { results.append(try await checker.checkInvariant(.aql(expression))) }
        for pattern in patterns { results.append(try await checker.checkInvariant(.forbidden(pattern))) }
        for expression in reach { results.append(try await checker.checkReachable(.aql(expression))) }
        if deadlock { results.append(checker.checkDeadlockFreedom()) }
        let report = ExplorationReport(space: space, results: results)
        report.lines.forEach { print($0) }
        if let dot {
            try space.dot(highlighted: report.highlightedStates).appending("\n").write(
                to: URL(fileURLWithPath: dot), atomically: true, encoding: .utf8)
            log.progress("wrote \(dot)")
        }
        let status = report.exitStatus
        if status != SwiftHenshinVocabulary.ExitStatus.success { throw ExitCode(status) }
    }

    /// The parameter values that `--param` gives, by rule or unit.
    ///
    /// - Parameters:
    ///   - loaded: The module.
    ///   - resource: The resource of the initial model, in which objects are found.
    /// - Returns: One assignment for each rule or unit that has values.
    /// - Throws: `KeyValueOptionError` for a pair that cannot be read, and
    ///   ``SwiftHenshinError`` for a unit that the module lacks or an object that the model
    ///   lacks.
    func parameterValues(of loaded: LoadedModule, in resource: Resource) async throws -> [String: [ParameterValues]] {
        let pairs = try KeyValueOption<String>(
            noun: SwiftHenshinVocabulary.Noun.parameter, keyPlaceholder: SwiftHenshinVocabulary.Noun.unitParameter
        ).values(from: param)
        var texts: [String: [String: String]] = [:]
        for (key, text) in pairs {
            guard let separator = key.firstIndex(of: SwiftHenshinVocabulary.Separator.unitParameter) else {
                throw KeyValueOptionError.missingSeparator(
                    noun: SwiftHenshinVocabulary.Noun.parameter, text: key,
                    usage: SwiftHenshinVocabulary.ValueName.unitParam)
            }
            texts[String(key[..<separator]), default: [:]][String(key[key.index(after: separator)...])] = text
        }
        var result: [String: [ParameterValues]] = [:]
        for (unitName, assignments) in texts {
            let unit = try loaded.unit(named: unitName)
            let family = ParameterArguments.family(for: unit.parameters, classNames: loaded.classNames)
            let arguments = try family.values(
                from: assignments.map { $0.key + String(KeyValueOptionSyntax.separator) + $0.value })
            result[unitName] = [try await ParameterArguments.values(arguments, parameters: unit.parameters, in: resource)]
        }
        return result
    }
}
