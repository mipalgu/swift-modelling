//
//  MTLFootprintTests.swift
//  ModelTypingTests
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import ModelTyping
import MTL
import Testing

/// A self-authored catalogue generator written against the first library version.
let catalogueModule = """
    [module generateCatalogue('http://example.org/library/1.0')/]

    [template public main(library : library::Library)]
    [file (library.name + '.txt', overwrite)]
    [for (book : library::Book | library.books)]
    [book.title/] by [book.authors.name->sep(', ')/][if (book.genre = library::Genre::poetry)] (poem)[/if]
    [book.describe()/] [book.isbn.shout()/]
    [/for]
    [let count : Integer = library.writers->size()][count/] writers[/let]
    [/file]
    [/template]

    [template public describe(book : library::Book)][book.pages/] pages[/template]

    [query public prolific(writer : library::Writer) : Boolean = writer.books->size() > 3 /]

    [query public recent(library : library::Library) : Sequence(library::Book) = library.books->select(b | b.pages > 0) /]

    [template public summary(library : library::Library)][library.recent().title/][/template]
    """

@Suite("MTL footprints")
struct MTLFootprintTests {
    /// Extracts the footprint of an MTL module against the first library version.
    private func footprint(_ source: String) async throws -> (MetamodelFootprint, Footprint) {
        let binding = MetamodelBinding(name: "library", modelType: try await Fixtures.modelType("LibraryV1"))
        let footprint = try await MTLFootprintExtractor(bindings: [binding]).footprint(ofSource: source)
        return (try #require(footprint[metamodel: "library"]), footprint)
    }

    @Test("Templates, queries, blocks and embedded expressions contribute to the footprint")
    func catalogue() async throws {
        let (usage, footprint) = try await footprint(catalogueModule)
        #expect(usage.classNames == ["Book", "Library", "Writer"])
        #expect(usage.featureNames == [
            "Book.authors", "Book.genre", "Book.isbn", "Book.pages", "Book.title", "Library.books", "Library.name",
            "Library.writers", "Writer.books", "Writer.name",
        ])
        #expect(usage.literals.keys.map(\.description) == ["Genre.poetry"])
        #expect(usage.features.values.allSatisfy { $0.access == .read && $0.isCertain })
        #expect(footprint.isComplete, "\(footprint.uncertainties)")
    }

    @Test("Protected areas, traces, let and else-if blocks are visited")
    func blocks() async throws {
        let (usage, _) = try await footprint("""
            [module m('http://example.org/library/1.0')/]
            [template public main(book : library::Book)]
            [protected (book.isbn)]keep[/protected]
            [if (book.pages > 100)]long[elseif (book.pages > 10)]medium[else][book.title/][/if]
            [let first : library::Writer = book.authors->first()][first.born/][/let]
            [/template]
            """)
        #expect(usage.featureNames == ["Book.authors", "Book.isbn", "Book.pages", "Book.title", "Writer.born"])
    }

    @Test("Guards are visited with the template parameters bound")
    func guards() async throws {
        let (usage, _) = try await footprint("""
            [module m('http://example.org/library/1.0')/]
            [template public main(book : library::Book) ? (book.genre <> library::Genre::fiction)][book.title/][/template]
            """)
        #expect(usage.featureNames == ["Book.genre", "Book.title"])
        #expect(usage.literals.keys.map(\.description) == ["Genre.fiction"])
    }

    @Test("Unparsable modules are rejected")
    func parseFailure() async throws {
        await #expect(throws: FootprintExtractionError.self) { try await footprint("[module") }
    }
}
