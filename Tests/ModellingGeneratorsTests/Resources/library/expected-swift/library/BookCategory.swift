//
//  BookCategory.swift
//
//  Copyright 2026 Example Pty Ltd
//

import EMFBase
import Foundation

/// The BookCategory enumeration.
// @generated
public enum BookCategory: Int, Sendable, Codable, CaseIterable, EcoreValue {
    /// The Mystery literal.
    // @generated
    case Mystery = 0

    /// The ScienceFiction literal.
    // @generated
    case ScienceFiction = 1

    /// The Biography literal.
    // @generated
    case Biography = 2

    /// The text that stands for the literal in a serialised model.
    // @generated
    public var literalText: String {
        switch self {
        case .Mystery: return "Mystery"
        case .ScienceFiction: return "ScienceFiction"
        case .Biography: return "Biography"
        }
    }

    /// Creates the literal that a text stands for in a serialised model.
    ///
    /// - Parameter literalText: The text of the literal.
    // @generated
    public init?(literalText: String) {
        switch literalText {
        case "Mystery": self = .Mystery
        case "ScienceFiction": self = .ScienceFiction
        case "Biography": self = .Biography
        default: return nil
        }
    }
}
