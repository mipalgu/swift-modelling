import Foundation
import Testing

@testable import ModellingGenerators

/// Evaluates template expressions against a fixture, with a set of named bindings.
struct FixtureExpressions {
    /// The name of the fixture directory.
    let fixture: String

    /// The file stem of the source model.
    let stem: String

    /// The import options of the generator model.
    let options: GenModelImportOptions

    /// The variables that expressions can use: name, type and defining expression.
    let bindings: [(name: String, type: String, value: String)]

    /// Evaluates expressions and splits the output at the separating bars.
    ///
    /// - Parameter expressions: The template expressions, each written without its brackets.
    /// - Returns: The value of each expression as text.
    @MainActor
    func evaluate(_ expressions: [String]) async throws -> [String] {
        let generated = try await GeneratedProject.make(fixture, stem: stem, options: options)
        defer { generated.remove() }
        let opening = bindings.map { "[let \($0.name) : \($0.type) = \($0.value)]" }.joined()
        let closing = String(repeating: "[/let]", count: bindings.count)
        let body = opening + expressions.map { "[\($0)/]" }.joined(separator: "|") + closing
        return try await TemplateHarness(generated: generated).run(body).components(separatedBy: "|")
    }

    /// The expressions for the enumerations fixture.
    static let enumerations = FixtureExpressions(
        fixture: "enumerations", stem: "enumerations",
        options: GenModelImportOptions(basePackage: "org.example.traffic"),
        bindings: [
            ("p", "GenPackage", "genModel.allGenPackages()->first()"),
            ("colour", "GenEnum", "p.genEnums->at(1)"),
            ("mode", "GenEnum", "p.genEnums->at(2)"),
            ("light", "GenClass", "p.genClasses->first()"),
        ])

    /// The expressions for the nested packages fixture.
    static let nested = FixtureExpressions(
        fixture: "nested", stem: "company",
        options: GenModelImportOptions(
            basePackage: "org.example.company", packagePrefixes: ["projects": "Proj"]),
        bindings: [
            ("root", "GenPackage", "genModel.allGenPackages()->at(1)"),
            ("people", "GenPackage", "genModel.allGenPackages()->at(2)"),
            ("projects", "GenPackage", "genModel.allGenPackages()->at(3)"),
            ("employee", "GenClass", "people.genClasses->at(2)"),
        ])

    /// The expressions for the Ecore built-in types fixture.
    static let bridge = FixtureExpressions(
        fixture: "ecoretypes", stem: "bridge", options: GenModelImportOptions(),
        bindings: [
            ("p", "GenPackage", "genModel.allGenPackages()->first()"),
            ("span", "GenClass", "p.genClasses->first()"),
            ("label", "GenFeature", "span.genFeatures->at(1)"),
            ("length", "GenFeature", "span.genFeatures->at(2)"),
            ("payload", "GenFeature", "span.genFeatures->at(3)"),
            ("supports", "GenFeature", "span.genFeatures->at(4)"),
            ("next", "GenFeature", "span.genFeatures->at(5)"),
        ])
}

@Suite("Java naming queries")
struct JavaNamesTests {
    @Test("Packages combine the base package, the package name and the suffixes")
    @MainActor
    func packageNames() async throws {
        let values = try await FixtureExpressions.nested.evaluate([
            "root.qualifiedPackageName()", "people.qualifiedPackageName()", "projects.qualifiedPackageName()",
            "people.basePackageName()", "root.basePackageName()", "projects.interfacePackageName()",
            "projects.classPackageName()", "projects.utilitiesPackageName()", "projects.reflectionPackageName()",
            "employee.qualifiedInterfaceName()", "employee.qualifiedClassName()",
            "employee.interfaceName()", "employee.className()",
        ])
        #expect(values == [
            "org.example.company.company", "org.example.company.company.people",
            "org.example.company.company.projects", "org.example.company.company",
            "org.example.company", "org.example.company.company.projects",
            "org.example.company.company.projects.impl", "org.example.company.company.projects.util",
            "org.example.company.company.projects", "org.example.company.company.people.Employee",
            "org.example.company.company.people.impl.EmployeeImpl", "Employee", "EmployeeImpl",
        ])
    }

    @Test("Package classes carry the prefix of their package")
    @MainActor
    func packageClasses() async throws {
        let values = try await FixtureExpressions.nested.evaluate([
            "projects.packageInterfaceName()", "projects.packageClassName()",
            "projects.qualifiedPackageInterfaceName()", "projects.qualifiedPackageClassName()",
            "projects.factoryInterfaceName()", "projects.factoryClassName()", "root.packageInterfaceName()",
            "projects.prefixedName('Switch')",
        ])
        #expect(values == [
            "ProjPackage", "ProjPackageImpl", "org.example.company.company.projects.ProjPackage",
            "org.example.company.company.projects.impl.ProjPackageImpl", "ProjFactory", "ProjFactoryImpl",
            "CompanyPackage", "ProjSwitch",
        ])
    }

    @Test("Reserved words get an underscore and other names stay")
    @MainActor
    func safeNames() async throws {
        let values = try await FixtureExpressions.enumerations.evaluate([
            "safeName('class')", "safeName('default')", "safeName('Default')", "safeName('name')",
            "safeName('true')", "safeName('goto')", "safeName('record')",
            "safeFeatureName(light.genFeatures->first())",
            "'ClassName'.uncapPrefixedName().safeName()",
        ])
        #expect(values == ["class_", "default_", "Default", "name", "true_", "goto_", "record", "colour", "className"])
    }

    @Test("Blank text and package affixes")
    @MainActor
    func affixes() async throws {
        let values = try await FixtureExpressions.enumerations.evaluate([
            "isBlank(null)", "isBlank('')", "isBlank('x')", "addPackageSuffix('a.b', '')", "addPackageSuffix('a.b', 'c')",
            "addPackagePrefix('', 'b')", "addPackagePrefix('a', 'b')", "packagePath('a.b.c')",
        ])
        #expect(values == ["true", "true", "false", "a.b", "a.b.c", "b", "a.b", "a/b/c"])
    }

    @Test("Compliance levels decide on generics and override annotations")
    @MainActor
    func complianceLevels() async throws {
        let values = try await FixtureExpressions.enumerations.evaluate([
            "genModel.complianceLevel()", "genModel.useGenerics()", "genModel.useClassOverrideAnnotation()",
            "genModel.useInterfaceOverrideAnnotation()", "genModel.isOn('nonNLSMarkers')",
            "genModel.isOn('importOrganizing')", "genModel.isOn('noSuchSetting')",
        ])
        #expect(values == ["17.0", "true", "true", "true", "false", "true", "false"])
    }

    @Test("Enumeration literals follow the constant naming conventions")
    @MainActor
    func literalConstants() async throws {
        let values = try await FixtureExpressions.enumerations.evaluate([
            "mode.genEnumLiterals->collect(l | l.enumLiteralID())->join(',')",
            "mode.genEnumLiterals->collect(l | l.enumLiteralInstanceConstantName())->join(',')",
            "mode.genEnumLiterals->collect(l | l.enumLiteralValueConstantName())->join(',')",
            "mode.genEnumLiterals->collect(l | l.enumLiteralName())->join(',')",
            "mode.usesTypeSafeConstants()", "colour.qualifiedEnumName()",
            "colour.formattedClassifierName()", "mode.genEnumLiterals->collect(l | l.formattedLiteralName())->join(',')",
        ])
        #expect(values == [
            "DEFAULT,FAST_FORWARD,HTTP_SERVER,__,QUOTE", "DEFAULT,FAST_FORWARD,HTTP_SERVER,__,QUOTE",
            "DEFAULT_VALUE,FAST_FORWARD_VALUE,HTTP_SERVER_VALUE,___VALUE,QUOTE_VALUE",
            "default,fastForward,HTTPServer,__,quote", "false", "org.example.traffic.enumerations.Colour",
            "Colour", "Default,Fast Forward,HTTP Server,,Quote",
        ])
    }

    @Test("Accessor names follow the feature kind")
    @MainActor
    func accessors() async throws {
        let values = try await FixtureExpressions.bridge.evaluate([
            "label.getAccessor(false)", "length.getAccessor(true)", "label.featureAccessorName()",
            "label.safeFeatureName()", "p.genClasses->first().classifierAccessorName()",
        ])
        #expect(values == ["getLabel", "isLength", "Span_Label", "label", "Span"])
    }
}

@Suite("Java type queries")
struct JavaTypesTests {
    @Test("Built-in data types map through the type table")
    @MainActor
    func builtInTypes() async throws {
        let values = try await FixtureExpressions.bridge.evaluate([
            "label.ecoreFeature.eType.instanceClassName()", "length.ecoreFeature.eType.instanceClassName()",
            "payload.ecoreFeature.eType.instanceClassName()", "label.itemTypeName()", "length.itemTypeName()",
            "supports.itemTypeName()", "next.itemTypeName()",
        ])
        #expect(values == [
            "java.lang.String", "double", "java.lang.Object", "java.lang.String", "double",
            "org.eclipse.emf.ecore.EObject", "bridge.Span",
        ])
    }

    @Test("Primitive types have wrapper classes and zero values")
    @MainActor
    func primitives() async throws {
        let values = try await FixtureExpressions.bridge.evaluate([
            "isPrimitiveType('int')", "isPrimitiveType('java.lang.Integer')", "isPrimitiveType('java.lang.String')",
            "objectTypeName('int')", "objectTypeName('boolean')", "objectTypeName('java.lang.String')",
            "zeroValue('int')", "zeroValue('boolean')", "zeroValue('java.lang.String')", "zeroValue('long')",
            "zeroValue('float')", "zeroValue('char')", "zeroValue('com.example.Unknown')",
            "length.listItemTypeName()", "label.listItemTypeName()",
        ])
        #expect(values == [
            "true", "false", "false", "java.lang.Integer", "java.lang.Boolean", "java.lang.String", "0", "false",
            "null", "0L", "0.0F", "'\\u0000'", "null", "java.lang.Double", "java.lang.String",
        ])
    }

    @Test("Many-valued features use lists and single-valued features use their type")
    @MainActor
    func containerTypes() async throws {
        let values = try await FixtureExpressions.bridge.evaluate([
            "supports.listTypeName()", "supports.isMapType()", "next.isMapType()",
            "importedType(label)", "importedType(length)", "importedType(supports)", "importedType(next)",
            "importedType(payload)",
        ])
        #expect(values == [
            "org.eclipse.emf.common.util.EList", "false", "false", "String", "double", "EList<EObject>", "Span",
            "Object",
        ])
    }

    @Test("Classifiers stand for their interface, enum or instance class")
    @MainActor
    func classifierTypes() async throws {
        let values = try await FixtureExpressions.enumerations.evaluate([
            "qualifiedTypeName(light.ecoreClass)", "qualifiedTypeName(colour.ecoreEnum)",
            "qualifiedTypeName(null)", "light.genFeatures->first().itemTypeName()",
        ])
        #expect(values == [
            "org.example.traffic.enumerations.Light", "org.example.traffic.enumerations.Colour", "java.lang.Object",
            "org.example.traffic.enumerations.Colour",
        ])
    }
}

@Suite("Java import queries")
struct JavaImportsTests {
    /// Evaluates text that registers imports, against the enumerations fixture.
    @MainActor
    static func run(_ body: String) async throws -> String {
        let generated = try await GeneratedProject.make(
            "enumerations", stem: "enumerations", options: GenModelImportOptions(basePackage: "org.example.traffic"))
        defer { generated.remove() }
        return try await TemplateHarness(generated: generated).run(body)
    }

    @Test("Parts of qualified names")
    @MainActor
    func nameParts() async throws {
        let text = try await Self.run(
            "['a.b.C'.packageOf()/]|['a.b.C'.shortName()/]|['a.b.C$D'.importName()/]|['a.b.C$D'.baseName()/]|['C'.packageOf()/]|[isImplicitType('String')/]|[isImplicitType('List')/]"
        )
        #expect(text == "a.b|C|a.b.C|C.D||true|false")
    }

    @Test("The first claim on a simple name keeps it and later claims are qualified")
    @MainActor
    func conflicts() async throws {
        let text = try await Self.run(
            "[collect ('imports', 'org.example.Unit')/][importedName('java.util.List')/]|[importedName('java.awt.List')/]|[importedName('java.util.List')/]|[importedName('other.Unit')/]|[importedName('org.example.Unit')/]"
        )
        #expect(text == "List|java.awt.List|List|other.Unit|Unit")
    }

    @Test("Types of java.lang and of the unit's package need no import")
    @MainActor
    func implicitImports() async throws {
        let text = try await Self.run(
            "[collect ('imports', 'org.example.Unit')/][importedName('java.lang.String')/]|[importedName('java.lang.Integer')/]|[importedName('org.example.Sibling')/]|[importedName('Plain')/]|[importedName('org.other.Far')/]|[emit ('imports') once][importBlock(items)/][/emit]"
        )
        #expect(text == "String|Integer|Sibling|Plain|Far|import org.other.Far;\n")
    }

    @Test("The import block is sorted and separated by package")
    @MainActor
    func importBlock() async throws {
        let text = try await Self.run(
            "[collect ('imports', 'org.example.Unit')/][addTypes()/][emit ('imports') once][importBlock(items)/][/emit]"
                .replacingOccurrences(
                    of: "[addTypes()/]",
                    with:
                        "[collect ('imports', Sequence{'org.b.Z', 'java.util.List', 'java.util.Arrays', 'org.a.Y'})/]")
        )
        #expect(text == "import java.util.Arrays;\nimport java.util.List;\n\nimport org.a.Y;\n\nimport org.b.Z;\n")
    }

    @Test("Nested types are imported through their outermost type")
    @MainActor
    func nestedTypes() async throws {
        let text = try await Self.run(
            "[collect ('imports', 'org.example.Unit')/][importedName('org.other.Outer$Inner')/]|[importedName('org.other.Outer')/]|[emit ('imports') once][importBlock(items)/][/emit]"
        )
        #expect(text == "Outer.Inner|Outer|import org.other.Outer;\n")
    }
}

@Suite("Java documentation queries")
struct JavaDocumentationTests {
    @Test("Literals escape the characters Java needs escaped")
    @MainActor
    func stringLiterals() async throws {
        let values = try await FixtureExpressions.enumerations.evaluate([
            "javaStringLiteral('plain')", "javaStringLiteral(null)", "javaStringLiteral('say \"hi\"')",
            "javaStringLiteral('back\\\\slash')", "javaStringLiteral('tab\\there')", "javaStringLiteral('it\\'s')",
            "javaStringLiteral('line\\nbreak')", "javaStringLiteral('caf\u{e9}')", "javaStringLiteral('')",
        ])
        #expect(values == [
            "\"plain\"", "null", "\"say \\\"hi\\\"\"", "\"back\\\\slash\"", "\"tab\\there\"", "\"it\\'s\"",
            "\"line\\nbreak\"", "\"caf\\u00e9\"", "\"\"",
        ])
    }

    @Test("Text for comments and model tags is escaped and encoded")
    @MainActor
    func escapes() async throws {
        let values = try await FixtureExpressions.enumerations.evaluate([
            "escapeText('plain', '')", "escapeText('a b=c', ' =')", "escapeText('caf\u{e9}', '')",
            "escapeText('x/*y*/z', '')", "xmlEscape('a<b>&\"c\"')", "isPlainText('abc')", "isPlainText('a\"b')",
            "isPlainText('a*/b')",
        ])
        #expect(values == [
            "plain", "a\\040b\\075c", "caf\\351", "x/*y*/z", "a&lt;b&gt;&amp;&quot;c&quot;", "true", "false", "false",
        ])
    }

    @Test("Non-externalised string markers follow the generator model")
    @MainActor
    func nonNLS() async throws {
        let values = try await FixtureExpressions.enumerations.evaluate([
            "nonNLS(genModel, 1)", "nonNLS(genModel, 2)", "genModel.hasCopyrightField()",
            "genModel.copyrightFieldLiteral()",
        ])
        #expect(values == ["", "", "false", "null"])
    }

    @Test("Model tags list the settings that differ from the defaults")
    @MainActor
    func modelTags() async throws {
        let values = try await FixtureExpressions.enumerations.evaluate([
            "colour.modelInfo()->size()", "colour.modelTag(' * ', colour.modelInfo())",
            "mode.genEnumLiterals->at(1).modelTag(' * ', mode.genEnumLiterals->at(1).modelInfo())",
            "colour.genEnumLiterals->at(1).modelTag('   * ', colour.genEnumLiterals->at(1).modelInfo())",
        ])
        #expect(values == ["0", " * @model", " * @model name=\"default\"", "   * @model name=\"Red\"\n   *        literal=\"red\""])
    }
}
