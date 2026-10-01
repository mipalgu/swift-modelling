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
            files: ["org/example/library/BookCategory.java"]),
        JavaGoldenCase(
            fixture: "nested", stem: "company",
            options: GenModelImportOptions(
                basePackage: "org.example.company", packagePrefixes: ["projects": "Proj"]),
            files: ["org/example/company/company/projects/Status.java"]),
        JavaGoldenCase(
            fixture: "enumerations", stem: "enumerations",
            options: GenModelImportOptions(basePackage: "org.example.traffic"),
            files: [
                "org/example/traffic/enumerations/Colour.java",
                "org/example/traffic/enumerations/Empty.java",
                "org/example/traffic/enumerations/Mode.java",
            ]),
        JavaGoldenCase(
            fixture: "documented", stem: "documented",
            options: GenModelImportOptions(basePackage: "org.example.alarm"),
            files: ["org/example/alarm/documented/Level.java"]),
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
        #expect(result.files.map(\.lastPathComponent) == ["Colour.java", "Mode.java", "Empty.java"])
        #expect(result.outputDirectory.path == generated.output.standardizedFileURL.path)
    }

    @Test("The source directory of the generator model can be part of the layout")
    @MainActor
    func sourceRootLayout() async throws {
        let generated = try await GeneratedProject.make(
            "library", stem: "library", options: GenModelImportOptions(basePackage: "org.example"))
        defer { generated.remove() }
        let result = try await generated.generate(options: GenerationOptions(includeSourceRoot: true))
        #expect(generated.generatedPaths() == ["library/src/org/example/library/BookCategory.java"])
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
        #expect(fileUpdates.map(\.completed) == [1, 2, 3])
        #expect(fileUpdates.allSatisfy { $0.total == 3 })
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
