//
// ModuleLoader.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import Henshin
import ModellingCommandLine

/// The formats in which a Henshin module is stored.
enum ModuleFormat: Sendable, Equatable {
    /// A Henshin document in XMI (`.henshin`).
    case xmi
    /// A Henshin Text document (`.henshin_text`).
    case text

    /// The format that the extension of a file names.
    ///
    /// - Parameter path: The path of the file.
    /// - Returns: The format, or `nil` if the extension names neither format.
    init?(path: String) {
        switch URL(fileURLWithPath: path).pathExtension.lowercased() {
        case SwiftHenshinVocabulary.FileExtension.henshin: self = .xmi
        case SwiftHenshinVocabulary.FileExtension.henshinText: self = .text
        default: return nil
        }
    }
}

/// A module that swift-henshin has read, with the resource set that holds its metamodels.
struct LoadedModule: Sendable {
    /// The path of the module file, as given on the command line.
    let path: String

    /// The format of the module file.
    let format: ModuleFormat

    /// The module, as far as it could be read.
    let module: HenshinModule

    /// The resource set that holds the metamodels of the module; models to transform are
    /// loaded into it, so that rule types and model classes are the same.
    let resourceSet: ResourceSet

    /// The metamodel packages that the resource set knows, other than those of Henshin and
    /// Ecore themselves.
    let packages: [EPackage]

    /// The problems of reading a Henshin Text document, with their positions; empty for a
    /// Henshin document in XMI.
    let diagnostics: [SourceDiagnostic]

    /// The errors among the ``diagnostics``.
    var errors: [SourceDiagnostic] { diagnostics.filter { $0.severity == .error } }

    /// The names of the units and rules of the module, in order.
    var unitNames: [String] { module.units.map(\.name) }

    /// The names of the rules of the module, in order.
    var ruleNames: [String] { module.rules.map(\.name) }

    /// Finds a unit or rule by name.
    ///
    /// - Parameter name: The name.
    /// - Returns: The unit.
    /// - Throws: ``SwiftHenshinError/unknownUnit(_:_:)`` if the module has no such unit.
    func unit(named name: String) throws -> TransformationUnit {
        guard let unit = module.unit(named: name) else { throw SwiftHenshinError.unknownUnit(name, unitNames) }
        return unit
    }

    /// Finds a rule by name.
    ///
    /// - Parameter name: The name.
    /// - Returns: The rule.
    /// - Throws: ``SwiftHenshinError/unknownRule(_:_:)`` if the module has no such rule.
    func rule(named name: String) throws -> Rule {
        guard let rule = module.unit(named: name)?.rule else { throw SwiftHenshinError.unknownRule(name, ruleNames) }
        return rule
    }

    /// The names of the classes of the metamodels, by which parameter types name classes.
    var classNames: Set<String> {
        var names = Set<String>()
        /// Collects the classes of a package and its sub-packages.
        func visit(_ package: EPackage) {
            for case let eClass as EClass in package.eClassifiers { names.insert(eClass.name) }
            package.eSubpackages.forEach(visit)
        }
        packages.forEach(visit)
        return names
    }
}

/// Reads Henshin modules from Henshin documents and Henshin Text documents.
///
/// The metamodels given on the command line are registered first. A Henshin document then
/// finds the metamodels it refers to among them, or at the locations it names; a Henshin
/// Text document finds the packages it imports among them, or in the Ecore documents beside
/// it. A Henshin Text document is read in the encoding given with `--encoding`, else as
/// UTF-8 with a fallback to ISO-8859-1.
@MainActor
struct ModuleLoader {
    /// The paths of the metamodels given on the command line.
    let metamodels: [String]

    /// The encoding of Henshin Text documents, or `nil` to detect it.
    let encoding: TextEncoding?

    /// The log of progress and warnings.
    let log: Log

    /// The namespace URI of the Ecore metamodel, whose package is not a metamodel of a module.
    static let ecoreNamespace = "http://www.eclipse.org/emf/2002/Ecore"

    /// Creates a loader.
    ///
    /// - Parameters:
    ///   - metamodels: The paths of the metamodels given on the command line.
    ///   - encoding: The encoding of Henshin Text documents, or `nil` to detect it.
    ///   - log: The log of progress and warnings.
    nonisolated init(metamodels: [String], encoding: TextEncoding?, log: Log) {
        self.metamodels = metamodels
        self.encoding = encoding
        self.log = log
    }

    /// Reads a module, reporting the problems of a Henshin Text document rather than
    /// throwing them.
    ///
    /// Warnings are not written; the caller decides how to report the
    /// ``LoadedModule/diagnostics``.
    ///
    /// - Parameter path: The path of the module file, as given on the command line.
    /// - Returns: The module with its resource set and diagnostics.
    /// - Throws: ``SwiftHenshinError/fileNotFound(_:)`` if the file does not exist,
    ///   ``SwiftHenshinError/unknownModuleFormat(_:)`` if its extension names no module
    ///   format, and the errors of reading the file, a metamodel or a Henshin document.
    func read(_ path: String) async throws -> LoadedModule {
        guard FileManager.default.fileExists(atPath: path) else { throw SwiftHenshinError.fileNotFound(path) }
        guard let format = ModuleFormat(path: path) else { throw SwiftHenshinError.unknownModuleFormat(path) }
        let resourceSet = ResourceSet()
        for metamodel in metamodels {
            log.progress("registering the metamodel \(metamodel)")
            try await MetamodelRegistration.registerMetamodels(
                at: metamodel, into: resourceSet, diagnosticOutput: log.write)
        }
        let url = URL(fileURLWithPath: path)
        log.progress("reading the module \(path)")
        let module: HenshinModule
        var diagnostics: [SourceDiagnostic] = []
        switch format {
        case .xmi:
            module = try await HenshinModuleLoader.load(url: url, resourceSet: resourceSet)
        case .text:
            let text = try SourceFile.read(path, encoding: encoding)
            if let warning = text.warning { log.report([warning], file: path) }
            let translation = try await HenshinTextLoader.translate(
                text: text.text, directory: url.deletingLastPathComponent(), resourceSet: resourceSet)
            module = translation.module
            diagnostics = translation.diagnostics
        }
        return LoadedModule(
            path: path, format: format, module: module, resourceSet: resourceSet,
            packages: await Self.metamodelPackages(in: resourceSet), diagnostics: diagnostics)
    }

    /// Reads a module that must be free of errors, writing the warnings of a Henshin Text
    /// document to standard error.
    ///
    /// - Parameter path: The path of the module file, as given on the command line.
    /// - Returns: The module with its resource set.
    /// - Throws: ``SwiftHenshinError/invalidText(_:_:)`` after writing the errors of a Henshin
    ///   Text document, and the errors of ``read(_:)``.
    func load(_ path: String) async throws -> LoadedModule {
        let loaded = try await read(path)
        log.report(loaded.diagnostics, file: path)
        guard loaded.errors.isEmpty else { throw SwiftHenshinError.invalidText(path, loaded.errors.count) }
        log.progress("read \(loaded.module.units.count) unit(s), \(loaded.module.rules.count) of them rules")
        return loaded
    }

    /// The root packages that a resource set knows, other than those of Henshin and Ecore.
    ///
    /// - Parameter resourceSet: The resource set.
    /// - Returns: The packages of its resources, which the rules of a module refer to, then
    ///   its other registered metamodels, each namespace once.
    static func metamodelPackages(in resourceSet: ResourceSet) async -> [EPackage] {
        let excluded: Set<String> = [HenshinConstants.nsURI, ecoreNamespace]
        var packages: [EPackage] = []
        /// Adds a package unless it is excluded or known already.
        func add(_ package: EPackage) {
            guard !excluded.contains(package.nsURI), !packages.contains(where: { $0.nsURI == package.nsURI }) else { return }
            packages.append(package)
        }
        for resource in await resourceSet.getResources() {
            for case let package as EPackage in await resource.getRootObjects() { add(package) }
        }
        for uri in await resourceSet.getMetamodelURIs(includingSubpackages: false) {
            if let package = await resourceSet.getMetamodel(uri: uri) { add(package) }
        }
        return packages
    }
}
