//
// TransformationStepTests.swift
// ModellingPipelineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ECore
import EMFBase
import Foundation
import ModellingPipeline
import Testing

@Suite("TransformationStep - ATL runs on models in memory")
@MainActor
struct TransformationStepTests {
    /// A module-level helper implemented in Swift that writes its argument in capitals.
    static let shout = ATLNativeHelper(
        name: "shout", parameterTypes: ["String"], returnType: "String"
    ) { _, arguments in
        (arguments.first.flatMap { $0 as? String } ?? "").uppercased()
    }

    /// Loads the metamodels and the source model of the fixture.
    private func load(_ fixture: PipelineFixture) async throws -> (packages: [EPackage], source: Resource) {
        let resourceSet = ResourceSet()
        let packages = try await ModelIO.registerMetamodels(
            at: [fixture.peopleEcore, fixture.contactsEcore], in: resourceSet)
        let source = try await ModelIO.load(url: fixture.peopleModel, resourceSet: resourceSet).resource
        return (packages, source)
    }

    /// The full names of the contacts of a book.
    private func fullNames(in book: Resource?) async throws -> [String] {
        let book = try #require(book)
        let contacts = await book.getAllObjects().compactMap { $0 as? DynamicEObject }
            .filter { $0.eClass.name == "Contact" }
        return contacts.compactMap { $0.eGet("fullName") as? String }.sorted()
    }

    @Test("runs the module with native helpers and parameters")
    func runsWithHelpersAndParameters() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let (packages, source) = try await load(fixture)

        let step = TransformationStep(
            moduleURL: fixture.transformation, metamodels: packages, sourceAliases: ["IN": source],
            parameters: ["greeting": "Hi"], nativeHelpers: [Self.shout])
        let targets = try await step.run()

        #expect(Array(targets.keys) == ["OUT"])
        #expect(try await fullNames(in: targets["OUT"]) == ["Hi ADA", "Hi ALAN"])
    }

    @Test("uses the declared default of a parameter and a registry of metamodels")
    func defaultParameter() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let (packages, source) = try await load(fixture)

        let step = TransformationStep(
            moduleURL: fixture.transformation, metamodels: ATLMetamodelRegistry(packages: packages),
            nativeHelpers: [Self.shout])
        let targets = try await step.run(sources: ["IN": source, "UNUSED": source])

        #expect(try await fullNames(in: targets["OUT"]) == ["Dear ADA", "Dear ALAN"])
    }

    @Test("gives targets transient URIs unless a location is given")
    func targetURIs() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let (packages, source) = try await load(fixture)
        let location = fixture.directory.appendingPathComponent("contacts.xmi")

        let transient = try await TransformationStep(
            moduleURL: fixture.transformation, metamodels: packages, sourceAliases: ["IN": source],
            nativeHelpers: [Self.shout]
        ).run()
        let placed = try await TransformationStep(
            moduleURL: fixture.transformation, metamodels: packages, sourceAliases: ["IN": source],
            targetAliases: ["OUT"], nativeHelpers: [Self.shout], targetURIs: ["OUT": location]
        ).run()

        #expect(transient["OUT"]?.uri == "\(TransformationStep.transientScheme):OUT")
        #expect(placed["OUT"]?.uri == location.absoluteString)
    }

    @Test("reports a module that cannot be read")
    func unreadableModule() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let missing = fixture.directory.appendingPathComponent("Missing.atl")

        await #expect {
            _ = try await TransformationStep(moduleURL: missing).run()
        } throws: { error in
            guard case ModelPipelineError.transformationUnreadable(let path, _) = error else { return false }
            return path == missing.path
        }
    }

    @Test("reports a failing run with the name of the module")
    func failingRun() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let (packages, _) = try await load(fixture)

        await #expect {
            _ = try await TransformationStep(moduleURL: fixture.transformation, metamodels: packages).run()
        } throws: { error in
            guard case ModelPipelineError.transformationFailed(let module, _) = error else { return false }
            return module == "People2Contacts"
        }
    }

    @Test("describes its errors")
    func errorDescriptions() {
        #expect(ModelPipelineError.transformationUnreadable("a.atl", "why").description
            == "The transformation 'a.atl' cannot be read: why")
        #expect(ModelPipelineError.transformationFailed("M", "why").description == "The transformation 'M' failed: why")
        #expect(ModelPipelineError.templatesUnreadable("a.mtl", "why").description
            == "The templates 'a.mtl' cannot be read: why")
        #expect(ModelPipelineError.noTemplates("M").description == "The module 'M' holds no templates")
        #expect(ModelPipelineError.templateNotFound("t", "M").description
            == "The template 't' is not a template of the module 'M'")
        #expect(ModelPipelineError.unknownModel("x", ["b", "a"]).description
            == "The pipeline holds no model named 'x'; it holds: a, b")
        #expect(ModelPipelineError.unknownModel("x", []).localizedDescription
            == "The pipeline holds no model named 'x'; it holds: none")
    }
}
