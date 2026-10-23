//
// ModelPipelineTests.swift
// ModellingPipelineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingGenerators
import ModellingPipeline
import Testing

@Suite("ModelPipeline - load, transform, generate and save")
@MainActor
struct ModelPipelineTests {
    @Test("runs a transformation and a generation over loaded models and saves the result")
    func fullPipeline() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let output = fixture.directory.appendingPathComponent("generated")
        let saved = fixture.directory.appendingPathComponent("saved/contacts.json")
        let transformation = TransformationStep(
            moduleURL: fixture.transformation, nativeHelpers: [TransformationStepTests.shout])
        let packages = try await ModelIO.registerMetamodels(
            at: [fixture.peopleEcore, fixture.contactsEcore], in: ResourceSet())
        var step = transformation
        step.metamodels = .init(packages: packages)
        let generation = GenerationStep(
            templates: .module(fixture.listing), parameters: ["prefix": "- "], outputDirectory: output)
        let collector = ReportCollector()

        let pipeline = ModelPipeline(steps: [
            .registerMetamodels([fixture.peopleEcore, fixture.contactsEcore]),
            .load(name: "people", url: fixture.peopleModel),
            .transform(step, sources: ["IN": "people"], targets: ["OUT": "contacts"]),
            .generate(generation, arguments: ["contacts"]),
            .save(name: "contacts", url: saved),
        ])
        let result = try await pipeline.run(progress: { collector.receive($0) })

        #expect(Set(result.models.keys) == ["people", "contacts"])
        let listing = output.appendingPathComponent("contacts.txt").standardizedFileURL
        #expect(result.generatedFiles == [listing])
        #expect(result.generations.first?.standardOutput?.contains("listed") == true)
        #expect(try fixture.text(of: listing) == "- Dear ADA\n- Dear ALAN\n")
        #expect(try fixture.text(of: saved).contains("Dear ADA"))
        #expect(collector.messages.contains("Loading people.xmi"))
        #expect(collector.messages.contains("Transforming with People2Contacts.atl"))
        #expect(collector.messages.contains("Saving contacts.json"))
    }

    @Test("keeps targets under their aliases and reads sources of the same name")
    func defaultNames() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let packages = try await ModelIO.registerMetamodels(
            at: [fixture.peopleEcore, fixture.contactsEcore], in: ResourceSet())
        let step = TransformationStep(
            moduleURL: fixture.transformation, metamodels: packages,
            nativeHelpers: [TransformationStepTests.shout])
        let saved = fixture.directory.appendingPathComponent("contacts.xmi")

        let result = try await ModelPipeline(steps: [
            .registerPackages(packages),
            .load(name: "IN", url: fixture.peopleModel, format: .xmi),
            .transform(step),
            .save(name: "OUT", url: saved, format: .xmi),
        ]).run()

        #expect(Set(result.models.keys) == ["IN", "OUT"])
        #expect(result.generatedFiles.isEmpty)
        let reloadSet = ResourceSet()
        let reloaded = try await ModelIO.load(url: saved, resourceSet: reloadSet, metamodels: [fixture.contactsEcore])
        #expect(await reloaded.resource.getAllObjects().count == 3)
    }

    @Test("collects what a conversion cannot keep")
    func diagnostics() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let saved = fixture.directory.appendingPathComponent("people.json")

        let result = try await ModelPipeline(steps: [
            .load(name: "people", url: fixture.peopleModel),
            .save(name: "people", url: saved),
        ]).run()

        #expect(!result.diagnostics.isEmpty)
        #expect(FileManager.default.fileExists(atPath: saved.path))
    }

    @Test("rejects a step that names a model the pipeline does not hold")
    func unknownModel() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }

        await #expect(throws: ModelPipelineError.unknownModel("missing", [])) {
            _ = try await ModelPipeline(steps: [
                .save(name: "missing", url: fixture.directory.appendingPathComponent("x.xmi"))
            ]).run()
        }
        let generation = GenerationStep(templates: .module(fixture.listing), outputDirectory: fixture.directory)
        await #expect(throws: ModelPipelineError.unknownModel("contacts", [])) {
            _ = try await ModelPipeline(steps: [.generate(generation, arguments: ["contacts"])]).run()
        }
        let step = TransformationStep(moduleURL: fixture.transformation)
        await #expect(throws: ModelPipelineError.unknownModel("people", [])) {
            _ = try await ModelPipeline(steps: [.transform(step, sources: ["IN": "people"])]).run()
        }
    }

    @Test("starts with no steps and adds them in order")
    func steps() {
        var pipeline = ModelPipeline()
        #expect(pipeline.steps.isEmpty)
        pipeline.steps.append(.registerMetamodels([]))
        #expect(pipeline.steps.count == 1)
    }
}
