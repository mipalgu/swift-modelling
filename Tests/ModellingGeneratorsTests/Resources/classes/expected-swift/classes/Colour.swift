//
//  Colour.swift
//

import EMFBase
import Foundation

/// The Colour enumeration.
// @generated
public enum Colour: Int, Sendable, Codable, CaseIterable, EcoreValue {
    /// The Red literal.
    // @generated
    case Red = 0

    /// The Green literal.
    // @generated
    case Green = 1

    /// The Blue literal.
    // @generated
    case Blue = 2

    /// The text that stands for the literal in a serialised model.
    // @generated
    public var literalText: String {
        switch self {
        case .Red: return "Red"
        case .Green: return "Green"
        case .Blue: return "Blue"
        }
    }

    /// Creates the literal that a text stands for in a serialised model.
    ///
    /// - Parameter literalText: The text of the literal.
    // @generated
    public init?(literalText: String) {
        switch literalText {
        case "Red": self = .Red
        case "Green": self = .Green
        case "Blue": self = .Blue
        default: return nil
        }
    }
}
