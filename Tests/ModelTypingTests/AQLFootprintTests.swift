//
//  AQLFootprintTests.swift
//  ModelTypingTests
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import AQL
import ModelTyping
import Testing

@Suite("AQL footprints")
struct AQLFootprintTests {
    /// Extracts the footprint of an AQL expression against the first library version.
    private func footprint(_ source: String, _ variables: [String: String] = ["self": "library::Library"]) async throws
        -> (MetamodelFootprint, Footprint)
    {
        let binding = MetamodelBinding(name: "library", modelType: try await Fixtures.modelType("LibraryV1"))
        let footprint = try AQLFootprintExtractor(bindings: [binding]).footprint(ofSource: source, variables: variables)
        return (try #require(footprint[metamodel: "library"]), footprint)
    }

    @Test("Navigations through iterators are typed by the iterated elements")
    func navigation() async throws {
        let (usage, footprint) = try await footprint("self.books->select(b | b.pages > 100).title")
        #expect(usage.featureNames == ["Book.pages", "Book.title", "Library.books"])
        #expect(usage.classNames == ["Library"])
        #expect(usage.access("Book.title") == .read)
        #expect(usage.features.values.allSatisfy { $0.isCertain })
        #expect(footprint.isComplete)
        #expect(usage.role == .source)
    }

    @Test("Implicit iterators resolve bare names as features of the element")
    func implicitIterator() async throws {
        let (usage, footprint) = try await footprint("self.books->select(pages > 1)->collect(isbn)")
        #expect(usage.featureNames == ["Book.isbn", "Book.pages", "Library.books"])
        #expect(footprint.isComplete)
    }

    @Test("Type literals, allInstances, type tests, casts and filters record classes")
    func typeOperations() async throws {
        let (usage, _) = try await footprint(
            "library::Book.allInstances()->select(b | b.oclIsKindOf(library::Item))->filter(library::Book).title")
        #expect(usage.classNames == ["Book", "Item", "Library"])
        #expect(usage.featureNames == ["Book.title"])
        let (cast, _) = try await footprint("self.oclAsType(library::Writer).born", ["self": "ecore::EObject"])
        #expect(cast.featureNames == ["Writer.born"])
        let (contents, _) = try await footprint("self.eAllContents(library::Writer)->collect(w | w.name)")
        #expect(contents.featureNames == ["Writer.name"])
        #expect(contents.classNames == ["Library", "Writer"])
    }

    @Test("Inherited features are recorded through the accessing class")
    func inherited() async throws {
        let (usage, _) = try await footprint("self.books.id")
        #expect(usage.featureNames == ["Book.id", "Library.books"])
    }

    @Test("Enumeration literals are recorded")
    func literals() async throws {
        let (usage, _) = try await footprint("self.books->select(b | b.genre = library::Genre::poetry)")
        #expect(usage.literals.keys.map(\.description) == ["Genre.poetry"])
        #expect(usage.featureNames == ["Book.genre", "Library.books"])
    }

    @Test("Let bindings, conditionals and collection literals keep their types")
    func structure() async throws {
        let (usage, footprint) = try await footprint("""
            let first = self.books->first() in if first.title <> '' then Sequence{first}.authors.name else self.name endif
            """)
        #expect(usage.featureNames == ["Book.authors", "Book.title", "Library.books", "Library.name", "Writer.name"])
        #expect(footprint.isComplete)
    }

    @Test("Standard services keep or change types as declared", arguments: [
        ("self.books->asSet()->sortedBy(b | b.title)->first().isbn", "Book.isbn"),
        ("self.writers->collect(w | w.books)->flatten()->any(b | b.pages > 1).genre", "Book.genre"),
        ("self.books->reject(b | b.isbn.size() > 3)->last().title", "Book.title"),
        ("self.books->exists(b | b.title.startsWith('A'))", "Book.title"),
        ("self.books->forAll(b | b.pages > 0)", "Book.pages"),
        ("self.books->closure(b | b.authors.books)->size()", "Writer.books"),
    ])
    func services(source: String, expected: String) async throws {
        let (usage, footprint) = try await footprint(source)
        #expect(usage.featureNames.contains(expected), "\(usage.featureNames)")
        #expect(footprint.isComplete, "\(footprint.uncertainties)")
    }

    @Test("Unknown receiver types lead to uncertain uses of every candidate owner")
    func unknownReceiver() async throws {
        let (usage, footprint) = try await footprint("self.eContainer().name")
        #expect(usage.featureNames == ["Library.name", "Writer.name"])
        #expect(usage.features.values.allSatisfy { !$0.isCertain })
        #expect(footprint.uncertainties.map(\.kind) == [.unknownReceiverType])
        #expect(footprint.uncertainties.first?.detail.contains("library!Library, library!Writer") == true)
        #expect(!footprint.isComplete)
    }

    @Test("Features declared only by subclasses are recorded there, uncertainly")
    func subclassFeatures() async throws {
        let (usage, footprint) = try await footprint("self.title", ["self": "library::Item"])
        #expect(usage.featureNames == ["Book.title"])
        #expect(usage.features.values.first?.isCertain == false)
        #expect(footprint.uncertainties.map(\.kind) == [.featureInSubclass])
    }

    @Test("Unknown features, variables and types are reported", arguments: [
        ("self.colour", FootprintUncertaintyKind.unknownFeature),
        ("nobody.name", .unknownVariable),
        ("other::Thing.allInstances()", .unknownType),
        ("library::Shelf.allInstances()", .unknownType),
        ("self.size().name", .unknownFeature),
    ])
    func gaps(source: String, kind: FootprintUncertaintyKind) async throws {
        let (_, footprint) = try await footprint(source, source.hasPrefix("nobody") ? [:] : ["self": "library::Library"])
        #expect(footprint.uncertainties.map(\.kind).contains(kind), "\(footprint.uncertainties)")
    }

    @Test("Unparsable expressions are rejected")
    func parseFailure() async throws {
        let binding = MetamodelBinding(name: "library", modelType: try await Fixtures.modelType("LibraryV1"))
        #expect(throws: FootprintExtractionError.self) {
            try AQLFootprintExtractor(bindings: [binding]).footprint(ofSource: "self.(", variables: [:])
        }
    }
}
