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

    /// The Amber literal.
    // @generated
    case Amber = 1

    /// The Green literal.
    // @generated
    case Green = 5

    /// The Yellow literal, which has the value of Amber.
    // @generated
    public static let Yellow: Colour = .Amber

    /// The text that stands for the literal in a serialised model.
    // @generated
    public var literalText: String {
        switch self {
        case .Red: return "red"
        case .Amber: return "amber"
        case .Green: return "Green"
        }
    }

    /// Creates the literal that a text stands for in a serialised model.
    ///
    /// - Parameter literalText: The text of the literal.
    // @generated
    public init?(literalText: String) {
        switch literalText {
        case "red": self = .Red
        case "amber": self = .Amber
        case "yellow": self = .Yellow
        case "Green": self = .Green
        default: return nil
        }
    }
}
