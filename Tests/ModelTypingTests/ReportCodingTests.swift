//
//  ReportCodingTests.swift
//  ModelTypingTests
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import Foundation
import ModelTyping
import Testing

/// Tests of the JSON form of footprints and access modes, and of the hints and messages that
/// help a reader adapt a module.
@Suite("Report coding and guidance")
struct ReportCodingTests {
    /// A footprint that uses a class, a feature and a literal.
    private func footprint() -> MetamodelFootprint {
        var footprint = MetamodelFootprint(metamodelName: "library", role: .sourceAndTarget)
        footprint.record(className: "Book", Usage([.read, .instantiate]))
        footprint.record(feature: FeatureReference(className: "Book", featureName: "title"), Usage([.read, .write]))
        footprint.record(feature: FeatureReference(className: "Book", featureName: "pages"), Usage(.read, isCertain: false))
        footprint.record(literal: LiteralReference(enumerationName: "Genre", literalName: "poetry"), Usage(.read))
        return footprint
    }

    /// Encodes a value as a JSON object of Foundation types.
    private func json(_ value: some Encodable) throws -> Any {
        try JSONSerialization.jsonObject(with: try JSONEncoder().encode(value))
    }

    @Test("Access modes are written as the names of their uses")
    func accessNames() throws {
        #expect(try json(AccessMode([.read, .write, .instantiate])) as? [String] == ["read", "write", "instantiate"])
        #expect(try json(AccessMode.write) as? [String] == ["write"])
        #expect(try json(AccessMode()) as? [String] == [])
        let decoded = try JSONDecoder().decode(AccessMode.self, from: Data(#"["instantiate","read"]"#.utf8))
        #expect(decoded == [.read, .instantiate])
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(AccessMode.self, from: Data(#"["delete"]"#.utf8))
        }
        #expect(AccessMode.allNames == ["read", "write", "instantiate"])
    }

    @Test("Features and literals are written as arrays of objects, sorted, with readable access")
    func footprintShape() throws {
        let object = try #require(try json(footprint()) as? [String: Any])
        let features = try #require(object["features"] as? [[String: Any]])
        #expect(features.count == 2)
        #expect(features[0]["className"] as? String == "Book")
        #expect(features[0]["featureName"] as? String == "pages")
        #expect(features[0]["access"] as? [String] == ["read"])
        #expect(features[0]["isCertain"] as? Bool == false)
        #expect(features[1]["featureName"] as? String == "title")
        #expect(features[1]["access"] as? [String] == ["read", "write"])
        let literals = try #require(object["literals"] as? [[String: Any]])
        #expect(literals.count == 1)
        #expect(literals[0]["enumerationName"] as? String == "Genre")
        #expect(literals[0]["literalName"] as? String == "poetry")
        #expect(literals[0]["access"] as? [String] == ["read"])
        let classes = try #require(object["classes"] as? [String: [String: Any]])
        #expect(classes["Book"]?["access"] as? [String] == ["read", "instantiate"])
        #expect(object["role"] as? String == "sourceAndTarget")
        #expect(object["metamodelName"] as? String == "library")
    }

    @Test("Footprints round-trip through JSON")
    func footprintRoundTrip() throws {
        let original = footprint()
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode(MetamodelFootprint.self, from: data) == original)
        let whole = Footprint(metamodels: ["library": original], uncertainties: [])
        #expect(try JSONDecoder().decode(Footprint.self, from: try JSONEncoder().encode(whole)) == whole)
        let empty = MetamodelFootprint(metamodelName: "empty", role: .source)
        #expect(try JSONDecoder().decode(MetamodelFootprint.self, from: try JSONEncoder().encode(empty)) == empty)
    }

    @Test("A literal that has no near miss is hinted when it is the only unmatched literal")
    func uniqueLiteralHint() {
        let required = Build.modelType([
            Build.eClass("Book", [Build.attribute("genre", "Genre")]), Build.eEnum("Genre", ["fiction", "history"]),
        ])
        let provided = Build.modelType([
            Build.eClass("Book", [Build.attribute("genre", "Genre")]), Build.eEnum("Genre", ["fiction", "chronicle"]),
        ])
        var usage = MetamodelFootprint(metamodelName: "mm", role: .source)
        usage.record(literal: LiteralReference(enumerationName: "Genre", literalName: "history"), Usage(.read))
        let report = ModelTypeChecker().check(required: required, provided: provided, mode: .partial, footprint: usage)
        #expect(report.has(.missingLiteral, .error, at: "mm!Genre.history"))
        let hint = report.renamingHints.first { $0.kind == .literal }
        #expect(hint?.renamingEntry == "Genre.history=chronicle")
        #expect(hint?.reason == .uniqueStructuralCandidate)
        #expect(report.formatted().contains("hint: --rename Genre.history=chronicle (uniqueStructuralCandidate)"))
        let renamed = ModelTypeChecker(options: CheckOptions(renaming: report.suggestedRenaming))
            .check(required: required, provided: provided, mode: .partial, footprint: usage)
        #expect(renamed.compatible)
    }

    @Test("A literal is not hinted when several unmatched literals remain")
    func ambiguousLiteralHint() {
        let required = Build.modelType([Build.eEnum("Genre", ["fiction", "history"])])
        let provided = Build.modelType([Build.eEnum("Genre", ["fiction", "chronicle", "memoir"])])
        var usage = MetamodelFootprint(metamodelName: "mm", role: .source)
        usage.record(literal: LiteralReference(enumerationName: "Genre", literalName: "history"), Usage(.read))
        let report = ModelTypeChecker().check(required: required, provided: provided, mode: .partial, footprint: usage)
        #expect(report.has(.missingLiteral, .error, at: "mm!Genre.history"))
        #expect(!report.renamingHints.contains { $0.kind == .literal })
    }

    @Test("Widening is not applied by the published semantics, and the message says why")
    func wideningUnderPublishedSemantics() {
        let int = Build.modelType([Build.eClass("Book", [Build.attribute("pages", "EInt", changeable: false)])])
        let long = Build.modelType([Build.eClass("Book", [Build.attribute("pages", "ELong", changeable: false)])])
        var usage = MetamodelFootprint(metamodelName: "mm", role: .source)
        usage.record(feature: FeatureReference(className: "Book", featureName: "pages"), Usage(.read))
        for semantics in [MatchingSemantics.objectTypeMatching, .mofClassMatching] {
            let widening = CheckOptions(allowsNumericWidening: true, semantics: semantics)
            let report = ModelTypeChecker(options: widening).check(
                required: long, provided: int, mode: .partial, footprint: usage)
            #expect(report.has(.featureTypeMismatch, .error, at: "mm!Book.pages"), "\(semantics)")
            let message = report.errors.first?.message ?? ""
            #expect(message.contains("numeric widening applies only to the access-refined semantics"), "\(message)")
            let without = ModelTypeChecker(options: CheckOptions(semantics: semantics)).check(
                required: long, provided: int, mode: .partial, footprint: usage)
            let unasked = without.errors.map(\.message).joined(separator: "\n")
            #expect(!unasked.contains("widening"), "\(unasked)")
        }
        let refined = ModelTypeChecker(options: CheckOptions(allowsNumericWidening: true)).check(
            required: long, provided: int, mode: .partial, footprint: usage)
        #expect(refined.compatible)
    }
}
