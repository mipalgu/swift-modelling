import ArgumentParser
import Foundation
import Testing

/// Tests for `swift-atl transform --abstract-rule-matching` and `--abstract-leaf-rules`.
///
/// The first option chooses what an element gives that an abstract rule matches but none of the
/// rules extending it match: nothing, as in Eclipse ATL, or a turn for the rules declared after the
/// abstract rule. The second chooses what an element gives that an abstract rule matches when no
/// rule extends it: an error, as in Eclipse ATL, or nothing. The legacy preset selects the second
/// value of each.
@Suite("swift-atl - abstract rules")
struct AbstractRuleTests {
    /// The long name of the option that chooses how abstract rules match.
    private static let matchingOption = "--abstract-rule-matching"

    /// The long name of the option that chooses what an abstract rule without sub-rules gives.
    private static let leafOption = "--abstract-leaf-rules"

    /// The long name of the option that chooses the preset.
    private static let semanticsOption = "--semantics"

    /// The name of the configuration file.
    private static let configurationFile = ".swift-modelling.json"

    /// The name that the open task has under every choice.
    private static let openName = "name=\"any drafting\""

    /// The name that the finished task has when the rule declared after the abstract rule that it
    /// matches transforms it.
    private static let finishedName = "name=\"any reviewing\""

    /// A transformation with a rule for every task, an abstract rule for the finished tasks that
    /// takes precedence over it, and the only rule extending that abstract rule, which no task matches.
    static let matchingTransformation = """
        -- @path Tasks=/Tasks.ecore
        -- @path Notes=/Notes.ecore

        module AbstractMatchingNotes;
        create OUT : Notes from IN : Tasks;

        abstract rule Task2Note {
            from t : Tasks!Task
            to n : Notes!Note (name <- 'abstract ' + t.name)
        }

        abstract rule ClosedTask extends Task2Note {
            from t : Tasks!Task (t.done)
            to n : Notes!Note (name <- 'closed ' + t.name)
        }

        rule ArchivedTask extends ClosedTask {
            from t : Tasks!Task (t.done and t.name = 'archived')
            to n : Notes!Note (name <- 'archived ' + t.name)
        }

        rule AnyTask extends Task2Note {
            from t : Tasks!Task
            to n : Notes!Note (name <- 'any ' + t.name)
        }
        """

    /// A transformation with an abstract rule for the finished tasks that no rule extends, and a
    /// rule for the open tasks.
    static let leafTransformation = """
        -- @path Tasks=/Tasks.ecore
        -- @path Notes=/Notes.ecore

        module AbstractLeafNotes;
        create OUT : Notes from IN : Tasks;

        abstract rule FinishedTask {
            from t : Tasks!Task (t.done)
            to n : Notes!Note (name <- 'finished ' + t.name)
        }

        rule OpenTask {
            from t : Tasks!Task (not t.done)
            to n : Notes!Note (name <- 'any ' + t.name)
        }
        """

    /// The name that the finished task would have if the abstract rule that no rule extends were applied.
    private static let abstractName = "name=\"finished reviewing\""

    /// A directory with the metamodels, the transformations and the source model.
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
            try write(AbstractRuleTests.matchingTransformation, to: "AbstractMatchingNotes.atl")
            try write(AbstractRuleTests.leafTransformation, to: "AbstractLeafNotes.atl")
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

    /// Runs a transformation from the workspace directory.
    ///
    /// - Parameters:
    ///   - module: The name of the transformation file.
    ///   - workspace: The workspace.
    ///   - target: The name of the target model.
    ///   - extra: The arguments after the models.
    /// - Returns: The result of the command and the text of the target model, if any.
    @MainActor
    private func transform(
        _ module: String, in workspace: Workspace, target: String = "notes.xmi", extra: [String] = []
    ) async throws -> (result: SubprocessResult, text: String?) {
        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                module, "--metamodel-path", workspace.root.path, "--source", "IN=tasks.xmi",
                "--target", "OUT=\(target)",
            ] + extra,
            workingDirectory: workspace.root)
        return (result, try? String(contentsOf: workspace.root.appendingPathComponent(target), encoding: .utf8))
    }

    /// Runs the transformation whose abstract rule has a sub-rule that the finished task does not match.
    @MainActor
    private func matching(
        _ workspace: Workspace, target: String = "notes.xmi", extra: [String] = []
    ) async throws -> (result: SubprocessResult, text: String?) {
        try await transform("AbstractMatchingNotes.atl", in: workspace, target: target, extra: extra)
    }

    /// Runs the transformation whose abstract rule has no sub-rule.
    @MainActor
    private func leaf(
        _ workspace: Workspace, target: String = "notes.xmi", extra: [String] = []
    ) async throws -> (result: SubprocessResult, text: String?) {
        try await transform("AbstractLeafNotes.atl", in: workspace, target: target, extra: extra)
    }

    /// Checks that the abstract rule kept the rule declared after it from transforming the finished task.
    ///
    /// - Parameters:
    ///   - result: The result of the command.
    ///   - text: The text of the target model.
    private func expectStopped(_ result: SubprocessResult, _ text: String?) {
        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text?.contains(Self.openName) == true, "\(text ?? "")")
        #expect(text?.contains(Self.finishedName) == false, "\(text ?? "")")
    }

    /// Checks that the rule declared after the abstract rule transformed the finished task.
    ///
    /// - Parameters:
    ///   - result: The result of the command.
    ///   - text: The text of the target model.
    private func expectSkipped(_ result: SubprocessResult, _ text: String?) {
        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text?.contains(Self.openName) == true, "\(text ?? "")")
        #expect(text?.contains(Self.finishedName) == true, "\(text ?? "")")
    }

    /// Checks that the abstract rule that no rule extends stopped the run before a target was written.
    ///
    /// - Parameters:
    ///   - result: The result of the command.
    ///   - text: The text of the target model.
    private func expectFailed(_ result: SubprocessResult, _ text: String?) {
        #expect(!result.succeeded, "\(result.stdout)\(result.stderr)")
        let output = result.stdout + result.stderr
        for expected in ["FinishedTask", "reviewing"] {
            #expect(output.contains(expected), "\(expected) is missing from: \(output)")
        }
        #expect(text == nil, "\(text ?? "")")
    }

    /// Checks that the abstract rule that no rule extends transformed nothing.
    ///
    /// - Parameters:
    ///   - result: The result of the command.
    ///   - text: The text of the target model.
    private func expectIgnored(_ result: SubprocessResult, _ text: String?) {
        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text?.contains(Self.openName) == true, "\(text ?? "")")
        #expect(text?.contains(Self.abstractName) == false, "\(text ?? "")")
    }

    // MARK: - An Abstract Rule Whose Sub-Rules Do Not Match

    @Test(
        "lets the abstract rule keep the next rule from transforming an element by default and with eclipse",
        arguments: [[], [matchingOption, "eclipse"]])
    @MainActor
    func stoppedByDefault(extra: [String]) async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await matching(workspace, extra: extra)

        expectStopped(result, text)
    }

    @Test("lets the next rule transform the element with skip")
    @MainActor
    func skippedOnCommandLine() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await matching(workspace, extra: [Self.matchingOption, "skip"])

        expectSkipped(result, text)
    }

    @Test("lets the legacy preset skip the abstract rule")
    @MainActor
    func skippedByLegacyPreset() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await matching(workspace, extra: [Self.semanticsOption, "legacy"])

        expectSkipped(result, text)
    }

    @Test("lets the flag override the preset in either direction")
    @MainActor
    func matchingFlagOverridesPreset() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (eclipse, eclipseText) = try await matching(
            workspace, target: "a.xmi", extra: [Self.semanticsOption, "legacy", Self.matchingOption, "eclipse"])
        let (skip, skipText) = try await matching(
            workspace, target: "b.xmi", extra: [Self.semanticsOption, "standard", Self.matchingOption, "skip"])

        expectStopped(eclipse, eclipseText)
        expectSkipped(skip, skipText)
    }

    @Test("takes the value of the configuration file, which the command line overrides")
    @MainActor
    func matchingConfigurationKey() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }
        try workspace.write(#"{ "abstract-rule-matching": "skip" }"#, to: Self.configurationFile)

        let (configured, configuredText) = try await matching(workspace, target: "configured.xmi")
        let (overridden, overriddenText) = try await matching(
            workspace, target: "overridden.xmi", extra: [Self.matchingOption, "eclipse"])
        let (ignored, ignoredText) = try await matching(workspace, target: "ignored.xmi", extra: ["--no-config"])

        expectSkipped(configured, configuredText)
        expectStopped(overridden, overriddenText)
        expectStopped(ignored, ignoredText)
    }

    @Test("lets the key of the file override the preset")
    @MainActor
    func matchingKeyOverridesPreset() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }
        try workspace.write(#"{ "semantics": "legacy", "abstract-rule-matching": "eclipse" }"#, to: Self.configurationFile)

        let (result, text) = try await matching(workspace)

        expectStopped(result, text)
    }

    // MARK: - An Abstract Rule That No Rule Extends

    @Test(
        "stops the run when an abstract rule that no rule extends matches, by default and with error",
        arguments: [[], [leafOption, "error"]])
    @MainActor
    func failsByDefault(extra: [String]) async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await leaf(workspace, extra: extra)

        expectFailed(result, text)
    }

    @Test("lets an abstract rule that no rule extends transform nothing with ignore")
    @MainActor
    func ignoredOnCommandLine() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await leaf(workspace, extra: [Self.leafOption, "ignore"])

        expectIgnored(result, text)
    }

    @Test("lets the legacy preset ignore the abstract rule")
    @MainActor
    func ignoredByLegacyPreset() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await leaf(workspace, extra: [Self.semanticsOption, "legacy"])

        expectIgnored(result, text)
    }

    @Test("lets the flag override the preset in either direction")
    @MainActor
    func leafFlagOverridesPreset() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (error, errorText) = try await leaf(
            workspace, target: "a.xmi", extra: [Self.semanticsOption, "legacy", Self.leafOption, "error"])
        let (ignore, ignoreText) = try await leaf(
            workspace, target: "b.xmi", extra: [Self.semanticsOption, "standard", Self.leafOption, "ignore"])

        expectFailed(error, errorText)
        expectIgnored(ignore, ignoreText)
    }

    @Test("takes the value of the configuration file, which the command line overrides")
    @MainActor
    func leafConfigurationKey() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }
        try workspace.write(#"{ "abstract-leaf-rules": "ignore" }"#, to: Self.configurationFile)

        let (configured, configuredText) = try await leaf(workspace, target: "configured.xmi")
        let (overridden, overriddenText) = try await leaf(
            workspace, target: "overridden.xmi", extra: [Self.leafOption, "error"])
        let (ignored, ignoredText) = try await leaf(workspace, target: "ignored.xmi", extra: ["--no-config"])

        expectIgnored(configured, configuredText)
        expectFailed(overridden, overriddenText)
        expectFailed(ignored, ignoredText)
    }

    @Test("lets the key of the file override the preset")
    @MainActor
    func leafKeyOverridesPreset() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }
        try workspace.write(#"{ "semantics": "legacy", "abstract-leaf-rules": "error" }"#, to: Self.configurationFile)

        let (result, text) = try await leaf(workspace)

        expectFailed(result, text)
    }

    @Test("keeps the two choices independent")
    @MainActor
    func independentChoices() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (matchingResult, matchingText) = try await matching(
            workspace, target: "a.xmi", extra: [Self.leafOption, "ignore"])
        let (leafResult, leafText) = try await leaf(
            workspace, target: "b.xmi", extra: [Self.matchingOption, "skip"])

        expectStopped(matchingResult, matchingText)
        expectFailed(leafResult, leafText)
    }

    // MARK: - Usage

    @Test(
        "rejects a value that is not a choice, on the command line or in the file",
        arguments: [
            (option: matchingOption, key: "abstract-rule-matching", value: "ignore", accepted: ["eclipse", "skip"]),
            (option: leafOption, key: "abstract-leaf-rules", value: "skip", accepted: ["error", "ignore"]),
        ])
    @MainActor
    func rejectsUnknownValue(option: String, key: String, value: String, accepted: [String]) async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (fromCommandLine, commandLineText) = try await matching(workspace, extra: [option, value])
        try workspace.write(#"{ "\#(key)": "\#(value)" }"#, to: Self.configurationFile)
        let (fromFile, fileText) = try await matching(workspace, target: "other.xmi")

        #expect(fromCommandLine.exitCode == ExitCode.validationFailure.rawValue, "\(fromCommandLine.stderr)")
        #expect(fromCommandLine.stderr.contains(value), "\(fromCommandLine.stderr)")
        #expect(commandLineText == nil)
        #expect(!fromFile.succeeded)
        let output = fromFile.stdout + fromFile.stderr
        for expected in ["'\(key)'", "'\(value)'"] + accepted {
            #expect(output.contains(expected), "\(expected) is missing from: \(output)")
        }
        #expect(fileText == nil)
    }

    @Test(
        "lists the options and their values in the help of the commands that run rules",
        arguments: ["transform", "generate"])
    @MainActor
    func help(command: String) async throws {
        let result = try await executeSwiftATL(command: command, arguments: ["--help"])

        #expect(result.succeeded)
        for expected in [Self.matchingOption, "eclipse|skip", Self.leafOption, "error|ignore"] {
            #expect(result.stdout.contains(expected), "\(expected) is missing from: \(result.stdout)")
        }
    }
}
