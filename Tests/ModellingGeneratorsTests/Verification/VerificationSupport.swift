//
// VerificationSupport.swift
// ModellingGeneratorsTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import ModellingGenerators

/// The neutral lending models that the verification tests export.
enum LendingFixtures {
    /// The directory of the lending fixtures among the resources of the tests.
    ///
    /// A missing directory yields a location that does not exist, so that the tests that read
    /// it fail with the name of the missing file.
    static var lendingDirectory: URL {
        (try? Fixtures.url(of: "lending")) ?? URL(fileURLWithPath: "lending")
    }

    /// The lending metamodel.
    static var lendingMetamodel: URL { lendingDirectory.appendingPathComponent("lending.ecore") }

    /// A lending model that conforms to the metamodel and satisfies its invariants.
    static var lendingModel: URL { lendingDirectory.appendingPathComponent("lending.xmi") }

    /// A lending model that violates invariants of the metamodel.
    static var lendingViolations: URL { lendingDirectory.appendingPathComponent("violations.xmi") }

    /// Loads the lending metamodel.
    ///
    /// - Returns: The root package of the lending metamodel.
    /// - Throws: An error if the metamodel cannot be read or holds no package.
    static func lendingPackage() async throws -> EPackage {
        let resource = try await ResourceSet().loadEcoreResource(uri: lendingMetamodel.absoluteString)
        guard let package = await resource.getRootObjects().first as? EPackage else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return package
    }
}

/// The verification exports of the fixtures, written by the generation pipeline.
///
/// Each export runs the pipeline as `swift-ecore generate` does, into a new scratch directory,
/// and returns the text of the files that it wrote; the scratch directory is removed afterwards.
enum VerificationExports {
    /// Exports the lending metamodel.
    ///
    /// - Parameter target: The verification target.
    /// - Returns: The text of each file, by path relative to the output directory.
    /// - Throws: The error of the pipeline.
    @MainActor
    static func metamodel(_ target: VerificationTarget) async throws -> [String: String] {
        try await collect { directory in
            try await GenerationPipeline.generate(
                inputURL: LendingFixtures.lendingMetamodel, language: target.templateSetName,
                outputDirectory: directory, importOptions: GenModelImportOptions(atlOptions: .standard),
                options: GenerationOptions(mtlOptions: .standard))
        }
    }

    /// Exports a lending model.
    ///
    /// - Parameters:
    ///   - model: The model.
    ///   - target: The verification target.
    /// - Returns: The text of each file, by path relative to the output directory.
    /// - Throws: The error of the pipeline.
    @MainActor
    static func model(_ model: URL, _ target: VerificationTarget) async throws -> [String: String] {
        try await collect { directory in
            try await GenerationPipeline.generate(
                modelURL: model, metamodelURL: LendingFixtures.lendingMetamodel,
                language: target.templateSetName, outputDirectory: directory)
        }
    }

    /// Runs an export into a scratch directory and reads back what it wrote.
    ///
    /// - Parameter export: The export, given the output directory.
    /// - Returns: The text of each written file, by path relative to the output directory.
    /// - Throws: The error of the export, or of reading a file.
    @MainActor
    private static func collect(
        _ export: (URL) async throws -> GenerationResult
    ) async throws -> [String: String] {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-verification-tests").appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let result = try await export(directory)
        let base = result.outputDirectory.standardizedFileURL.path + "/"
        var files: [String: String] = [:]
        for file in result.files {
            let path = file.standardizedFileURL.path
            let relative = path.hasPrefix(base) ? String(path.dropFirst(base.count)) : file.lastPathComponent
            files[relative] = try String(contentsOf: file, encoding: .utf8)
        }
        return files
    }
}

/// The location of the expected verification exports.
enum VerificationGoldenFiles {
    /// Whether the tests write the generated text as the expected text.
    ///
    /// Setting the environment variable `VERIFICATION_RECORD_GOLDEN` to `1` writes the generated
    /// text into the sources of the tests, for review before it is accepted.
    static var recording: Bool { ProcessInfo.processInfo.environment["VERIFICATION_RECORD_GOLDEN"] == "1" }

    /// The directory of the expected exports of a target, in the sources of the tests.
    ///
    /// - Parameter target: The verification target.
    /// - Returns: The directory.
    static func sourceDirectory(for target: VerificationTarget) -> URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Resources").appendingPathComponent("lending")
            .appendingPathComponent("expected").appendingPathComponent(target.rawValue)
    }

    /// The directory of the expected exports of a target, in the resources of the tests.
    ///
    /// - Parameter target: The verification target.
    /// - Returns: The directory.
    /// - Throws: An error if the directory is not among the resources.
    static func directory(for target: VerificationTarget) throws -> URL {
        try Fixtures.url(of: "lending/expected/\(target.rawValue)")
    }
}
