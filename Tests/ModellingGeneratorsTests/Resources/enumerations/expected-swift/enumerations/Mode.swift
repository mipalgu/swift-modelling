//
//  Mode.swift
//

import EMFBase
import Foundation

/// The Mode enumeration.
// @generated
public enum Mode: Int, Sendable, Codable, CaseIterable, EcoreValue {
    /// The default literal.
    // @generated
    case `default` = 0

    /// The fastForward literal.
    // @generated
    case fastForward = 1

    /// The HTTPServer literal.
    // @generated
    case HTTPServer = 2

    /// The _ literal.
    // @generated
    case __ = 3

    /// The quote literal.
    // @generated
    case quote = 4

    /// The text that stands for the literal in a serialised model.
    // @generated
    public var literalText: String {
        switch self {
        case .`default`: return "default"
        case .fastForward: return "fastForward"
        case .HTTPServer: return "HTTPServer"
        case .__: return "_"
        case .quote: return "say \"hi\""
        }
    }

    /// Creates the literal that a text stands for in a serialised model.
    ///
    /// - Parameter literalText: The text of the literal.
    // @generated
    public init?(literalText: String) {
        switch literalText {
        case "default": self = .`default`
        case "fastForward": self = .fastForward
        case "HTTPServer": self = .HTTPServer
        case "_": self = .__
        case "say \"hi\"": self = .quote
        default: return nil
        }
    }
}
