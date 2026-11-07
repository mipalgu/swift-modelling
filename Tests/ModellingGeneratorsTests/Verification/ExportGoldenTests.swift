//
// ExportGoldenTests.swift
// ModellingGeneratorsTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@testable import ModellingGenerators

/// Compares the exports of the lending metamodel and models with the expected text.
///
/// Setting the environment variable `VERIFICATION_RECORD_GOLDEN` to `1` writes the generated text
/// as the expected text instead, for review before it is accepted.
@Suite("Verification export golden files", .serialized)
struct ExportGoldenTests {
    /// The exports of the lending metamodel match the expected files.
    @Test("The lending metamodel exports as expected", arguments: VerificationTarget.allCases)
    func exportsMetamodel(target: VerificationTarget) async throws {
        let files = try await VerificationExports.metamodel(target)
        #expect(!files.isEmpty)
        try compare(files, target: target)
    }

    /// The exports of the lending models match the expected files.
    @Test(
        "The lending models export as expected",
        arguments: VerificationTarget.allCases, [LendingFixtures.lendingModel, LendingFixtures.lendingViolations])
    func exportsModel(target: VerificationTarget, model: URL) async throws {
        let files = try await VerificationExports.model(model, target)
        #expect(!files.isEmpty)
        try compare(files, target: target)
    }

    /// Compares exported files with the expected files of a target, or records them.
    ///
    /// - Parameters:
    ///   - files: The text of each exported file, by relative path.
    ///   - target: The verification target.
    /// - Throws: An error if an expected file cannot be read or a recorded one cannot be written.
    private func compare(_ files: [String: String], target: VerificationTarget) throws {
        if VerificationGoldenFiles.recording {
            let directory = VerificationGoldenFiles.sourceDirectory(for: target)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for (path, text) in files {
                let url = directory.appendingPathComponent((path as NSString).lastPathComponent)
                try text.write(to: url, atomically: true, encoding: .utf8)
            }
            return
        }
        let directory = try VerificationGoldenFiles.directory(for: target)
        for (path, text) in files {
            let url = directory.appendingPathComponent((path as NSString).lastPathComponent)
            let expected = try String(contentsOf: url, encoding: .utf8)
            #expect(text == expected, "\(target.rawValue): \(url.lastPathComponent) differs from the expected text")
        }
    }
}
