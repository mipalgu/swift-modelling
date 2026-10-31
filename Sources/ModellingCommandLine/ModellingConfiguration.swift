//
// ModellingConfiguration.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ATL
import ECore
import Foundation
import MTL

/// The settings of a configuration file of the modelling tools.
///
/// A configuration file is a JSON object whose keys are the long names of the command-line
/// options that choose behaviours, without their leading hyphens, and `semantics` for the
/// preset. Every key is optional:
///
/// ```json
/// {
///   "semantics": "legacy",
///   "block-line-breaks": "acceleo",
///   "check-let-types": true,
///   "container-scope": "any-resource"
/// }
/// ```
///
/// The values are the spellings of the options on the command line, as JSON strings, except
/// for `check-let-types` and `cache-containers`, which take JSON booleans. ``keys`` lists the
/// accepted keys.
///
/// A command reads the file named ``fileName`` that ``discover(from:)`` finds from the current
/// directory, or the file that `--config` names (see ``SemanticsOptions``). An option given on
/// the command line overrides the file, and an option in the file overrides the preset, as
/// ``SemanticsSettings`` describes.
public struct ModellingConfiguration: Sendable, Equatable {
    /// The name of a configuration file, `.swift-modelling.json`.
    public static let fileName = ".swift-modelling.json"

    /// The name of the entry that marks the root of a repository, `.git`.
    ///
    /// ``discover(from:)`` looks no further up than the first directory with this entry, which
    /// may be a directory or, in a linked work tree, a file.
    public static let repositoryMarker = ".git"

    /// The kinds of JSON values that the keys of a configuration file take.
    public enum ValueKind: String, Sendable, Equatable {
        /// A JSON string that is one of the spellings of the option.
        case string = "a string"

        /// A JSON boolean, `true` or `false`.
        case boolean = "true or false"
    }

    /// The keys that a configuration file accepts.
    ///
    /// The keys are the long names of the options that ``SemanticsOptions``,
    /// ``MTLSemanticsOptions``, ``ATLSemanticsOptions``, ``LetTypeMismatchOptions`` and
    /// ``UnsetFeatureOptions`` define.
    public static let keys: [String] = [
        SemanticsOptions.OptionName.semantics,
        MTLSemanticsOptions.OptionName.blockLineBreaks,
        MTLSemanticsOptions.OptionName.collectionParameters,
        MTLSemanticsOptions.OptionName.checkLetTypes,
        MTLSemanticsOptions.OptionName.cacheContainers,
        MTLSemanticsOptions.OptionName.collectionArguments,
        MTLSemanticsOptions.OptionName.collectionKinds,
        MTLSemanticsOptions.OptionName.singleValueCollections,
        MTLSemanticsOptions.OptionName.containerLookup,
        ATLSemanticsOptions.OptionName.collectionRangeSyntax,
        SemanticsOptions.OptionName.containerScope,
        LetTypeMismatchOptions.optionName,
        UnsetFeatureOptions.optionName,
    ]

    /// The file that the settings were read from, or `nil` if they were not read from a file.
    public var url: URL?

    /// The preset of behaviours (`semantics`).
    public var semantics: SemanticsPreset?

    /// The line break after a block written on one line (`block-line-breaks`).
    public var blockLineBreaks: MTLBlockLineBreaks?

    /// The collections that conform to collection-typed parameters (`collection-parameters`).
    public var collectionParameters: MTLCollectionParameters?

    /// Whether `let` blocks check their values against the declared types (`check-let-types`).
    public var checksLetTypes: Bool?

    /// Whether containers are looked up only once per run (`cache-containers`).
    public var cachesContainers: Bool?

    /// How a collection passed to an operation that adds an element is treated
    /// (`collection-arguments`).
    public var collectionArguments: AQLCollectionArguments?

    /// Whether collections keep their kinds (`collection-kinds`).
    public var collectionKinds: AQLCollectionKinds?

    /// The collection that an arrow call on a single value sees (`single-value-collections`).
    public var singleValueCollections: AQLSingleValueCollections?

    /// How the containers of model objects are found (`container-lookup`).
    public var containerLookup: AQLContainerLookup?

    /// Whether ATL collection literals accept integer ranges (`collection-range-syntax`).
    public var collectionRangeSyntax: ATLCollectionRangeSyntax?

    /// The objects whose containers a model answers for (`container-scope`).
    public var containerLookupScope: ContainerLookupScope?

    /// How a typed `let` treats a value of another type (`let-type-mismatches`).
    public var letTypeMismatches: MTLLetTypeMismatches?

    /// How unset features read (`unset-features`).
    public var unsetFeatures: UnsetFeatureReads?

    /// Creates settings that set nothing, as when no configuration file is read.
    public init() {}

    /// Reads the settings of a configuration file.
    ///
    /// - Parameter url: The location of the file.
    /// - Throws: ``ModellingConfigurationError/unreadable(path:reason:)`` if the file does not
    ///   exist, is a directory or cannot be read, and the errors of ``init(data:url:)`` if its
    ///   contents are not valid settings.
    public init(contentsOf url: URL) throws(ModellingConfigurationError) {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
            throw .unreadable(path: url.path, reason: "it is a directory")
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw .unreadable(path: url.path, reason: error.localizedDescription)
        }
        try self.init(data: data, url: url)
    }

    /// Reads the settings of a configuration file from its contents.
    ///
    /// - Parameters:
    ///   - data: The contents of the file, a JSON object.
    ///   - url: The location of the file, which errors name and ``url`` keeps.
    /// - Throws: ``ModellingConfigurationError/malformed(path:reason:)`` if the contents are not
    ///   JSON, ``ModellingConfigurationError/notAnObject(path:)`` if they are not a JSON object,
    ///   ``ModellingConfigurationError/unknownKey(_:path:)`` for a key that is not one of
    ///   ``keys``, ``ModellingConfigurationError/wrongType(key:expected:path:)`` for a value of
    ///   the wrong JSON type, and ``ModellingConfigurationError/invalidValue(_:key:accepted:path:)``
    ///   for a string that is not one of the spellings of its option.
    public init(data: Data, url: URL) throws(ModellingConfigurationError) {
        let path = url.path
        let document: JSONValue
        do {
            document = try JSONDecoder().decode(JSONValue.self, from: data)
        } catch let DecodingError.dataCorrupted(context) {
            throw .malformed(path: path, reason: context.debugDescription)
        } catch {
            throw .malformed(path: path, reason: String(describing: error))
        }
        guard case .object(let object) = document else { throw .notAnObject(path: path) }
        if let unknown = object.keys.sorted().first(where: { !Self.keys.contains($0) }) {
            throw .unknownKey(unknown, path: path)
        }
        let reader = Reader(object: object, path: path)
        self.url = url
        semantics = try reader.value(of: SemanticsOptions.OptionName.semantics)
        blockLineBreaks = try reader.value(of: MTLSemanticsOptions.OptionName.blockLineBreaks)
        collectionParameters = try reader.value(of: MTLSemanticsOptions.OptionName.collectionParameters)
        checksLetTypes = try reader.flag(MTLSemanticsOptions.OptionName.checkLetTypes)
        cachesContainers = try reader.flag(MTLSemanticsOptions.OptionName.cacheContainers)
        collectionArguments = try reader.value(of: MTLSemanticsOptions.OptionName.collectionArguments)
        collectionKinds = try reader.value(of: MTLSemanticsOptions.OptionName.collectionKinds)
        singleValueCollections = try reader.value(of: MTLSemanticsOptions.OptionName.singleValueCollections)
        containerLookup = try reader.value(of: MTLSemanticsOptions.OptionName.containerLookup)
        collectionRangeSyntax = try reader.value(of: ATLSemanticsOptions.OptionName.collectionRangeSyntax)
        containerLookupScope = try reader.value(of: SemanticsOptions.OptionName.containerScope)
        letTypeMismatches = try reader.value(of: LetTypeMismatchOptions.optionName)
        unsetFeatures = try reader.value(of: UnsetFeatureOptions.optionName)
    }

    /// Finds the configuration file that applies to a directory.
    ///
    /// The directory and then each of its parent directories is checked for a file named
    /// ``fileName``, and the first one found is returned. The search stops after checking the
    /// first directory that contains an entry named ``repositoryMarker``, the root of the
    /// repository, or at the root of the file system. A directory named ``fileName`` is not a
    /// configuration file and is passed over.
    ///
    /// - Parameter directory: The directory to start from, usually the current directory.
    /// - Returns: The location of the configuration file, or `nil` if there is none.
    public static func discover(from directory: URL) -> URL? {
        let fileManager = FileManager.default
        var current = directory.standardizedFileURL
        while true {
            let candidate = current.appendingPathComponent(fileName)
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: candidate.path, isDirectory: &isDirectory), !isDirectory.boolValue {
                return candidate
            }
            if fileManager.fileExists(atPath: current.appendingPathComponent(repositoryMarker).path) {
                return nil
            }
            let parent = current.deletingLastPathComponent().standardizedFileURL
            guard parent.pathComponents.count < current.pathComponents.count else { return nil }
            current = parent
        }
    }
}

/// An error in reading a configuration file of the modelling tools.
///
/// Each error names the file, and where it concerns a key, the key; the description is a
/// message for the user.
public enum ModellingConfigurationError: Error, Sendable, Equatable, CustomStringConvertible {
    /// The file does not exist, is a directory, or cannot be read.
    ///
    /// - Parameters:
    ///   - path: The path of the file.
    ///   - reason: Why the file cannot be read.
    case unreadable(path: String, reason: String)

    /// The contents of the file are not JSON.
    ///
    /// - Parameters:
    ///   - path: The path of the file.
    ///   - reason: What the JSON parser reported.
    case malformed(path: String, reason: String)

    /// The contents of the file are JSON, but not a JSON object.
    ///
    /// - Parameter path: The path of the file.
    case notAnObject(path: String)

    /// The file has a key that is not one of ``ModellingConfiguration/keys``.
    ///
    /// - Parameters:
    ///   - key: The key.
    ///   - path: The path of the file.
    case unknownKey(String, path: String)

    /// The value of a key has the wrong JSON type.
    ///
    /// - Parameters:
    ///   - key: The key.
    ///   - expected: The kind of value that the key takes.
    ///   - path: The path of the file.
    case wrongType(key: String, expected: ModellingConfiguration.ValueKind, path: String)

    /// The value of a key is not one of the spellings of its option.
    ///
    /// - Parameters:
    ///   - value: The value found.
    ///   - key: The key.
    ///   - accepted: The spellings that the key accepts.
    ///   - path: The path of the file.
    case invalidValue(String, key: String, accepted: [String], path: String)

    /// A message that names the file, and the key, value and accepted values where they apply.
    public var description: String {
        switch self {
        case .unreadable(let path, let reason):
            return "Cannot read the configuration file \(path): \(reason)"
        case .malformed(let path, let reason):
            return "The configuration file \(path) is not valid JSON: \(reason)"
        case .notAnObject(let path):
            return "The configuration file \(path) does not hold a JSON object"
        case .unknownKey(let key, let path):
            return "Unknown key '\(key)' in the configuration file \(path): expected "
                + Self.alternatives(ModellingConfiguration.keys.map { "'\($0)'" })
        case .wrongType(let key, let expected, let path):
            return "The value of '\(key)' in the configuration file \(path) is not \(expected.rawValue)"
        case .invalidValue(let value, let key, let accepted, let path):
            return "Invalid value '\(value)' for '\(key)' in the configuration file \(path): expected "
                + Self.alternatives(accepted)
        }
    }

    /// Lists alternatives in prose.
    ///
    /// - Parameter values: The alternatives.
    /// - Returns: The alternatives separated by commas, with `or` before the last.
    private static func alternatives(_ values: [String]) -> String {
        guard let last = values.last else { return "" }
        let leading = values.dropLast()
        return leading.isEmpty ? last : leading.joined(separator: ", ") + " or " + last
    }
}

/// A JSON value of any kind.
private enum JSONValue: Decodable {
    case null
    case boolean(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    /// Decodes the value, trying each kind in turn.
    ///
    /// - Parameter decoder: The decoder to read from.
    /// - Throws: A decoding error if the value is of no kind.
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }
}

/// Reads the values of the keys of a configuration file.
private struct Reader {
    /// The object of the file.
    let object: [String: JSONValue]

    /// The path of the file, for errors.
    let path: String

    /// Reads the value of a key whose values are the spellings of an option.
    ///
    /// - Parameter key: The key.
    /// - Returns: The value, or `nil` if the key is absent.
    /// - Throws: ``ModellingConfigurationError`` if the value is not a string, or not a spelling.
    func value<Value: CaseIterable & RawRepresentable>(of key: String) throws(ModellingConfigurationError)
        -> Value?
    where Value.RawValue == String {
        guard let found = object[key] else { return nil }
        guard case .string(let text) = found else {
            throw .wrongType(key: key, expected: .string, path: path)
        }
        guard let value = Value(rawValue: text) else {
            throw .invalidValue(text, key: key, accepted: Value.allCases.map(\.rawValue), path: path)
        }
        return value
    }

    /// Reads the value of a key that takes a boolean.
    ///
    /// - Parameter key: The key.
    /// - Returns: The value, or `nil` if the key is absent.
    /// - Throws: ``ModellingConfigurationError/wrongType(key:expected:path:)`` if the value is
    ///   not a boolean.
    func flag(_ key: String) throws(ModellingConfigurationError) -> Bool? {
        guard let found = object[key] else { return nil }
        guard case .boolean(let value) = found else {
            throw .wrongType(key: key, expected: .boolean, path: path)
        }
        return value
    }
}
