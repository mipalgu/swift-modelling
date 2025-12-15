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

/// Command for querying models and metamodels.
///
/// The query command provides inspection capabilities for models,
/// allowing users to examine structure, find objects, and analyse content.
struct QueryCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "query",
        abstract: "Query models and metamodels"
    )

    /// Model file path to query.
    @Argument(help: "Model file path to query")
    var inputPath: String

    /// Query expression to execute.
    @Option(
        name: .shortAndLong,
        help: "Query expression (e.g., 'count(*)', 'find(Person)', 'list-classes')")
    var query: String = "info"

    /// Enable verbose output.
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    /// Executes the query command.
    ///
    /// Runs the specified query against the input model and displays results.
    ///
    /// - Throws: `QueryError` if the query fails.
    func run() async throws {
        if verbose {
            print("Querying: \(inputPath)")
            print("Query: \(query)")
        }

        let inputURL = URL(fileURLWithPath: inputPath)

        guard FileManager.default.fileExists(atPath: inputPath) else {
            throw QueryError.fileNotFound(inputPath)
        }

        // Load model
        let resource: Resource
        let fileExtension = inputURL.pathExtension.lowercased()

        switch fileExtension {
        case "xmi":
            let parser = XMIParser()
            resource = try await parser.parse(inputURL)
        case "json":
            let parser = JSONParser()
            resource = try await parser.parse(inputURL)
        case "ecore":
            let parser = XMIParser()
            resource = try await parser.parse(inputURL)
        default:
            throw QueryError.unsupportedFormat(fileExtension)
        }

        // Execute query
        let queryEngine = QueryEngine(resource: resource)
        let result = try await queryEngine.execute(query)

        print(result)
    }
}
