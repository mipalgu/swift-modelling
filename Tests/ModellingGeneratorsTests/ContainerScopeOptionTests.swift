//
// ContainerScopeOptionTests.swift
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

/// Tests for the container lookup scope that generation and import options give the resource
/// sets into which the pipelines load their models.
@Suite("Generation options - container lookup scope")
struct ContainerScopeOptionTests {
    @Test("leaves the container lookup scope unconfigured by default")
    func unconfiguredByDefault() {
        #expect(GenerationOptions(mtlOptions: .standard).containerLookupScope == nil)
        #expect(GenerationOptions(mtlOptions: .legacy).containerLookupScope == nil)
        #expect(GenModelImportOptions(atlOptions: .standard).containerLookupScope == nil)
        #expect(GenModelImportOptions(atlOptions: .legacy).containerLookupScope == nil)
    }

    @Test("compares options by their container lookup scope")
    func equality() {
        var scoped = GenerationOptions(mtlOptions: .standard)
        scoped.containerLookupScope = .thisResource
        #expect(scoped != GenerationOptions(mtlOptions: .standard))
        var imports = GenModelImportOptions(atlOptions: .standard)
        imports.containerLookupScope = .anyResource
        #expect(imports != GenModelImportOptions(atlOptions: .standard))
    }

    @Test("configures the resource set of an import with the scope of the options", arguments: [nil] + ContainerLookupScope.allCases.map(Optional.some))
    @MainActor
    func importResourceSet(scope: ContainerLookupScope?) async throws {
        let project = try FixtureProject.make("library")
        defer { project.remove() }
        var options = GenModelImportOptions(atlOptions: .standard)
        options.containerLookupScope = scope

        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [project.model("library.ecore")], options: options)

        #expect(await result.resourceSet.defaultContainerLookupScope == scope)
        #expect(await result.resource.containerLookupScope == scope ?? .builtInDefault)
    }
}
