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
        version: "0.1.0",
        subcommands: [
            InfoCommand.self,
            ValidateCommand.self,
            ConvertCommand.self,
            GenerateCommand.self,
            QueryCommand.self,
        ]
    )
}
