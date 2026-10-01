//
// GenModelServices+Naming.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Foundation
import GenModel

extension GenModelServices {
    /// The name formatting services, offered on generator elements and on text.
    ///
    /// On a generator element they format the name of the Ecore element it describes; on text
    /// they format the text itself.
    var namingServices: [AQLService] {
        typealias Name = GenModelServiceName
        let provider = self
        var result: [AQLService] = [
            AQLService(Name.name, receiver: genElementReceiver) { call in
                try provider.element(of: call).name
            }
        ]
        let formats: [(String, @Sendable (String) -> String)] = [
            (Name.capName, { GenModelNaming.capName($0) }),
            (Name.uncapName, { GenModelNaming.uncapName($0) }),
            (Name.uncapPrefixedName, { GenModelNaming.uncapPrefixedName($0) }),
            (Name.upperName, { GenModelNaming.upperName($0) }),
        ]
        for (name, format) in formats {
            result.append(
                AQLService(name, receiver: genElementReceiver) { call in
                    format(try provider.element(of: call).name)
                })
            result.append(
                AQLService(name, receiver: .string) { call in
                    format(try call.receiverString())
                })
        }
        result.append(
            AQLService(Name.formatName, receiver: .string, arity: 1...3) { call in
                try Self.formatName(call)
            })
        return result
    }

    /// Splits a text into words and joins them again.
    ///
    /// The receiver is the text. The first argument is the separator character, the second is an
    /// optional prefix that is recognised as a separate word, the third states whether a
    /// recognised prefix is kept.
    ///
    /// - Parameter call: The service call.
    /// - Returns: The reformatted text.
    /// - Throws: ``AQLExecutionError/typeError(_:)`` if an argument has the wrong type.
    static func formatName(_ call: AQLServiceCall) throws -> String {
        let separator = try call.string(0)
        guard separator.count == 1, let character = separator.first else {
            throw AQLExecutionError.typeError("\(call.name) requires a one character separator")
        }
        let prefix = call.argument(1) as? String
        let includePrefix = call.argument(2) as? Bool ?? false
        return GenModelNaming.format(
            try call.receiverString(), separator: character, prefix: prefix?.isEmpty == true ? nil : prefix,
            includePrefix: includePrefix)
    }
}
