//
// DocumentedCommands.swift
// TutorialTests
//
// Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Subprocess

#if canImport(System)
    import System
#else
    import SystemPackage
#endif

/// The subcommands and long options that the help page of a tool or subcommand lists.
struct CommandHelpPage: Sendable, Equatable {
    /// The subcommands that the page lists, in its order.
    let subcommands: [String]

    /// The subcommand that runs when none is named, if the page marks one as the default.
    let defaultSubcommand: String?

    /// The long options that the page lists, including the inverted forms of flags.
    let longOptions: Set<String>

    /// Reads the subcommands and long options of a help page.
    ///
    /// Subcommands are the lowercase names indented by two spaces in the section headed
    /// ``TutorialReplayConfiguration/subcommandsHeading``. Options are the names before the
    /// description of every line that starts with two spaces and a hyphen, such as
    /// `  -o, --output <output>`, `  --cache/--no-cache` or `  --[no-]cache`.
    ///
    /// - Parameter text: The text that a tool prints for its help option.
    init(text: String) {
        var subcommands: [String] = []
        var defaultSubcommand: String?
        var options: Set<String> = []
        var inSubcommands = false
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            if let first = line.first, !first.isWhitespace {
                inSubcommands = line.trimmingCharacters(in: .whitespaces)
                    == TutorialReplayConfiguration.subcommandsHeading
                continue
            }
            if line.hasPrefix("  -") {
                let names = line.dropFirst(2).components(separatedBy: "  ")[0]
                for name in names.components(separatedBy: ", ").flatMap({ $0.components(separatedBy: "/") }) {
                    let option = name.split(separator: " ").first.map(String.init) ?? ""
                    options.formUnion(Self.expandingInversion(option).filter { $0.hasPrefix("--") })
                }
            } else if inSubcommands, line.hasPrefix("  "), !line.hasPrefix("   ") {
                let words = line.split(separator: " ").map(String.init)
                guard let name = words.first, name.allSatisfy({ $0.isLowercase || $0.isNumber || $0 == "-" }),
                    name.first?.isLowercase == true
                else { continue }
                subcommands.append(name)
                if words.count > 1, words[1] == TutorialReplayConfiguration.defaultSubcommandMarker {
                    defaultSubcommand = name
                }
            }
        }
        self.subcommands = subcommands
        self.defaultSubcommand = defaultSubcommand
        longOptions = options
    }

    /// The forms of an option name that writes its inversion in brackets, such as `--[no-]cache`.
    ///
    /// - Parameter option: An option name as a help page shows it.
    /// - Returns: The name itself, or its plain and its inverted form.
    static func expandingInversion(_ option: String) -> [String] {
        guard let open = option.firstIndex(of: "["), let close = option.firstIndex(of: "]"), open < close else {
            return [option]
        }
        let prefix = option[..<open], inner = option[option.index(after: open)..<close]
        let suffix = option[option.index(after: close)...]
        return [String(prefix + suffix), String(prefix + inner + suffix)]
    }
}

/// An invocation of a tool that a document shows in a fenced shell block.
struct DocumentedInvocation: Sendable, Equatable {
    /// The line of the document on which the command starts.
    let line: Int

    /// The command line as the document shows it, with continuation lines joined.
    let text: String

    /// The tool that the command runs.
    let tool: String

    /// The arguments after the tool name.
    let arguments: [String]
}

/// The invocations of the tools that a document shows, and the check that the tools accept them.
enum DocumentedCommands {
    /// The documents whose command lines are checked: the read-me file and every article of a
    /// documentation catalogue below the sources directory.
    ///
    /// Tutorials are replayed instead, and files below a resources directory are material that
    /// tutorials show, not articles.
    ///
    /// - Returns: The documents, sorted by path.
    /// - Throws: An error if the sources directory cannot be read.
    static func documents() throws -> [URL] {
        let root = TutorialCatalogue.repositoryRoot
        let articles = try TutorialCatalogue.files(
            below: root.appendingPathComponent(TutorialReplayConfiguration.sourcesDirectory),
            withExtension: TutorialReplayConfiguration.articleExtension
        ).filter { url in
            let components = url.pathComponents
            guard let catalogue = components.lastIndex(where: {
                $0.hasSuffix("." + TutorialReplayConfiguration.catalogueExtension)
            }) else { return false }
            return !components[catalogue...].contains(TutorialReplayConfiguration.resourcesDirectory)
        }
        return [root.appendingPathComponent(TutorialReplayConfiguration.readMeFile)] + articles
    }

    /// The command lines of the fenced shell blocks of a Markdown document.
    ///
    /// A line that ends with a backslash continues on the next line. Prompts such as `$ ` are
    /// removed, and comment lines are left out.
    ///
    /// - Parameter markdown: The text of a Markdown document.
    /// - Returns: Each command line with the line of the document on which it starts.
    static func shellLines(inMarkdown markdown: String) -> [(line: Int, text: String)] {
        var lines: [(line: Int, text: String)] = []
        var fence: String?
        var isShell = false
        var pending: (line: Int, text: String)?
        for (offset, rawLine) in markdown.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            if let open = fence {
                if trimmed.hasPrefix(open), trimmed.allSatisfy({ $0 == open.first }) {
                    fence = nil
                    if let command = pending { lines.append(command) }
                    pending = nil
                    continue
                }
                guard isShell else { continue }
                var text = trimmed
                if pending == nil {
                    for prompt in TutorialReplayConfiguration.shellPrompts where text.hasPrefix(prompt) {
                        text.removeFirst(prompt.count)
                    }
                    if text.first == TutorialReplayConfiguration.commentCharacter || text.isEmpty { continue }
                }
                let continues = text.hasSuffix("\\")
                if continues { text.removeLast() }
                if var command = pending {
                    command.text += " " + text
                    pending = command
                } else {
                    pending = (offset + 1, text)
                }
                if !continues, let command = pending {
                    lines.append(command)
                    pending = nil
                }
            } else if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                let marker = String(trimmed.prefix(while: { $0 == trimmed.first }))
                let language = trimmed.dropFirst(marker.count).split(whereSeparator: \.isWhitespace).first
                    .map { $0.lowercased() } ?? ""
                fence = marker
                isShell = TutorialReplayConfiguration.shellLanguages.contains(language)
            }
        }
        return lines
    }

    /// Splits a command line into words as a shell does, with control operators as words of their own.
    ///
    /// Quotes group words and are removed, a backslash escapes the next character, an unquoted `#`
    /// at the start of a word starts a comment, and `|`, `||`, `&`, `&&` and `;` become separate
    /// words, except for an ampersand in a redirection such as `2>&1`.
    ///
    /// - Parameter line: A command line.
    /// - Returns: The words of the line.
    static func words(of line: String) -> [String] {
        var words: [String] = []
        var word = ""
        var hasWord = false
        var quote: Character?
        var escaped = false
        func flush() {
            if hasWord { words.append(word) }
            word = ""
            hasWord = false
        }
        for character in line {
            if escaped {
                word.append(character)
                escaped = false
            } else if let open = quote {
                if character == open { quote = nil } else { word.append(character) }
            } else if character == "\\" {
                escaped = true
                hasWord = true
            } else if character == "\"" || character == "'" {
                quote = character
                hasWord = true
            } else if character.isWhitespace {
                flush()
            } else if character == "#" && !hasWord {
                break
            } else if character == "&" && (word.hasSuffix(">") || word.hasSuffix("<")) {
                word.append(character)
            } else if character == "|" || character == "&" || character == ";" {
                let isRepeat = !hasWord && words.last.map { $0 == String(character) } == true
                flush()
                if isRepeat { words[words.count - 1].append(character) } else { words.append(String(character)) }
            } else {
                word.append(character)
                hasWord = true
            }
        }
        flush()
        return words
    }

    /// The invocations of the tools in a command line.
    ///
    /// A command runs a tool when its first word, after any variable assignments, names the tool
    /// or a path to it, or when it is `swift run` followed by the name of the tool.
    ///
    /// - Parameters:
    ///   - line: A command line.
    ///   - number: The line of the document on which the command starts.
    /// - Returns: The invocations in the command line.
    static func invocations(in line: String, at number: Int) -> [DocumentedInvocation] {
        let operators: Set<String> = ["|", "||", "&", "&&", ";"]
        var invocations: [DocumentedInvocation] = []
        var command: [String] = []
        func finish() {
            var rest = command.drop { $0.contains("=") && !$0.hasPrefix("-") }
            if rest.starts(with: TutorialReplayConfiguration.packageRunCommand) {
                rest = rest.dropFirst(TutorialReplayConfiguration.packageRunCommand.count)
            }
            if let first = rest.first,
                let tool = TutorialReplayConfiguration.toolNames.first(where: {
                    first == $0 || first.hasSuffix("/" + $0)
                })
            {
                invocations.append(
                    DocumentedInvocation(line: number, text: line, tool: tool, arguments: Array(rest.dropFirst())))
            }
            command = []
        }
        for word in words(of: line) {
            if operators.contains(word) { finish() } else { command.append(word) }
        }
        finish()
        return invocations
    }

    /// Whether a word is a placeholder of a documentation example rather than a literal argument.
    ///
    /// - Parameter word: A word of a command line.
    /// - Returns: `true` if the word contains a placeholder, a variable or a pattern.
    static func isPlaceholder(_ word: String) -> Bool {
        word.contains { "<>$*{[".contains($0) }
    }

    /// The problems of an invocation: an unknown subcommand, or long options that its help does not list.
    ///
    /// The first argument names a subcommand unless it is an option. When it names no subcommand,
    /// the default subcommand of the tool, if any, receives the arguments. The implicit `help`
    /// subcommand and placeholders such as `<command>` are accepted unchecked.
    ///
    /// - Parameters:
    ///   - invocation: The invocation to check.
    ///   - help: The help page of the tool, or of one of its subcommands; `nil` if the tool is not built.
    /// - Returns: A description of every problem found.
    /// - Throws: An error if a help page cannot be obtained.
    static func problems(
        of invocation: DocumentedInvocation, help: (String, String?) async throws -> CommandHelpPage?
    ) async throws -> [String] {
        let tool = invocation.tool
        guard let root = try await help(tool, nil) else {
            return ["'\(tool)' is not an executable of this package"]
        }
        var arguments = invocation.arguments[...]
        var page = root
        var command = tool
        if let candidate = arguments.first, !candidate.hasPrefix("-") {
            if candidate == TutorialReplayConfiguration.implicitHelpSubcommand || isPlaceholder(candidate) {
                return []
            }
            if root.subcommands.contains(candidate) {
                arguments = arguments.dropFirst()
                command = "\(tool) \(candidate)"
                page = try await help(tool, candidate) ?? root
            } else if let fallback = root.defaultSubcommand {
                command = "\(tool) \(fallback)"
                page = try await help(tool, fallback) ?? root
            } else if !root.subcommands.isEmpty {
                return [
                    "'\(tool)' has no subcommand '\(candidate)' (subcommands: "
                        + root.subcommands.joined(separator: ", ") + ")"
                ]
            }
        } else if let fallback = root.defaultSubcommand {
            command = "\(tool) \(fallback)"
            page = try await help(tool, fallback) ?? root
        }
        var problems: [String] = []
        for argument in arguments {
            if argument == "--" { break }
            guard argument.hasPrefix("--"), argument.count > 2, !isPlaceholder(argument) else { continue }
            let option = argument.split(separator: "=", maxSplits: 1).first.map(String.init) ?? argument
            if !page.longOptions.contains(option) {
                problems.append(
                    "'\(command)' has no option '\(option)' (not listed by '\(command) \(TutorialReplayConfiguration.helpOption)')")
            }
        }
        return problems
    }
}

/// The help pages of the tools of this build, each obtained once.
actor CommandLineHelp {
    /// The help pages shared by the tests of this target.
    static let shared = CommandLineHelp()

    /// The help pages requested so far, by tool and subcommand.
    private var pages: [String: Task<CommandHelpPage?, any Error>] = [:]

    /// The help page of a tool or one of its subcommands.
    ///
    /// - Parameters:
    ///   - tool: The name of the tool.
    ///   - subcommand: The subcommand, or `nil` for the tool itself.
    ///   - productsDirectory: The directory that holds the executables of this build.
    /// - Returns: The help page, or `nil` if this build has no executable of that name.
    /// - Throws: An error if the tool cannot be started.
    func page(tool: String, subcommand: String?, productsDirectory: URL) async throws -> CommandHelpPage? {
        let key = ([tool] + (subcommand.map { [$0] } ?? [])).joined(separator: " ")
        if let page = pages[key] { return try await page.value }
        let task = Task<CommandHelpPage?, any Error> {
            #if os(Windows)
                let executable = productsDirectory.appendingPathComponent(tool + ".exe")
            #else
                let executable = productsDirectory.appendingPathComponent(tool)
            #endif
            guard FileManager.default.isExecutableFile(atPath: executable.path) else { return nil }
            let arguments = (subcommand.map { [$0] } ?? []) + [TutorialReplayConfiguration.helpOption]
            let result = try await withProcessSlot {
                try await Subprocess.run(
                    .path(FilePath(executable.path)),
                    arguments: Arguments(arguments),
                    output: .string(limit: 1 << 20),
                    error: .string(limit: 1 << 20))
            }
            return CommandHelpPage(text: (result.standardOutput ?? "") + (result.standardError ?? ""))
        }
        pages[key] = task
        return try await task.value
    }
}
