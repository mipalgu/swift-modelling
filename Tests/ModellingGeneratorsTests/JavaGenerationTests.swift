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

    /// The expected files, relative to the generated source root.
    let files: [String]

    var testDescription: String { fixture }

    /// Every fixture with committed Java expectations.
    static let all: [JavaGoldenCase] = [
        JavaGoldenCase(
            fixture: "library", stem: "library",
            options: GenModelImportOptions(
                basePackage: "org.example", copyright: "Copyright 2026 Example Pty Ltd"),
            files: [
                "org/example/library/Book.java",
                "org/example/library/BookCategory.java",
                "org/example/library/Lendable.java",
                "org/example/library/Library.java",
                "org/example/library/Named.java",
                "org/example/library/Writer.java",
                "org/example/library/impl/BookImpl.java",
                "org/example/library/impl/LibraryImpl.java",
                "org/example/library/impl/NamedImpl.java",
                "org/example/library/impl/WriterImpl.java",
            ]),
        JavaGoldenCase(
            fixture: "nested", stem: "company",
            options: GenModelImportOptions(
                basePackage: "org.example.company", packagePrefixes: ["projects": "Proj"]),
            files: [
                "org/example/company/company/Company.java",
                "org/example/company/company/impl/CompanyImpl.java",
                "org/example/company/company/people/Employee.java",
                "org/example/company/company/people/Person.java",
                "org/example/company/company/people/impl/EmployeeImpl.java",
                "org/example/company/company/people/impl/PersonImpl.java",
                "org/example/company/company/projects/Project.java",
                "org/example/company/company/projects/Status.java",
                "org/example/company/company/projects/archive/Record.java",
                "org/example/company/company/projects/archive/impl/RecordImpl.java",
                "org/example/company/company/projects/impl/ProjectImpl.java",
            ]),
        JavaGoldenCase(
            fixture: "enumerations", stem: "enumerations",
            options: GenModelImportOptions(basePackage: "org.example.traffic"),
            files: [
                "org/example/traffic/enumerations/Colour.java",
                "org/example/traffic/enumerations/Empty.java",
                "org/example/traffic/enumerations/Light.java",
                "org/example/traffic/enumerations/Mode.java",
                "org/example/traffic/enumerations/impl/LightImpl.java",
            ]),
        JavaGoldenCase(
            fixture: "classes", stem: "classes",
            options: GenModelImportOptions(basePackage: "org.example.shapes"),
            files: [
                "org/example/shapes/classes/Canvas.java",
                "org/example/shapes/classes/Circle.java",
                "org/example/shapes/classes/Colour.java",
                "org/example/shapes/classes/Named.java",
                "org/example/shapes/classes/Shape.java",
                "org/example/shapes/classes/impl/CanvasImpl.java",
                "org/example/shapes/classes/impl/CircleImpl.java",
                "org/example/shapes/classes/impl/ShapeImpl.java",
            ]),
        JavaGoldenCase(
            fixture: "documented", stem: "documented",
            options: GenModelImportOptions(basePackage: "org.example.alarm"),
            files: [
                "org/example/alarm/documented/Level.java",
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

        #expect(generated.generatedPaths() == golden.files.sorted())
        let project = generated.project
        for path in golden.files {
            let expected = try String(contentsOf: project.javaExpectation(path), encoding: .utf8)
            let actual = try generated.text(path)
            #expect(actual == expected, "\(path) differs from its expectation")
        }
    }

    @Test(
        "Every fixture generates without error",
        arguments: JavaGoldenCase.all.map(\.fixture) + ["families", "organisation", "ecoretypes"])
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
        #expect(result.files.map(\.lastPathComponent) == ["Light.java", "LightImpl.java", "Colour.java", "Mode.java", "Empty.java"])
        #expect(result.outputDirectory.path == generated.output.standardizedFileURL.path)
    }

    @Test("The source directory of the generator model can be part of the layout")
    @MainActor
    func sourceRootLayout() async throws {
        let generated = try await GeneratedProject.make(
            "library", stem: "library", options: GenModelImportOptions(basePackage: "org.example"))
        defer { generated.remove() }
        let result = try await generated.generate(options: GenerationOptions(includeSourceRoot: true))
        let libraryFiles = try #require(JavaGoldenCase.all.first { $0.fixture == "library" }).files
        #expect(generated.generatedPaths() == libraryFiles.map { "library/src/\($0)" }.sorted())
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
        #expect(fileUpdates.map(\.completed) == [1, 2, 3, 4, 5])
        #expect(fileUpdates.allSatisfy { $0.total == 5 })
        #expect(fileUpdates.last?.fraction == 1)
        #expect(updates.last?.message == "Done")
        #expect(updates.first?.fraction == nil)
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
