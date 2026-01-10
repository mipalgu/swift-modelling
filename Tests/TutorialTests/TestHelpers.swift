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
            return code
        case .unhandledException:
            return -1
        @unknown default:
            return -1
        }
    }

    var succeeded: Bool {
        exitCode == 0
    }
}

// MARK: - Executable Path Resolution

func swiftEcoreExecutablePath() throws -> String {
    let executableName = "swift-ecore"
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

    let result = try await Subprocess.run(
        .path(FilePath(executablePath)),
        arguments: Arguments(allArgs),
        output: .string(limit: 16384),
        error: .string(limit: 16384)
    )

    return SubprocessResult(
        terminationStatus: result.terminationStatus,
        stdout: captureOutput ? (result.standardOutput ?? "") : "",
        stderr: captureOutput ? (result.standardError ?? "") : ""
    )
}
