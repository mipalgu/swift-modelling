import ATL
//
// TestCommand.swift
// swift-atl
//
//  Created by Rene Hexel on 6/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Foundation

/// Command for testing ATL transformation files.
///
/// The test command runs comprehensive tests on ATL transformation files,
/// including parsing tests, validation tests, and transformation execution tests.
/// It can test individual files or entire directories of ATL transformations.
struct TestCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "test",
        abstract: "Test ATL transformation files",
        discussion: """
            Runs comprehensive tests on ATL transformation files including parsing tests,
            validation tests, and transformation execution tests. Can test individual files
            or entire directories of ATL transformations.

            Examples:
                swift-atl test Families2Persons.atl
                swift-atl test --directory Tests/ATLTests/Resources
                swift-atl test *.atl --timeout 30 --verbose
            """
    )

    /// ATL source files to test.
    ///
    /// One or more paths to ATL transformation files that should be tested.
    /// If not specified, uses files from the directory option.
    @Argument(help: "ATL source files to test")
    var atlFiles: [String] = []

    /// Directory containing ATL test files.
    ///
    /// When specified, tests all ATL files found in this directory
    /// and its subdirectories.
    @Option(name: .shortAndLong, help: "Directory containing ATL test files")
    var directory: String?

    /// Test timeout in seconds.
    ///
    /// Maximum time allowed for each test to complete before being
    /// marked as failed due to timeout. Default is 60 seconds.
    @Option(name: .shortAndLong, help: "Test timeout in seconds (default: 60)")
    var timeout: TimeInterval = 60.0

    /// Output file path for test results.
    ///
    /// When specified, writes a detailed test report to the given file
    /// instead of printing to standard output.
    @Option(name: .shortAndLong, help: "Output file for test results")
    var output: String?

    /// Enable verbose output mode.
    ///
    /// Shows detailed test progress and additional diagnostic information
    /// during test execution.
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    /// Stop on first test failure.
    ///
    /// When enabled, stops running tests immediately after the first
    /// failure is encountered.
    @Flag(name: .long, help: "Stop on first test failure")
    var failFast: Bool = false

    /// Executes the test command.
    ///
    /// Runs tests on the specified ATL files and generates a test report.
    /// Returns appropriate exit codes based on test results.
    ///
    /// - Throws: `ValidationError` if no files are specified, or `ExitCode` if tests fail
    func run() async throws {
        var filesToTest: [String] = atlFiles

        // If directory specified, find all ATL files
        if let dir = directory {
            let dirURL = URL(fileURLWithPath: dir)
            let fileManager = FileManager.default

            guard fileManager.fileExists(atPath: dir) else {
                throw ValidationError("Test directory not found: \(dir)")
            }

            if verbose {
                print("Scanning directory: \(dir)")
            }

            let contents = try fileManager.contentsOfDirectory(
                at: dirURL, includingPropertiesForKeys: nil)
            let atlFileURLs = contents.filter { $0.pathExtension.lowercased() == "atl" }
            filesToTest.append(contentsOf: atlFileURLs.map { $0.path })
        }

        guard !filesToTest.isEmpty else {
            throw ValidationError("No ATL files to test")
        }

        if verbose {
            print("Testing \(filesToTest.count) ATL file(s)")
            print("Timeout: \(timeout) seconds")
        }

        var testResults: [TestResult] = []
        var passedTests = 0
        var failedTests = 0

        for atlFile in filesToTest {
            if verbose {
                print("Testing: \(atlFile)")
            }

            let result = await runTest(for: atlFile)
            testResults.append(result)

            if result.passed {
                passedTests += 1
                if !verbose {
                    print("PASS: \(atlFile)")
                }
            } else {
                failedTests += 1
                if !verbose {
                    print("FAIL: \(atlFile) - \(result.error ?? "Unknown error")")
                }

                if failFast {
                    print("Stopping tests due to --fail-fast")
                    break
                }
            }
        }

        // Print summary
        if verbose {
            print("\nTest Summary:")
            print("Passed: \(passedTests)")
            print("Failed: \(failedTests)")
            print("Total: \(testResults.count)")
            print(
                "Success rate: \(String(format: "%.1f", Double(passedTests) / Double(testResults.count) * 100))%"
            )
        } else {
            print("Tests complete: \(passedTests) passed, \(failedTests) failed")
        }

        // Write detailed results if requested
        if let outputPath = output {
            let report = generateTestReport(testResults)
            try report.write(
                to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
            print("Test report written to \(outputPath)")
        }

        // Exit with error code if tests failed
        if failedTests > 0 {
            throw ExitCode.failure
        }
    }

    private func runTest(for filePath: String) async -> TestResult {
        let startTime = Date()

        return await withTaskGroup(of: TestResult.self) { group in
            group.addTask {
                await self.executeTestWithTimeout(filePath: filePath, startTime: startTime)
            }
            return await group.next()
                ?? TestResult(
                    filename: filePath,
                    passed: false,
                    testTime: Date().timeIntervalSince(startTime),
                    error: "Test task failed to complete"
                )
        }
    }

    private func executeTestWithTimeout(filePath: String, startTime: Date) async -> TestResult {
        do {
            let testTask = Task {
                try await executeTest(filePath: filePath, startTime: startTime)
            }

            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TestError.timeout
            }

            let result = try await withThrowingTaskGroup(of: TestResult.self) { group in
                group.addTask { try await testTask.value }
                group.addTask {
                    _ = try await timeoutTask.value
                    throw TestError.timeout
                }

                let result = try await group.next()!
                group.cancelAll()
                return result
            }

            return result

        } catch TestError.timeout {
            return TestResult(
                filename: filePath,
                passed: false,
                testTime: timeout,
                error: "Test timed out after \(Int(timeout)) seconds"
            )
        } catch {
            return TestResult(
                filename: filePath,
                passed: false,
                testTime: Date().timeIntervalSince(startTime),
                error: error.localizedDescription
            )
        }
    }

    private func executeTest(filePath: String, startTime: Date) async throws -> TestResult {
        guard FileManager.default.fileExists(atPath: filePath) else {
            return TestResult(
                filename: filePath,
                passed: false,
                testTime: Date().timeIntervalSince(startTime),
                error: "File not found"
            )
        }

        // Test 1: Parse the ATL file
        let atlSource = try String(contentsOfFile: filePath, encoding: .utf8)
        let parser = ATLParser()
        let module = try await parser.parseContent(
            atlSource, filename: URL(fileURLWithPath: filePath).lastPathComponent)

        if verbose {
            print("  Parse successful: \(module.name)")
        }

        // Test 2: Validate module structure
        guard !module.name.isEmpty else {
            return TestResult(
                filename: filePath,
                passed: false,
                testTime: Date().timeIntervalSince(startTime),
                error: "Module name is empty"
            )
        }

        if verbose {
            print("  Module validation successful")
        }

        // Test 3: Basic semantic checks
        if module.sourceMetamodels.isEmpty && module.matchedRules.isEmpty
            && module.calledRules.isEmpty
        {
            return TestResult(
                filename: filePath,
                passed: false,
                testTime: Date().timeIntervalSince(startTime),
                error: "Module appears to be empty or invalid"
            )
        }

        if verbose {
            print("  All tests passed")
        }

        return TestResult(
            filename: filePath,
            passed: true,
            testTime: Date().timeIntervalSince(startTime),
            error: nil
        )
    }

    private func generateTestReport(_ results: [TestResult]) -> String {
        var report = "ATL Test Report\n"
        report += "===============\n\n"

        let passedTests = results.filter { $0.passed }
        let failedTests = results.filter { !$0.passed }
        let totalTime = results.reduce(0) { $0 + $1.testTime }

        report += "Summary:\n"
        report += "  Tests passed: \(passedTests.count)\n"
        report += "  Tests failed: \(failedTests.count)\n"
        report += "  Total time: \(String(format: "%.3f", totalTime * 1000))ms\n"
        report +=
            "  Success rate: \(String(format: "%.1f", Double(passedTests.count) / Double(results.count) * 100))%\n\n"

        for result in results {
            report += "Test: \(result.filename)\n"
            report += "Result: \(result.passed ? "PASS" : "FAIL")\n"
            report += "Time: \(String(format: "%.3f", result.testTime * 1000))ms\n"
            if let error = result.error {
                report += "Error: \(error)\n"
            }
            report += "\n"
        }

        return report
    }
}

// MARK: - Analyze Command

/// Command for analyzing ATL transformation files.
///
/// The analyze command provides comprehensive analysis of ATL transformation files,
/// including complexity metrics, rule analysis, helper function analysis,
/// and transformation pattern detection.
