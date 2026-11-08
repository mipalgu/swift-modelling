//
// LoadWarningTests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import Testing

/// Tests for metamodels with several root packages or without a namespace, and for files whose
/// extension names no format.
@Suite("swift-ecore - root packages, load warnings and file formats", .serialized)
struct LoadWarningTests {
    /// A metamodel whose first root package, of data types, has no namespace, as in KM3.
    static let withoutNamespace = """
        <?xml version="1.0" encoding="UTF-8"?>
        <xmi:XMI xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore">
          <ecore:EPackage name="Primitives">
            <eClassifiers xsi:type="ecore:EDataType" name="Text" instanceClassName="java.lang.String"/>
          </ecore:EPackage>
          <ecore:EPackage name="people" nsURI="http://example.org/people" nsPrefix="people">
            <eClassifiers xsi:type="ecore:EClass" name="Person">
              <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" eType="#/0/Text"/>
            </eClassifiers>
          </ecore:EPackage>
        </xmi:XMI>

        """

    /// A model whose root object is an instance of the second root package of ``withoutNamespace``.
    static let person = """
        <?xml version="1.0" encoding="UTF-8"?>
        <people:Person xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:people="http://example.org/people" name="Alex"/>

        """

    /// The warnings that ``withoutNamespace`` causes, without the name of the file.
    static let warnings = [
        "The package 'Primitives' has no 'nsURI' and is not registered under a namespace",
        "The package 'Primitives' has no 'nsPrefix' and is not registered under a namespace",
    ]

    /// A directory with the metamodel and the model.
    struct Files {
        /// The directory.
        let directory: URL

        /// The metamodel.
        var metamodel: URL { directory.appendingPathComponent("People.ecore") }

        /// The model.
        var model: URL { directory.appendingPathComponent("person.xmi") }

        /// Creates the files.
        init() throws {
            directory = try createTemporaryDirectory()
            try LoadWarningTests.withoutNamespace.write(to: metamodel, atomically: true, encoding: .utf8)
            try LoadWarningTests.person.write(to: model, atomically: true, encoding: .utf8)
        }

        /// Writes another file into the directory.
        ///
        /// - Parameters:
        ///   - text: The contents.
        ///   - name: The name of the file.
        /// - Returns: The file.
        func write(_ text: String, named name: String) throws -> URL {
            let url = directory.appendingPathComponent(name)
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        }

        /// Removes the directory.
        func remove() { cleanupTemporaryDirectory(directory) }
    }

    @Test("reads a metamodel whose root package has no namespace, warning on standard error",
        arguments: ["inspect", "statistics", "validate"])
    @MainActor
    func metamodelWithoutNamespace(command: String) async throws {
        let files = try Files()
        defer { files.remove() }

        let result = try await executeSwiftEcore(command: command, arguments: [files.metamodel.path])

        for warning in Self.warnings {
            #expect(result.stderr.contains("warning: \(files.metamodel.path): \(warning)"), "\(command): \(result.stderr)")
        }
        #expect(!result.stdout.contains("warning:"), "\(command): \(result.stdout)")
        if command == "validate" {
            #expect(!result.succeeded)
            let output = result.stdout + result.stderr
            #expect(output.contains("The namespace URI '' is not well formed"), "\(output)")
        } else {
            #expect(result.succeeded, "\(command): \(result.stdout)\(result.stderr)")
            #expect(result.stdout.contains(command == "inspect" ? "Package Primitives" : "Packages: 2"), "\(result.stdout)")
        }
    }

    @Test(
        "load warnings follow the lines printed before them when both streams share a pipe",
        arguments: [
            (command: "inspect", output: nil, before: "Inspecting: "),
            (command: "convert", output: "People.km3", before: "Reading Ecore"),
        ] as [(command: String, output: String?, before: String)])
    @MainActor
    func warningsFollowEarlierOutput(command: String, output: String?, before: String) async throws {
        let files = try Files()
        defer { files.remove() }
        let target = output.map { files.directory.appendingPathComponent($0).path }

        let result = try await executeSwiftEcoreWithCombinedOutput(
            command: command, arguments: ["--verbose", files.metamodel.path] + (target.map { [$0] } ?? []))

        #expect(result.succeeded, "\(command): \(result.stdout)")
        let lines = result.stdout.split(whereSeparator: \.isNewline).map(String.init)
        let earlier = try #require(lines.firstIndex { $0.hasPrefix(before) }, "\(command): \(result.stdout)")
        let warning = try #require(lines.firstIndex { $0.hasPrefix("warning: ") }, "\(command): \(result.stdout)")
        #expect(earlier < warning, "\(command): \(result.stdout)")
    }

    @Test("an inspection report follows the load warnings when both streams share a pipe")
    @MainActor
    func reportFollowsWarnings() async throws {
        let files = try Files()
        defer { files.remove() }

        let result = try await executeSwiftEcoreWithCombinedOutput(command: "inspect", arguments: [files.metamodel.path])

        #expect(result.succeeded, "\(result.stdout)")
        let lines = result.stdout.split(whereSeparator: \.isNewline).map(String.init)
        let warning = try #require(lines.lastIndex { $0.hasPrefix("warning: ") }, "\(result.stdout)")
        let report = try #require(lines.firstIndex { $0.hasPrefix("Metamodel: ") }, "\(result.stdout)")
        #expect(warning < report, "\(result.stdout)")
    }

    @Test("compares metamodels whose root package has no namespace, warning on standard error")
    @MainActor
    func compareWithoutNamespace() async throws {
        let files = try Files()
        defer { files.remove() }

        let result = try await executeSwiftEcore(command: "compare", arguments: [files.metamodel.path, files.metamodel.path])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stderr.contains("warning: \(files.metamodel.path): \(Self.warnings[0])"), "\(result.stderr)")
    }

    @Test("registers every root package of a metamodel given with --metamodel")
    @MainActor
    func everyRootPackage() async throws {
        let files = try Files()
        defer { files.remove() }

        let inspection = try await executeSwiftEcore(
            command: "inspect", arguments: [files.model.path, "--metamodel", files.metamodel.path])
        let validation = try await executeSwiftEcore(
            command: "validate", arguments: [files.model.path, "--metamodel", files.metamodel.path])

        #expect(inspection.succeeded, "\(inspection.stdout)\(inspection.stderr)")
        #expect(inspection.stdout.contains("Metamodels: http://example.org/people\n"), "\(inspection.stdout)")
        #expect(validation.succeeded, "\(validation.stdout)\(validation.stderr)")
        #expect(validation.stderr.contains("warning: \(files.metamodel.path): \(Self.warnings[0])"), "\(validation.stderr)")
    }

    @Test("reads a model whose extension names no format in the format of its contents")
    @MainActor
    func unknownExtension() async throws {
        let files = try Files()
        defer { files.remove() }
        let renamed = try files.write(Self.person, named: "person.model")

        let result = try await executeSwiftEcore(
            command: "inspect", arguments: [renamed.path, "--metamodel", files.metamodel.path])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.hasPrefix("Model: person.model (XMI)\n"), "\(result.stdout)")
        #expect(result.stdout.contains("Person: 1"), "\(result.stdout)")
    }

    @Test("reports contents that are neither XML nor JSON, listing the supported formats",
        arguments: ["inspect", "statistics", "validate", "query"])
    @MainActor
    func unsupportedContents(command: String) async throws {
        let files = try Files()
        defer { files.remove() }
        let text = try files.write("Alex is a person\n", named: "person.txt")

        let result = try await executeSwiftEcore(
            command: command, arguments: command == "query" ? [text.path, "--query", "count"] : [text.path])

        #expect(!result.succeeded)
        let supported = ModelFormat.allCases.map(\.rawValue).joined(separator: ", ")
        #expect(result.stderr.contains("Unsupported format: txt (supported: \(supported))"), "\(command): \(result.stderr)")
    }
}
