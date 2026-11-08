//
//  RenamingHint.swift
//  ModelTyping
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

/// The kind of element a renaming hint is about.
public enum RenamingHintKind: String, Sendable, Hashable, Codable {
    /// A class or enumeration.
    case classifier
    /// A feature of a class.
    case feature
    /// A literal of an enumeration.
    case literal
}

/// Why a provided name is suggested for a missing required name.
public enum RenamingHintReason: String, Sendable, Hashable, Codable {
    /// The names differ only in letter case.
    case caseDifference
    /// The names are within a small edit distance of each other.
    case nearMissName
    /// One name contains the other.
    case containedName
    /// The only unmatched provided feature of the same kind and type, or the only unmatched
    /// literal of the provided enumeration.
    case uniqueStructuralCandidate
    /// An unmatched provided class with largely the same feature names.
    case similarStructure
}

/// A suggestion that a missing required element may have been renamed.
public struct RenamingHint: Sendable, Hashable, Codable, CustomStringConvertible {
    /// The kind of element.
    public let kind: RenamingHintKind
    /// The metamodel name.
    public let metamodel: String
    /// The required owner (class or enumeration) of a feature or literal.
    public let owner: String?
    /// The required name that has no provided counterpart.
    public let requiredName: String
    /// The provided name that may correspond to it.
    public let suggestedName: String
    /// Why the provided name is suggested.
    public let reason: RenamingHintReason
    /// The case-insensitive edit distance between the names.
    public let distance: Int

    /// Creates a renaming hint.
    ///
    /// - Parameters:
    ///   - kind: The kind of element.
    ///   - metamodel: The metamodel name.
    ///   - owner: The required owner of a feature or literal (default: `nil`).
    ///   - requiredName: The missing required name.
    ///   - suggestedName: The suggested provided name.
    ///   - reason: Why the name is suggested.
    ///   - distance: The case-insensitive edit distance between the names.
    public init(
        kind: RenamingHintKind, metamodel: String, owner: String? = nil, requiredName: String,
        suggestedName: String, reason: RenamingHintReason, distance: Int
    ) {
        self.kind = kind
        self.metamodel = metamodel
        self.owner = owner
        self.requiredName = requiredName
        self.suggestedName = suggestedName
        self.reason = reason
        self.distance = distance
    }

    /// The renaming entry that applies the hint, in the form accepted by ``Renaming/init(parsing:)``.
    public var renamingEntry: String {
        let required = owner.map { Renaming.memberKey(owner: $0, member: requiredName) } ?? requiredName
        return "\(required)=\(suggestedName)"
    }

    /// The hint as one line of text.
    public var description: String {
        "\(metamodel): \(renamingEntry) (\(reason.rawValue), distance \(distance))"
    }
}

/// Finds provided names that may correspond to missing required names.
public enum NameSimilarity {
    /// The optimal string alignment distance between two strings, ignoring letter case.
    ///
    /// The distance counts insertions, deletions, substitutions and transpositions
    /// of adjacent characters.
    ///
    /// - Parameters:
    ///   - lhs: The first string.
    ///   - rhs: The second string.
    /// - Returns: The minimum number of edits that turn one string into the other.
    public static func editDistance(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs.lowercased()), b = Array(rhs.lowercased())
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var table = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in 0...a.count { table[i][0] = i }
        for j in 0...b.count { table[0][j] = j }
        for i in 1...a.count {
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                table[i][j] = min(table[i - 1][j] + 1, table[i][j - 1] + 1, table[i - 1][j - 1] + cost)
                if i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] {
                    table[i][j] = min(table[i][j], table[i - 2][j - 2] + 1)
                }
            }
        }
        return table[a.count][b.count]
    }

    /// The largest edit distance accepted as a near miss for a name.
    ///
    /// - Parameter name: The required name.
    /// - Returns: One edit per three characters, and at least one.
    public static func nearMissThreshold(for name: String) -> Int { max(1, name.count / 3) }

    /// The provided names that are near misses of a required name, closest first.
    ///
    /// - Parameters:
    ///   - name: The required name.
    ///   - candidates: The provided names that are not matched by any required name.
    ///   - maximumDistance: The largest accepted distance, or `nil` for ``nearMissThreshold(for:)``.
    /// - Returns: The candidates with the reason and distance, closest first.
    public static func nearMisses(
        of name: String, among candidates: [String], maximumDistance: Int? = nil
    ) -> [(name: String, reason: RenamingHintReason, distance: Int)] {
        let limit = maximumDistance ?? nearMissThreshold(for: name)
        var result: [(name: String, reason: RenamingHintReason, distance: Int)] = []
        for candidate in candidates where candidate != name {
            let distance = editDistance(name, candidate)
            if distance == 0 {
                result.append((candidate, .caseDifference, 0))
            } else if distance <= limit {
                result.append((candidate, .nearMissName, distance))
            } else if min(name.count, candidate.count) >= 3,
                candidate.lowercased().contains(name.lowercased()) || name.lowercased().contains(candidate.lowercased())
            {
                result.append((candidate, .containedName, distance))
            }
        }
        return result.sorted { ($0.distance, $0.name) < ($1.distance, $1.name) }
    }

    /// The Jaccard similarity of two sets of names.
    ///
    /// - Parameters:
    ///   - lhs: The first set.
    ///   - rhs: The second set.
    /// - Returns: The size of the intersection divided by the size of the union, or 0 for two empty sets.
    public static func jaccard(_ lhs: Set<String>, _ rhs: Set<String>) -> Double {
        let union = lhs.union(rhs)
        return union.isEmpty ? 0 : Double(lhs.intersection(rhs).count) / Double(union.count)
    }
}
