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
            AQLService(Name.characterCodes, receiver: .string) { call in
                AQLValues.collection(try call.receiverString().utf16.map { Int($0) })
            },
            AQLService(Name.fromCharacterCode, receiver: .number) { call in
                guard let code = AQLValues.integer(call.receiver), let unit = UInt16(exactly: code) else {
                    throw AQLExecutionError.typeError("\(call.name) requires a UTF-16 code unit")
                }
                return String(utf16CodeUnits: [unit], count: 1)
            },
            AQLService(Name.toHexString, receiver: .number, arity: 0...1) { call in
                try Self.formatNumber(call, radix: 16)
            },
            AQLService(Name.toOctalString, receiver: .number, arity: 0...1) { call in
                try Self.formatNumber(call, radix: 8)
            },
            AQLService(Name.join, receiver: .collection, arity: 0...1) { call in
                let separator = call.arguments.isEmpty ? "" : try call.string(0)
                return call.receiverElements().map { AQLValues.description(of: $0) }
                    .joined(separator: separator)
            },
            AQLService(Name.detailKeys, receiver: .custom { $0 is EAnnotation }) { call in
                let annotation = call.receiver as? EAnnotation
                return AQLValues.collection((annotation.map { Array($0.details.keys) } ?? []).map { $0 })
            },
            AQLService(Name.detailValue, receiver: .custom { $0 is EAnnotation }, arity: 1) { call in
                (call.receiver as? EAnnotation)?.details[try call.string(0)]
            },
        ]
    }

    /// Writes an integer in a radix, padded with leading zeros.
    ///
    /// The receiver is the number; the optional argument is the minimum number of digits.
    ///
    /// - Parameters:
    ///   - call: The service call.
    ///   - radix: The radix of the notation.
    /// - Returns: The digits, in lower case.
    /// - Throws: ``AQLExecutionError/typeError(_:)`` if the receiver is not an integer.
    static func formatNumber(_ call: AQLServiceCall, radix: Int) throws -> String {
        guard let number = AQLValues.integer(call.receiver) else {
            throw AQLExecutionError.typeError("\(call.name) requires an integer receiver")
        }
        let digits = String(number, radix: radix)
        let width = call.arguments.isEmpty ? 0 : try call.integer(0)
        return String(repeating: "0", count: max(0, width - digits.count)) + digits
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
