//
// TutorialResourceUsage.swift
// TutorialTests
//
// Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// The rules that decide whether a resource of the documentation catalogue is used.
///
/// A resource is used when:
/// - a tutorial or article of the catalogue refers to it by name in an argument of one of
///   ``TutorialReplayConfiguration/resourceDirectives``, or in a Markdown image, where a name
///   without an extension refers to every resource of that stem, and a name refers to its
///   appearance and scale variants as well, such as `chart~dark.svg` or `chart@2x.png`;
/// - the content of a used resource names it by file name, alone or at the end of a relative
///   path, as a script, a template, a transformation or a model does; or
/// - it is the Graphviz source of a used image of the same stem.
///
/// Articles and tutorials below the resources directory are resources themselves, so their
/// references count only through the content rule.
enum TutorialResourceUsage {
    /// The resources of a catalogue that are not used, less the exceptions.
    ///
    /// - Parameters:
    ///   - catalogue: The root directory of the documentation catalogue.
    ///   - exceptions: Resources that count as used, by path relative to the resources directory.
    /// - Returns: The paths of the unused resources relative to the resources directory, sorted.
    /// - Throws: An error if the catalogue cannot be read.
    static func unusedResources(
        inCatalogue catalogue: URL,
        exceptions: [String: String] = TutorialReplayConfiguration.unusedResourceExceptions
    ) throws -> [String] {
        let root = catalogue.resolvingSymlinksInPath()
        let resourcesRoot = root.appendingPathComponent(TutorialReplayConfiguration.resourcesDirectory)
        let resources = try regularFiles(below: resourcesRoot)
        let byName = Dictionary(grouping: resources, by: \.lastPathComponent)
        let byStem = Dictionary(grouping: resources) { stemAndExtension(of: $0.lastPathComponent).stem }

        var used = Set<URL>()
        var pending: [URL] = []
        func use(_ url: URL) {
            guard used.insert(url).inserted else { return }
            pending.append(url)
            let (stem, pathExtension) = stemAndExtension(of: url.lastPathComponent)
            guard TutorialReplayConfiguration.imageExtensions.contains(pathExtension.lowercased()) else { return }
            for source in byStem[stem] ?? []
            where stemAndExtension(of: source.lastPathComponent).pathExtension
                == TutorialReplayConfiguration.graphvizSourceExtension
            {
                use(source)
            }
        }

        let documents = try regularFiles(below: root).filter { url in
            !url.path.hasPrefix(resourcesRoot.path + "/")
                && [TutorialReplayConfiguration.tutorialExtension, TutorialReplayConfiguration.articleExtension]
                    .contains(url.pathExtension)
        }
        for document in documents {
            for reference in directiveReferences(in: try String(contentsOf: document, encoding: .utf8)) {
                let name = reference.split(separator: "/").last.map(String.init) ?? reference
                for candidate in byStem[stemAndExtension(of: name).stem] ?? []
                where Self.reference(name, names: candidate.lastPathComponent) {
                    use(candidate)
                }
            }
        }
        while let resource = pending.popLast() {
            guard let text = try? String(contentsOf: resource, encoding: .utf8) else { continue }
            for token in contentTokens(in: text) {
                for candidate in byName[token] ?? [] { use(candidate) }
            }
        }

        let depth = resourcesRoot.pathComponents.count
        return resources.filter { !used.contains($0) }
            .map { $0.pathComponents.dropFirst(depth).joined(separator: "/") }
            .filter { exceptions[$0] == nil }
            .sorted()
    }

    /// The stem and extension of a resource name without its appearance and scale variants.
    ///
    /// - Parameter name: A file name or a reference, such as `chart~dark@2x.png` or `chart`.
    /// - Returns: The stem without variant markers, such as `chart`, and the extension, which is
    ///   empty when the name has none.
    static func stemAndExtension(of name: String) -> (stem: String, pathExtension: String) {
        var stem = name
        var pathExtension = ""
        if let dot = name.lastIndex(of: "."), dot > name.startIndex {
            stem = String(name[..<dot])
            pathExtension = String(name[name.index(after: dot)...])
        }
        let markers = TutorialReplayConfiguration.appearanceVariantMarkers
            + TutorialReplayConfiguration.scaleVariantMarkers
        var stripped = true
        while stripped {
            stripped = false
            for marker in markers where stem.hasSuffix(marker) && stem.count > marker.count {
                stem.removeLast(marker.count)
                stripped = true
            }
        }
        return (stem, pathExtension)
    }

    /// Whether a reference of a directive names a resource file.
    ///
    /// - Parameters:
    ///   - reference: The name in the directive, with or without an extension.
    ///   - fileName: The file name of a resource.
    /// - Returns: `true` if the stems agree after removing variants, and the reference either has
    ///   no extension or the same one.
    static func reference(_ reference: String, names fileName: String) -> Bool {
        let wanted = stemAndExtension(of: reference)
        let candidate = stemAndExtension(of: fileName)
        return wanted.stem == candidate.stem
            && (wanted.pathExtension.isEmpty || wanted.pathExtension == candidate.pathExtension)
    }

    /// The resource names that the directives and Markdown images of a text refer to, in text order.
    ///
    /// - Parameter text: The text of a tutorial or article.
    /// - Returns: The values of every argument of ``TutorialReplayConfiguration/resourceArguments``
    ///   in one of ``TutorialReplayConfiguration/resourceDirectives``, and the targets of Markdown images.
    static func directiveReferences(in text: String) -> [String] {
        var found: [(line: Int, order: Int, name: String)] = []
        for directive in TutorialReplayConfiguration.resourceDirectives {
            for (line, arguments) in TutorialCatalogue.directives(directive, in: text) {
                for (order, label) in TutorialReplayConfiguration.resourceArguments.enumerated() {
                    if let name = arguments[label], !name.isEmpty { found.append((line, order, name)) }
                }
            }
        }
        for (offset, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            for match in line.matches(of: #/!\[[^\]]*\]\((?<target>[^)\s]+)/#) {
                found.append((offset + 1, 0, String(match.output.target)))
            }
        }
        return found.enumerated()
            .sorted { ($0.element.line, $0.element.order, $0.offset) < ($1.element.line, $1.element.order, $1.offset) }
            .map(\.element.name)
    }

    /// The words of a text that may name a resource file.
    ///
    /// A word is a run of letters, digits, underscores, hyphens and full stops, without leading or
    /// trailing full stops, so that the names in a relative path or at the end of a sentence are found.
    ///
    /// - Parameter text: The content of a resource.
    /// - Returns: The words of the text.
    static func contentTokens(in text: String) -> Set<String> {
        let words = text.split { !($0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" || $0 == ".") }
        return Set(words.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".")) }.filter { !$0.isEmpty })
    }

    /// The regular files below a directory, without hidden files.
    ///
    /// - Parameter directory: The directory to search.
    /// - Returns: The files, with symbolic links in their paths resolved.
    /// - Throws: An error if the directory cannot be read.
    private static func regularFiles(below directory: URL) throws -> [URL] {
        let keys: [URLResourceKey] = [.isRegularFileKey]
        guard
            let enumerator = FileManager.default.enumerator(
                at: directory, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles])
        else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: directory.path])
        }
        return try enumerator.compactMap { $0 as? URL }
            .filter { try $0.resourceValues(forKeys: Set(keys)).isRegularFile == true }
            .map { $0.resolvingSymlinksInPath() }
    }
}
