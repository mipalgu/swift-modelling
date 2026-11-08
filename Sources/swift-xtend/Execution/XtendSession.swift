//
// XtendSession.swift
// swift-xtend
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingCommandLine
import Xtend

/// An Xtend program together with the models it works on.
///
/// A session reads the Xtend sources (reporting a fallback of the encoding on standard error),
/// registers the metamodels, loads the models and builds the program, whose warnings are
/// reported on standard error. The classes of the program can then be chosen and run.
@MainActor
struct XtendSession {
    /// The resource set that holds the metamodels and models.
    let resourceSet: ResourceSet

    /// The loaded models, in command line order.
    let models: [Resource]

    /// The program that the sources declare.
    let program: XtendProgram

    /// The classes that the sources declare, in source order.
    var classes: [XtendClass] { program.parseResults.flatMap(\.file.classes) }

    /// Opens a session.
    ///
    /// - Parameters:
    ///   - options: The options of the command line.
    /// - Returns: The session.
    /// - Throws: ``SwiftXtendError`` if a file does not exist or the sources have errors, and the
    ///   errors of metamodel registration, of reading sources and of loading models.
    static func open(_ options: ProgramOptions) async throws -> XtendSession {
        let settings = try options.semanticsOptions.settings()
        let encoding = options.encodingOptions.encoding(settings: settings)
        var sources: [XtendSource] = []
        for path in [options.source] + options.includes {
            guard FileManager.default.isReadableFile(atPath: path) else { throw SwiftXtendError.sourceNotFound(path) }
            sources.append(XtendSource(document: path, text: try SourceFile.text(at: path, encoding: encoding)))
        }
        for path in options.models where !FileManager.default.fileExists(atPath: path) {
            throw SwiftXtendError.modelNotFound(path)
        }
        let loadOptions = options.formatOptions.ecoreLoadOptions(settings: settings)
        let resourceSet = settings.makeResourceSet()
        for metamodel in options.metamodelOptions.metamodels {
            if options.verbose { report("Registering metamodel \(metamodel)") }
            try await MetamodelRegistration.registerMetamodels(
                at: metamodel, into: resourceSet, announcement: "", verbose: false, options: loadOptions)
        }
        var models: [Resource] = []
        for path in options.models {
            if options.verbose { report("Loading model \(path)") }
            models.append(try await load(model: path, into: resourceSet, options: loadOptions))
        }
        var packages: [EPackage] = []
        var seen = Set<String>()
        let ecoreURI = await resourceSet.ecorePackage.nsURI
        for uri in await resourceSet.getMetamodelURIs() where uri != ecoreURI {
            if let package = await resourceSet.getMetamodel(uri: uri), seen.insert(package.nsURI + package.name).inserted {
                packages.append(package)
            }
        }
        let program = XtendProgram(sources: sources, metamodels: packages)
        FileDiagnosticReport.write(program.diagnostics)
        let errors = program.errors.count
        guard errors == 0 else { throw SwiftXtendError.invalidProgram(errors) }
        return XtendSession(resourceSet: resourceSet, models: models, program: program)
    }

    /// Loads one model into a resource set.
    ///
    /// A file that holds a metamodel is registered, and its first package becomes the content
    /// of the resource.
    ///
    /// - Parameters:
    ///   - path: The path of the model file.
    ///   - resourceSet: The resource set that receives the resource.
    ///   - options: The options with which metamodels are read.
    /// - Returns: The resource that holds the model.
    /// - Throws: The errors of metamodel registration and of the model reader.
    private static func load(model path: String, into resourceSet: ResourceSet, options: EcoreLoadOptions) async throws -> Resource {
        let url = URL(fileURLWithPath: path)
        if await MetamodelRegistration.holdsMetamodel(at: path) {
            let package = try await MetamodelRegistration.registerMetamodel(
                at: path, into: resourceSet, options: options)
            let resource = await resourceSet.createResource(uri: url.absoluteString)
            await resource.add(package)
            return resource
        }
        let format = try ModelFileFormat.detectedInstanceFormat(of: url)
        return try await ModelIO.load(
            url: url, format: format, resourceSet: resourceSet,
            options: ModelIO.LoadOptions(requiresMetamodel: false)
        ).resource
    }

    /// Chooses the class to use.
    ///
    /// - Parameter name: The simple or qualified name that `--class` gives, if any.
    /// - Returns: The class with that name, or the only class of the program if no name is given.
    /// - Throws: ``SwiftXtendError/noClasses``, ``SwiftXtendError/ambiguousClass(_:)`` or
    ///   ``SwiftXtendError/classNotFound(_:_:)``.
    func selectClass(named name: String?) throws -> XtendClass {
        let all = classes
        guard !all.isEmpty else { throw SwiftXtendError.noClasses }
        guard let name else {
            guard all.count == 1 else { throw SwiftXtendError.ambiguousClass(all.map(\.qualifiedName)) }
            return all[0]
        }
        guard let found = all.first(where: { $0.qualifiedName == name }) ?? all.first(where: { $0.name == name }) else {
            throw SwiftXtendError.classNotFound(name, all.map(\.qualifiedName))
        }
        return found
    }

    /// Reports a line of progress on standard error.
    ///
    /// - Parameter message: The message.
    nonisolated static func report(_ message: String) {
        StandardStreams.writeToStandardError(message + "\n")
    }
}
