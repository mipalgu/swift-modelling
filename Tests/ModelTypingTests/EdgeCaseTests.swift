//
//  EdgeCaseTests.swift
//  ModelTypingTests
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import AQL
import ATL
import ECore
import EMFBase
import Foundation
import ModelTyping
import MTL
import Testing

/// An expression kind that no walker knows.
private struct OpaqueAQLExpression: AQLExpression {
    @MainActor
    func evaluate(in context: AQLExecutionContext) async throws -> (any EcoreValue)? { nil }
}

/// An ATL expression kind that no walker knows.
private struct OpaqueATLExpression: ATLExpression {
    @MainActor
    func evaluate(in context: ATLExecutionContext) async throws -> (any EcoreValue)? { nil }
}

/// An ATL statement kind that no walker knows.
private struct OpaqueATLStatement: ATLStatement {
    @MainActor
    func execute(in context: ATLExecutionContext) async throws {}
}

/// Constructs that parsers produce rarely or only from other notations.
@Suite("Edge cases")
struct EdgeCaseTests {
    // MARK: - AQL

    /// The library binding of the first library version.
    private func libraryBinding() async throws -> MetamodelBinding {
        MetamodelBinding(name: "library", modelType: try await Fixtures.modelType("LibraryV1"))
    }

    @Test("AQL nodes built in code are typed like parsed ones")
    func aqlNodesInCode() async throws {
        let extractor = AQLFootprintExtractor(bindings: [try await libraryBinding()])
        let self_ = AQLVariableExpression(name: "self")
        let books = AQLNavigationExpression(source: self_, property: "books")
        let expressions: [any AQLExpression] = [
            AQLStringInterpolationExpression(parts: [.init(literal: "x")]),
            AQLUnaryExpression(op: .not, operand: AQLNavigationExpression(source: self_, property: "name")),
            AQLUnaryExpression(op: .negate, operand: AQLLiteralExpression(value: 1.5)),
            AQLLambdaExpression(iterator: "b", body: AQLNavigationExpression(source: AQLVariableExpression(name: "b"), property: "x")),
            AQLEnumLiteralExpression(packageName: nil, enumName: "Genre", literal: "fiction"),
            AQLCallExpression(source: books, methodName: "collectNested", arguments: [
                AQLLambdaExpression(iterator: "b", body: AQLNavigationExpression(source: AQLVariableExpression(name: "b"), property: "isbn")),
            ], usesArrow: true),
            AQLNavigationExpression(source: AQLCallExpression(source: books, methodName: "at", arguments: [AQLLiteralExpression(value: 1)], usesArrow: true), property: "title"),
            AQLCallExpression(source: books, methodName: "collectNested", arguments: [], usesArrow: true),
            AQLCallExpression(methodName: "bare", arguments: [AQLLiteralExpression(value: true)]),
            AQLNavigationExpression(source: AQLLiteralExpression(value: nil), property: "anything"),
        ]
        let footprint = extractor.footprint(of: AQLCollectionLiteralExpression(kind: .sequence, elements: expressions),
                                            variables: ["self": "library::Library"])
        let usage = try #require(footprint[metamodel: "library"])
        #expect(usage.featureNames == ["Book.isbn", "Book.title", "Library.books", "Library.name"])
        #expect(usage.literals.keys.map(\.description) == ["Genre.fiction"])
        #expect(footprint.uncertainties.map(\.kind) == [.unknownReceiverType, .unknownReceiverType])
    }

    @Test("Unknown AQL node kinds are reported")
    func aqlUnknownNode() async throws {
        let footprint = AQLFootprintExtractor(bindings: [try await libraryBinding()]).footprint(of: OpaqueAQLExpression())
        #expect(footprint.uncertainties.map(\.kind) == [.unknownOperation])
    }

    @Test("Unqualified, enumeration, data type and canonical type names resolve")
    func typeNames() async throws {
        let custom = ModelType(packages: [EPackage(name: "shop", eClassifiers: [
            EDataType(name: "Money", instanceClassName: "java.math.BigDecimal"),
            Build.eEnum("Size", ["s", "m"]),
            Build.eClass("Item", [Build.attribute("price", "Money"), EAttribute(name: "size", eType: Build.eEnum("Size", ["s", "m"]))]),
        ])])
        let extractor = AQLFootprintExtractor(bindings: [MetamodelBinding(name: "shop", modelType: custom)])
        let footprint = try extractor.footprint(
            ofSource: "Sequence{item.price, size, count, money, unknown, shop::Ghost.allInstances().colour}",
            variables: ["item": "Item", "size": "shop::Size", "count": "EInt", "money": "Money", "unknown": "Nowhere"])
        #expect(footprint[metamodel: "shop"]?.classNames == ["Ghost", "Item"])
        #expect(footprint[metamodel: "shop"]?.featureNames == ["Ghost.colour", "Item.price"])
        #expect(Set(footprint.uncertainties.map(\.kind)) == [.unknownType, .unknownFeature])
        #expect(custom.objectType(named: "Item")?.property(named: "price")?.instanceClassName == "java.math.BigDecimal")
    }

    @Test("Literals are attributed to the single enumeration that declares them, or to all candidates")
    func literalCandidates() async throws {
        let ambiguous = Build.modelType([
            Build.eEnum("Colour", ["red", "plain"]), Build.eEnum("Finish", ["matt", "plain"]),
            Build.eClass("Thing", [Build.attribute("name")]),
        ], name: "MM")
        let module = try await ATLParser(options: .standard).parseContent("""
            module M;
            create OUT : MM from IN : MM;
            rule R { from t : MM!Thing (#red <> #plain) to u : MM!Thing ( name <- t.name ) }
            """, filename: "m.atl")
        let footprint = ATLFootprintExtractor(metamodels: ["MM": ambiguous]).footprint(of: module)
        let literals = try #require(footprint[metamodel: "MM"]?.literals)
        #expect(literals[LiteralReference(enumerationName: "Colour", literalName: "red")]?.isCertain == true)
        #expect(literals[LiteralReference(enumerationName: "Colour", literalName: "plain")]?.isCertain == false)
        #expect(literals[LiteralReference(enumerationName: "Finish", literalName: "plain")]?.isCertain == false)
        #expect(footprint.uncertainties.map(\.kind) == [.unresolvedLiteral])
    }

    // MARK: - ATL

    @Test("Less common ATL syntax is typed")
    func atlSyntax() async throws {
        let metamodels = ["Families": try await Fixtures.modelType("Families"), "Persons": try await Fixtures.modelType("Persons")]
        let footprint = try await ATLFootprintExtractor(metamodels: metamodels).footprint(ofSource: """
            module M;
            create OUT : Persons from IN : Families;
            helper context Families!Family def: child(i : Integer) : Families!Member = self.sons->at(i);
            rule R {
                from f : Families!Family (#mr = #mr)
                using {
                    first : Families!Member = f.child(1);
                    names : Sequence(String) = f.daughters->collect(d | d.firstName);
                    tuple : TupleType(n : Integer) = Tuple{n = -1};
                    numbers : Sequence(Integer) = Sequence{1..3};
                    members : Sequence(Families!Member) = Sequence{first};
                    kind : OclAny = Persons!Salutation;
                    nobody : OclAny = ghost;
                    nothing : OclAny = thisModule.missing;
                    nowhere : OclAny = thisModule.unknown(1);
                    last : String = let m : Families!Member = f.mother in m.firstName;
                }
                to p : Persons!Male ( fullName <- first.firstName )
            }
            """)
        let families = try #require(footprint[metamodel: "Families"])
        #expect(families.featureNames == [
            "Family.daughters", "Family.mother", "Family.sons", "Member.firstName",
        ])
        #expect(Set(footprint.uncertainties.map(\.kind)) == [.unknownVariable, .unknownOperation])
        #expect(footprint[metamodel: "Persons"]?.literals.keys.map(\.description) == ["Salutation.mr"])
    }

    @Test("ATL nodes built in code, generic helpers and unknown kinds are handled")
    func atlNodesInCode() async throws {
        let family = ATLVariableExpression(name: "f")
        let sons = ATLNavigationExpression(source: family, property: "sons")
        let guardExpression = ATLCollectionLiteralExpression(collectionType: "Sequence", elements: [
            ATLCollectionExpression(source: sons, operation: .select, iterator: "s",
                                    body: ATLNavigationExpression(source: ATLVariableExpression(name: "s"), property: "firstName")),
            ATLCollectionExpression(source: sons, operation: .size),
            ATLOperationExpression(source: family, operationName: "lastName", arguments: []),
            ATLHelperCallExpression(helperName: "surname", arguments: [family]),
            ATLHelperCallExpression(helperName: "make", arguments: []),
            ATLLambdaExpression(parameter: "x", body: ATLVariableExpression(name: "x")),
            OpaqueATLExpression(),
        ])
        let helper = ATLHelper(name: "surname", returnType: "String", parameters: [ATLParameter(name: "g", type: "Families!Family")],
                               body: ATLNavigationExpression(source: ATLVariableExpression(name: "g"), property: "lastName"))
        let rule = ATLMatchedRule(
            name: "R", sourcePattern: ATLSourcePattern(variableName: "f", type: "Families!Family"),
            targetPatterns: [ATLTargetPattern(variableName: "p", type: "Persons!Male")], guard: guardExpression,
            doStatements: [
                ATLVariableDeclarationStatement(name: "n", type: "String", initialiser: ATLLiteralExpression(value: "x")),
                ATLVariableDeclarationStatement(name: "m"),
                ATLAssignmentStatement(target: .variable("n"), value: ATLEnumLiteralExpression(name: "mr")),
                OpaqueATLStatement(),
            ])
        let make = ATLCalledRule(name: "make", targetPatterns: [ATLTargetPattern(variableName: "q", type: "Persons!Female")])
        let module = ATLModule(
            name: "M", sourceMetamodels: ["IN": EPackage(name: "Families")], targetMetamodels: ["OUT": EPackage(name: "Persons")],
            helpers: ["surname": helper], matchedRules: [rule], calledRules: ["make": make])
        let metamodels = ["Families": try await Fixtures.modelType("Families"), "Persons": try await Fixtures.modelType("Persons")]
        let footprint = ATLFootprintExtractor(metamodels: metamodels).footprint(of: module)
        #expect(footprint[metamodel: "Families"]?.featureNames == ["Family.lastName", "Family.sons", "Member.firstName"])
        #expect(footprint[metamodel: "Persons"]?.classNames == ["Female", "Male"])
        #expect(footprint.uncertainties.filter { $0.kind == .unknownOperation }.count == 2)
        let empty = ATLCalledRule(name: "empty", targetPatterns: [])
        let query = ATLModule(name: "Q", sourceMetamodels: [:], targetMetamodels: [:], calledRules: ["empty": empty],
                              queryBody: ATLMethodCallExpression(receiver: ATLVariableExpression(name: "thisModule"), methodName: "empty"))
        #expect(ATLFootprintExtractor(metamodels: metamodels).footprint(of: query).metamodels.isEmpty)
    }

    // MARK: - MTL

    @Test("MTL post-conditions, macros, file options and linked modules are visited")
    func mtlConstructs() async throws {
        let parser = MTLParser()
        let main = try await parser.parse("""
            [module main('http://example.org/library/1.0')/]
            [template public main(book : library::Book) post (self.trim())]
            [file (book.title, 'overwrite', book.isbn)][book.helperQuery()/][/file]
            [wrap(book)][book.pages/][/wrap]
            [/template]
            [macro wrap(item : library::Book, content : Body)]<[item.genre/]>[content/][/macro]
            """)
        let helper = try await parser.parse("""
            [module helper('http://example.org/library/1.0')/]
            [query public helperQuery(book : library::Book) : library::Writer = book.authors->first() /]
            """)
        let traced = MTLTemplate(name: "traced", parameters: [MTLVariable(name: "w", type: "library::Writer")], body: MTLBlock(statements: [
            MTLTrace(sourceExpression: MTLExpression(AQLNavigationExpression(source: AQLVariableExpression(name: "w"), property: "born")),
                     body: MTLBlock(statements: [])),
        ]))
        let tracing = MTLModule(name: "tracing", metamodels: [:], templates: ["traced": traced])
        let linked = main.linking(imports: [helper, tracing], extending: nil)
        let footprint = MTLFootprintExtractor(bindings: [try await libraryBinding()]).footprint(of: linked)
        let usage = try #require(footprint[metamodel: "library"])
        #expect(usage.featureNames == ["Book.authors", "Book.genre", "Book.isbn", "Book.pages", "Book.title", "Writer.born"])
        #expect(usage.classNames == ["Book", "Writer"])
    }

    // MARK: - Checker

    @Test("Footprints are re-keyed to the requested metamodel name")
    func footprintRenaming() {
        let modelType = Build.modelType([Build.eClass("Book", [Build.attribute("title")])])
        var footprint = MetamodelFootprint(metamodelName: "other", role: .source)
        #expect(footprint.isEmpty)
        footprint.record(feature: FeatureReference(className: "Book", featureName: "title"), Usage(.read))
        #expect(!footprint.isEmpty)
        let report = ModelTypeChecker().check(required: modelType, provided: modelType, mode: .partial,
                                              metamodelName: "lib", footprint: footprint)
        #expect(report.footprint?.metamodels.keys.map { $0 } == ["lib"])
        #expect(report.compatible)
    }

    @Test("Literals of a missing enumeration, container references and type kinds")
    func checkerBranches() {
        let required = Build.modelType([
            Build.eEnum("Genre", ["fiction"]),
            Build.eClass("Book", [Build.attribute("genre", "EString")]),
        ])
        let provided = Build.modelType([
            Build.eEnum("Kind", ["fiction"]),
            Build.eClass("Book", [EAttribute(name: "genre", eType: Build.eEnum("Kind", ["fiction"]))]),
        ])
        var footprint = MetamodelFootprint(metamodelName: "mm", role: .source)
        footprint.record(literal: LiteralReference(enumerationName: "Genre", literalName: "fiction"), Usage(.read))
        footprint.record(literal: LiteralReference(enumerationName: "Genre", literalName: "poetry"), Usage(.read))
        footprint.record(feature: FeatureReference(className: "Book", featureName: "genre"), Usage(.read))
        let report = ModelTypeChecker().check(required: required, provided: provided, mode: .partial, footprint: footprint)
        #expect(report.diagnostics(withCode: .missingEnumeration).count == 1)
        #expect(report.has(.featureTypeMismatch, .error, at: "mm!Book.genre"))

        let shelfID = EUUID(), itemsID = EUUID()
        let owned = Build.modelType([
            Build.eClass("Shelf", [Build.reference("items", "Item", upper: -1, containment: true, id: itemsID, opposite: shelfID)]),
            Build.eClass("Item", [Build.reference("shelf", "Shelf", lower: 1, id: shelfID, opposite: itemsID)]),
        ])
        var creation = MetamodelFootprint(metamodelName: "mm", role: .target)
        creation.record(className: "Item", Usage(.instantiate))
        let created = ModelTypeChecker().check(required: owned, provided: owned, mode: .partial, footprint: creation)
        #expect(created.diagnostics.isEmpty)
    }

    @Test("Near-miss class names are suggested")
    func classNearMiss() {
        let required = Build.modelType([Build.eClass("Writer")])
        let provided = Build.modelType([Build.eClass("Writers")])
        let report = ModelTypeChecker().check(required: required, provided: provided, mode: .totalNonIsomorphic)
        #expect(report.renamingHints.map(\.renamingEntry) == ["Writer=Writers"])
        #expect(report.renamingHints.first?.reason == .nearMissName)
    }

    @Test("Model types can be assembled from parts")
    func assembledModelType() {
        let book = ObjectType(name: "Book", packageName: "lib", isAbstract: false, isInterface: false,
                              directSuperTypeNames: [], allSuperTypeNames: [], ownPropertyNames: ["title"],
                              properties: ["title": PropertyType(name: "title", declaringClassName: "Book", kind: .attribute,
                                                                 typeName: "EString", typeKind: .dataType)])
        let modelType = ModelType(packageNames: ["lib"], objectTypes: ["Book": book],
                                  enumerations: ["Genre": EnumerationType(name: "Genre", packageName: "lib", literalNames: ["a"])],
                                  dataTypes: ["Text": DataTypeDescriptor(name: "Text", instanceClassName: nil)])
        #expect(modelType.objectType(named: "lib::Book") == book)
        #expect(ModelTypeChecker().check(required: modelType, provided: modelType, mode: .totalIsomorphic).diagnostics.isEmpty)
    }
}
