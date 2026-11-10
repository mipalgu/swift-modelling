//
// TestSupport.swift
// swift-henshin-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Subprocess
import Synchronization
import Testing

@testable import swift_henshin

#if canImport(System)
    import System
#else
    import SystemPackage
#endif

/// Errors that the support code of the tests reports.
enum SwiftHenshinTestError: Error, CustomStringConvertible {
    /// The executable of the tool has not been built.
    case executableNotFound(String)

    /// A fixture is missing from the resources of the tests.
    case fixtureNotFound(String)

    /// A description of the error for test reports.
    var description: String {
        switch self {
        case .executableNotFound(let path): return "Executable not found at \(path); build the package first"
        case .fixtureNotFound(let name): return "Fixture not found: \(name)"
        }
    }
}

/// The fixtures that the tests read.
///
/// The depot fixture is a small self-authored example: a depot whose bins pass tokens around
/// a ring and hold parcels, with the same rules and units written as a Henshin document
/// (`depot.henshin`) and as a Henshin Text document (`depot.henshin_text`).
enum Fixture {
    /// The directory of the depot fixture, relative to the resources of the tests.
    static let depotDirectory = "depot"

    /// The metamodel of the depot fixture.
    static let metamodel = "Depot.ecore"

    /// The model of the depot fixture.
    static let model = "depot.xmi"

    /// The rules of the depot fixture as a Henshin document.
    static let module = "depot.henshin"

    /// The rules of the depot fixture as a Henshin Text document.
    static let textModule = "depot.henshin_text"

    /// Every file of the depot fixture.
    static let all = [metamodel, model, module, textModule]

    /// The directory that holds the fixtures within the resource bundle of the tests.
    static let resourcesDirectory = "Resources"

    /// The location of a file of the depot fixture.
    ///
    /// The resource bundle of the tests is laid out differently by the build systems and
    /// platforms, so the bundle is asked for the file first, and the layouts in which a
    /// copied resource directory can appear are then tried in turn.
    ///
    /// - Parameter name: The name of the file.
    /// - Returns: Its location within the resources of the tests.
    /// - Throws: ``SwiftHenshinTestError/fixtureNotFound(_:)``, naming every location that
    ///   was tried, if the file does not exist.
    static func depot(_ name: String) throws -> URL {
        let bundle = Bundle.module
        let subdirectory = resourcesDirectory + "/" + depotDirectory
        if let url = bundle.url(forResource: name, withExtension: nil, subdirectory: subdirectory) {
            return url
        }
        let roots = [bundle.resourceURL, bundle.bundleURL, bundle.bundleURL.appendingPathComponent("Contents/Resources")]
        let candidates = roots.compactMap { $0?.appendingPathComponent(subdirectory).appendingPathComponent(name) }
        if let url = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
            return url
        }
        let tried = candidates.map(\.path).joined(separator: ", ")
        throw SwiftHenshinTestError.fixtureNotFound("\(name) (tried: \(tried))")
    }

    /// Creates an empty directory for one test.
    ///
    /// - Returns: The directory.
    /// - Throws: An error if the directory cannot be created.
    static func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("swift-henshin-tests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Copies the files of the depot fixture into a new temporary directory.
    ///
    /// - Returns: The directory.
    /// - Throws: An error if a file cannot be copied.
    static func copyDepot() throws -> URL {
        let directory = try temporaryDirectory()
        for name in all {
            try FileManager.default.copyItem(at: try depot(name), to: directory.appendingPathComponent(name))
        }
        return directory
    }

    /// Writes a file into a directory.
    ///
    /// - Parameters:
    ///   - text: The contents.
    ///   - name: The name of the file.
    ///   - directory: The directory.
    /// - Returns: The location of the file.
    /// - Throws: An error if the file cannot be written.
    @discardableResult
    static func write(_ text: String, named name: String, in directory: URL) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// Reads a file of a directory.
    ///
    /// - Parameters:
    ///   - name: The name of the file.
    ///   - directory: The directory.
    /// - Returns: The contents.
    /// - Throws: An error if the file cannot be read.
    static func read(_ name: String, in directory: URL) throws -> String {
        try String(contentsOf: directory.appendingPathComponent(name), encoding: .utf8)
    }
}

/// The result of running the tool.
struct ToolRun: Sendable {
    /// The exit status, or -1 if the tool ended otherwise.
    let status: Int32

    /// What the tool printed to standard output.
    let output: String

    /// What the tool printed to standard error.
    let error: String

    /// Whether the tool exited with status 0.
    var succeeded: Bool { status == 0 }
}

/// The location of the built swift-henshin executable, beside the bundle of the tests.
///
/// - Returns: The path of the executable.
/// - Throws: ``SwiftHenshinTestError/executableNotFound(_:)`` if it has not been built.
func swiftHenshinExecutablePath() throws -> String {
    #if os(Windows)
        let name = SwiftHenshinVocabulary.toolName + ".exe"
    #else
        let name = SwiftHenshinVocabulary.toolName
    #endif
    var directory = Bundle.module.bundleURL.deletingLastPathComponent()
    while directory.pathExtension == "xctest" || ["Contents", "Resources"].contains(directory.lastPathComponent) {
        directory = directory.deletingLastPathComponent()
    }
    let path = directory.appendingPathComponent(name).path
    guard FileManager.default.fileExists(atPath: path) else { throw SwiftHenshinTestError.executableNotFound(path) }
    return path
}

/// Runs the tool with arguments.
///
/// - Parameters:
///   - arguments: The arguments.
///   - directory: The working directory, or `nil` for that of the tests.
/// - Returns: The result of the run.
/// - Throws: An error if the tool cannot be started.
func runSwiftHenshin(_ arguments: [String], in directory: URL? = nil) async throws -> ToolRun {
    let result = try await Subprocess.run(
        .path(FilePath(try swiftHenshinExecutablePath())),
        arguments: Arguments(arguments),
        workingDirectory: directory.map { FilePath($0.path) },
        output: .string(limit: 1 << 22),
        error: .string(limit: 1 << 22))
    let status: Int32
    if case .exited(let code) = result.terminationStatus { status = Int32(code) } else { status = -1 }
    return ToolRun(
        status: status, output: normalisedConsoleText(result.standardOutput ?? ""),
        error: normalisedConsoleText(result.standardError ?? ""))
}

/// Text that a tool printed, with line feeds between its lines on every platform.
///
/// On Windows, standard output and standard error are in text mode, which ends each line
/// that a tool prints with a carriage return and line feed. The captured text is brought
/// back to the line feeds that the tool printed, so that tests compare the same text on
/// every platform. Elsewhere, the text is returned unchanged.
///
/// - Parameter text: The text as captured from the standard output or standard error of a tool.
/// - Returns: The text with each carriage return and line feed on Windows replaced by a line feed.
func normalisedConsoleText(_ text: String) -> String {
    #if os(Windows)
    return text.replacingOccurrences(of: "\r\n", with: "\n")
    #else
    return text
    #endif
}

/// A log that records its lines instead of writing them.
final class RecordingLog: Sendable {
    /// The recorded text.
    private let storage = Mutex<String>("")

    /// The text written so far.
    var text: String { storage.withLock { $0 } }

    /// The log that records into this recorder.
    ///
    /// - Parameter verbose: Whether progress is recorded.
    /// - Returns: The log.
    func log(verbose: Bool = false) -> Log {
        Log(verbose: verbose) { [self] line in storage.withLock { $0 += line } }
    }
}
