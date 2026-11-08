//
//  ModelTypeTests.swift
//  ModelTypingTests
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import ECore
import ModelTyping
import Testing

@Suite("Model types")
struct ModelTypeTests {
    @Test("Object types flatten inherited properties and keep own ones")
    func flattening() async throws {
        let library = try await Fixtures.modelType("LibraryV1")
        let book = try #require(library.objectType(named: "Book"))
        #expect(book.ownPropertyNames == ["title", "pages", "isbn", "genre", "authors"])
        #expect(Set(book.properties.keys) == ["id", "title", "pages", "isbn", "genre", "authors"])
        #expect(book.property(named: "id")?.declaringClassName == "Item")
        #expect(book.directSuperTypeNames == ["Item"])
        #expect(book.allSuperTypeNames == ["Item"])
        #expect(library.objectType(named: "Item")?.isInstantiable == false)
    }

    @Test("Properties capture type, multiplicity, containment and opposites")
    func properties() async throws {
        let library = try await Fixtures.modelType("LibraryV1")
        let authors = try #require(library.objectType(named: "Book")?.property(named: "authors"))
        #expect(authors.kind == .reference)
        #expect(authors.typeName == "Writer")
        #expect(authors.typeKind == .objectType)
        #expect(authors.lowerBound == 1)
        #expect(authors.upperBound == PropertyType.unbounded)
        #expect(authors.isMany)
        #expect(authors.multiplicityDescription == "[1..*]")
        #expect(authors.oppositeName == "books")
        #expect(!authors.isContainment)
        let books = try #require(library.objectType(named: "Library")?.property(named: "books"))
        #expect(books.isContainment)
        let genre = try #require(library.objectType(named: "Book")?.property(named: "genre"))
        #expect(genre.typeKind == .enumeration)
        #expect(library.enumerations["Genre"]?.literalNames == ["fiction", "nonFiction", "poetry"])
        let pages = try #require(library.objectType(named: "Book")?.property(named: "pages"))
        #expect(pages.typeKind == .dataType)
        #expect(pages.typeName == "EInt")
    }

    @Test("Qualified lookup accepts package names and namespace prefixes")
    func qualifiedLookup() async throws {
        let library = try await Fixtures.modelType("LibraryV1")
        #expect(library.objectType(named: "library::Book")?.name == "Book")
        #expect(library.objectType(named: "lib::Book")?.name == "Book")
        #expect(library.objectType(named: "other::Book") == nil)
        #expect(library.objectType(named: "Nothing") == nil)
        #expect(library.containsPackage(namedOrPrefixed: "lib"))
    }

    @Test("Conformance follows the transitive subclass relation")
    func conformance() async throws {
        let refined = try await Fixtures.modelType("LibraryV1Refined")
        #expect(refined.conforms("Book", to: "Entity"))
        #expect(refined.conforms("Book", to: "Book"))
        #expect(!refined.conforms("Entity", to: "Book"))
        #expect(!refined.conforms("Book", to: "Missing"))
        #expect(refined.subclassNames(of: "Item") == ["Item", "Book", "Magazine"])
    }

    @Test("Qualified names split at the last separator", arguments: [
        ("Families!Member", "Families", "Member"), ("library::Book", "library", "Book"),
        ("a::b::C", "a::b", "C"), ("Plain", nil, "Plain"),
    ] as [(String, String?, String)])
    func splitting(text: String, qualifier: String?, name: String) {
        let split = ModelType.splitQualifiedName(text)
        #expect(split.qualifier == qualifier)
        #expect(split.name == name)
    }

    @Test("Written type names unwrap collection constructors", arguments: [
        ("Sequence(Families!Family)", 1, "Families", "Family", false),
        ("OrderedSet(Set(library::Book))", 2, "library", "Book", false),
        ("String", 0, nil, "String", true), ("TupleType(a : Integer)", 0, nil, "TupleType(a : Integer)", true),
        ("Map(String, Integer)", 0, nil, "Map(String, Integer)", true),
    ] as [(String, Int, String?, String, Bool)])
    func writtenTypes(text: String, depth: Int, qualifier: String?, name: String, primitive: Bool) {
        let written = WrittenTypeName(text)
        #expect(written.collectionDepth == depth)
        #expect(written.qualifier == qualifier)
        #expect(written.name == name)
        #expect(written.isPrimitive == primitive)
    }

    @Test("Canonical data types widen only within their chain")
    func widening() {
        #expect(CanonicalDataType.integer32.widens(to: .integer64))
        #expect(CanonicalDataType.integer32.widens(to: .integer32))
        #expect(!CanonicalDataType.integer64.widens(to: .integer32))
        #expect(CanonicalDataType.real32.widens(to: .decimal))
        #expect(!CanonicalDataType.integer32.widens(to: .real64))
        #expect(!CanonicalDataType.string.widens(to: .integer32))
        #expect(CanonicalDataType.string.wideningChain == [.string])
    }

    @Test("Static types expose their element types")
    func staticTypes() {
        let book = StaticType.object(metamodel: "lib", className: "Book")
        #expect(StaticType.collection(.collection(book)).elementType == book)
        #expect(StaticType.collection(book).isCollection)
        #expect(!book.isCollection)
        #expect(StaticType.collection(.collection(book)).flattenedCollection == .collection(book))
        #expect(StaticType.unknown.isUnknown)
        #expect(book.description == "lib!Book")
        #expect(StaticType.collection(.dataValue("string")).description == "Collection(string)")
        #expect(StaticType.module.description == "thisModule")
        #expect(StaticType.typeLiteral(metamodel: "lib", className: "Book").description == "type lib!Book")
        #expect(StaticType.enumeration(metamodel: "lib", name: "Genre").description == "lib!Genre")
        #expect(StaticType.unknown.description == "?")
    }
}
