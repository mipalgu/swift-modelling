//
// ScriptCommands.swift
// TutorialTests
//
// Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// A command that a script runs, with the line on which it appears.
struct ScriptCommand: Sendable, Equatable, Hashable {
    /// The name of the command as the script writes it.
    let name: String

    /// The line of the script on which the command appears.
    let line: Int
}

/// The commands that a bash script runs, found by reading the script rather than running it.
///
/// The reader splits a script into words and operators as bash does, with quotes, escapes, line
/// continuations, comments and here-documents, and reads command substitutions, backticks and
/// process substitutions as scripts of their own. A word is a command when it stands where bash
/// expects one: at the start of a line, after a control operator or a reserved word such as `then`,
/// after any variable assignments and redirections. The command run by a wrapper such as `xargs`,
/// `env` or `find -exec` counts as well. Loop and case headers, test expressions, arithmetic and
/// function definitions are recognised so that their words are not taken for commands.
enum ScriptCommands {
    /// The commands of a script that must be installed: neither builtins nor reserved words, nor tools
    /// of this package, nor functions that the script defines, nor paths or names built from variables.
    ///
    /// - Parameter script: The text of a bash script.
    /// - Returns: Every occurrence of such a command, in script order.
    static func externalCommands(in script: String) -> [ScriptCommand] {
        let parsed = parse(script)
        return parsed.commands.filter { command in
            isInstalledCommandName(command.name) && !parsed.functions.contains(command.name)
        }
    }

    /// Whether a command name must be found on the search path.
    ///
    /// - Parameter name: The name of a command as a script writes it.
    /// - Returns: `false` for builtins, reserved words, tools of this package, paths and names that
    ///   are built from variables or substitutions.
    static func isInstalledCommandName(_ name: String) -> Bool {
        !name.isEmpty
            && !TutorialReplayConfiguration.shellBuiltins.contains(name)
            && !TutorialReplayConfiguration.shellReservedWords.contains(name)
            && !TutorialReplayConfiguration.toolNames.contains(name)
            && !name.contains("/") && !name.contains("$") && !name.contains("`") && !name.contains("=")
    }

    /// A word or an operator of a script.
    struct Token: Equatable {
        /// What a token is.
        enum Kind: Equatable {
            /// A word, with quotes and escapes removed.
            case word
            /// A control operator such as `|`, `&&`, `;`, `;;`, `(` or `)`.
            case control
            /// A redirection operator, whose next word is its target.
            case redirection
            /// The end of a line.
            case newline
        }

        /// What the token is.
        let kind: Kind

        /// The text of the token.
        let text: String

        /// The line on which the token starts.
        let line: Int
    }

    /// The commands of a script, including builtins, and the functions that it defines.
    ///
    /// - Parameters:
    ///   - script: The text of a bash script.
    ///   - firstLine: The line number of the first line of the text within its script.
    /// - Returns: Every word in command position and the names of the defined functions.
    static func parse(_ script: String, firstLine: Int = 1) -> (commands: [ScriptCommand], functions: Set<String>) {
        var lexer = Lexer(Array(script), line: firstLine)
        let tokens = lexer.tokens()
        var commands = lexer.nestedCommands
        var functions = lexer.nestedFunctions
        var expectCommand = true
        var skipUntil: String?
        var inCasePattern = false
        var wrapper: (name: String, operandsToSkip: Int, lookup: Bool)?
        var findCommand = false
        var nextIsCommand = false
        var index = 0
        func peek(_ offset: Int) -> Token? {
            index + offset < tokens.count ? tokens[index + offset] : nil
        }
        while index < tokens.count {
            let token = tokens[index]
            defer { index += 1 }
            if let target = skipUntil {
                if token.kind == .word && token.text == target || token.kind == .control && token.text == target {
                    skipUntil = nil
                    if target == "in" { inCasePattern = true } else { expectCommand = target == "do" }
                }
                continue
            }
            if inCasePattern {
                if token.kind == .word && token.text == "esac" {
                    inCasePattern = false
                    expectCommand = false
                } else if token.kind == .control && (token.text == ")" || token.text == "))") {
                    inCasePattern = false
                    expectCommand = true
                }
                continue
            }
            switch token.kind {
            case .newline:
                expectCommand = true
                wrapper = nil
                findCommand = false
                nextIsCommand = false
            case .redirection:
                if peek(1)?.kind == .word { index += 1 }
            case .control:
                switch token.text {
                case ";;", ";&", ";;&":
                    inCasePattern = true
                case "((":
                    skipUntil = "))"
                case ")", "))":
                    expectCommand = false
                default:
                    expectCommand = true
                }
                wrapper = nil
                findCommand = false
                nextIsCommand = false
            case .word:
                let word = token.text
                if expectCommand {
                    if isAssignment(word) {
                        if word.hasSuffix("="), peek(1)?.kind == .control, peek(1)?.text == "(" { skipUntil = ")" }
                        continue
                    }
                    switch word {
                    case "if", "then", "else", "elif", "do", "while", "until", "!", "{", "time":
                        continue
                    case "fi", "done", "}", "esac":
                        expectCommand = false
                        continue
                    case "for", "select":
                        skipUntil = "do"
                        continue
                    case "case":
                        skipUntil = "in"
                        continue
                    case "[[":
                        skipUntil = "]]"
                        expectCommand = false
                        continue
                    case "function":
                        if let name = peek(1), name.kind == .word {
                            functions.insert(name.text)
                            index += 1
                            if peek(1)?.text == "(" && peek(2)?.text == ")" { index += 2 }
                        }
                        expectCommand = true
                        continue
                    default:
                        break
                    }
                    if peek(1)?.kind == .control && peek(1)?.text == "(" && peek(2)?.text == ")" {
                        functions.insert(word)
                        index += 2
                        expectCommand = true
                        continue
                    }
                    commands.append(ScriptCommand(name: word, line: token.line))
                    expectCommand = false
                    findCommand = word == TutorialReplayConfiguration.findCommand
                    if TutorialReplayConfiguration.commandWrappers.contains(word) {
                        wrapper = (word, TutorialReplayConfiguration.commandWrapperLeadingOperands[word] ?? 0, false)
                    }
                    continue
                }
                if nextIsCommand {
                    commands.append(ScriptCommand(name: word, line: token.line))
                    nextIsCommand = false
                    findCommand = word == TutorialReplayConfiguration.findCommand
                    continue
                }
                if findCommand && TutorialReplayConfiguration.findExecutionOptions.contains(word) {
                    nextIsCommand = true
                    continue
                }
                if var current = wrapper {
                    if word.hasPrefix("-") {
                        if current.name == "command" && TutorialReplayConfiguration.commandLookupOptions.contains(word) {
                            current.lookup = true
                        }
                        if TutorialReplayConfiguration.commandWrapperOptionsWithValue.contains(word) { index += 1 }
                        wrapper = current
                    } else if isAssignment(word) {
                        continue
                    } else if current.operandsToSkip > 0 {
                        current.operandsToSkip -= 1
                        wrapper = current
                    } else {
                        if !current.lookup { commands.append(ScriptCommand(name: word, line: token.line)) }
                        wrapper = TutorialReplayConfiguration.commandWrappers.contains(word) && !current.lookup
                            ? (word, TutorialReplayConfiguration.commandWrapperLeadingOperands[word] ?? 0, false) : nil
                        findCommand = word == TutorialReplayConfiguration.findCommand
                    }
                }
            }
        }
        return (commands.enumerated().sorted { ($0.element.line, $0.offset) < ($1.element.line, $1.offset) }
            .map(\.element), functions)
    }

    /// Whether a word assigns a variable, such as `NAME=value` or `LIST+=(a b)`.
    ///
    /// - Parameter word: A word of a script.
    /// - Returns: `true` if the word starts with a variable name followed by `=` or `+=`.
    static func isAssignment(_ word: String) -> Bool {
        guard let equals = word.firstIndex(of: "="), equals > word.startIndex else { return false }
        var name = word[..<equals]
        if name.hasSuffix("+") { name = name.dropLast() }
        guard let first = name.first, first.isLetter || first == "_" else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    /// Splits a script into tokens and reads its substitutions as scripts of their own.
    struct Lexer {
        /// The characters of the script.
        let characters: [Character]

        /// The position of the next character.
        var index = 0

        /// The line of the next character.
        var line: Int

        /// The delimiters of the here-documents whose bodies start after the current line.
        var pendingHereDocuments: [(delimiter: String, stripsTabs: Bool)] = []

        /// The commands found in substitutions.
        var nestedCommands: [ScriptCommand] = []

        /// The functions defined in substitutions.
        var nestedFunctions: Set<String> = []

        /// The characters that end an unquoted word, listed one by one so that a carriage return
        /// and a line feed are not read as one character.
        static let wordEnds: Set<Character> = [" ", "\t", "\r", "\n", ";", "&", "|", "(", ")", "<", ">"]

        /// Creates a lexer for a script.
        ///
        /// - Parameters:
        ///   - characters: The characters of the script.
        ///   - line: The line number of the first character.
        init(_ characters: [Character], line: Int) {
            self.characters = characters
            self.line = line
        }

        /// The character at an offset from the next one, if any.
        func peek(_ offset: Int = 0) -> Character? {
            index + offset < characters.count ? characters[index + offset] : nil
        }

        /// Splits the whole script into tokens.
        ///
        /// - Returns: The tokens in script order.
        mutating func tokens() -> [Token] {
            var tokens: [Token] = []
            while let character = peek() {
                if character == "\\" && peek(1) == "\n" {
                    index += 2
                    line += 1
                } else if character == " " || character == "\t" || character == "\r" {
                    index += 1
                } else if character == "\n" {
                    tokens.append(Token(kind: .newline, text: "\n", line: line))
                    index += 1
                    line += 1
                    skipHereDocumentBodies()
                } else if character == "#" {
                    while let next = peek(), next != "\n" { index += 1 }
                } else if let token = operatorToken() {
                    tokens.append(token)
                    if token.kind == .redirection && token.text.hasPrefix("<<") && token.text != "<<<" {
                        skipBlanks()
                        let start = line
                        let delimiter = word()
                        pendingHereDocuments.append((delimiter, token.text == "<<-"))
                        tokens.append(Token(kind: .word, text: delimiter, line: start))
                    }
                } else {
                    let start = line
                    tokens.append(Token(kind: .word, text: word(), line: start))
                }
            }
            return tokens
        }

        /// Skips spaces and tabs.
        mutating func skipBlanks() {
            while let character = peek(), character == " " || character == "\t" { index += 1 }
        }

        /// Reads an operator at the current position, if there is one.
        ///
        /// - Returns: A control or redirection token, or `nil` if a word starts here.
        mutating func operatorToken() -> Token? {
            let start = line
            var digits = 0
            while let character = peek(digits), character.isNumber { digits += 1 }
            if let character = peek(digits), character == "<" || character == ">", peek(digits + 1) != "(" {
                index += digits
                var text = String(character)
                index += 1
                while let next = peek(), "<>&|-".contains(next), text.count < 3 {
                    if next == "-" && text != "<<" { break }
                    text.append(next)
                    index += 1
                }
                if text.hasSuffix("&"), let next = peek(), next.isNumber || next == "-" {
                    index += 1
                    return Token(kind: .redirection, text: text, line: start)
                }
                return Token(kind: .redirection, text: text, line: start)
            }
            guard digits == 0, let character = peek() else { return nil }
            if character == "&" && peek(1) == ">" {
                index += 2
                if peek() == ">" { index += 1 }
                return Token(kind: .redirection, text: "&>", line: start)
            }
            for candidate in [";;&", "((", "))", "&&", "||", ";;", ";&", "|&", "|", "&", ";", "(", ")"] {
                let symbols = Array(candidate)
                if symbols.indices.allSatisfy({ peek($0) == symbols[$0] }) {
                    index += symbols.count
                    return Token(kind: .control, text: candidate, line: start)
                }
            }
            return nil
        }

        /// Reads a word, removing quotes and escapes and reading substitutions as scripts.
        ///
        /// - Returns: The text of the word.
        mutating func word() -> String {
            var text = ""
            while let character = peek() {
                if Self.wordEnds.contains(character) {
                    if (character == "<" || character == ">") && peek(1) == "(" {
                        index += 2
                        text += "<(" + substitution(closing: ")") + ")"
                        continue
                    }
                    break
                }
                index += 1
                switch character {
                case "\\":
                    if let next = peek() {
                        if next == "\n" { line += 1 } else { text.append(next) }
                        index += 1
                    }
                case "'":
                    while let next = peek(), next != "'" {
                        if next == "\n" { line += 1 }
                        text.append(next)
                        index += 1
                    }
                    index += 1
                case "\"":
                    text += doubleQuoted()
                case "`":
                    text += "`" + substitution(closing: "`") + "`"
                case "$":
                    text += dollar()
                default:
                    text.append(character)
                }
            }
            return text
        }

        /// Reads the rest of a double-quoted string, reading its substitutions as scripts.
        ///
        /// - Returns: The text of the string without its quotes.
        mutating func doubleQuoted() -> String {
            var text = ""
            while let character = peek(), character != "\"" {
                index += 1
                switch character {
                case "\\":
                    if let next = peek() {
                        if next == "\n" { line += 1 } else { text.append(next) }
                        index += 1
                    }
                case "`":
                    text += "`" + substitution(closing: "`") + "`"
                case "$":
                    text += dollar()
                case "\n":
                    line += 1
                    text.append(character)
                default:
                    text.append(character)
                }
            }
            index += 1
            return text
        }

        /// Reads what follows a dollar sign: a command substitution, arithmetic or a parameter expansion.
        ///
        /// - Returns: The text of the expansion, starting with the dollar sign.
        mutating func dollar() -> String {
            if peek() == "(" && peek(1) == "(" {
                index += 2
                return "$((" + balanced(open: "(", close: ")", depth: 2) + "))"
            }
            if peek() == "(" {
                index += 1
                return "$(" + substitution(closing: ")") + ")"
            }
            if peek() == "{" {
                index += 1
                return "${" + balanced(open: "{", close: "}", depth: 1) + "}"
            }
            return "$"
        }

        /// Reads text up to the bracket that closes the given number of open brackets.
        ///
        /// - Parameters:
        ///   - open: The opening bracket.
        ///   - close: The closing bracket.
        ///   - depth: How many brackets are open.
        /// - Returns: The text between the brackets.
        mutating func balanced(open: Character, close: Character, depth: Int) -> String {
            var depth = depth
            var text = ""
            while let character = peek() {
                index += 1
                if character == "\n" { line += 1 }
                if character == open { depth += 1 }
                if character == close {
                    depth -= 1
                    if depth == 0 { break }
                }
                text.append(character)
            }
            return text
        }

        /// Reads a command substitution or process substitution and records its commands.
        ///
        /// - Parameter closing: The character that ends the substitution.
        /// - Returns: The text of the substitution.
        mutating func substitution(closing: Character) -> String {
            let start = line
            var depth = 1
            var text = ""
            var quote: Character?
            while let character = peek() {
                index += 1
                if character == "\n" { line += 1 }
                if let open = quote {
                    if character == open { quote = nil }
                    if character == "\\" && open == "\"", let next = peek() {
                        if next == "\n" { line += 1 }
                        text.append(character)
                        text.append(next)
                        index += 1
                        continue
                    }
                } else if character == "\\", let next = peek() {
                    if next == "\n" { line += 1 }
                    text.append(character)
                    text.append(next)
                    index += 1
                    continue
                } else if (character == "'" || character == "\"") && closing != "`" {
                    quote = character
                } else if closing == ")" && character == "(" {
                    depth += 1
                } else if character == closing {
                    depth -= 1
                    if depth == 0 { break }
                }
                text.append(character)
            }
            let inner = ScriptCommands.parse(text, firstLine: start)
            nestedCommands += inner.commands
            nestedFunctions.formUnion(inner.functions)
            return text
        }

        /// Skips the bodies of the here-documents that start after the line just ended.
        mutating func skipHereDocumentBodies() {
            while !pendingHereDocuments.isEmpty {
                let (delimiter, stripsTabs) = pendingHereDocuments.removeFirst()
                while peek() != nil {
                    var content = ""
                    while let character = peek(), character != "\n" {
                        content.append(character)
                        index += 1
                    }
                    if peek() == "\n" {
                        index += 1
                        line += 1
                    }
                    let compared = stripsTabs ? String(content.drop { $0 == "\t" }) : content
                    if compared == delimiter { break }
                }
            }
        }
    }
}

/// A use of an installed command by a Terminal script of a tutorial.
struct CommandUse: Sendable, Equatable {
    /// The identifier of the tutorial.
    let tutorial: String

    /// The resource name of the script.
    let script: String

    /// The line of the script on which the command appears.
    let line: Int
}

extension TutorialCatalogue {
    /// The installed commands that the Terminal scripts of a series run, with where they run them.
    ///
    /// - Parameter series: The series.
    /// - Returns: For each command, its uses in reading order.
    func requiredCommands(ofSeries series: String) -> [String: [CommandUse]] {
        var required: [String: [CommandUse]] = [:]
        for tutorial in tutorials where tutorial.series == series {
            for code in tutorial.codes where code.kind == .terminal {
                guard case .found(let url) = resources.resolve(code.file),
                    let script = try? String(contentsOf: url, encoding: .utf8)
                else { continue }
                for command in ScriptCommands.externalCommands(in: script) {
                    required[command.name, default: []].append(
                        CommandUse(tutorial: tutorial.identifier, script: code.file, line: command.line))
                }
            }
        }
        return required
    }
}

extension TutorialReplayEnvironment {
    /// Finds a command on the search path of the scripts.
    ///
    /// - Parameter command: The name of the command.
    /// - Returns: The location of the first executable of that name, or `nil` if there is none.
    func locate(_ command: String) -> String? {
        searchPath.split(separator: TutorialReplayConfiguration.searchPathSeparator)
            .map { "\($0)/\(command)" }
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// The reason that a series cannot be replayed, if a command that it needs is missing.
    ///
    /// - Parameters:
    ///   - series: The series.
    ///   - required: The installed commands that the series needs, with their uses.
    /// - Returns: A message that names the missing commands, what provides them, and the tutorials
    ///   and script lines that need them, or `nil` if every command is on the search path.
    func missingCommandsMessage(series: String, required: [String: [CommandUse]]) -> String? {
        Self.missingCommandsMessage(series: series, required: required) { locate($0) }
    }

    /// The reason that a series cannot be replayed, given a way to find commands.
    ///
    /// - Parameters:
    ///   - series: The series.
    ///   - required: The installed commands that the series needs, with their uses.
    ///   - locate: Finds a command, returning `nil` if it is missing.
    /// - Returns: A message that names the missing commands, what provides them, and the tutorials
    ///   and script lines that need them, or `nil` if every command is found.
    static func missingCommandsMessage(
        series: String, required: [String: [CommandUse]], locate: (String) -> String?
    ) -> String? {
        let missing = required.keys.filter { locate($0) == nil }.sorted()
        guard !missing.isEmpty else { return nil }
        let names = missing.map { command in
            TutorialReplayConfiguration.commandProviders[command].map { "\(command) (\($0))" } ?? command
        }
        var lines = [
            "Series \(series) was not replayed: it needs \(names.joined(separator: ", ")), "
                + "which \(missing.count == 1 ? "is" : "are") not installed on the replay search path."
        ]
        for command in missing {
            let uses = required[command] ?? []
            let tutorials = uses.map(\.tutorial).reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
            lines.append("  \(command) is needed by \(tutorials.joined(separator: ", ")):")
            lines += uses.map { "    \($0.tutorial): \($0.script) line \($0.line)" }
        }
        return lines.joined(separator: "\n")
    }
}
