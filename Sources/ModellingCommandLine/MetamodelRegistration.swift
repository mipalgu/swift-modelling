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

    /// The line that reports a registered metamodel in verbose output.
    ///
    /// - Parameter package: The root package of the registered metamodel.
    /// - Returns: The line, naming the package and its namespace URI.
    public static func registeredMessage(for package: EPackage) -> String {
        "  ✓ Registered metamodel '\(package.name)' with URI: \(package.nsURI)"
    }

    /// Loads an Ecore metamodel and registers it with a resource set.
    ///
    /// The root package of the file is registered under its namespace URI, so parsers that use
    /// the resource set find its classes, and resources of the set are written with its
    /// namespace.
    ///
    /// - Parameters:
    ///   - path: The path to the `.ecore` file.
    ///   - resourceSet: The resource set in which to register the metamodel.
    ///   - announcement: The text that introduces the path in verbose output.
    ///   - verbose: Whether to print progress to standard output.
    /// - Returns: The loaded root package.
    /// - Throws: ``MetamodelRegistrationError/fileNotFound(_:)`` if the file does not exist, or
    ///   the error of the parser if the file cannot be loaded.
    @MainActor
    @discardableResult
    public static func registerMetamodel(
        at path: String,
        into resourceSet: ResourceSet,
        announcement: String = defaultAnnouncement,
        verbose: Bool = false
    ) async throws -> EPackage {
        guard FileManager.default.fileExists(atPath: path) else {
            throw MetamodelRegistrationError.fileNotFound(path)
        }
        if verbose {
            print("\(announcement): \(path)")
        }
        let package = try await EPackage(url: URL(fileURLWithPath: path), enableDebugging: verbose)
        await resourceSet.registerMetamodel(package, uri: package.nsURI)
        if verbose {
            print(registeredMessage(for: package))
        }
        return package
    }

    /// Loads Ecore metamodels and registers them with a new resource set.
    ///
    /// - Parameters:
    ///   - paths: The paths to the `.ecore` files, in command line order.
    ///   - verbose: Whether to print progress to standard output.
    /// - Returns: The resource set with every metamodel registered.
    /// - Throws: The error of ``registerMetamodel(at:into:announcement:verbose:)`` for the first
    ///   file that cannot be registered.
    @MainActor
    public static func resourceSet(registering paths: [String], verbose: Bool = false) async throws -> ResourceSet {
        let resourceSet = ResourceSet()
        for path in paths {
            try await registerMetamodel(at: path, into: resourceSet, verbose: verbose)
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
