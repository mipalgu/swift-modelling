//
// ModelBinding.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ModellingCommandLine

/// A model that the command line binds to a name, as `--model` or `--target` gives it.
///
/// Programs refer to a model by its name or by one of its aliases, as in `Bank!Account.all`.
/// The value of the option is `name=file`, or `name,alias,...=file` to give the model aliases
/// as well, such as `Source,Bank=bank.xmi`.
struct ModelBinding: Sendable, Equatable {
    /// The name by which programs refer to the model.
    let name: String

    /// Further names by which programs may refer to the model.
    let aliases: [String]

    /// The path of the model file, as given on the command line.
    let path: String

    /// Every name by which programs may refer to the model, its name first.
    var names: [String] { [name] + aliases }

    /// The family of `name=file` options that bind models.
    static let option = KeyValueOption<String>(
        noun: SwiftEpsilonVocabulary.Noun.model, keyPlaceholder: KeyValueOptionSyntax.defaultKeyPlaceholder
    ) { _, path in
        guard !path.isEmpty else { throw MissingPath() }
        return path
    }

    /// Creates a binding.
    ///
    /// - Parameters:
    ///   - name: The name by which programs refer to the model.
    ///   - aliases: Further names for the model (default: none).
    ///   - path: The path of the model file.
    init(name: String, aliases: [String] = [], path: String) {
        self.name = name
        self.aliases = aliases
        self.path = path
    }

    /// Reads a binding from the value of a command line option.
    ///
    /// - Parameter argument: The value, such as `Bank=bank.xmi` or `Source,Bank=bank.xmi`.
    /// - Throws: `KeyValueOptionError` if the value is not `name=file` or the file is empty,
    ///   and ``SwiftEpsilonError/invalidModelName(_:)`` if a name is not an identifier.
    init(parsing argument: String) throws {
        let (key, path) = try Self.option.pair(argument)
        let names = key.split(separator: SwiftEpsilonVocabulary.Binding.aliasSeparator, omittingEmptySubsequences: false)
            .map(String.init)
        for candidate in names where !Identifier.isValid(candidate) {
            throw SwiftEpsilonError.invalidModelName(candidate)
        }
        self.init(name: names[0], aliases: Array(names.dropFirst()), path: path)
    }

    /// The reason why a binding without a file is rejected.
    struct MissingPath: Error, CustomStringConvertible {
        /// A phrase that says what is missing.
        var description: String { "expected the path of a model file" }
    }
}

/// A model that the command line asks to store after a successful run, as `--store` gives it.
///
/// The value of the option is the name of a model that `--model` binds, which is then written
/// back to its own file, or `name=file` to write it to another file.
struct StoreRequest: Sendable, Equatable {
    /// The name or an alias of the model.
    let name: String

    /// The file to write the model to, or `nil` to write it back to the file it was read from.
    let path: String?

    /// Creates a request.
    ///
    /// - Parameters:
    ///   - name: The name or an alias of the model.
    ///   - path: The file to write to, or `nil` (the default) for the file of the model.
    init(name: String, path: String? = nil) {
        self.name = name
        self.path = path
    }

    /// Reads a request from the value of a command line option.
    ///
    /// - Parameter argument: The value, such as `Bank` or `Bank=repaired.xmi`.
    /// - Throws: `KeyValueOptionError` if a file is given but empty, and
    ///   ``SwiftEpsilonError/invalidModelName(_:)`` if the name is not an identifier.
    init(parsing argument: String) throws {
        guard argument.contains(KeyValueOptionSyntax.separator) else {
            guard Identifier.isValid(argument) else { throw SwiftEpsilonError.invalidModelName(argument) }
            self.init(name: argument)
            return
        }
        let (name, path) = try ModelBinding.option.pair(argument)
        guard Identifier.isValid(name) else { throw SwiftEpsilonError.invalidModelName(name) }
        self.init(name: name, path: path)
    }
}

/// The rules for the names of models and parameters.
enum Identifier {
    /// Whether a text is an identifier: a letter or underscore followed by letters, digits and
    /// underscores.
    ///
    /// - Parameter text: The text.
    /// - Returns: `true` if the text is a non-empty identifier.
    static func isValid(_ text: String) -> Bool {
        guard let first = text.unicodeScalars.first,
            first == "_" || first.properties.isAlphabetic
        else { return false }
        return text.unicodeScalars.allSatisfy { $0 == "_" || $0.properties.isAlphabetic || ("0"..."9").contains($0) }
    }
}
