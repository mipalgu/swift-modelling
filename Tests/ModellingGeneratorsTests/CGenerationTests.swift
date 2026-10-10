import Foundation
import Testing

@testable import ModellingGenerators

/// A fixture together with the files that the C template set must generate for it.
struct CGoldenCase: Sendable, CustomTestStringConvertible {
    /// The name of the fixture directory.
    let fixture: String

    /// The file stem of the source model.
    let stem: String

    /// The import options that the expectations were reviewed for.
    let options: GenModelImportOptions

    /// The expected files, relative to the output directory and sorted.
    let files: [String]

    var testDescription: String { fixture }

    /// The folder of the expectations, below the fixture.
    static let expectationFolder = "expected-c"

    /// Every fixture with committed C expectations.
    static let all: [CGoldenCase] = [
        CGoldenCase(
            fixture: "library", stem: "library",
            options: GenModelImportOptions(basePackage: "org.example", copyright: "Copyright 2026 Example Pty Ltd"),
            files: [
                "EObject.h",
                "library/library.c",
                "library/library.h",
            ]),
        CGoldenCase(
            fixture: "nested", stem: "company",
            options: GenModelImportOptions(basePackage: "org.example.company", packagePrefixes: ["projects": "Proj"]),
            files: [
                "EObject.h",
                "company/company.c",
                "company/company.h",
                "company/people/people.c",
                "company/people/people.h",
                "company/projects/archive/archive.c",
                "company/projects/archive/archive.h",
                "company/projects/projects.c",
                "company/projects/projects.h",
            ]),
        CGoldenCase(
            fixture: "enumerations", stem: "enumerations",
            options: GenModelImportOptions(basePackage: "org.example.traffic"),
            files: [
                "EObject.h",
                "enumerations/enumerations.c",
                "enumerations/enumerations.h",
            ]),
        CGoldenCase(
            fixture: "classes", stem: "classes",
            options: GenModelImportOptions(basePackage: "org.example.shapes"),
            files: [
                "EObject.h",
                "classes/classes.c",
                "classes/classes.h",
            ]),
        CGoldenCase(
            fixture: "maps", stem: "maps",
            options: GenModelImportOptions(),
            files: [
                "EObject.h",
                "maps/maps.c",
                "maps/maps.h",
            ]),
        CGoldenCase(
            fixture: "documented", stem: "documented",
            options: GenModelImportOptions(basePackage: "org.example.alarm"),
            files: [
                "EObject.h",
                "documented/documented.c",
                "documented/documented.h",
            ]),
        CGoldenCase(
            fixture: "datatypes", stem: "datatypes",
            options: GenModelImportOptions(basePackage: "org.example.types"),
            files: [
                "EObject.h",
                "datatypes/datatypes.c",
                "datatypes/datatypes.h",
            ]),
        CGoldenCase(
            fixture: "families", stem: "families",
            options: GenModelImportOptions(basePackage: "org.example.families"),
            files: [
                "EObject.h",
                "Families/Families.c",
                "Families/Families.h",
            ]),
        CGoldenCase(
            fixture: "organisation", stem: "organisation",
            options: GenModelImportOptions(prefix: "Org"),
            files: [
                "EObject.h",
                "organisation/organisation.c",
                "organisation/organisation.h",
            ]),
        CGoldenCase(
            fixture: "ecoretypes", stem: "bridge",
            options: GenModelImportOptions(basePackage: "org.example.bridge"),
            files: [
                "EObject.h",
                "bridge/bridge.c",
                "bridge/bridge.h",
            ]),
        CGoldenCase(
            fixture: "bare", stem: "bare",
            options: GenModelImportOptions(),
            files: [
                "EObject.h",
                "bare/bare.c",
                "bare/bare.h",
            ]),
        CGoldenCase(
            fixture: "cnames", stem: "cnames",
            options: GenModelImportOptions(),
            files: [
                "EObject.h",
                "cnames/cnames.c",
                "cnames/cnames.h",
                "cnames/delete/delete.c",
                "cnames/delete/delete.h",
            ]),
    ]

    /// The case of a fixture.
    ///
    /// - Parameter fixture: The name of the fixture directory.
    /// - Returns: The case, or `nil` if the fixture has none.
    static func named(_ fixture: String) -> CGoldenCase? { all.first { $0.fixture == fixture } }
}

/// Generates a fixture with the C template set.
///
/// - Parameters:
///   - golden: The fixture to generate.
///   - options: The generation options.
/// - Returns: The generated project; the caller removes it.
@MainActor
func generateC(
    _ golden: CGoldenCase, options: GenerationOptions = GenerationOptions()
) async throws -> GeneratedProject {
    let generated = try await GeneratedProject.make(
        golden.fixture, stem: golden.stem, options: golden.options, language: "c")
    try await generated.generate(options: options)
    return generated
}

@Suite("C generation")
struct CGenerationTests {
    @Test("Generated files match the reviewed expectations", arguments: CGoldenCase.all)
    @MainActor
    func goldenFiles(_ golden: CGoldenCase) async throws {
        let generated = try await generateC(golden)
        defer { generated.remove() }

        let paths = generated.generatedPaths()
        #expect(paths == golden.files, "the generated files differ from the expected files")
        if GoldenFiles.isRecording {
            let folder = GoldenFiles.sourceFixtures.appendingPathComponent(
                "\(golden.fixture)/\(CGoldenCase.expectationFolder)")
            try? FileManager.default.removeItem(at: folder)
        }
        for path in paths {
            try GoldenFiles.check(
                try generated.text(path),
                against: "\(golden.fixture)/\(CGoldenCase.expectationFolder)/\(path)", path)
        }
    }

    @Test("Every header guards itself against repeated inclusion", arguments: CGoldenCase.all)
    @MainActor
    func headersAreGuarded(_ golden: CGoldenCase) async throws {
        let generated = try await generateC(golden)
        defer { generated.remove() }
        for path in generated.generatedPaths() where path.hasSuffix(".h") {
            let lines = try generated.text(path).components(separatedBy: "\n")
            let guardName = String(
                path.uppercased().map { $0.isASCII && ($0.isLetter || $0.isNumber) ? $0 : "_" })
            let opening = try #require(lines.firstIndex { $0.hasPrefix("#ifndef ") }, "\(path) has no guard")
            #expect(lines[opening] == "#ifndef \(guardName)", "\(path): the guard is named from the path")
            #expect(lines[opening + 1] == "#define \(guardName)", "\(path): the guard is defined at once")
            #expect(lines.last == "", "\(path) ends with a line break")
            #expect(lines.dropLast().last == "#endif", "\(path) ends with the end of its guard")
        }
    }

    @Test("Every fixture generates without error", arguments: CGoldenCase.all)
    @MainActor
    func everyFixtureGenerates(_ golden: CGoldenCase) async throws {
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, language: "c")
        defer { generated.remove() }
        let result = try await generated.generate()
        #expect(result.language == "c")
        #expect(result.files.count == generated.generatedPaths().count)
        #expect(result.packageCount >= 1)
        #expect(generated.generatedPaths().allSatisfy { $0.hasSuffix(".c") || $0.hasSuffix(".h") })
    }

    @Test("Generating twice yields identical files")
    @MainActor
    func determinism() async throws {
        let golden = try #require(CGoldenCase.named("library"))
        let generated = try await generateC(golden)
        defer { generated.remove() }
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
        let golden = try #require(CGoldenCase.named("enumerations"))
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options, language: "c")
        defer { generated.remove() }
        let result = try await generated.generate()
        #expect(result.language == "c")
        #expect(result.packageCount == 1)
        let names = result.files.map(\.lastPathComponent)
        #expect(
            names.isSubsequence(containing: ["EObject.h", "enumerations.h", "enumerations.c"]),
            "unexpected file order: \(names)")
        #expect(result.outputDirectory.path == generated.output.standardizedFileURL.path)
    }

    @Test("The source directory of the generator model can be part of the layout")
    @MainActor
    func sourceRootLayout() async throws {
        let golden = try #require(CGoldenCase.named("library"))
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options, language: "c")
        defer { generated.remove() }
        let result = try await generated.generate(options: GenerationOptions(includeSourceRoot: true))
        #expect(Set(generated.generatedPaths()) == Set(golden.files.map { "library/src/" + $0 }))
        #expect(result.outputDirectory.lastPathComponent == "src")
    }

    @Test("Progress reports count the files and know the total")
    @MainActor
    func progressCounts() async throws {
        let golden = try #require(CGoldenCase.named("nested"))
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options, language: "c")
        defer { generated.remove() }
        let collector = ProgressCollector()
        try await generated.generate(progress: { collector.add($0) })
        let updates = collector.updates
        let fileUpdates = updates.filter { $0.message.hasPrefix("Generated ") }
        #expect(fileUpdates.count == golden.files.count)
        #expect(fileUpdates.map(\.completed) == Array(1...fileUpdates.count))
        #expect(fileUpdates.allSatisfy { $0.total == fileUpdates.count })
        #expect(fileUpdates.last?.fraction == 1)
        #expect(updates.last?.message == "Done")
    }

    @Test("Every package writes a header and a source file named after it, and one support header is shared")
    @MainActor
    func packageFiles() async throws {
        let golden = try #require(CGoldenCase.named("nested"))
        let generated = try await generateC(golden)
        defer { generated.remove() }
        let paths = generated.generatedPaths()
        for directory in ["company", "company/people", "company/projects", "company/projects/archive"] {
            let name = String(directory.split(separator: "/").last ?? "")
            #expect(paths.contains("\(directory)/\(name).h"), "\(directory) has no header")
            #expect(paths.contains("\(directory)/\(name).c"), "\(directory) has no source file")
        }
        #expect(paths.filter { $0.hasSuffix("EObject.h") } == ["EObject.h"])
    }

    @Test("The support header does not depend on the model", arguments: CGoldenCase.all)
    @MainActor
    func supportHeaderIsShared(_ golden: CGoldenCase) async throws {
        let generated = try await generateC(golden)
        defer { generated.remove() }
        let library = try #require(CGoldenCase.named("library"))
        let reference = try await generateC(library)
        defer { reference.remove() }
        #expect(try generated.text("EObject.h") == (try reference.text("EObject.h")))
    }

    @Test("Several models can be generated into one directory")
    @MainActor
    func severalModelsShareADirectory() async throws {
        let library = try #require(CGoldenCase.named("library"))
        let bare = try #require(CGoldenCase.named("bare"))
        let first = try await generateC(library)
        defer { first.remove() }
        let second = try await GeneratedProject.make(
            bare.fixture, stem: bare.stem, options: bare.options, language: "c")
        defer { second.remove() }
        let before = try first.text("EObject.h")
        _ = try await GenerationPipeline.generate(
            genModelURL: second.genModel, language: "c", outputDirectory: first.output,
            options: GenerationOptions())
        #expect(try first.text("EObject.h") == before)
        #expect(Set(first.generatedPaths()) == Set(library.files + ["bare/bare.c", "bare/bare.h"]))
    }
}
