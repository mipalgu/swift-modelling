import Foundation
import Subprocess
#if canImport(System)
import System
#else
import SystemPackage
#endif
import Testing

// MARK: - Test Errors

enum TestError: Error, CustomStringConvertible {
    case executableNotFound(String)
    case unexpectedOutput

    var description: String {
        switch self {
        case .executableNotFound(let path):
            return "Executable not found at: \(path). Run 'swift build --scratch-path /tmp/build-swift-modelling' first."
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
    let scratchPath = "/tmp/build-swift-modelling"
    let configuration = "debug"
    let executableName = "swift-ecore"

    let path = "\(scratchPath)/\(configuration)/\(executableName)"

    guard FileManager.default.fileExists(atPath: path) else {
        throw TestError.executableNotFound(path)
    }

    return path
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
