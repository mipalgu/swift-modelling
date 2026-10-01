//
// GenModelServices+Text.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Foundation

extension GenModelServices {
    /// Text helpers that the AQL string library lacks.
    var textServices: [AQLService] {
        typealias Name = GenModelServiceName
        return [
            AQLService(Name.lines, receiver: .string) { call in
                AQLValues.collection(Self.lines(of: try call.receiverString()))
            },
            AQLService(Name.indentLines, receiver: .string, arity: 1) { call in
                Self.indentLines(of: try call.receiverString(), with: try call.string(0))
            },
        ]
    }

    /// Splits a text into lines at line feeds, carriage returns and carriage return line feed pairs.
    ///
    /// - Parameter text: The text to split.
    /// - Returns: The lines without their line breaks; an empty text yields one empty line.
    static func lines(of text: String) -> [String] {
        var result: [String] = []
        var current = ""
        var previousWasCarriageReturn = false
        for character in text.unicodeScalars {
            switch character {
            case "\r":
                result.append(current)
                current = ""
                previousWasCarriageReturn = true
            case "\n":
                if !previousWasCarriageReturn {
                    result.append(current)
                    current = ""
                }
                previousWasCarriageReturn = false
            default:
                current.unicodeScalars.append(character)
                previousWasCarriageReturn = false
            }
        }
        result.append(current)
        return result
    }

    /// Prefixes every line of a text except the first.
    ///
    /// Line breaks are normalised to line feeds.
    ///
    /// - Parameters:
    ///   - text: The text to indent.
    ///   - prefix: The text written after each line break.
    /// - Returns: The lines joined by line feeds followed by the prefix.
    static func indentLines(of text: String, with prefix: String) -> String {
        lines(of: text).joined(separator: "\n" + prefix)
    }
}
