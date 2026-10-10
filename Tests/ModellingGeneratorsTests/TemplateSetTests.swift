import Foundation
import Testing

@testable import ModellingGenerators

/// A scratch directory for template files, removed when the value goes out of scope.
struct ScratchDirectory {
    /// The location of the directory.
    let url: URL

    /// Creates an empty scratch directory.
    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-template-tests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    /// Writes a file below the directory, creating directories as needed.
    ///
    /// - Parameters:
    ///   - text: The content of the file.
    ///   - path: The path relative to the directory.
    func write(_ text: String, to path: String) throws {
        let file = url.appendingPathComponent(path)
        try FileManager.default.createDirectory(
            at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: file, atomically: true, encoding: .utf8)
    }

    /// Removes the directory.
    func remove() { try? FileManager.default.removeItem(at: url) }
}

@Suite("Template sets")
struct TemplateSetTests {
    @Test("The bundled Java set is assembled with its modules and data")
    func bundledJavaSet() throws {
        let set = try TemplateSet.assemble(language: "java")
        defer { set.remove() }
        #expect(set.descriptor.name == "java")
        #expect(set.descriptor.mainModule == "generate")
        #expect(set.descriptor.mainTemplate == "generate")
        #expect(set.descriptor.dataModels.map(\.name) == ["types"])
        #expect(set.descriptor.fileCountTemplate == "fileCount")
        #expect(set.descriptor.layout.sourceRootSetting == "modelDirectory")
        #expect(!set.descriptor.layout.includeSourceRoot)
        for file in [
            "generate.mtl", "EnumClass.mtl", "Header.mtl", "JavaNames.mtl", "JavaTypes.mtl",
            "JavaImports.mtl", "JavaDocumentation.mtl", "TypeMapping.ecore", "java-types.xmi",
        ] {
            #expect(
                FileManager.default.fileExists(atPath: set.directory.appendingPathComponent(file).path),
                "\(file) is missing")
        }
    }

    @Test("The bundled Swift set is assembled with its modules and data")
    func bundledSwiftSet() throws {
        let set = try TemplateSet.assemble(language: "swift")
        defer { set.remove() }
        #expect(set.descriptor.name == "swift")
        #expect(set.descriptor.summary?.isEmpty == false)
        #expect(set.descriptor.mainModule == "generate")
        #expect(set.descriptor.mainTemplate == "generate")
        #expect(set.descriptor.fileCountTemplate == "fileCount")
        #expect(set.descriptor.dataModels == [.init(name: "types", metamodel: "TypeMapping.ecore", model: "swift-types.xmi")])
        #expect(set.descriptor.layout.sourceRootSetting == "modelDirectory")
        #expect(!set.descriptor.layout.includeSourceRoot)
        #expect(set.descriptor.options.lineDelimiter == "\n")
        #expect(set.descriptor.styles.isEmpty && set.descriptor.defaultStyle == nil)
        for file in [
            "generate.mtl", "SwiftNames.mtl", "SwiftTypes.mtl", "SwiftImports.mtl", "SwiftDocumentation.mtl",
            "Header.mtl", "EnumClass.mtl", "DataTypeFile.mtl", "Class.mtl", "ClassQueries.mtl",
            "ClassFeature.mtl", "ClassReflection.mtl", "PackageClass.mtl", "FactoryClass.mtl",
            "TypeMapping.ecore", "swift-types.xmi",
        ] {
            #expect(
                FileManager.default.fileExists(atPath: set.directory.appendingPathComponent(file).path),
                "\(file) is missing")
        }
        #expect(set.mainModuleURL.lastPathComponent == "generate.mtl")
    }

    @Test("The Swift type table lists the built-in types, the reserved words and their kinds")
    func swiftTypeTable() throws {
        let set = try TemplateSet.assemble(language: "swift")
        defer { set.remove() }
        let table = try String(
            contentsOf: set.directory.appendingPathComponent("swift-types.xmi"), encoding: .utf8)
        #expect(table.contains(#"language="swift""#))
        for model in [
            "EString", "EBoolean", "EInt", "ELong", "EShort", "EByte", "EChar", "EDouble", "EFloat", "EBigInteger",
            "EBigDecimal", "EDate", "EJavaObject", "EByteArray", "EObject", "EClass",
        ] {
            #expect(table.contains(#"modelType="\#(model)""#), "\(model) is not mapped")
        }
        for word in ["guard", "Type", "class", "protocol", "default", "in", "operator", "repeat", "where"] {
            #expect(table.contains(#"word="\#(word)" kind="keyword""#), "\(word) is not a keyword")
        }
        for word in ["String", "Date", "Mutex"] { #expect(table.contains(#"word="\#(word)" kind="type""#)) }
        for word in ["id", "eClass", "hash"] { #expect(table.contains(#"word="\#(word)" kind="member""#)) }
        let metamodel = try String(
            contentsOf: set.directory.appendingPathComponent("TypeMapping.ecore"), encoding: .utf8)
        for feature in ["modelType", "targetType", "zeroValue", "instanceClass", "module", "literalStyle", "kind"] {
            #expect(metamodel.contains(#"name="\#(feature)""#), "\(feature) is not declared")
        }
    }

    @Test("The bundled C set is assembled with its modules and data")
    func bundledCSet() throws {
        let set = try TemplateSet.assemble(language: "c")
        defer { set.remove() }
        #expect(set.descriptor.name == "c")
        #expect(set.descriptor.summary?.isEmpty == false)
        #expect(set.descriptor.mainModule == "generate")
        #expect(set.descriptor.mainTemplate == "generate")
        #expect(set.descriptor.fileCountTemplate == "fileCount")
        #expect(set.descriptor.dataModels == [.init(name: "types", metamodel: "TypeMapping.ecore", model: "c-types.xmi")])
        #expect(set.descriptor.layout.sourceRootSetting == "modelDirectory")
        #expect(!set.descriptor.layout.includeSourceRoot)
        #expect(set.descriptor.options.lineDelimiter == "\n")
        #expect(set.descriptor.styles.isEmpty && set.descriptor.defaultStyle == nil)
        for file in [
            "generate.mtl", "CNames.mtl", "CTypes.mtl", "CIncludes.mtl", "CDocumentation.mtl", "Header.mtl",
            "EObjectHeader.mtl", "PackageHeader.mtl", "PackageSource.mtl", "ClassQueries.mtl", "ClassHeader.mtl",
            "ClassSource.mtl", "ClassDescriptor.mtl", "EnumDeclaration.mtl", "DataTypeDeclaration.mtl",
            "TypeMapping.ecore", "c-types.xmi",
        ] {
            #expect(
                FileManager.default.fileExists(atPath: set.directory.appendingPathComponent(file).path),
                "\(file) is missing")
        }
        #expect(set.mainModuleURL.lastPathComponent == "generate.mtl")
    }

    @Test("The C type table lists the built-in types, how they are stored and the reserved words")
    func cTypeTable() throws {
        let set = try TemplateSet.assemble(language: "c")
        defer { set.remove() }
        let table = try String(contentsOf: set.directory.appendingPathComponent("c-types.xmi"), encoding: .utf8)
        #expect(table.contains(#"language="c""#))
        for model in [
            "EString", "EBoolean", "EInt", "ELong", "EShort", "EByte", "EChar", "EDouble", "EFloat", "EBigInteger",
            "EBigDecimal", "EDate", "EJavaObject", "EByteArray", "EObject",
        ] {
            #expect(table.contains(#"modelType="\#(model)""#), "\(model) is not mapped")
        }
        for storage in ["scalar", "string", "bytes", "pointer"] {
            #expect(table.contains(#"storage="\#(storage)""#), "no mapping is stored as \(storage)")
        }
        for kind in ["keyword", "type", "member"] { #expect(table.contains(#"<reservedWords kind="\#(kind)""#)) }
        let metamodel = try String(
            contentsOf: set.directory.appendingPathComponent("TypeMapping.ecore"), encoding: .utf8)
        for feature in ["modelType", "targetType", "parameterType", "storage", "zeroValue", "module", "literalStyle", "words"] {
            #expect(metamodel.contains(#"name="\#(feature)""#), "\(feature) is not declared")
        }
    }

    @Test("The bundled C++ set is assembled with its modules and data")
    func bundledCppSet() throws {
        let set = try TemplateSet.assemble(language: "cpp")
        defer { set.remove() }
        #expect(set.descriptor.name == "cpp")
        #expect(set.descriptor.summary?.isEmpty == false)
        #expect(set.descriptor.mainModule == "generate")
        #expect(set.descriptor.mainTemplate == "generate")
        #expect(set.descriptor.fileCountTemplate == "fileCount")
        #expect(
            set.descriptor.dataModels == [.init(name: "types", metamodel: "TypeMapping.ecore", model: "cpp-types.xmi")])
        #expect(set.descriptor.layout.sourceRootSetting == "modelDirectory")
        #expect(!set.descriptor.layout.includeSourceRoot)
        #expect(set.descriptor.options.lineDelimiter == "\n")
        #expect(set.descriptor.styles.isEmpty && set.descriptor.defaultStyle == nil)
        for file in [
            "generate.mtl", "SupportHeader.mtl", "Class.mtl", "ClassQueries.mtl", "ClassFeature.mtl",
            "EnumClass.mtl", "DataTypeFile.mtl", "PackageClass.mtl", "FactoryClass.mtl", "Header.mtl",
            "CppNames.mtl", "CppTypes.mtl", "CppIncludes.mtl", "CppDocumentation.mtl",
            "TypeMapping.ecore", "cpp-types.xmi",
        ] {
            #expect(
                FileManager.default.fileExists(atPath: set.directory.appendingPathComponent(file).path),
                "\(file) is missing")
        }
        #expect(set.mainModuleURL.lastPathComponent == "generate.mtl")
    }

    @Test("The C++ type table lists the built-in types, how they are passed and the reserved words")
    func cppTypeTable() throws {
        let set = try TemplateSet.assemble(language: "cpp")
        defer { set.remove() }
        let table = try String(
            contentsOf: set.directory.appendingPathComponent("cpp-types.xmi"), encoding: .utf8)
        #expect(table.contains(#"language="cpp""#))
        for model in [
            "EString", "EBoolean", "EInt", "ELong", "EShort", "EByte", "EChar", "EDouble", "EFloat", "EBigInteger",
            "EBigDecimal", "EDate", "EJavaObject", "EByteArray", "EObject",
        ] {
            #expect(table.contains(#"modelType="\#(model)""#), "\(model) is not mapped")
        }
        for word in ["class", "namespace", "template", "new", "delete", "this", "virtual", "operator", "and", "not"] {
            #expect(table.contains(#"word="\#(word)" kind="keyword""#), "\(word) is not a keyword")
        }
        for word in ["EObject", "ClassInfo", "FILE", "size_t"] {
            #expect(table.contains(#"word="\#(word)" kind="type""#), "\(word) is not a type")
        }
        let metamodel = try String(
            contentsOf: set.directory.appendingPathComponent("TypeMapping.ecore"), encoding: .utf8)
        for feature in ["modelType", "targetType", "zeroValue", "module", "literalStyle", "byValue", "kind"] {
            #expect(metamodel.contains(#"name="\#(feature)""#), "\(feature) is not declared")
        }
    }

    @Test("The available languages include C, C++, Java and Swift")
    func availableLanguages() {
        #expect(TemplateSet.availableLanguages().contains("java"))
        #expect(TemplateSet.availableLanguages().contains("swift"))
        #expect(TemplateSet.availableLanguages().contains("c"))
        #expect(TemplateSet.availableLanguages().contains("cpp"))
        #expect(!TemplateSet.availableLanguages().contains("llvm"))
        #expect(TemplateSet.availableLanguages() == TemplateSet.availableLanguages().sorted())
    }

    @Test("Only Java offers code styles")
    func bundledCodeStyles() {
        #expect(TemplateSet.bundledCodeStyles().map(\.language) == ["java"])
    }

    @Test("An unknown language is reported with the known ones")
    func unknownLanguage() {
        #expect(throws: GenerationError.unknownLanguage("cobol", TemplateSet.availableLanguages())) {
            try TemplateSet.assemble(language: "cobol")
        }
    }

    @Test("A template path that is not a directory is reported")
    func invalidTemplatePath() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write("x", to: "file.txt")
        let path = scratch.url.appendingPathComponent("file.txt")
        #expect(throws: GenerationError.templatePathInvalid(path.path)) {
            try TemplateSet.assemble(language: "java", templatePaths: [path])
        }
        let missing = scratch.url.appendingPathComponent("missing")
        #expect(throws: GenerationError.templatePathInvalid(missing.path)) {
            try TemplateSet.assemble(language: "java", templatePaths: [missing])
        }
    }

    @Test("A file in a flat override directory replaces the bundled file")
    func flatOverride() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write("[comment replaced /]", to: "Header.mtl")
        let set = try TemplateSet.assemble(language: "java", templatePaths: [scratch.url])
        defer { set.remove() }
        let header = try String(contentsOf: set.directory.appendingPathComponent("Header.mtl"), encoding: .utf8)
        #expect(header == "[comment replaced /]")
        #expect(FileManager.default.fileExists(atPath: set.directory.appendingPathComponent("EnumClass.mtl").path))
    }

    @Test("A language directory inside an override directory is used")
    func nestedOverride() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write("nested", to: "java/Header.mtl")
        try scratch.write("not used", to: "other/Header.mtl")
        let set = try TemplateSet.assemble(language: "java", templatePaths: [scratch.url])
        defer { set.remove() }
        let header = try String(contentsOf: set.directory.appendingPathComponent("Header.mtl"), encoding: .utf8)
        #expect(header == "nested")
    }

    @Test("Later override directories take precedence over earlier ones")
    func overridePrecedence() throws {
        let first = try ScratchDirectory()
        let second = try ScratchDirectory()
        defer {
            first.remove()
            second.remove()
        }
        try first.write("first", to: "Header.mtl")
        try first.write("only first", to: "Extra.mtl")
        try second.write("second", to: "Header.mtl")
        let set = try TemplateSet.assemble(language: "java", templatePaths: [first.url, second.url])
        defer { set.remove() }
        #expect(try String(contentsOf: set.directory.appendingPathComponent("Header.mtl"), encoding: .utf8) == "second")
        #expect(try String(contentsOf: set.directory.appendingPathComponent("Extra.mtl"), encoding: .utf8) == "only first")
    }

    @Test("A template set that exists only in an override directory is found")
    func languageFromOverride() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write(
            #"{"name": "notes", "mainModule": "main", "mainTemplate": "main"}"#,
            to: "notes/templateset.json")
        try scratch.write("[module main('http://www.eclipse.org/emf/2002/GenModel')/]", to: "notes/main.mtl")
        #expect(TemplateSet.availableLanguages(templatePaths: [scratch.url]).contains("notes"))
        let set = try TemplateSet.assemble(language: "notes", templatePaths: [scratch.url])
        defer { set.remove() }
        #expect(set.descriptor.dataModels.isEmpty)
        #expect(set.descriptor.layout == TemplateSetDescriptor.Layout())
        #expect(set.mainModuleURL.lastPathComponent == "main.mtl")
    }

    @Test("A set without a descriptor or without its main module is invalid")
    func invalidSets() throws {
        let scratch = try ScratchDirectory()
        defer { scratch.remove() }
        try scratch.write(
            #"{"name": "broken", "mainModule": "missing", "mainTemplate": "main"}"#,
            to: "broken/templateset.json")
        #expect(
            throws: GenerationError.templateSetInvalid("broken", "the main module 'missing' is missing")
        ) {
            try TemplateSet.assemble(language: "broken", templatePaths: [scratch.url])
        }
        try scratch.write("{ not json", to: "garbled/templateset.json")
        #expect(throws: GenerationError.self) {
            try TemplateSet.assemble(language: "garbled", templatePaths: [scratch.url])
        }
    }

    @Test("The descriptor reads optional members with defaults")
    func descriptorDefaults() throws {
        let minimal = #"{"name": "x", "mainModule": "m", "mainTemplate": "t"}"#
        let descriptor = try JSONDecoder().decode(TemplateSetDescriptor.self, from: Data(minimal.utf8))
        #expect(descriptor.summary == nil)
        #expect(descriptor.fileCountTemplate == nil)
        #expect(descriptor.dataModels.isEmpty)
        #expect(descriptor.layout.sourceRootSetting == nil)
        #expect(!descriptor.layout.includeSourceRoot)
        #expect(descriptor.options.lineDelimiter == nil)

        let full = """
            {"name": "x", "summary": "s", "mainModule": "m", "mainTemplate": "t",
             "fileCountTemplate": "c",
             "dataModels": [{"name": "d", "metamodel": "d.ecore", "model": "d.xmi"}],
             "layout": {"sourceRootSetting": "dir", "includeSourceRoot": true},
             "options": {"lineDelimiter": "\\r\\n"}}
            """
        let decoded = try JSONDecoder().decode(TemplateSetDescriptor.self, from: Data(full.utf8))
        #expect(decoded.summary == "s")
        #expect(decoded.fileCountTemplate == "c")
        #expect(decoded.dataModels == [.init(name: "d", metamodel: "d.ecore", model: "d.xmi")])
        #expect(decoded.layout == .init(sourceRootSetting: "dir", includeSourceRoot: true))
        #expect(decoded.options.lineDelimiter == "\r\n")
    }

    @Test("Progress reports compute their completed share")
    func progressFraction() {
        #expect(GenerationProgressUpdate(message: "m").fraction == nil)
        #expect(GenerationProgressUpdate(message: "m", completed: 1, total: 4).fraction == 0.25)
        #expect(GenerationProgressUpdate(message: "m", completed: 9, total: 4).fraction == 1)
        #expect(GenerationProgressUpdate(message: "m", completed: 0, total: 0).fraction == nil)
    }

    @Test("Generation options derive the redirection pattern")
    func redirectionPattern() {
        #expect(GenerationOptions().effectiveRedirectionPattern == nil)
        #expect(GenerationOptions(diff: true).effectiveRedirectionPattern == ".{0}.new")
        #expect(GenerationOptions(diff: true, redirectionPattern: "{0}.x").effectiveRedirectionPattern == "{0}.x")
    }
}
