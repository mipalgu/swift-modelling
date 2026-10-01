import Foundation
import Synchronization
import Testing

@testable import ModellingGenerators

/// A fixture together with the files that the Java template set must generate for it.
struct JavaGoldenCase: Sendable, CustomTestStringConvertible {
    /// The name of the fixture directory.
    let fixture: String

    /// The file stem of the source model.
    let stem: String

    /// The import options that the expectations were reviewed for.
    let options: GenModelImportOptions

    /// The expected enumeration files, relative to the generated source root.
    let files: [String]

    /// The expected package interface and implementation files, and serialised packages.
    var packageFiles: [String] = []

    /// The expected factory interface and implementation files.
    var factoryFiles: [String] = []

    /// All expected files, sorted.
    var allFiles: [String] { (files + packageFiles + factoryFiles).sorted() }

    var testDescription: String { fixture }

    /// Every fixture with committed Java expectations.
    static let all: [JavaGoldenCase] = [
        JavaGoldenCase(
            fixture: "library", stem: "library",
            options: GenModelImportOptions(
                basePackage: "org.example", copyright: "Copyright 2026 Example Pty Ltd"),
            files: ["org/example/library/BookCategory.java"],
            packageFiles: ["org/example/library/LibraryPackage.java", "org/example/library/impl/LibraryPackageImpl.java"],
            factoryFiles: ["org/example/library/LibraryFactory.java", "org/example/library/impl/LibraryFactoryImpl.java"]),
        JavaGoldenCase(
            fixture: "nested", stem: "company",
            options: GenModelImportOptions(
                basePackage: "org.example.company", packagePrefixes: ["projects": "Proj"]),
            files: ["org/example/company/company/projects/Status.java"],
            packageFiles: [
                "org/example/company/company/CompanyPackage.java",
                "org/example/company/company/impl/CompanyPackageImpl.java",
                "org/example/company/company/people/PeoplePackage.java",
                "org/example/company/company/people/impl/PeoplePackageImpl.java",
                "org/example/company/company/projects/ProjPackage.java",
                "org/example/company/company/projects/impl/ProjPackageImpl.java",
                "org/example/company/company/projects/archive/ArchivePackage.java",
                "org/example/company/company/projects/archive/impl/ArchivePackageImpl.java",
            ],
            factoryFiles: [
                "org/example/company/company/CompanyFactory.java",
                "org/example/company/company/impl/CompanyFactoryImpl.java",
                "org/example/company/company/people/PeopleFactory.java",
                "org/example/company/company/people/impl/PeopleFactoryImpl.java",
                "org/example/company/company/projects/ProjFactory.java",
                "org/example/company/company/projects/archive/ArchiveFactory.java",
                "org/example/company/company/projects/archive/impl/ArchiveFactoryImpl.java",
                "org/example/company/company/projects/impl/ProjFactoryImpl.java",
            ]),
        JavaGoldenCase(
            fixture: "enumerations", stem: "enumerations",
            options: GenModelImportOptions(basePackage: "org.example.traffic"),
            files: [
                "org/example/traffic/enumerations/Colour.java",
                "org/example/traffic/enumerations/Empty.java",
                "org/example/traffic/enumerations/Mode.java",
            ],
            packageFiles: [
                "org/example/traffic/enumerations/EnumerationsPackage.java",
                "org/example/traffic/enumerations/impl/EnumerationsPackageImpl.java",
            ],
            factoryFiles: [
                "org/example/traffic/enumerations/EnumerationsFactory.java",
                "org/example/traffic/enumerations/impl/EnumerationsFactoryImpl.java",
            ]),
        JavaGoldenCase(
            fixture: "documented", stem: "documented",
            options: GenModelImportOptions(basePackage: "org.example.alarm"),
            files: ["org/example/alarm/documented/Level.java"],
            packageFiles: [
                "org/example/alarm/documented/DocumentedPackage.java",
                "org/example/alarm/documented/impl/DocumentedPackageImpl.java",
            ],
            factoryFiles: [
                "org/example/alarm/documented/DocumentedFactory.java",
                "org/example/alarm/documented/impl/DocumentedFactoryImpl.java",
            ]),
        JavaGoldenCase(
            fixture: "datatypes", stem: "datatypes",
            options: GenModelImportOptions(basePackage: "org.example.types"),
            files: ["org/example/types/datatypes/Colour.java"],
            factoryFiles: [
                "org/example/types/datatypes/DatatypesFactory.java",
                "org/example/types/datatypes/impl/DatatypesFactoryImpl.java",
            ]),
        JavaGoldenCase(
            fixture: "families", stem: "families",
            options: GenModelImportOptions(basePackage: "org.example.families"),
            files: [],
            packageFiles: [
                "org/example/families/Families/FamiliesPackage.java",
                "org/example/families/Families/impl/FamiliesPackageImpl.java",
            ],
            factoryFiles: [
                "org/example/families/Families/FamiliesFactory.java",
                "org/example/families/Families/impl/FamiliesFactoryImpl.java",
            ]),
        JavaGoldenCase(
            fixture: "organisation", stem: "organisation",
            options: GenModelImportOptions(basePackage: "org.example.organisation"),
            files: [],
            packageFiles: [
                "org/example/organisation/organisation/OrganisationPackage.java",
                "org/example/organisation/organisation/impl/OrganisationPackageImpl.java",
            ],
            factoryFiles: [
                "org/example/organisation/organisation/OrganisationFactory.java",
                "org/example/organisation/organisation/impl/OrganisationFactoryImpl.java",
            ]),
        JavaGoldenCase(
            fixture: "ecoretypes", stem: "bridge",
            options: GenModelImportOptions(basePackage: "org.example.bridge"),
            files: [],
            packageFiles: [
                "org/example/bridge/bridge/BridgePackage.java",
                "org/example/bridge/bridge/impl/BridgePackageImpl.java",
            ],
            factoryFiles: [
                "org/example/bridge/bridge/BridgeFactory.java",
                "org/example/bridge/bridge/impl/BridgeFactoryImpl.java",
            ]),
    ]
}

@Suite("Java generation")
struct JavaGenerationTests {
    @Test("Generated enumerations match the reviewed expectations", arguments: JavaGoldenCase.all)
    @MainActor
    func goldenFiles(_ golden: JavaGoldenCase) async throws {
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options)
        defer { generated.remove() }
        try await generated.generate()

        let missing = Set(golden.allFiles).subtracting(generated.generatedPaths())
        #expect(missing.isEmpty, "missing generated files: \(missing.sorted())")
        let project = generated.project
        for path in golden.allFiles {
            let expected = try String(contentsOf: project.javaExpectation(path), encoding: .utf8)
            let actual = try generated.text(path)
            #expect(actual == expected, "\(path) differs from its expectation")
        }
    }

    @Test(
        "Every fixture generates without error",
        arguments: JavaGoldenCase.all.map(\.fixture))
    @MainActor
    func everyFixtureGenerates(_ fixture: String) async throws {
        let stem = ["nested": "company", "ecoretypes": "bridge"][fixture] ?? fixture
        let generated = try await GeneratedProject.make(fixture, stem: stem)
        defer { generated.remove() }
        let result = try await generated.generate()
        #expect(result.files.count == generated.generatedPaths().count)
        #expect(result.packageCount >= 1)
    }

    @Test("Generating twice yields identical files")
    @MainActor
    func determinism() async throws {
        let generated = try await GeneratedProject.make(
            "enumerations", stem: "enumerations",
            options: GenModelImportOptions(basePackage: "org.example.traffic"))
        defer { generated.remove() }
        try await generated.generate()
        let first = try generated.generatedPaths().map { try generated.text($0) }
        try FileManager.default.removeItem(at: generated.output)
        try await generated.generate()
        let second = try generated.generatedPaths().map { try generated.text($0) }
        #expect(first == second)
        #expect(!first.isEmpty)
    }

    @Test("The result lists the files in the order they were written")
    @MainActor
    func resultListsFiles() async throws {
        let generated = try await GeneratedProject.make(
            "enumerations", stem: "enumerations",
            options: GenModelImportOptions(basePackage: "org.example.traffic"))
        defer { generated.remove() }
        let result = try await generated.generate()
        #expect(result.language == "java")
        #expect(result.packageCount == 1)
        let names = result.files.map(\.lastPathComponent)
        let expectedOrder = [
            "EnumerationsPackage.java", "EnumerationsPackageImpl.java", "EnumerationsFactory.java",
            "EnumerationsFactoryImpl.java", "Colour.java", "Mode.java", "Empty.java",
        ]
        #expect(names.isSubsequence(containing: expectedOrder), "unexpected file order: \(names)")
        #expect(result.outputDirectory.path == generated.output.standardizedFileURL.path)
    }

    @Test("The source directory of the generator model can be part of the layout")
    @MainActor
    func sourceRootLayout() async throws {
        let generated = try await GeneratedProject.make(
            "library", stem: "library", options: GenModelImportOptions(basePackage: "org.example"))
        defer { generated.remove() }
        let result = try await generated.generate(options: GenerationOptions(includeSourceRoot: true))
        let expected = (JavaGoldenCase.all.first { $0.fixture == "library" }?.allFiles ?? []).map { "library/src/" + $0 }
        #expect(!expected.isEmpty)
        #expect(Set(generated.generatedPaths()).isSuperset(of: expected))
        #expect(result.outputDirectory.lastPathComponent == "src")
    }

    @Test("Progress reports count the files and know the total")
    @MainActor
    func progressCounts() async throws {
        let generated = try await GeneratedProject.make(
            "enumerations", stem: "enumerations",
            options: GenModelImportOptions(basePackage: "org.example.traffic"))
        defer { generated.remove() }
        let collector = ProgressCollector()
        try await generated.generate(progress: { collector.add($0) })
        let updates = collector.updates
        let fileUpdates = updates.filter { $0.message.hasPrefix("Generated ") }
        #expect(fileUpdates.map(\.completed) == Array(1...fileUpdates.count))
        #expect(fileUpdates.count >= 5)
        #expect(fileUpdates.allSatisfy { $0.total == fileUpdates.count })
        #expect(fileUpdates.last?.fraction == 1)
        #expect(updates.last?.message == "Done")
        #expect(updates.first?.fraction == nil)
    }
}

extension Array where Element: Equatable {
    /// Whether the given elements all occur in this array, in the given order, possibly with others between them.
    func isSubsequence(containing expected: [Element]) -> Bool {
        var remaining = expected[...]
        for element in self where element == remaining.first {
            remaining = remaining.dropFirst()
        }
        return remaining.isEmpty
    }
}

/// Collects progress reports from a generation run.
final class ProgressCollector: Sendable {
    private let storage = Mutex<[GenerationProgressUpdate]>([])

    /// The reports received so far.
    var updates: [GenerationProgressUpdate] { storage.withLock { $0 } }

    /// Records a report.
    func add(_ update: GenerationProgressUpdate) {
        storage.withLock { $0.append(update) }
    }
}
