//
// QueryCommand.swift
// ECore
//
//  Created by Rene Hexel on 3/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import Foundation
import ModellingCommandLine

/// Command for querying models and metamodels.
///
/// The query command answers questions about a whole document: how many objects it has and of
/// which classes, which classes a metamodel defines and how they extend each other, which objects
/// belong to a class, and how the objects contain each other.
struct QueryCommand: AsyncParsableCommand {
    /// The name, summary and help of the `query` subcommand.
    static let configuration = CommandConfiguration(
        commandName: "query",
        abstract: "Query models and metamodels",
        discussion: """
            Queries look at the whole document: every object of a model however deeply it is \
            contained, and every element of a metamodel (.ecore).

            info          the number of root objects and of all objects, and the objects of each class
            count         the number of objects
            list-classes  (or classes) the classes of the objects of a model with their counts, or \
            every class of a metamodel with its supertypes
            hierarchy     the inheritance hierarchy of the classes
            find <class>  the objects of a class or of one of its subclasses, with their features
            tree          the containment tree

            --\(MetamodelOptions.optionName) names an Ecore metamodel of the model. \
            \(MetamodelOptions.effect)
            """
    )

    /// Model file path to query.
    @Argument(help: "Model or metamodel file to query (.xmi, .json or .ecore)")
    var inputPath: String

    /// Query expression to execute.
    @Option(name: .shortAndLong, help: "Query expression: \(QueryKind.helpList)")
    var query: String = QueryKind.info.rawValue

    /// The metamodels of the model.
    @OptionGroup var metamodelOptions: MetamodelOptions

    /// Enable verbose output.
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    /// Executes the query command.
    ///
    /// Reads the document with its metamodels, runs the query and prints the result.
    ///
    /// - Throws: ``DocumentError`` if the file cannot be read, ``QueryError`` if the query is
    ///   invalid, or the error of the parser.
    func run() async throws {
        if verbose {
            print("Querying: \(inputPath)")
            print("Query: \(query)")
        }
        let document: ModelDocument
        do {
            document = try await ModelDocument.load(path: inputPath, metamodelOptions: metamodelOptions, verbose: verbose)
        } catch DocumentError.fileNotFound(let path) {
            throw QueryError.fileNotFound(path)
        } catch DocumentError.unsupportedFormat(let format) {
            throw QueryError.unsupportedFormat(format)
        }
        let result = try await QueryEngine(document: document).execute(query)
        withExtendedLifetime(document) {}
        print(result, terminator: "")
    }
}
