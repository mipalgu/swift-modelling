//
// MetamodelEncodingTests.swift
// swift-xtend-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Checks that `--encoding` applies to metamodels in text formats, such as KM3, as it does to
/// the sources of swift-xtend.
@Suite("swift-xtend - metamodels in text formats in the encoding of the run")
struct MetamodelEncodingTests {
    /// A KM3 metamodel whose first line holds a character outside ASCII, written in ISO-8859-1.
    static let metamodel = """
        -- Caf\u{E9} catalogue
        package shop {
          class Item {
            attribute name : String;
          }
        }
        package PrimitiveTypes {
          datatype String;
        }

        """

    /// A model of ``metamodel``, which refers to the package by its name.
    static let model = """
        <?xml version="1.0" encoding="UTF-8"?>
        <shop:Item xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:shop="shop" name="tea"/>

        """

    /// The warning of reading the metamodel as ISO-8859-1.
    static let fallback = "warning: Shop.km3: line 1, column 7: The text is not valid UTF-8 and was read as ISO-8859-1"

    /// The error of reading the metamodel as UTF-8.
    static let malformed = "Cannot read Shop.km3: the file is not valid UTF-8 text"

    /// The option that names the encoding.
    static let encodingOption = "--encoding"

    /// Writes the metamodel, the model and a program into a directory.
    ///
    /// - Parameters:
    ///   - directory: The directory.
    ///   - program: The text of the program.
    ///   - name: The file name of the program.
    /// - Throws: An error if a file cannot be written.
    static func write(into directory: URL, program: String, as name: String) throws {
        try metamodel.write(to: directory.appendingPathComponent("Shop.km3"), atomically: true, encoding: .isoLatin1)
        try model.write(to: directory.appendingPathComponent("item.xmi"), atomically: true, encoding: .utf8)
        try program.write(to: directory.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }

    @Test("reads a Latin-1 KM3 metamodel with a warning, in the encoding given, or not at all")
    func km3Metamodel() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let program = """
            import shop.Item

            class Names {
                def name(Item item) {
                    item.name
                }
            }

            """
        try Self.write(into: directory, program: program, as: "Names.xtend")
        func run(_ arguments: [String]) async throws -> (succeeded: Bool, output: String, error: String) {
            let result = try await runSwiftXtend(arguments, in: directory)
            return (result.succeeded, result.output, result.error)
        }
        let arguments = ["run", "Names.xtend", "--method", "name", "--model", "item.xmi", "--metamodel", "Shop.km3"]
        let detected = try await run(arguments)
        let latin1 = try await run(arguments + [Self.encodingOption, "latin1"])
        let wrong = try await run(arguments + [Self.encodingOption, "UTF-8"])

        let expected = "tea"
        #expect(detected.succeeded, "\(detected.error)")
        #expect(detected.output.trimmingCharacters(in: .whitespacesAndNewlines) == expected)
        #expect(detected.error.contains(Self.fallback), "\(detected.error)")
        #expect(latin1.succeeded, "\(latin1.error)")
        #expect(latin1.output.trimmingCharacters(in: .whitespacesAndNewlines) == expected)
        #expect(!latin1.error.contains("ISO-8859-1"), "\(latin1.error)")
        #expect(!wrong.succeeded)
        #expect((wrong.output + wrong.error).contains(Self.malformed), "\(wrong.output)\(wrong.error)")
    }
}
