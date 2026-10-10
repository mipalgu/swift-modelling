//
//  Level.swift
//

import EMFBase
import Foundation

/// The levels of an alarm.
/// Higher levels need quicker action.
// @generated
public enum Level: Int, Sendable, Codable, CaseIterable, EcoreValue {
    /// The Low literal.
    // @generated
    case Low = 0

    /// Immediate action.
    /// Wake somebody.
    // @generated
    case High = 1

    /// @deprecated use High
    // @generated
    case Old = 2

    /// The text that stands for the literal in a serialised model.
    // @generated
    public var literalText: String {
        switch self {
        case .Low: return "Low"
        case .High: return "High"
        case .Old: return "Old"
        }
    }

    /// Creates the literal that a text stands for in a serialised model.
    ///
    /// - Parameter literalText: The text of the literal.
    // @generated
    public init?(literalText: String) {
        switch literalText {
        case "Low": self = .Low
        case "High": self = .High
        case "Old": self = .Old
        default: return nil
        }
    }
}
