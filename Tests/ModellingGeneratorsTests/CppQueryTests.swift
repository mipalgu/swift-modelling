import Foundation
import Testing

@testable import ModellingGenerators

extension TemplateHarness {
    /// The imports that every harness module of the C++ template set declares.
    static let cppModules = [
        "CppNames", "CppIncludes", "CppTypes", "CppDocumentation", "Header", "EnumClass", "ClassQueries",
        "ClassFeature", "Class", "PackageClass", "FactoryClass", "DataTypeFile", "SupportHeader",
    ]
}

@Suite("C++ naming and typing queries")
struct CppQueryTests {
    /// The keywords of C++20, which no generated name can be.
    static let keywords = [
        "alignas", "alignof", "and", "and_eq", "asm", "atomic_cancel", "atomic_commit", "atomic_noexcept", "auto",
        "bitand", "bitor", "bool", "break", "case", "catch", "char", "char8_t", "char16_t", "char32_t", "class",
        "compl", "concept", "const", "consteval", "constexpr", "constinit", "const_cast", "continue", "co_await",
        "co_return", "co_yield", "decltype", "default", "delete", "do", "double", "dynamic_cast", "else", "enum",
        "explicit", "export", "extern", "false", "final", "float", "for", "friend", "goto", "if", "import", "inline",
        "int", "long", "module", "mutable", "namespace", "new", "noexcept", "not", "not_eq", "nullptr", "operator",
        "or", "or_eq", "override", "private", "protected", "public", "register", "reinterpret_cast", "requires",
        "return", "short", "signed", "sizeof", "static", "static_assert", "static_cast", "struct", "switch",
        "synchronized", "template", "this", "thread_local", "throw", "true", "try", "typedef", "typeid", "typename",
        "union", "unsigned", "using", "virtual", "void", "volatile", "wchar_t", "while", "xor", "xor_eq",
    ]

    /// Names of types, macros and functions of the standard library and of the support header.
    static let claimedNames = [
        "std", "EObject", "ClassInfo", "FeatureInfo", "FeatureKind", "PackageInfo", "isKindOf", "literalOf", "NULL",
        "EOF", "FILE", "BUFSIZ", "EXIT_SUCCESS", "INT_MAX", "SEEK_SET", "stdin", "stdout", "stderr", "errno",
        "assert", "offsetof", "va_list", "size_t", "ssize_t", "ptrdiff_t", "nullptr_t", "time_t", "tm", "int8_t",
        "int16_t", "int32_t", "int64_t", "uint8_t", "uint16_t", "uint32_t", "uint64_t", "intptr_t", "restrict",
        "TRUE", "FALSE", "min", "max", "small", "near", "far", "interface", "unix", "linux", "major", "minor",
    ]

    /// Evaluates expressions of the C++ template modules against a fixture.
    ///
    /// - Parameters:
    ///   - expressions: The template expressions to evaluate. No result contains a bar.
    ///   - fixture: The name of the fixture.
    ///   - inFirstPackage: Whether the expressions refer to the first package of the model as `p`.
    /// - Returns: The text of each expression.
    @MainActor
    func evaluate(
        _ expressions: [String], fixture: String = "library", inFirstPackage: Bool = false
    ) async throws -> [String] {
        let golden = try #require(CppGoldenCase.named(fixture))
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options, language: "cpp")
        defer { generated.remove() }
        let harness = TemplateHarness(generated: generated, modules: TemplateHarness.cppModules)
        let body = expressions.map { expression in
            inFirstPackage
                ? "[let p : GenPackage = genModel.allGenPackages()->first()][\(expression)/][/let]" : "[\(expression)/]"
        }.joined(separator: "|")
        return try await harness.run(body).components(separatedBy: "|")
    }

    // MARK: - Names

    @Test("Keywords of the language get a trailing underscore")
    @MainActor
    func keywordsAreEscaped() async throws {
        let results = try await evaluate(Self.keywords.map { "escaped('\($0)')" })
        #expect(results == Self.keywords.map { $0 + "_" })
    }

    @Test("Names of the standard library and of the support header get a trailing underscore")
    @MainActor
    func claimedNamesAreEscaped() async throws {
        let results = try await evaluate(Self.claimedNames.map { "typeIdentifier('\($0)')" })
        #expect(results == Self.claimedNames.map { $0 + "_" })
    }

    @Test("Every name that the support header declares is claimed")
    @MainActor
    func supportNamesAreClaimed() async throws {
        let names = [
            "classInfoName()", "featureInfoName()", "packageInfoName()", "featureKindName()", "kindOfFunctionName()",
            "rootObjectType()", "literalFunctionName()",
        ]
        let results = try await evaluate(names + names.map { "escaped(\($0))" })
        #expect(results.count == names.count * 2)
        #expect(results.suffix(names.count) == results.prefix(names.count).map { $0 + "_" })
        #expect(
            results.prefix(names.count) == [
                "ClassInfo", "FeatureInfo", "PackageInfo", "FeatureKind", "isKindOf", "EObject", "literalOf",
            ])
    }

    @Test("Other names stay as they are")
    @MainActor
    func ordinaryNames() async throws {
        let names = [
            "label", "operation", "name", "value", "type", "Type", "text", "Guard", "classes", "inside", "Book", "Date",
            "String", "Package", "_",
        ]
        let results = try await evaluate(names.map { "escaped('\($0)')" })
        #expect(results == names)
    }

    @Test("Enumeration literals are escaped like other names")
    @MainActor
    func literalNames() async throws {
        let results = try await evaluate(
            [
                "genModel.allGenPackages().genEnums->collect(e | e.genEnumLiterals->collect(l | l.literalName())->join(','))->join(';')"
            ], fixture: "enumerations")
        #expect(results == ["Red,Amber,Yellow,Green;default_,fastForward,HTTPServer,_,quote;"])
    }

    @Test("Packages have a directory, a namespace, a header for their description and names from their prefix")
    @MainActor
    func packageNames() async throws {
        let each =
            "genModel.allGenPackages()->collect(p | p.packageDirectory() + '=' + p.namespacePath() + '=' + p.packageTypeName() + '=' + p.factoryFileName() + '=' + p.packageHeader())->join(';')"
        let nested = try await evaluate([each], fixture: "nested")
        #expect(
            nested == [
                "company=company=CompanyPackage=CompanyFactory=company/CompanyPackage.hpp;"
                    + "company/people=company::people=PeoplePackage=PeopleFactory=company/people/PeoplePackage.hpp;"
                    + "company/projects=company::projects=ProjPackage=ProjFactory=company/projects/ProjPackage.hpp;"
                    + "company/projects/archive=company::projects::archive=ArchivePackage=ArchiveFactory="
                    + "company/projects/archive/ArchivePackage.hpp"
            ])
        let reserved = try await evaluate([each], fixture: "cnames")
        #expect(
            reserved == [
                "cnames=cnames=CnamesPackage=CnamesFactory=cnames/CnamesPackage.hpp;"
                    + "cnames/delete=cnames::delete_=DeletePackage=DeleteFactory=cnames/delete/DeletePackage.hpp"
            ])
        let organisation = try await evaluate([each], fixture: "organisation")
        #expect(organisation == ["organisation=organisation=OrgPackage=OrgFactory=organisation/OrgPackage.hpp"])
    }

    @Test("Classes are abstract base classes, concrete classes, or both, and are found by their header")
    @MainActor
    func classKinds() async throws {
        let each =
            "genModel.allGenPackages()->collect(p | p.genClasses->collect(c | c.name() + ':' + (if c.isProtocol() then 'P' else 'p' endif) + (if c.isInstantiable() then 'I' else 'i' endif) + (if c.hasSubclasses() then 'S' else 's' endif) + ':' + c.interfaceName() + '/' + c.className() + '/' + c.classifierHeader() + '/' + c.descriptorName()))->join(';')"
        let library = try await evaluate([each])
        #expect(
            library == [
                "Named:PiS:Named/NamedImpl/library/Named.hpp/namedClass;Lendable:PiS:Lendable/LendableImpl/library/Lendable.hpp/lendableClass;"
                    + "Book:pIs:Book/Book/library/Book.hpp/bookClass;Writer:pIs:Writer/Writer/library/Writer.hpp/writerClass;"
                    + "Library:pIs:Library/Library/library/Library.hpp/libraryClass"
            ])
        let reserved = try await evaluate([each], fixture: "cnames")
        let classes = try #require(reserved.first).components(separatedBy: ";")
        #expect(classes.contains("Vehicle:PIS:Vehicle/VehicleImpl/cnames/Vehicle.hpp/vehicleClass"))
        #expect(classes.contains("Truck:pIs:Truck/Truck/cnames/Truck.hpp/truckClass"))
        #expect(classes.contains("Shape:Pis:Shape/Shape/cnames/Shape.hpp/shapeClass"))
        #expect(classes.contains("static:pIs:static_/static_/cnames/static_.hpp/staticClass"))
        #expect(classes.contains("EObject:pIs:EObject_/EObject_/cnames/EObject_.hpp/eObjectClass"))
        #expect(classes.contains("Wheel:pIs:Wheel/Wheel/cnames/delete/Wheel.hpp/wheelClass"))
    }

    @Test("A classifier is written with its namespace outside its package, and plain inside it")
    @MainActor
    func qualifiedNames() async throws {
        let results = try await evaluate(
            [
                "genModel.allGenPackages()->last().genClasses->first().qualifiedName(genModel.allGenPackages()->first())",
                "genModel.allGenPackages()->last().genClasses->first().qualifiedName(genModel.allGenPackages()->last())",
            ], fixture: "cnames")
        #expect(results == ["::cnames::delete_::Wheel", "Wheel"])
    }

    @Test("Bases are virtual, and a class without generated supertypes derives from the root class")
    @MainActor
    func baseClauses() async throws {
        let results = try await evaluate(
            [
                "p.genClasses->select(c | c.name() = 'Book')->collect(c | c.baseClasses(p) + '#' + c.concreteBaseClasses(p))->first()",
                "p.genClasses->select(c | c.name() = 'Named')->collect(c | c.baseClasses(p) + '#' + c.concreteBaseClasses(p))->first()",
                "inheritance('X')",
            ], inFirstPackage: true)
        #expect(
            results == [
                "public virtual Named, public virtual Lendable#public virtual Named, public virtual Lendable",
                "public virtual EObject#public virtual Named", "public virtual X",
            ])
    }

    @Test("Features are implemented by the concrete class once, and the classes they refer to are declared ahead of use")
    @MainActor
    func implementedFeatures() async throws {
        let results = try await evaluate(
            [
                "p.genClasses->select(c | c.name() = 'Book')->collect(c | c.implementedFeatures()->size().toString() + ':' + c.genFeatures->size().toString() + ':' + c.usedFeatures()->size().toString() + ':' + c.forwardDeclared()->collect(t | t.name())->join(','))->first()",
                "p.genClasses->select(c | c.name() = 'Named')->collect(c | c.usedFeatures()->size().toString() + ':' + c.forwardDeclared()->size().toString())->first()",
            ], inFirstPackage: true)
        #expect(results == ["8:5:8:Library,Writer", "1:0"])
    }

    // MARK: - Types and accessors

    @Test("The accessors and storage of features follow their kind")
    @MainActor
    func accessors() async throws {
        let each =
            "p.genClasses->select(c | c.name() = 'Book')->first().genFeatures->collect(f | f.name() + ':' + f.getterName() + ':' + f.setterName() + ':' + f.storageName() + ':' + f.storageType(p) + ':' + f.valueTypeName(p) + ':' + f.parameterTypeName(p) + ':' + f.initialValue(p))->join(';')"
        let results = try await evaluate([each], inFirstPackage: true)
        #expect(
            results == [
                "pages:getPages:setPages:m_pages:std::int32_t:std::int32_t:std::int32_t:100;"
                    + "category:getCategory:setCategory:m_category:BookCategory:BookCategory:BookCategory:BookCategory::Mystery;"
                    + "isbn:getIsbn:setIsbn:m_isbn:ISBN:const ISBN &:const ISBN &:;"
                    + "author:getAuthor:setAuthor:m_author:std::weak_ptr<Writer>:std::shared_ptr<Writer>:const std::shared_ptr<Writer> &:;"
                    + "library:getLibrary:setLibrary:m_library:std::weak_ptr<Library>:std::shared_ptr<Library>:const std::shared_ptr<Library> &:"
            ])
    }

    @Test("Many-valued features are vectors, of shared pointers where they contain and of weak pointers where they do not")
    @MainActor
    func manyValuedFeatures() async throws {
        let each =
            "p.genClasses->select(c | c.name() = 'Library' or c.name() = 'Writer')->collect(c | c.genFeatures->collect(f | c.name() + '.' + f.name() + '=' + f.storageType(p) + '/' + f.mutableAccessType(p) + '/' + f.constantAccessType(p) + '/' + f.storedRead()))->join(';')"
        let results = try await evaluate([each], inFirstPackage: true)
        let writer = results.first?.components(separatedBy: ";") ?? []
        #expect(writer.contains("Writer.aliases=std::vector<std::string>/std::vector<std::string> &/const std::vector<std::string> &/m_aliases"))
        #expect(writer.contains("Writer.books=std::vector<std::weak_ptr<Book>>/std::vector<std::weak_ptr<Book>> &/const std::vector<std::weak_ptr<Book>> &/m_books"))
        #expect(writer.contains("Library.books=std::vector<std::shared_ptr<Book>>/std::vector<std::shared_ptr<Book>> &/const std::vector<std::shared_ptr<Book>> &/m_books"))
    }

    @Test("A concrete class overrides the accessors that a base class declares")
    @MainActor
    func overrides() async throws {
        let each =
            "p.genClasses->select(c | c.name() = 'Book')->collect(c | c.genFeatures->first().overrideSpecifier(c) + '|' + c.allGenFeatures()->first().overrideSpecifier(c))->first()"
        let results = try await evaluate([each], inFirstPackage: true)
        #expect(results.count == 2)
        #expect(results[0] == "")
        #expect(results[1] == " override")
    }

    @Test("Types of the table are written as C++ types")
    @MainActor
    func typeText() async throws {
        let results = try await evaluate([
            "vectorType('int')", "sharedType('B')", "weakType('B')", "optionalType('int')", "constReference('std::string')",
            "declarator('const int &', 'x')", "declarator('int', 'x')", "textViewType()", "enumerationBaseType()",
            "makeSharedFunction()",
        ])
        #expect(
            results == [
                "std::vector<int>", "std::shared_ptr<B>", "std::weak_ptr<B>", "std::optional<int>", "const std::string &",
                "const int &x", "int x", "std::string_view", "std::int32_t", "std::make_shared",
            ])
    }

    @Test("Default value literals become C++ literals by the style of the type table")
    @MainActor
    func literals() async throws {
        let results = try await evaluate([
            "literalExpression('14', 'number')", "literalExpression('-1.5e3', 'number')",
            "literalExpression('x', 'number')", "literalExpression('TRUE', 'boolean')",
            "literalExpression('maybe', 'boolean')", "literalExpression('abc', 'string')",
            "literalExpression('xyz', 'character')", "literalExpression('x', '')", "literalExpression('x', null)",
        ])
        #expect(results == ["14", "-1.5e3", "", "true", "", "\"abc\"", "120", "", ""])
    }

    @Test("String literals escape quotes, backslashes and control characters")
    @MainActor
    func stringLiterals() async throws {
        let results = try await evaluate([
            "cppStringLiteral('plain')", #"cppStringLiteral('say "hi"')"#, #"cppStringLiteral('a\\b')"#,
            #"cppStringLiteral('a\nb')"#, #"cppStringLiteral('a\tb')"#, "cppStringLiteral('caf\u{E9}')",
            "cppStringLiteral(1.fromCharacterCode())", "cppStringLiteral(27.fromCharacterCode())",
            "cppStringLiteral('')",
        ])
        #expect(
            results == [
                #""plain""#, #""say \"hi\"""#, #""a\\b""#, #""a\nb""#, #""a\tb""#, "\"caf\u{E9}\"", #""\001""#,
                #""\033""#, #""""#,
            ])
    }

    @Test("Built-in model types map to C++ types by name and by instance class")
    @MainActor
    func typeMappings() async throws {
        let results = try await evaluate([
            "typeMapping('EString').targetType", "typeMapping('EInt').targetType", "typeMapping('EInt').zeroValue",
            "typeMapping('EIntegerObject').zeroValue", "typeMapping('ELong').targetType",
            "instanceMapping('java.util.Date').targetType", "instanceMapping('java.lang.String').modelType",
            "instanceMapping('int').modelType", "typeMapping('EDate').module", "typeMapping('EClass').targetType",
            "typeMapping('EObject').targetType", "typeMapping('EBoolean').byValue",
            "typeMapping('EIntegerObject').module", "typeMapping('EIntegerObject').targetType",
        ])
        #expect(
            results == [
                "std::string", "std::int32_t", "0", "", "std::int64_t", "std::chrono::system_clock::time_point",
                "EString", "EInt", "chrono", "EObject", "EObject", "true", "optional cstdint",
                "std::optional<std::int32_t>",
            ])
    }

    @Test("The type table maps no instance class to two model types, and every built-in type has a mapping")
    func typeTable() throws {
        let set = try TemplateSet.assemble(language: "cpp")
        defer { set.remove() }
        let table = try String(
            contentsOf: set.directory.appendingPathComponent("cpp-types.xmi"), encoding: .utf8)
        let classes = table.components(separatedBy: "instanceClass=\"").dropFirst().compactMap {
            $0.components(separatedBy: "\"").first
        }
        #expect(classes.count > 10)
        #expect(Set(classes).count == classes.count)
        for type in [
            "EString", "EBoolean", "EBooleanObject", "EByte", "EByteObject", "EByteArray", "EChar", "ECharacterObject",
            "EDouble", "EDoubleObject", "EFloat", "EFloatObject", "EInt", "EIntegerObject", "ELong", "ELongObject",
            "EShort", "EShortObject", "EBigDecimal", "EBigInteger", "EDate", "EJavaObject", "EObject", "EClass",
        ] {
            #expect(table.contains("modelType=\"\(type)\""), "\(type) has no mapping")
        }
    }

    // MARK: - Documentation and includes

    @Test("Documentation becomes documentation comment lines with no trailing blanks, the first paragraph the brief")
    @MainActor
    func documentationComments() async throws {
        let results = try await evaluate([
            #"docComment('one\n\ntwo')"#, "docComment('single')", #"briefComment('one\n\ntwo')"#,
            "briefComment('@deprecated x')", #"docComment('a\\')"#, #"documentationText(genModel, 'Fallback.')"#,
            "generatedTag()",
        ])
        #expect(results[0] == "/// one\n///\n/// two")
        #expect(results[1] == "/// single")
        #expect(results[2] == "/// @brief one\n///\n/// two")
        #expect(results[3] == "/// @deprecated x")
        #expect(results[4] == "/// a\\ ", "a trailing backslash would continue the comment")
        #expect(results[5] == "/// @brief Fallback.")
        #expect(results[6] == "// @generated")
    }

    @Test("Include directives are written once and in order, with the headers of the model first")
    @MainActor
    func includeDirectives() async throws {
        let results = try await evaluate([
            "standardInclude('vector')", "projectInclude('a/B.hpp')", "supportInclude()",
            "includedDirectives(Sequence{'#include <vector>', '#include \"b.hpp\"', '#include <string>', '#include <vector>', '#include \"a.hpp\"'})->join(',')",
        ])
        #expect(
            results == [
                "#include <vector>", "#include \"a/B.hpp\"", "#include \"EObject.hpp\"",
                "#include \"a.hpp\",#include \"b.hpp\",#include <string>,#include <vector>",
            ])
    }
}
