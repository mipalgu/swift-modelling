import Foundation
import Subprocess
import System
import Testing

// MARK: - Test Errors

/// Errors that can occur during test execution.
enum TestError: Error, CustomStringConvertible {
    case executableNotFound(String)
    case resourceNotFound(String)
    case unexpectedOutput

    var description: String {
        switch self {
        case .executableNotFound(let path):
            return "Executable not found at: \(path). Run 'swift build --scratch-path /tmp/build-swift-modelling' first."
        case .resourceNotFound(let name):
            return "Test resource not found: \(name)"
        case .unexpectedOutput:
            return "Unexpected command output"
        }
    }
}

// MARK: - Subprocess Result

/// Simplified result structure for testing subprocess execution.
struct SubprocessResult: Sendable {
    let terminationStatus: Subprocess.TerminationStatus
    let stdout: String
    let stderr: String

    /// The exit code from the subprocess.
    var exitCode: Int32 {
        switch terminationStatus {
        case .exited(let code):
            return code
        case .unhandledException:
            return -1
        @unknown default:
            return -1
        }
    }

    /// Whether the subprocess succeeded (exit code 0).
    var succeeded: Bool {
        exitCode == 0
    }
}

// MARK: - Executable Path Resolution

/// Resolves the path to the swift-atl executable built in the scratch directory.
///
/// The executable is expected at `/tmp/build-swift-modelling/{platform}/debug/swift-atl`.
///
/// - Returns: The absolute path to the swift-atl executable.
/// - Throws: `TestError.executableNotFound` if the executable doesn't exist.
func swiftATLExecutablePath() throws -> String {
    let scratchPath = "/tmp/build-swift-modelling"

    #if os(macOS)
    #if arch(arm64)
    let platform = "arm64-apple-macosx"
    #else
    let platform = "x86_64-apple-macosx"
    #endif
    #elseif os(Linux)
    let platform = "x86_64-unknown-linux-gnu"
    #else
    #error("Unsupported platform")
    #endif

    let configuration = "debug"
    let executableName = "swift-atl"

    let path = "\(scratchPath)/\(platform)/\(configuration)/\(executableName)"

    guard FileManager.default.fileExists(atPath: path) else {
        throw TestError.executableNotFound(path)
    }

    return path
}

// MARK: - Resource Loading

/// Loads a test resource file from the bundle.
///
/// - Parameters:
///   - name: The name of the resource file.
///   - subdirectory: Optional subdirectory within Resources.
/// - Returns: URL to the resource file.
/// - Throws: `TestError.resourceNotFound` if the resource doesn't exist.
func loadTestResource(named name: String, subdirectory: String? = nil) throws -> URL {
    // Bundle.module points to the test bundle
    let bundle = Bundle.module

    // Construct the subdirectory path if provided
    let subdirectoryPath = subdirectory.map { "Resources/\($0)" } ?? "Resources"

    // Try to find the resource using Bundle's built-in methods
    guard let resourceURL = bundle.url(forResource: name, withExtension: nil, subdirectory: subdirectoryPath) else {
        // If not found, try manual construction as fallback
        guard let bundleURL = bundle.resourceURL else {
            throw TestError.resourceNotFound("Bundle resources not found")
        }

        var manualURL = bundleURL.appendingPathComponent(subdirectoryPath)
        manualURL.appendPathComponent(name)

        guard FileManager.default.fileExists(atPath: manualURL.path) else {
            throw TestError.resourceNotFound("\(name) (tried: \(manualURL.path))")
        }

        return manualURL
    }

    return resourceURL
}

// MARK: - Temporary Directory Management

/// Creates a temporary directory for test outputs.
///
/// - Returns: URL to the temporary directory.
/// - Throws: File system errors if directory creation fails.
func createTemporaryDirectory() throws -> URL {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("swift-modelling-tests")
        .appendingPathComponent(UUID().uuidString)

    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    return tempDir
}

/// Cleanup helper to remove temporary test files.
///
/// - Parameter url: The temporary directory to remove.
func cleanupTemporaryDirectory(_ url: URL) {
    try? FileManager.default.removeItem(at: url)
}

// MARK: - Subprocess Execution

/// Executes a swift-atl command and returns the result.
///
/// - Parameters:
///   - command: The command to execute (e.g., "parse", "validate").
///   - arguments: Additional arguments for the command.
///   - captureOutput: Whether to capture stdout and stderr (default: true).
/// - Returns: The subprocess execution result.
/// - Throws: Errors from subprocess execution or executable path resolution.
@MainActor
func executeSwiftATL(
    command: String,
    arguments: [String] = [],
    captureOutput: Bool = true
) async throws -> SubprocessResult {
    // Given
    let executablePath = try swiftATLExecutablePath()

    // When
    var allArgs = [command]
    allArgs.append(contentsOf: arguments)

    // Always capture output for simplicity, just return empty if not needed
    let result = try await Subprocess.run(
        .path(FilePath(executablePath)),
        arguments: Arguments(allArgs),
        output: .string(limit: 16384),
        error: .string(limit: 16384)
    )

    // Then
    return SubprocessResult(
        terminationStatus: result.terminationStatus,
        stdout: captureOutput ? (result.standardOutput ?? "") : "",
        stderr: captureOutput ? (result.standardError ?? "") : ""
    )
}
