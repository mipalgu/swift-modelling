//
// SwiftEcore.swift
// ECore
//
//  Created by Rene Hexel on 3/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ArgumentParser

/// The main command-line interface for Swift Ecore.
///
/// Swift Ecore provides Eclipse Modeling Framework (EMF) functionality for Swift,
/// including model validation, format conversion, code generation, and querying capabilities.
@main
struct SwiftEcoreCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swift-ecore",
        abstract: "Swift Ecore - Eclipse Modeling Framework for Swift",
        discussion: """
            Copyright (c) 2025 Rene Hexel.
            All rights reserved.

            Swift Ecore provides comprehensive support for metamodel specifications.
            It enables parsing, validation, format conversion, and queries of
            metamodels defined in .ecore (XML) and JSON format.

            The tool supports standard Ecore metamodel syntax for compatibility with existing
            Eclipse Ecore meta-models while providing enhanced performance through Swift's concurrent
            execution model and type safety.
            """,
        version: "0.1.1",
        subcommands: [
            InfoCommand.self,
            ValidateCommand.self,
            ConvertCommand.self,
            GenerateCommand.self,
            QueryCommand.self,
        ]
    )
}
