import Foundation
import Subprocess
import Testing

#if canImport(System)
    import System
#else
    import SystemPackage
#endif

// MARK: - Test Errors

enum TestError: Error, CustomStringConvertible {
    case executableNotFound(String)
    case unexpectedOutput

    var description: String {
        switch self {
        case .executableNotFound(let path):
            return
                "Executable not found at: \(path). Run 'swift build' first."
        case .unexpectedOutput:
            return "Unexpected command output"
        }
    }
}

// MARK: - Subprocess Result

struct SubprocessResult: Sendable {
    let terminationStatus: Subprocess.TerminationStatus
    let stdout: String
    let stderr: String

    var exitCode: Int32 {
        switch terminationStatus {
        case .exited(let code):
            return Int32(code)
        default:
            return -1
        }
    }

    var succeeded: Bool {
        exitCode == 0
    }
}

// MARK: - Executable Path Resolution

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

/// Finds the Swift compiler executable in the system PATH
/// - Returns: Path to the swift executable
/// - Throws: TestError if swift cannot be found
func findSwiftExecutable() throws -> String {
    // Check common locations
    let commonPaths = [
        "/usr/bin/swift",  // macOS system Swift
        "/usr/local/bin/swift",  // Homebrew Swift on macOS
    ]

    for path in commonPaths {
        if FileManager.default.fileExists(atPath: path) {
            return path
        }
    }

    // Search in PATH environment variable (for Linux and custom installations)
    if let pathEnv = ProcessInfo.processInfo.environment["PATH"] {
        let paths = pathEnv.split(separator: ":").map(String.init)
        for dir in paths {
            let swiftPath = "\(dir)/swift"
            if FileManager.default.fileExists(atPath: swiftPath) {
                return swiftPath
            }
        }
    }

    throw TestError.executableNotFound("swift")
}

// MARK: - Subprocess Execution

@MainActor
func executeSwiftEcore(
    command: String,
    arguments: [String] = [],
    captureOutput: Bool = true
) async throws -> SubprocessResult {
    let executablePath = try swiftEcoreExecutablePath()

    var allArgs = [command]
    allArgs.append(contentsOf: arguments)

    let result = try await withProcessSlot {
        try await Subprocess.run(
            .path(FilePath(executablePath)),
            arguments: Arguments(allArgs),
            output: .string(limit: 16384),
            error: .string(limit: 16384)
        )
    }

    return SubprocessResult(
        terminationStatus: result.terminationStatus,
        stdout: captureOutput ? (result.standardOutput ?? "") : "",
        stderr: captureOutput ? (result.standardError ?? "") : ""
    )
}

/// Text as a command-line tool prints it on this platform.
///
/// Standard output ends each line with the platform's line terminator, which is a carriage
/// return and line feed on Windows and a line feed elsewhere.
///
/// - Parameter text: The text with line feeds between its lines.
/// - Returns: The text with the platform's line terminator between its lines.
func consoleText(_ text: String) -> String {
    #if os(Windows)
    return text.replacingOccurrences(of: "\n", with: "\r\n")
    #else
    return text
    #endif
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
