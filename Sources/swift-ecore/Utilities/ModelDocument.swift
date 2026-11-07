//
// ModelDocument.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import ModellingCommandLine

/// A model or metamodel that a command has read.
///
/// An Ecore file (`.ecore`) or a KM3 file (`.km3`) is read as a metamodel, whose root packages
/// are available as ``packages``. An XMI (`.xmi`) or JSON (`.json`) file is read as a model. A file with another
/// extension is read in the format of its contents. The metamodels named with `--metamodel` are
/// registered with the resource set of the document before it is read, so the objects of a
/// model are instances of the classes those metamodels define.
struct ModelDocument: Sendable {
    /// The path of the file as given on the command line.
    let path: String

    /// The location of the file.
    let url: URL

    /// The format in which the file was read.
    let format: ModelFormat

    /// The resource that holds the objects of the file.
    let resource: Resource

    /// The resource set that holds the resource and the registered metamodels.
    let resourceSet: ResourceSet

    /// The root packages of a metamodel, in document order, or none for a model.
    let packages: [EPackage]

    /// The metamodels that were registered before the file was read.
    let metamodels: [EPackage]

    /// What the parser could not keep, such as classes that no metamodel defines.
    let diagnostics: ConversionDiagnostics

    /// Whether the file is a metamodel rather than a model.
    var isMetamodel: Bool { !packages.isEmpty }

    /// Whether the model was read with at least one registered metamodel.
    var hasMetamodel: Bool { !metamodels.isEmpty }

    /// Whether the reader made up a class that no metamodel defines for an object of the model.
    var hasUntypedClasses: Bool {
        diagnostics.warnings.contains { warning in
            if case .untypedClass = warning.kind { return true }
            return false
        }
    }

    /// The name of the file without its directory.
    var fileName: String { url.lastPathComponent }

    /// The name of the format, as the commands show it.
    var formatName: String { format == .ecore ? ModelVocabulary.ecoreFormatName : format.rawValue.uppercased() }

    /// Reads a model or metamodel file.
    ///
    /// The format follows from the file extension or, for an extension that names no format,
    /// from the contents of the file. The metamodels of `metamodelOptions` are registered
    /// first; a JSON model must then use their classes only. The warnings of reading the file,
    /// such as a root package without a namespace URI, are written to standard error.
    ///
    /// - Parameters:
    ///   - path: The path of the file.
    ///   - metamodelOptions: The metamodels given on the command line.
    ///   - requiresMetamodel: Whether the classes of a JSON model must be defined by a registered
    ///     metamodel, or `nil` to require them whenever a metamodel was given.
    ///   - verbose: Whether to report the metamodels as they are loaded.
    ///   - km3Options: How the data types of a KM3 metamodel are read (default
    ///     `KM3ReadOptions.standard`).
    /// - Returns: The document.
    /// - Throws: ``DocumentError`` if the file does not exist or its format cannot be
    ///   determined, or the error of a metamodel or of the parser.
    static func load(
        path: String,
        metamodelOptions: MetamodelOptions,
        requiresMetamodel: Bool? = nil,
        verbose: Bool = false,
        km3Options: KM3ReadOptions = .standard
    ) async throws -> ModelDocument {
        guard FileManager.default.fileExists(atPath: path) else {
            throw DocumentError.fileNotFound(path)
        }
        let url = URL(fileURLWithPath: path)
        guard let format = ModelFormat.detect(url: url) ?? (try? ModelFormat.detect(contentsOf: url)) else {
            throw DocumentError.unsupportedFormat(url.pathExtension)
        }
        let ecoreLoadOptions = EcoreLoadOptions(km3Options: km3Options)
        let resourceSet = try await metamodelOptions.resourceSet(verbose: verbose, options: ecoreLoadOptions)
            ?? ResourceSet()
        let metamodels = await registeredMetamodels(of: resourceSet)
        let options = ModelIO.LoadOptions(requiresMetamodel: requiresMetamodel, ecoreLoadOptions: ecoreLoadOptions)
        let loaded = try await ModelIO.load(url: url, format: format, resourceSet: resourceSet, options: options)
        FileDiagnosticReport.write(await loaded.resource.loadDiagnostics, file: path)
        return ModelDocument(
            path: path, url: url, format: loaded.format, resource: loaded.resource, resourceSet: resourceSet,
            packages: loaded.packages, metamodels: metamodels, diagnostics: loaded.diagnostics)
    }

    /// The root packages registered with a resource set, without the nested packages.
    ///
    /// - Parameter resourceSet: The resource set.
    /// - Returns: The packages, ordered by namespace URI.
    static func registeredMetamodels(of resourceSet: ResourceSet) async -> [EPackage] {
        var packages: [EPackage] = []
        for uri in await resourceSet.getMetamodelURIs().sorted() {
            if let package = await resourceSet.getMetamodel(uri: uri) { packages.append(package) }
        }
        return packages
    }

    /// The packages that describe the document: its own packages for a metamodel, else the
    /// registered metamodels.
    var describingPackages: [EPackage] { isMetamodel ? packages : metamodels }
}

/// An error that occurs while a command reads a file.
enum DocumentError: Error, LocalizedError, Equatable {
    /// The file does not exist.
    ///
    /// The associated value is the path as given on the command line.
    case fileNotFound(String)

    /// Neither the extension nor the contents of the file name a format that the command reads.
    ///
    /// The associated value is the extension.
    case unsupportedFormat(String)

    /// A localised description of the error.
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .unsupportedFormat(let format):
            return Self.unsupportedFormatDescription(format)
        }
    }

    /// The description of a format that no command reads, listing the supported formats.
    ///
    /// - Parameter format: The extension of the file.
    /// - Returns: For example `Unsupported format: txt (supported: xmi, json, ecore)`.
    static func unsupportedFormatDescription(_ format: String) -> String {
        let supported = ModelFormat.allCases.map(\.fileExtension).joined(separator: ", ")
        return "Unsupported format: \(format) (supported: \(supported))"
    }
}
