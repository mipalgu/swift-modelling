import ArgumentParser
import Foundation
import Testing

/// Tests for `swift-atl transform --sub-rule-precedence`, which chooses which rule transforms a
/// source element that a guarded rule and an unguarded rule extending it both match: the guarded
/// rule by default, as in Eclipse ATL, and the extending rule with `extending-rule` or the legacy
/// preset.
@Suite("swift-atl - sub-rule precedence")
struct SubRulePrecedenceTests {
    /// The long name of the option.
    private static let option = "--sub-rule-precedence"

    /// The long name of the option that chooses the preset.
    private static let semanticsOption = "--semantics"

    /// The name of the configuration file.
    private static let configurationFile = ".swift-modelling.json"

    /// The name that a finished task has when the guarded rule transforms it.
    private static let guardedName = "name=\"done reviewing\""

    /// The name that a finished task has when the rule extending the guarded rule transforms it.
    private static let extendingName = "name=\"any reviewing\""

    /// A transformation with a rule that has a guard, and a rule without one that extends it.
    static let transformation = """
        -- @path Tasks=/Tasks.ecore
        -- @path Notes=/Notes.ecore

        module PrecedenceNotes;
        create OUT : Notes from IN : Tasks;

        rule DoneTask {
            from t : Tasks!Task (t.done)
            to n : Notes!Note (name <- 'done ' + t.name)
        }

        rule AnyTask extends DoneTask {
            from t : Tasks!Task
            to n : Notes!Note (name <- 'any ' + t.name)
        }
        """

    /// A directory with the metamodels, the transformation and the source model.
    struct Workspace {
        /// The temporary directory.
        let root: URL

        /// Creates the directory, marked as the root of a repository.
        ///
        /// - Throws: An error if a file cannot be written.
        init() throws {
            root = try createTemporaryDirectory()
            try FileManager.default.createDirectory(
                at: root.appendingPathComponent(".git"), withIntermediateDirectories: true)
            try write(SiblingRuleConflictTests.tasks, to: "Tasks.ecore")
            try write(SiblingRuleConflictTests.notes, to: "Notes.ecore")
            try write(SiblingRuleConflictTests.model, to: "tasks.xmi")
            try write(SubRulePrecedenceTests.transformation, to: "PrecedenceNotes.atl")
        }

        /// Writes a file at a path relative to the directory.
        ///
        /// - Parameters:
        ///   - text: The contents.
        ///   - path: The path, relative to the directory.
        /// - Throws: An error if the file cannot be written.
        func write(_ text: String, to path: String) throws {
            try text.write(to: root.appendingPathComponent(path), atomically: true, encoding: .utf8)
        }
    }

    /// Runs the transformation from the workspace directory.
    ///
    /// - Parameters:
    ///   - workspace: The workspace.
    ///   - target: The name of the target model.
    ///   - extra: The arguments after the models.
    /// - Returns: The result of the command and the text of the target model, if any.
    @MainActor
    private func transform(
        _ workspace: Workspace, target: String = "notes.xmi", extra: [String] = []
    ) async throws -> (result: SubprocessResult, text: String?) {
        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                "PrecedenceNotes.atl", "--metamodel-path", workspace.root.path, "--source", "IN=tasks.xmi",
                "--target", "OUT=\(target)",
            ] + extra,
            workingDirectory: workspace.root)
        return (result, try? String(contentsOf: workspace.root.appendingPathComponent(target), encoding: .utf8))
    }

    /// Checks that the guarded rule transformed the finished task.
    ///
    /// - Parameters:
    ///   - result: The result of the command.
    ///   - text: The text of the target model.
    private func expectGuarded(_ result: SubprocessResult, _ text: String?) {
        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text?.contains(Self.guardedName) == true, "\(text ?? "")")
        #expect(text?.contains(Self.extendingName) == false, "\(text ?? "")")
    }

    /// Checks that the rule extending the guarded rule transformed the finished task.
    ///
    /// - Parameters:
    ///   - result: The result of the command.
    ///   - text: The text of the target model.
    private func expectExtending(_ result: SubprocessResult, _ text: String?) {
        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text?.contains(Self.extendingName) == true, "\(text ?? "")")
        #expect(text?.contains(Self.guardedName) == false, "\(text ?? "")")
    }

    @Test("lets the guarded rule transform the element by default and with eclipse", arguments: [[], [option, "eclipse"]])
    @MainActor
    func guardedByDefault(extra: [String]) async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await transform(workspace, extra: extra)

        expectGuarded(result, text)
    }

    @Test("lets the extending rule transform the element with extending-rule")
    @MainActor
    func extendingOnCommandLine() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await transform(workspace, extra: [Self.option, "extending-rule"])

        expectExtending(result, text)
    }

    @Test("lets the legacy preset choose the extending rule")
    @MainActor
    func legacyPreset() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await transform(workspace, extra: [Self.semanticsOption, "legacy"])

        expectExtending(result, text)
    }

    @Test("lets the flag override the preset in either direction")
    @MainActor
    func flagOverridesPreset() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (eclipse, eclipseText) = try await transform(
            workspace, target: "a.xmi", extra: [Self.semanticsOption, "legacy", Self.option, "eclipse"])
        let (extending, extendingText) = try await transform(
            workspace, target: "b.xmi", extra: [Self.semanticsOption, "standard", Self.option, "extending-rule"])

        expectGuarded(eclipse, eclipseText)
        expectExtending(extending, extendingText)
    }

    @Test("takes the value of the configuration file, which the command line overrides")
    @MainActor
    func configurationKey() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }
        try workspace.write(#"{ "sub-rule-precedence": "extending-rule" }"#, to: Self.configurationFile)

        let (configured, configuredText) = try await transform(workspace, target: "configured.xmi")
        let (overridden, overriddenText) = try await transform(
            workspace, target: "overridden.xmi", extra: [Self.option, "eclipse"])
        let (ignored, ignoredText) = try await transform(workspace, target: "ignored.xmi", extra: ["--no-config"])

        expectExtending(configured, configuredText)
        expectGuarded(overridden, overriddenText)
        expectGuarded(ignored, ignoredText)
    }

    @Test("lets the key of the file override the preset")
    @MainActor
    func keyOverridesPreset() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }
        try workspace.write(#"{ "semantics": "legacy", "sub-rule-precedence": "eclipse" }"#, to: Self.configurationFile)

        let (result, text) = try await transform(workspace)

        expectGuarded(result, text)
    }

    @Test("rejects a value that is not a sub-rule precedence, on the command line or in the file")
    @MainActor
    func rejectsUnknownValue() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (fromCommandLine, commandLineText) = try await transform(workspace, extra: [Self.option, "overriding"])
        try workspace.write(#"{ "sub-rule-precedence": "overriding" }"#, to: Self.configurationFile)
        let (fromFile, fileText) = try await transform(workspace)

        #expect(fromCommandLine.exitCode == ExitCode.validationFailure.rawValue, "\(fromCommandLine.stderr)")
        #expect(fromCommandLine.stderr.contains("overriding"), "\(fromCommandLine.stderr)")
        #expect(commandLineText == nil)
        #expect(!fromFile.succeeded)
        let output = fromFile.stdout + fromFile.stderr
        for expected in ["'sub-rule-precedence'", "'overriding'", "eclipse", "extending-rule"] {
            #expect(output.contains(expected), "\(expected) is missing from: \(output)")
        }
        #expect(fileText == nil)
    }

    @Test("lists the option and its values in the help of the commands that run rules", arguments: ["transform", "generate"])
    @MainActor
    func help(command: String) async throws {
        let result = try await executeSwiftATL(command: command, arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains(Self.option))
        #expect(result.stdout.contains("eclipse|extending-rule"))
    }
}
