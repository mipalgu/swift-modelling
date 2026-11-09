//
// ProjectOptionKeysCommandTests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for the configuration keys of the project-wide options of `swift-ecore`: the reference
/// style of `convert`, the generator model settings of `genmodel` and the strictness of
/// `validate`.
@Suite("swift-ecore - configuration keys of project-wide options", .serialized)
struct ProjectOptionKeysCommandTests {
    /// The same-document reference of the classifier model in the plain style.
    static let plainReference = "type=\"cls:DataType /0/@classifiers.0\""

    /// The same-document reference of the classifier model in the encoded style.
    static let encodedReference = "#/0/@classifiers.0"

    // MARK: - convert

    /// Converts the two-root classifier model to XMI from the working directory of a repository.
    ///
    /// - Parameters:
    ///   - workspace: The repository.
    ///   - extra: The arguments after the metamodel.
    /// - Returns: The result of the command and the text written.
    @MainActor
    private func convert(
        in workspace: ReadingConfigurationTests.Workspace, _ extra: [String] = []
    ) async throws -> (result: SubprocessResult, text: String) {
        let metamodel = try loadTestResource(named: "classifiers.ecore", subdirectory: "ecore")
        let model = try loadTestResource(named: "classifiers-two-roots.xmi", subdirectory: "xmi")
        let output = workspace.root.appendingPathComponent("out.xmi")
        try? FileManager.default.removeItem(at: output)
        let result = try await workspace.run(
            "convert", [model.path, output.path, "--metamodel", metamodel.path, "--force"] + extra)
        return (result, (try? String(contentsOf: output, encoding: .utf8)) ?? "")
    }

    @Test("writes references in the style of the configuration file, unless the command line says otherwise")
    @MainActor
    func referenceStyle() async throws {
        let workspace = try ReadingConfigurationTests.Workspace()
        defer { workspace.remove() }
        let plain = try await convert(in: workspace)
        try workspace.write(#"{ "reference-style": "plain" }"#)

        let configured = try await convert(in: workspace)
        let overridden = try await convert(in: workspace, ["--reference-style", "encoded"])
        let ignored = try await convert(in: workspace, ["--no-config"])

        #expect(configured.result.succeeded, "\(configured.result.stderr)")
        #expect(configured.text.contains(Self.plainReference), "\(configured.text)")
        #expect(overridden.text.contains(Self.encodedReference), "\(overridden.text)")
        #expect(overridden.text == plain.text)
        #expect(ignored.text == plain.text)
        #expect(ignored.result.stdout == plain.result.stdout)
        #expect(ignored.result.stderr == plain.result.stderr)
    }

    @Test("rejects a reference style that is not one, naming the key and the accepted values")
    @MainActor
    func invalidReferenceStyle() async throws {
        let workspace = try ReadingConfigurationTests.Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "reference-style": "fancy" }"#)

        let (result, _) = try await convert(in: workspace)

        #expect(result.exitCode == 1)
        for text in ["'reference-style'", "'fancy'", "encoded", "plain"] {
            #expect(result.stderr.contains(text), "\(text) is missing from: \(result.stderr)")
        }
    }

    // MARK: - validate

    @Test("fails on warnings as the strict key says, unless the command line says otherwise")
    @MainActor
    func strict() async throws {
        let workspace = try ReadingConfigurationTests.Workspace()
        defer { workspace.remove() }
        let metamodel = try loadTestResource(named: "staff.ecore", subdirectory: "ecore").path
        let arguments = [metamodel, "--check-abstract-classes"]
        let plain = try await workspace.run("validate", arguments)
        try workspace.write(#"{ "strict": true }"#)

        let configured = try await workspace.run("validate", arguments)
        let overridden = try await workspace.run("validate", arguments + ["--no-strict"])

        #expect(plain.succeeded, "\(plain.stdout)\(plain.stderr)")
        #expect(!configured.succeeded)
        #expect(configured.stderr.contains("(strict: warnings count as errors)"), "\(configured.stderr)")
        #expect(overridden.succeeded, "\(overridden.stdout)\(overridden.stderr)")
        #expect(overridden.stdout == plain.stdout)
    }

    @Test("requires explicit values as the configuration file says, unless the command line says otherwise")
    @MainActor
    func requireExplicitValues() async throws {
        let workspace = try ReadingConfigurationTests.Workspace()
        defer { workspace.remove() }
        let metamodel = try loadTestResource(named: "shelf.ecore", subdirectory: "ecore").path
        let model = try loadTestResource(named: "shelf-unset.xmi", subdirectory: "xmi").path
        let arguments = [model, "--metamodel", metamodel]
        try workspace.write(#"{ "require-explicit-values": true }"#)

        let configured = try await workspace.run("validate", arguments)
        let overridden = try await workspace.run("validate", arguments + ["--no-require-explicit-values"])
        let ignored = try await workspace.run("validate", arguments + ["--no-config"])

        #expect(!configured.succeeded)
        #expect(configured.stdout.contains("Feature 'kind' needs at least 1 value(s) but has 0"), "\(configured.stdout)")
        #expect(overridden.succeeded, "\(overridden.stdout)\(overridden.stderr)")
        #expect(ignored.succeeded, "\(ignored.stdout)\(ignored.stderr)")
    }

    @Test("rejects a strictness that is not a boolean")
    @MainActor
    func invalidStrict() async throws {
        let workspace = try ReadingConfigurationTests.Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "strict": "yes" }"#)

        let result = try await workspace.run("validate", [workspace.notes])

        #expect(result.exitCode == 1)
        #expect(result.stderr.contains("'strict'"), "\(result.stderr)")
        #expect(result.stderr.contains("true or false"), "\(result.stderr)")
    }

    // MARK: - genmodel

    /// Writes the generator model of the families fixture from the working directory.
    ///
    /// - Parameters:
    ///   - workspace: The repository.
    ///   - extra: The arguments after the model.
    /// - Returns: The result of the command and the text of the generator model, if any.
    @MainActor
    private func genModel(
        in workspace: ReadingConfigurationTests.Workspace, _ extra: [String] = []
    ) async throws -> (result: SubprocessResult, text: String?) {
        let project = workspace.root.appendingPathComponent("families")
        if !FileManager.default.fileExists(atPath: project.path) {
            try FileManager.default.copyItem(
                at: ConfigurationTests.fixtureRoot.appendingPathComponent("families"), to: project)
        }
        let output = project.appendingPathComponent("model/families.genmodel")
        try? FileManager.default.removeItem(at: output)
        let result = try await workspace.run(
            "genmodel", [project.appendingPathComponent("model/families.ecore").path] + extra)
        return (result, try? String(contentsOf: output, encoding: .utf8))
    }

    @Test("writes the generator model settings of the configuration file, unless the command line says otherwise")
    @MainActor
    func genModelSettings() async throws {
        let workspace = try ReadingConfigurationTests.Workspace()
        defer { workspace.remove() }
        let plain = try await genModel(in: workspace)
        try workspace.write(
            """
            { "base-package": "org.example", "prefix": ["Fam"], "jdk-level": "21.0", "defaults": "wizard",
              "root-extends-class": "org.example.Base", "import-organizing": false }
            """)

        let configured = try await genModel(in: workspace)
        let overridden = try await genModel(
            in: workspace,
            ["--base-package", "com.example", "--prefix", "Kin", "--jdk-level", "17.0", "--defaults", "headless",
             "--root-extends-class", "com.example.Root", "--import-organizing"])
        let ignored = try await genModel(in: workspace, ["--no-config"])

        #expect(configured.result.succeeded, "\(configured.result.stderr)")
        let text = configured.text ?? ""
        for expected in [
            #"basePackage="org.example""#, #"prefix="Fam""#, #"complianceLevel="21.0""#,
            #"rootExtendsClass="org.example.Base""#, #"operationReflection="true""#,
        ] {
            #expect(text.contains(expected), "\(expected) is missing from: \(text)")
        }
        #expect(text.contains(#"importOrganizing="false""#) || !text.contains(#"importOrganizing="true""#), "\(text)")
        let other = overridden.text ?? ""
        for expected in [
            #"basePackage="com.example""#, #"prefix="Kin""#, #"complianceLevel="17.0""#,
            #"rootExtendsClass="com.example.Root""#,
        ] {
            #expect(other.contains(expected), "\(expected) is missing from: \(other)")
        }
        #expect(!other.contains("org.example"), "\(other)")
        #expect(ignored.text == plain.text)
    }

    @Test("rejects generator model settings of the wrong kind, naming the key")
    @MainActor
    func invalidGenModelSettings() async throws {
        let workspace = try ReadingConfigurationTests.Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "prefix": "Fam" }"#)

        let (result, text) = try await genModel(in: workspace)

        #expect(result.exitCode == 1)
        #expect(text == nil)
        #expect(result.stderr.contains("'prefix'"), "\(result.stderr)")
        #expect(result.stderr.contains("a list of strings"), "\(result.stderr)")
    }
}
