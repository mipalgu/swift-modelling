import Foundation
import Subprocess
import Testing

#if canImport(System)
    import System
#else
    import SystemPackage
#endif

// MARK: - Test Errors

/// Errors that can occur during test execution.
enum TestError: Error, CustomStringConvertible {
    case executableNotFound(String)
    case resourceNotFound(String)
    case unexpectedOutput

    var description: String {
        switch self {
        case .executableNotFound(let path):
            return
                "Executable not found at: \(path). Run 'swift build' first."
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
            return Int32(code)
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

/// Resolves the path to the swift-ecore executable using `swift build --show-bin-path`.
///
/// This dynamically locates the build directory regardless of the scratch path used.
///
/// - Returns: The absolute path to the swift-ecore executable.
/// - Throws: `TestError.executableNotFound` if the executable doesn't exist.
func swiftEcoreExecutablePath() throws -> String {
    #if os(Windows)
    let executableName = "swift-ecore.exe"
    #else
    let executableName = "swift-ecore"
    #endif
    var bundleURL = Bundle.module.bundleURL

    // In Xcode, Bundle.module.bundleURL may point to Contents/Resources inside the bundle
    // We need to navigate up to the Products/Debug directory
    if bundleURL.pathComponents.contains("Contents")
        && bundleURL.pathComponents.contains("Resources")
    {
        // Navigate up from .xctest/Contents/Resources to the directory containing .xctest
        while !bundleURL.pathExtension.isEmpty || bundleURL.lastPathComponent == "Contents"
            || bundleURL.lastPathComponent == "Resources"
        {
            bundleURL = bundleURL.deletingLastPathComponent()
            if bundleURL.pathExtension == "xctest" {
                bundleURL = bundleURL.deletingLastPathComponent()
                break
            }
        }
    } else {
        // For SPM and standard Xcode builds, executable is sibling of test bundle
        // SPM: /tmp/build/debug/swift-ecore-testsPackageTests.bundle -> /tmp/build/debug
        // Xcode: /DerivedData/.../Build/Products/Debug/swift-ecore-testsPackageTests.bundle -> .../Debug
        bundleURL = bundleURL.deletingLastPathComponent()
    }

    let bundleSiblingPath = bundleURL.appendingPathComponent(executableName).path
    guard FileManager.default.fileExists(atPath: bundleSiblingPath) else {
        throw TestError.executableNotFound(bundleSiblingPath)
    }

    return bundleSiblingPath
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
    guard
        let resourceURL = bundle.url(
            forResource: name, withExtension: nil, subdirectory: subdirectoryPath)
    else {
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

// MARK: - Dependency Resource Resolution

/// Finds a resource file in a dependency's checkouts directory.
///
/// This dynamically locates files in dependency checkouts regardless of the scratch path used.
/// Uses `Bundle.module.bundleURL` to find the build directory, then navigates to checkouts.
///
/// For SPM: Bundle is at `/scratch-path/debug/TestBundle.bundle`
///          Checkouts are at `/scratch-path/checkouts/`
///
/// For Xcode: Bundle is at `/DerivedData/.../Build/Products/Debug/TestBundle.xctest`
///            Checkouts are at `/DerivedData/.../SourcePackages/checkouts/`
///
/// - Parameters:
///   - fileName: The resource file name (e.g., "organisation.ecore").
///   - dependencyName: The dependency package name (e.g., "swift-ecore").
///   - relativePath: The path from the dependency root to the resource (e.g., "Tests/ECoreTests/Resources/xmi").
/// - Returns: The path to the resource file.
/// - Throws: `TestError.resourceNotFound` if the resource cannot be located.
func findDependencyResource(
    fileName: String,
    dependencyName: String,
    relativePath: String
) throws -> String {
    var bundleURL = Bundle.module.bundleURL

    // In Xcode, Bundle.module.bundleURL may point to Contents/Resources inside the bundle
    if bundleURL.pathComponents.contains("Contents")
        && bundleURL.pathComponents.contains("Resources")
    {
        // Navigate up from .xctest/Contents/Resources to the directory containing .xctest
        while !bundleURL.pathExtension.isEmpty || bundleURL.lastPathComponent == "Contents"
            || bundleURL.lastPathComponent == "Resources"
        {
            bundleURL = bundleURL.deletingLastPathComponent()
            if bundleURL.pathExtension == "xctest" {
                bundleURL = bundleURL.deletingLastPathComponent()
                break
            }
        }
    } else {
        // For SPM builds, bundle is at /scratch-path/debug/TestBundle.bundle
        // Go up one level to get to /scratch-path/debug
        bundleURL = bundleURL.deletingLastPathComponent()
    }

    // Now bundleURL points to the products directory (debug or Debug)
    // For SPM: /scratch-path/arm64-apple-macosx/debug -> search upward to find checkouts
    // For Xcode: /DerivedData/.../Build/Products/Debug -> search for SourcePackages/checkouts

    // Search upward for a directory containing "checkouts" (SPM) or "SourcePackages/checkouts" (Xcode)
    var searchURL = bundleURL
    var lastTriedPath = ""
    for _ in 0..<10 {
        // Try SPM layout: checkouts at same level
        let spmCheckoutsURL =
            searchURL
            .appendingPathComponent("checkouts")
            .appendingPathComponent(dependencyName)
            .appendingPathComponent(relativePath)
            .appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: spmCheckoutsURL.path) {
            return spmCheckoutsURL.path
        }
        lastTriedPath = spmCheckoutsURL.path

        // Try Xcode layout: SourcePackages/checkouts at same level
        let xcodeCheckoutsURL =
            searchURL
            .appendingPathComponent("SourcePackages")
            .appendingPathComponent("checkouts")
            .appendingPathComponent(dependencyName)
            .appendingPathComponent(relativePath)
            .appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: xcodeCheckoutsURL.path) {
            return xcodeCheckoutsURL.path
        }

        let parent = searchURL.deletingLastPathComponent()
        if parent.path == searchURL.path {
            break  // Reached root
        }
        searchURL = parent
    }

    throw TestError.resourceNotFound(
        "\(fileName) from \(dependencyName) at \(relativePath). "
            + "Last tried path: \(lastTriedPath)"
    )
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

/// Executes a swift-ecore command and returns the result.
///
/// - Parameters:
///   - command: The command to execute (e.g., "validate", "convert").
///   - arguments: Additional arguments for the command.
///   - captureOutput: Whether to capture stdout and stderr (default: true).
/// - Returns: The subprocess execution result.
/// - Throws: Errors from subprocess execution or executable path resolution.
@MainActor
func executeSwiftEcore(
    command: String,
    arguments: [String] = [],
    captureOutput: Bool = true
) async throws -> SubprocessResult {
    // Given
    let executablePath = try swiftEcoreExecutablePath()

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
