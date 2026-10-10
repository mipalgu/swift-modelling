import Foundation
import Testing

@testable import ModellingGenerators

@Suite("Swift naming and typing queries")
struct SwiftQueryTests {
    /// The words that must be quoted wherever they name a generated element.
    static let keywords = [
        "guard", "Type", "class", "protocol", "default", "in", "operator", "repeat", "where", "Protocol", "Self",
        "self", "func", "let", "var", "struct", "enum", "extension", "import", "init", "switch", "case", "for",
        "while", "if", "else", "return", "throw", "throws", "try", "as", "is", "nil", "true", "false", "super",
        "static", "public", "private", "internal", "open", "subscript", "typealias", "inout", "defer", "do",
        "catch", "break", "continue", "fallthrough", "associatedtype", "deinit", "fileprivate", "rethrows",
        "precedencegroup", "Any", "await", "_",
    ]

    /// Evaluates expressions of the Swift template modules against the library fixture.
    ///
    /// - Parameter expressions: The expressions to evaluate.
    /// - Returns: The text of each expression.
    @MainActor
    func evaluate(_ expressions: [String]) async throws -> [String] {
        let generated = try await GeneratedProject.make("library", stem: "library", language: "swift")
        defer { generated.remove() }
        let harness = TemplateHarness(generated: generated, modules: TemplateHarness.swiftModules)
        let body = expressions.map { "[\($0)/]" }.joined(separator: "|")
        return try await harness.run(body).components(separatedBy: "|")
    }

    @Test("Keywords of the language are quoted in names")
    @MainActor
    func keywordsAreQuoted() async throws {
        let results = try await evaluate(Self.keywords.map { "safeName('\($0)')" })
        #expect(results == Self.keywords.map { "`\($0)`" })
    }

    @Test("Keywords are quoted in the names of types and cases too")
    @MainActor
    func keywordsAreQuotedInTypes() async throws {
        let results = try await evaluate(["typeIdentifier('Type')", "typeIdentifier('Protocol')", "quoted('default')"])
        #expect(results == ["`Type`", "`Protocol`", "`default`"])
    }

    @Test("Other names stay as they are")
    @MainActor
    func ordinaryNames() async throws {
        let names = ["label", "operation", "name", "value", "type", "text", "Guard", "classes", "inside", "Book"]
        let results = try await evaluate(names.map { "safeName('\($0)')" })
        #expect(results == names)
    }

    @Test("Names that the runtime protocol claims get a trailing underscore")
    @MainActor
    func memberNames() async throws {
        let names = ["id", "eClass", "hash", "hashValue", "eGet", "eSet", "eIsSet", "eUnset", "eStorage"]
        let results = try await evaluate(names.map { "safeName('\($0)')" })
        #expect(results == names.map { $0 + "_" })
    }

    @Test("Names of types that would hide a type of the runtime or the standard library get a trailing underscore")
    @MainActor
    func typeNames() async throws {
        let names = [
            "String", "Date", "Int", "Bool", "Mutex", "EObject", "EClass", "EStorage", "EWeakReference", "Sendable",
            "Classifier", "ID",
        ]
        let results = try await evaluate(names.map { "typeIdentifier('\($0)')" })
        #expect(results == names.map { $0 + "_" })
        let others = try await evaluate(["typeIdentifier('Book')", "plainTypeName('Type')", "plainTypeName('Date')"])
        #expect(others == ["Book", "Type", "Date_"])
    }

    @Test("Enumeration literals named with a single underscore are doubled")
    @MainActor
    func caseNames() async throws {
        let generated = try await GeneratedProject.make(
            "enumerations", stem: "enumerations", language: "swift")
        defer { generated.remove() }
        let harness = TemplateHarness(generated: generated, modules: TemplateHarness.swiftModules)
        let text = try await harness.run(
            "[for (e : GenEnum | genModel.allGenPackages().genEnums)][for (l : GenEnumLiteral | e.genEnumLiterals)][l.caseName()/],[/for][/for]")
        #expect(text.contains("`default`,"))
        #expect(text.contains("__,"))
        #expect(text.contains("HTTPServer,"))
        #expect(!text.contains(",_,"))
    }

    @Test("String literals escape quotes, backslashes and control characters")
    @MainActor
    func stringLiterals() async throws {
        let results = try await evaluate([
            "swiftStringLiteral('plain')", #"swiftStringLiteral('say "hi"')"#, #"swiftStringLiteral('a\\b')"#,
            #"swiftStringLiteral('a\nb')"#, #"swiftStringLiteral('a\tb')"#, "swiftStringLiteral('caf\u{E9}')",
            "swiftStringLiteral(1.fromCharacterCode())", "swiftStringLiteral(27.fromCharacterCode())",
            "swiftStringLiteral('')",
        ])
        #expect(
            results == [
                #""plain""#, #""say \"hi\"""#, #""a\\b""#, #""a\nb""#, #""a\tb""#, "\"caf\u{E9}\"", #""\u{1}""#,
                #""\u{1b}""#, #""""#,
            ])
    }

    @Test("Documentation becomes documentation comment lines with no trailing blanks")
    @MainActor
    func documentationComments() async throws {
        let results = try await evaluate([
            #"docComment('one\n\ntwo')"#, "docComment('single')", #"documentationText(genModel, 'Fallback.')"#,
        ])
        #expect(results[0] == "/// one\n///\n/// two")
        #expect(results[1] == "/// single")
        #expect(results[2] == "/// Fallback.")
    }

    @Test("Default value literals become Swift literals by the style of the type table")
    @MainActor
    func literals() async throws {
        let results = try await evaluate([
            "literalExpression('14', 'number')", "literalExpression('-1.5e3', 'number')",
            "literalExpression('x', 'number')", "literalExpression('TRUE', 'boolean')",
            "literalExpression('maybe', 'boolean')", "literalExpression('abc', 'string')",
            "literalExpression('xyz', 'character')", "literalExpression('x', '')",
            "literalExpression('x', null)",
        ])
        #expect(results == ["14", "-1.5e3", "", "true", "", "\"abc\"", "\"x\"", "", ""])
    }

    @Test("Optional and cast types keep existential types together")
    @MainActor
    func typeText() async throws {
        let results = try await evaluate([
            "optionalType('String')", "optionalType('any Named')", "castType('any Named')", "castType('Book')",
        ])
        #expect(results == ["String?", "(any Named)?", "(any Named)", "Book"])
    }

    @Test("Modules are imported once and in sorted order")
    @MainActor
    func importedModules() async throws {
        let results = try await evaluate([
            "importedModules(Sequence{'Synchronization', 'ECore', 'Foundation', 'ECore', 'EMFBase'})->join(',')",
        ])
        #expect(results == ["ECore,EMFBase,Foundation,Synchronization"])
    }

    @Test("Built-in model types map to Swift types by name and by instance class")
    @MainActor
    func typeMappings() async throws {
        let results = try await evaluate([
            "typeMapping('EString').targetType", "typeMapping('EInt').targetType", "typeMapping('EInt').zeroValue",
            "typeMapping('EIntegerObject').zeroValue", "typeMapping('ELong').targetType",
            "instanceMapping('java.util.Date').targetType", "instanceMapping('java.lang.String').modelType",
            "instanceMapping('int').modelType", "typeMapping('EDate').module", "typeMapping('EClass').targetType",
            "typeMapping('EObject').targetType",
        ])
        #expect(
            results == [
                "String", "Int", "0", "nil", "Int64", "Date", "EString", "EInt", "Foundation", "EClass",
                "any EObject",
            ])
    }

    @Test("The type table maps no instance class to two model types")
    func instanceClassesAreUnique() throws {
        let set = try TemplateSet.assemble(language: "swift")
        defer { set.remove() }
        let table = try String(
            contentsOf: set.directory.appendingPathComponent("swift-types.xmi"), encoding: .utf8)
        let classes = table.components(separatedBy: "instanceClass=\"").dropFirst().compactMap {
            $0.components(separatedBy: "\"").first
        }
        #expect(classes.count > 10)
        #expect(Set(classes).count == classes.count)
    }
}
