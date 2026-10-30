//
// GenerationSemanticsTests.swift
// ModellingGeneratorsTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ECore
import Foundation
import MTL
import Testing

@testable import ModellingGenerators

/// Tests for the behaviours that generation and import options select: those documented for
/// this release through the initialisers that take options, and those of version 0.6 through
/// the initialisers and default arguments of that version.
@Suite("Generation options - behaviours of this release and of version 0.6")
struct GenerationSemanticsTests {
    /// A header module whose output shows one behaviour of the templates per line.
    static let probe = """
        [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
        [template public header(element : OclAny, fileName : String)]
        // probe
        [if (false)]never[/if]
        // args=[Sequence{'a'}->append(Sequence{'b', 'c'})->flatten()->size()/]
        // kinds=[OrderedSet{'a'}->including('a')->size()/]
        // single=['a'->including('a')->size()/]
        // lettypes=[let n : Integer = fileName]unchecked[/let]
        // end
        [/template]
        """

    /// The start of a generated file with the behaviour of this release and skipped mismatches.
    static let standardHeader =
        "// probe\n// args=3\n// kinds=1\n// single=1\n// lettypes=\n// end\n"

    /// The start of a generated file with the behaviour of version 0.6.
    static let legacyHeader =
        "// probe\n\n// args=2\n// kinds=2\n// single=2\n// lettypes=unchecked\n// end\n"

    /// A helper that uses an integer range, appended to a copy of the bundled transformation.
    static let rangeHelper = "\nhelper def : probeRange : Sequence(Integer) = Sequence{1..2};\n"

    /// The behaviours of this release, with typed `let` mismatches skipped.
    static var standardSkipping: MTLOptions {
        var options = MTLOptions.standard
        options.letTypeMismatches = .skip
        return options
    }

    // MARK: - Options

    @Test("generation options of version 0.6 carry the legacy options")
    func legacyGenerationOptions() {
        #expect(GenerationOptions().mtlOptions == .legacy)
        #expect(GenerationOptions().unsetFeatureReads == .defaults)

        var undefined = MTLOptions.legacy
        undefined.unsetFeatureReads = .undefined
        var options = GenerationOptions(templatePaths: [], diff: true, unsetFeatureReads: .undefined)
        #expect(options.mtlOptions == undefined)
        #expect(options.unsetFeatureReads == .undefined)
        #expect(options.diff)
        options.unsetFeatureReads = .defaults
        #expect(options.mtlOptions == .legacy)
    }

    @Test("generation options carry the behaviours they are given")
    func generationOptions() {
        let standard = GenerationOptions(diff: true, mtlOptions: .standard)
        #expect(standard.mtlOptions == .standard)
        #expect(standard.diff)
        #expect(GenerationOptions(mtlOptions: .legacy) == GenerationOptions())
        #expect(GenerationOptions(mtlOptions: .standard) != GenerationOptions())
    }

    @Test("import options of version 0.6 carry the legacy ATL options")
    func legacyImportOptions() {
        #expect(GenModelImportOptions().atlOptions == .legacy)
        #expect(GenModelImportOptions(basePackage: "org.example").atlOptions == .legacy)
        let options = GenModelImportOptions(basePackage: "org.example", atlOptions: .standard)
        #expect(options.atlOptions == .standard)
        #expect(options.basePackage == "org.example")
        #expect(GenModelImportOptions(atlOptions: .legacy) == GenModelImportOptions())
    }

    // MARK: - Generation

    /// Generates Swift from the library Ecore model with the probe header module.
    ///
    /// - Parameter generate: Runs the pipeline with the model, output and template directory.
    /// - Returns: The start of one generated file.
    @MainActor
    private func header(
        _ generate: (URL, URL, URL) async throws -> GenerationResult
    ) async throws -> String {
        let project = try FixtureProject.make("library")
        defer { project.remove() }
        let templates = try ScratchDirectory()
        defer { templates.remove() }
        try templates.write(Self.probe, to: "Header.mtl")
        let output = project.root.appendingPathComponent("swift")
        _ = try await generate(project.root.appendingPathComponent("model/library.ecore"), output, templates.url)
        return try String(contentsOf: output.appendingPathComponent("library/Book.swift"), encoding: .utf8)
    }

    @Test("generates as version 0.6 did without options")
    @MainActor
    func legacyWithoutOptions() async throws {
        let project = try FixtureProject.make("library")
        defer { project.remove() }
        let model = project.root.appendingPathComponent("model/library.ecore")
        let omitted = project.root.appendingPathComponent("omitted")
        let legacy = project.root.appendingPathComponent("legacy")
        let omittedResult = try await GenerationPipeline.generate(
            inputURL: model, language: "swift", outputDirectory: omitted)
        let legacyResult = try await GenerationPipeline.generate(
            inputURL: model, language: "swift", outputDirectory: legacy,
            options: GenerationOptions(mtlOptions: .legacy))

        #expect(omittedResult.files.map(\.lastPathComponent) == legacyResult.files.map(\.lastPathComponent))
        for file in legacyResult.files {
            let relative = String(file.path.dropFirst(legacyResult.outputDirectory.path.count))
            let expected = try String(contentsOf: file, encoding: .utf8)
            let actual = try String(contentsOfFile: omittedResult.outputDirectory.path + relative, encoding: .utf8)
            #expect(actual == expected, "\(relative)")
        }

        let customised = try await header { model, output, templates in
            try await GenerationPipeline.generate(
                inputURL: model, language: "swift", outputDirectory: output,
                options: GenerationOptions(templatePaths: [templates]))
        }
        #expect(customised.hasPrefix(Self.legacyHeader), "\(customised)")
    }

    @Test("generates as version 0.6 did with the legacy options")
    @MainActor
    func legacyOptions() async throws {
        let text = try await header { model, output, templates in
            try await GenerationPipeline.generate(
                inputURL: model, language: "swift", outputDirectory: output,
                options: GenerationOptions(templatePaths: [templates], mtlOptions: .legacy))
        }
        #expect(text.hasPrefix(Self.legacyHeader), "\(text)")
    }

    @Test("generates with the behaviour of this release with the standard options")
    @MainActor
    func standardOptions() async throws {
        let text = try await header { model, output, templates in
            try await GenerationPipeline.generate(
                inputURL: model, language: "swift", outputDirectory: output,
                options: GenerationOptions(templatePaths: [templates], mtlOptions: Self.standardSkipping))
        }
        #expect(text.hasPrefix(Self.standardHeader), "\(text)")
    }

    @Test("generates from a generator model with the behaviours of either release")
    @MainActor
    func generatorModel() async throws {
        for (options, expected) in [
            (GenerationOptions(mtlOptions: Self.standardSkipping), Self.standardHeader),
            (GenerationOptions(), Self.legacyHeader),
        ] {
            let text = try await header { model, output, templates in
                let genModel = try await GenerationPipeline.ecoreToGenModel(
                    ecoreURLs: [model], options: GenModelImportOptions(atlOptions: .standard))
                var options = options
                options.templatePaths = [templates]
                return try await GenerationPipeline.generate(
                    genModelURL: genModel.url, language: "swift", outputDirectory: output, options: options)
            }
            #expect(text.hasPrefix(expected), "\(text)")
        }
    }

    // MARK: - Import

    /// Imports the library Ecore model with a copy of the bundled transformation that uses a range.
    ///
    /// - Parameter importOptions: Creates the import options from the replacement transformation;
    ///   `nil` leaves the options to the default argument and the bundled transformation.
    /// - Throws: The error of the import.
    @MainActor
    private func importWithRange(_ importOptions: (URL) -> GenModelImportOptions) async throws {
        let project = try FixtureProject.make("library")
        defer { project.remove() }
        let bundled = try #require(GenModelTransformation.resourceURL)
        let transformation = project.root.appendingPathComponent("Ecore2GenModel.atl")
        try (try String(contentsOf: bundled, encoding: .utf8) + Self.rangeHelper)
            .write(to: transformation, atomically: true, encoding: .utf8)
        _ = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [project.root.appendingPathComponent("model/library.ecore")],
            options: importOptions(transformation))
    }

    @Test("rejects a range in a replacement transformation as version 0.6 did")
    @MainActor
    func legacyImportRejectsRanges() async throws {
        await #expect(throws: GenerationError.self) {
            try await importWithRange { GenModelImportOptions(transformation: $0) }
        }
        await #expect(throws: GenerationError.self) {
            try await importWithRange { GenModelImportOptions(transformation: $0, atlOptions: .legacy) }
        }
    }

    @Test("accepts a range in a replacement transformation with the standard options")
    @MainActor
    func standardImportAcceptsRanges() async throws {
        try await importWithRange { GenModelImportOptions(transformation: $0, atlOptions: .standard) }
    }

    @Test("imports with the bundled transformation without options")
    @MainActor
    func defaultImport() async throws {
        let project = try FixtureProject.make("library")
        defer { project.remove() }
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [project.root.appendingPathComponent("model/library.ecore")])
        #expect(FileManager.default.fileExists(atPath: result.url.path))
    }
}
