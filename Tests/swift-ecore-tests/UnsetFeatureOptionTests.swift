import Foundation
import Testing

/// Tests for `swift-ecore --unset-features`, which chooses how the transformation and the
/// templates read structural features that a model does not set.
@Suite("swift-ecore - reading unset features")
struct UnsetFeatureOptionTests {
    /// The long name of the option.
    private static let option = "--unset-features"

    /// The fixtures shared with the generator library tests.
    private static let fixtureRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ModellingGeneratorsTests/Resources")

    /// Writes the generator model of the families fixture with extra arguments.
    ///
    /// - Parameter extra: The arguments after the model.
    /// - Returns: The result of the command and the text of the generator model, if any.
    @MainActor
    private func genModel(_ extra: [String]) async throws -> (result: SubprocessResult, text: String?) {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let project = scratch.appendingPathComponent("families")
        try FileManager.default.copyItem(at: Self.fixtureRoot.appendingPathComponent("families"), to: project)
        let ecore = project.appendingPathComponent("model/families.ecore")
        let output = project.appendingPathComponent("model/families.genmodel")
        try? FileManager.default.removeItem(at: output)

        let result = try await executeSwiftEcore(command: "genmodel", arguments: [ecore.path] + extra)
        return (result, try? String(contentsOf: output, encoding: .utf8))
    }

    @Test("describes the option in the help of generate and genmodel", arguments: ["generate", "genmodel"])
    @MainActor
    func help(command: String) async throws {
        let result = try await executeSwiftEcore(command: command, arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains(Self.option))
        #expect(result.stdout.contains("undefined"))
        #expect(result.stdout.contains("Eclipse Modeling Framework"))
    }

    @Test("writes the same generator model with --unset-features defaults as without the option")
    @MainActor
    func explicitDefaultsMatchDefault() async throws {
        let (plain, plainText) = try await genModel([])
        let (explicit, explicitText) = try await genModel([Self.option, "defaults"])

        #expect(plain.succeeded, "\(plain.stdout)\(plain.stderr)")
        #expect(explicit.succeeded, "\(explicit.stdout)\(explicit.stderr)")
        #expect(plainText != nil)
        #expect(explicitText == plainText)
    }

    @Test("rejects a value that is not a mode", arguments: ["generate", "genmodel"])
    @MainActor
    func rejectsUnknownMode(command: String) async throws {
        let result = try await executeSwiftEcore(command: command, arguments: [Self.option, "sometimes"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("sometimes"))
    }
}
