//
//  Hue.swift
//

import EMFBase
import Foundation

/// The Hue enumeration.
// @generated
public enum Hue: Int, Sendable, Codable, CaseIterable, EcoreValue {
    /// The red literal.
    // @generated
    case red = 0

    /// The green literal.
    // @generated
    case green = 2

    /// The blue literal.
    // @generated
    case blue = 3

    /// The text that stands for the literal in a serialised model.
    // @generated
    public var literalText: String {
        switch self {
        case .red: return "red"
        case .green: return "green"
        case .blue: return "blue"
        }
    }

    /// Creates the literal that a text stands for in a serialised model.
    ///
    /// - Parameter literalText: The text of the literal.
    // @generated
    public init?(literalText: String) {
        switch literalText {
        case "red": self = .red
        case "green": self = .green
        case "blue": self = .blue
        default: return nil
        }
    }
}
