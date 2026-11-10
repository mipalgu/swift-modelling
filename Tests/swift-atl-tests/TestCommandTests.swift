import ArgumentParser
import Foundation
import Subprocess
import Testing

@testable import swift_atl

#if canImport(System)
    import System
#else
    import SystemPackage
#endif

// MARK: - Test Command Tests

/// End-to-end tests of `swift-atl test`.
///
/// The tests run the built tool on small transformations with a generous per-file time limit
/// and check that each run finishes as soon as its checks are done, rather than when that
/// time limit has passed, and that a transformation whose checks overrun the limit is
/// reported as timed out.  Each run of the tool has a deadline, after which it is stopped.
@Suite("swift-atl test - Completion and time limits")
struct TestCommandTests {

    /// The per-file time limit, in seconds, passed to the tool by the completion tests.
    static let generousTimeout = "60"

    /// The longest a completion test may take, well below ``generousTimeout``.
    static let promptCompletion = Duration.seconds(15)

    /// How long a run of the tool may take before it is stopped, below ``generousTimeout``.
    static let runDeadline = Duration.seconds(30)

    /// Runs `swift-atl test` with a deadline and measures how long it took.
    ///
    /// The duration covers only the run of the tool, not the time spent waiting for other
    /// tests.  The tool is stopped if it is still running after ``runDeadline``.
    ///
    /// - Parameter arguments: The arguments that follow the `test` command.
    /// - Returns: The result of the run and its duration.
    /// - Throws: Errors from starting the tool, or an issue if it misses the deadline.
    @MainActor
    func timedTestRun(_ arguments: [String]) async throws -> (SubprocessResult, Duration) {
        let executablePath = try swiftATLExecutablePath()
        let finished = try await withProcessSlot {
            try await withThrowingTaskGroup(of: (SubprocessResult, Duration)?.self) { group in
                group.addTask {
                    let clock = ContinuousClock()
                    let start = clock.now
                    let result = try await Subprocess.run(
                        .path(FilePath(executablePath)),
                        arguments: Arguments(["test"] + arguments),
                        environment: childEnvironment([:]),
                        output: .string(limit: subprocessOutputLimit),
                        error: .string(limit: subprocessOutputLimit)
                    )
                    let elapsed = clock.now - start
                    let output = SubprocessResult(
                        terminationStatus: result.terminationStatus,
                        stdout: result.standardOutput ?? "",
                        stderr: result.standardError ?? ""
                    )
                    return (output, elapsed)
                }
                group.addTask {
                    try await Task.sleep(for: Self.runDeadline)
                    return nil
                }
                let first = try await group.next() ?? nil
                group.cancelAll()
                return first
            }
        }
        return try #require(
            finished, "swift-atl test did not finish within \(Self.runDeadline)")
    }

    /// Writes a transformation with many matched rules.
    ///
    /// - Parameters:
    ///   - directory: The directory to write the transformation to.
    ///   - ruleCount: How many matched rules the transformation has.
    /// - Returns: The location of the transformation.
    /// - Throws: Errors from writing the file.
    func writeLargeTransformation(in directory: URL, ruleCount: Int) throws -> URL {
        var source = "module Large;\ncreate OUT: Target from IN: Source;\n"
        for index in 1...ruleCount {
            source += """
                rule Rule\(index) {
                    from s: Source!Element (s.name = '\(index)')
                    to t: Target!Element (
                        name <- s.name + '\(index)'
                    )
                }

                """
        }
        let url = directory.appendingPathComponent("Large.atl")
        try source.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @Test("a passing transformation finishes without waiting for the time limit")
    @MainActor
    func passingFileFinishesPromptly() async throws {
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")

        let (result, elapsed) = try await timedTestRun([
            "--timeout", Self.generousTimeout, atlFile.path,
        ])

        #expect(result.exitCode == 0)
        #expect(result.stdout.contains("PASS: \(atlFile.path)"))
        #expect(result.stdout.contains("1 passed, 0 failed"))
        #expect(elapsed < Self.promptCompletion)
    }

    @Test("a failing transformation finishes without waiting for the time limit")
    @MainActor
    func failingFileFinishesPromptly() async throws {
        let atlFile = try loadTestResource(named: "invalid-syntax.atl", subdirectory: "atl")

        let (result, elapsed) = try await timedTestRun([
            "--timeout", Self.generousTimeout, atlFile.path,
        ])

        #expect(result.exitCode == 1)
        #expect(result.stdout.contains("FAIL: \(atlFile.path)"))
        #expect(!result.stdout.contains("timed out"))
        #expect(elapsed < Self.promptCompletion)
    }

    @Test("several transformations finish without waiting for the time limit of each")
    @MainActor
    func severalFilesFinishPromptly() async throws {
        let simple = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")
        let invalid = try loadTestResource(named: "invalid-syntax.atl", subdirectory: "atl")
        let families = try loadTestResource(
            named: "Families2Persons.atl", subdirectory: "transformations")

        let (result, elapsed) = try await timedTestRun([
            "--timeout", Self.generousTimeout, simple.path, invalid.path, families.path,
        ])

        #expect(result.exitCode == 1)
        #expect(result.stdout.contains("2 passed, 1 failed"))
        #expect(elapsed < Self.promptCompletion)
    }

    @Test("a directory of transformations finishes without waiting for the time limit")
    @MainActor
    func directoryFinishesPromptly() async throws {
        let simple = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")
        let directory = simple.deletingLastPathComponent()

        let (result, elapsed) = try await timedTestRun([
            "--timeout", Self.generousTimeout, "--directory", directory.path,
        ])

        #expect(result.exitCode == 1)
        #expect(result.stdout.contains("1 passed, 1 failed"))
        #expect(elapsed < Self.promptCompletion)
    }

    @Test("a transformation whose checks overrun the time limit is reported as timed out")
    @MainActor
    func overrunningFileTimesOut() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let atlFile = try writeLargeTransformation(in: directory, ruleCount: 2_000)

        let (result, elapsed) = try await timedTestRun(["--timeout", "0.001", atlFile.path])

        #expect(result.exitCode == 1)
        #expect(result.stdout.contains("FAIL: \(atlFile.path) - Test timed out"))
        #expect(result.stdout.contains("0 passed, 1 failed"))
        #expect(elapsed < Self.promptCompletion)
    }

    @Test("a very large time limit is accepted")
    @MainActor
    func veryLargeTimeoutIsAccepted() async throws {
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")

        let (result, elapsed) = try await timedTestRun(["--timeout", "1e300", atlFile.path])

        #expect(result.exitCode == 0)
        #expect(result.stdout.contains("1 passed, 0 failed"))
        #expect(elapsed < Self.promptCompletion)
    }

    @Test(
        "a time limit that is not a positive number is rejected",
        arguments: ["--timeout=0", "--timeout=-1", "--timeout=nan", "--timeout=inf"]
    )
    @MainActor
    func invalidTimeoutIsRejected(option: String) async throws {
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")

        let (result, _) = try await timedTestRun([option, atlFile.path])

        #expect(result.exitCode == ExitCode.validationFailure.rawValue)
        #expect(result.stderr.contains("--timeout"))
    }
}

// MARK: - Time Limit Tests

/// Tests of how `swift-atl test` keeps the time limit of each file.
///
/// A time limit is kept by sleeping for its length, which the concurrency runtime of some
/// platforms cannot do for every length that a number of seconds can express.  A time limit
/// longer than ``TestCommand/longestTimeLimit`` is therefore not kept at all.
@Suite("swift-atl test - Time limits that are kept")
struct TimeLimitTests {

    @Test("an ordinary time limit is kept to the nanosecond")
    func ordinaryTimeLimitIsKept() {
        #expect(TestCommand.nanoseconds(for: 60) == 60_000_000_000)
        #expect(TestCommand.nanoseconds(for: 0.001) == 1_000_000)
        #expect(TestCommand.nanoseconds(for: 1.5) == 1_500_000_000)
    }

    @Test("the longest time limit is kept, and fits a signed number of nanoseconds")
    func longestTimeLimitIsKept() throws {
        let nanoseconds = try #require(TestCommand.nanoseconds(for: TestCommand.longestTimeLimit))
        #expect(nanoseconds < UInt64(Int64.max))
    }

    @Test(
        "a time limit longer than the longest one is not kept",
        arguments: [TestCommand.longestTimeLimit * 2, Double(Int64.max), Double(UInt64.max), 1e300]
    )
    func longerTimeLimitIsNotKept(seconds: TimeInterval) {
        #expect(TestCommand.nanoseconds(for: seconds) == nil)
    }

    @Test("an operation runs to its end under a time limit that is not kept")
    func operationEndsUnderUnkeptTimeLimit() async throws {
        let value = try await TestCommand.firstOutcome(withinSeconds: 1e300) {
            try await Task.sleep(for: .milliseconds(50))
            return 42
        }
        #expect(value == 42)
    }

    @Test("an operation that overruns a time limit that is kept times out")
    func operationOverrunsKeptTimeLimit() async {
        await #expect(throws: swift_atl.TestError.timeout) {
            try await TestCommand.firstOutcome(withinSeconds: 0.001) {
                try await Task.sleep(for: .seconds(30))
                return 42
            }
        }
    }
}
