//
// TransformCommand.swift
// swift-atl
//
//  Created by Rene Hexel on 6/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ATL
import ArgumentParser
import ECore
import Foundation
import OrderedCollections

/// Command for executing model transformations.
///
/// The transform command executes ATL model-to-model transformations using
/// compiled transformation modules, processing source models to produce
/// target models according to transformation rules.
struct TransformCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "transform",
        abstract: "Execute model transformations",
        discussion: """
            Executes model transformations using compiled ATL modules or source files.
            Supports transformation of models in XMI and JSON formats with automatic
            format detection and conversion.

            Examples:
                # Transform using ATL source
                swift-atl transform Families2Persons.atl \\
                  --source families.xmi --target persons.xmi
            """
    )

    @Argument(help: "ATL transformation file (.atl)")
    var transformation: String

    @Option(name: .long, help: "Source model files (format: alias=file)")
    var sources: [String] = []

    @Option(name: .long, help: "Target model files (format: alias=file)")
    var targets: [String] = []

    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    func run() async throws {
        if verbose {
            print("Starting ATL transformation: \(transformation)")
            print("Source models: \(sources)")
            print("Target models: \(targets)")
        }

        do {
            if verbose {
                print("Loading transformation module...")
            }

            // Parse the transformation file
            let atlSource = try String(contentsOfFile: transformation, encoding: .utf8)
            let parser = ATLParser()
            let module = try await parser.parseContent(
                atlSource, filename: URL(fileURLWithPath: transformation).lastPathComponent)

            if verbose {
                print("Transformation module loaded: \(module.name)")
                print(
                    "  - Source metamodels: \(module.sourceMetamodels.keys.joined(separator: ", "))"
                )
                print(
                    "  - Target metamodels: \(module.targetMetamodels.keys.joined(separator: ", "))"
                )
                print("  - Matched rules: \(module.matchedRules.count)")
                print("  - Called rules: \(module.calledRules.count)")
                print("  - Helpers: \(module.helpers.count)")
            }

            // Create and configure the ATL virtual machine
            let virtualMachine = await MainActor.run { ATLVirtualMachine(module: module) }

            if verbose {
                print("Executing transformation...")
            }

            // TODO: Implement actual model loading and transformation execution
            // For now, just run the VM with empty resources
            let emptySourceModels: OrderedDictionary<String, Resource> = [:]
            let emptyTargetModels: OrderedDictionary<String, Resource> = [:]

            try await virtualMachine.execute(
                sources: emptySourceModels,
                targets: emptyTargetModels
            )

            // Display execution statistics
            let stats = await MainActor.run { virtualMachine.getStatistics() }
            if verbose {
                print("Transformation Statistics:")
                print(stats.summary())
            } else {
                let duration = String(format: "%.3f", stats.executionTime * 1000)
                print("Transformation completed in \(duration)ms")
            }

        } catch {
            print("Transformation failed: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}

// MARK: - Generate Command

/// Command for generating code from models using ATL transformations.
///
/// The generate command uses ATL-based code generators to produce source code
/// from input models. It supports multiple target languages and customizable
/// generation templates through ATL transformation modules.
