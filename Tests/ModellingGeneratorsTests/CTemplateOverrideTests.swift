import Foundation
import Testing

@testable import ModellingGenerators

@Suite("Overriding the C templates")
struct CTemplateOverrideTests {
    @Test("A template path replaces the header module and nothing else")
    @MainActor
    func overridesHeader() async throws {
        let golden = try #require(CGoldenCase.named("library"))
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write(
            """
            [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
            [template public header(element : OclAny, fileName : String)]// Customised for [fileName/][/template]
            """, to: "Header.mtl")
        let generated = try await generateC(golden, options: GenerationOptions(templatePaths: [scratch.url]))
        defer { generated.remove() }

        let customised = try generated.text("library/library.h")
        let expected = try String(
            contentsOf: Fixtures.url(of: "library/expected-c/library/library.h"), encoding: .utf8)
        let header = "//\n//  library.h\n//\n//  Copyright 2026 Example Pty Ltd\n//\n"
        #expect(expected.hasPrefix(header))
        #expect(customised.hasPrefix("// Customised for library.h\n\n#ifndef LIBRARY_LIBRARY_H\n"))
        #expect(customised.dropFirst("// Customised for library.h".count) == expected.dropFirst(header.count - 1))
        #expect(try generated.text("library/library.c").hasPrefix("// Customised for library.c\n\n#include \"library/library.h\"\n"))
        #expect(try generated.text("EObject.h").hasPrefix("// Customised for EObject.h\n\n#ifndef EOBJECT_H\n"))
    }

    @Test("The type table can be replaced to map model types to other C types")
    @MainActor
    func overridesTypeTable() async throws {
        let golden = try #require(CGoldenCase.named("library"))
        let bundled = try TemplateSet.assemble(language: "c")
        defer { bundled.remove() }
        let table = try String(
            contentsOf: bundled.directory.appendingPathComponent("c-types.xmi"), encoding: .utf8)
        let replaced = table.replacingOccurrences(
            of: #"targetType="int32_t" storage="scalar" zeroValue="0" instanceClass="int" "#,
            with: #"targetType="long" storage="scalar" zeroValue="0" instanceClass="int" "#
        ).replacingOccurrences(
            of: #"targetType="char *" parameterType="const char *" storage="string" zeroValue="NULL" instanceClass="java.lang.String""#,
            with: #"targetType="unsigned char *" parameterType="const unsigned char *" storage="string" zeroValue="NULL" instanceClass="java.lang.String""#)
        #expect(replaced != table)
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write(replaced, to: "c-types.xmi")
        let generated = try await generateC(golden, options: GenerationOptions(templatePaths: [scratch.url]))
        defer { generated.remove() }

        let header = try generated.text("library/library.h")
        #expect(header.contains("    long pages;\n"))
        #expect(header.contains("long Book_get_pages(const Book *self);\n"))
        #expect(header.contains("    unsigned char *name;\n"))
        #expect(header.contains("const unsigned char *Book_get_name(const Book *self);\n"))
        #expect(header.contains("typedef unsigned char *ISBN;\n"))
        #expect(try generated.text("library/library.c").contains("    self->pages = 100;\n"))
    }

    @Test("A directory named after the language inside a template path is used")
    @MainActor
    func nestedOverride() async throws {
        let golden = try #require(CGoldenCase.named("bare"))
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write(
            """
            [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
            [template public header(element : OclAny, fileName : String)]// Nested[/template]
            """, to: "c/Header.mtl")
        let generated = try await generateC(golden, options: GenerationOptions(templatePaths: [scratch.url]))
        defer { generated.remove() }
        #expect(try generated.text("bare/bare.h").hasPrefix("// Nested\n"))
        #expect(try generated.text("bare/bare.c").hasPrefix("// Nested\n"))
    }

    @Test("The bundled C set is assembled with its modules and data")
    func bundledSet() throws {
        let set = try TemplateSet.assemble(language: "c")
        defer { set.remove() }
        #expect(set.descriptor.name == "c")
        #expect(set.descriptor.summary?.isEmpty == false)
        #expect(set.descriptor.mainModule == "generate")
        #expect(set.descriptor.mainTemplate == "generate")
        #expect(set.descriptor.dataModels.map(\.name) == ["types"])
        #expect(set.descriptor.fileCountTemplate == "fileCount")
        #expect(set.descriptor.layout.sourceRootSetting == "modelDirectory")
        #expect(!set.descriptor.layout.includeSourceRoot)
        #expect(set.descriptor.options.lineDelimiter == "\n")
        #expect(set.descriptor.styles.isEmpty && set.descriptor.defaultStyle == nil)
        for file in [
            "generate.mtl", "CNames.mtl", "CTypes.mtl", "CIncludes.mtl", "CDocumentation.mtl", "Header.mtl",
            "EObjectHeader.mtl", "PackageHeader.mtl", "PackageSource.mtl", "ClassQueries.mtl", "ClassHeader.mtl",
            "ClassSource.mtl", "ClassDescriptor.mtl", "EnumDeclaration.mtl", "DataTypeDeclaration.mtl",
            "TypeMapping.ecore", "c-types.xmi",
        ] {
            #expect(
                FileManager.default.fileExists(atPath: set.directory.appendingPathComponent(file).path),
                "\(file) is missing")
        }
    }
}
