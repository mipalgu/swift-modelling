//
// GenerateModelEncodingTests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for the character encoding in which `swift-ecore generate --model` reads a model in a
/// text format.
///
/// A metamodel written in KM3 is a model of a metamodel that describes Ecore packages, so it can
/// be exported with `--model`. A model that is not valid UTF-8 is read as ISO-8859-1 with a
/// warning on standard error that names it; `--encoding`, and the `encoding` key of the
/// configuration file, name the encoding instead.
@Suite("swift-ecore generate - model encodings", .serialized)
struct GenerateModelEncodingTests {
    /// A package name with characters outside US-ASCII.
    static let packageName = "Grüße"

    /// The name of the model file.
    static let modelFile = "greeting.km3"

    /// The name of the metamodel file.
    static let metamodelFile = "ecore.ecore"

    /// The output directory, relative to the repository.
    static let outputDirectory = "out"

    /// The warning that a file was read as ISO-8859-1.
    static let fallbackWarning = GenerateEncodingTests.fallbackWarning

    /// A metamodel whose class `EPackage` has the name of an Ecore package.
    static let metamodel = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" \
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" \
        xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="ecore" \
        nsURI="http://www.eclipse.org/emf/2002/Ecore" nsPrefix="ecore">
          <eClassifiers xsi:type="ecore:EClass" name="EPackage">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" \
        eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// A KM3 model whose package name has characters outside US-ASCII.
    static let model = """
        package \(packageName) {
          class Book {
            attribute title : String;
          }
        }
        package PrimitiveTypes {
          datatype String;
        }
        """

    /// A repository with the metamodel and the model in ISO-8859-1.
    struct Workspace {
        /// The root of the repository, which the tool runs in.
        let root: URL

        /// Creates the repository.
        init() throws {
            root = try createTemporaryDirectory()
            try FileManager.default.createDirectory(
                at: root.appendingPathComponent(".git"), withIntermediateDirectories: true)
            try GenerateModelEncodingTests.metamodel.write(
                to: root.appendingPathComponent(GenerateModelEncodingTests.metamodelFile),
                atomically: true, encoding: .utf8)
            let data = try #require(GenerateModelEncodingTests.model.data(using: .isoLatin1))
            try data.write(to: root.appendingPathComponent(GenerateModelEncodingTests.modelFile))
        }

        /// Writes the configuration file.
        ///
        /// - Parameter text: The contents of the file.
        func configure(_ text: String) throws {
            try text.write(
                to: root.appendingPathComponent(ConfigurationTests.configurationFile), atomically: true,
                encoding: .utf8)
        }

        /// Generates Alloy from the metamodel and exports the model, from the repository.
        ///
        /// - Parameter extra: The arguments after the metamodel, language, model and output.
        /// - Returns: The result of the command and the text of the files written.
        @MainActor
        func generate(_ extra: [String] = []) async throws -> (result: SubprocessResult, text: String) {
            let output = root.appendingPathComponent(GenerateModelEncodingTests.outputDirectory)
            try? FileManager.default.removeItem(at: output)
            let result = try await executeSwiftEcore(
                command: "generate",
                arguments: [
                    GenerateModelEncodingTests.metamodelFile, "--language", "alloy",
                    "--model", GenerateModelEncodingTests.modelFile,
                    "-o", GenerateModelEncodingTests.outputDirectory,
                ] + extra,
                workingDirectory: root)
            let files = (try? FileManager.default.contentsOfDirectory(at: output, includingPropertiesForKeys: nil)) ?? []
            let text = files.compactMap { try? String(contentsOf: $0, encoding: .utf8) }.joined()
            return (result, text)
        }

        /// Removes the repository.
        func remove() {
            cleanupTemporaryDirectory(root)
        }
    }

    @Test("a model that is not UTF-8 is read as ISO-8859-1 with a warning naming it")
    @MainActor
    func fallback() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (result, text) = try await workspace.generate()

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text.contains(Self.packageName), "\(text)")
        #expect(result.stderr.contains("warning: \(Self.modelFile): line "), "\(result.stderr)")
        #expect(result.stderr.contains(Self.fallbackWarning), "\(result.stderr)")
    }

    @Test("--encoding names the encoding of the model")
    @MainActor
    func explicit() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let latin1 = try await workspace.generate(["--encoding", "iso-8859-1"])
        let utf8 = try await workspace.generate(["--encoding", "UTF-8"])

        #expect(latin1.result.succeeded, "\(latin1.result.stdout)\(latin1.result.stderr)")
        #expect(latin1.text.contains(Self.packageName), "\(latin1.text)")
        #expect(!latin1.result.stderr.contains(Self.fallbackWarning), "\(latin1.result.stderr)")
        #expect(!utf8.result.succeeded)
        #expect((utf8.result.stdout + utf8.result.stderr).contains(Self.modelFile))
    }

    @Test("the configuration file names the encoding of the model, which --encoding overrides")
    @MainActor
    func configured() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.configure(#"{ "encoding": "ISO-8859-1" }"#)

        let configured = try await workspace.generate()
        let overridden = try await workspace.generate(["--encoding", "UTF-8"])

        #expect(configured.result.succeeded, "\(configured.result.stdout)\(configured.result.stderr)")
        #expect(configured.text.contains(Self.packageName), "\(configured.text)")
        #expect(!configured.result.stderr.contains(Self.fallbackWarning), "\(configured.result.stderr)")
        #expect(!overridden.result.succeeded)
    }
}
