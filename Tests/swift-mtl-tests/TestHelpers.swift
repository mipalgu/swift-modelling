import Foundation
import Subprocess
#if canImport(System)
import System
#else
import SystemPackage
#endif
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
            let scratch = ProcessInfo.processInfo.environment["SWIFT_MTL_SCRATCH_PATH"] ?? ".build"
            return "Executable not found at: \(path). Run 'swift build --scratch-path \(scratch)' first."
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

/// Returns the scratch directory path for build artefacts.
///
/// The path can be overridden using the `SWIFT_MTL_SCRATCH_PATH` environment variable.
/// Defaults to `/tmp/build-swift-mtl` if not set.
///
/// - Returns: The scratch directory path.
func scratchPath() -> String {
    if let envPath = ProcessInfo.processInfo.environment["SWIFT_MTL_SCRATCH_PATH"] {
        return envPath
    }
    return "/tmp/build-swift-mtl"
}

/// Resolves the path to the swift-mtl executable built in the scratch directory.
///
/// The executable is expected at `<scratch-path>/debug/swift-mtl`.
/// The function first checks the `SWIFT_MTL_SCRATCH_PATH` environment variable,
/// then falls back to detecting the build directory from the test bundle location
/// (checking both SPM and Xcode bundle structures),
/// and finally defaults to `/tmp/build-swift-mtl` if neither is available.
///
/// - Returns: The absolute path to the swift-mtl executable.
/// - Throws: `TestError.executableNotFound` if the executable doesn't exist.
func swiftMTLExecutablePath() throws -> String {
    let configuration = "debug"
    let executableName = "swift-mtl"

    // Strategy 1: Check environment variable
    if let envPath = ProcessInfo.processInfo.environment["SWIFT_MTL_SCRATCH_PATH"] {
        let path = "\(envPath)/\(configuration)/\(executableName)"
        if FileManager.default.fileExists(atPath: path) {
            return path
        }
    }

    // Strategy 2: Detect from test bundle location
    var bundleURL = Bundle.module.bundleURL

    // In Xcode, Bundle.module.bundleURL may point to Contents/Resources inside the bundle
    // We need to navigate up to the Products/Debug directory
    if bundleURL.pathComponents.contains("Contents") && bundleURL.pathComponents.contains("Resources") {
        // Navigate up from .xctest/Contents/Resources to the directory containing .xctest
        while !bundleURL.pathExtension.isEmpty || bundleURL.lastPathComponent == "Contents" || bundleURL.lastPathComponent == "Resources" {
            bundleURL = bundleURL.deletingLastPathComponent()
            if bundleURL.pathExtension == "xctest" {
                bundleURL = bundleURL.deletingLastPathComponent()
                break
            }
        }
    } else {
        // For SPM and standard Xcode builds, executable is sibling of test bundle
        // SPM: /tmp/build/debug/swift-mtl-testsPackageTests.xctest -> /tmp/build/debug
        // Xcode: /DerivedData/.../Build/Products/Debug/swift-mtl-testsPackageTests.xctest -> .../Debug
        bundleURL = bundleURL.deletingLastPathComponent()
    }

    let bundleSiblingPath = bundleURL.appendingPathComponent(executableName).path
    if FileManager.default.fileExists(atPath: bundleSiblingPath) {
        return bundleSiblingPath
    }

    // Strategy 3: Fall back to default path
    let defaultPath = "/tmp/build-swift-mtl/\(configuration)/\(executableName)"
    guard FileManager.default.fileExists(atPath: defaultPath) else {
        throw TestError.executableNotFound(bundleSiblingPath)
    }

    return defaultPath
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
        .appendingPathComponent("swift-mtl-tests")
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

/// Executes a swift-mtl command and returns the result.
///
/// - Parameters:
///   - command: The command to execute (e.g., "generate", "parse", "validate").
///   - arguments: Additional arguments for the command.
///   - captureOutput: Whether to capture stdout and stderr (default: true).
/// - Returns: The subprocess execution result.
/// - Throws: Errors from subprocess execution or executable path resolution.
@MainActor
func executeSwiftMTL(
    command: String,
    arguments: [String] = [],
    captureOutput: Bool = true
) async throws -> SubprocessResult {
    // Given
    let executablePath = try swiftMTLExecutablePath()

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
