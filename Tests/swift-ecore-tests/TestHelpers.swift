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
        default:
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
///   - workingDirectory: The directory to run the tool in (default: the current directory).
///   - environment: The environment variables to set, or to remove where the value is `nil`
///     (default: none); see ``childEnvironment(_:)``.
/// - Returns: The subprocess execution result.
/// - Throws: Errors from subprocess execution or executable path resolution.
@MainActor
func executeSwiftEcore(
    command: String,
    arguments: [String] = [],
    captureOutput: Bool = true,
    workingDirectory: URL? = nil,
    environment: [String: String?] = [:]
) async throws -> SubprocessResult {
    // Given
    let executablePath = try swiftEcoreExecutablePath()

    // When
    var allArgs = [command]
    allArgs.append(contentsOf: arguments)

    // Always capture output for simplicity, just return empty if not needed
    let result = try await withProcessSlot {
        try await Subprocess.run(
            .path(FilePath(executablePath)),
            arguments: Arguments(allArgs),
            environment: childEnvironment(environment),
            workingDirectory: workingDirectory.map { FilePath($0.path) },
            output: .string(limit: 16384),
            error: .string(limit: 16384)
        )
    }

    // Then
    return SubprocessResult(
        terminationStatus: result.terminationStatus,
        stdout: captureOutput ? (result.standardOutput ?? "") : "",
        stderr: captureOutput ? (result.standardError ?? "") : ""
    )
}

// MARK: - Child Environment

/// The environment variable that chooses the semantics of the tools.
let semanticsVariable = "SWIFT_MODELLING_SEMANTICS"

/// The environment of a child process.
///
/// The child inherits the environment of the tests without ``semanticsVariable``, so that the
/// tests do not depend on the environment of the developer, and with the given updates.
///
/// - Parameter updates: The variables to set, or to remove where the value is `nil`.
/// - Returns: The environment of the child.
func childEnvironment(_ updates: [String: String?]) -> Environment {
    var values: [Environment.Key: String?] = [Environment.Key(stringLiteral: semanticsVariable): nil]
    for (key, value) in updates {
        values[Environment.Key(stringLiteral: key)] = value
    }
    return .inherit.updating(values)
}

// MARK: - Process Slots

/// Limits how many processes the tests of this target run at the same time.
///
/// Swift Testing runs tests concurrently, and on Linux the tests of every target share one
/// process. Starting a process for every concurrently running test can exhaust the file
/// descriptors of that process, so a test waits for a free slot before it starts a process.
actor ProcessSlots {
    /// The slots shared by the tests of this target.
    static let shared = ProcessSlots(limit: max(2, ProcessInfo.processInfo.activeProcessorCount))

    /// How many processes may run at the same time.
    let limit: Int

    /// How many processes are running.
    private var running = 0

    /// The tests waiting for a slot, in the order in which they asked for one.
    private var waiting: [CheckedContinuation<Void, Never>] = []

    /// Creates slots for a number of processes.
    ///
    /// - Parameter limit: How many processes may run at the same time.
    init(limit: Int) {
        self.limit = limit
    }

    /// Waits until a slot is free and takes it.
    func acquire() async {
        guard running >= limit else {
            running += 1
            return
        }
        await withCheckedContinuation { waiting.append($0) }
    }

    /// Gives a slot back, handing it to the test that has waited longest, if any.
    func release() {
        if waiting.isEmpty {
            running -= 1
        } else {
            waiting.removeFirst().resume()
        }
    }
}

/// Runs work that starts a process once a process slot is free.
///
/// - Parameters:
///   - isolation: The actor the work runs on, by default that of the caller.
///   - body: The work, which starts the process and waits for it.
/// - Returns: The result of the work.
/// - Throws: Any error the work throws.
func withProcessSlot<T>(
    isolation: isolated (any Actor)? = #isolation,
    _ body: () async throws -> T
) async rethrows -> T {
    await ProcessSlots.shared.acquire()
    do {
        let value = try await body()
        await ProcessSlots.shared.release()
        return value
    } catch {
        await ProcessSlots.shared.release()
        throw error
    }
}
