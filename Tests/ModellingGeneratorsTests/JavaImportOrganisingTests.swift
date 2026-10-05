import Foundation
import Testing

@testable import ModellingGenerators

/// A fixture whose factory implementation, switch, adapter factory and validator import the interface package.
struct ImportOrganisingCase: Sendable, CustomTestStringConvertible {
    /// The name of the fixture directory.
    let fixture: String

    /// The file stem of the source model.
    let stem: String

    /// The base package of the generated code, or `nil` for none.
    let basePackage: String?

    /// The package that holds the interfaces of the model.
    let interfacePackage: String

    /// The prefix of the model, which names the package interface and the utility classes.
    let prefix: String

    /// Whether the model has enumerations.
    let hasEnumerations: Bool

    /// Whether the model has constraints, and therefore a validator.
    var hasValidator = false

    var testDescription: String { fixture }

    /// The import options, with or without organised imports.
    func options(organising: Bool) -> GenModelImportOptions {
        GenModelImportOptions(basePackage: basePackage, importOrganizing: organising)
    }

    /// The directory of the files below the generated source root.
    var directory: String { interfacePackage.replacingOccurrences(of: ".", with: "/") }

    /// The factory implementation, switch, adapter factory and, if there is one, validator.
    var files: [String] {
        var paths = [
            "\(directory)/impl/\(prefix)FactoryImpl.java", "\(directory)/util/\(prefix)Switch.java",
            "\(directory)/util/\(prefix)AdapterFactory.java",
        ]
        if hasValidator { paths.append("\(directory)/util/\(prefix)Validator.java") }
        return paths
    }

    /// The fixtures with and without enumerations.
    static let all: [ImportOrganisingCase] = [
        ImportOrganisingCase(
            fixture: "families", stem: "families", basePackage: "org.example.families",
            interfacePackage: "org.example.families.Families", prefix: "Families", hasEnumerations: false),
        ImportOrganisingCase(
            fixture: "organisation", stem: "organisation", basePackage: "org.example.organisation",
            interfacePackage: "org.example.organisation.organisation", prefix: "Organisation",
            hasEnumerations: false),
        ImportOrganisingCase(
            fixture: "ecoretypes", stem: "bridge", basePackage: "org.example.bridge",
            interfacePackage: "org.example.bridge.bridge", prefix: "Bridge", hasEnumerations: false),
        ImportOrganisingCase(
            fixture: "maps", stem: "maps", basePackage: nil, interfacePackage: "maps", prefix: "Maps",
            hasEnumerations: false),
        ImportOrganisingCase(
            fixture: "constraints", stem: "constraints", basePackage: "org.example.bank",
            interfacePackage: "org.example.bank.bank", prefix: "Bank", hasEnumerations: false,
            hasValidator: true),
        ImportOrganisingCase(
            fixture: "library", stem: "library", basePackage: "org.example", interfacePackage: "org.example.library",
            prefix: "Library", hasEnumerations: true),
        ImportOrganisingCase(
            fixture: "enumerations", stem: "enumerations", basePackage: "org.example.traffic",
            interfacePackage: "org.example.traffic.enumerations", prefix: "Enumerations", hasEnumerations: true),
    ]
}

@Suite("Java imports and the importOrganizing setting")
struct JavaImportOrganisingTests {
    /// The import statements of a file.
    private static func imports(_ text: String) -> [String] {
        text.components(separatedBy: "\n").filter { $0.hasPrefix("import ") }
    }

    @Test(
        "Without organised imports the interface package is imported as a whole, whether or not the model has enumerations",
        arguments: ImportOrganisingCase.all)
    @MainActor
    func wildcardImports(_ golden: ImportOrganisingCase) async throws {
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options(organising: false))
        defer { generated.remove() }
        try await generated.generate()
        let wildcard = "import \(golden.interfacePackage).*;"
        for path in golden.files {
            let text = try generated.text(path)
            #expect(text.contains(wildcard), "\(path) lacks \(wildcard)")
            #expect(
                !Self.imports(text).contains("import \(golden.interfacePackage).\(golden.prefix)Package;"),
                "\(path) imports the package interface explicitly")
        }
    }

    @Test(
        "With organised imports every type is imported by name instead of the interface package",
        arguments: ImportOrganisingCase.all)
    @MainActor
    func explicitImports(_ golden: ImportOrganisingCase) async throws {
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options(organising: true))
        defer { generated.remove() }
        try await generated.generate()
        for path in golden.files {
            let text = try generated.text(path)
            #expect(!text.contains("\(golden.interfacePackage).*;"), "\(path) keeps the wildcard import")
            #expect(
                Self.imports(text).contains("import \(golden.interfacePackage).\(golden.prefix)Package;"),
                "\(path) lacks the explicit import of the package interface")
        }
    }

    @Test("Organised imports are sorted within their groups")
    @MainActor
    func organisedImportsAreSorted() async throws {
        let golden = ImportOrganisingCase.all[5]
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options(organising: true))
        defer { generated.remove() }
        try await generated.generate()
        for path in golden.files {
            let block = try generated.text(path).components(separatedBy: "\n")
                .drop { !$0.hasPrefix("import ") }.prefix { $0.hasPrefix("import ") || $0.isEmpty }
            let groups = block.split(separator: "", omittingEmptySubsequences: true)
            for group in groups {
                #expect(Array(group) == group.sorted(), "\(path) has an unsorted group")
            }
            #expect(groups.count <= 2, "\(path) groups its imports by java and org only")
        }
    }

    @Test("Imports are grouped by top-level package: java, javax, org, com, then any other")
    @MainActor
    func organisedGroups() async throws {
        let generated = try await GeneratedProject.make(
            "families", stem: "families", options: ImportOrganisingCase.all[0].options(organising: true))
        defer { generated.remove() }
        let body =
            "[collect ('imports', 'org.example.Unit')/][collect ('imports', Sequence{'org.b.B', 'zed.Z', 'com.c.C', 'javax.x.X', 'java.util.List', 'org.a.A', 'java.io.File', 'org.example.Sibling', 'acme.Q'})/][emit ('imports') once][organisedImportBlock(items)/][/emit]"
        let text = try await TemplateHarness(generated: generated).run(body)
        #expect(
            text
                == "import java.io.File;\nimport java.util.List;\n\nimport javax.x.X;\n\nimport org.a.A;\nimport org.b.B;\n\nimport com.c.C;\n\nimport acme.Q;\nimport zed.Z;\n"
        )
    }
}
