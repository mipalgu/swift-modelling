import Foundation
import Testing

@testable import ModellingGenerators

/// A fixture whose generator model is adjusted, with the files that the Java template set must write for it
/// when the output location includes the source directory.
struct JavaProjectCase: Sendable, CustomTestStringConvertible {
    /// The name of the case, which is the folder of its expectations.
    let name: String

    /// The name of the fixture directory.
    let fixture: String

    /// The file stem of the source model.
    let stem: String

    /// The import options.
    let options: GenModelImportOptions

    /// Replacements applied to the text of the generator model, as pairs of old and new text.
    let edits: [(String, String)]

    /// The expected files, relative to the output directory.
    let files: [String]

    var testDescription: String { name }

    /// The root of the expectations in the bundled fixtures.
    static let expectationFolder = "expected-java-project"

    /// The names of the project files that a model with plugin support writes into its project directory.
    static let projectFileNames: Set<String> = ["build.properties", "MANIFEST.MF", "plugin.properties", "plugin.xml"]

    /// The project files that every case with plugin support writes.
    static func projectFiles(_ project: String) -> [String] {
        ["build.properties", "META-INF/MANIFEST.MF", "plugin.properties", "plugin.xml"].map { "\(project)/\($0)" }
    }

    /// Every case with committed expectations.
    static let all: [JavaProjectCase] = [
        JavaProjectCase(
            name: "library-none", fixture: "library", stem: "library",
            options: GenModelImportOptions(basePackage: "org.example", copyright: "Copyright 2026 Example Pty Ltd"),
            edits: [],
            files: projectFiles("library") + ["library/src/org/example/library/BookCategory.java"]),
        JavaProjectCase(
            name: "library-xmi", fixture: "library", stem: "library",
            options: GenModelImportOptions(basePackage: "org.example", copyright: "Copyright 2026 Example Pty Ltd"),
            edits: [
                ("<genPackages ", "<genPackages resource=\"XMI\" contentTypeIdentifier=\"lib\" fileExtensions=\"lib, library\" "),
                ("modelName=", "modelPluginClass=\"org.example.LibraryPlugin\" oSGiCompatible=\"true\" modelName="),
            ],
            files: projectFiles("library") + [
                "library/src/org/example/LibraryPlugin.java",
                "library/src/org/example/library/BookCategory.java",
                "library/src/org/example/library/util/LibraryResourceFactoryImpl.java",
                "library/src/org/example/library/util/LibraryResourceImpl.java",
            ]),
        JavaProjectCase(
            name: "library-descriptor", fixture: "library", stem: "library",
            options: GenModelImportOptions(basePackage: "org.example"),
            edits: [
                ("<genPackages ", "<genPackages resource=\"Basic\" "),
                ("modelName=", "bundleManifest=\"false\" runtimeJar=\"true\" pluginKey=\"library\" modelName="),
            ],
            files: [
                "library/build.properties", "library/plugin.properties", "library/plugin.xml",
                "library/src/org/example/library/BookCategory.java",
                "library/src/org/example/library/util/LibraryResourceFactoryImpl.java",
                "library/src/org/example/library/util/LibraryResourceImpl.java",
            ]),
        JavaProjectCase(
            name: "xml-namespace", fixture: "xmlmodel", stem: "orders",
            options: GenModelImportOptions(basePackage: "org.example"),
            edits: [("modelName=", "pluginKey=\"xmlmodel\" modelName=")],
            files: projectFiles("xmlmodel") + [
                "xmlmodel/src/org/example/orders/util/OrdersResourceFactoryImpl.java",
                "xmlmodel/src/org/example/orders/util/OrdersResourceImpl.java",
                "xmlmodel/src/org/example/orders/util/OrdersXMLProcessor.java",
            ]),
        JavaProjectCase(
            name: "xml-no-namespace", fixture: "xmlnamespaceless", stem: "plain",
            options: GenModelImportOptions(basePackage: "org.example"),
            edits: [("modelName=", "modelPluginClass=\"org.example.PlainPlugin\" modelName=")],
            files: projectFiles("xmlnamespaceless") + [
                "xmlnamespaceless/src/org/example/PlainPlugin.java",
                "xmlnamespaceless/src/org/example/plain/util/PlainResourceFactoryImpl.java",
                "xmlnamespaceless/src/org/example/plain/util/PlainResourceImpl.java",
                "xmlnamespaceless/src/org/example/plain/util/PlainXMLProcessor.java",
            ]),
        JavaProjectCase(
            name: "enumerations", fixture: "enumerations", stem: "enumerations",
            options: GenModelImportOptions(basePackage: "org.example.traffic"),
            edits: [],
            files: projectFiles("enumerations") + [
                "enumerations/src/org/example/traffic/enumerations/Colour.java",
                "enumerations/src/org/example/traffic/enumerations/Empty.java",
                "enumerations/src/org/example/traffic/enumerations/Mode.java",
            ]),
        JavaProjectCase(
            name: "nested", fixture: "nested", stem: "company",
            options: GenModelImportOptions(
                basePackage: "org.example.company", packagePrefixes: ["projects": "Proj"]),
            edits: [("<genPackages ", "<genPackages resource=\"XMI\" ")],
            files: projectFiles("nested") + [
                "nested/src/org/example/company/company/projects/Status.java",
                "nested/src/org/example/company/company/util/CompanyResourceFactoryImpl.java",
                "nested/src/org/example/company/company/util/CompanyResourceImpl.java",
            ]),
        JavaProjectCase(
            name: "documented", fixture: "documented", stem: "documented",
            options: GenModelImportOptions(basePackage: "org.example.alarm"),
            edits: [],
            files: projectFiles("documented") + ["documented/src/org/example/alarm/documented/Level.java"]),
    ]

    /// Imports the fixture, applies the edits and generates with the source directory in the output location.
    @MainActor
    func generate(options extra: GenerationOptions = GenerationOptions(includeSourceRoot: true)) async throws
        -> GeneratedProject
    {
        let generated = try await GeneratedProject.make(fixture, stem: stem, options: options)
        var text = try String(contentsOf: generated.genModel, encoding: .utf8)
        for (old, new) in edits { text = text.replacingOccurrences(of: old, with: new) }
        try text.write(to: generated.genModel, atomically: true, encoding: .utf8)
        try await generated.generate(options: extra)
        return generated
    }
}

@Suite("Java resource and project files")
struct JavaProjectFilesTests {
    @Test("Generated files match the reviewed expectations", arguments: JavaProjectCase.all)
    @MainActor
    func goldenFiles(_ golden: JavaProjectCase) async throws {
        let generated = try await golden.generate()
        defer { generated.remove() }
        if GoldenFiles.isRecording {
            for path in generated.generatedPaths() {
                try GoldenFiles.check(
                    try generated.text(path),
                    against: "\(golden.fixture)/\(JavaProjectCase.expectationFolder)/\(golden.name)/\(path)")
            }
            return
        }
        let missing = Set(golden.files).subtracting(generated.generatedPaths())
        #expect(missing.isEmpty, "missing generated files: \(missing.sorted())")
        for path in golden.files {
            try GoldenFiles.check(
                try generated.text(path),
                against: "\(golden.fixture)/\(JavaProjectCase.expectationFolder)/\(golden.name)/\(path)", path)
        }
    }

    @Test("Project files are written only when the output includes the source directory")
    @MainActor
    func noProjectFilesWithoutSourceRoot() async throws {
        let golden = JavaProjectCase.all[1]
        let generated = try await golden.generate(options: GenerationOptions())
        defer { generated.remove() }
        let paths = generated.generatedPaths()
        let expected = [
            "org/example/LibraryPlugin.java", "org/example/library/BookCategory.java",
            "org/example/library/util/LibraryResourceFactoryImpl.java",
            "org/example/library/util/LibraryResourceImpl.java",
        ]
        #expect(Set(paths).isSuperset(of: expected))
        #expect(paths.allSatisfy { !JavaProjectCase.projectFileNames.contains(URL(fileURLWithPath: $0).lastPathComponent) })
    }

    @Test("A model without plugin identifier writes no project files")
    @MainActor
    func noPluginSupport() async throws {
        var golden = JavaProjectCase.all[0]
        golden = JavaProjectCase(
            name: golden.name, fixture: golden.fixture, stem: golden.stem, options: golden.options,
            edits: [("modelPluginID=\"library\"", "")], files: [])
        let generated = try await golden.generate()
        defer { generated.remove() }
        let paths = generated.generatedPaths()
        #expect(paths.contains("library/src/org/example/library/BookCategory.java"))
        #expect(paths.allSatisfy { !JavaProjectCase.projectFileNames.contains(URL(fileURLWithPath: $0).lastPathComponent) })
    }

    @Test("Existing project files are kept, and forcing the overwrite replaces them")
    @MainActor
    func existingFiles() async throws {
        let golden = JavaProjectCase.all[0]
        let generated = try await golden.generate()
        defer { generated.remove() }
        let path = "library/plugin.xml"
        try "kept".write(to: generated.file(path), atomically: true, encoding: .utf8)
        try await generated.generate(options: GenerationOptions(includeSourceRoot: true))
        #expect(try generated.text(path) == "kept")
        try await generated.generate(options: GenerationOptions(forceOverwrite: true, includeSourceRoot: true))
        #expect(try generated.text(path) != "kept")
    }

    @Test("Existing properties files are kept unless forced, and the build properties follow the plugin descriptor")
    @MainActor
    func propertiesFiles() async throws {
        let golden = JavaProjectCase.all[0]
        let generated = try await golden.generate()
        defer { generated.remove() }
        let plugin = "library/plugin.properties"
        let build = "library/build.properties"
        let descriptor = "library/plugin.xml"
        let regenerate = { (force: Bool) in
            try await generated.generate(options: GenerationOptions(forceOverwrite: force, includeSourceRoot: true))
        }

        try "kept plugin".write(to: generated.file(plugin), atomically: true, encoding: .utf8)
        try "kept build".write(to: generated.file(build), atomically: true, encoding: .utf8)
        try await regenerate(false)
        #expect(try generated.text(plugin) == "kept plugin")
        #expect(try generated.text(build) == "kept build", "the build properties stay once a plugin descriptor exists")

        try FileManager.default.removeItem(at: generated.file(descriptor))
        try await regenerate(false)
        #expect(try generated.text(build) != "kept build", "the build properties are replaced without a plugin descriptor")
        #expect(try generated.text(plugin) == "kept plugin")

        try "kept build".write(to: generated.file(build), atomically: true, encoding: .utf8)
        try await regenerate(true)
        #expect(try generated.text(plugin) != "kept plugin")
        #expect(try generated.text(build) != "kept build")
    }

    @Test("Properties files are written in ISO-8859-1 with escapes beyond it, other project files in UTF-8")
    @MainActor
    func propertiesEncoding() async throws {
        let golden = JavaProjectCase(
            name: "encoding", fixture: "library", stem: "library",
            options: GenModelImportOptions(basePackage: "org.example", copyright: "Copyright \u{A9} 2026 Zo\u{EB} \u{65E5}\u{672C}"),
            edits: [], files: [])
        let generated = try await golden.generate()
        defer { generated.remove() }
        for name in ["library/plugin.properties", "library/build.properties"] {
            let bytes = try Data(contentsOf: generated.file(name))
            let latin1 = try #require(String(data: bytes, encoding: .isoLatin1))
            #expect(latin1.hasPrefix("# Copyright \u{A9} 2026 Zo\u{EB} \\u65e5\\u672c\n"), "\(name)")
            #expect(String(data: bytes, encoding: .utf8) == nil, "\(name) is not UTF-8")
        }
    }

    @Test("An edited Java file of the project is merged with the generated text")
    @MainActor
    func javaIsMerged() async throws {
        let golden = JavaProjectCase.all[1]
        let generated = try await golden.generate()
        defer { generated.remove() }
        let java = "library/src/org/example/LibraryPlugin.java"
        var edited = try generated.text(java).trimmingCharacters(in: .whitespacesAndNewlines)
        edited.removeLast()
        edited += "\n  public void keptByHand() {}\n}\n"
        try edited.write(to: generated.file(java), atomically: true, encoding: .utf8)
        try await generated.generate(options: GenerationOptions(includeSourceRoot: true))
        #expect(try generated.text(java).contains("keptByHand"), "an edited Java file is merged")
    }

    @Test("The result counts the project files")
    @MainActor
    func counts() async throws {
        let golden = JavaProjectCase.all[1]
        let generated = try await golden.generate()
        defer { generated.remove() }
        let collector = ProgressCollector()
        try await generated.generate(
            options: GenerationOptions(forceOverwrite: true, includeSourceRoot: true),
            progress: { collector.add($0) })
        let total = collector.updates.compactMap(\.total).last
        #expect(total == generated.generatedPaths().count)
        #expect(total ?? 0 >= golden.files.count)
    }
}
