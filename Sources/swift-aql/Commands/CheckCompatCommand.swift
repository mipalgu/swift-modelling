//
// CheckCompatCommand.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ArgumentParser
import ModelTyping
import ModellingCommandLine

/// A conversion failure of a variable given without a type.
private struct MissingVariableType: Error, CustomStringConvertible {
    /// The reason, for the message of the option family.
    var description: String { SwiftAQLVocabulary.VariableType.missingType }
}

/// The command that checks whether an AQL expression can be used with another metamodel.
///
/// The expression is parsed, its footprint is extracted against the metamodel that it was
/// written against, with the types of its variables as given, and the target metamodel is
/// checked against that footprint for what the expression reads. The report is printed to
/// standard output, and the exit status tells the verdict (see
/// ``ModellingCommandLine/CompatibilityVerdict``).
struct CheckCompatCommand: AsyncParsableCommand {
    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: SwiftAQLVocabulary.Command.checkCompat,
        abstract: "Check whether an AQL expression can be used with another metamodel",
        discussion: """
            \(CompatibilityCheckOptions.discussion(module: "the expression"))

            The expression is given with --\(SwiftAQLVocabulary.OptionName.expression) or read \
            from the file that --\(SwiftAQLVocabulary.OptionName.expressionFile) names. Each \
            --\(SwiftAQLVocabulary.OptionName.variable) gives the type of a variable of the \
            expression, such as self=library::Library or books=Sequence(library::Book), so \
            that the features it navigates can be found; the uses of a variable without a type \
            make the verdict inconclusive.

            An expression is checked against one metamodel. The name of \
            --\(CompatibilityCheckOptions.OptionName.metamodel) is the name under which the \
            findings refer to it, conventionally the name of its package, which also qualifies \
            the types of the expression, such as library in library::Book.

            \(SourceEncodingOptions.discussion(reader: "an expression file", configurable: false))

            Examples:
              swift-aql check-compat -e "self.books->collect(b | b.title)" \\
                  --variable self=library::Library \\
                  --metamodel library=Library.ecore \\
                  --target-metamodel library=LibraryV2.ecore
              swift-aql check-compat -f titles.aql --variable self=library::Library \\
                  --metamodel library=Library.ecore \\
                  --target-metamodel library=LibraryV2.ecore \\
                  --rename Writer=Author --allow-widening --format json
            """
    )

    /// The family of `name=type` options that give the types of variables.
    static let variableTypes = KeyValueOption<String>(noun: SwiftAQLVocabulary.VariableType.noun) { _, type in
        guard !type.isEmpty else { throw MissingVariableType() }
        return type
    }

    /// The expression, as given on the command line.
    @Option(
        name: [.customShort("e"), .customLong(SwiftAQLVocabulary.OptionName.expression)],
        help: ArgumentHelp("The AQL expression to check", valueName: SwiftAQLVocabulary.ValueName.expression))
    var expression: String?

    /// The file that holds the expression.
    @Option(
        name: [.customShort("f"), .customLong(SwiftAQLVocabulary.OptionName.expressionFile)],
        help: ArgumentHelp(
            "A file that holds the AQL expression to check", valueName: SwiftAQLVocabulary.ValueName.expressionFile))
    var expressionFile: String?

    /// The types of the variables of the expression, as `name=type` in command line order.
    @Option(
        name: .customLong(SwiftAQLVocabulary.OptionName.variable),
        help: ArgumentHelp(
            "The type of a variable of the expression, such as self=library::Library "
                + "(can be specified multiple times)",
            valueName: SwiftAQLVocabulary.ValueName.variable))
    var variables: [String] = []

    /// The metamodel, the mode and the options of the check.
    @OptionGroup(title: "Compatibility")
    var compatibility: CompatibilityCheckOptions

    /// The character encoding of an expression file.
    @OptionGroup var encodingOptions: SourceEncodingOptions

    /// The source of the expression that the command line names.
    var source: ExpressionSource? { ExpressionSource.select(texts: [expression], file: expressionFile) }

    /// The types of the variables, by name.
    ///
    /// - Returns: The written type of each variable; a later variable replaces an earlier one
    ///   of the same name.
    /// - Throws: A `KeyValueOptionError` if a variable is not given as `name=type`.
    func variableTypes() throws -> [String: String] {
        try Self.variableTypes.values(from: variables)
    }

    /// Checks that the command line names exactly one expression, well-formed variables and
    /// one metamodel.
    ///
    /// - Throws: A validation error that names the first problem.
    func validate() throws {
        guard source != nil else {
            throw ArgumentParser.ValidationError(
                "Give either --\(SwiftAQLVocabulary.OptionName.expression) or "
                    + "--\(SwiftAQLVocabulary.OptionName.expressionFile), but not both")
        }
        do {
            _ = try variableTypes()
        } catch {
            throw ArgumentParser.ValidationError(String(describing: error))
        }
        try compatibility.validateSingleMetamodel()
    }

    /// Parses the expression.
    ///
    /// - Returns: The expression.
    /// - Throws: The errors of ``ExpressionSource/text(encoding:)``, and
    ///   ``SwiftAQLError/invalidExpression(_:)`` if the expression is not valid AQL.
    func parsedExpression() throws -> any AQLExpression {
        guard let source else { throw SwiftAQLError.emptyExpression }
        let parsed = AQLParser().parse(try source.text(encoding: encodingOptions.explicitEncoding))
        let problems = parsed.diagnostics.filter { $0.severity == .error }
        guard problems.isEmpty, let expression = parsed.expression else {
            throw SwiftAQLError.invalidExpression(problems.map(SwiftAQLError.describe))
        }
        return expression
    }

    /// Checks the expression and prints the report.
    ///
    /// - Throws: `ExitCode` with the status of the verdict unless it is compatible, or with
    ///   ``ModellingCommandLine/CompatibilityVerdict/failureExitStatus`` if the expression or
    ///   the metamodels cannot be read.
    @MainActor
    func run() async throws {
        try await compatibility.run { metamodels in
            let sole = try metamodels.requireSole()
            return ReuseChecker.check(
                aql: try parsedExpression(), variables: try variableTypes(), metamodelName: sole.name,
                required: sole.required, provided: sole.provided, mode: compatibility.mode,
                options: try compatibility.checkOptions())
        }
    }
}
