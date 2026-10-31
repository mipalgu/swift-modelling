//
// QueryCommand.swift
// swift-atl
//
//  Created by Rene Hexel on 26/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ArgumentParser
import ECore
import EMFBase
import Foundation
import ModellingCommandLine
import OrderedCollections

/// Command for evaluating ATL query units.
///
/// The query command evaluates a query unit, which starts with `query Name = expression;`
/// instead of a module header, over its input models. It prints the value of the query and
/// lets the query write files with `writeTo` and `writeToWithCharset`, confined to an output
/// directory unless unrestricted paths are allowed explicitly.
struct QueryCommand: AsyncParsableCommand {

    /// The separator between a model name and its metamodel name in a `--source` argument.
    static let metamodelSeparator: Character = ":"

    /// The separator between a name and a file path in `--source` and `--metamodel` arguments.
    static let pathSeparator: Character = "="

    static let configuration = CommandConfiguration(
        commandName: "query",
        abstract: "Evaluate ATL queries",
        discussion: """
            Evaluates an ATL query unit over its input models and prints its value. A query unit \
            starts with 'query Name = expression;' instead of a module header and contains only \
            helpers besides its query.

            The metamodels of a query are named by its -- @path and -- @nsURI directives, or given \
            with --metamodel NAME=file.ecore. Each metamodel is an input model of the same name, so \
            --source model.xmi binds the models in the order of their metamodels, and \
            --source Name=model.xmi binds a model by metamodel name. --source IN:Name=model.xmi \
            names the model IN, for allInstancesFrom('IN'), and binds it to the metamodel Name.

            A query can write strings to files with writeTo(path) and \
            writeToWithCharset(path, charset). Relative paths are resolved against the output \
            directory, which is the current directory unless --output-directory names another. \
            Absolute paths and paths that lead outside the output directory, through '..' or \
            symbolic links, are rejected unless --allow-unrestricted-paths is given. Missing \
            directories are created and existing files are replaced.

            The value of the query is printed to standard output: a string as it is, followed by \
            a line break unless it ends with one, and any other value as ATL writes it, such as \
            true, 42 or Sequence{'a', 'b'}. A query that ends with writeTo prints true. Use \
            --no-print-result to print nothing. Messages are written to standard error.

            Examples:
                # Write the dot file that the query builds, below graphs/
                swift-atl query Flow2Dot.atl --source order.xmi --output-directory graphs

                # Print the value of a query to a file instead
                swift-atl query FlowText.atl --source Flow=order.xmi > order.txt

                # Name the model and give the metamodel on the command line
                swift-atl query Count.atl --metamodel Flow=Flow.ecore \\
                  --source IN:Flow=order.xmi --param offset=10

            \(UnsetFeatureOptions.discussion(reader: "the query"))

            \(ATLSemanticsOptions.discussion(reader: "the query"))

            \(SemanticsOptions.discussion())
            """
    )

    @Argument(help: "ATL query file (.atl)")
    var query: String

    /// The input model files.
    ///
    /// Each argument is a path, `NAME=path` or `NAME:METAMODEL=path`.
    @Option(
        name: .long,
        help: ArgumentHelp(
            "Input model file as path, NAME=path or NAME:METAMODEL=path (can be specified multiple times)",
            valueName: "[NAME[:METAMODEL]=]path"))
    var source: [String] = []

    /// Ecore metamodel files, optionally bound to the metamodel name that the query uses.
    @Option(
        name: [.customShort("m"), .long],
        help: ArgumentHelp(
            "Ecore metamodel of the input models as file.ecore or NAME=file.ecore (can be specified multiple times)",
            discussion: "Without a name, the metamodel is bound under the name of its package.",
            valueName: "[NAME=]file.ecore"))
    var metamodel: [String] = []

    /// Input format override for the input models.
    @Option(
        name: .long,
        help: "Input format for the input models (xmi, json) - auto-detect from extension if not specified")
    var inputFormat: String?

    /// Metamodel search paths for resolving `@path` directives.
    @Option(name: .long, help: "Metamodel search path (can be specified multiple times)")
    var metamodelPath: [String] = []

    /// Values for the parameters that the query declares with `-- @param`.
    @Option(
        name: .long,
        help: "Value for a query parameter as name=value (can be specified multiple times)")
    var param: [String] = []

    /// The directory that `writeTo` resolves relative paths against.
    @Option(
        name: .long,
        help: ArgumentHelp(
            "Directory that writeTo and writeToWithCharset write into (default: the current directory)",
            valueName: "directory"))
    var outputDirectory: String?

    /// Whether `writeTo` may write outside the output directory.
    @Flag(
        name: .long,
        help: "Let writeTo and writeToWithCharset write to absolute paths and outside the output directory")
    var allowUnrestrictedPaths: Bool = false

    /// Whether the value of the query is printed.
    @Flag(
        name: .long, inversion: .prefixedNo,
        help: "Print the value of the query to standard output")
    var printResult: Bool = true

    /// How the query reads features that a model does not set.
    @OptionGroup(title: "Evaluation")
    var unsetFeatureOptions: UnsetFeatureOptions

    @Flag(name: .shortAndLong, help: "Enable verbose output on standard error")
    var verbose: Bool = false

    @Flag(name: .shortAndLong, help: "Enable debug output with detailed execution tracing")
    var debug: Bool = false

    /// The behaviours of the ATL source.
    @OptionGroup(title: "Evaluation")
    var atlSemanticsOptions: ATLSemanticsOptions

    /// The preset of the behaviours, standard or that of version 0.6.
    @OptionGroup(title: "Evaluation")
    var semanticsOptions: SemanticsOptions

    func run() async throws {
        let settings = try semanticsOptions.settings()
        do {
            let value = try await evaluate(settings: settings)
            if printResult {
                let text = await MainActor.run {
                    (value as? String) ?? ATLValueText.render(value)
                }
                print(text, terminator: text.hasSuffix("\n") ? "" : "\n")
            }
        } catch {
            writeError("Query failed: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }

    /// Parses the query, binds its input models and evaluates it.
    ///
    /// - Parameter settings: The preset, configuration file and container scope of the run.
    /// - Returns: The value of the query.
    /// - Throws: Parsing, binding, loading and execution errors.
    private func evaluate(settings: SemanticsSettings) async throws -> (any EcoreValue)? {
        let searchPaths = metamodelSearchPaths(for: query, explicit: metamodelPath)
        let atlOptions = atlSemanticsOptions.atlOptions(settings: settings)
        let unit = try await ATLParser(options: atlOptions, enableDebugging: debug).parseContent(
            String(contentsOfFile: query, encoding: .utf8),
            filename: URL(fileURLWithPath: query).path,
            searchPaths: searchPaths,
            continueAfterErrors: false,
            metamodelRegistry: try await builtInMetamodelRegistry())
        guard unit.isQuery else {
            throw ValidationError(
                "'\(query)' is a transformation module; run it with 'swift-atl \(TransformCommand.configuration.commandName ?? "")'"
            )
        }
        let parameterValues = try unit.parameterValues(fromText: parseParameters(param))
        let packages = try await metamodelPackages()

        var metamodelNames = Array(unit.sourceMetamodels.keys)
        for name in packages.keys where !metamodelNames.contains(name) {
            metamodelNames.append(name)
        }
        let (models, files) = try inputModels(metamodelNames: metamodelNames)
        let bound = unit.declaringSourceModels(
            models, metamodels: Dictionary(uniqueKeysWithValues: packages.map { ($0.key, $0.value) }))
        for (model, package) in bound.sourceMetamodels where package.eClassifiers.isEmpty {
            let name = bound.declaredMetamodelNames[model] ?? package.name
            throw ValidationError(
                "No metamodel is available for '\(name)': add a -- @path directive or --metamodel \(name)=file.ecore"
            )
        }
        report("Query \(bound.name) over \(models.map { "\($0.key) : \($0.value)" }.joined(separator: ", "))")

        let sources = try await loadModelsFromMapping(
            files, metamodels: bound.sourceMetamodels, containerLookupScope: settings.containerLookupScope,
            explicitFormat: inputFormat, verbose: false, debug: debug)
        let fileOutput = fileOutputPolicy()
        if let directory = fileOutput.baseDirectory {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory),
                !isDirectory.boolValue
            {
                throw ValidationError(
                    "The output directory '\(directory.path)' exists but is not a directory")
            }
        }
        report("Writing files relative to \(fileOutput.baseDirectory?.path ?? "")")

        let unsetFeatureReads = unsetFeatureOptions.unsetFeatures(settings: settings)
        let virtualMachine = await MainActor.run {
            ATLVirtualMachine(
                module: bound, unsetFeatureReads: unsetFeatureReads, fileOutput: fileOutput)
        }
        if debug {
            await virtualMachine.enableDebugging(true)
        }
        let value = try await virtualMachine.evaluateQuery(
            sources: sources, parameters: parameterValues)
        let statistics = await MainActor.run { virtualMachine.getStatistics() }
        report("Query evaluated in \(String(format: "%.3f", statistics.executionTime * 1000))ms")
        return value
    }

    /// Loads the metamodels given with `--metamodel`.
    ///
    /// - Returns: The packages indexed by the metamodel name they are bound to, in command line order.
    /// - Throws: An error if a file cannot be loaded.
    private func metamodelPackages() async throws -> OrderedDictionary<String, EPackage> {
        var packages: OrderedDictionary<String, EPackage> = [:]
        for argument in metamodel {
            let (name, path) = Self.split(argument)
            guard FileManager.default.fileExists(atPath: path) else {
                throw TransformationError.modelFileNotFound(path)
            }
            let package = try await EPackage(url: URL(fileURLWithPath: path))
            packages[name ?? package.name] = package
        }
        return packages
    }

    /// Maps the `--source` arguments to input models.
    ///
    /// Positional paths are matched to the metamodels in order, each model named after its
    /// metamodel. Named arguments give the model name and, after a colon, the metamodel name,
    /// which defaults to the model name.
    ///
    /// - Parameter metamodelNames: The metamodel names known for the query, in order.
    /// - Returns: The metamodel name of each model and the file of each model, by model name.
    /// - Throws: `TransformationError.invalidModelArgument` if the arguments do not fit.
    private func inputModels(metamodelNames: [String]) throws -> (
        models: OrderedDictionary<String, String>, files: OrderedDictionary<String, String>
    ) {
        var models: OrderedDictionary<String, String> = [:]
        var files: OrderedDictionary<String, String> = [:]
        let available = metamodelNames.isEmpty ? "none" : metamodelNames.joined(separator: ", ")
        if source.contains(where: { $0.contains(Self.pathSeparator) }) {
            for argument in source {
                let (name, path) = Self.split(argument)
                guard let name, !name.isEmpty else {
                    throw TransformationError.invalidModelArgument(
                        "Expected NAME=path or NAME:METAMODEL=path for every model, got: \(argument)")
                }
                let parts = name.split(separator: Self.metamodelSeparator, maxSplits: 1).map(String.init)
                let modelName = parts[0]
                let metamodelName = parts.count == 2 ? parts[1] : modelName
                guard parts.count == 2 || metamodelNames.contains(metamodelName) else {
                    throw TransformationError.invalidModelArgument(
                        "'\(modelName)' is not a metamodel of the query (metamodels: \(available)); use \(modelName)\(Self.metamodelSeparator)METAMODEL=path"
                    )
                }
                guard models.updateValue(metamodelName, forKey: modelName) == nil else {
                    throw TransformationError.invalidModelArgument(
                        "The model '\(modelName)' is given more than once")
                }
                files[modelName] = path
            }
        } else {
            guard source.count == metamodelNames.count else {
                throw TransformationError.invalidModelArgument(
                    "Mismatch: provided \(source.count) input model file(s) but the query names \(metamodelNames.count) metamodel(s). Metamodels: \(available)"
                )
            }
            for (name, path) in zip(metamodelNames, source) {
                models[name] = name
                files[name] = path
            }
        }
        return (models, files)
    }

    /// The policy for the files that the query writes.
    private func fileOutputPolicy() -> ATLFileOutputPolicy {
        let directory = URL(
            fileURLWithPath: outputDirectory ?? FileManager.default.currentDirectoryPath,
            isDirectory: true)
        return allowUnrestrictedPaths
            ? .unrestricted(relativeTo: directory) : .confined(to: directory)
    }

    /// Splits an argument of the form `NAME=path` into its name and path.
    ///
    /// - Parameter argument: The argument as given on the command line.
    /// - Returns: The name, or `nil` without a separator, and the path.
    private static func split(_ argument: String) -> (name: String?, path: String) {
        guard let separator = argument.firstIndex(of: pathSeparator) else { return (nil, argument) }
        return (String(argument[..<separator]), String(argument[argument.index(after: separator)...]))
    }

    /// Writes a progress message to standard error when verbose output is enabled.
    private func report(_ message: String) {
        if verbose { writeError(message) }
    }

    /// Writes a line to standard error.
    private func writeError(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
}
