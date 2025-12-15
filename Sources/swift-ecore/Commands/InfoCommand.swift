//
// InfoCommand.swift
// ECore
//
//  Created by Rene Hexel on 3/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//

import ArgumentParser

/// The default command that displays information about Swift Ecore.
struct InfoCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Show Swift Ecore information"
    )

    /// Executes the info command.
    ///
    /// Displays version information and available commands for Swift Ecore.
    func run() async throws {
        print(
            """
            Swift Ecore v0.1.0
            Eclipse Modeling Framework for Swift

            Available commands:
              validate    Validate models and metamodels
              convert     Convert between formats (XMI <-> JSON)
              generate    Generate code from models
              query       Query models and metamodels

            Use 'swift-ecore <command> --help' for detailed help on each command.
            """)
    }
}
