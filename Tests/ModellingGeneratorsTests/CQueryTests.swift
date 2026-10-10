import Foundation
import Testing

@testable import ModellingGenerators

extension TemplateHarness {
    /// The imports that every harness module of the C template set declares.
    static let cModules = [
        "CNames", "CTypes", "CIncludes", "CDocumentation", "Header", "ClassQueries", "ClassHeader", "ClassSource",
        "ClassDescriptor", "EnumDeclaration", "DataTypeDeclaration", "EObjectHeader", "PackageHeader", "PackageSource",
    ]
}

@Suite("C naming and typing queries")
struct CQueryTests {
    /// The words of C and C++ that cannot name a type, field or parameter.
    static let keywords = [
        "int", "char", "struct", "union", "enum", "typedef", "static", "extern", "register", "volatile", "const",
        "signed", "unsigned", "void", "goto", "default", "switch", "case", "return", "sizeof", "inline", "restrict",
        "_Bool", "_Complex", "_Generic", "_Atomic", "_Noreturn", "_Static_assert", "_Thread_local", "bool", "true",
        "false", "nullptr", "constexpr", "typeof", "class", "namespace", "template", "this", "new", "delete",
        "operator", "private", "protected", "public", "virtual", "friend", "explicit", "mutable", "typename", "using",
        "throw", "try", "catch", "and", "or", "not", "xor", "decltype", "noexcept", "wchar_t",
    ]

    /// The names of the standard library and of the support header that cannot name a type, field or parameter.
    static let typeWords = [
        "NULL", "size_t", "ptrdiff_t", "FILE", "int8_t", "int32_t", "uint16_t", "int64_t", "intptr_t", "time_t",
        "va_list", "errno", "assert", "stdin", "EOF", "EXIT_SUCCESS", "SIZE_MAX", "EObject", "EClassInfo",
        "EFeatureInfo", "EFeatureKind", "EPackageInfo", "EByteArray", "EList", "EObject_destroy", "EObject_grown",
        "EFeatureKind_Attribute",
    ]

    /// The names that the generated structures and functions claim.
    static let memberWords = [
        "eObject", "eClass", "self", "value", "index", "literal", "copy", "items", "previous", "object", "position",
        "capacity",
    ]

    /// Evaluates expressions of the C template modules against a fixture.
    ///
    /// - Parameters:
    ///   - expressions: The expressions to evaluate.
    ///   - fixture: The name of the fixture to evaluate against.
    /// - Returns: The text of each expression.
    @MainActor
    func evaluate(_ expressions: [String], fixture: String = "library") async throws -> [String] {
        let golden = try #require(CGoldenCase.named(fixture))
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options, language: "c")
        defer { generated.remove() }
        let harness = TemplateHarness(generated: generated, modules: TemplateHarness.cModules)
        let body = expressions.map { "[\($0)/]" }.joined(separator: "|")
        return try await harness.run(body).components(separatedBy: "|")
    }

    /// The expression for the features that the structure of a class of the generator model holds.
    ///
    /// - Parameter name: The name of the class.
    /// - Returns: An expression for the features, inherited ones first.
    func features(of name: String) -> String {
        "genModel.allGenPackages().genClasses->select(c | c.name() = '\(name)')->first().implementedFeatures()"
    }

    // MARK: - Reserved words

    @Test("Keywords of C and C++ get a trailing underscore")
    @MainActor
    func keywordsAreEscaped() async throws {
        let results = try await evaluate(Self.keywords.map { "safeName('\($0)')" })
        #expect(results == Self.keywords.map { $0 + "_" })
    }

    @Test("Names of the standard library and of the support header get a trailing underscore")
    @MainActor
    func typeNamesAreEscaped() async throws {
        let results = try await evaluate(Self.typeWords.map { "safeName('\($0)')" })
        #expect(results == Self.typeWords.map { $0 + "_" })
    }

    @Test("Names that the generated code claims get a trailing underscore")
    @MainActor
    func memberNamesAreEscaped() async throws {
        let results = try await evaluate(Self.memberWords.map { "safeName('\($0)')" })
        #expect(results == Self.memberWords.map { $0 + "_" })
    }

    @Test("Other names stay as they are, and the escape is for exact names only")
    @MainActor
    func ordinaryNames() async throws {
        let names = [
            "label", "operation", "name", "Type", "Class", "Int", "Guard", "classes", "inside", "Book", "Static", "NULLs",
            "int_", "eclass",
        ]
        let results = try await evaluate(names.map { "safeName('\($0)')" })
        #expect(results == names)
        let tests = try await evaluate(["isReserved('NULL')", "isReserved('label')", "isReserved('int')"])
        #expect(tests == ["true", "false", "true"])
    }

    @Test("The reserved words are listed once each, with the kinds keyword, type and member")
    func reservedWordsAreListedOnce() throws {
        let set = try TemplateSet.assemble(language: "c")
        defer { set.remove() }
        let table = try String(
            contentsOf: set.directory.appendingPathComponent("c-types.xmi"), encoding: .utf8)
        let lists = table.components(separatedBy: "<reservedWords ").dropFirst().compactMap {
            $0.components(separatedBy: "words=\"").dropFirst().first?.components(separatedBy: "\"").first
        }
        #expect(lists.count == 3)
        let words = lists.flatMap { $0.split(separator: " ").map(String.init) }
        #expect(words.count > 200)
        #expect(Set(words).count == words.count, "a word is listed twice")
        #expect(!lists.contains { $0.hasPrefix(" ") || $0.hasSuffix(" ") || $0.contains("  ") }, "words are separated by single spaces")
        for kind in ["keyword", "type", "member"] {
            #expect(table.contains("<reservedWords kind=\"\(kind)\" words=\""), "no words of the kind \(kind)")
        }
        for word in Self.keywords + Self.typeWords + Self.memberWords {
            #expect(words.contains(word), "\(word) is not listed")
        }
    }

    // MARK: - Files, packages and classes

    @Test("Packages have a header and a source file named after them, and a guard made from the path")
    @MainActor
    func packageNames() async throws {
        let results = try await evaluate(
            [
                "genModel.allGenPackages()->collect(p | p.headerPath())->join(',')",
                "genModel.allGenPackages()->collect(p | p.sourcePath())->join(',')",
                "genModel.allGenPackages()->collect(p | p.includeGuard())->join(',')",
                "genModel.allGenPackages()->collect(p | p.headerInclude())->join(',')",
                "genModel.allGenPackages()->collect(p | p.packageDirectory())->join(',')",
                "genModel.allGenPackages()->collect(p | p.hasClassifiers())->join(',')",
                "supportHeaderName()", "supportGuard()", "headerExtension() + sourceExtension()",
            ], fixture: "nested")
        #expect(
            results == [
                "company/company.h,company/people/people.h,company/projects/projects.h,company/projects/archive/archive.h",
                "company/company.c,company/people/people.c,company/projects/projects.c,company/projects/archive/archive.c",
                "COMPANY_COMPANY_H,COMPANY_PEOPLE_PEOPLE_H,COMPANY_PROJECTS_PROJECTS_H,COMPANY_PROJECTS_ARCHIVE_ARCHIVE_H",
                #""company/company.h","company/people/people.h","company/projects/projects.h","company/projects/archive/archive.h""#,
                "company,company/people,company/projects,company/projects/archive", "true,true,true,true",
                "EObject.h", "EOBJECT_H", ".h.c",
            ])
    }

    @Test("The names of the package description and the factory come from the prefix of the package")
    @MainActor
    func packageDescriptionNames() async throws {
        let results = try await evaluate(
            [
                "genModel.allGenPackages()->collect(p | p.packageInfoName())->join(',')",
                "genModel.allGenPackages()->collect(p | p.factoryFunctionName())->join(',')",
                "genModel.allGenPackages()->collect(p | p.classListName())->join(',')",
            ], fixture: "nested")
        #expect(
            results == [
                "CompanyPackage,PeoplePackage,ProjPackage,ArchivePackage",
                "CompanyFactory_create,PeopleFactory_create,ProjFactory_create,ArchiveFactory_create",
                "CompanyPackage_classes,PeoplePackage_classes,ProjPackage_classes,ArchivePackage_classes",
            ])
    }

    @Test("Classes are escaped as types, and their functions are named after the type")
    @MainActor
    func classNames() async throws {
        let classes = "genModel.allGenPackages().genClasses"
        let results = try await evaluate(
            [
                "\(classes)->collect(c | c.className())->join(',')",
                "\(classes)->collect(c | c.descriptorName())->join(',')",
                "\(classes)->select(c | c.name() = 'Vehicle')->first().createName()",
                "\(classes)->select(c | c.name() = 'Vehicle')->first().destroyName()",
                "\(classes)->select(c | c.name() = 'static')->first().createName()",
                "\(classes)->select(c | c.name() = 'static')->first().featureTableName()",
                "\(classes)->select(c | c.name() = 'static')->first().superTableName()",
                "\(classes)->select(c | c.name() = 'static')->first().tableCreateName()",
                "\(classes)->select(c | c.name() = 'static')->first().tableDestroyName()",
                "genModel.allGenPackages().genEnums->collect(e | e.classifierName())->join(',')",
                "genModel.allGenPackages().genDataTypes->collect(d | d.classifierName())->join(',')",
            ], fixture: "cnames")
        #expect(
            results == [
                "Vehicle,Truck,Driver,static_,FILE_,EObject_,Shape,Wheel",
                "Vehicle_class,Truck_class,Driver_class,static__class,FILE__class,EObject__class,Shape_class,Wheel_class",
                "Vehicle_create", "Vehicle_destroy", "static__create", "static__features", "static__superTypes",
                "static__create_object", "static__destroy_object", "Mode", "size_t_",
            ])
    }

    @Test("Classes that are abstract, interfaces or extended are plain objects; only classes with instances have structures")
    @MainActor
    func classKinds() async throws {
        let classes = "genModel.allGenPackages().genClasses"
        let results = try await evaluate(
            [
                "\(classes)->collect(c | c.isProtocol())->join(',')", "\(classes)->collect(c | c.isInstantiable())->join(',')",
                "\(classes)->collect(c | c.hasSubclasses())->join(',')",
                "\(classes)->collect(c | c.modelSupers()->size())->join(',')",
            ], fixture: "cnames")
        #expect(
            results == [
                "true,false,false,false,false,false,true,false", "true,true,true,true,true,true,false,true",
                "true,false,false,false,false,false,false,false", "0,1,0,0,0,0,0,0",
            ])
        let library = try await evaluate(
            [
                "\(classes)->collect(c | c.name())->join(',')", "\(classes)->collect(c | c.isProtocol())->join(',')",
                "\(classes)->collect(c | c.isInstantiable())->join(',')",
                "\(classes)->select(c | c.name() = 'Book')->first().implementedFeatures()->collect(f | f.genClass().name())->asSet()->size()",
            ])
        #expect(
            library == [
                "Named,Lendable,Book,Writer,Library", "true,true,false,false,false", "false,false,true,true,true", "3",
            ])
    }

    @Test("The constants and conversion functions of an enumeration are named after the enumeration")
    @MainActor
    func enumerationNames() async throws {
        let enums = "genModel.allGenPackages().genEnums"
        let results = try await evaluate(
            [
                "\(enums)->first().literalConstant(\(enums)->first().genEnumLiterals->first())",
                "\(enums)->first().literalFunctionName()", "\(enums)->first().fromLiteralFunctionName()",
                "\(enums)->collect(e | e.genEnumLiterals->collect(l | e.literalConstant(l)))->join(',')",
            ], fixture: "enumerations")
        #expect(results[0] == "Colour_Red")
        #expect(results[1] == "Colour_literal")
        #expect(results[2] == "Colour_from_literal")
        #expect(results[3].contains("Mode_default,Mode_fastForward,Mode_HTTPServer,Mode__,Mode_quote"))
        #expect(results[3].hasSuffix("Colour_Green,Mode_default,Mode_fastForward,Mode_HTTPServer,Mode__,Mode_quote"))
    }

    // MARK: - Features

    @Test("Features are stored as scalars, owned text, owned bytes or pointers")
    @MainActor
    func featureTypes() async throws {
        let book = features(of: "Book")
        let writer = features(of: "Writer")
        let library = features(of: "Library")
        let results = try await evaluate([
            "\(book)->collect(f | f.itemTypeName())->join(',')", "\(book)->collect(f | f.valueTypeName())->join(',')",
            "\(book)->collect(f | f.fieldTypeName())->join(',')", "\(book)->collect(f | f.storage())->join(',')",
            "\(book)->collect(f | f.zeroValue())->join(',')", "\(book)->collect(f | f.defaultExpression())->join(',')",
            "\(book)->collect(f | f.copiesValue())->join(',')", "\(writer)->collect(f | f.fieldTypeName())->join(',')",
            "\(book)->collect(f | f.pointsToStructure())->join(',')", "\(library)->collect(f | f.isOwning())->join(',')",
            "\(book)->collect(f | f.featureKindConstant())->join(',')",
            "\(library)->collect(f | f.featureKindConstant())->join(',')",
        ])
        #expect(
            results == [
                "char *,int32_t,bool,int32_t,BookCategory,ISBN,Writer *,Library *",
                "const char *,int32_t,bool,int32_t,BookCategory,const char *,Writer *,Library *",
                "char *,int32_t,bool,int32_t,BookCategory,ISBN,Writer *,Library *",
                "string,scalar,scalar,scalar,scalar,string,pointer,pointer",
                "NULL,0,false,0,(BookCategory)0,NULL,NULL,NULL", "NULL,14,false,100,BookCategory_Mystery,NULL,NULL,NULL",
                "true,false,false,false,false,true,false,false", "char *,EList(char *),EList(Book *)",
                "false,false,false,false,false,false,true,true", "false,true,true",
                "EFeatureKind_Attribute,EFeatureKind_Attribute,EFeatureKind_Attribute,EFeatureKind_Attribute,EFeatureKind_Attribute,EFeatureKind_Attribute,EFeatureKind_Reference,EFeatureKind_Reference",
                "EFeatureKind_Attribute,EFeatureKind_Containment,EFeatureKind_Containment",
            ])
    }

    @Test("Values are released by freeing owned text and bytes and destroying contained objects")
    @MainActor
    func releasing() async throws {
        let book = features(of: "Book")
        let library = features(of: "Library")
        let results = try await evaluate([
            "\(book)->collect(f | f.releaseStatement('x'))->join(',')",
            "\(library)->collect(f | f.releaseStatement('self->books'))->join(',')",
            "\(book)->collect(f | f.releasesValues())->join(',')", "\(library)->collect(f | f.releasesValues())->join(',')",
        ])
        #expect(
            results == [
                "free(x);,,,,,free(x);,,", "free(self->books);,EObject_destroy((EObject *)self->books);,EObject_destroy((EObject *)self->books);",
                "true,false,false,false,false,true,false,false", "true,true,true",
            ])
    }

    @Test("The names of the functions of a feature join the type, an action and the feature")
    @MainActor
    func accessorNames() async throws {
        let writer = "genModel.allGenPackages().genClasses->select(c | c.name() = 'Writer')->first()"
        let aliases = "\(writer).implementedFeatures()->select(f | f.name() = 'aliases')->first()"
        let named = try await evaluate([
            "\(writer).getterName(\(aliases))", "\(writer).setterName(\(aliases))", "\(writer).countName(\(aliases))",
            "\(writer).itemName(\(aliases))", "\(writer).addName(\(aliases))", "\(writer).removeName(\(aliases))",
            "\(writer).clearName(\(aliases))",
        ])
        #expect(
            named == [
                "Writer_get_aliases", "Writer_set_aliases", "Writer_count_aliases", "Writer_item_aliases",
                "Writer_add_aliases", "Writer_remove_aliases", "Writer_clear_aliases",
            ])
    }

    @Test("A field whose name a type of the structure uses is escaped once more")
    @MainActor
    func fieldNames() async throws {
        let vehicle = "genModel.allGenPackages().genClasses->select(c | c.name() = 'Vehicle')->first()"
        let results = try await evaluate(
            [
                "\(vehicle).implementedFeatures()->collect(f | \(vehicle).fieldName(f))->join(',')",
                "\(vehicle).usedTypeNames()->includes('static_')", "\(vehicle).usedTypeNames()->includes('Driver')",
                "\(vehicle).usedTypeNames()->includes('char *')",
            ], fixture: "cnames")
        #expect(results[0].hasPrefix("int_,register_,union_,class_,namespace_,new_,delete_,template_,this_,signed_,NULL_,eObject_,bool_,default_,size_t_,mode,modes,keywords,driver,wheels,"))
        #expect(results[0].hasSuffix(",static__"))
        #expect(results[1...3] == ["true", "true", "false"])
    }

    // MARK: - Literals and documentation

    @Test("String literals escape quotes, backslashes, control characters and question marks")
    @MainActor
    func stringLiterals() async throws {
        let results = try await evaluate([
            "cStringLiteral('plain')", #"cStringLiteral('say "hi"')"#, #"cStringLiteral('a\\b')"#, #"cStringLiteral('a\nb')"#,
            #"cStringLiteral('a\tb')"#, "cStringLiteral('caf\u{E9}')", "cStringLiteral(1.fromCharacterCode())",
            "cStringLiteral(127.fromCharacterCode())", "cStringLiteral('what??')", "cStringLiteral('')",
            "cStringLiteral(null)",
        ])
        #expect(
            results == [
                #""plain""#, #""say \"hi\"""#, #""a\\b""#, #""a\nb""#, #""a\tb""#, "\"caf\u{E9}\"", #""\001""#, #""\177""#,
                #""what\?\?""#, #""""#, "NULL",
            ])
        let codes = try await evaluate(["escapeCode(10, 'x')", "escapeCode(63, '?')", "escapeCode(65, 'A')"])
        #expect(codes == [#"\n"#, #"\?"#, "A"])
    }

    @Test("Documentation becomes Doxygen comment lines with a brief tag and no trailing blanks")
    @MainActor
    func documentationComments() async throws {
        let results = try await evaluate([
            #"docComment('one\n\ntwo')"#, "docComment('single')", "docComment('@deprecated use X')",
            #"documentationText(genModel, 'Fallback.')"#, "generatedTag()",
        ])
        #expect(results[0] == "/// @brief one\n///\n/// two")
        #expect(results[1] == "/// @brief single")
        #expect(results[2] == "/// @deprecated use X")
        #expect(results[3] == "/// @brief Fallback.")
        #expect(results[4] == "// @generated")
    }

    @Test("Default value literals become C literals by the style of the type table")
    @MainActor
    func literals() async throws {
        let results = try await evaluate([
            "literalExpression('14', 'number')", "literalExpression('-1.5e3', 'number')",
            "literalExpression('x', 'number')", "literalExpression('007', 'number')",
            "literalExpression('-0012', 'number')", "literalExpression('0.5', 'number')",
            "literalExpression('0', 'number')", "literalExpression('00', 'number')",
            "literalExpression('TRUE', 'boolean')", "literalExpression('maybe', 'boolean')",
            "literalExpression('abc', 'string')", "literalExpression('xyz', 'character')",
            "literalExpression('x', '')", "literalExpression('x', null)",
        ])
        #expect(results == ["14", "-1.5e3", "", "7", "-12", "0.5", "0", "0", "true", "", "\"abc\"", "120", "", ""])
    }

    // MARK: - Includes and declarations

    @Test("Headers are included once and in sorted order, the headers of the generated code first")
    @MainActor
    func includedHeaders() async throws {
        let results = try await evaluate([
            #"includedHeaders(Sequence{'<stdlib.h>', '"EObject.h"', '<stdbool.h>', '<stdlib.h>'})->join(',')"#,
            "headerIncludes()->join(',')", "sourceIncludes()->join(',')", "supportHeaderIncludes()->join(',')",
            "supportInclude()",
        ])
        #expect(
            results == [
                #""EObject.h",<stdbool.h>,<stdlib.h>"#, #""EObject.h",<stdbool.h>,<stddef.h>,<stdint.h>"#,
                "<stdlib.h>,<string.h>", "<stdbool.h>,<stddef.h>,<stdint.h>,<stdlib.h>,<string.h>", #""EObject.h""#,
            ])
    }

    @Test("The header of a feature is the header of a mapped type or of the package that declares its type")
    @MainActor
    func featureIncludes() async throws {
        let book = features(of: "Book")
        let results = try await evaluate([
            "\(book)->collect(f | f.featureInclude(f.genClass().genPackage()))->join(',')",
        ])
        #expect(results == [",<stdint.h>,<stdbool.h>,<stdint.h>,,,,"])
    }

    @Test("A declaration puts a space between the type and the name unless the type ends in an asterisk")
    @MainActor
    func declarations() async throws {
        let results = try await evaluate([
            "declare('char *', 'name')", "declare('int32_t', 'pages')", "declare('EList(char *)', 'aliases')",
            "declare('const char *', 'value')",
        ])
        #expect(results == ["char *name", "int32_t pages", "EList(char *) aliases", "const char *value"])
    }

    // MARK: - The type table

    @Test("Built-in model types map to C types by name and by instance class")
    @MainActor
    func typeMappings() async throws {
        let results = try await evaluate([
            "typeMapping('EString').targetType", "typeMapping('EString').parameterType", "typeMapping('EString').storage",
            "typeMapping('EInt').targetType", "typeMapping('EInt').zeroValue", "typeMapping('EIntegerObject').targetType",
            "typeMapping('EIntegerObject').zeroValue", "typeMapping('ELong').targetType",
            "typeMapping('EByteArray').storage", "typeMapping('EByteArray').zeroValue", "typeMapping('EChar').targetType",
            "typeMapping('EDate').targetType", "typeMapping('EDate').storage", "typeMapping('EJavaObject').storage",
            "typeMapping('EBigInteger').storage", "typeMapping('EObject').targetType", "typeMapping('EFloat').zeroValue",
            "instanceMapping('java.util.Date').targetType", "instanceMapping('java.lang.String').modelType",
            "instanceMapping('int').modelType", "typeMapping('EInt').module", "typeMapping('EString').module",
            "typeMapping('EBoolean').module", "enumStorageType()", "listMacro()",
            "itemsMember() + countMember() + capacityMember()",
        ])
        #expect(
            results == [
                "char *", "const char *", "string", "int32_t", "0", "int32_t", "0", "int64_t", "bytes",
                "(EByteArray){NULL, 0}", "uint16_t", "int64_t", "scalar", "pointer", "string", "EObject *", "0.0f",
                "int64_t", "EString", "EInt", "<stdint.h>", "", "<stdbool.h>", "int", "EList", "itemscountcapacity",
            ])
    }

    @Test("The type table maps no instance class to two model types, and every mapping has a known storage")
    func tableIsConsistent() throws {
        let set = try TemplateSet.assemble(language: "c")
        defer { set.remove() }
        let table = try String(
            contentsOf: set.directory.appendingPathComponent("c-types.xmi"), encoding: .utf8)
        let classes = table.components(separatedBy: "instanceClass=\"").dropFirst().compactMap {
            $0.components(separatedBy: "\"").first
        }
        #expect(classes.count > 10)
        #expect(Set(classes).count == classes.count)
        let storages = table.components(separatedBy: "storage=\"").dropFirst().compactMap {
            $0.components(separatedBy: "\"").first
        }
        #expect(storages.count == table.components(separatedBy: "<mappings ").count - 1, "a mapping has no storage")
        #expect(Set(storages).isSubset(of: ["scalar", "string", "bytes", "pointer"]))
        #expect(Set(storages).count == 4)
    }
}
