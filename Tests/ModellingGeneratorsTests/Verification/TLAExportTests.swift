//
// TLAExportTests.swift
// ModellingGeneratorsTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@testable import ModellingGenerators

/// Details of the TLA+ export that the lending fixtures do not exercise.
@Suite("TLA+ export")
struct TLAExportTests {
    /// The text of an exported file, found by its file name.
    ///
    /// - Parameters:
    ///   - name: The file name.
    ///   - files: The exported files, by relative path.
    /// - Returns: The text of the file.
    private func file(_ name: String, in files: [String: String]) throws -> String {
        try #require(files.first { ($0.key as NSString).lastPathComponent == name }?.value)
    }

    /// A value of a data type that the export does not interpret is written as text, and the
    /// set of such values of the model fixes the constant of the data type.
    @Test("Values of uninterpreted data types are exported as text")
    func uninterpretedValues() async throws {
        let model = try TLAVariantModels.write("rated", replacing: [("pages=\"320\"", "pages=\"320\" rating=\"4.5\"")])
        let files = try await VerificationExports.model(model, .tla)
        let module = try file("rated_instance.tla", in: files)
        #expect(module.contains("InstanceEDoubleValues == {\"4.5\"}"))
        #expect(module.contains("rating |-> \"4.5\""))
        let configuration = try file("rated_instance.cfg", in: files)
        #expect(configuration.contains("EDoubleValues <- InstanceEDoubleValues"))
    }

    /// The metamodel module declares a constant for the values of each uninterpreted data type.
    @Test("Uninterpreted data types are constants of the metamodel module")
    func uninterpretedConstants() async throws {
        let module = try file("lending.tla", in: try await VerificationExports.metamodel(.tla))
        #expect(module.contains("CONSTANT EDoubleValues"))
        #expect(module.contains("rating: EDoubleValues \\cup {Null}"))
    }
}
