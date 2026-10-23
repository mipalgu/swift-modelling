//
// TemplateSetLocator.swift
// ModellingPipeline
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import ModellingGenerators

/// Finds and assembles template sets below a list of resource directories.
///
/// A resource directory holds template sets in the layout of the bundled one: a directory for
/// each language, named after it, with a `templateset.json` descriptor. The locator searches its
/// ``bundledRoots`` in order, so that a client library ships its own sets in its resource bundle
/// and finds them like the sets of ``ModellingGenerators``, whose directory is the default root.
///
/// A template set can also be named by its directory, which then stands on its own; see
/// ``assemble(templateSet:templatePaths:)``.
///
/// ## Example
///
/// ```swift
/// let roots = TemplateSet.defaultBundledRoots + [clientTemplatesDirectory]
/// let locator = TemplateSetLocator(bundledRoots: roots)
/// let set = try locator.assemble(language: "c")
/// defer { set.remove() }
/// ```
public struct TemplateSetLocator: Sendable, Equatable {
    /// The directories that hold template sets, in search order.
    ///
    /// Every root that holds a set of a language contributes to it, and a later root replaces
    /// the files of an earlier one.
    public var bundledRoots: [URL]

    /// Creates a locator.
    ///
    /// - Parameter bundledRoots: The directories that hold template sets, in search order
    ///   (default: the directory of the template sets bundled with ``ModellingGenerators``).
    public init(bundledRoots: [URL] = TemplateSet.defaultBundledRoots) {
        self.bundledRoots = bundledRoots
    }

    /// The languages for which a template set exists.
    ///
    /// - Parameter templatePaths: The override directories to include in the search.
    /// - Returns: The sorted names of the languages.
    public func availableLanguages(templatePaths: [URL] = []) -> [String] {
        TemplateSet.availableLanguages(templatePaths: templatePaths, bundledRoots: bundledRoots)
    }

    /// The code styles that the template sets offer.
    ///
    /// - Returns: The languages that offer code styles, sorted by name, each with the names of its
    ///   styles sorted and the name of its default style, if it has one.
    public func codeStyles() -> [(language: String, styles: [String], defaultStyle: String?)] {
        TemplateSet.codeStyles(bundledRoots: bundledRoots)
    }

    /// Assembles the template set of a language.
    ///
    /// - Parameters:
    ///   - language: The language, which names the template set.
    ///   - templatePaths: Override directories, searched after the roots; later entries take
    ///     precedence over earlier ones.
    /// - Returns: The assembled set; call ``TemplateSet/remove()`` when it is no longer needed.
    /// - Throws: The errors of ``TemplateSet/assemble(language:templatePaths:bundledRoots:)``.
    public func assemble(language: String, templatePaths: [URL] = []) throws -> TemplateSet {
        try TemplateSet.assemble(language: language, templatePaths: templatePaths, bundledRoots: bundledRoots)
    }

    /// Assembles a template set named by its directory or by its language.
    ///
    /// A reference that names an existing directory with a descriptor selects the set in that
    /// directory, without the sets of the roots. Any other reference that contains a path
    /// separator is rejected, as it names no template set directory. A plain name is the
    /// language of a set below the roots.
    ///
    /// - Parameters:
    ///   - reference: The path of a template set directory, or the name of a language.
    ///   - templatePaths: Override directories; later entries take precedence over earlier ones.
    /// - Returns: The assembled set; call ``TemplateSet/remove()`` when it is no longer needed.
    /// - Throws: ``GenerationError/templateSetInvalid(_:_:)`` if a path names no directory with a
    ///   descriptor, and the errors of ``assemble(language:templatePaths:)``.
    public func assemble(templateSet reference: String, templatePaths: [URL] = []) throws -> TemplateSet {
        let directory = URL(fileURLWithPath: reference).standardizedFileURL
        if Self.isTemplateSet(directory) {
            return try TemplateSet.assemble(
                language: directory.lastPathComponent, templatePaths: templatePaths,
                bundledRoots: [directory.deletingLastPathComponent()])
        }
        guard !reference.contains(where: Self.pathSeparators.contains) else {
            throw GenerationError.templateSetInvalid(
                reference, "there is no directory with a \(TemplateSetConstants.descriptorFileName) descriptor")
        }
        return try assemble(language: reference, templatePaths: templatePaths)
    }

    /// The characters that separate the components of a path.
    static let pathSeparators: Set<Character> = ["/", "\\"]

    /// Reports whether a directory holds a template set.
    ///
    /// - Parameter directory: The directory to examine.
    /// - Returns: `true` if the directory contains a descriptor.
    public static func isTemplateSet(_ directory: URL) -> Bool {
        FileManager.default.fileExists(
            atPath: directory.appendingPathComponent(TemplateSetConstants.descriptorFileName).path)
    }
}
