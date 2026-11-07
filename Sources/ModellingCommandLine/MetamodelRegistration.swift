//
// MetamodelRegistration.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation

/// Loads the Ecore metamodels named on a command line and registers them with a resource set.
///
/// A parser that has a resource set with registered metamodels builds the objects of a model
/// from the classes of those metamodels, and a serialiser writes the classes of the objects of
/// a resource in the set in the namespaces of their metamodels. The commands of the tools
/// register each Ecore file given on their command line, and each metamodel package they have
/// already loaded, through this helper, so that every command reads and writes models in the
/// same way.
public enum MetamodelRegistration {
    /// The file extension of an Ecore metamodel, without the leading dot.
    public static let ecoreExtension = "ecore"

    /// The text that announces the loading of a metamodel in verbose output.
    public static let defaultAnnouncement = "Loading metamodel"

    /// Reports whether a path names an Ecore metamodel file.
    ///
    /// - Parameter path: The file path to examine.
    /// - Returns: `true` if the file extension is ``ecoreExtension``, ignoring case.
    public static func isEcoreFile(_ path: String) -> Bool {
        URL(fileURLWithPath: path).pathExtension.lowercased() == ecoreExtension
    }

    /// Reports whether a path names a file in a format that holds only metamodels.
    ///
    /// The formats are those whose built-in handler has the role `ModelFormatRole.metamodel`,
    /// such as Ecore (`.ecore`) and KM3 (`.km3`). A JSON file may hold a model or a metamodel,
    /// so it is not one of them.
    ///
    /// - Parameter path: The file path to examine.
    /// - Returns: `true` if the file extension, ignoring case, is one of such a format.
    public static func isMetamodelFile(_ path: String) -> Bool {
        handler(for: path).map { $0.role == .metamodel } ?? false
    }

    /// Reports whether a path names a file in a format that may hold a metamodel.
    ///
    /// The formats are those whose built-in handler does not have the role
    /// `ModelFormatRole.model`, such as Ecore, KM3 and JSON.
    ///
    /// - Parameter path: The file path to examine.
    /// - Returns: `true` if the file extension, ignoring case, is one of such a format.
    public static func mayHoldMetamodel(_ path: String) -> Bool {
        handler(for: path).map { $0.role != .model } ?? false
    }

    /// The built-in handler of the format that the extension of a path names.
    ///
    /// - Parameter path: The file path.
    /// - Returns: The handler, or `nil` if the extension names no built-in format.
    private static func handler(for path: String) -> (any ModelFormatHandler)? {
        let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
        guard !fileExtension.isEmpty else { return nil }
        return ModelFormatRegistry.builtInHandlers.first { $0.fileExtensions.contains(fileExtension) }
    }

    /// The line that reports a registered metamodel in verbose output.
    ///
    /// - Parameters:
    ///   - package: The root package of the registered metamodel.
    ///   - uri: The URI under which the package is registered, or `nil` for its namespace URI.
    /// - Returns: The line, naming the package and the URI.
    public static func registeredMessage(for package: EPackage, uri: String? = nil) -> String {
        "  ✓ Registered metamodel '\(package.name)' with URI: \(uri ?? package.nsURI)"
    }

    /// Loads every root package of a metamodel file.
    ///
    /// The file is read as `ModelIO.registerMetamodels(at:in:options:registry:)` reads it,
    /// in the metamodel format that its extension or its contents name: an Ecore document, a
    /// JSON metamodel or a KM3 document, for example. The root packages are loaded together,
    /// so that references between them and to files next to the metamodel resolve, but they
    /// are registered with no resource set. A root package without a namespace URI or prefix
    /// loads with an empty one, as in EMF. The diagnostics of reading the file, such as such a
    /// package, a file read as ISO-8859-1 or a syntax error of KM3, are written to standard
    /// error with ``FileDiagnosticReport`` and do not make the load fail.
    ///
    /// - Parameters:
    ///   - path: The path to the metamodel file.
    ///   - options: The options with which the file is read (default options).
    ///   - debug: Whether the parser prints its trace of an Ecore document to standard output.
    /// - Returns: The root packages, in document order.
    /// - Throws: ``MetamodelRegistrationError/fileNotFound(_:)`` if the file does not exist, or
    ///   the error of the reader if the file cannot be loaded or has no root package.
    public static func loadPackages(
        at path: String, options: EcoreLoadOptions = EcoreLoadOptions(), debug: Bool = false
    ) async throws -> [EPackage] {
        try await load(at: path, options: options, debug: debug).packages
    }

    /// Loads every root package of a metamodel file with the URIs under which it registers them.
    ///
    /// - Parameters:
    ///   - path: The path to the metamodel file.
    ///   - options: The options with which the file is read.
    ///   - debug: Whether the parser prints its trace of an Ecore document to standard output.
    /// - Returns: The root packages in document order, and the URI under which each package
    ///   that is registered is registered: its namespace URI or, for a package without one in
    ///   a format such as KM3, its name.
    /// - Throws: As ``loadPackages(at:options:debug:)``.
    private static func load(
        at path: String, options: EcoreLoadOptions, debug: Bool
    ) async throws -> (packages: [EPackage], registrations: [(uri: String, package: EPackage)]) {
        guard FileManager.default.fileExists(atPath: path) else {
            throw MetamodelRegistrationError.fileNotFound(path)
        }
        let url = URL(fileURLWithPath: path)
        let resourceSet = ResourceSet()
        if debug, await readsAsEcore(url) {
            _ = try await ModelIO.load(
                url: url, format: .ecore, resourceSet: resourceSet,
                options: ModelIO.LoadOptions(ecoreLoadOptions: options, enableDebugging: true))
        }
        let packages = try await ModelIO.registerMetamodels(at: [url], in: resourceSet, options: options)
        let uri = URIReference.canonicalise(url.absoluteString)
        FileDiagnosticReport.write(await resourceSet.getResource(uri: uri)?.loadDiagnostics ?? [], file: path)
        guard !packages.isEmpty else { throw XMIError.noRootObject }
        let identifiers = Set(packages.map(\.id))
        var registrations: [(uri: String, package: EPackage)] = []
        for registered in await resourceSet.getMetamodelURIs().sorted() {
            guard let package = await resourceSet.getMetamodel(uri: registered), identifiers.contains(package.id) else {
                continue
            }
            registrations.append((registered, package))
        }
        let order = Dictionary(packages.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { first, _ in first })
        registrations.sort { (order[$0.package.id] ?? 0, $0.uri) < (order[$1.package.id] ?? 0, $1.uri) }
        return (packages, registrations)
    }

    /// Whether a metamodel file is read as an Ecore document, whose reader can print a trace.
    ///
    /// - Parameter url: The location of the file.
    /// - Returns: `true` unless the extension or, without a known extension, the contents of
    ///   the file name another metamodel format, such as KM3.
    private static func readsAsEcore(_ url: URL) async -> Bool {
        let registry = ModelFormatRegistry.shared
        var handler = await registry.handler(for: url)
        if handler == nil, let data = try? Data(contentsOf: url) {
            handler = await registry.handler(recognising: data)
        }
        guard let handler, handler.role != .model else { return true }
        switch handler.format {
        case .xmi?, .json?, .ecore?: return true
        default: return false
        }
    }

    /// Loads a metamodel and registers it with a resource set.
    ///
    /// Every root package of the file is registered, as
    /// ``registerMetamodels(at:into:announcement:verbose:debug:options:)`` registers them,
    /// and the first is returned.
    ///
    /// - Parameters:
    ///   - path: The path to the metamodel file.
    ///   - resourceSet: The resource set in which to register the metamodel.
    ///   - announcement: The text that introduces the path in verbose output.
    ///   - verbose: Whether to print progress to standard output.
    ///   - debug: Whether the parser prints its trace of the metamodel document to standard output.
    ///   - options: The options with which the file is read (default options).
    /// - Returns: The first root package of the file.
    /// - Throws: ``MetamodelRegistrationError/fileNotFound(_:)`` if the file does not exist, or
    ///   the error of the reader if the file cannot be loaded.
    @MainActor
    @discardableResult
    public static func registerMetamodel(
        at path: String,
        into resourceSet: ResourceSet,
        announcement: String = defaultAnnouncement,
        verbose: Bool = false,
        debug: Bool = false,
        options: EcoreLoadOptions = EcoreLoadOptions()
    ) async throws -> EPackage {
        let packages = try await registerMetamodels(
            at: path, into: resourceSet, announcement: announcement, verbose: verbose, debug: debug, options: options)
        guard let first = packages.first else { throw XMIError.noRootObject }
        return first
    }

    /// Loads a metamodel and registers each of its root packages with a resource set.
    ///
    /// The file may be in any metamodel format, such as Ecore, JSON or KM3 (see
    /// ``loadPackages(at:options:debug:)``). Each root package with a namespace URI is
    /// registered under it, so parsers that use the resource set find its classes, and
    /// resources of the set are written with its namespace. A root package without a namespace
    /// URI is loaded with the others, so that their references to it resolve. It is not
    /// registered if it comes from an Ecore or JSON document; one from a format without
    /// namespaces, such as KM3, is registered under its name, as the ATL tool chain does. A
    /// warning on standard error reports either.
    ///
    /// Verbose output names the file and each registered package. The trace of the XMI parser
    /// is a separate debugging aid that only `debug` turns on.
    ///
    /// - Parameters:
    ///   - path: The path to the metamodel file.
    ///   - resourceSet: The resource set in which to register the metamodel.
    ///   - announcement: The text that introduces the path in verbose output.
    ///   - verbose: Whether to print progress to standard output.
    ///   - debug: Whether the parser prints its trace of the metamodel document to standard output.
    ///   - options: The options with which the file is read (default options).
    /// - Returns: The root packages of the file, in document order.
    /// - Throws: ``MetamodelRegistrationError/fileNotFound(_:)`` if the file does not exist, or
    ///   the error of the reader if the file cannot be loaded.
    @MainActor
    @discardableResult
    public static func registerMetamodels(
        at path: String,
        into resourceSet: ResourceSet,
        announcement: String = defaultAnnouncement,
        verbose: Bool = false,
        debug: Bool = false,
        options: EcoreLoadOptions = EcoreLoadOptions()
    ) async throws -> [EPackage] {
        guard FileManager.default.fileExists(atPath: path) else {
            throw MetamodelRegistrationError.fileNotFound(path)
        }
        if verbose {
            print("\(announcement): \(path)")
        }
        let loaded = try await load(at: path, options: options, debug: debug)
        for (uri, package) in loaded.registrations {
            await resourceSet.registerMetamodel(package, uri: uri)
            if verbose {
                print(registeredMessage(for: package, uri: uri))
            }
        }
        return loaded.packages
    }

    /// Loads Ecore metamodels and registers them with a new resource set.
    ///
    /// Every root package of each file is registered, as
    /// ``registerMetamodels(at:into:announcement:verbose:debug:options:)`` registers them.
    ///
    /// - Parameters:
    ///   - paths: The paths to the `.ecore` files, in command line order.
    ///   - verbose: Whether to print progress to standard output.
    ///   - debug: Whether the parser prints its trace of each metamodel document to standard output.
    ///   - options: The options with which the files are read (default options).
    /// - Returns: The resource set with every metamodel registered.
    /// - Throws: The error of ``registerMetamodels(at:into:announcement:verbose:debug:options:)`` for the
    ///   first file that cannot be registered.
    @MainActor
    public static func resourceSet(
        registering paths: [String], verbose: Bool = false, debug: Bool = false,
        options: EcoreLoadOptions = EcoreLoadOptions()
    ) async throws -> ResourceSet {
        let resourceSet = ResourceSet()
        for path in paths {
            try await registerMetamodels(at: path, into: resourceSet, verbose: verbose, debug: debug, options: options)
        }
        return resourceSet
    }

    /// Registers loaded metamodel packages with a resource set.
    ///
    /// Each package is registered under its namespace URI; a later package with the same URI
    /// replaces an earlier one.
    ///
    /// - Parameters:
    ///   - packages: The root packages of the metamodels.
    ///   - resourceSet: The resource set in which to register them.
    public static func register(_ packages: some Sequence<EPackage>, into resourceSet: ResourceSet) async {
        for package in packages {
            await resourceSet.registerMetamodel(package, uri: package.nsURI)
        }
    }
}

/// An error that occurs while registering a metamodel named on the command line.
public enum MetamodelRegistrationError: Error, CustomStringConvertible, LocalizedError {
    /// The metamodel file does not exist.
    ///
    /// The associated value is the path as given on the command line.
    case fileNotFound(String)

    /// A description of the error, naming the path that was not found.
    public var description: String {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        }
    }

    /// The localised description of the error, which is its ``description``.
    public var errorDescription: String? { description }
}
