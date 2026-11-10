//
// TestSupport.swift
// swift-aql-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import Foundation
import Subprocess
import Testing

@testable import swift_aql

#if canImport(System)
    import System
#else
    import SystemPackage
#endif

/// Errors that the support code of the tests reports.
enum SwiftAQLTestError: Error, CustomStringConvertible {
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
enum Fixture {
    /// The directory of the shop fixture, relative to the resources of the tests.
    static let shopDirectory = "shop"

    /// The metamodel of the shop fixture.
    static let shopMetamodel = "Shop.ecore"

    /// The model of the shop fixture.
    static let shopModel = "shop.xmi"

    /// The directory that holds the fixtures within the resource bundle of the tests.
    static let resourcesDirectory = "Resources"

    /// The location of a file of the shop fixture.
    ///
    /// The resource bundle of the tests is laid out differently by the build systems and
    /// platforms, so the bundle is asked for the file first, and the layouts in which a
    /// copied resource directory can appear are then tried in turn.
    ///
    /// - Parameter name: The name of the file.
    /// - Returns: Its location within the resources of the tests.
    /// - Throws: ``SwiftAQLTestError/fixtureNotFound(_:)``, naming every location that was
    ///   tried, if the file does not exist.
    static func shop(_ name: String) throws -> URL {
        let bundle = Bundle.module
        let subdirectory = resourcesDirectory + "/" + shopDirectory
        if let url = bundle.url(forResource: name, withExtension: nil, subdirectory: subdirectory) {
            return url
        }
        let roots = [bundle.resourceURL, bundle.bundleURL, bundle.bundleURL.appendingPathComponent("Contents/Resources")]
        let candidates = roots.compactMap { $0?.appendingPathComponent(subdirectory).appendingPathComponent(name) }
        if let url = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
            return url
        }
        let tried = candidates.map(\.path).joined(separator: ", ")
        throw SwiftAQLTestError.fixtureNotFound("\(name) (tried: \(tried))")
    }

    /// Creates an empty directory for one test.
    ///
    /// - Returns: The directory.
    /// - Throws: An error if the directory cannot be created.
    static func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("swift-aql-tests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Copies the shop model and its metamodel into a directory.
    ///
    /// - Parameter directory: The directory.
    /// - Returns: The location of the copied model.
    /// - Throws: An error if a file cannot be copied.
    @discardableResult
    static func copyShop(to directory: URL) throws -> URL {
        for name in [shopMetamodel, shopModel] {
            try FileManager.default.copyItem(at: try shop(name), to: directory.appendingPathComponent(name))
        }
        return directory.appendingPathComponent(shopModel)
    }
}

/// Loads the shop fixture and creates an evaluator for it.
///
/// - Parameters:
///   - metamodels: The metamodels to give as if on the command line.
///   - options: The behaviours of expressions.
/// - Returns: The evaluator.
/// - Throws: An error if the fixture cannot be loaded.
@MainActor
func shopEvaluator(metamodels: [String] = [], options: AQLOptions = .standard) async throws -> ExpressionEvaluator {
    let loaded = try await ModelLoader(metamodels: metamodels, settings: .init()).load([try Fixture.shop(Fixture.shopModel).path])
    return await ExpressionEvaluator(models: loaded, options: options)
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

/// The location of the built swift-aql executable, beside the bundle of the tests.
///
/// - Returns: The path of the executable.
/// - Throws: ``SwiftAQLTestError/executableNotFound(_:)`` if it has not been built.
func swiftAQLExecutablePath() throws -> String {
    #if os(Windows)
        let name = SwiftAQLVocabulary.toolName + ".exe"
    #else
        let name = SwiftAQLVocabulary.toolName
    #endif
    var directory = Bundle.module.bundleURL.deletingLastPathComponent()
    while directory.pathExtension == "xctest" || ["Contents", "Resources"].contains(directory.lastPathComponent) {
        directory = directory.deletingLastPathComponent()
    }
    let path = directory.appendingPathComponent(name).path
    guard FileManager.default.fileExists(atPath: path) else { throw SwiftAQLTestError.executableNotFound(path) }
    return path
}

/// Runs the tool with arguments.
///
/// The preset of the semantics is not inherited from the environment of the tests, so that the
/// tool runs with its defaults unless a test says otherwise.
///
/// - Parameters:
///   - arguments: The arguments.
///   - directory: The working directory, or `nil` for that of the tests.
///   - environment: Environment variables to set or, with `nil`, to remove.
/// - Returns: The result of the run.
/// - Throws: An error if the tool cannot be started.
func runSwiftAQL(
    _ arguments: [String], in directory: URL? = nil, environment: [String: String?] = [:]
) async throws -> ToolRun {
    var values: [Environment.Key: String?] = ["SWIFT_MODELLING_SEMANTICS": nil]
    for (key, value) in environment { values[Environment.Key(stringLiteral: key)] = value }
    let result = try await Subprocess.run(
        .path(FilePath(try swiftAQLExecutablePath())),
        arguments: Arguments(arguments),
        environment: .inherit.updating(values),
        workingDirectory: directory.map { FilePath($0.path) },
        output: .string(limit: 1 << 20),
        error: .string(limit: 1 << 20))
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
