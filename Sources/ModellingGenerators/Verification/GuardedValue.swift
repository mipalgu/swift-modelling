//
// GuardedValue.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// The text of a single value together with the conditions under which it is defined.
///
/// TLA+ and Event-B have no undefined values, so the printers of these targets write a
/// navigation through an absent value as a value that is guarded by the condition that every
/// value on the way is present. An atomic formula over guarded values holds only if its guards
/// hold, which follows OCL, where an invariant over an invalid value is not satisfied.
struct GuardedValue {
    /// The text of the value.
    var text: String
    /// The conditions that must hold for the text to denote a value.
    var guards: [String] = []
    /// The condition under which the value is present, if it may be absent.
    var presence: String? = nil

    /// All conditions that must hold for the value to be present.
    var definedness: [String] { guards + (presence.map { [$0] } ?? []) }
}

/// Joins conditions with a conjunction operator, wrapping compound conditions in parentheses.
///
/// - Parameters:
///   - conditions: The conditions, of which the last is the main formula.
///   - conjunction: The conjunction operator of the target, with surrounding spaces.
/// - Returns: The conjunction, or the only condition unchanged.
func conjoin(_ conditions: [String], with conjunction: String) -> String {
    guard conditions.count > 1 else { return conditions.first ?? "" }
    return conditions.map { "(\($0))" }.joined(separator: conjunction)
}
