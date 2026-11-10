//
//  Renaming.swift
//  ModelTyping
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import Foundation

/// An explicit mapping from required names to provided names.
///
/// Non-isomorphic subtyping ([Guy et al. 2012](https://doi.org/10.1007/978-3-642-31491-9_30), Def. 13 and 14, p. 410)
/// relates metamodels whose elements do not correspond by name alone through a
/// model adaptation; a renaming is the simplest such adaptation, comparable to
/// the renaming of concepts in Melange ([Degueule et al. 2015](https://doi.org/10.1145/2814251.2814252),
/// Sect. 5.2.1, p. 34).
/// Renamings apply only in the non-isomorphic modes. Classifier
/// renamings apply to classes, enumerations and data types. Member renamings
/// apply to features and enumeration literals and are keyed by the required
/// owner and member name, written `Owner.member`.
public struct Renaming: Sendable, Hashable, Codable {
    /// Provided classifier names, indexed by required classifier name.
    public var classifiers: [String: String]
    /// Provided member names, indexed by `Owner.member` with required names.
    public var members: [String: String]

    /// A renaming that keeps every name.
    public static let identity = Renaming()

    /// Creates a renaming.
    ///
    /// - Parameters:
    ///   - classifiers: Provided classifier names, indexed by required classifier name (default: none).
    ///   - members: Provided member names, indexed by `Owner.member` (default: none).
    public init(classifiers: [String: String] = [:], members: [String: String] = [:]) {
        self.classifiers = classifiers
        self.members = members
    }

    /// Parses a renaming from `required=provided` entries.
    ///
    /// An entry whose required side contains a `.` renames a member
    /// (`Book.title=name`); any other entry renames a classifier
    /// (`Writer=Author`). Entries may be separated by commas or given separately.
    ///
    /// - Parameter entries: The entries to parse.
    /// - Throws: ``RenamingError/malformedEntry(_:)`` if an entry is not of the form `required=provided`.
    public init(parsing entries: [String]) throws {
        self.init()
        for entry in entries.flatMap({ $0.split(separator: ",") }) {
            let parts = entry.split(separator: "=", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else {
                throw RenamingError.malformedEntry(String(entry))
            }
            if parts[0].contains(ModelTypingVocabulary.featureSeparator) {
                members[parts[0]] = parts[1]
            } else {
                classifiers[parts[0]] = parts[1]
            }
        }
    }

    /// The provided name of a classifier.
    ///
    /// - Parameter name: The required classifier name.
    /// - Returns: The renamed classifier name, or `name` itself if it is not renamed.
    public func providedClassifierName(for name: String) -> String { classifiers[name] ?? name }

    /// The provided name of a feature or literal.
    ///
    /// The owners are tried in order, so that a feature renamed on the class
    /// that declares it is also renamed when accessed through a subclass.
    ///
    /// - Parameters:
    ///   - name: The required member name.
    ///   - owners: The required owner names to try, most specific first.
    /// - Returns: The renamed member name, or `name` itself if it is not renamed.
    public func providedMemberName(for name: String, ownedBy owners: [String]) -> String {
        for owner in owners {
            if let renamed = members[Self.memberKey(owner: owner, member: name)] { return renamed }
        }
        return name
    }

    /// Whether the renaming changes no names.
    public var isEmpty: Bool { classifiers.isEmpty && members.isEmpty }

    /// The textual entries of the renaming, sorted, in the form accepted by ``init(parsing:)``.
    public var entries: [String] {
        (classifiers.map { "\($0.key)=\($0.value)" } + members.map { "\($0.key)=\($0.value)" }).sorted()
    }

    /// The key of a member renaming.
    ///
    /// - Parameters:
    ///   - owner: The required owner name.
    ///   - member: The required member name.
    /// - Returns: The key `owner.member`.
    public static func memberKey(owner: String, member: String) -> String {
        owner + ModelTypingVocabulary.featureSeparator + member
    }
}

/// A problem with the textual form of a renaming.
public enum RenamingError: Error, Sendable, Hashable {
    /// The entry is not of the form `required=provided`.
    case malformedEntry(String)
}
