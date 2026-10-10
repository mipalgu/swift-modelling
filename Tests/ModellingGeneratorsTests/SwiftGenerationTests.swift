import Foundation
import Testing

@testable import ModellingGenerators

/// A fixture together with the files that the Swift template set must generate for it.
struct SwiftGoldenCase: Sendable, CustomTestStringConvertible {
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
    static let expectationFolder = "expected-swift"

    /// Every fixture with committed Swift expectations.
    static let all: [SwiftGoldenCase] = [
        SwiftGoldenCase(
            fixture: "library", stem: "library",
            options: GenModelImportOptions(basePackage: "org.example", copyright: "Copyright 2026 Example Pty Ltd"),
            files: [
                "library/Book.swift",
                "library/BookCategory.swift",
                "library/ISBN.swift",
                "library/Lendable.swift",
                "library/Library.swift",
                "library/LibraryFactory.swift",
                "library/LibraryPackage.swift",
                "library/Named.swift",
                "library/Writer.swift",
            ]),
        SwiftGoldenCase(
            fixture: "nested", stem: "company",
            options: GenModelImportOptions(basePackage: "org.example.company", packagePrefixes: ["projects": "Proj"]),
            files: [
                "company/Company.swift",
                "company/CompanyFactory.swift",
                "company/CompanyPackage.swift",
                "company/people/Employee.swift",
                "company/people/PeopleFactory.swift",
                "company/people/PeoplePackage.swift",
                "company/people/Person.swift",
                "company/projects/ProjFactory.swift",
                "company/projects/ProjPackage.swift",
                "company/projects/Project.swift",
                "company/projects/Status.swift",
                "company/projects/archive/ArchiveFactory.swift",
                "company/projects/archive/ArchivePackage.swift",
                "company/projects/archive/Record.swift",
            ]),
        SwiftGoldenCase(
            fixture: "enumerations", stem: "enumerations",
            options: GenModelImportOptions(basePackage: "org.example.traffic"),
            files: [
                "enumerations/Colour.swift",
                "enumerations/Empty.swift",
                "enumerations/EnumerationsFactory.swift",
                "enumerations/EnumerationsPackage.swift",
                "enumerations/Light.swift",
                "enumerations/Mode.swift",
            ]),
        SwiftGoldenCase(
            fixture: "classes", stem: "classes",
            options: GenModelImportOptions(basePackage: "org.example.shapes"),
            files: [
                "classes/Canvas.swift",
                "classes/Circle.swift",
                "classes/ClassesFactory.swift",
                "classes/ClassesPackage.swift",
                "classes/Colour.swift",
                "classes/Named.swift",
                "classes/Shape.swift",
            ]),
        SwiftGoldenCase(
            fixture: "maps", stem: "maps",
            options: GenModelImportOptions(),
            files: [
                "maps/Dictionary_.swift",
                "maps/MapsFactory.swift",
                "maps/MapsPackage.swift",
                "maps/StringToIntEntry.swift",
            ]),
        SwiftGoldenCase(
            fixture: "documented", stem: "documented",
            options: GenModelImportOptions(basePackage: "org.example.alarm"),
            files: [
                "documented/DocumentedFactory.swift",
                "documented/DocumentedPackage.swift",
                "documented/Level.swift",
            ]),
        SwiftGoldenCase(
            fixture: "datatypes", stem: "datatypes",
            options: GenModelImportOptions(basePackage: "org.example.types"),
            files: [
                "datatypes/Anything.swift",
                "datatypes/Class.swift",
                "datatypes/Colour.swift",
                "datatypes/Count.swift",
                "datatypes/DatatypesFactory.swift",
                "datatypes/DatatypesPackage.swift",
                "datatypes/Gizmo.swift",
                "datatypes/Hidden.swift",
                "datatypes/Stamp.swift",
                "datatypes/Thing.swift",
            ]),
        SwiftGoldenCase(
            fixture: "families", stem: "families",
            options: GenModelImportOptions(basePackage: "org.example.families"),
            files: [
                "Families/FamiliesFactory.swift",
                "Families/FamiliesPackage.swift",
                "Families/Family.swift",
                "Families/Member.swift",
            ]),
        SwiftGoldenCase(
            fixture: "organisation", stem: "organisation",
            options: GenModelImportOptions(prefix: "Org"),
            files: [
                "organisation/OrgFactory.swift",
                "organisation/OrgPackage.swift",
                "organisation/Organisation.swift",
                "organisation/Person.swift",
                "organisation/Team.swift",
            ]),
        SwiftGoldenCase(
            fixture: "ecoretypes", stem: "bridge",
            options: GenModelImportOptions(basePackage: "org.example.bridge"),
            files: [
                "bridge/BridgeFactory.swift",
                "bridge/BridgePackage.swift",
                "bridge/Span.swift",
            ]),
        SwiftGoldenCase(
            fixture: "bare", stem: "bare",
            options: GenModelImportOptions(),
            files: [
                "bare/BareFactory.swift",
                "bare/BarePackage.swift",
                "bare/Thing.swift",
            ]),
        SwiftGoldenCase(
            fixture: "swiftnames", stem: "swiftnames",
            options: GenModelImportOptions(),
            files: [
                "swiftnames/Date_.swift",
                "swiftnames/Driver.swift",
                "swiftnames/Hue.swift",
                "swiftnames/Mood.swift",
                "swiftnames/Package.swift",
                "swiftnames/Stamp.swift",
                "swiftnames/SwiftnamesFactory.swift",
                "swiftnames/SwiftnamesPackage.swift",
                "swiftnames/Truck.swift",
                "swiftnames/Type.swift",
                "swiftnames/Values.swift",
                "swiftnames/Vehicle.swift",
                "swiftnames/parts/PartsFactory.swift",
                "swiftnames/parts/PartsPackage.swift",
                "swiftnames/parts/Protocol.swift",
                "swiftnames/parts/Self.swift",
                "swiftnames/parts/String_.swift",
                "swiftnames/parts/Wheel.swift",
            ]),
    ]

    /// The case of a fixture.
    ///
    /// - Parameter fixture: The name of the fixture directory.
    /// - Returns: The case, or `nil` if the fixture has none.
    static func named(_ fixture: String) -> SwiftGoldenCase? { all.first { $0.fixture == fixture } }
}

/// Generates a fixture with the Swift template set.
///
/// - Parameters:
///   - golden: The fixture to generate.
///   - options: The generation options.
/// - Returns: The generated project; the caller removes it.
@MainActor
func generateSwift(
    _ golden: SwiftGoldenCase, options: GenerationOptions = GenerationOptions()
) async throws -> GeneratedProject {
    let generated = try await GeneratedProject.make(
        golden.fixture, stem: golden.stem, options: golden.options, language: "swift")
    try await generated.generate(options: options)
    return generated
}

@Suite("Swift generation")
struct SwiftGenerationTests {
    @Test("Generated files match the reviewed expectations", arguments: SwiftGoldenCase.all)
    @MainActor
    func goldenFiles(_ golden: SwiftGoldenCase) async throws {
        let generated = try await generateSwift(golden)
        defer { generated.remove() }

        let paths = generated.generatedPaths()
        #expect(paths == golden.files, "the generated files differ from the expected files")
        if GoldenFiles.isRecording {
            let folder = GoldenFiles.sourceFixtures.appendingPathComponent(
                "\(golden.fixture)/\(SwiftGoldenCase.expectationFolder)")
            try? FileManager.default.removeItem(at: folder)
        }
        for path in paths {
            try GoldenFiles.check(
                try generated.text(path),
                against: "\(golden.fixture)/\(SwiftGoldenCase.expectationFolder)/\(path)", path)
        }
    }

    @Test("Every generated enumeration is Sendable, Codable and CaseIterable", arguments: SwiftGoldenCase.all)
    @MainActor
    func enumerationsConform(_ golden: SwiftGoldenCase) async throws {
        let generated = try await generateSwift(golden)
        defer { generated.remove() }
        for path in generated.generatedPaths() {
            let text = try generated.text(path)
            for line in text.split(separator: "\n") where line.hasPrefix("public enum ") {
                #expect(
                    line.contains(" Sendable, Codable, CaseIterable"),
                    "\(path) does not declare Sendable, Codable and CaseIterable: \(line)")
            }
        }
    }

    @Test("Every fixture generates without error", arguments: SwiftGoldenCase.all)
    @MainActor
    func everyFixtureGenerates(_ golden: SwiftGoldenCase) async throws {
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, language: "swift")
        defer { generated.remove() }
        let result = try await generated.generate()
        #expect(result.language == "swift")
        #expect(result.files.count == generated.generatedPaths().count)
        #expect(result.packageCount >= 1)
        #expect(generated.generatedPaths().allSatisfy { $0.hasSuffix(".swift") })
    }

    @Test("Generating twice yields identical files")
    @MainActor
    func determinism() async throws {
        let golden = try #require(SwiftGoldenCase.named("library"))
        let generated = try await generateSwift(golden)
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
        let golden = try #require(SwiftGoldenCase.named("enumerations"))
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options, language: "swift")
        defer { generated.remove() }
        let result = try await generated.generate()
        #expect(result.language == "swift")
        #expect(result.packageCount == 1)
        let names = result.files.map(\.lastPathComponent)
        let expectedOrder = [
            "EnumerationsPackage.swift", "EnumerationsFactory.swift", "Light.swift", "Colour.swift", "Mode.swift",
            "Empty.swift",
        ]
        #expect(names.isSubsequence(containing: expectedOrder), "unexpected file order: \(names)")
        #expect(result.outputDirectory.path == generated.output.standardizedFileURL.path)
    }

    @Test("The source directory of the generator model can be part of the layout")
    @MainActor
    func sourceRootLayout() async throws {
        let golden = try #require(SwiftGoldenCase.named("library"))
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options, language: "swift")
        defer { generated.remove() }
        let result = try await generated.generate(options: GenerationOptions(includeSourceRoot: true))
        #expect(Set(generated.generatedPaths()) == Set(golden.files.map { "library/src/" + $0 }))
        #expect(result.outputDirectory.lastPathComponent == "src")
    }

    @Test("Progress reports count the files and know the total")
    @MainActor
    func progressCounts() async throws {
        let golden = try #require(SwiftGoldenCase.named("nested"))
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options, language: "swift")
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

    @Test("Every package writes a package description and a factory, and nothing else is shared")
    @MainActor
    func packageFiles() async throws {
        let golden = try #require(SwiftGoldenCase.named("nested"))
        let generated = try await generateSwift(golden)
        defer { generated.remove() }
        let paths = generated.generatedPaths()
        for (directory, prefix) in [
            ("company", "Company"), ("company/people", "People"), ("company/projects", "Proj"),
            ("company/projects/archive", "Archive"),
        ] {
            #expect(paths.contains("\(directory)/\(prefix)Package.swift"), "\(directory) has no package description")
            #expect(paths.contains("\(directory)/\(prefix)Factory.swift"), "\(directory) has no factory")
        }
    }
}
