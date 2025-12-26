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
            Executes model transformations using ATL source files.
            Supports transformation of models in XMI and JSON formats with automatic
            format detection based on file extensions. Format can be overridden using
            --input-format and --output-format options.

            Source and target models are mapped to the metamodel aliases declared in
            the ATL transformation file's create statement. You can provide files
            positionally (matched by order) or explicitly with ALIAS=path format.

            Examples:
                # Positional mapping (simple)
                swift-atl transform Families2Persons.atl \\
                  --source families.xmi \\
                  --target persons.xmi

                # Explicit mapping (when clarity needed)
                swift-atl transform transformation.atl \\
                  --source IN=input.xmi \\
                  --target OUT=output.xmi

                # Format override (load XMI from .dat file, save JSON to .out file)
                swift-atl transform transformation.atl \\
                  --source input.dat \\
                  --target output.out \\
                  --input-format xmi \\
                  --output-format json

                # Multiple models (positional order matches create statement)
                swift-atl transform complex.atl \\
                  --source families.xmi \\
                  --source departments.xmi \\
                  --target persons.xmi \\
                  --target organizations.xmi
            """
    )

    @Argument(help: "ATL transformation file (.atl)")
    var transformation: String

    /// Source model file paths.
    ///
    /// Files are mapped to source metamodel aliases in the order they appear
    /// in the ATL transformation's create statement. Alternatively, you can
    /// specify explicit aliases using the format ALIAS=path.
    ///
    /// Examples:
    ///   - Positional: `--source input.xmi`
    ///   - Explicit:   `--source IN=input.xmi`
    @Option(name: .long, help: "Source model file (can be specified multiple times)")
    var source: [String] = []

    /// Target model file paths.
    ///
    /// Files are mapped to target metamodel aliases in the order they appear
    /// in the ATL transformation's create statement. Alternatively, you can
    /// specify explicit aliases using the format ALIAS=path.
    ///
    /// Examples:
    ///   - Positional: `--target output.xmi`
    ///   - Explicit:   `--target OUT=output.xmi`
    @Option(name: .long, help: "Target model file (can be specified multiple times)")
    var target: [String] = []

    /// Input format override for source models.
    ///
    /// Overrides automatic format detection based on file extension for all
    /// source models. When not specified, format is inferred from each file's
    /// extension (.xmi, .ecore → XMI; .json → JSON).
    @Option(name: .long, help: "Input format for source models (xmi, json) - auto-detect from extension if not specified")
    var inputFormat: String?

    /// Output format override for target models.
    ///
    /// Overrides automatic format detection based on file extension for all
    /// target models. When not specified, format is inferred from each file's
    /// extension (.xmi, .ecore → XMI; .json → JSON).
    @Option(name: .long, help: "Output format for target models (xmi, json) - infer from extension if not specified")
    var outputFormat: String?

    /// Deprecated: Source model files with explicit aliases.
    ///
    /// This option is deprecated. Use `--source` with positional arguments instead.
    @Option(name: .long, help: .hidden)
    var sources: [String] = []

    /// Deprecated: Target model files with explicit aliases.
    ///
    /// This option is deprecated. Use `--target` with positional arguments instead.
    @Option(name: .long, help: .hidden)
    var targets: [String] = []

    /// Metamodel search paths for resolving @path directives in ATL files.
    ///
    /// Specifies directories to search when loading metamodels referenced by @path
    /// directives in the transformation. Can be specified multiple times to provide
    /// multiple search paths. Paths are searched in order.
    ///
    /// The final search path order is:
    ///   1. Paths from --metamodel-path options (in order specified)
    ///   2. Paths from ECOREPATH environment variable (colon-separated)
    ///   3. Directory containing the ATL file
    ///   4. Current working directory
    ///
    /// Examples:
    ///   `--metamodel-path /path/to/metamodels`
    ///   `--metamodel-path ~/project/models --metamodel-path /usr/share/ecore`
    @Option(name: .long, help: "Metamodel search path (can be specified multiple times)")
    var metamodelPath: [String] = []

    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    @Flag(name: .shortAndLong, help: "Enable debug output with detailed execution tracing")
    var debug: Bool = false

    @Flag(name: .long, help: "Continue after metamodel loading errors (useful for testing)")
    var continueAfterErrors: Bool = false

    func run() async throws {
        if verbose {
            print("Starting ATL transformation: \(transformation)")
            print("Source model files: \(source)")
            print("Target model files: \(target)")
            if let inputFmt = inputFormat {
                print("Input format override: \(inputFmt)")
            }
            if let outputFmt = outputFormat {
                print("Output format override: \(outputFmt)")
            }
        }

        do {
            // Step 1: Build metamodel search paths
            var searchPaths: [String] = []
            var hasUserSpecifiedPaths = false

            // Priority 1: CLI arguments
            if !metamodelPath.isEmpty {
                searchPaths.append(contentsOf: metamodelPath)
                hasUserSpecifiedPaths = true
            }

            // Priority 2: ECOREPATH environment variable
            if let ecorepath = ProcessInfo.processInfo.environment["ECOREPATH"], !ecorepath.isEmpty {
                let paths = ecorepath.split(separator: ":").map(String.init)
                searchPaths.append(contentsOf: paths)
                hasUserSpecifiedPaths = true
            }

            // Only add default search paths if user hasn't specified any
            if !hasUserSpecifiedPaths {
                let atlURL = URL(fileURLWithPath: transformation)
                let atlDirectory = atlURL.deletingLastPathComponent().path

                // Default priority 1: ATL file's directory
                searchPaths.append(atlDirectory)

                // Default priority 2: Common metamodel directories relative to ATL file
                let atlParentDir = URL(fileURLWithPath: atlDirectory).deletingLastPathComponent().path
                let commonPaths = [
                    "\(atlParentDir)", // Parent of ATL directory
                    "\(atlParentDir)/Resources", // Common Resources directory
                    "\(atlDirectory)/../Resources", // Resources at same level
                    "\(atlDirectory)/../../Resources" // Resources two levels up (for test structures)
                ]
                for path in commonPaths {
                    let normalized = URL(fileURLWithPath: path).standardizedFileURL.path
                    if !searchPaths.contains(normalized) {
                        searchPaths.append(normalized)
                    }
                }

                // Default priority 3: Current working directory
                let currentDirectory = FileManager.default.currentDirectoryPath
                if currentDirectory != atlDirectory {
                    searchPaths.append(currentDirectory)
                }
            }

            if verbose && !searchPaths.isEmpty {
                print("Metamodel search paths:")
                for (index, path) in searchPaths.enumerated() {
                    print("  \(index + 1). \(path)")
                }
            }

            // Step 2: Parse the transformation file
            if verbose {
                print("\n=== Loading Transformation Module ===")
            }

            let atlSource = try String(contentsOfFile: transformation, encoding: .utf8)
            let parser = ATLParser(enableDebugging: debug)
            let module = try await parser.parseContent(
                atlSource,
                filename: URL(fileURLWithPath: transformation).lastPathComponent,
                searchPaths: searchPaths,
                continueAfterErrors: continueAfterErrors)

            if verbose {
                print("Transformation module loaded: \(module.name)")
                print("  - Source metamodels: \(module.sourceMetamodels.keys.joined(separator: ", "))")
                print("  - Target metamodels: \(module.targetMetamodels.keys.joined(separator: ", "))")
                print("  - Matched rules: \(module.matchedRules.count)")
                print("  - Called rules: \(module.calledRules.count)")
                print("  - Helpers: \(module.helpers.count)")
            }

            // Handle deprecated --sources/--targets flags
            let sourceFiles = source.isEmpty ? sources : source
            let targetFiles = target.isEmpty ? targets : target

            if !sources.isEmpty || !targets.isEmpty {
                if verbose {
                    print("\nNote: --sources and --targets flags are deprecated. Use --source and --target instead.")
                }
            }

            // Step 2: Map and load source models
            if verbose {
                print("\n=== Loading Source Models ===")
                if let inputFmt = inputFormat {
                    print("Using input format override: \(inputFmt)")
                }
            }

            let sourceAliases = Array(module.sourceMetamodels.keys)
            let sourceMapping = try mapFilesToAliases(
                filePaths: sourceFiles,
                aliases: sourceAliases,
                modelType: "source",
                verbose: verbose
            )

            let sourceModels = try await loadModelsFromMapping(
                sourceMapping,
                metamodels: module.sourceMetamodels,
                explicitFormat: inputFormat,
                verbose: verbose,
                debug: debug
            )

            if verbose {
                print("Loaded \(sourceModels.count) source model(s)")
            }

            // Step 3: Map target file paths and create resources
            if verbose {
                print("\n=== Preparing Target Models ===")
            }

            let targetAliases = Array(module.targetMetamodels.keys)
            let targetMapping = try mapFilesToAliases(
                filePaths: targetFiles,
                aliases: targetAliases,
                modelType: "target",
                verbose: verbose
            )

            var targetModels: OrderedDictionary<String, Resource> = [:]
            for (alias, path) in targetMapping {
                let resource = Resource(uri: "file://\(path)")
                targetModels[alias] = resource

                if verbose {
                    print("  - \(alias) -> \(path)")
                }
            }

            // Step 4: Execute transformation
            if verbose {
                print("\n=== Executing Transformation ===")
            }

            let virtualMachine = await MainActor.run { ATLVirtualMachine(module: module) }

            // Enable debug mode if requested
            if debug {
                await virtualMachine.enableDebugging(true)
            }

            try await virtualMachine.execute(
                sources: sourceModels,
                targets: targetModels
            )

            // Step 5: Save target models
            if verbose {
                print("\n=== Saving Results ===")
                if let outputFmt = outputFormat {
                    print("Using output format override: \(outputFmt)")
                }
            }

            try await saveTargetModelsFromMapping(
                targetModels,
                mapping: targetMapping,
                explicitFormat: outputFormat,
                verbose: verbose
            )

            // Step 6: Display execution statistics
            if verbose {
                print("\n=== Transformation Statistics ===")
            }

            let stats = await MainActor.run { virtualMachine.getStatistics() }
            if verbose {
                print(stats.summary())
            } else {
                let duration = String(format: "%.3f", stats.executionTime * 1000)
                print("Transformation completed successfully in \(duration)ms")
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
