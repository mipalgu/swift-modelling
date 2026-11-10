//
// ModelEncodingTests.swift
// ModellingGeneratorsTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation
import Testing

@testable import ModellingGenerators

/// Tests for the character encoding in which a model export reads a model in a text format.
///
/// A metamodel written in KM3 is a model of a metamodel that describes Ecore packages, so a
/// model export can read it. A model that is not valid UTF-8 is read as ISO-8859-1 with a
/// decoding warning, unless ``GenerationOptions/modelEncoding`` names its encoding.
@Suite("Generation - model encodings")
struct ModelEncodingTests {
    /// A package name with characters outside US-ASCII.
    static let packageName = "Grüße"

    /// The name of the model file.
    static let modelFile = "greeting.km3"

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

    /// Exports the KM3 model, written in ISO-8859-1, to Alloy.
    ///
    /// - Parameter encoding: The encoding of the model, or `nil` for UTF-8 with a fallback.
    /// - Returns: The result of the export, the model file and the text of the files written.
    /// - Throws: The error of the export.
    @MainActor
    private func export(encoding: TextEncoding?) async throws
        -> (result: GenerationResult, model: URL, text: String)
    {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write(Self.metamodel, to: "ecore.ecore")
        let model = scratch.url.appendingPathComponent(Self.modelFile)
        try #require(Self.model.data(using: .isoLatin1)).write(to: model)
        let output = scratch.url.appendingPathComponent("out")
        var options = GenerationOptions(mtlOptions: .standard)
        options.modelEncoding = encoding
        let result = try await GenerationPipeline.generate(
            modelURL: model, metamodelURL: scratch.url.appendingPathComponent("ecore.ecore"),
            language: VerificationTarget.alloy.templateSetName, outputDirectory: output, options: options)
        let text = try result.files.map { try String(contentsOf: $0, encoding: .utf8) }.joined()
        return (result, model, text)
    }

    @Test("the options read a model in UTF-8 by default")
    func defaults() {
        #expect(GenerationOptions(mtlOptions: .standard).modelEncoding == nil)
        #expect(GenerationOptions(mtlOptions: .legacy).modelEncoding == nil)
    }

    @Test("a model that is not UTF-8 is read as ISO-8859-1 with a warning naming it")
    @MainActor
    func fallback() async throws {
        let (result, model, text) = try await export(encoding: nil)
        #expect(text.contains(Self.packageName), "\(text)")
        #expect(result.decodingWarnings.map(\.code) == [TextDecodingDiagnostic.decodedAsISOLatin1])
        #expect(result.decodingWarnings.first?.document == model.relativePath)
    }

    @Test("a model is read in the encoding of the options without a warning")
    @MainActor
    func explicit() async throws {
        let (result, _, text) = try await export(encoding: .isoLatin1)
        #expect(text.contains(Self.packageName), "\(text)")
        #expect(result.decodingWarnings.isEmpty)
    }

    @Test("a model that is not valid in the encoding of the options is rejected")
    @MainActor
    func malformed() async throws {
        await #expect(throws: GenerationError.self) {
            _ = try await export(encoding: .utf8)
        }
    }
}
