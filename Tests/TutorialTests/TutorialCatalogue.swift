//
// TutorialCatalogue.swift
// TutorialTests
//
// Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// A code directive of a tutorial, which shows a resource under a name.
///
/// A step either shows a file that the reader saves under ``name``, a shell script that the reader
/// runs (named ``TutorialReplayConfiguration/terminalCodeName``), or text that is only shown, such
/// as the output of a command or an excerpt of a generated file.
struct TutorialCode: Sendable, Equatable {
    /// The name that the tutorial shows above the code, which is the file name for a file to save.
    let name: String

    /// The name of the resource that holds the code.
    let file: String

    /// The line of the tutorial file on which the directive starts.
    let line: Int

    /// What the reader does with this code.
    var kind: Kind {
        if name == TutorialReplayConfiguration.terminalCodeName { return .terminal }
        if TutorialCode.isDisplayLabel(name) { return .display }
        return .file
    }

    /// What the reader does with the code of a directive.
    enum Kind: Sendable, Equatable {
        /// The reader runs the code as a shell script in the working directory.
        case terminal

        /// The reader saves the code under its name in the working directory.
        case file

        /// The reader only reads the code, such as the output of a command or an excerpt.
        case display
    }

    /// Whether a name labels code that is only shown rather than a file to save.
    ///
    /// Text that a command printed is named ``TutorialReplayConfiguration/outputCodeName``, and an
    /// excerpt of a file carries a remark in parentheses after the file name, such as
    /// `Book.java (excerpt)`. Neither names a file that the reader creates.
    ///
    /// - Parameter name: The name of a code directive.
    /// - Returns: `true` if the name is a label for code that is only shown.
    static func isDisplayLabel(_ name: String) -> Bool {
        if name == TutorialReplayConfiguration.outputCodeName { return true }
        guard name.hasSuffix(")"), let open = name.lastIndex(of: "("), open > name.startIndex else {
            return false
        }
        return name[name.index(before: open)].isWhitespace
    }
}

/// A tutorial file of the documentation catalogue.
struct TutorialDocument: Sendable {
    /// The location of the tutorial file.
    let url: URL

    /// The series the tutorial belongs to: its directory relative to the tutorials directory.
    let series: String

    /// The name of the tutorial file without its extension, by which the table of contents refers to it.
    let name: String

    /// The code directives of the tutorial in document order.
    let codes: [TutorialCode]

    /// The identifier of the tutorial, made of its series and its name.
    var identifier: String { series.isEmpty ? name : "\(series)/\(name)" }
}

/// The outcome of looking up the resource that a code directive names.
enum ResourceResolution: Sendable, Equatable {
    /// Exactly one resource has the name.
    case found(URL)

    /// No resource has the name.
    case missing

    /// Several resources have the name, so the one that DocC shows is undetermined.
    case ambiguous([URL])
}

/// The resources of the documentation catalogue, by file name.
///
/// DocC finds the resource of a code directive by its file name anywhere below the resources
/// directory, so a name must belong to exactly one file.
struct TutorialResourceIndex: Sendable {
    /// The files of the resources directory, by file name, each list sorted by path.
    let filesByName: [String: [URL]]

    /// Indexes the files below a resources directory.
    ///
    /// - Parameter directory: The resources directory of the catalogue.
    /// - Throws: An error if the directory cannot be read.
    init(directory: URL) throws {
        var index: [String: [URL]] = [:]
        let keys: [URLResourceKey] = [.isRegularFileKey]
        guard
            let enumerator = FileManager.default.enumerator(
                at: directory, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles])
        else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: directory.path])
        }
        for case let url as URL in enumerator {
            guard try url.resourceValues(forKeys: Set(keys)).isRegularFile == true else { continue }
            index[url.lastPathComponent, default: []].append(url)
        }
        filesByName = index.mapValues { $0.sorted { $0.path < $1.path } }
    }

    /// Looks up the resource that a code directive names.
    ///
    /// - Parameter file: The value of the `file` argument of the directive.
    /// - Returns: The single resource of that name, or why there is none.
    func resolve(_ file: String) -> ResourceResolution {
        let matches = filesByName[file] ?? []
        switch matches.count {
        case 0: return .missing
        case 1: return .found(matches[0])
        default: return .ambiguous(matches)
        }
    }
}

/// The tutorials of the documentation catalogue, grouped into series in reading order.
///
/// The tutorials of one directory form a series that a reader works through in one working
/// directory. Their order is that of the table of contents; a tutorial that the table of contents
/// does not list follows the listed ones in the order of its file name.
struct TutorialCatalogue: Sendable {
    /// The root directory of the documentation catalogue.
    let root: URL

    /// The tutorials in reading order: series by their first appearance, then by position.
    let tutorials: [TutorialDocument]

    /// The names that the table of contents refers to, in its order.
    let tableOfContents: [String]

    /// The resources of the catalogue.
    let resources: TutorialResourceIndex

    /// The root of this repository.
    static var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    /// The catalogue of this repository, read once.
    static let shared: Result<TutorialCatalogue, any Error> = Result {
        try TutorialCatalogue(
            root: repositoryRoot.appendingPathComponent(TutorialReplayConfiguration.tutorialCatalogue))
    }

    /// Reads the tutorials, the table of contents and the resources of a catalogue.
    ///
    /// - Parameter root: The root directory of the documentation catalogue.
    /// - Throws: An error if a file of the catalogue cannot be read.
    init(root: URL) throws {
        self.root = root
        let tutorialsRoot = root.appendingPathComponent(TutorialReplayConfiguration.tutorialsDirectory)
            .resolvingSymlinksInPath()
        let rootDepth = tutorialsRoot.pathComponents.count
        resources = try TutorialResourceIndex(
            directory: root.appendingPathComponent(TutorialReplayConfiguration.resourcesDirectory))

        var documents: [TutorialDocument] = []
        var contents: [String] = []
        for url in try Self.files(below: tutorialsRoot, withExtension: TutorialReplayConfiguration.tutorialExtension) {
            let text = try String(contentsOf: url, encoding: .utf8)
            if text.contains(TutorialReplayConfiguration.tableOfContentsDirective + "(") {
                contents += Self.tutorialReferences(in: text)
                continue
            }
            let relative = url.resolvingSymlinksInPath().deletingLastPathComponent().pathComponents
                .dropFirst(rootDepth).joined(separator: "/")
            documents.append(
                TutorialDocument(
                    url: url, series: relative, name: url.deletingPathExtension().lastPathComponent,
                    codes: Self.codes(in: text)))
        }
        tableOfContents = contents
        tutorials = Self.readingOrder(of: documents, tableOfContents: contents)
    }

    /// The tutorials of the series that a tutorial belongs to, up to and including it.
    ///
    /// - Parameter tutorial: A tutorial of the catalogue.
    /// - Returns: The tutorials of its series in reading order, ending with the tutorial.
    func seriesPrefix(endingWith tutorial: TutorialDocument) -> [TutorialDocument] {
        let series = tutorials.filter { $0.series == tutorial.series }
        guard let end = series.firstIndex(where: { $0.identifier == tutorial.identifier }) else { return [] }
        return Array(series[...end])
    }

    /// Orders tutorials by series and by their position in the table of contents.
    ///
    /// - Parameters:
    ///   - documents: The tutorials in any order.
    ///   - tableOfContents: The names that the table of contents refers to, in its order.
    /// - Returns: The tutorials in reading order.
    static func readingOrder(of documents: [TutorialDocument], tableOfContents: [String]) -> [TutorialDocument] {
        let position = Dictionary(
            tableOfContents.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        let unlisted = tableOfContents.count
        func key(_ document: TutorialDocument) -> (Int, String) {
            (position[document.name] ?? unlisted, document.name)
        }
        let seriesOrder = Dictionary(grouping: documents, by: \.series)
            .mapValues { $0.map { key($0) }.min { $0 < $1 } ?? (unlisted, "") }
        return documents.sorted { lhs, rhs in
            if lhs.series != rhs.series {
                let left = seriesOrder[lhs.series]!, right = seriesOrder[rhs.series]!
                return left != right ? left < right : lhs.series < rhs.series
            }
            return key(lhs) < key(rhs)
        }
    }

    /// The files with an extension below a directory, sorted by path.
    ///
    /// - Parameters:
    ///   - directory: The directory to search.
    ///   - pathExtension: The extension of the files to find.
    /// - Returns: The files found.
    /// - Throws: An error if the directory cannot be read.
    static func files(below directory: URL, withExtension pathExtension: String) throws -> [URL] {
        guard
            let enumerator = FileManager.default.enumerator(
                at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: directory.path])
        }
        return enumerator.compactMap { $0 as? URL }
            .filter { $0.pathExtension == pathExtension }
            .map(\.standardizedFileURL)
            .sorted { $0.path < $1.path }
    }

    /// The code directives of a tutorial in document order.
    ///
    /// - Parameter text: The text of a tutorial file.
    /// - Returns: The directives that name both a code name and a resource file.
    static func codes(in text: String) -> [TutorialCode] {
        directives(TutorialReplayConfiguration.codeDirective, in: text).compactMap { line, arguments in
            guard let name = arguments[TutorialReplayConfiguration.codeNameArgument],
                let file = arguments[TutorialReplayConfiguration.codeFileArgument]
            else { return nil }
            return TutorialCode(name: name, file: file, line: line)
        }
    }

    /// The resource names that the code directives of a tutorial refer to, with their lines.
    ///
    /// - Parameter text: The text of a tutorial file.
    /// - Returns: Every `file` and `previousFile` argument of a code directive, in document order.
    static func referencedFiles(in text: String) -> [(file: String, line: Int)] {
        directives(TutorialReplayConfiguration.codeDirective, in: text).flatMap { line, arguments in
            [TutorialReplayConfiguration.codeFileArgument, TutorialReplayConfiguration.codePreviousFileArgument]
                .compactMap { arguments[$0] }
                .map { (file: $0, line: line) }
        }
    }

    /// The tutorial names that the table of contents refers to, in its order.
    ///
    /// - Parameter text: The text of the table of contents.
    /// - Returns: The last path component of each documentation link of a tutorial reference.
    static func tutorialReferences(in text: String) -> [String] {
        directives(TutorialReplayConfiguration.tutorialReferenceDirective, in: text).compactMap { _, arguments in
            guard var link = arguments[TutorialReplayConfiguration.tutorialReferenceArgument] else { return nil }
            if link.hasPrefix(TutorialReplayConfiguration.documentationLinkScheme) {
                link.removeFirst(TutorialReplayConfiguration.documentationLinkScheme.count)
            }
            return link.split(separator: "/").last.map(String.init)
        }
    }

    /// The occurrences of a directive in a text, with their arguments.
    ///
    /// Arguments are `label: value` pairs separated by commas. A value is either a string literal in
    /// double quotes, which may contain parentheses and commas, or a bare word that ends at the next
    /// comma, closing parenthesis or white space.
    ///
    /// - Parameters:
    ///   - directive: The directive with its `@` sign, such as `@Code`.
    ///   - text: The text to search.
    /// - Returns: The line on which each occurrence starts and its arguments by label.
    static func directives(_ directive: String, in text: String) -> [(line: Int, arguments: [String: String])] {
        var found: [(line: Int, arguments: [String: String])] = []
        let characters = Array(text)
        let marker = Array(directive + "(")
        var line = 1
        var index = 0
        while index < characters.count {
            if characters[index] == "\n" { line += 1 }
            guard characters[index] == marker[0], characters[index...].starts(with: marker) else {
                index += 1
                continue
            }
            let start = line
            index += marker.count
            var arguments: [String: String] = [:]
            while index < characters.count, characters[index] != ")" {
                while index < characters.count, characters[index].isWhitespace || characters[index] == "," {
                    if characters[index] == "\n" { line += 1 }
                    index += 1
                }
                var label = ""
                while index < characters.count, characters[index] != ":", characters[index] != ")" {
                    label.append(characters[index])
                    index += 1
                }
                guard index < characters.count, characters[index] == ":" else { break }
                index += 1
                while index < characters.count, characters[index] == " " { index += 1 }
                var value = ""
                if index < characters.count, characters[index] == "\"" {
                    index += 1
                    while index < characters.count, characters[index] != "\"" {
                        if characters[index] == "\\", index + 1 < characters.count { index += 1 }
                        value.append(characters[index])
                        index += 1
                    }
                    index += 1
                } else {
                    while index < characters.count, characters[index] != ",", characters[index] != ")",
                        !characters[index].isWhitespace
                    {
                        value.append(characters[index])
                        index += 1
                    }
                }
                arguments[label.trimmingCharacters(in: .whitespacesAndNewlines)] = value
            }
            found.append((line: start, arguments: arguments))
        }
        return found
    }
}
