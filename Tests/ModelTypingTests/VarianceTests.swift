//
//  VarianceTests.swift
//  ModelTypingTests
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import ECore
import EMFBase
import ModelTyping
import Testing

/// Focused tests of the property matching rules, one rule at a time.
@Suite("Property matching variance")
struct VarianceTests {
    /// Checks a single feature use in partial mode.
    private func check(
        _ required: ModelType, _ provided: ModelType, _ className: String, _ feature: String, _ access: AccessMode,
        certain: Bool = true, options: CheckOptions = CheckOptions()
    ) -> CompatibilityReport {
        var footprint = MetamodelFootprint(metamodelName: "mm", role: .source)
        footprint.record(feature: FeatureReference(className: className, featureName: feature), Usage(access, isCertain: certain))
        return ModelTypeChecker(options: options).check(required: required, provided: provided, mode: .partial, footprint: footprint)
    }

    /// A shelf metamodel whose `items` reference is typed by the given class.
    private func shelves(itemsOf type: String, lower: Int = 0, upper: Int = -1, ordered: Bool = true,
                         unique: Bool = true, containment: Bool = false) -> ModelType {
        Build.modelType([
            Build.eClass("Shelf", [Build.reference("items", type, lower: lower, upper: upper, containment: containment,
                                                   ordered: ordered, unique: unique)]),
            Build.eClass("Item", abstract: true, [Build.attribute("id")]),
            Build.eClass("Book", supers: ["Item"], [Build.attribute("title")]),
        ])
    }

    @Test("Reference types are covariant for reading and contravariant for writing")
    func referenceVariance() {
        let general = shelves(itemsOf: "Item"), specific = shelves(itemsOf: "Book")
        #expect(check(general, specific, "Shelf", "items", .read).compatible)
        #expect(!check(general, specific, "Shelf", "items", .write).compatible)
        #expect(!check(general, specific, "Shelf", "items", [.read, .write]).compatible)
        #expect(!check(specific, general, "Shelf", "items", .read).compatible)
        #expect(check(specific, general, "Shelf", "items", .write).compatible)
        let report = check(general, specific, "Shelf", "items", .write)
        #expect(report.has(.featureTypeMismatch, .error, at: "mm!Shelf.items"))
        #expect(report.errors.first?.rule == .propertyTypeVariance)
    }

    @Test("Upper bounds narrow for reading and widen for writing")
    func upperBounds() {
        let many = shelves(itemsOf: "Item"), single = shelves(itemsOf: "Item", upper: 1)
        #expect(check(many, single, "Shelf", "items", .read).compatible)
        #expect(check(many, single, "Shelf", "items", .write).codes(.error) == [.multiplicityMismatch])
        #expect(check(single, many, "Shelf", "items", .read).codes(.error) == [.multiplicityMismatch])
        #expect(check(single, many, "Shelf", "items", .write).compatible)
    }

    @Test("Lower bounds are errors unless leniency is requested")
    func lowerBounds() {
        let optional = shelves(itemsOf: "Item", upper: 1), mandatory = shelves(itemsOf: "Item", lower: 1, upper: 1)
        #expect(check(optional, mandatory, "Shelf", "items", .read).compatible)
        #expect(!check(optional, mandatory, "Shelf", "items", .write).compatible)
        #expect(!check(mandatory, optional, "Shelf", "items", .read).compatible)
        let lenient = check(mandatory, optional, "Shelf", "items", .read, options: CheckOptions(lenientLowerBounds: true))
        #expect(lenient.compatible)
        #expect(lenient.codes(.warning) == [.multiplicityMismatch])
    }

    @Test("Ordering and uniqueness that the module relies on must be kept")
    func collectionSemantics() {
        let ordered = shelves(itemsOf: "Item"), unordered = shelves(itemsOf: "Item", ordered: false)
        #expect(check(ordered, unordered, "Shelf", "items", .read).codes(.error) == [.orderingMismatch])
        #expect(check(unordered, ordered, "Shelf", "items", .read).compatible)
        let lossy = check(ordered, unordered, "Shelf", "items", .write)
        #expect(lossy.compatible && lossy.codes(.warning) == [.orderingMismatch])
        let bag = shelves(itemsOf: "Item", unique: false), set = shelves(itemsOf: "Item")
        #expect(check(bag, set, "Shelf", "items", .read).compatible)
        #expect(check(set, bag, "Shelf", "items", .read).codes(.error) == [.uniquenessMismatch])
        #expect(check(bag, set, "Shelf", "items", .write).codes(.warning) == [.uniquenessMismatch])
    }

    @Test("Containment differences are errors when written and warnings when only read")
    func containment() {
        let plain = shelves(itemsOf: "Item"), owning = shelves(itemsOf: "Item", containment: true)
        let read = check(plain, owning, "Shelf", "items", .read)
        #expect(read.compatible && read.codes(.warning) == [.containmentMismatch])
        #expect(check(plain, owning, "Shelf", "items", .write).codes(.error) == [.containmentMismatch])
        let total = ModelTypeChecker().check(required: plain, provided: owning, mode: .totalNonIsomorphic)
        #expect(total.codes(.error) == [.containmentMismatch])
    }

    @Test("Opposites matter for writing and for total subtyping")
    func opposites() {
        let booksID = EUUID(), authorsID = EUUID()
        let paired = Build.modelType([
            Build.eClass("Book", [Build.reference("authors", "Writer", upper: -1, id: authorsID, opposite: booksID)]),
            Build.eClass("Writer", [Build.reference("books", "Book", upper: -1, id: booksID, opposite: authorsID)]),
        ])
        let unpaired = Build.modelType([
            Build.eClass("Book", [Build.reference("authors", "Writer", upper: -1)]),
            Build.eClass("Writer", [Build.reference("books", "Book", upper: -1)]),
        ])
        #expect(paired.objectType(named: "Book")?.property(named: "authors")?.oppositeName == "books")
        #expect(check(paired, unpaired, "Book", "authors", .read).diagnostics.isEmpty)
        let written = check(paired, unpaired, "Book", "authors", .write)
        #expect(written.compatible && written.codes(.warning) == [.oppositeMismatch])
        var footprint = MetamodelFootprint(metamodelName: "mm", role: .sourceAndTarget)
        footprint.record(feature: FeatureReference(className: "Book", featureName: "authors"), Usage(.write))
        footprint.record(feature: FeatureReference(className: "Writer", featureName: "books"), Usage(.read))
        let roundTrip = ModelTypeChecker().check(required: paired, provided: unpaired, mode: .partial, footprint: footprint)
        #expect(roundTrip.has(.oppositeMismatch, .error, at: "mm!Book.authors"))
        let total = ModelTypeChecker().check(required: paired, provided: unpaired, mode: .totalNonIsomorphic)
        #expect(total.codes(.error) == [.oppositeMismatch])
    }

    @Test("Written features must be changeable and not derived")
    func changeability() {
        let writable = Build.modelType([Build.eClass("Book", [Build.attribute("title")])])
        let fixed = Build.modelType([Build.eClass("Book", [Build.attribute("title", changeable: false)])])
        let derived = Build.modelType([Build.eClass("Book", [Build.attribute("title", derived: true)])])
        #expect(check(writable, fixed, "Book", "title", .read).compatible)
        #expect(check(writable, fixed, "Book", "title", .write).codes(.error) == [.featureNotChangeable])
        #expect(check(writable, derived, "Book", "title", .write).codes(.error) == [.featureNotChangeable])
    }

    @Test("An attribute cannot stand in for a reference")
    func kinds() {
        let attribute = Build.modelType([Build.eClass("Book", [Build.attribute("author")]), Build.eClass("Writer")])
        let reference = Build.modelType([Build.eClass("Book", [Build.reference("author", "Writer")]), Build.eClass("Writer")])
        #expect(check(attribute, reference, "Book", "author", .read).codes(.error) == [.featureKindMismatch])
    }

    @Test("Numeric widening is optional and follows the direction of use")
    func numericWidening() {
        let int = Build.modelType([Build.eClass("Book", [Build.attribute("pages", "EInt")])])
        let long = Build.modelType([Build.eClass("Book", [Build.attribute("pages", "ELong")])])
        let widening = CheckOptions(allowsNumericWidening: true)
        #expect(!check(long, int, "Book", "pages", .read).compatible)
        #expect(check(long, int, "Book", "pages", .read, options: widening).compatible)
        #expect(!check(int, long, "Book", "pages", .read, options: widening).compatible)
        #expect(check(int, long, "Book", "pages", .write, options: widening).compatible)
        #expect(!check(int, long, "Book", "pages", [.read, .write], options: widening).compatible)
        let isomorphic = ModelTypeChecker(options: widening).check(required: long, provided: int, mode: .totalIsomorphic)
        #expect(isomorphic.codes(.error) == [.featureTypeMismatch])
    }

    @Test("Data types compare by canonical category, not by spelling")
    func dataTypeSpelling() {
        let ecore = Build.modelType([Build.eClass("Book", [Build.attribute("pages", "EInt"), Build.attribute("title")])])
        let boxed = Build.modelType([Build.eClass("Book", [
            Build.attribute("pages", "EIntegerObject"), Build.attribute("title", "MyText"),
        ])])
        let report = check(ecore, boxed, "Book", "pages", .read)
        #expect(report.compatible)
        #expect(!check(ecore, boxed, "Book", "title", .read).compatible)
        let custom = ModelType(packages: [EPackage(name: "mm", eClassifiers: [
            EDataType(name: "Text", instanceClassName: "java.lang.String"),
            Build.eClass("Book", [EAttribute(name: "title", eType: EDataType(name: "Text", instanceClassName: "java.lang.String"))]),
        ])])
        #expect(check(ecore, custom, "Book", "title", .read).compatible)
        #expect(custom.dataTypes["Text"]?.instanceClassName == "java.lang.String")
    }

    @Test("Uses that could only be guessed are reported as warnings")
    func uncertainUses() {
        let required = Build.modelType([Build.eClass("Book", [Build.attribute("title")])])
        let provided = Build.modelType([Build.eClass("Book", [Build.attribute("name")])])
        let guessed = check(required, provided, "Book", "title", .read, certain: false)
        #expect(guessed.compatible)
        #expect(guessed.codes(.warning) == [.missingFeature])
        #expect(!check(required, provided, "Book", "title", .read).compatible)
    }

    @Test("Instantiated classes must be concrete")
    func instantiation() {
        let concrete = Build.modelType([Build.eClass("Book")])
        let abstract = Build.modelType([Build.eClass("Book", abstract: true)])
        var footprint = MetamodelFootprint(metamodelName: "mm", role: .target)
        footprint.record(className: "Book", Usage(.instantiate))
        let report = ModelTypeChecker().check(required: concrete, provided: abstract, mode: .partial, footprint: footprint)
        #expect(report.has(.abstractInstantiation, .error, at: "mm!Book"))
        footprint.record(className: "Unknown", Usage(.instantiate))
        let unknown = ModelTypeChecker().check(
            required: concrete, provided: Build.modelType([Build.eClass("Book"), Build.eClass("Unknown", abstract: true)]),
            mode: .partial, footprint: footprint)
        #expect(unknown.has(.abstractInstantiation, .error, at: "mm!Unknown"))
    }

    @Test("Enumeration-typed attributes need the corresponding provided enumeration")
    func enumerationTypes() {
        let required = Build.modelType([Build.eEnum("Genre", ["fiction"]), Build.eClass("Book", [
            EAttribute(name: "genre", eType: Build.eEnum("Genre", ["fiction"])),
        ])])
        let provided = Build.modelType([Build.eEnum("Kind", ["fiction"]), Build.eClass("Book", [
            EAttribute(name: "genre", eType: Build.eEnum("Kind", ["fiction"])),
        ])])
        #expect(check(required, provided, "Book", "genre", .read).codes(.error) == [.featureTypeMismatch])
        let renamed = check(required, provided, "Book", "genre", .read,
                            options: CheckOptions(renaming: Renaming(classifiers: ["Genre": "Kind"])))
        #expect(renamed.compatible)
    }
}
