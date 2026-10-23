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
/// A client library can ship template sets of its own in a resource directory that is laid out
/// like the bundled one, and pass it as one of the roots of
/// ``assemble(language:templatePaths:bundledRoots:)`` and
/// ``availableLanguages(templatePaths:bundledRoots:)``. A set can also share modules with other
/// sets: the directories that its descriptor lists in ``TemplateSetDescriptor/imports`` are copied
/// beside it, so that a module of the set imports them by their qualified names.
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

    /// The directories in which the modules of the set find the modules they import.
    ///
    /// The first entry is ``directory``; a set that imports shared directories also lists the
    /// directory that holds their copies, so that `[import expressions::c/]` finds the module
    /// `c` of an imported directory named `expressions`.
    public let searchPaths: [URL]

    /// Creates the description of an assembled set.
    ///
    /// - Parameters:
    ///   - descriptor: The descriptor of the set.
    ///   - directory: The scratch directory that holds the assembled files.
    ///   - searchPaths: The directories searched for imported modules; `nil` (the default)
    ///     searches the scratch directory only.
    init(descriptor: TemplateSetDescriptor, directory: URL, searchPaths: [URL]? = nil) {
        self.descriptor = descriptor
        self.directory = directory
        self.searchPaths = searchPaths ?? [directory]
    }

    /// The location of the main module.
    public var mainModuleURL: URL {
        directory.appendingPathComponent(descriptor.mainModule)
            .appendingPathExtension(TemplateSetConstants.moduleFileExtension)
    }

    /// The location of the directory that holds the bundled template sets.
    ///
    /// - Returns: The file URL of the directory, or `nil` if the resource bundle does not contain it.
    public static var bundledRoot: URL? {
        GeneratorResources.url(forResource: TemplateSetConstants.bundledDirectory, withExtension: nil)
    }

    /// The directories that hold template sets when no other roots are given.
    ///
    /// - Returns: The directory of the bundled template sets, or no directory if the resource
    ///   bundle does not contain it.
    public static var defaultBundledRoots: [URL] {
        [bundledRoot].compactMap { $0 }
    }

    /// The languages for which a template set exists.
    ///
    /// - Parameter templatePaths: The override directories to include in the search.
    /// - Returns: The sorted names of the languages whose directory holds a descriptor.
    public static func availableLanguages(templatePaths: [URL] = []) -> [String] {
        availableLanguages(templatePaths: templatePaths, bundledRoots: defaultBundledRoots)
    }

    /// The languages for which a template set exists below given roots.
    ///
    /// - Parameters:
    ///   - templatePaths: The override directories to include in the search.
    ///   - bundledRoots: The directories that hold template sets, one directory per language,
    ///     such as ``defaultBundledRoots`` or the resource directory of a client library.
    /// - Returns: The sorted names of the languages whose directory holds a descriptor.
    public static func availableLanguages(templatePaths: [URL] = [], bundledRoots: [URL]) -> [String] {
        var languages = Set<String>()
        for root in bundledRoots + templatePaths {
            let entries =
                (try? FileManager.default.contentsOfDirectory(
                    at: root, includingPropertiesForKeys: nil)) ?? []
            for entry in entries where hasDescriptor(entry) { languages.insert(entry.lastPathComponent) }
        }
        return languages.sorted()
    }

    /// The code styles that the bundled template sets offer.
    ///
    /// - Returns: The bundled languages that offer code styles, sorted by name, each with the
    ///   names of its styles sorted and the name of its default style, if it has one.
    public static func bundledCodeStyles() -> [(language: String, styles: [String], defaultStyle: String?)] {
        codeStyles(bundledRoots: defaultBundledRoots)
    }

    /// The code styles that the template sets below given roots offer.
    ///
    /// A language whose set exists below several roots offers the styles of the descriptor in the
    /// last of them, as an assembled set does.
    ///
    /// - Parameter bundledRoots: The directories that hold template sets, one directory per language.
    /// - Returns: The languages that offer code styles, sorted by name, each with the names of its
    ///   styles sorted and the name of its default style, if it has one.
    public static func codeStyles(bundledRoots: [URL]) -> [(language: String, styles: [String], defaultStyle: String?)] {
        availableLanguages(bundledRoots: bundledRoots).compactMap { language in
            guard
                let directory = bundledRoots.map({ $0.appendingPathComponent(language) }).last(where: hasDescriptor),
                let descriptor = try? readDescriptor(in: directory, language: language),
                !descriptor.styles.isEmpty
            else { return nil }
            return (language, descriptor.styleNames, descriptor.defaultStyle)
        }
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
        try assemble(language: language, templatePaths: templatePaths, bundledRoots: defaultBundledRoots)
    }

    /// Assembles the template set of a language from given roots.
    ///
    /// Every root that holds a directory named after the language contributes its files, in the
    /// order of the roots, so that a later root replaces files of an earlier one; the override
    /// directories follow. The directories that the descriptor lists in
    /// ``TemplateSetDescriptor/imports`` are copied beside the assembled set and added to its
    /// ``searchPaths``. An import is resolved against the directory of each contributing part
    /// that holds a descriptor, latest first, and the first existing directory is used.
    ///
    /// - Parameters:
    ///   - language: The language, which names the template set.
    ///   - templatePaths: Override directories, searched after the roots; later entries take
    ///     precedence over earlier ones.
    ///   - bundledRoots: The directories that hold template sets, one directory per language,
    ///     such as ``defaultBundledRoots`` or the resource directory of a client library.
    /// - Returns: The assembled set.
    /// - Throws: ``GenerationError/templatePathInvalid(_:)`` if an override is not a directory,
    ///   ``GenerationError/unknownLanguage(_:_:)`` if neither a root nor an override has the
    ///   language, and ``GenerationError/templateSetInvalid(_:_:)`` if the descriptor is missing
    ///   or unreadable, an import is not a directory, or the main module is absent.
    public static func assemble(language: String, templatePaths: [URL] = [], bundledRoots: [URL]) throws
        -> TemplateSet
    {
        var sources: [URL] = bundledRoots.map { $0.appendingPathComponent(language) }.filter(hasDescriptor)
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
                language, availableLanguages(templatePaths: templatePaths, bundledRoots: bundledRoots))
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
            let imported = try copyImports(
                of: descriptor, language: language, from: sources.filter(hasDescriptor).reversed(),
                into: scratch)
            let set = TemplateSet(
                descriptor: descriptor, directory: directory,
                searchPaths: imported ? [directory, scratch] : [directory])
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

    /// Copies the directories that a descriptor imports beside the assembled set.
    ///
    /// - Parameters:
    ///   - descriptor: The descriptor of the assembled set.
    ///   - language: The language of the set, for messages.
    ///   - parts: The contributing directories that hold a descriptor, latest first; an import is
    ///     resolved against each of them until an existing directory is found.
    ///   - scratch: The directory that holds the assembled set and receives the imports.
    /// - Returns: Whether any directory was imported.
    /// - Throws: ``GenerationError/templateSetInvalid(_:_:)`` if an import is not a directory,
    ///   shares its name with the set or another import, or cannot be copied.
    private static func copyImports(
        of descriptor: TemplateSetDescriptor, language: String, from parts: [URL], into scratch: URL
    ) throws -> Bool {
        var names: Set<String> = [language]
        for entry in descriptor.imports {
            let candidates = parts.map { $0.appendingPathComponent(entry).standardizedFileURL }
            guard let source = candidates.first(where: isDirectory) else {
                throw GenerationError.templateSetInvalid(
                    language, "the import '\(entry)' is not a directory")
            }
            let name = source.lastPathComponent
            guard names.insert(name).inserted else {
                throw GenerationError.templateSetInvalid(
                    language, "the import '\(entry)' has the name of the set or of another import")
            }
            let target = scratch.appendingPathComponent(name)
            do {
                try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
                try overlay(source, onto: target)
            } catch {
                throw GenerationError.templateSetInvalid(language, String(describing: error))
            }
        }
        return !descriptor.imports.isEmpty
    }

    /// Whether a location is an existing directory.
    private static func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
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
