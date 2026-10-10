import Foundation
import Testing

@testable import ModellingGenerators

@Suite("Overriding the Swift templates")
struct SwiftTemplateOverrideTests {
    @Test("A template path replaces the header module and nothing else")
    @MainActor
    func overridesHeader() async throws {
        let golden = try #require(SwiftGoldenCase.named("library"))
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write(
            """
            [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
            [template public header(element : OclAny, fileName : String)]// Customised for [fileName/][/template]
            """, to: "Header.mtl")
        let generated = try await generateSwift(golden, options: GenerationOptions(templatePaths: [scratch.url]))
        defer { generated.remove() }

        let customised = try generated.text("library/Book.swift")
        let expected = try String(
            contentsOf: Fixtures.url(of: "library/expected-swift/library/Book.swift"), encoding: .utf8)
        let header = "//\n//  Book.swift\n//\n//  Copyright 2026 Example Pty Ltd\n//\n"
        #expect(expected.hasPrefix(header))
        #expect(customised.hasPrefix("// Customised for Book\n\nimport ECore\n"))
        #expect(customised.dropFirst("// Customised for Book".count) == expected.dropFirst(header.count - 1))
    }

    @Test("The type table can be replaced to map a model type to another Swift type")
    @MainActor
    func overridesTypeTable() async throws {
        let golden = try #require(SwiftGoldenCase.named("library"))
        let bundled = try TemplateSet.assemble(language: "swift")
        defer { bundled.remove() }
        let table = try String(
            contentsOf: bundled.directory.appendingPathComponent("swift-types.xmi"), encoding: .utf8)
        let replaced = table.replacingOccurrences(
            of: #"targetType="String" zeroValue="nil" instanceClass="java.lang.String""#,
            with: #"targetType="Substring" zeroValue="nil" instanceClass="java.lang.String""#)
        #expect(replaced != table)
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write(replaced, to: "swift-types.xmi")
        let generated = try await generateSwift(golden, options: GenerationOptions(templatePaths: [scratch.url]))
        defer { generated.remove() }

        let named = try generated.text("library/Named.swift")
        #expect(named.contains("var name: Substring? { get set }"))
        #expect(try generated.text("library/ISBN.swift").contains("public typealias ISBN = Substring\n"))
    }

    @Test("A directory named after the language inside a template path is used")
    @MainActor
    func nestedOverride() async throws {
        let golden = try #require(SwiftGoldenCase.named("bare"))
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write(
            """
            [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
            [template public header(element : OclAny, fileName : String)]// Nested[/template]
            """, to: "swift/Header.mtl")
        let generated = try await generateSwift(golden, options: GenerationOptions(templatePaths: [scratch.url]))
        defer { generated.remove() }
        #expect(try generated.text("bare/Thing.swift").hasPrefix("// Nested\n"))
    }
}
