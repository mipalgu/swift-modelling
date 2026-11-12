//
// SwiftAQLVocabulary.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ModellingCommandLine

/// The names, markers and spellings that the swift-aql tool relies on.
///
/// Every value that carries meaning for the command line, the variables it binds or the way it
/// prints results is defined here once, so that the commands, their help and their tests agree.
enum SwiftAQLVocabulary {
    /// The name of the tool, as typed on the command line.
    static let toolName = "swift-aql"

    /// The version that `--version` reports.
    static let version = "0.8.1"

    /// The names of the subcommands.
    enum Command {
        /// The subcommand that evaluates an expression against models given with `--model`.
        static let evaluate = "evaluate"

        /// The subcommand that evaluates a query against a model given as an argument.
        static let query = "query"

        /// The subcommand that checks whether an expression can be used with another metamodel.
        static let checkCompat = CompatibilityCheckOptions.commandName
    }

    /// The long names of the options.
    enum OptionName {
        /// The option that names a model to load.
        static let model = "model"

        /// The option that gives the expression of `evaluate`.
        static let expression = "expression"

        /// The option that names a file holding the expression of `evaluate`.
        static let expressionFile = "expression-file"

        /// The option that gives the expression of `query`.
        static let query = "query"

        /// The option that names a file holding the expression of `query`.
        static let queryFile = "query-file"

        /// The option that selects the object bound to `self`.
        static let context = "context"

        /// The option that gives the type of a variable of an expression to check.
        static let variable = "variable"
    }

    /// The names of the values of the options in the usage of a command.
    enum ValueName {
        /// The value of an option that names a model file.
        static let model = "file"

        /// The value of an option that gives an expression.
        static let expression = "expression"

        /// The value of an option that names an expression file.
        static let expressionFile = "file.aql"

        /// The value of the context option.
        static let context = "id-or-name"

        /// The value of the option that gives the type of a variable.
        static let variable = "name=type"
    }

    /// The words with which the variables of an expression to check are named in messages.
    enum VariableType {
        /// The word that names a member of the family of variable options.
        static let noun = "variable"

        /// The reason why a variable is given without a type.
        static let missingType = "expected the type of the variable, such as library::Library"
    }

    /// The variables that a run binds before it evaluates an expression.
    enum Variable {
        /// The variable that holds the context object.
        static let selfName = AQLSyntax.selfVariable
    }

    /// The name of the attribute that labels an object whenever its class has one.
    ///
    /// The comparison ignores case, as the reflective item providers of the Eclipse Modeling
    /// Framework do.
    static let labelAttributeName = "name"

    /// The spellings with which results are printed.
    enum Display {
        /// The text of the null value.
        static let null = AQLSyntax.nullText

        /// The character that encloses a string.
        static let quote: Character = "\""

        /// The character that escapes a quote or backslash within a string.
        static let escape: Character = "\\"

        /// The text that opens a collection.
        static let collectionOpening = "["

        /// The text that closes a collection.
        static let collectionClosing = "]"

        /// The text that separates the elements of a collection.
        static let separator = ", "

        /// The text that opens the label of an object after its class name.
        static let labelOpening = "("

        /// The text that closes the label of an object.
        static let labelClosing = ")"

        /// The word that introduces a reference that could not be resolved.
        static let unresolved = "unresolved"

        /// The character that separates the URI of an unresolved reference from its fragment.
        static let fragmentSeparator = "#"

        /// The escape sequences of control characters within a string.
        static let controlEscapes: [Character: String] = ["\n": "\\n", "\r": "\\r", "\t": "\\t"]
    }

    /// The names of the files and directories that metamodel discovery looks at.
    enum Discovery {
        /// The attribute of an Ecore package that holds its namespace URI.
        static let namespaceURIAttribute = "nsURI"

        /// The characters that may follow a namespace URI where a model refers to it.
        static let namespaceURITerminators: Set<Character> = ["\"", "'", "#"]
    }

    /// The syntax of the fragment paths that locate an object within a model.
    enum Fragment {
        /// The character that separates the segments of a path and starts it.
        static let separator: Character = "/"

        /// The character that starts the segment of a containment reference.
        static let featureMarker: Character = "@"

        /// The character that separates the name of a reference from a position.
        static let indexSeparator: Character = "."
    }

    /// The names that the XMI format gives to its own elements and attributes.
    enum XMI {
        /// The name of the attribute that holds the identifier of an element.
        static let identifierAttribute = "xmi:id"

        /// The local name of the element that wraps several root objects.
        static let documentElement = "XMI"

        /// The separator between a namespace prefix and a local name.
        static let prefixSeparator: Character = ":"
    }
}
