import Foundation
import Testing

@Suite("swift-ecore genmodel - Generator models from Ecore models")
struct GenModelCommandTests {
    /// The fixtures shared with the generator library tests.
    private static let fixtureRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ModellingGeneratorsTests/Resources")

    /// Copies a fixture project into a scratch directory.
    ///
    /// - Parameter name: The name of the fixture directory.
    /// - Returns: The scratch directory that contains the project directory.
    private func scratchProject(_ name: String) throws -> (scratch: URL, project: URL) {
        let scratch = try createTemporaryDirectory()
        let project = scratch.appendingPathComponent(name)
        try FileManager.default.copyItem(
            at: Self.fixtureRoot.appendingPathComponent(name), to: project)
        try FileManager.default.removeItem(at: project.appendingPathComponent("expected"))
        return (scratch, project)
    }

    private func expected(_ name: String, _ file: String) throws -> String {
        try String(
            contentsOf: Self.fixtureRoot.appendingPathComponent("\(name)/expected/\(file)"),
            encoding: .utf8)
    }

    @Test("writes the generator model beside the Ecore model and matches the reviewed expectation")
    @MainActor
    func writesBesideModel() async throws {
        let (scratch, project) = try scratchProject("library")
        defer { cleanupTemporaryDirectory(scratch) }
        let ecore = project.appendingPathComponent("model/library.ecore")

        let result = try await executeSwiftEcore(
            command: "genmodel",
            arguments: [
                ecore.path, "--base-package", "org.example", "--copyright",
                "Copyright 2026 Example Pty Ltd",
            ])

        #expect(result.succeeded)
        let genModel = project.appendingPathComponent("model/library.genmodel")
        #expect(result.stdout.contains("Wrote"))
        #expect(
            try String(contentsOf: genModel, encoding: .utf8) == expected("library", "library.genmodel"))
    }

    @Test("writes to the file named by --output")
    @MainActor
    func writesToOutput() async throws {
        let (scratch, project) = try scratchProject("families")
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("elsewhere/kinship.genmodel")

        let result = try await executeSwiftEcore(
            command: "genmodel",
            arguments: [project.appendingPathComponent("model/families.ecore").path, "-o", output.path])

        #expect(result.succeeded)
        let text = try String(contentsOf: output, encoding: .utf8)
        #expect(text.contains(#"modelName="Kinship""#))
        #expect(text.contains("<foreignModel>../families/model/families.ecore</foreignModel>"))
        #expect(
            !FileManager.default.fileExists(
                atPath: project.appendingPathComponent("model/families.genmodel").path))
    }

    @Test("passes the settings of the importer options to the generator model")
    @MainActor
    func passesOptions() async throws {
        let (scratch, project) = try scratchProject("nested")
        defer { cleanupTemporaryDirectory(scratch) }

        let result = try await executeSwiftEcore(
            command: "genmodel",
            arguments: [
                project.appendingPathComponent("model/company.ecore").path,
                "--base-package", "org.acme", "--prefix", "Firm", "--prefix", "people=Staff",
                "--model-project", "acme", "--model-plugin-id", "org.acme.model",
                "--model-directory", "/acme/gen", "--jdk-level", "21.0",
            ])

        #expect(result.succeeded)
        let text = try String(
            contentsOf: project.appendingPathComponent("model/company.genmodel"), encoding: .utf8)
        #expect(text.contains(#"<genPackages prefix="Firm" basePackage="org.acme""#))
        #expect(text.contains(#"<nestedGenPackages prefix="Staff""#))
        #expect(text.contains(#"modelPluginID="org.acme.model""#))
        #expect(text.contains(#"modelDirectory="/acme/gen""#))
        #expect(text.contains(#"complianceLevel="21.0""#))
    }

    @Test("derives the project from the folder layout")
    @MainActor
    func derivesProject() async throws {
        let (scratch, project) = try scratchProject("organisation")
        defer { cleanupTemporaryDirectory(scratch) }

        let result = try await executeSwiftEcore(
            command: "genmodel",
            arguments: [project.appendingPathComponent("model/organisation.ecore").path])

        #expect(result.succeeded)
        let text = try String(
            contentsOf: project.appendingPathComponent("model/organisation.genmodel"),
            encoding: .utf8)
        #expect(text.contains(#"modelDirectory="/organisation/src""#))
    }

    @Test("reports progress and a summary in verbose mode")
    @MainActor
    func verboseOutput() async throws {
        let (scratch, project) = try scratchProject("library")
        defer { cleanupTemporaryDirectory(scratch) }

        let result = try await executeSwiftEcore(
            command: "genmodel",
            arguments: [project.appendingPathComponent("model/library.ecore").path, "--verbose"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("Loading library.ecore"))
        #expect(result.stdout.contains("Transforming library.ecore (1 of 1)"))
        #expect(result.stdout.contains("Writing library.genmodel"))
        #expect(result.stdout.contains("classes: 5"))
    }

    @Test("is quiet unless asked to be verbose")
    @MainActor
    func quietByDefault() async throws {
        let (scratch, project) = try scratchProject("library")
        defer { cleanupTemporaryDirectory(scratch) }

        let result = try await executeSwiftEcore(
            command: "genmodel",
            arguments: [project.appendingPathComponent("model/library.ecore").path])

        #expect(result.succeeded)
        #expect(!result.stdout.contains("Loading"))
    }

    @Test("generates identical files on every run")
    @MainActor
    func isDeterministic() async throws {
        let (scratch, project) = try scratchProject("nested")
        defer { cleanupTemporaryDirectory(scratch) }
        let ecore = project.appendingPathComponent("model/company.ecore").path
        let output = scratch.appendingPathComponent("out.genmodel")

        let one = try await executeSwiftEcore(command: "genmodel", arguments: [ecore, "-o", output.path])
        let firstRun = try Data(contentsOf: output)
        try FileManager.default.removeItem(at: output)
        let two = try await executeSwiftEcore(command: "genmodel", arguments: [ecore, "-o", output.path])
        let secondRun = try Data(contentsOf: output)

        #expect(one.succeeded && two.succeeded)
        #expect(firstRun == secondRun)
    }

    @Test("combines several Ecore models into one generator model")
    @MainActor
    func severalModels() async throws {
        let (scratch, library) = try scratchProject("library")
        defer { cleanupTemporaryDirectory(scratch) }
        let families = scratch.appendingPathComponent("families")
        try FileManager.default.copyItem(
            at: Self.fixtureRoot.appendingPathComponent("families"), to: families)
        try FileManager.default.removeItem(at: families.appendingPathComponent("expected"))
        let output = scratch.appendingPathComponent("all.genmodel")

        let result = try await executeSwiftEcore(
            command: "genmodel",
            arguments: [
                library.appendingPathComponent("model/library.ecore").path,
                families.appendingPathComponent("model/families.ecore").path, "-o", output.path,
            ])

        #expect(result.succeeded)
        let text = try String(contentsOf: output, encoding: .utf8)
        #expect(text.components(separatedBy: "<genPackages ").count == 3)
        #expect(text.contains("<foreignModel>library/model/library.ecore</foreignModel>"))
        #expect(text.contains("<foreignModel>families/model/families.ecore</foreignModel>"))
    }

    @Test("keeps the settings of the generator model given to --reload")
    @MainActor
    func reloadsSettings() async throws {
        let (scratch, project) = try scratchProject("families")
        defer { cleanupTemporaryDirectory(scratch) }
        let ecore = project.appendingPathComponent("model/families.ecore").path
        let genModel = project.appendingPathComponent("model/families.genmodel")
        let first = try await executeSwiftEcore(command: "genmodel", arguments: [ecore])
        #expect(first.succeeded)
        let edited = try String(contentsOf: genModel, encoding: .utf8)
            .replacingOccurrences(of: #"modelName="Families""#, with: #"modelName="Kin""#)
        try edited.write(to: genModel, atomically: true, encoding: .utf8)

        let result = try await executeSwiftEcore(
            command: "genmodel", arguments: [ecore, "--reload", genModel.path])

        #expect(result.succeeded)
        #expect(try String(contentsOf: genModel, encoding: .utf8).contains(#"modelName="Kin""#))
    }

    @Test("fails with a clear message for a missing Ecore model")
    @MainActor
    func missingModel() async throws {
        let result = try await executeSwiftEcore(
            command: "genmodel", arguments: ["/nonexistent/swift-modelling/none.ecore"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("does not exist"))
    }

    @Test("fails with a clear message for an unsupported compliance level")
    @MainActor
    func unsupportedLevel() async throws {
        let (scratch, project) = try scratchProject("families")
        defer { cleanupTemporaryDirectory(scratch) }

        let result = try await executeSwiftEcore(
            command: "genmodel",
            arguments: [project.appendingPathComponent("model/families.ecore").path, "--jdk-level", "99"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("not supported"))
        #expect(result.stderr.contains("17.0"))
    }

    @Test("fails with a clear message for a generator model that cannot be reloaded")
    @MainActor
    func missingReload() async throws {
        let (scratch, project) = try scratchProject("families")
        defer { cleanupTemporaryDirectory(scratch) }

        let result = try await executeSwiftEcore(
            command: "genmodel",
            arguments: [
                project.appendingPathComponent("model/families.ecore").path, "--reload",
                scratch.appendingPathComponent("none.genmodel").path,
            ])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("cannot be reloaded"))
    }

    @Test("requires at least one Ecore model")
    @MainActor
    func requiresModel() async throws {
        let result = try await executeSwiftEcore(command: "genmodel", arguments: [])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("model.ecore"))
    }

    @Test("documents its options in the help")
    @MainActor
    func helpListsOptions() async throws {
        let result = try await executeSwiftEcore(command: "genmodel", arguments: ["--help"])

        #expect(result.succeeded)
        for option in [
            "--base-package", "--prefix", "--model-project", "--model-plugin-id",
            "--model-directory", "--copyright", "--jdk-level", "--reload", "--output", "--verbose",
        ] {
            #expect(result.stdout.contains(option), "Missing \(option)")
        }
    }
}
