//
//  Mood.swift
//

import EMFBase
import Foundation

/// The Mood enumeration.
// @generated
public enum Mood: Sendable, Codable, CaseIterable, EcoreValue {
    /// The text that stands for the literal in a serialised model.
    // @generated
    public var literalText: String {
        switch self {
        }
    }

    /// Creates the literal that a text stands for in a serialised model.
    ///
    /// - Parameter literalText: The text of the literal.
    // @generated
    public init?(literalText: String) {
        switch literalText {
        default: return nil
        }
    }

    /// Fails, because an enumeration without literals has no value to decode.
    ///
    /// - Parameter decoder: The decoder that holds the encoded value.
    /// - Throws: A decoding error, always.
    // @generated
    public init(from decoder: any Decoder) throws {
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: decoder.codingPath, debugDescription: "An enumeration without literals has no values."))
    }

    /// Encodes nothing, because an enumeration without literals has no values.
    ///
    /// - Parameter encoder: The encoder that receives the value.
    // @generated
    public func encode(to encoder: any Encoder) throws {
        switch self {
        }
    }
}
