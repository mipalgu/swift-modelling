//
// ModelFile.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingCommandLine

/// A model that swift-henshin has loaded into the resource set of a module.
struct LoadedModel: Sendable {
    /// The path of the model file, as given on the command line.
    let path: String

    /// The format in which the model was read, and in which it is printed.
    let format: ModelFormat

    /// The resource that holds the objects of the model.
    let resource: Resource
}

/// Reads and writes model files in the formats of the format registry.
///
/// A model is read in the format that its extension names, else in the format of its
/// contents (see `ModelFileFormat`), and written in the format that the extension of the
/// output file names, XMI by default.
enum ModelFile {
    /// Loads a model into a resource set.
    ///
    /// What the reader could not keep, such as a class that no metamodel defines, is
    /// reported on standard error.
    ///
    /// - Parameters:
    ///   - path: The path of the model file, as given on the command line.
    ///   - resourceSet: The resource set that holds the metamodels of the module.
    ///   - log: The log of progress and warnings.
    /// - Returns: The loaded model.
    /// - Throws: ``SwiftHenshinError/fileNotFound(_:)`` if the file does not exist, and the
    ///   error of the reader if it cannot be read.
    static func load(_ path: String, into resourceSet: ResourceSet, log: Log) async throws -> LoadedModel {
        guard FileManager.default.fileExists(atPath: path) else { throw SwiftHenshinError.fileNotFound(path) }
        let url = URL(fileURLWithPath: path)
        let format = try ModelFileFormat.detectedInstanceFormat(of: url)
        log.progress("reading the model \(path) as \(format.rawValue)")
        let loaded = try await ModelIO.load(
            url: url, format: format, resourceSet: resourceSet, options: ModelIO.LoadOptions(requiresMetamodel: false))
        log.report(await loaded.resource.loadDiagnostics, file: path)
        return LoadedModel(path: path, format: format, resource: loaded.resource)
    }

    /// Writes a model to a file in the format that the extension of the file names.
    ///
    /// What cannot be kept is reported on standard error.
    ///
    /// - Parameters:
    ///   - resource: The resource that holds the model.
    ///   - path: The path of the file to write.
    /// - Throws: The error of the serialiser or of the file system.
    static func save(_ resource: Resource, to path: String) async throws {
        let url = URL(fileURLWithPath: path)
        var diagnostics = ConversionDiagnostics()
        try await ModelIO.save(
            resource, to: url, format: ModelFileFormat.instanceFormat(of: url), diagnostics: &diagnostics)
        ConversionWarningReport.write(diagnostics, metamodelGiven: true)
    }

    /// Renders a model as the text of a document.
    ///
    /// - Parameter model: The model, which is rendered in the format in which it was read.
    /// - Returns: The text of the document.
    /// - Throws: The error of the serialiser.
    static func text(of model: LoadedModel) async throws -> String {
        var diagnostics = ConversionDiagnostics()
        let text = try await ModelIO.serialise(
            model.resource, format: model.format, relativeTo: URL(fileURLWithPath: model.path),
            diagnostics: &diagnostics)
        ConversionWarningReport.write(diagnostics, metamodelGiven: true)
        return text
    }
}
