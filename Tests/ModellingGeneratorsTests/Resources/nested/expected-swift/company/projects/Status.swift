//
//  Status.swift
//

import EMFBase
import Foundation

/// The Status enumeration.
// @generated
public enum Status: Int, Sendable, Codable, CaseIterable, EcoreValue {
    /// The Proposed literal.
    // @generated
    case Proposed = 0

    /// The Active literal.
    // @generated
    case Active = 1

    /// The Finished literal.
    // @generated
    case Finished = 2

    /// The text that stands for the literal in a serialised model.
    // @generated
    public var literalText: String {
        switch self {
        case .Proposed: return "Proposed"
        case .Active: return "Active"
        case .Finished: return "Finished"
        }
    }

    /// Creates the literal that a text stands for in a serialised model.
    ///
    /// - Parameter literalText: The text of the literal.
    // @generated
    public init?(literalText: String) {
        switch literalText {
        case "Proposed": self = .Proposed
        case "Active": self = .Active
        case "Finished": self = .Finished
        default: return nil
        }
    }
}
