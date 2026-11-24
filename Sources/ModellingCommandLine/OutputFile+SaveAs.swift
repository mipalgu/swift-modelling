//
// OutputFile+SaveAs.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingGenerators

/// A model that a command writes to a file.
public struct OutputModel: Sendable {
    /// The resource that holds the model.
    public var resource: Resource

    /// The path of the file, as given on the command line.
    public var path: String

    /// The format of the document, or `nil` to take it from the file extension.
    public var format: ModelFormat?

    /// The options with which the model is written as XMI.
    public var xmiOptions: XMISerializationOptions

    /// Creates a model to write.
    ///
    /// - Parameters:
    ///   - resource: The resource that holds the model.
    ///   - path: The path of the file, as given on the command line.
    ///   - format: The format of the document, or `nil` (the default) to take it from the file
    ///     extension.
    ///   - xmiOptions: The options with which the model is written as XMI (default: `legacy`).
    public init(
        _ resource: Resource, path: String, format: ModelFormat? = nil, xmiOptions: XMISerializationOptions = .legacy
    ) {
        self.resource = resource
        self.path = path
        self.format = format
        self.xmiOptions = xmiOptions
    }

    /// The location of the file.
    public var url: URL { URL(fileURLWithPath: path) }
}

extension OutputFile {
    /// Saves models as the files of a command, each taking the location of its file.
    ///
    /// This is the save as of the Eclipse Modeling Framework, applied to all models of a
    /// command at once: every model takes the URI of its file before any file is written, so
    /// that models that refer to each other refer to each other at their new locations,
    /// relative or absolute as their XMI options choose, whichever is written first. A model
    /// that is written back to the file it was read from keeps its URI. A model written to
    /// a new file alone is written exactly as a copy of it would be, since references within
    /// a model name no file.
    ///
    /// The first file given for a model becomes its location; a further file for the same
    /// model is written as a copy. Each file is written as
    /// ``save(_:to:format:xmiOptions:registry:encoding:warn:)`` writes it. If the files cannot
    /// be given to the models, nothing is written; if a file cannot be written, the models
    /// keep the locations they had before, and the files written already remain.
    ///
    /// - Parameters:
    ///   - models: The models and their files, in the order in which they are written.
    ///   - registry: The registry that provides the format handlers (default: `shared`).
    ///   - encoding: The encoding of the files.
    ///   - warn: Receives the warning that JSON was written in UTF-8 instead of the encoding
    ///     asked for (default: standard error).
    /// - Returns: The warnings recorded while the models were written.
    /// - Throws: ``OutputFileError/sameFile(path:other:)`` if two different models are given
    ///   the same file, ``OutputFileError/fileInUse(path:)`` if a file is that of another
    ///   model the command has read and does not write, and the errors of
    ///   ``save(_:to:format:xmiOptions:registry:encoding:warn:)``.
    @discardableResult
    public static func saveAs(
        _ models: [OutputModel], registry: ModelFormatRegistry = .shared, encoding: TextEncoding,
        warn: (String) -> Void = StandardStreams.writeToStandardError
    ) async throws -> ConversionDiagnostics {
        let relocation: DocumentRelocation
        do {
            relocation = try await DocumentRelocation.relocate(models.map { ($0.resource, $0.url) })
        } catch let error as DocumentRelocationError {
            throw outputError(for: error, models: models)
        }
        var diagnostics = ConversionDiagnostics()
        do {
            for placement in relocation.placements {
                guard let model = models.first(where: { $0.resource === placement.resource && $0.url == placement.url })
                else { continue }
                diagnostics.merge(
                    try await save(
                        model.resource, to: placement.url, format: model.format, xmiOptions: model.xmiOptions,
                        registry: registry, encoding: encoding, warn: warn))
            }
        } catch {
            await relocation.restore()
            throw error
        }
        return diagnostics
    }

    /// Saves a model as the file of a command and gives the model the location of that file.
    ///
    /// The model is written as ``saveAs(_:registry:encoding:warn:)`` writes the models of a
    /// command, which is byte for byte as
    /// ``save(_:to:format:xmiOptions:registry:encoding:warn:)`` writes a copy of it.
    ///
    /// - Parameters:
    ///   - resource: The resource to save.
    ///   - path: The path of the file, as given on the command line.
    ///   - format: The format of the document, or `nil` (the default) to take it from the file
    ///     extension.
    ///   - xmiOptions: The options with which XMI is written (default: `legacy`).
    ///   - registry: The registry that provides the format handlers (default: `shared`).
    ///   - encoding: The encoding of the file.
    ///   - warn: Receives the warning that JSON was written in UTF-8 instead of the encoding
    ///     asked for (default: standard error).
    /// - Returns: The warnings recorded while the model was written.
    /// - Throws: The errors of ``saveAs(_:registry:encoding:warn:)``.
    @discardableResult
    public static func saveAs(
        _ resource: Resource, to path: String, format: ModelFormat? = nil,
        xmiOptions: XMISerializationOptions = .legacy, registry: ModelFormatRegistry = .shared,
        encoding: TextEncoding, warn: (String) -> Void = StandardStreams.writeToStandardError
    ) async throws -> ConversionDiagnostics {
        try await saveAs(
            [OutputModel(resource, path: path, format: format, xmiOptions: xmiOptions)], registry: registry,
            encoding: encoding, warn: warn)
    }

    /// The error that tells the user why models cannot be given their files.
    ///
    /// - Parameters:
    ///   - error: The error of the relocation.
    ///   - models: The models and their files, as given.
    /// - Returns: The error, naming each file by its path as given.
    static func outputError(for error: DocumentRelocationError, models: [OutputModel]) -> OutputFileError {
        func path(of url: URL) -> String { models.first { $0.url == url }?.path ?? url.path }
        switch error {
        case .sameFile(let first, let second):
            return .sameFile(path: path(of: second), other: path(of: first))
        case .fileInUse(let url):
            return .fileInUse(path: path(of: url))
        }
    }
}
