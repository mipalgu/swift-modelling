//
// TestSupport.swift
// swift-xtend-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Subprocess
import Testing

@testable import swift_xtend

#if canImport(System)
    import System
#else
    import SystemPackage
#endif

/// Errors that the support code of the tests reports.
enum SwiftXtendTestError: Error, CustomStringConvertible {
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
    /// The directory of the library fixtures, relative to the resources of the tests.
    static let libraryDirectory = "library"

    /// The directory that holds the fixtures within the resource bundle of the tests.
    static let resourcesDirectory = "Resources"

    /// The metamodel of the library fixture.
    static let libraryMetamodel = "Library.ecore"

    /// The metamodel of the catalogue fixture, the target of the transformation.
    static let catalogueMetamodel = "Catalogue.ecore"

    /// The model of the library fixture.
    static let libraryModel = "library.xmi"

    /// The source of queries and changes on the library.
    static let report = "Report.xtend"

    /// The source of the generator.
    static let catalogueGenerator = "Catalogue.xtend"

    /// The source of the dispatch methods over libraries and books.
    static let labels = "Labels.xtend"

    /// The source of the transformation from libraries to catalogues.
    static let transform = "Transform.xtend"

    /// The location of a file of the fixtures.
    ///
    /// The resource bundle of the tests is laid out differently by the build systems and
    /// platforms, so the bundle is asked for the file first, and the layouts in which a
    /// copied resource directory can appear are then tried in turn.
    ///
    /// - Parameter name: The name of the file.
    /// - Returns: Its location within the resources of the tests.
    /// - Throws: ``SwiftXtendTestError/fixtureNotFound(_:)``, naming every location that was
    ///   tried, if the file does not exist.
    static func library(_ name: String) throws -> URL {
        let bundle = Bundle.module
        let subdirectory = resourcesDirectory + "/" + libraryDirectory
        if let url = bundle.url(forResource: name, withExtension: nil, subdirectory: subdirectory) {
            return url
        }
        let roots = [bundle.resourceURL, bundle.bundleURL, bundle.bundleURL.appendingPathComponent("Contents/Resources")]
        let candidates = roots.compactMap { $0?.appendingPathComponent(subdirectory).appendingPathComponent(name) }
        if let url = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
            return url
        }
        let tried = candidates.map(\.path).joined(separator: ", ")
        throw SwiftXtendTestError.fixtureNotFound("\(name) (tried: \(tried))")
    }

    /// Creates an empty directory for one test.
    ///
    /// - Returns: The directory.
    /// - Throws: An error if the directory cannot be created.
    static func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("swift-xtend-tests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Copies all library fixtures into a directory.
    ///
    /// - Parameter directory: The directory.
    /// - Throws: An error if a file cannot be copied.
    static func copyAll(to directory: URL) throws {
        for name in [
            libraryMetamodel, catalogueMetamodel, libraryModel, report, catalogueGenerator, transform,
            "Maths.xtend", "Escape.xtend", "Latin.xtend", "Pair.xtend", "Helper.xtend", "Wrong.xtend",
            labels,
        ] {
            try FileManager.default.copyItem(at: try library(name), to: directory.appendingPathComponent(name))
        }
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

/// The location of the built swift-xtend executable, beside the bundle of the tests.
///
/// - Returns: The path of the executable.
/// - Throws: ``SwiftXtendTestError/executableNotFound(_:)`` if it has not been built.
func swiftXtendExecutablePath() throws -> String {
    #if os(Windows)
        let name = SwiftXtendVocabulary.toolName + ".exe"
    #else
        let name = SwiftXtendVocabulary.toolName
    #endif
    var directory = Bundle.module.bundleURL.deletingLastPathComponent()
    while directory.pathExtension == "xctest" || ["Contents", "Resources"].contains(directory.lastPathComponent) {
        directory = directory.deletingLastPathComponent()
    }
    let path = directory.appendingPathComponent(name).path
    guard FileManager.default.fileExists(atPath: path) else { throw SwiftXtendTestError.executableNotFound(path) }
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
/// - Returns: The result of the run.
/// - Throws: An error if the tool cannot be started.
func runSwiftXtend(_ arguments: [String], in directory: URL? = nil) async throws -> ToolRun {
    let result = try await Subprocess.run(
        .path(FilePath(try swiftXtendExecutablePath())),
        arguments: Arguments(arguments),
        environment: .inherit.updating(["SWIFT_MODELLING_SEMANTICS": nil]),
        workingDirectory: directory.map { FilePath($0.path) },
        output: .string(limit: 1 << 20),
        error: .string(limit: 1 << 20))
    let status: Int32
    if case .exited(let code) = result.terminationStatus { status = Int32(code) } else { status = -1 }
    return ToolRun(status: status, output: result.standardOutput ?? "", error: result.standardError ?? "")
}

/// Runs the tool in a fresh directory that holds all library fixtures.
///
/// - Parameter body: The test body, given the directory.
/// - Throws: The errors of the body.
func withFixtures(_ body: (URL) async throws -> Void) async throws {
    let directory = try Fixture.temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    try Fixture.copyAll(to: directory)
    try await body(directory)
}
