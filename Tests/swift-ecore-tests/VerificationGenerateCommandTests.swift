//
// VerificationGenerateCommandTests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@Suite("swift-ecore generate - verification targets and model exports")
struct VerificationGenerateCommandTests {
    /// The lending fixtures shared with the generator library tests.
    private static let lendingRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ModellingGeneratorsTests/Resources/lending")

    /// The lending metamodel.
    private static let metamodel = lendingRoot.appendingPathComponent("lending.ecore")

    /// A model of the lending metamodel that satisfies its invariants.
    private static let model = lendingRoot.appendingPathComponent("lending.xmi")

    /// A model of the lending metamodel that violates some of its invariants.
    private static let violations = lendingRoot.appendingPathComponent("violations.xmi")

    /// Compares a generated file with its reviewed expectation.
    ///
    /// - Parameters:
    ///   - name: The file name, the same in the output and the expectations.
    ///   - target: The verification target, which names the directory of the expectations.
    ///   - output: The output directory.
    private func expectMatches(_ name: String, target: String, in output: URL) throws {
        let generated = output.appendingPathComponent(name)
        #expect(FileManager.default.fileExists(atPath: generated.path), "\(name) was not generated")
        let expected = Self.lendingRoot.appendingPathComponent("expected/\(target)/\(name)")
        #expect(
            try String(contentsOf: generated, encoding: .utf8) == String(contentsOf: expected, encoding: .utf8),
            "\(name) differs from the expectation")
    }

    @Test("the help lists the verification targets and the model option")
    @MainActor
    func helpListsTargets() async throws {
        let result = try await executeSwiftEcore(command: "generate", arguments: ["--help"])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(result.stdout.contains("Verification targets: alloy, eventb, lean, tla"))
        #expect(result.stdout.contains("--model <file.xmi>"))
        #expect(result.stdout.contains("Languages with a template set: c, cpp, java, swift"))
    }

    @Test("exports a metamodel to each verification target", arguments: [
        ("alloy", ["lending.als"]), ("tla", ["lending.tla"]), ("eventb", ["lending_ctx.bucx", "lending_machine.bumx"]),
        ("lean", ["Lending.lean"]),
    ])
    @MainActor
    func exportsMetamodel(target: String, files: [String]) async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }

        let result = try await executeSwiftEcore(
            command: "generate", arguments: [Self.metamodel.path, "--language", target, "-o", scratch.path])

        #expect(result.succeeded, "\(result.stderr)")
        let noun = files.count == 1 ? "file" : "files"
        #expect(result.stdout.contains("Generated \(files.count) \(noun) in:"))
        for name in files { try expectMatches(name, target: target, in: scratch) }
    }

    @Test("exports models together with their metamodel")
    @MainActor
    func exportsModels() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                Self.metamodel.path, "--language", "tla", "--model", Self.model.path, "--model", Self.violations.path,
                "-o", scratch.path,
            ])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(result.stdout.contains("Generated 5 files in:"))
        for name in [
            "lending.tla", "lending_instance.tla", "lending_instance.cfg", "violations_instance.tla",
            "violations_instance.cfg",
        ] {
            try expectMatches(name, target: "tla", in: scratch)
        }
    }

    @Test("exports a model of the Ecore models of a generator model")
    @MainActor
    func exportsModelOfGenModel() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let project = scratch.appendingPathComponent("lending/model")
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        let ecore = project.appendingPathComponent("lending.ecore")
        try FileManager.default.copyItem(at: Self.metamodel, to: ecore)
        let created = try await executeSwiftEcore(command: "genmodel", arguments: [ecore.path])
        #expect(created.succeeded, "\(created.stderr)")
        let output = scratch.appendingPathComponent("eventb")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                project.appendingPathComponent("lending.genmodel").path, "--language", "eventb", "--model",
                Self.model.path, "-o", output.path,
            ])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(result.stdout.contains("Generated 4 files in:"))
        for name in ["lending_ctx.bucx", "lending_machine.bumx", "lending_instance_ctx.bucx", "lending_instance_machine.bumx"] {
            try expectMatches(name, target: "eventb", in: output)
        }
    }

    @Test("verbose output names each exported model")
    @MainActor
    func verboseNamesModels() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [Self.metamodel.path, "--language", "lean", "--model", Self.model.path, "-o", scratch.path, "-v"])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(result.stdout.contains("Exporting model: \(Self.model.path)"))
        try expectMatches("LendingInstance.lean", target: "lean", in: scratch)
    }

    @Test("rejects models for a language that cannot export them, before writing anything")
    @MainActor
    func rejectsModelsForCodeLanguage() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [Self.metamodel.path, "--language", "java", "--model", Self.model.path, "-o", output.path])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("The java templates cannot export models"))
        #expect(result.stderr.contains("alloy, eventb, lean, tla"))
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test("reports a model that does not exist")
    @MainActor
    func reportsMissingModel() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let missing = scratch.appendingPathComponent("missing.xmi").path

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [Self.metamodel.path, "--language", "alloy", "--model", missing, "-o", scratch.path])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("Input file not found: \(missing)"))
    }

    @Test("lists the verification targets after the code languages for an unknown language")
    @MainActor
    func unknownLanguageListsTargets() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }

        let result = try await executeSwiftEcore(
            command: "generate", arguments: [Self.metamodel.path, "--language", "z3", "-o", scratch.path])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("Supported: c, cpp, java, swift, alloy, eventb, lean, tla"))
    }
}
