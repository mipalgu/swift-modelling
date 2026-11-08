//
// AnalyseCommand.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Henshin
import HenshinAnalysis

extension SwiftHenshinVocabulary.Granularity: ExpressibleByArgument {
    /// The level of the analysis that the value names.
    var level: AnalysisGranularity {
        switch self {
        case .binary: return .binary
        case .atoms: return .atoms
        case .minimalReasons: return .minimalReasons
        case .criticalPairs: return .criticalPairs
        }
    }
}

extension SwiftHenshinVocabulary.Direction: ExpressibleByArgument {}

extension SwiftHenshinVocabulary.OutputFormat: ExpressibleByArgument {}

/// The command that finds the conflicts and dependencies of the rules of a module.
///
/// The analysis is static: critical pair analysis examines how the graphs of two rules can
/// overlap, without a model, and reports every ordered pair of the chosen rules, each rule
/// paired with itself too.
struct AnalyseCommand: AsyncParsableCommand {
    /// Shorthand for the option names.
    private typealias Key = SwiftHenshinVocabulary.OptionName
    /// Shorthand for the value names.
    private typealias Placeholder = SwiftHenshinVocabulary.ValueName

    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: SwiftHenshinVocabulary.Command.analyse,
        abstract: "Find the conflicts and dependencies of rules",
        discussion: """
            Analyses every ordered pair of the rules that --\(Key.rules) names (all rules of \
            the module by default), each rule paired with itself too. A conflict means that \
            applying the first rule may disable the second (delete-use, produce-forbid, \
            change-use, change-forbid); a dependency means that it may enable the second \
            (produce-use, delete-forbid, change-use, change-forbid). --\(Key.direction) \
            chooses conflicts, dependencies or both.

            --\(Key.granularity) chooses how finely interactions are described: binary \
            (whether the rules interact), atoms, minimal-reasons (the default) or \
            critical-pairs, each including the coarser ones. --\(Key.essential) reports \
            only essential critical pairs, and --\(Key.noMultiplicities) lets overlaps \
            ignore the multiplicities of the metamodel. The analysis over-approximates: it does \
            not evaluate attribute conditions or non-literal attribute values.

            The text report starts each direction with a matrix of the pairs (the number of \
            minimal reasons, or of atoms, x for an interaction found at binary granularity, \
            and . for none), followed by the details of every interacting pair. \
            --\(Key.format) json prints the same results as a JSON document.

            \(SwiftHenshinCommand.matchingDiscussion) Only the dangling condition affects the \
            analysis.

            \(SwiftHenshinCommand.metamodelDiscussion)

            \(SwiftHenshinCommand.encodingDiscussion)

            Exit statuses: 0 on success, whether or not rules interact, 1 if the module cannot \
            be read or names no such rule, and 64 for an invalid command line.

            Examples:
              swift-henshin analyse depot.henshin
              swift-henshin analyse depot.henshin --rules addParcel,removeParcel \\
                --direction both --granularity critical-pairs --format json
            """
    )

    /// The module file.
    @Argument(help: ArgumentHelp("The module to analyse (.henshin or .henshin_text)", valueName: Placeholder.module))
    var module: String

    /// The names of the rules to analyse.
    @Option(
        name: .customLong(Key.rules),
        help: ArgumentHelp(
            "Rules to analyse, separated by commas (can be specified multiple times; default: all)",
            valueName: Placeholder.names))
    var rules: [String] = []

    /// Whether conflicts, dependencies or both are analysed.
    @Option(
        name: .customLong(Key.direction),
        help: ArgumentHelp("Whether to find conflicts, dependencies or both", valueName: Placeholder.direction))
    var direction: SwiftHenshinVocabulary.Direction = .conflict

    /// How finely interactions are described.
    @Option(
        name: .customLong(Key.granularity),
        help: ArgumentHelp("How finely to describe the interactions", valueName: Placeholder.level))
    var granularity: SwiftHenshinVocabulary.Granularity = .minimalReasons

    /// Whether only essential critical pairs are reported.
    @Flag(name: .customLong(Key.essential), help: "Report only essential critical pairs")
    var essential = false

    /// Whether overlaps may ignore the multiplicities of the metamodel.
    @Flag(name: .customLong(Key.noMultiplicities), help: "Let overlaps ignore the multiplicities of the metamodel")
    var noMultiplicities = false

    /// The format of the report.
    @Option(
        name: .customLong(Key.format), help: ArgumentHelp("The format of the report", valueName: Placeholder.format))
    var format: SwiftHenshinVocabulary.OutputFormat = .text

    /// The overrides of matching, of which the dangling condition affects the analysis.
    @OptionGroup(title: "Matching")
    var matchingOptions: MatchingOptions

    /// The options with which the module is read.
    @OptionGroup var moduleOptions: ModuleOptions

    /// The options of the analysis that the command line asks for.
    var analysisOptions: AnalysisOptions {
        AnalysisOptions(
            respectsMultiplicities: !noMultiplicities, checkDangling: matchingOptions.dangling?.checks,
            essentialOnly: essential)
    }

    /// The directions to analyse, in the order of the report.
    var directions: [InteractionDirection] {
        switch direction {
        case .conflict: return [.conflict]
        case .dependency: return [.dependency]
        case .both: return [.conflict, .dependency]
        }
    }

    /// Analyses the rules and prints the report.
    ///
    /// - Throws: ``SwiftHenshinError/unknownRule(_:_:)`` for a name that is not a rule,
    ///   ``SwiftHenshinError/noRules`` if there is nothing to analyse, and the errors of
    ///   reading the module.
    @MainActor
    func run() async throws {
        let loader = moduleOptions.loader
        let loaded = try await loader.load(module)
        let names = NameList.names(rules)
        let selected = try names.isEmpty ? loaded.module.rules : names.map(loaded.rule(named:))
        guard !selected.isEmpty else { throw SwiftHenshinError.noRules }
        let analyser = CriticalPairAnalyser(options: analysisOptions)
        var tables: [InteractionTable] = []
        for direction in directions {
            loader.log.progress("analysing \(direction.rawValue)s of \(selected.count) rule(s) at \(granularity.rawValue)")
            tables.append(analyser.analyse(selected, direction: direction, granularity: granularity.level))
        }
        switch format {
        case .text: print(AnalysisReport.text(of: tables))
        case .json: print(try AnalysisReport(tables: tables, granularity: granularity.level).json())
        }
    }
}
