//
// SwiftAQL.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ModellingCommandLine

/// The main command-line interface for Swift AQL.
///
/// Swift AQL evaluates Acceleo Query Language (AQL) expressions against models, so that the
/// queries of templates and transformations can be tried out, and models can be checked and
/// reported on from scripts.
///
/// ## Available Commands
///
/// - **evaluate**: evaluate an expression against the models given with `--model`
/// - **query**: evaluate a query against the model given as an argument
/// - **check-compat**: check whether an expression can be used with another metamodel
///
/// ## Example Usage
///
/// ```bash
/// swift-aql evaluate --model company.xmi --expression "company.departments.name"
/// swift-aql query company.xmi --query "self.employees->size()" --context company1
/// swift-aql check-compat -e "self.books.title" --variable self=library::Library \
///     --metamodel library=Library.ecore --target-metamodel library=LibraryV2.ecore
/// ```
@main
struct SwiftAQLCommand: AsyncParsableCommand {
    /// The name, summary, version and subcommands of the tool.
    static let configuration = CommandConfiguration(
        commandName: SwiftAQLVocabulary.toolName,
        abstract: "Acceleo Query Language command-line tool",
        discussion: """
            Copyright (c) 2026 Rene Hexel.
            All rights reserved.

            Swift AQL evaluates Acceleo Query Language (AQL) expressions against models in XMI \
            or JSON format, or against Ecore metamodels, and prints their values. It uses the \
            same expression engine as the templates of swift-mtl.
            """,
        version: SwiftAQLVocabulary.version,
        subcommands: [
            EvaluateCommand.self,
            QueryCommand.self,
            CheckCompatCommand.self,
        ]
    )

    /// A paragraph that describes the variables that an expression can use.
    static let bindingDiscussion = """
        The expression sees self, which is the object that --\(SwiftAQLVocabulary.OptionName.context) \
        selects or else the first root object of the first model, and a variable for each root \
        object, named after its class with a lower-case first letter, such as company for a \
        root object of class Company.
        """

    /// A paragraph that describes how the metamodels of the models are found.
    static let metamodelDiscussion = """
        Without --\(MetamodelOptions.optionName), the metamodel files in the directory of \
        each model, such as Ecore, JSON, KM3 or EMOF files, whose namespace URI the model uses \
        are registered as its metamodels, so that its attributes have their declared types.
        """

    /// A paragraph that describes how values are printed.
    static let outputDiscussion = """
        Strings are printed in double quotes, numbers and Booleans as they are, model objects as \
        their class name followed by their name in parentheses, such as Employee(Alice Smith), \
        collections in square brackets, and an undefined value as null.
        """
}
