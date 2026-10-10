import Foundation
import Testing

@testable import ModellingGenerators

@Suite("Overriding the C++ templates")
struct CppTemplateOverrideTests {
    /// The lines that every header starts with before its header comment.
    static let guardLines = "#pragma once\n\n"

    @Test("A template path replaces the header module and nothing else")
    @MainActor
    func overridesHeader() async throws {
        let golden = try #require(CppGoldenCase.named("library"))
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write(
            """
            [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
            [template public header(element : OclAny, fileName : String)]// Customised for [fileName/][/template]
            """, to: "Header.mtl")
        let generated = try await generateCpp(golden, options: GenerationOptions(templatePaths: [scratch.url]))
        defer { generated.remove() }

        let customised = try generated.text("library/Book.hpp")
        let expected = try String(
            contentsOf: Fixtures.url(of: "library/expected-cpp/library/Book.hpp"), encoding: .utf8)
        let header = "//\n//  Book.hpp\n//\n//  Copyright 2026 Example Pty Ltd\n//\n"
        #expect(expected.hasPrefix(Self.guardLines + header))
        #expect(customised.hasPrefix(Self.guardLines + "// Customised for Book\n\n#include \"EObject.hpp\"\n"))
        #expect(
            customised.dropFirst((Self.guardLines + "// Customised for Book").count)
                == expected.dropFirst((Self.guardLines + header).count - 1))
    }

    @Test("The type table can be replaced to map a model type to another C++ type")
    @MainActor
    func overridesTypeTable() async throws {
        let golden = try #require(CppGoldenCase.named("library"))
        let bundled = try TemplateSet.assemble(language: "cpp")
        defer { bundled.remove() }
        let table = try String(
            contentsOf: bundled.directory.appendingPathComponent("cpp-types.xmi"), encoding: .utf8)
        let replaced = table.replacingOccurrences(
            of: #"targetType="std::string" instanceClass="java.lang.String""#,
            with: #"targetType="std::wstring" instanceClass="java.lang.String""#)
        #expect(replaced != table)
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write(replaced, to: "cpp-types.xmi")
        let generated = try await generateCpp(golden, options: GenerationOptions(templatePaths: [scratch.url]))
        defer { generated.remove() }

        let named = try generated.text("library/Named.hpp")
        #expect(named.contains("    virtual const std::wstring &getName() const = 0;"))
        #expect(try generated.text("library/ISBN.hpp").contains("using ISBN = std::wstring;\n"))
    }

    @Test("The reserved words can be replaced to claim another name")
    @MainActor
    func overridesReservedWords() async throws {
        let golden = try #require(CppGoldenCase.named("library"))
        let bundled = try TemplateSet.assemble(language: "cpp")
        defer { bundled.remove() }
        let table = try String(
            contentsOf: bundled.directory.appendingPathComponent("cpp-types.xmi"), encoding: .utf8)
        let replaced = table.replacingOccurrences(
            of: "</typemapping:TypeTable>", with: "  <reservedWords word=\"Writer\" kind=\"type\"/>\n</typemapping:TypeTable>")
        #expect(replaced != table)
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write(replaced, to: "cpp-types.xmi")
        let generated = try await generateCpp(golden, options: GenerationOptions(templatePaths: [scratch.url]))
        defer { generated.remove() }

        #expect(Set(generated.generatedPaths()).contains("library/Writer_.hpp"))
        #expect(!Set(generated.generatedPaths()).contains("library/Writer.hpp"))
        #expect(try generated.text("library/Writer_.hpp").contains("class Writer_ final : public virtual Named {"))
        #expect(try generated.text("library/Book.hpp").contains("    std::weak_ptr<Writer_> m_author;\n"))
    }

    @Test("A directory named after the language inside a template path is used")
    @MainActor
    func nestedOverride() async throws {
        let golden = try #require(CppGoldenCase.named("bare"))
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write(
            """
            [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
            [template public header(element : OclAny, fileName : String)]// Nested[/template]
            """, to: "cpp/Header.mtl")
        let generated = try await generateCpp(golden, options: GenerationOptions(templatePaths: [scratch.url]))
        defer { generated.remove() }
        #expect(try generated.text("bare/Thing.hpp").hasPrefix(Self.guardLines + "// Nested\n"))
    }
}
