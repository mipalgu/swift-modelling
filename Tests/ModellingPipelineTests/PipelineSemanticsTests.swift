//
// PipelineSemanticsTests.swift
// ModellingPipelineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ECore
import EMFBase
import Foundation
import MTL
import ModellingGenerators
import ModellingPipeline
import Testing

/// Tests for the behaviours that pipeline steps select: those documented for this release
/// through the initialisers that take options, and those of version 0.6 through the
/// initialisers of that version.
@Suite("Pipeline steps - behaviours of this release and of version 0.6")
@MainActor
struct PipelineSemanticsTests {
    /// A module whose output shows one behaviour of the templates per line.
    static let probe = """
        [module Probe('http://example.com')]
        [template public main()]
        [file ('result.txt')]
        start
        [if (false)]never[/if]
        args=[Sequence{'a'}->append(Sequence{'b', 'c'})->flatten()->size()/]
        kinds=[OrderedSet{'a'}->including('a')->size()/]
        single=['a'->including('a')->size()/]
        lettypes=[let n : Integer = 'text']unchecked[/let]
        end
        [/file]
        [/template]
        """

    /// The output of the probe with the behaviour of this release and skipped mismatches.
    static let standardOutput = "start\nargs=3\nkinds=1\nsingle=1\nlettypes=\nend\n"

    /// The output of the probe with the behaviour of version 0.6, as swift-modelling 0.6.2 writes it.
    static let legacyOutput = "start\n\nargs=2\nkinds=2\nsingle=2\nlettypes=unchecked\nend\n"

    /// A transformation whose rule uses an integer range.
    static let ranges = """
        module Ranges;
        create OUT : Contacts from IN : People;

        rule Person2Contact {
            from p : People!Person
            to c : Contacts!Contact ( fullName <- p.name + Sequence{1..3}->size().toString() )
        }
        """

    /// The behaviours of this release, with typed `let` mismatches skipped.
    static var standardSkipping: MTLOptions {
        var options = MTLOptions.standard
        options.letTypeMismatches = .skip
        return options
    }

    /// Runs the probe module with a generation step and returns the text it wrote.
    private func generate(_ step: (URL, URL) -> GenerationStep) async throws -> (GenerationStep.Result, String) {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let module = fixture.directory.appendingPathComponent("modules/Probe.mtl")
        try fixture.write(Self.probe, to: module)
        let result = try await step(module, fixture.directory.appendingPathComponent("generated")).run(arguments: [])
        return (result, try fixture.text(of: try #require(result.files.first)))
    }

    // MARK: - Generation steps

    @Test("a generation step of version 0.6 carries the legacy options")
    func legacyGenerationStep() {
        let directory = URL(fileURLWithPath: "generated")
        let step = GenerationStep(templates: .module(directory), outputDirectory: directory)
        #expect(step.mtlOptions == .legacy)

        var undefined = MTLOptions.legacy
        undefined.unsetFeatureReads = .undefined
        var reading = GenerationStep(
            templates: .module(directory), outputDirectory: directory, unsetFeatureReads: .undefined)
        #expect(reading.mtlOptions == undefined)
        #expect(reading.unsetFeatureReads == .undefined)
        reading.unsetFeatureReads = .defaults
        #expect(reading.mtlOptions == .legacy)
    }

    @Test("a generation step carries the options it is given")
    func generationStepOptions() {
        let directory = URL(fileURLWithPath: "generated")
        let step = GenerationStep(templates: .module(directory), outputDirectory: directory, mtlOptions: .standard)
        #expect(step.mtlOptions == .standard)
        #expect(step.unsetFeatureReads == .defaults)
    }

    @Test("a generation step of version 0.6 generates as version 0.6 did")
    func legacyGeneration() async throws {
        let (result, text) = try await generate { module, output in
            GenerationStep(templates: .module(module), outputDirectory: output)
        }

        #expect(text == Self.legacyOutput)
        #expect(result.warnings.isEmpty)
    }

    @Test("a generation step with the legacy options generates as version 0.6 did")
    func legacyOptionsGeneration() async throws {
        let (_, text) = try await generate { module, output in
            GenerationStep(templates: .module(module), outputDirectory: output, mtlOptions: .legacy)
        }

        #expect(text == Self.legacyOutput)
    }

    @Test("a generation step with the standard options generates with the behaviour of this release")
    func standardGeneration() async throws {
        let (result, text) = try await generate { module, output in
            GenerationStep(templates: .module(module), outputDirectory: output, mtlOptions: Self.standardSkipping)
        }

        #expect(text == Self.standardOutput)
        #expect(result.warnings.count == 1)
    }

    @Test("describes a generation without warnings with the initialiser of version 0.6")
    func resultWithoutWarnings() {
        let directory = URL(fileURLWithPath: "generated")
        let result = GenerationStep.Result(
            outputDirectory: directory, files: [], standardOutput: nil, mainTemplate: "main", templateSet: nil)
        #expect(result.warnings.isEmpty)

        let warning = SourceDiagnostic(severity: .warning, code: "mtl.letTypeMismatch", message: "skipped")
        let warned = GenerationStep.Result(
            outputDirectory: directory, files: [], standardOutput: nil, mainTemplate: "main", templateSet: nil,
            warnings: [warning])
        #expect(warned.warnings == [warning])
    }

    // MARK: - Transformation steps

    /// Loads the metamodels and the source model of the fixture.
    private func load(_ fixture: PipelineFixture) async throws -> (packages: [EPackage], source: Resource) {
        let resourceSet = ResourceSet()
        let packages = try await ModelIO.registerMetamodels(
            at: [fixture.peopleEcore, fixture.contactsEcore], in: resourceSet)
        let source = try await ModelIO.load(url: fixture.peopleModel, resourceSet: resourceSet).resource
        return (packages, source)
    }

    @Test("transformation steps of version 0.6 carry the legacy options")
    func legacyTransformationSteps() {
        let url = URL(fileURLWithPath: "Ranges.atl")
        #expect(TransformationStep(moduleURL: url).atlOptions == .legacy)
        #expect(TransformationStep(moduleURL: url, metamodels: [EPackage]()).atlOptions == .legacy)
        #expect(TransformationStep(moduleURL: url, atlOptions: .standard).atlOptions == .standard)
        #expect(TransformationStep(moduleURL: url, metamodels: [EPackage](), atlOptions: .standard).atlOptions == .standard)
    }

    @Test("a transformation step of version 0.6 rejects ranges as version 0.6 did")
    func legacyTransformationRejectsRanges() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let (packages, source) = try await load(fixture)
        let module = fixture.directory.appendingPathComponent("Ranges.atl")
        try fixture.write(Self.ranges, to: module)

        for step in [
            TransformationStep(moduleURL: module, metamodels: packages, sourceAliases: ["IN": source]),
            TransformationStep(
                moduleURL: module, metamodels: ATLMetamodelRegistry(packages: packages), sourceAliases: ["IN": source]),
            TransformationStep(moduleURL: module, metamodels: packages, sourceAliases: ["IN": source], atlOptions: .legacy),
        ] {
            await #expect(throws: ModelPipelineError.self) {
                _ = try await step.run()
            }
        }
    }

    @Test("a transformation step with the standard options accepts ranges")
    func standardTransformationAcceptsRanges() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let (packages, source) = try await load(fixture)
        let module = fixture.directory.appendingPathComponent("Ranges.atl")
        try fixture.write(Self.ranges, to: module)

        for step in [
            TransformationStep(moduleURL: module, metamodels: packages, sourceAliases: ["IN": source], atlOptions: .standard),
            TransformationStep(
                moduleURL: module, metamodels: ATLMetamodelRegistry(packages: packages), sourceAliases: ["IN": source],
                atlOptions: .standard),
        ] {
            let targets = try await step.run()
            let book = try #require(targets["OUT"])
            let names = await book.getAllObjects().compactMap { ($0 as? DynamicEObject)?.eGet("fullName") as? String }
            #expect(names.sorted() == ["Ada3", "Alan3"])
        }
    }

    // MARK: - Pipelines

    @Test("a pipeline runs its steps with the behaviours they carry")
    func pipelineUsesStepOptions() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let module = fixture.directory.appendingPathComponent("modules/Probe.mtl")
        try fixture.write(Self.probe, to: module)
        let ranges = fixture.directory.appendingPathComponent("Ranges.atl")
        try fixture.write(Self.ranges, to: ranges)
        let (packages, _) = try await load(fixture)
        let standard = GenerationStep(
            templates: .module(module), outputDirectory: fixture.directory.appendingPathComponent("standard"),
            mtlOptions: Self.standardSkipping)
        let legacy = GenerationStep(
            templates: .module(module), outputDirectory: fixture.directory.appendingPathComponent("legacy"),
            mtlOptions: .legacy)

        let result = try await ModelPipeline(steps: [
            .registerMetamodels([fixture.peopleEcore, fixture.contactsEcore]),
            .load(name: "IN", url: fixture.peopleModel),
            .transform(
                TransformationStep(moduleURL: ranges, metamodels: packages, atlOptions: .standard),
                targets: ["OUT": "book"]),
            .generate(standard), .generate(legacy),
        ]).run()

        #expect(result.models["book"] != nil)
        #expect(try fixture.text(of: try #require(result.generations.first?.files.first)) == Self.standardOutput)
        #expect(try fixture.text(of: try #require(result.generations.last?.files.first)) == Self.legacyOutput)
    }
}
