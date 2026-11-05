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

                # Metamodel files instead of -- @path directives
                swift-atl transform Families2Persons.atl \\
                  --source families.xmi --source-metamodel Families.ecore \\
                  --target persons.xmi --target-metamodel Persons.ecore

                # Refine a model in place, with one metamodel for source and target
                swift-atl transform Cleanup.atl --refining \\
                  --source customers.xmi --target cleaned.xmi --metamodel Customer.ecore

                # Check a transformation against its metamodels without running it
                swift-atl transform Families2Persons.atl --validate-only \\
                  --source-metamodel Families.ecore --target-metamodel Persons.ecore

                # Module parameters declared with -- @param in the transformation
                swift-atl transform Ecore2GenModel.atl \\
                  --source IN=library.ecore \\
                  --target OUT=library.genmodel \\
                  --param basePackage=org.example \\
                  --param prefix=Library

            Metamodel files given with --source-metamodel, --target-metamodel or --metamodel \
            take the place of the -- @path and -- @nsURI directives of their metamodels. Give them \
            by position, in the order of the module header, or as name=file.ecore with the \
            metamodel name of the header. --metamodel binds any metamodel of the module, such as \
            one that source and target models share.

            A -- @path directive that starts with / names a file in an Eclipse workspace, as \
            /Project/Families.ecore. It is looked up in each metamodel search directory, first \
            with the directory as the workspace (Project/Families.ecore) and then with the \
            directory as the project directory itself (Families.ecore). Without --metamodel-path \
            or ECOREPATH, the directory of the transformation, its parent and the current \
            directory are searched.

            A module declared with refining instead of from, or run with --refining, refines its \
            source model: each target model starts as a copy of the source model, rules change \
            the elements they match, and elements that no rule matches are kept unchanged. A \
            rule whose to section starts with drop deletes the element it matches, together \
            with what it contains, after all other rules have run, and references to the \
            deleted elements are removed; drop is an error outside refining mode.

            --validate-only parses the transformation, binds its metamodels, checks the model \
            element types and bound features of its rules and helpers against them, and loads \
            the source models that are given, without running the transformation or writing \
            targets.

            The Ecore and generator model metamodels are built in: a transformation can name them \
            with -- @nsURI directives, without a metamodel file. Targets that are instances of a \
            built-in metamodel are written in the layout of the Eclipse Modeling Framework, with \
            references to other models as uri#fragment attribute values.

            A transformation whose rules match nothing writes each target as an empty model: an \
            XMI document without elements, or an empty JSON array.

            \(ReferenceStyleOptions.discussion(written: "target models of metamodels that are not built in"))

            \(UnsetFeatureOptions.discussion(reader: "the rules of the transformation"))

            \(ATLSemanticsOptions.discussion(reader: "the transformation"))

            \(SemanticsOptions.discussion())
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

    /// The metamodel files that take the place of the directives of the transformation.
    @OptionGroup(title: "Metamodels")
    var metamodelFiles: TransformMetamodelOptions

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

    /// Whether the transformation refines its source model, as if declared with `refining`.
    @Flag(
        name: .long,
        help: "Refine the source model: start each target as a copy of the source model and keep what no rule matches")
    var refining: Bool = false

    /// Whether the transformation is only checked, without running it or writing targets.
    @Flag(
        name: .long,
        help: "Check the transformation against its metamodels and load the source models, without running it")
    var validateOnly: Bool = false

    /// Whether nothing is printed when the command succeeds.
    @Flag(name: .shortAndLong, help: "Print nothing on success")
    var quiet: Bool = false

    /// The behaviours of the ATL source.
    @OptionGroup(title: "Evaluation")
    var atlSemanticsOptions: ATLSemanticsOptions

    /// The preset of the behaviours, standard or that of version 0.6.
    @OptionGroup(title: "Evaluation")
    var semanticsOptions: SemanticsOptions

    /// Checks that the command line does not ask for both quiet and verbose output.
    ///
    /// - Throws: A validation error if `--quiet` is given with `--verbose` or `--debug`.
    func validate() throws {
        if quiet && (verbose || debug) {
            throw ArgumentParser.ValidationError("--quiet cannot be combined with --verbose or --debug")
        }
    }

    func run() async throws {
        let settings = try semanticsOptions.settings()
        let atlOptions = atlSemanticsOptions.atlOptions(settings: settings)
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
            let parser = ATLParser(options: atlOptions, enableDebugging: debug)
            let parsed = try await parser.parseContent(
                atlSource,
                filename: URL(fileURLWithPath: transformation).path,
                searchPaths: searchPaths,
                continueAfterErrors: continueAfterErrors || metamodelFiles.isGiven,
                metamodelRegistry: try await builtInMetamodelRegistry())
            var module = try await metamodelFiles.bind(
                parsed, requiresAll: metamodelFiles.isGiven && !continueAfterErrors, verbose: verbose)
            if refining && !module.isRefining {
                module = module.refining()
            }
            guard !module.isQuery else {
                throw ValidationError(
                    "'\(transformation)' is a query unit; run it with 'swift-atl \(QueryCommand.configuration.commandName ?? "")'"
                )
            }
            let parameterValues = try module.parameterValues(fromText: parseParameters(param))

            if verbose {
                print("Transformation module loaded: \(module.name)")
                if module.isRefining {
                    print("  - Running in refining mode")
                }
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

            if validateOnly {
                try await checkOnly(module, sourceFiles: sourceFiles, targetFiles: targetFiles, settings: settings)
                return
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
                containerLookupScope: settings.containerLookupScope,
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
            let targetResourceSet = settings.makeResourceSet()
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

            let unsetFeatureReads = unsetFeatureOptions.unsetFeatures(settings: settings)
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
            } else if !quiet {
                let duration = String(format: "%.3f", stats.executionTime * 1000)
                print("Transformation completed successfully in \(duration)ms")
            }

        } catch {
            print("\(validateOnly ? "Validation" : "Transformation") failed: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }

    /// Checks a transformation and its models without running it.
    ///
    /// The module is checked with ``TransformationCheck/problems(of:)``. The source models that
    /// are given are mapped to the source models of the module and loaded with its metamodels,
    /// and the target models that are given are mapped to its target models; no file is written.
    ///
    /// - Parameters:
    ///   - module: The module, with its metamodels bound.
    ///   - sourceFiles: The source model files from the command line, possibly none.
    ///   - targetFiles: The target model files from the command line, possibly none.
    ///   - settings: The settings of the run, whose container lookup scope applies.
    /// - Throws: ``TransformationError/invalidTransformation(_:)`` for problems of the module,
    ///   and the errors of mapping and loading the models.
    private func checkOnly(
        _ module: ATLModule, sourceFiles: [String], targetFiles: [String], settings: SemanticsSettings
    ) async throws {
        let problems = TransformationCheck.problems(of: module)
        guard problems.isEmpty else { throw TransformationError.invalidTransformation(problems) }
        var loadedModels = 0
        if !sourceFiles.isEmpty {
            let mapping = try mapFilesToAliases(
                filePaths: sourceFiles, aliases: Array(module.sourceMetamodels.keys), modelType: "source",
                verbose: verbose)
            loadedModels = try await loadModelsFromMapping(
                mapping, metamodels: module.sourceMetamodels, containerLookupScope: settings.containerLookupScope,
                explicitFormat: inputFormat, verbose: verbose, debug: debug
            ).count
        }
        if !targetFiles.isEmpty {
            _ = try mapFilesToAliases(
                filePaths: targetFiles, aliases: Array(module.targetMetamodels.keys), modelType: "target",
                verbose: verbose)
        }
        guard !quiet else { return }
        let metamodels = TransformationCheck.metamodelsByName(of: module).sorted { $0.key < $1.key }
            .map { "\($0.key) (\($0.value.nsURI))" }
        print("Transformation '\(module.name)' is valid")
        print("  Metamodels: \(metamodels.joined(separator: ", "))")
        print("  Rules: \(module.matchedRules.count) matched, \(module.calledRules.count) called; helpers: \(module.helpers.count)")
        if module.isRefining {
            print("  Refining mode")
        }
        print("  Source models loaded: \(loadedModels)")
    }
}
