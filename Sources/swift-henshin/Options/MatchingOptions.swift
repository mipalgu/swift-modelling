//
// MatchingOptions.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Henshin

/// Whether the dangling condition of every rule is overridden, and how.
///
/// A rule that checks the dangling condition is not applicable where deleting its objects
/// would leave a reference dangling. Without the check, the references to deleted objects
/// are removed, and deleted objects take their contents with them.
enum DanglingCondition: String, EnumerableFlag, Sendable {
    /// Every rule checks the dangling condition.
    case checkDangling
    /// No rule checks the dangling condition.
    case noDanglingCheck

    /// The names of the flag of a value.
    ///
    /// - Parameter value: The value.
    /// - Returns: `--check-dangling`, or `--no-dangling-check` with its shorter spelling
    ///   `--no-dangling`.
    static func name(for value: DanglingCondition) -> NameSpecification {
        typealias Key = SwiftHenshinVocabulary.OptionName
        switch value {
        case .checkDangling: return [.customLong(Key.checkDangling)]
        case .noDanglingCheck: return [.customLong(Key.noDanglingCheck), .customLong(Key.noDangling)]
        }
    }

    /// The help of the flag of a value.
    ///
    /// - Parameter value: The value.
    /// - Returns: A sentence that describes the effect of the flag.
    static func help(for value: DanglingCondition) -> ArgumentHelp? {
        switch value {
        case .checkDangling:
            return "Check the dangling condition for every rule, whatever the rule says"
        case .noDanglingCheck:
            return "Do not check the dangling condition: remove the references to deleted objects instead"
        }
    }

    /// Whether the dangling condition is checked.
    var checks: Bool { self == .checkDangling }
}

/// Whether the injective matching of every rule is overridden, and how.
///
/// Injective matching maps different nodes of a rule to different objects.
enum Injectivity: String, EnumerableFlag, Sendable {
    /// Every rule matches injectively.
    case injective
    /// No rule matches injectively, so different nodes may match the same object.
    case nonInjective

    /// The help of the flag of a value.
    ///
    /// - Parameter value: The value.
    /// - Returns: A sentence that describes the effect of the flag.
    static func help(for value: Injectivity) -> ArgumentHelp? {
        switch value {
        case .injective: return "Match every rule injectively, whatever the rule says"
        case .nonInjective: return "Let different nodes of every rule match the same object"
        }
    }

    /// Whether matching is injective.
    var isInjective: Bool { self == .injective }
}

/// The command line options that override how the rules of a module match.
///
/// Without them, each rule follows its own `checkDangling` and `injectiveMatching` settings,
/// which default to `true` in Henshin.
struct MatchingOptions: ParsableArguments, Sendable {
    /// The override of the dangling condition, if any.
    @Flag var dangling: DanglingCondition?

    /// The override of injective matching, if any.
    @Flag var injectivity: Injectivity?

    /// Creates the options with nothing overridden.
    init() {}

    /// Engine options with the overrides of the command line.
    ///
    /// - Parameter options: The options to start from (default options).
    /// - Returns: The options with the dangling condition and injectivity overridden as given.
    func engineOptions(_ options: EngineOptions = EngineOptions()) -> EngineOptions {
        var result = options
        result.checkDangling = dangling?.checks
        result.injectiveMatching = injectivity?.isInjective
        return result
    }
}
