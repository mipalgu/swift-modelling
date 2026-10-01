//
// GenerationPipeline+Input.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import GenModel

extension GenerationPipeline {
    /// Generates code from a generator model or an Ecore model.
    ///
    /// A generator model (`.genmodel`) is generated from directly, as
    /// ``generate(genModelURL:language:outputDirectory:options:progress:)`` does. An Ecore model
    /// (`.ecore`) is imported into a temporary generator model first, as
    /// ``ecoreToGenModel(ecoreURLs:options:progress:)`` does, and the temporary model is removed
    /// afterwards.
    ///
    /// - Parameters:
    ///   - inputURL: The location of the `.genmodel` or `.ecore` file.
    ///   - language: The language, which names the template set.
    ///   - outputDirectory: The directory to write below; it is created if necessary.
    ///   - importOptions: The settings of the import of an Ecore model; ignored for a generator model.
    ///   - options: The settings of the generation.
    ///   - progress: A closure that receives progress reports.
    /// - Returns: The files that were written.
    /// - Throws: ``GenerationError/unsupportedInput(_:)`` for any other kind of file, and the errors
    ///   of the import and of the generation.
    @MainActor
    public static func generate(
        inputURL: URL, language: String, outputDirectory: URL,
        importOptions: GenModelImportOptions = GenModelImportOptions(),
        options: GenerationOptions = GenerationOptions(),
        progress: @escaping GenerationProgressReporter = { _ in }
    ) async throws -> GenerationResult {
        let kind = inputURL.pathExtension.lowercased()
        if kind == GenModelConstants.genModelFileExtension {
            return try await generate(
                genModelURL: inputURL, language: language, outputDirectory: outputDirectory,
                options: options, progress: progress)
        }
        guard kind == TemplateSetConstants.metamodelFileExtension else {
            throw GenerationError.unsupportedInput(inputURL.path)
        }
        let scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent(TemplateSetConstants.scratchDirectoryPrefix)
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: scratch) }
        var importing = importOptions
        importing.reload = nil
        importing.output = scratch.appendingPathComponent(defaultOutput(for: inputURL).lastPathComponent)
        let imported = try await ecoreToGenModel(
            ecoreURLs: [inputURL], options: importing,
            progress: { progress(GenerationProgressUpdate(message: $0)) })
        return try await generate(
            genModelURL: imported.url, language: language, outputDirectory: outputDirectory,
            options: options, progress: progress)
    }
}
