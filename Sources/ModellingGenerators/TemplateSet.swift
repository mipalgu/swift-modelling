//
// TemplateSet.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// A template set for one language, assembled from the bundled set and optional override directories.
///
/// The bundled sets live in the `Templates` directory of this library, one directory per
/// language. Directories given as template paths are searched before the bundled set: a file in
/// an override directory replaces the bundled file of the same relative path, so a single module
/// can be customised without copying the rest. An override directory either contains a directory
/// named after the language, or holds the files of the set directly.
///
/// Assembling copies the files into a scratch directory so that modules import each other with
/// the overrides in place. Call ``remove()`` when generation has finished.
///
/// ## Example
///
/// ```swift
/// let set = try TemplateSet.assemble(language: "java", templatePaths: [customisations])
/// defer { set.remove() }
/// print(set.descriptor.mainModule)
/// ```
public struct TemplateSet: Sendable {
    /// The descriptor of the assembled set.
    public let descriptor: TemplateSetDescriptor

    /// The scratch directory that holds the assembled files.
    public let directory: URL

    /// The location of the main module.
    public var mainModuleURL: URL {
        directory.appendingPathComponent(descriptor.mainModule)
            .appendingPathExtension(TemplateSetConstants.moduleFileExtension)
    }

    /// The location of the directory that holds the bundled template sets.
    ///
    /// - Returns: The file URL of the directory, or `nil` if the resource bundle does not contain it.
    public static var bundledRoot: URL? {
        Bundle.module.url(forResource: TemplateSetConstants.bundledDirectory, withExtension: nil)
    }

    /// The languages for which a template set exists.
    ///
    /// - Parameter templatePaths: The override directories to include in the search.
    /// - Returns: The sorted names of the languages whose directory holds a descriptor.
    public static func availableLanguages(templatePaths: [URL] = []) -> [String] {
        var languages = Set<String>()
        for root in ([bundledRoot].compactMap { $0 }) + templatePaths {
            let entries =
                (try? FileManager.default.contentsOfDirectory(
                    at: root, includingPropertiesForKeys: nil)) ?? []
            for entry in entries where hasDescriptor(entry) { languages.insert(entry.lastPathComponent) }
        }
        return languages.sorted()
    }

    /// Assembles the template set of a language.
    ///
    /// - Parameters:
    ///   - language: The language, which names the template set.
    ///   - templatePaths: Override directories, searched before the bundled set; later entries
    ///     take precedence over earlier ones.
    /// - Returns: The assembled set.
    /// - Throws: ``GenerationError/templatePathInvalid(_:)`` if an override is not a directory,
    ///   ``GenerationError/unknownLanguage(_:_:)`` if neither the bundle nor an override has the
    ///   language, and ``GenerationError/templateSetInvalid(_:_:)`` if the descriptor is missing
    ///   or unreadable or the main module is absent.
    public static func assemble(language: String, templatePaths: [URL] = []) throws -> TemplateSet {
        var sources: [URL] = []
        if let bundled = bundledRoot?.appendingPathComponent(language), hasDescriptor(bundled) {
            sources.append(bundled)
        }
        for path in templatePaths {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path.path, isDirectory: &isDirectory),
                isDirectory.boolValue
            else { throw GenerationError.templatePathInvalid(path.path) }
            let nested = path.appendingPathComponent(language)
            var nestedIsDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: nested.path, isDirectory: &nestedIsDirectory),
                nestedIsDirectory.boolValue
            {
                sources.append(nested)
            } else if !hasLanguageDirectories(path) {
                sources.append(path)
            }
        }
        guard !sources.isEmpty else {
            throw GenerationError.unknownLanguage(
                language, availableLanguages(templatePaths: templatePaths))
        }

        let scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent(TemplateSetConstants.scratchDirectoryPrefix)
            .appendingPathComponent(UUID().uuidString)
        let directory = scratch.appendingPathComponent(language)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for source in sources { try overlay(source, onto: directory) }
        } catch {
            try? FileManager.default.removeItem(at: scratch)
            throw GenerationError.templateSetInvalid(language, String(describing: error))
        }

        do {
            let descriptor = try readDescriptor(in: directory, language: language)
            let set = TemplateSet(descriptor: descriptor, directory: directory)
            guard FileManager.default.fileExists(atPath: set.mainModuleURL.path) else {
                throw GenerationError.templateSetInvalid(
                    language, "the main module '\(descriptor.mainModule)' is missing")
            }
            return set
        } catch {
            try? FileManager.default.removeItem(at: scratch)
            throw error
        }
    }

    /// Removes the scratch directory of the assembled set.
    public func remove() {
        try? FileManager.default.removeItem(at: directory.deletingLastPathComponent())
    }

    // MARK: - Helpers

    private static func hasDescriptor(_ directory: URL) -> Bool {
        FileManager.default.fileExists(
            atPath: directory.appendingPathComponent(TemplateSetConstants.descriptorFileName).path)
    }

    /// Whether a directory contains template sets of several languages instead of the files of one.
    private static func hasLanguageDirectories(_ directory: URL) -> Bool {
        let entries =
            (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil))
            ?? []
        return entries.contains { hasDescriptor($0) }
    }

    private static func readDescriptor(in directory: URL, language: String) throws -> TemplateSetDescriptor {
        let url = directory.appendingPathComponent(TemplateSetConstants.descriptorFileName)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw GenerationError.templateSetInvalid(
                language, "the descriptor \(TemplateSetConstants.descriptorFileName) is missing")
        }
        do {
            return try JSONDecoder().decode(TemplateSetDescriptor.self, from: Data(contentsOf: url))
        } catch {
            throw GenerationError.templateSetInvalid(language, "the descriptor is unreadable: \(error)")
        }
    }

    /// Copies the files of a directory into another, replacing files of the same relative path.
    private static func overlay(_ source: URL, onto destination: URL) throws {
        let manager = FileManager.default
        let sourcePath = source.standardizedFileURL.path
        guard
            let enumerator = manager.enumerator(
                at: source, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
        else { return }
        for case let item as URL in enumerator {
            let relative = String(item.standardizedFileURL.path.dropFirst(sourcePath.count + 1))
            let target = destination.appendingPathComponent(relative)
            let isDirectory = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDirectory {
                try manager.createDirectory(at: target, withIntermediateDirectories: true)
            } else {
                try manager.createDirectory(
                    at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
                if manager.fileExists(atPath: target.path) { try manager.removeItem(at: target) }
                try manager.copyItem(at: item, to: target)
            }
        }
    }
}
