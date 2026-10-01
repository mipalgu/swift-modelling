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

    @Test("The available languages include Java")
    func availableLanguages() {
        #expect(TemplateSet.availableLanguages().contains("java"))
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
