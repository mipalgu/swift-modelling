//
// ModellingConfigurationTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ATL
import ECore
import Foundation
import MTL
import ModellingCommandLine
import Testing

/// A directory for the files of one test, removed when the test is done with it.
struct ScratchDirectory {
    /// The directory.
    let url: URL

    /// Creates an empty directory below the temporary directory.
    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("modelling-configuration-tests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    /// Creates a directory below this one, with its intermediate directories.
    ///
    /// - Parameter path: The relative path of the directory.
    /// - Returns: The directory.
    @discardableResult
    func directory(_ path: String) throws -> URL {
        let directory = url.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// Writes a text file below this directory, creating its directory.
    ///
    /// - Parameters:
    ///   - text: The contents of the file.
    ///   - path: The relative path of the file.
    /// - Returns: The file.
    @discardableResult
    func write(_ text: String, to path: String) throws -> URL {
        let file = url.appendingPathComponent(path)
        try FileManager.default.createDirectory(
            at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: file, atomically: true, encoding: .utf8)
        return file
    }

    /// Writes a configuration file into a directory below this one.
    ///
    /// - Parameters:
    ///   - text: The contents of the file.
    ///   - directory: The relative path of the directory, empty for this one.
    /// - Returns: The file.
    @discardableResult
    func writeConfiguration(_ text: String, in directory: String = "") throws -> URL {
        let path = directory.isEmpty
            ? ModellingConfiguration.fileName : "\(directory)/\(ModellingConfiguration.fileName)"
        return try write(text, to: path)
    }

    /// Marks a directory below this one as the root of a repository.
    ///
    /// - Parameters:
    ///   - directory: The relative path of the directory, empty for this one.
    ///   - asFile: Whether the marker is a file, as in a linked work tree, instead of a directory.
    func markRepository(_ directory: String = "", asFile: Bool = false) throws {
        let base = directory.isEmpty ? url : url.appendingPathComponent(directory)
        let marker = base.appendingPathComponent(ModellingConfiguration.repositoryMarker)
        if asFile {
            try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
            try "gitdir: elsewhere\n".write(to: marker, atomically: true, encoding: .utf8)
        } else {
            try FileManager.default.createDirectory(at: marker, withIntermediateDirectories: true)
        }
    }

    /// Removes the directory and its contents.
    func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}

/// Whether two optional file locations name the same path.
///
/// - Parameters:
///   - found: The location found, if any.
///   - expected: The location expected, if any.
/// - Returns: Whether both are `nil`, or both name the same standardised path.
func samePath(_ found: URL?, _ expected: URL?) -> Bool {
    found?.standardizedFileURL.path == expected?.standardizedFileURL.path
}

/// The error that reading a configuration throws, if any.
///
/// - Parameter body: Reads a configuration.
/// - Returns: The error, or `nil` if the configuration was read.
func configurationError(_ body: () throws(ModellingConfigurationError) -> ModellingConfiguration)
    -> ModellingConfigurationError?
{
    do {
        _ = try body()
        return nil
    } catch {
        return error
    }
}

@Suite("Modelling configuration file")
struct ModellingConfigurationTests {
    /// Reads a configuration from text, as if it came from a file.
    ///
    /// - Parameter text: The contents of the file.
    /// - Returns: The configuration.
    /// - Throws: ``ModellingConfigurationError`` if the text is not a valid configuration.
    private func parse(_ text: String) throws(ModellingConfigurationError) -> ModellingConfiguration {
        try ModellingConfiguration(data: Data(text.utf8), url: Self.file)
    }

    /// The location that the parsed text pretends to come from.
    private static let file = URL(fileURLWithPath: "/projects/example/.swift-modelling.json")

    // MARK: - Names

    @Test("names the file and the repository marker once")
    func names() {
        #expect(ModellingConfiguration.fileName == ".swift-modelling.json")
        #expect(ModellingConfiguration.repositoryMarker == ".git")
    }

    @Test("accepts the command-line names of the options as keys")
    func keys() {
        #expect(
            Set(ModellingConfiguration.keys) == [
                "semantics", "block-line-breaks", "collection-parameters", "check-let-types",
                "cache-containers", "collection-arguments", "collection-kinds", "single-value-collections",
                "container-lookup", "collection-range-syntax", "container-scope", "let-type-mismatches",
                "unset-features",
            ])
    }

    // MARK: - Valid contents

    @Test("reads an empty object as a configuration that sets nothing")
    func empty() throws {
        let configuration = try parse("{}")
        var expected = ModellingConfiguration()
        expected.url = Self.file
        #expect(configuration == expected)
        #expect(configuration.semantics == nil)
        #expect(configuration.containerLookupScope == nil)
    }

    @Test("reads every key")
    func everyKey() throws {
        let configuration = try parse(
            """
            {
              "semantics": "legacy",
              "block-line-breaks": "kept",
              "collection-parameters": "exact",
              "check-let-types": false,
              "cache-containers": true,
              "collection-arguments": "first-element",
              "collection-kinds": "sequences",
              "single-value-collections": "sequence",
              "container-lookup": "registered-objects",
              "collection-range-syntax": "eclipse",
              "container-scope": "this-resource",
              "let-type-mismatches": "skip",
              "unset-features": "undefined"
            }
            """)
        #expect(configuration.url == Self.file)
        #expect(configuration.semantics == .legacy)
        #expect(configuration.blockLineBreaks == .kept)
        #expect(configuration.collectionParameters == .exact)
        #expect(configuration.checksLetTypes == false)
        #expect(configuration.cachesContainers == true)
        #expect(configuration.collectionArguments == .firstElement)
        #expect(configuration.collectionKinds == .sequences)
        #expect(configuration.singleValueCollections == .sequence)
        #expect(configuration.containerLookup == .registeredObjects)
        #expect(configuration.collectionRangeSyntax == .eclipse)
        #expect(configuration.containerLookupScope == .thisResource)
        #expect(configuration.letTypeMismatches == .skip)
        #expect(configuration.unsetFeatures == .undefined)
    }

    @Test("reads each preset and scope", arguments: SemanticsPreset.allCases, ContainerLookupScope.allCases)
    func presetAndScope(preset: SemanticsPreset, scope: ContainerLookupScope) throws {
        let configuration = try parse(
            #"{ "semantics": "\#(preset.rawValue)", "container-scope": "\#(scope.rawValue)" }"#)
        #expect(configuration.semantics == preset)
        #expect(configuration.containerLookupScope == scope)
    }

    // MARK: - Errors

    @Test("rejects text that is not JSON, naming the file")
    func malformed() {
        let error = configurationError { () throws(ModellingConfigurationError) in try parse(#"{ "semantics": "#) }
        guard case .malformed(let path, _) = error else {
            Issue.record("expected a malformed file, got \(String(describing: error))")
            return
        }
        #expect(path == Self.file.path)
        #expect(error?.description.contains(Self.file.path) == true)
    }

    @Test("rejects JSON that is not an object, naming the file", arguments: ["[]", #""legacy""#, "true", "1", "null"])
    func notAnObject(text: String) {
        let error = configurationError { () throws(ModellingConfigurationError) in try parse(text) }
        #expect(error == .notAnObject(path: Self.file.path))
        #expect(error?.description.contains(Self.file.path) == true)
    }

    @Test("rejects an unknown key, naming the file and the key")
    func unknownKey() {
        let error = configurationError { () throws(ModellingConfigurationError) in
            try parse(#"{ "semantics": "legacy", "colour": "blue" }"#)
        }
        #expect(error == .unknownKey("colour", path: Self.file.path))
        let description = error?.description ?? ""
        #expect(description.contains(Self.file.path))
        #expect(description.contains("colour"))
    }

    @Test(
        "rejects a value of the wrong type, naming the file and the key",
        arguments: [
            (#"{ "semantics": true }"#, "semantics"),
            (#"{ "block-line-breaks": 1 }"#, "block-line-breaks"),
            (#"{ "container-scope": ["this-resource"] }"#, "container-scope"),
            (#"{ "let-type-mismatches": null }"#, "let-type-mismatches"),
            (#"{ "check-let-types": "false" }"#, "check-let-types"),
            (#"{ "cache-containers": 0 }"#, "cache-containers"),
            (#"{ "unset-features": { "mode": "undefined" } }"#, "unset-features"),
        ])
    func wrongType(text: String, key: String) {
        let error = configurationError { () throws(ModellingConfigurationError) in try parse(text) }
        guard case .wrongType(let found, _, let path) = error else {
            Issue.record("expected a value of the wrong type, got \(String(describing: error))")
            return
        }
        #expect(found == key)
        #expect(path == Self.file.path)
        let description = error?.description ?? ""
        #expect(description.contains(Self.file.path))
        #expect(description.contains(key))
    }

    @Test(
        "rejects a value that is not an accepted spelling, naming the file, key, value and accepted values",
        arguments: [
            (#"{ "semantics": "0.6" }"#, "semantics", "0.6", ["standard", "legacy"]),
            (#"{ "semantics": "Legacy" }"#, "semantics", "Legacy", ["standard", "legacy"]),
            (#"{ "container-scope": "everywhere" }"#, "container-scope", "everywhere", ["any-resource", "this-resource"]),
            (#"{ "collection-range-syntax": "sometimes" }"#, "collection-range-syntax", "sometimes", ["ocl", "eclipse"]),
            (#"{ "let-type-mismatches": "warn" }"#, "let-type-mismatches", "warn", ["error", "skip"]),
            (#"{ "unset-features": "" }"#, "unset-features", "", ["defaults", "undefined"]),
        ])
    func invalidValue(text: String, key: String, value: String, accepted: [String]) {
        let error = configurationError { () throws(ModellingConfigurationError) in try parse(text) }
        guard case .invalidValue(let found, let foundKey, let foundAccepted, let path) = error else {
            Issue.record("expected an invalid value, got \(String(describing: error))")
            return
        }
        #expect(found == value)
        #expect(foundKey == key)
        #expect(Set(foundAccepted) == Set(accepted))
        #expect(path == Self.file.path)
        let description = error?.description ?? ""
        for text in [Self.file.path, key, "'\(value)'"] + accepted {
            #expect(description.contains(text), "\(text) is missing from: \(description)")
        }
    }

    // MARK: - Files

    @Test("reads a file")
    func readsFile() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        let file = try scratch.writeConfiguration(#"{ "semantics": "legacy" }"#)

        let configuration = try ModellingConfiguration(contentsOf: file)

        #expect(configuration.semantics == .legacy)
        #expect(configuration.url == file)
    }

    @Test("reports a missing file, naming it")
    func missingFile() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        let file = scratch.url.appendingPathComponent("absent.json")

        let error = configurationError { () throws(ModellingConfigurationError) in
            try ModellingConfiguration(contentsOf: file)
        }

        guard case .unreadable(let path, _) = error else {
            Issue.record("expected an unreadable file, got \(String(describing: error))")
            return
        }
        #expect(path == file.path)
        #expect(error?.description.contains(file.path) == true)
    }

    @Test("reports a directory in place of a file, naming it")
    func directoryInPlaceOfFile() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        let directory = try scratch.directory("folder.json")

        let error = configurationError { () throws(ModellingConfigurationError) in
            try ModellingConfiguration(contentsOf: directory)
        }

        guard case .unreadable(let path, _) = error else {
            Issue.record("expected an unreadable file, got \(String(describing: error))")
            return
        }
        #expect(path == directory.path)
    }

    @Test("names the file in which an error is found")
    func namesFileOfError() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        let file = try scratch.writeConfiguration(#"{ "semantic": "legacy" }"#)

        let error = configurationError { () throws(ModellingConfigurationError) in
            try ModellingConfiguration(contentsOf: file)
        }

        #expect(error == .unknownKey("semantic", path: file.path))
    }

    // MARK: - Discovery

    @Test("finds the file in the start directory")
    func discoversInStart() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()
        let file = try scratch.writeConfiguration("{}")

        #expect(samePath(ModellingConfiguration.discover(from: scratch.url), file))
    }

    @Test("finds the file in a parent directory below the repository root")
    func discoversInParent() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()
        let file = try scratch.writeConfiguration("{}", in: "project")
        let start = try scratch.directory("project/sources/module")

        #expect(samePath(ModellingConfiguration.discover(from: start), file))
    }

    @Test("finds the file beside the repository marker", arguments: [false, true])
    func discoversAtRepositoryRoot(markerIsFile: Bool) throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository("repository", asFile: markerIsFile)
        let file = try scratch.writeConfiguration("{}", in: "repository")
        let start = try scratch.directory("repository/sources")

        #expect(samePath(ModellingConfiguration.discover(from: start), file))
    }

    @Test("does not look above the first directory with a repository marker", arguments: [false, true])
    func stopsAtRepositoryRoot(markerIsFile: Bool) throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()
        try scratch.writeConfiguration(#"{ "semantics": "legacy" }"#)
        try scratch.markRepository("repository", asFile: markerIsFile)
        let start = try scratch.directory("repository/sources/module")

        #expect(samePath(ModellingConfiguration.discover(from: start), nil))
    }

    @Test("prefers the nearest file")
    func nearestWins() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()
        try scratch.writeConfiguration(#"{ "semantics": "legacy" }"#)
        let nearest = try scratch.writeConfiguration(#"{ "semantics": "standard" }"#, in: "project")
        let start = try scratch.directory("project/sources")

        #expect(samePath(ModellingConfiguration.discover(from: start), nearest))
    }

    @Test("ignores a directory with the name of the file")
    func ignoresDirectories() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.markRepository()
        let file = try scratch.writeConfiguration("{}")
        try scratch.directory("project/\(ModellingConfiguration.fileName)")
        let start = try scratch.directory("project/sources")

        #expect(samePath(ModellingConfiguration.discover(from: start), file))
    }

    @Test("stops at the root of the file system")
    func stopsAtRoot() {
        let root = URL(fileURLWithPath: "/")
        let found = ModellingConfiguration.discover(from: root)
        #expect(found == nil || found?.deletingLastPathComponent().pathComponents == root.pathComponents)
    }
}
