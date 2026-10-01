//
// GenerationProgressStrategy.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import MTL

/// A generation strategy that reports each finished file and passes everything else on.
///
/// The strategy wraps another strategy, normally the file system strategy. It remembers the files
/// that were completed and tells a progress receiver about each of them. Text that a template
/// writes outside any file block is kept in memory and discarded, so that it never reaches the disk.
actor GenerationProgressStrategy: MTLGenerationStrategy {
    private let base: any MTLGenerationStrategy
    private let outputDirectory: URL
    private let total: Int?
    private let report: GenerationProgressReporter
    private let discarding = MTLInMemoryStrategy()
    private var discarded: Set<ObjectIdentifier> = []
    private var targets: [ObjectIdentifier: String] = [:]
    private var finished: [URL] = []

    /// The files completed so far, in order.
    var completedFiles: [URL] { finished }

    /// Creates a progress strategy.
    ///
    /// - Parameters:
    ///   - base: The strategy that writes the files.
    ///   - outputDirectory: The directory that relative file names are resolved against.
    ///   - total: The number of files that will be written, if known.
    ///   - report: The receiver of progress reports.
    init(
        wrapping base: any MTLGenerationStrategy, outputDirectory: URL, total: Int?,
        report: @escaping GenerationProgressReporter
    ) {
        self.base = base
        self.outputDirectory = outputDirectory
        self.total = total
        self.report = report
    }

    @MainActor
    func createWriter(
        url: String, mode: MTLOpenMode, charset: String, indentation: MTLIndentation
    ) async throws -> MTLWriter {
        if url == GenerationProgressStrategy.mainOutputName {
            let writer = try await discarding.createWriter(
                url: url, mode: mode, charset: charset, indentation: indentation)
            await discard(writer)
            return writer
        }
        let writer = try await base.createWriter(
            url: url, mode: mode, charset: charset, indentation: indentation)
        await remember(writer, url: url)
        return writer
    }

    @MainActor
    func finalizeWriter(_ writer: MTLWriter) async throws {
        if await isDiscarded(writer) {
            try await discarding.finalizeWriter(writer)
            return
        }
        try await base.finalizeWriter(writer)
        await complete(writer)
    }

    @MainActor
    func existingContent(url: String) async -> String? {
        await base.existingContent(url: url)
    }

    /// The name under which the template engine reports text written outside any file block.
    static let mainOutputName = "stdout"

    private func discard(_ writer: MTLWriter) {
        discarded.insert(ObjectIdentifier(writer))
    }

    private func isDiscarded(_ writer: MTLWriter) -> Bool {
        discarded.remove(ObjectIdentifier(writer)) != nil
    }

    private func remember(_ writer: MTLWriter, url: String) {
        targets[ObjectIdentifier(writer)] = url
    }

    private func complete(_ writer: MTLWriter) {
        guard let path = targets.removeValue(forKey: ObjectIdentifier(writer)) else { return }
        let file =
            path.hasPrefix("/")
            ? URL(fileURLWithPath: path) : outputDirectory.appendingPathComponent(path)
        finished.append(file.standardizedFileURL)
        report(
            GenerationProgressUpdate(
                message: "Generated \(file.lastPathComponent)", completed: finished.count, total: total))
    }
}
