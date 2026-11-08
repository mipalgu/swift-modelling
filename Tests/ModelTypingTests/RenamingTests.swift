//
//  RenamingTests.swift
//  ModelTypingTests
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import ModelTyping
import Testing

@Suite("Renamings and name similarity")
struct RenamingTests {
    @Test("Entries split into classifier and member renamings")
    func parsing() throws {
        let renaming = try Renaming(parsing: ["Writer=Author, Library.writers = authors", "Genre.poetry=verse"])
        #expect(renaming.classifiers == ["Writer": "Author"])
        #expect(renaming.members == ["Library.writers": "authors", "Genre.poetry": "verse"])
        #expect(renaming.entries == ["Genre.poetry=verse", "Library.writers=authors", "Writer=Author"])
        #expect(!renaming.isEmpty)
        #expect(Renaming.identity.isEmpty)
    }

    @Test("Malformed entries are rejected", arguments: ["Writer", "=Author", "Writer=", "a=b=c"])
    func malformed(entry: String) {
        #expect(throws: RenamingError.malformedEntry(entry)) { try Renaming(parsing: [entry]) }
    }

    @Test("Member renamings are found through any listed owner")
    func memberLookup() {
        let renaming = Renaming(classifiers: ["Writer": "Author"], members: ["Item.id": "identifier"])
        #expect(renaming.providedClassifierName(for: "Writer") == "Author")
        #expect(renaming.providedClassifierName(for: "Book") == "Book")
        #expect(renaming.providedMemberName(for: "id", ownedBy: ["Book", "Item"]) == "identifier")
        #expect(renaming.providedMemberName(for: "title", ownedBy: ["Book"]) == "title")
    }

    @Test("Edit distance counts transpositions as one edit and ignores case", arguments: [
        ("title", "titel", 1), ("isbn", "ISBN", 0), ("Writer", "Writers", 1), ("", "abc", 3), ("abc", "", 3),
        ("kitten", "sitting", 3), ("same", "same", 0),
    ])
    func editDistance(lhs: String, rhs: String, expected: Int) {
        #expect(NameSimilarity.editDistance(lhs, rhs) == expected)
    }

    @Test("Near misses are ranked closest first with their reasons")
    func nearMisses() {
        let misses = NameSimilarity.nearMisses(of: "title", among: ["titel", "TITLE", "bookTitle", "pages", "title"])
        #expect(misses.map(\.name) == ["TITLE", "titel", "bookTitle"])
        #expect(misses.map(\.reason) == [.caseDifference, .nearMissName, .containedName])
        #expect(NameSimilarity.nearMisses(of: "id", among: ["xid", "identifier"], maximumDistance: 0).isEmpty)
        #expect(NameSimilarity.nearMissThreshold(for: "ab") == 1)
        #expect(NameSimilarity.nearMissThreshold(for: "firstName") == 3)
    }

    @Test("Jaccard similarity compares name sets")
    func jaccard() {
        #expect(NameSimilarity.jaccard(["a", "b"], ["a", "b"]) == 1)
        #expect(NameSimilarity.jaccard(["a", "b"], ["b", "c"]) == 1.0 / 3.0)
        #expect(NameSimilarity.jaccard([], []) == 0)
    }

    @Test("Hints render as renaming entries")
    func hintEntries() {
        let feature = RenamingHint(kind: .feature, metamodel: "lib", owner: "Book", requiredName: "isbn",
                                   suggestedName: "ISBN", reason: .caseDifference, distance: 0)
        #expect(feature.renamingEntry == "Book.isbn=ISBN")
        #expect(feature.description == "lib: Book.isbn=ISBN (caseDifference, distance 0)")
        let classifier = RenamingHint(kind: .classifier, metamodel: "lib", requiredName: "Writer",
                                      suggestedName: "Author", reason: .similarStructure, distance: 6)
        #expect(classifier.renamingEntry == "Writer=Author")
    }
}
