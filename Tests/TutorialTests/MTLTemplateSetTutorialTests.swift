//
// MTLTemplateSetTutorialTests.swift
// TutorialTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Checks the steps of the MTL tutorial that package a generator as a template set.
@Suite("MTL Tutorials - template sets")
struct MTLTemplateSetTutorialTests {
    /// The directory that holds the files of the tutorial steps.
    let tutorialResourcesPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources/SwiftModelling/SwiftModelling.docc/Resources")

    /// The text of a step file.
    private func step(_ name: String) throws -> String {
        try String(contentsOf: tutorialResourcesPath.appendingPathComponent(name), encoding: .utf8)
    }

    @Test("Tutorial 08 Step 4: The descriptor names the module and template of the generator")
    func descriptor() throws {
        let data = Data(try step("mtl-step-41-templateset.json").utf8)
        let descriptor = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(descriptor["name"] as? String == "SwiftGenerator")
        #expect(descriptor["mainModule"] as? String == "SwiftGenerator")
        #expect(descriptor["mainTemplate"] as? String == "main")
        let module = try step("mtl-step-39-class-helper.mtl")
        #expect(module.contains("[module SwiftGenerator("))
        #expect(module.contains("[template main(pkg : EPackage)]"))
    }

    @Test("Tutorial 08 Step 5: The set runs with --template-set instead of a template file")
    func command() throws {
        let commands = try step("mtl-step-42-generate-template-set.sh")
        #expect(commands.contains("swift-mtl generate --template-set SwiftGenerator/"))
        #expect(commands.contains("--template-path my-changes/"))
        #expect(!commands.contains("SwiftGenerator.mtl --"))
    }
}
