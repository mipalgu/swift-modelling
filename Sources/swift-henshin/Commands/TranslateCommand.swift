//
// TranslateCommand.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Henshin

/// The command that translates a JavaScript expression of a Henshin module into AQL.
///
/// Henshin writes attribute values, attribute conditions and iteration counts in
/// JavaScript; the engine evaluates them as the Acceleo Query Language. The command shows
/// that translation, or the table of the supported constructs.
struct TranslateCommand: AsyncParsableCommand {
    /// Shorthand for the option names.
    private typealias Key = SwiftHenshinVocabulary.OptionName
    /// Shorthand for the value names.
    private typealias Placeholder = SwiftHenshinVocabulary.ValueName

    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: SwiftHenshinVocabulary.Command.translate,
        abstract: "Translate a JavaScript expression into AQL, or print the translation table",
        discussion: """
            Prints the AQL text that the engine evaluates for a JavaScript expression of a \
            Henshin module, given as an argument or with --\(Key.expression). The names \
            that the expression uses stand for parameters of a rule or unit and must be \
            declared with --\(Key.variables), separated by commas or with the option \
            repeated; any other name, and any construct outside the supported subset, is an \
            error that names the reason. --verbose also prints the names that the expression \
            uses and whether it is a literal, a lone variable or a query.

            --\(Key.table) prints the translations of the supported constructs, one per \
            line as JavaScript, AQL and a note separated by tabs, over the variables a, b, c, \
            s and t.

            Exit statuses: 0 on success, 1 if the expression cannot be translated, and 64 for \
            an invalid command line.

            Examples:
              swift-henshin translate "n > 0 && s.length < 5" --variables n,s
              swift-henshin translate -e "a / b" --variables a --variables b
              swift-henshin translate --table
            """
    )

    /// The expression, as given as an argument.
    @Argument(help: ArgumentHelp("The JavaScript expression to translate", valueName: Placeholder.expression))
    var expressionArgument: String?

    /// The expression, as given with the option.
    @Option(
        name: [.customShort("e"), .customLong(Key.expression)],
        help: ArgumentHelp("The JavaScript expression to translate", valueName: Placeholder.expression))
    var expression: String?

    /// The names that the expression may use.
    @Option(
        name: .customLong(Key.variables),
        help: ArgumentHelp(
            "Names that the expression may use, separated by commas (can be specified multiple times)",
            valueName: Placeholder.variables))
    var variables: [String] = []

    /// Whether the translation table is printed.
    @Flag(name: .customLong(Key.table), help: "Print the translations of the supported constructs")
    var table = false

    /// Whether the variables and the form of the expression are printed too.
    @Flag(
        name: [.customShort("v"), .customLong(Key.verbose)],
        help: "Also print the names that the expression uses and its form")
    var verbose = false

    /// The expression that the command line gives, if exactly one is given.
    var source: String? {
        let given = [expressionArgument, expression].compactMap { $0 }
        return given.count == 1 ? given[0] : nil
    }

    /// Checks that the command line asks for exactly one thing.
    ///
    /// - Throws: A validation error unless exactly one expression is given without
    ///   `--table`, or `--table` is given alone.
    func validate() throws {
        let expressions = [expressionArgument, expression].compactMap { $0 }.count
        if table {
            guard expressions == 0 else {
                throw ValidationError("--\(Key.table) cannot be combined with an expression")
            }
        } else if expressions != 1 {
            throw ValidationError(
                "Give the expression as an argument or with --\(Key.expression), and only one of them, "
                    + "or give --\(Key.table)")
        }
    }

    /// Prints the translation or the table.
    ///
    /// - Throws: ``SwiftHenshinError/untranslatable(_:_:)`` if the expression cannot be
    ///   translated.
    func run() async throws {
        if table {
            Self.tableLines().forEach { print($0) }
            return
        }
        guard let source else { return }
        let translated = try Self.translate(source, variables: NameList.names(variables))
        print(translated.aql)
        if verbose {
            print("variables: " + translated.variables.joined(separator: ", "))
            print("form: " + Self.describe(translated.form))
        }
    }

    /// Translates an expression.
    ///
    /// - Parameters:
    ///   - source: The JavaScript text.
    ///   - variables: The names that the expression may use.
    /// - Returns: The translation.
    /// - Throws: ``SwiftHenshinError/untranslatable(_:_:)`` with the reason of the translator.
    static func translate(_ source: String, variables: [String]) throws -> TranslatedExpression {
        let translator = JavaScriptTranslator(variables: Set(variables))
        switch Result(catching: { () throws(HenshinError) -> TranslatedExpression in try translator.translate(source) }) {
        case .success(let translated):
            return translated
        case .failure(.unsupportedExpression(_, let reason)):
            throw SwiftHenshinError.untranslatable(source, reason)
        case .failure(let error):
            throw SwiftHenshinError.untranslatable(source, error.description)
        }
    }

    /// Describes the form of a translated expression.
    ///
    /// - Parameter form: The form.
    /// - Returns: `literal`, `variable` or `query`.
    static func describe(_ form: TranslatedExpression.Form) -> String {
        switch form {
        case .literal: return "literal"
        case .variable: return "variable"
        case .query: return "query"
        }
    }

    /// The lines of the translation table.
    ///
    /// - Returns: One line per entry: the JavaScript, the AQL and the note, separated by tabs.
    static func tableLines() -> [String] {
        JavaScriptTranslator.translationTable.map { [$0.javaScript, $0.aql, $0.note].joined(separator: "\t") }
    }
}
