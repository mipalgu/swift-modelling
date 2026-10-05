import Foundation
import Testing

@testable import ModellingGenerators

/// Evaluates template expressions against the library fixture.
struct LibraryExpressions {
    /// The variables that every expression can use, bound to elements of the library generator model.
    static let bindings: [(name: String, type: String, value: String)] = [
        ("p", "GenPackage", "genModel.allGenPackages()->first()"),
        ("named", "GenClass", "p.genClasses->at(1)"),
        ("lendable", "GenClass", "p.genClasses->at(2)"),
        ("book", "GenClass", "p.genClasses->at(3)"),
        ("writer", "GenClass", "p.genClasses->at(4)"),
        ("lib", "GenClass", "p.genClasses->at(5)"),
        ("category", "GenEnum", "p.genEnums->first()"),
        ("isbn", "GenDataType", "p.genDataTypes->first()"),
        ("author", "GenFeature", "book.allGenFeatures()->at(7)"),
        ("pages", "GenFeature", "book.allGenFeatures()->at(4)"),
    ]

    /// Wraps expressions in the variable bindings.
    ///
    /// - Parameter expressions: Template expressions, each written without its brackets.
    /// - Returns: The template body that writes the values of the expressions separated by bars.
    static func body(_ expressions: [String]) -> String {
        let opening = bindings.map { "[let \($0.name) : \($0.type) = \($0.value)]" }.joined()
        let closing = String(repeating: "[/let]", count: bindings.count)
        return opening + expressions.map { "[\($0)/]" }.joined(separator: "|") + closing
    }

    /// Evaluates expressions and splits the output at the separating bars.
    ///
    /// - Parameter expressions: The template expressions.
    /// - Returns: The value of each expression as text.
    @MainActor
    static func evaluate(_ expressions: [String]) async throws -> [String] {
        let generated = try await GeneratedProject.make(
            "library", stem: "library",
            options: GenModelImportOptions(basePackage: "org.example", copyright: "Copyright 2026 Example Pty Ltd"))
        defer { generated.remove() }
        let output = try await TemplateHarness(generated: generated).run(body(expressions))
        return output.components(separatedBy: "|")
    }
}

@Suite("Generator model services")
struct GenModelServicesTests {
    @Test("Names are those of the Ecore elements, formatted on request")
    @MainActor
    func names() async throws {
        let values = try await LibraryExpressions.evaluate([
            "book.name()", "category.capName()", "category.uncapName()", "category.upperName()",
            "category.uncapPrefixedName()", "'loanDays'.capName()", "'LoanDays'.uncapName()",
            "'loanDays'.upperName()", "'XSDElement'.uncapPrefixedName()", "'loanDays'.formatName(' ')",
            "'LibraryBook'.formatName('_', 'Library', true)", "'LibraryBook'.formatName('_', 'Library')",
            "lib.genOperations->first().name()", "lib.genOperations->first().genParameters->collect(q | q.name())->join(',')",
        ])
        #expect(values == [
            "Book", "BookCategory", "bookCategory", "BOOK_CATEGORY", "bookCategory", "LoanDays", "loanDays",
            "LOAN_DAYS", "xsdElement", "loan Days", "Library_Book", "Book", "findBooks", "title,maxResults",
        ])
    }

    @Test("Navigation moves between elements and orders classifiers")
    @MainActor
    func navigation() async throws {
        let values = try await LibraryExpressions.evaluate([
            "book.genPackage().name()", "book.genModel().name()", "p.parentGenPackage().oclIsUndefined()",
            "author.genClass().name()", "category.genContainer().name()",
            "p.genClassifiers()->collect(c | c.name())->join(',')",
            "p.orderedGenClasses()->collect(c | c.name())->join(',')",
            "p.orderedGenClassifiers()->collect(c | c.name())->join(',')",
            "genModel.allGenPackages()->size()",
        ])
        #expect(values == [
            "library", "Library", "true", "Book", "library",
            "Named,Lendable,Book,Writer,Library,BookCategory,ISBN",
            "Named,Lendable,Book,Writer,Library", "Named,Lendable,Book,Writer,Library,BookCategory,ISBN", "1",
        ])
    }

    @Test("Classes expose inherited features, supertypes and numbering")
    @MainActor
    func classes() async throws {
        let values = try await LibraryExpressions.evaluate([
            "book.allGenFeatures()->collect(f | f.name())->join(',')",
            "book.inheritedGenFeatures()->collect(f | f.name())->join(',')",
            "book.implementedGenFeatures()->collect(f | f.name())->join(',')",
            "book.baseGenClasses()->collect(c | c.name())->join(',')",
            "book.allBaseGenClasses()->collect(c | c.name())->join(',')",
            "book.baseGenClass().name()", "book.classExtendsGenClass().name()",
            "book.implementedGenClasses()->collect(c | c.name())->join(',')",
            "named.baseGenClass().oclIsUndefined()", "book.featureID(pages)", "book.featureCount()",
            "writer.featureCount()", "lib.operationCount()", "lib.operationID(lib.allGenOperations()->first())",
            "lib.allGenOperations()->collect(o | o.name())->join(',')",
            "book.classifierID()", "category.classifierID()", "isbn.classifierID()",
            "book.classifierIDName()", "category.classifierIDName()", "book.isMapEntry()",
            "book.labelFeature().name()", "lendable.isInterface()", "book.isInterface()",
            "named.isAbstract()", "book.isAbstract()", "lendable.isAbstract()",
            "category.uniqueValuedGenEnumLiterals()->size()",
        ])
        #expect(values == [
            "name,loanDays,onLoan,pages,category,isbn,author,library",
            "name,loanDays,onLoan",
            "loanDays,onLoan,pages,category,isbn,author,library",
            "Named,Lendable", "Named,Lendable", "Named", "Named", "Lendable,Book",
            "true", "3", "8", "3", "1", "0", "findBooks",
            "2", "5", "6", "BOOK", "BOOK_CATEGORY", "false", "name", "true", "false", "true", "false", "true", "3",
        ])
    }

    @Test("Feature shortcuts read the Ecore feature")
    @MainActor
    func features() async throws {
        let values = try await LibraryExpressions.evaluate([
            "author.isReferenceType()", "author.isAttributeType()", "pages.isReferenceType()",
            "pages.isAttributeType()", "author.isContainment()", "author.isContainer()",
            "author.isBidirectional()", "author.reverseGenFeature().name()", "pages.reverseGenFeature().oclIsUndefined()",
            "author.isListType()", "author.isRequired()", "author.isChangeable()", "author.isVolatile()",
            "author.isTransient()", "author.isDerived()", "author.isUnsettable()", "author.isResolveProxies()",
            "pages.isResolveProxies()", "pages.hasDefault()", "pages.defaultValueLiteral()",
            "author.hasDefault()", "author.lowerBound()", "author.upperBound()",
            "lib.genFeatures->first().isContainment()", "lib.genFeatures->first().reverseGenFeature().isContainer()",
            "writer.genFeatures->at(1).isListType()", "writer.genFeatures->at(1).upperBound()",
        ])
        #expect(values == [
            "true", "false", "false", "true", "false", "false", "true", "books", "true", "false", "true", "true",
            "false", "false", "false", "false", "true", "false", "true", "100", "false", "1", "1", "true", "true",
            "true", "-1",
        ])
    }

    @Test("Ecore shortcuts return the native elements")
    @MainActor
    func ecoreElements() async throws {
        let values = try await LibraryExpressions.evaluate([
            "p.ecorePackage().name", "book.ecoreClass().name", "pages.ecoreFeature().name",
            "category.ecoreEnum().name", "category.genEnumLiterals->first().ecoreEnumLiteral().name",
            "isbn.ecoreDataType().name", "book.ecoreClass.genClassifier().name()",
            "category.ecoreEnum.genClassifier().name()", "isbn.ecoreDataType.genClassifier().name()",
            "book.ecoreClass.oclIsKindOf(EClass)", "pages.ecoreFeature.eType.name",
        ])
        #expect(values == [
            "library", "Book", "pages", "BookCategory", "Mystery", "ISBN", "Book", "BookCategory", "ISBN", "true", "EInt",
        ])
    }

    @Test("Settings fall back to the defaults of the generator metamodel")
    @MainActor
    func settings() async throws {
        let values = try await LibraryExpressions.evaluate([
            "genModel.setting('modelName')", "genModel.setting('complianceLevel')",
            "genModel.setting('nonNLSMarkers')", "genModel.setting('importOrganizing')",
            "category.setting('typeSafeEnumCompatible')", "genModel.setting('copyrightText')",
            "genModel.setting('noSuchSetting').oclIsUndefined()", "genModel.isSetting('modelName')",
            "genModel.isSetting('nonNLSMarkers')", "genModel.setting('suppressInterfaces')",
            "genModel.setting('creationCommands')", "p.setting('classPackageSuffix')",
            "p.setting('prefix')", "p.setting('literalsInterface')",
        ])
        #expect(values == [
            "Library", "17.0", "false", "false", "false", "Copyright 2026 Example Pty Ltd", "true", "true", "false",
            "false", "true", "impl", "Library", "true",
        ])
    }

    @Test("Documentation comes from the generator model annotation")
    @MainActor
    func documentation() async throws {
        let values = try await LibraryExpressions.evaluate([
            "category.hasDocumentation()", "category.documentation().oclIsUndefined()",
            "category.annotationDetail('urn:none', 'key').oclIsUndefined()",
        ])
        #expect(values == ["false", "true", "true"])
    }

    @Test("Text helpers split, indent and encode text")
    @MainActor
    func text() async throws {
        let values = try await LibraryExpressions.evaluate([
            "'a\\nb\\r\\nc\\rd'.lines()->size()", "''.lines()->size()", "'a\\nb'.indentLines('> ')",
            "'Ab'.characterCodes()->join(',')", "(255).toHexString(4)", "(255).toHexString()",
            "(8).toOctalString(3)", "(65).fromCharacterCode()", "Sequence{'x', 'y'}->join('-')",
            "Sequence{'x', 'y'}->join()",
        ])
        #expect(values == ["4", "1", "a\n> b", "65,98", "00ff", "ff", "010", "A", "x-y", "xy"])
    }

    @Test("Template data names the data models of the set")
    @MainActor
    func templateData() async throws {
        let values = try await LibraryExpressions.evaluate([
            "templateData('types')->size()", "templateData('types')->first().language",
            "templateData('types')->first().mappings->size()",
        ])
        #expect(values == ["1", "java", "32"])
    }

    @Test("Template data that the set does not have is an error")
    @MainActor
    func unknownTemplateData() async throws {
        let generated = try await GeneratedProject.make("library", stem: "library")
        defer { generated.remove() }
        await #expect(throws: GenerationError.self) {
            _ = try await TemplateHarness(generated: generated).run("[templateData('nothing')/]")
        }
    }

    @Test("Services reject receivers that are not generator model elements")
    @MainActor
    func wrongReceiver() async throws {
        let generated = try await GeneratedProject.make("library", stem: "library")
        defer { generated.remove() }
        await #expect(throws: GenerationError.self) {
            _ = try await TemplateHarness(generated: generated).run("[genModel.allGenPackages()->first().ecorePackage().allGenFeatures()/]")
        }
    }
}

@Suite("Generator model service helpers")
struct GenModelServiceHelperTests {
    @Test("Lines split at every kind of line break")
    func lines() {
        #expect(GenModelServices.lines(of: "a\nb") == ["a", "b"])
        #expect(GenModelServices.lines(of: "a\r\nb") == ["a", "b"])
        #expect(GenModelServices.lines(of: "a\rb") == ["a", "b"])
        #expect(GenModelServices.lines(of: "a\n\nb") == ["a", "", "b"])
        #expect(GenModelServices.lines(of: "") == [""])
        #expect(GenModelServices.lines(of: "a\n") == ["a", ""])
    }

    @Test("Indenting prefixes every line but the first")
    func indentLines() {
        #expect(GenModelServices.indentLines(of: "a\nb\nc", with: "  ") == "a\n  b\n  c")
        #expect(GenModelServices.indentLines(of: "single", with: "  ") == "single")
    }
}
