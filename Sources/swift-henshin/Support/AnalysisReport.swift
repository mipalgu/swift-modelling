//
// AnalysisReport.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Henshin
import HenshinAnalysis

/// The report of a conflict and dependency analysis, as text or as JSON.
///
/// The text report lists, for each direction, a matrix of the rule pairs (the number of
/// minimal reasons, of atoms at atom granularity, `x` for an interaction at binary
/// granularity, and `.` for none), followed by the details of every pair that interacts.
/// The JSON report holds the same results as a document.
struct AnalysisReport: Sendable, Codable, Equatable {
    /// The results of one direction of the analysis.
    struct Table: Sendable, Codable, Equatable {
        /// `conflict` or `dependency`.
        let direction: String

        /// The names of the rules, in order.
        let rules: [String]

        /// Every ordered pair of rules, by first and then second rule.
        let pairs: [Pair]
    }

    /// The interactions of an ordered pair of rules.
    struct Pair: Sendable, Codable, Equatable {
        /// The name of the rule applied first.
        let first: String

        /// The name of the other rule.
        let second: String

        /// Whether the first rule may disable (conflict) or enable (dependency) the second.
        let interacts: Bool

        /// The kinds of interaction, such as `delete-use`.
        let kinds: [String]

        /// The atoms, from atom granularity on.
        let atoms: [String]

        /// The minimal reasons, from minimal-reason granularity on.
        let minimalReasons: [String]

        /// The critical pairs, at critical-pair granularity.
        let criticalPairs: [CriticalPairReport]

        /// Whether a limit cut the critical pairs short.
        let truncated: Bool

        /// What the analysis approximated.
        let notes: [String]
    }

    /// A critical pair of a rule pair.
    struct CriticalPairReport: Sendable, Codable, Equatable {
        /// The kinds of interaction of the pair.
        let kinds: [String]

        /// Whether the overlap consists of the elements that cause the interaction.
        let essential: Bool

        /// The number of nodes of the overlap graph.
        let nodes: Int

        /// The number of edges of the overlap graph.
        let edges: Int

        /// The overlap of the two rules, as the analysis describes it.
        let overlap: String
    }

    /// The granularity of the analysis, such as `minimal-reasons`.
    let granularity: String

    /// The results, conflicts before dependencies.
    let tables: [Table]

    /// Creates the report of interaction tables.
    ///
    /// - Parameters:
    ///   - tables: The tables of the analysis, in the order to report them.
    ///   - granularity: The granularity of the analysis.
    init(tables: [InteractionTable], granularity: AnalysisGranularity) {
        self.granularity = granularity.description
        self.tables = tables.map { table in
            Table(
                direction: table.direction.rawValue, rules: table.rules,
                pairs: table.pairs.flatMap { $0 }.map(Pair.init))
        }
    }

    /// The report of interaction tables as readable text.
    ///
    /// - Parameter tables: The tables, in the order to report them.
    /// - Returns: The text of each table, separated by a blank line.
    static func text(of tables: [InteractionTable]) -> String {
        tables.map(tableText).joined(separator: "\n\n")
    }

    /// The report as a JSON document with sorted keys.
    ///
    /// - Returns: The document.
    /// - Throws: The error of the encoder.
    func json() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(self), as: UTF8.self)
    }

    /// The text of one table.
    ///
    /// - Parameter table: The table.
    /// - Returns: A heading, the matrix and the details of the interacting pairs.
    static func tableText(_ table: InteractionTable) -> String {
        let heading = table.direction == .conflict ? "Conflicts" : "Dependencies"
        var lines = [heading + ":", table.description]
        let interacting = table.interactingPairs
        if interacting.isEmpty {
            lines.append("none")
        } else {
            lines += interacting.map(\.description)
        }
        return lines.joined(separator: "\n")
    }
}

extension AnalysisReport.Pair {
    /// Creates the report of a rule pair.
    ///
    /// - Parameter interaction: The interactions of the pair.
    init(_ interaction: RulePairInteraction) {
        self.init(
            first: interaction.firstRule, second: interaction.secondRule, interacts: interaction.interacts,
            kinds: interaction.kinds.map(\.rawValue), atoms: interaction.atoms.map(\.description),
            minimalReasons: interaction.minimalReasons.map(\.description),
            criticalPairs: interaction.criticalPairs.map(AnalysisReport.CriticalPairReport.init),
            truncated: interaction.isTruncated, notes: interaction.notes)
    }
}

extension AnalysisReport.CriticalPairReport {
    /// Creates the report of a critical pair.
    ///
    /// - Parameter pair: The critical pair.
    init(_ pair: CriticalPair) {
        self.init(
            kinds: pair.kinds.map(\.rawValue), essential: pair.isEssential, nodes: pair.graph.nodes.count,
            edges: pair.graph.edges.count, overlap: pair.span.description)
    }
}
