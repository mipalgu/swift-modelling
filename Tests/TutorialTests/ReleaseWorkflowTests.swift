import Foundation
import Testing

/// Checks the release jobs that publish bottles and their Homebrew checksums.
///
/// Bottle production has one automatic owner, and formula publication waits for all of its builds.
@Suite("Release workflow orchestration")
struct ReleaseWorkflowTests {
    /// The reusable workflow that builds release archives.
    private static let bottleWorkflow = "build-bottles.yml"

    /// The workflow that owns automatic releases and formula publication.
    private static let releaseWorkflow = "release.yml"

    /// The event that starts an automatic release.
    private static let releaseEvent = "release"

    /// The event that permits a manual workflow run.
    private static let manualEvent = "workflow_dispatch"

    /// The event that permits reuse by another workflow.
    private static let callableEvent = "workflow_call"

    /// The job that calls every platform's bottle build.
    private static let bottleJob = "build-bottles"

    /// The job that calculates bottle checksums and publishes the formula.
    private static let formulaJob = "update-formula"

    /// The mapping key that declares prerequisite jobs.
    private static let dependencyKey = "needs:"

    /// The mapping key that declares workflow triggers.
    private static let triggerKey = "on:"

    /// The line endings commonly used in checked-out workflow files.
    private static let lineEndings = ["\n", "\r\n", "\r"]

    /// Reads a workflow from the repository.
    ///
    /// - Parameter name: The workflow's file name.
    /// - Returns: The workflow's YAML text.
    /// - Throws: A file-reading error if the workflow is unavailable.
    private static func workflow(_ name: String) throws -> String {
        try String(
            contentsOf: JavaTutorialSubject.repositoryRoot
                .appendingPathComponent(".github/workflows")
                .appendingPathComponent(name),
            encoding: .utf8)
    }

    /// Reads the indented lines beneath a YAML mapping key.
    ///
    /// - Parameters:
    ///   - heading: The mapping key, including its indentation and colon.
    ///   - text: The workflow's YAML text.
    /// - Returns: The lines belonging to the mapping key.
    /// - Throws: A test failure if the mapping key is absent.
    private static func section(_ heading: String, in text: String) throws -> [String] {
        let lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
        let start = try #require(lines.firstIndex(of: heading), "Missing workflow section: \(heading)")
        let indentation = heading.prefix { $0 == " " }.count
        return Array(lines.dropFirst(start + 1).prefix { line in
            line.trimmingCharacters(in: .whitespaces).isEmpty
                || line.prefix { $0 == " " }.count > indentation
        })
    }

    /// Reads the event names from the workflow's trigger mapping.
    ///
    /// - Parameter text: The workflow's YAML text.
    /// - Returns: The names of the events that can start the workflow.
    /// - Throws: A test failure if the trigger mapping is absent.
    private static func events(in text: String) throws -> Set<String> {
        Set(try section(triggerKey, in: text).compactMap { line in
            guard line.prefix(2) == "  ", line.dropFirst(2).first != " ", line.hasSuffix(":") else {
                return nil
            }
            return String(line.dropFirst(2).dropLast())
        })
    }

    /// Checks that workflow mappings retain their meaning with each common line ending.
    ///
    /// The trigger and job mappings use the same reader as the release contract checks.
    ///
    /// - Parameter lineEnding: The separator between the workflow's lines.
    @Test("Workflow mappings accept LF, CRLF and CR line endings", arguments: Self.lineEndings)
    func commonLineEndings(_ lineEnding: String) throws {
        let dependency = "    \(Self.dependencyKey) [\(Self.bottleJob)]"
        let workflow = [
            Self.triggerKey,
            "  \(Self.manualEvent):",
            "  \(Self.callableEvent):",
            "jobs:",
            "  \(Self.formulaJob):",
            dependency,
        ].joined(separator: lineEnding)
        let events = try Self.events(in: workflow)
        let formula = try Self.section("  \(Self.formulaJob):", in: workflow)
        #expect(events == [Self.manualEvent, Self.callableEvent])
        #expect(formula == [dependency])
    }

    /// Checks that the release owner invokes one reusable bottle workflow.
    ///
    /// The reusable workflow also permits deliberate manual builds.
    @Test("Published releases have one automatic bottle producer")
    func singleAutomaticProducer() throws {
        let bottles = try Self.workflow(Self.bottleWorkflow)
        let release = try Self.workflow(Self.releaseWorkflow)
        let bottleEvents = try Self.events(in: bottles)
        let releaseEvents = try Self.events(in: release)
        #expect(bottleEvents == [Self.manualEvent, Self.callableEvent])
        #expect(releaseEvents == [Self.releaseEvent, Self.manualEvent])

        let releaseEvent = try Self.section("  \(Self.releaseEvent):", in: release)
        #expect(releaseEvent.contains { $0.trimmingCharacters(in: .whitespaces) == "types: [published]" })
        let build = try Self.section("  \(Self.bottleJob):", in: release)
        #expect(build.contains {
            $0.trimmingCharacters(in: .whitespaces) == "uses: ./.github/workflows/\(Self.bottleWorkflow)"
        })
    }

    /// Checks that formula publication depends on the complete bottle workflow.
    ///
    /// The dependency prevents checksum calculation before any platform's build finishes.
    @Test("Formula checksum publication waits for the complete bottle workflow")
    func formulaWaitsForBottles() throws {
        let release = try Self.workflow(Self.releaseWorkflow)
        let formula = try Self.section("  \(Self.formulaJob):", in: release)
        let needs = try #require(formula.first {
            $0.trimmingCharacters(in: .whitespaces).hasPrefix(Self.dependencyKey)
        })
        let dependencies = needs.trimmingCharacters(in: .whitespaces).dropFirst(Self.dependencyKey.count)
            .trimmingCharacters(in: CharacterSet(charactersIn: " []"))
            .components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        #expect(dependencies.contains(Self.bottleJob))
    }
}
