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
import GenModel
import ModellingCommandLine
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
                  --target organisations.xmi

                # Module parameters declared with -- @param in the transformation
                swift-atl transform Ecore2GenModel.atl \\
                  --source IN=library.ecore \\
                  --target OUT=library.genmodel \\
                  --param basePackage=org.example \\
                  --param prefix=Library

            The Ecore and generator model metamodels are built in: a transformation can name them \
            with -- @nsURI directives, without a metamodel file. Targets that are instances of a \
            built-in metamodel are written in the layout of the Eclipse Modeling Framework, with \
            references to other models as uri#fragment attribute values.

            A transformation whose rules match nothing writes each target as an empty model: an \
            XMI document without elements, or an empty JSON array.

            \(ReferenceStyleOptions.discussion(written: "target models of metamodels that are not built in"))

            \(UnsetFeatureOptions.discussion(reader: "the rules of the transformation"))
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

    /// Values for the parameters that the transformation declares with `-- @param`.
    ///
    /// Each value is given as `name=value` and converted to the declared type of the parameter.
    /// The option can be repeated, once per parameter.
    @Option(
        name: .long,
        help: "Value for a module parameter as name=value (can be specified multiple times)")
    var param: [String] = []

    /// How the transformation reads features that a model does not set.
    @OptionGroup(title: "Evaluation")
    var unsetFeatureOptions: UnsetFeatureOptions

    /// How XMI target models spell references into themselves.
    @OptionGroup var referenceStyleOptions: ReferenceStyleOptions

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
            let searchPaths = metamodelSearchPaths(for: transformation, explicit: metamodelPath)

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
                filename: URL(fileURLWithPath: transformation).path,
                searchPaths: searchPaths,
                continueAfterErrors: continueAfterErrors,
                metamodelRegistry: try await builtInMetamodelRegistry())
            guard !module.isQuery else {
                throw ValidationError(
                    "'\(transformation)' is a query unit; run it with 'swift-atl \(QueryCommand.configuration.commandName ?? "")'"
                )
            }
            let parameterValues = try module.parameterValues(fromText: parseParameters(param))

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

            // Target resources carry their metamodels, so they are written in their namespaces
            let targetResourceSet = ResourceSet()
            await MetamodelRegistration.register(module.targetMetamodels.values, into: targetResourceSet)
            var targetModels: OrderedDictionary<String, Resource> = [:]
            for (alias, path) in targetMapping {
                let builtIn = module.targetMetamodels[alias].map(isBuiltIn) ?? false
                let resource = Resource(
                    uri: builtIn ? URL(fileURLWithPath: path).absoluteString : "file://\(path)")
                await resource.setResourceSet(targetResourceSet)
                targetModels[alias] = resource

                if verbose {
                    print("  - \(alias) -> \(path)")
                }
            }

            // Step 4: Execute transformation
            if verbose {
                print("\n=== Executing Transformation ===")
            }

            let unsetFeatureReads = unsetFeatureOptions.unsetFeatures
            let virtualMachine = await MainActor.run {
                ATLVirtualMachine(module: module, unsetFeatureReads: unsetFeatureReads)
            }

            // Enable debug mode if requested
            if debug {
                await virtualMachine.enableDebugging(true)
            }

            try await virtualMachine.execute(
                sources: sourceModels,
                targets: targetModels,
                parameters: parameterValues
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
                verbose: verbose,
                emfLayoutAliases: Set(
                    module.targetMetamodels.filter { isBuiltIn($0.value) }.map(\.key)),
                xmiOptions: referenceStyleOptions.serializationOptions
            )
            withExtendedLifetime(targetResourceSet) {}

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
