//
// TemplateRunTests.swift
// ModellingGeneratorsTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import MTL
import Synchronization
import Testing

@testable import ModellingGenerators

/// The messages of the progress reports of a run, in order.
private final class ProgressMessages: Sendable {
    /// The messages received so far.
    private let received = Mutex<[String]>([])

    /// The messages received so far, in order.
    var messages: [String] { received.withLock { $0 } }

    /// Records the message of a progress report.
    ///
    /// - Parameter update: The progress report.
    func record(_ update: GenerationProgressUpdate) {
        received.withLock { $0.append(update.message) }
    }
}

@Suite("Template runs")
struct TemplateRunTests {
    /// A module that writes a file named after the standard output with a file block, another
    /// file, and some text outside any file block.
    static let module = """
        [module console('http://www.eclipse.org/emf/2002/Ecore')]

        [template public main()]
        [file ('\(MTLStandardOutput.fileName)', overwrite)]from the block[/file]
        [file ('other.txt', overwrite)]other[/file]
        outside the blocks
        [/template]
        """

    /// Runs the module into a new directory.
    ///
    /// - Parameters:
    ///   - keepsStandardOutput: Whether the text outside any file block is kept.
    ///   - body: Checks the output and the directory.
    @MainActor
    private func run(
        keepsStandardOutput: Bool, _ body: (TemplateRun.Output, URL) throws -> Void
    ) async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("template-run-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let module = try await MTLParser().parse(Self.module, filename: "console.mtl")
        let updates = ProgressMessages()
        let output = try await TemplateRun.run(
            module: module, mainTemplate: "main", arguments: [], models: [:], services: [],
            options: MTLGeneratorOptions(), outputDirectory: directory, total: 2, mtlOptions: .standard,
            keepsStandardOutput: keepsStandardOutput, progress: { updates.record($0) })
        #expect(updates.messages == ["Generated \(MTLStandardOutput.fileName)", "Generated other.txt"])
        try body(output, directory)
    }

    @Test("writes a file block named after the standard output like any other file", arguments: [false, true])
    @MainActor
    func standardOutputFileBlock(keepsStandardOutput: Bool) async throws {
        try await run(keepsStandardOutput: keepsStandardOutput) { output, directory in
            let file = directory.appendingPathComponent(MTLStandardOutput.fileName)
            let text = try String(contentsOf: file, encoding: .utf8)
            #expect(text == "from the block")
            #expect(
                output.files.map(\.lastPathComponent) == [MTLStandardOutput.fileName, "other.txt"])
            #expect(output.files.first == file.standardizedFileURL)
        }
    }

    @Test("keeps the text outside the file blocks only when asked to")
    @MainActor
    func textOutsideFileBlocks() async throws {
        try await run(keepsStandardOutput: true) { output, _ in
            #expect(output.standardOutput?.contains("outside the blocks") == true)
            #expect(output.standardOutput?.contains("from the block") == false)
        }
        try await run(keepsStandardOutput: false) { output, _ in
            #expect(output.standardOutput == nil)
        }
    }
}
