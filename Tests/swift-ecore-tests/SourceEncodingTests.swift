//
// SourceEncodingTests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Text documents saved in ISO-8859-1, as older tools saved them, for `--encoding`.
private enum LegacyDocuments {
    /// The warning of a file that is read as ISO-8859-1 because it is not valid UTF-8.
    static let fallbackWarning = "The text is not valid UTF-8 and was read as ISO-8859-1"

    /// A KM3 metamodel whose first comment holds an e with an acute accent in ISO-8859-1.
    static let metamodel = "-- Biblioth\u{E8}que (fichier h\u{E9}rit\u{E9})\n"
        + "-- @nsURI http://www.example.org/library\n-- @nsPrefix lib\n"
        + "package Library {\n  class Book {\n    attribute title : String;\n  }\n}\n"
        + "package PrimitiveTypes {\n  datatype String;\n}\n"

    /// A model of the metamodel, in XMI.
    static let model = """
        <?xml version="1.0" encoding="UTF-8"?>
        <Library:Book xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:Library="http://www.example.org/library" title="Notes"/>
        """

    /// A Complete OCL document whose comment holds an e with an acute accent in ISO-8859-1.
    static let constraints = "-- R\u{E8}gles\npackage Library\ncontext Book\ninv Titled: title.size() > 0\nendpackage\n"

    /// Writes the documents into a new temporary directory.
    ///
    /// - Returns: The directory and the paths of the metamodel, the model and the constraints.
    static func write() throws -> (directory: URL, metamodel: String, model: String, constraints: String) {
        let directory = try createTemporaryDirectory()
        let metamodelURL = directory.appendingPathComponent("Library.km3")
        let modelURL = directory.appendingPathComponent("book.xmi")
        let constraintsURL = directory.appendingPathComponent("rules.ocl")
        try #require(metamodel.data(using: .isoLatin1)).write(to: metamodelURL)
        try model.write(to: modelURL, atomically: true, encoding: .utf8)
        try #require(constraints.data(using: .isoLatin1)).write(to: constraintsURL)
        return (directory, metamodelURL.path, modelURL.path, constraintsURL.path)
    }
}

@Suite("swift-ecore - Encoding of text documents")
struct SourceEncodingTests {
    /// The commands that read documents, with the arguments that read the metamodel.
    static func readingCommands(_ metamodel: String) -> [(String, [String])] {
        [
            ("inspect", [metamodel]), ("validate", [metamodel]), ("statistics", [metamodel]),
            ("query", [metamodel, "--query", "classes"]), ("compare", [metamodel, metamodel]),
        ]
    }

    @Test("reads a document that is not UTF-8 as ISO-8859-1 with a warning, or without one when its encoding is named")
    @MainActor
    func namedEncoding() async throws {
        let files = try LegacyDocuments.write()
        defer { cleanupTemporaryDirectory(files.directory) }
        let output = files.directory.appendingPathComponent("Library.ecore").path
        for (command, arguments) in Self.readingCommands(files.metamodel) + [("convert", [files.metamodel, output, "--force"])] {
            let detected = try await executeSwiftEcore(command: command, arguments: arguments)
            let named = try await executeSwiftEcore(command: command, arguments: arguments + ["--encoding", "latin1"])

            #expect(detected.succeeded, "\(command): \(detected.stdout)\(detected.stderr)")
            #expect(detected.stderr.contains(LegacyDocuments.fallbackWarning), "\(command): \(detected.stderr)")
            #expect(named.succeeded, "\(command): \(named.stdout)\(named.stderr)")
            #expect(!named.stderr.contains(LegacyDocuments.fallbackWarning), "\(command): \(named.stderr)")
        }
    }

    @Test("rejects a document that is not valid in the encoding named")
    @MainActor
    func invalidInNamedEncoding() async throws {
        let files = try LegacyDocuments.write()
        defer { cleanupTemporaryDirectory(files.directory) }
        for (command, arguments) in Self.readingCommands(files.metamodel) {
            let result = try await executeSwiftEcore(command: command, arguments: arguments + ["--encoding", "UTF-8"])

            #expect(result.exitCode == 1, "\(command): \(result.stdout)\(result.stderr)")
        }
    }

    @Test("reads the metamodels and the Complete OCL documents in the encoding named")
    @MainActor
    func metamodelsAndConstraints() async throws {
        let files = try LegacyDocuments.write()
        defer { cleanupTemporaryDirectory(files.directory) }
        let arguments = [files.model, "--metamodel", files.metamodel, "--ocl", files.constraints]

        let detected = try await executeSwiftEcore(command: "validate", arguments: arguments)
        let named = try await executeSwiftEcore(command: "validate", arguments: arguments + ["--encoding", "ISO-8859-1"])
        let constraintsOnly = try await executeSwiftEcore(
            command: "inspect", arguments: [files.metamodel, "--ocl", files.constraints, "--encoding", "latin1"])

        #expect(detected.succeeded, "\(detected.stdout)\(detected.stderr)")
        #expect(detected.stderr.components(separatedBy: LegacyDocuments.fallbackWarning).count == 3, "\(detected.stderr)")
        #expect(named.succeeded, "\(named.stdout)\(named.stderr)")
        #expect(named.stdout.contains("OCL invariants: 1 of 1 check(s) satisfied"), "\(named.stdout)")
        #expect(!named.stderr.contains(LegacyDocuments.fallbackWarning), "\(named.stderr)")
        #expect(constraintsOnly.succeeded, "\(constraintsOnly.stdout)\(constraintsOnly.stderr)")
        #expect(!constraintsOnly.stderr.contains(LegacyDocuments.fallbackWarning), "\(constraintsOnly.stderr)")
    }

    @Test("documents --encoding in the help of every command that reads documents")
    @MainActor
    func help() async throws {
        for command in ["inspect", "validate", "statistics", "query", "compare", "convert"] {
            let result = try await executeSwiftEcore(command: command, arguments: ["--help"])

            #expect(result.stdout.contains("--encoding <"), "\(command): \(result.stdout)")
            #expect(result.stdout.contains("ISO-8859-1"), "\(command): \(result.stdout)")
        }
    }
}
