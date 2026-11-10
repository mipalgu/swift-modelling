//
// TestSupport.swift
// swift-epsilon-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Subprocess
import Testing

@testable import swift_epsilon

#if canImport(System)
    import System
#else
    import SystemPackage
#endif

/// Errors that the support code of the tests reports.
enum SwiftEpsilonTestError: Error, CustomStringConvertible {
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

/// The fixtures that the tests read: a small bank, a ledger to transform it into, and
/// programs of every Epsilon language.
enum Fixture {
    /// The directory of the bank fixture, relative to the resources of the tests.
    static let bankDirectory = "bank"

    /// The directory that holds the fixtures within the resource bundle of the tests.
    static let resourcesDirectory = "Resources"

    /// The metamodel of the bank.
    static let bankMetamodel = "Bank.ecore"

    /// The metamodel of the ledger.
    static let ledgerMetamodel = "Ledger.ecore"

    /// The model of the bank.
    static let bankModel = "bank.xmi"

    /// Every file of the bank fixture.
    static let files = [
        bankMetamodel, ledgerMetamodel, bankModel, "report.eol", "greeting.eol", "failing.eol", "invalid.eol",
        "deposit.eol", "recursion.eol", "summary.eol", "rules.evl", "critiques.evl", "valid.evl", "bank2ledger.etl",
        "accounts.egl", "account.egl", "accounts.egx",
    ]

    /// The location of a file of the bank fixture.
    ///
    /// The resource bundle of the tests is laid out differently by the build systems and
    /// platforms, so the bundle is asked for the file first, and the layouts in which a
    /// copied resource directory can appear are then tried in turn.
    ///
    /// - Parameter name: The name of the file.
    /// - Returns: Its location within the resources of the tests.
    /// - Throws: ``SwiftEpsilonTestError/fixtureNotFound(_:)``, naming every location that was
    ///   tried, if the file does not exist.
    static func bank(_ name: String) throws -> URL {
        let bundle = Bundle.module
        let subdirectory = resourcesDirectory + "/" + bankDirectory
        if let url = bundle.url(forResource: name, withExtension: nil, subdirectory: subdirectory) {
            return url
        }
        let roots = [bundle.resourceURL, bundle.bundleURL, bundle.bundleURL.appendingPathComponent("Contents/Resources")]
        let candidates = roots.compactMap { $0?.appendingPathComponent(subdirectory).appendingPathComponent(name) }
        if let url = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
            return url
        }
        let tried = candidates.map(\.path).joined(separator: ", ")
        throw SwiftEpsilonTestError.fixtureNotFound("\(name) (tried: \(tried))")
    }

    /// Creates an empty directory for one test.
    ///
    /// The directory holds an empty `.git` directory, so that no configuration file of an
    /// enclosing directory is found from it.
    ///
    /// - Returns: The directory.
    /// - Throws: An error if the directory cannot be created.
    static func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("swift-epsilon-tests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url.appendingPathComponent(".git"), withIntermediateDirectories: true)
        return url
    }

    /// Creates a directory for one test that holds a copy of every file of the bank fixture.
    ///
    /// - Returns: The directory.
    /// - Throws: An error if a file cannot be copied.
    static func bankDirectoryCopy() throws -> URL {
        let directory = try temporaryDirectory()
        for name in files {
            try FileManager.default.copyItem(at: try bank(name), to: directory.appendingPathComponent(name))
        }
        return directory
    }
}

/// Loads the bank fixture into a workspace, as the commands do.
///
/// - Parameters:
///   - models: The values of `--model` (default: the bank as `Bank`).
///   - targets: The values of `--target` (default: none).
///   - stores: The values of `--store` (default: none).
///   - metamodels: The names of the metamodel files of the fixture (default: the bank and the ledger).
///   - parameters: The parameters of the run (default: none).
///   - directory: The directory that holds the files, or `nil` for the fixture itself.
/// - Returns: The workspace.
/// - Throws: The errors of loading the workspace.
func bankWorkspace(
    models: [String]? = nil, targets: [String] = [], stores: [String] = [],
    metamodels: [String] = [Fixture.bankMetamodel, Fixture.ledgerMetamodel], parameters: [String: ParameterValue] = [:],
    in directory: URL? = nil
) async throws -> ModelWorkspace {
    let path: (String) throws -> String = { name in
        try directory.map { $0.appendingPathComponent(name).path } ?? Fixture.bank(name).path
    }
    let models = try models ?? ["Bank=" + path(Fixture.bankModel)]
    var configuration = RunConfiguration(plan: try ModelPlan(models: models, targets: targets, stores: stores))
    configuration.metamodels = try metamodels.map(path)
    configuration.parameters = parameters
    return try await ModelWorkspace.load(configuration)
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

/// The location of the built swift-epsilon executable, beside the bundle of the tests.
///
/// - Returns: The path of the executable.
/// - Throws: ``SwiftEpsilonTestError/executableNotFound(_:)`` if it has not been built.
func swiftEpsilonExecutablePath() throws -> String {
    #if os(Windows)
        let name = SwiftEpsilonVocabulary.toolName + ".exe"
    #else
        let name = SwiftEpsilonVocabulary.toolName
    #endif
    var directory = Bundle.module.bundleURL.deletingLastPathComponent()
    while directory.pathExtension == "xctest" || ["Contents", "Resources"].contains(directory.lastPathComponent) {
        directory = directory.deletingLastPathComponent()
    }
    let path = directory.appendingPathComponent(name).path
    guard FileManager.default.fileExists(atPath: path) else { throw SwiftEpsilonTestError.executableNotFound(path) }
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
func runSwiftEpsilon(
    _ arguments: [String], in directory: URL? = nil, environment: [String: String?] = [:]
) async throws -> ToolRun {
    var values: [Environment.Key: String?] = ["SWIFT_MODELLING_SEMANTICS": nil]
    for (key, value) in environment { values[Environment.Key(stringLiteral: key)] = value }
    let result = try await Subprocess.run(
        .path(FilePath(try swiftEpsilonExecutablePath())),
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

/// The arguments that bind the bank model and both metamodels of the fixture, relative to a
/// copy of the fixture.
let bankArguments = [
    "--model", "Bank=" + Fixture.bankModel, "-m", Fixture.bankMetamodel, "-m", Fixture.ledgerMetamodel,
]
