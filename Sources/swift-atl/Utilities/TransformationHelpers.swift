//
// TransformationHelpers.swift
// swift-atl
//
//  Created by Rene Hexel on 6/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ATL
import ECore
import Foundation
import GenModel
import ModellingCommandLine
import OrderedCollections

// MARK: - Model Loading

/// Loads a model from a file using the appropriate parser.
///
/// The model is read in the format that the explicit format names or, without one, in the
/// format that the file extension names, as ``ModelFileFormat/instanceFormat(of:explicit:)``
/// chooses it. Classes that the registered metamodels do not define are read from the
/// document itself. Provides verbose output when requested, displaying the number of objects
/// loaded.
///
/// - Parameters:
///   - path: The file path to load from.
///   - resourceSet: The resource set with the registered metamodels, if any.
///   - containerLookupScope: The container lookup scope of the resource set created when
///     none is given, or `nil` for none.
///   - explicitFormat: Optional explicit format string override (e.g., "xmi", "json").
///   - verbose: Whether to print verbose output.
///   - debug: Whether to enable debug mode for parsers.
/// - Returns: The loaded resource containing the model.
/// - Throws: `TransformationError.modelFileNotFound` if the file doesn't exist.
func loadModel(
    from path: String,
    resourceSet: ResourceSet? = nil,
    containerLookupScope: ContainerLookupScope? = nil,
    explicitFormat: String? = nil,
    verbose: Bool,
    debug: Bool = false
) async throws -> Resource {
    let url = URL(fileURLWithPath: path)

    guard FileManager.default.fileExists(atPath: path) else {
        throw TransformationError.modelFileNotFound(path)
    }

    let format = ModelFileFormat.instanceFormat(of: url, explicit: explicitFormat)

    if verbose {
        if let explicit = explicitFormat {
            print("  Loading \(format.description) model (format override: \(explicit)) from: \(path)")
        } else {
            print("  Loading \(format.description) model from: \(path)")
        }
    }

    let options = ModelIO.LoadOptions(requiresMetamodel: false, enableDebugging: debug)
    let resource = try await ModelIO.load(
        url: url, format: format,
        resourceSet: resourceSet ?? ResourceSet(defaultContainerLookupScope: containerLookupScope), options: options
    ).resource

    if verbose {
        let count = await resource.count()
        let roots = await resource.getRootObjects()
        print("    Loaded \(count) objects (\(roots.count) root objects)")
    }

    return resource
}

// MARK: - Model Loading from Mapping

/// Loads models from mapped file paths.
///
/// Takes a mapping of aliases to file paths and loads each model using
/// the appropriate parser based on file extension or explicit format override.
///
/// - Parameters:
///   - mapping: Ordered dictionary mapping aliases to file paths
///   - metamodels: The metamodels to register in a resource set shared by the models, if any
///   - containerLookupScope: The container lookup scope of the resource sets that receive the
///     models, or `nil` for none
///   - explicitFormat: Optional explicit format override for all models
///   - verbose: Whether to print verbose output during loading
/// - Returns: Ordered dictionary mapping aliases to loaded resources
/// - Throws: `TransformationError` if loading fails
func loadModelsFromMapping(
    _ mapping: OrderedDictionary<String, String>,
    metamodels: OrderedDictionary<String, EPackage>? = nil,
    containerLookupScope: ContainerLookupScope? = nil,
    explicitFormat: String? = nil,
    verbose: Bool,
    debug: Bool = false
) async throws -> OrderedDictionary<String, Resource> {

    // Create a ResourceSet if we have metamodels to register
    var resourceSet: ResourceSet? = nil
    if let metamodels = metamodels {
        let set = ResourceSet(defaultContainerLookupScope: containerLookupScope)
        await MetamodelRegistration.register(metamodels.values, into: set)
        resourceSet = set
    }

    var models: OrderedDictionary<String, Resource> = [:]

    for (alias, path) in mapping {
        if verbose {
            print("Loading model '\(alias)' from: \(path)")
        }

        let resource = try await loadModel(
            from: path,
            resourceSet: resourceSet,
            containerLookupScope: containerLookupScope,
            explicitFormat: explicitFormat,
            verbose: verbose,
            debug: debug
        )

        models[alias] = resource
    }

    return models
}

// MARK: - File Path to Alias Mapping

/// Maps file paths to metamodel aliases using positional or explicit mapping.
///
/// This function supports two formats:
/// 1. Positional: Files are matched to aliases by order (e.g., first file → first alias)
/// 2. Explicit: Files specify their alias using ALIAS=path format
///
/// - Parameters:
///   - filePaths: Array of file paths (positional) or ALIAS=path strings (explicit)
///   - aliases: Ordered list of metamodel aliases from the ATL module
///   - modelType: Description of model type for error messages ("source" or "target")
///   - verbose: Whether to print verbose mapping information
/// - Returns: Ordered dictionary mapping aliases to file paths
/// - Throws: `TransformationError.invalidModelArgument` if mapping fails
func mapFilesToAliases(
    filePaths: [String],
    aliases: [String],
    modelType: String,
    verbose: Bool
) throws -> OrderedDictionary<String, String> {

    var mapping: OrderedDictionary<String, String> = [:]

    // Check if any paths use explicit ALIAS=path format
    let hasExplicitAliases = filePaths.contains { $0.contains("=") }

    if hasExplicitAliases {
        // Explicit mapping: Parse ALIAS=path format
        for filePath in filePaths {
            let components = filePath.split(separator: "=", maxSplits: 1)
            guard components.count == 2 else {
                throw TransformationError.invalidModelArgument(
                    "Expected format: ALIAS=path or simple path, got: \(filePath)"
                )
            }

            let alias = String(components[0])
            let path = String(components[1])

            // Validate alias is declared in ATL module
            guard aliases.contains(alias) else {
                throw TransformationError.invalidModelArgument(
                    "\(modelType.capitalized) alias '\(alias)' not declared in ATL module. Available aliases: \(aliases.joined(separator: ", "))"
                )
            }

            mapping[alias] = path

            if verbose {
                print("  Explicit mapping: \(alias) -> \(path)")
            }
        }

        // Validate all required aliases are provided
        for alias in aliases {
            guard mapping[alias] != nil else {
                throw TransformationError.invalidModelArgument(
                    "Missing \(modelType) model for alias '\(alias)'. Required aliases: \(aliases.joined(separator: ", "))"
                )
            }
        }

    } else {
        // Positional mapping: Match files to aliases by order
        guard filePaths.count == aliases.count else {
            throw TransformationError.invalidModelArgument(
                "Mismatch: provided \(filePaths.count) \(modelType) file(s) but ATL module declares \(aliases.count) \(modelType) metamodel(s). Expected aliases: \(aliases.joined(separator: ", "))"
            )
        }

        for (index, alias) in aliases.enumerated() {
            mapping[alias] = filePaths[index]

            if verbose {
                print("  Positional mapping: \(alias) -> \(filePaths[index])")
            }
        }
    }

    return mapping
}

// MARK: - Model Saving

/// Saves a resource to a file using the appropriate serialiser.
///
/// Serialises the provided resource in the format that the explicit format names or, without
/// one, in the format that the file extension names, as
/// ``ModelFileFormat/instanceFormat(of:explicit:)`` chooses it. Provides verbose output when
/// requested.
///
/// - Parameters:
///   - resource: The resource to save.
///   - path: The destination file path.
///   - explicitFormat: Optional explicit format string override (e.g., "xmi", "json").
///   - verbose: Whether to print verbose output during saving.
///   - emfLayout: Whether an XMI model is written in the layout of the Eclipse Modeling Framework,
///     with references to other models as `uri#fragment` attribute values.
///   - xmiOptions: The options with which a model that is not written in the layout of the
///     Eclipse Modeling Framework is written as XMI.
/// - Throws: Serialisation errors if saving fails.
func saveModel(
    _ resource: Resource,
    to path: String,
    explicitFormat: String? = nil,
    verbose: Bool,
    emfLayout: Bool = false,
    xmiOptions: XMISerializationOptions = .legacy
) async throws {
    let url = URL(fileURLWithPath: path)

    let format = ModelFileFormat.instanceFormat(of: url, explicit: explicitFormat)

    if verbose {
        let count = await resource.count()
        if let explicit = explicitFormat {
            print("  Saving \(count) objects to \(format.description) file (format override: \(explicit)): \(path)")
        } else {
            print("  Saving \(count) objects to \(format.description) file: \(path)")
        }
    }

    if format == .xmi && emfLayout {
        try await GenModelResource.save(resource, to: url)
    } else {
        try await ModelIO.save(resource, to: url, format: format, xmiOptions: xmiOptions)
    }

    if verbose {
        print("    Saved successfully")
    }
}

/// Saves multiple target models to their specified file paths.
///
/// Processes a mapping of target model aliases to file paths, saving each
/// corresponding resource from the targets dictionary to its specified file path.
/// An explicit format can be provided to override automatic format detection.
///
/// - Parameters:
///   - targets: Ordered dictionary of target resources to save
///   - mapping: Ordered dictionary mapping aliases to output file paths
///   - explicitFormat: Optional explicit format override for all models
///   - verbose: Whether to print verbose output during saving
///   - emfLayoutAliases: The aliases of the targets that are written in the layout of the
///     Eclipse Modeling Framework, because they are instances of a built-in metamodel
///   - xmiOptions: The options with which the other targets are written as XMI
/// - Throws: Serialisation errors if saving fails
func saveTargetModelsFromMapping(
    _ targets: OrderedDictionary<String, Resource>,
    mapping: OrderedDictionary<String, String>,
    explicitFormat: String? = nil,
    verbose: Bool,
    emfLayoutAliases: Set<String> = [],
    xmiOptions: XMISerializationOptions = .legacy
) async throws {
    if verbose && !mapping.isEmpty {
        print("Saving target models...")
    }

    for (alias, path) in mapping {
        guard let resource = targets[alias] else {
            if verbose {
                print("Warning: Target model '\(alias)' not found (may not have been created)")
            }
            continue
        }

        try await saveModel(
            resource,
            to: path,
            explicitFormat: explicitFormat,
            verbose: verbose,
            emfLayout: emfLayoutAliases.contains(alias),
            xmiOptions: xmiOptions
        )
    }
}

// MARK: - Metamodel Search Paths

/// The environment variable that lists metamodel directories, separated by colons.
let metamodelSearchPathVariable = "ECOREPATH"

/// Builds the directories searched for the metamodels named by `-- @path` directives.
///
/// Directories given on the command line come first, followed by those listed in the
/// `ECOREPATH` environment variable. Only when neither names a directory are the
/// default directories used: the directory of the ATL file, common `Resources`
/// directories near it, and the current directory.
///
/// - Parameters:
///   - atlFile: The path of the ATL file whose directives are resolved.
///   - explicit: The directories given with `--metamodel-path`, in order.
/// - Returns: The directories to search, in order.
func metamodelSearchPaths(for atlFile: String, explicit: [String]) -> [String] {
    var searchPaths: [String] = []
    var hasUserSpecifiedPaths = false

    // Priority 1: CLI arguments
    if !explicit.isEmpty {
        searchPaths.append(contentsOf: explicit)
        hasUserSpecifiedPaths = true
    }

    // Priority 2: ECOREPATH environment variable
    if let ecorepath = ProcessInfo.processInfo.environment[metamodelSearchPathVariable],
        !ecorepath.isEmpty
    {
        let paths = ecorepath.split(separator: ":").map(String.init)
        searchPaths.append(contentsOf: paths)
        hasUserSpecifiedPaths = true
    }

    // Only add default search paths if user hasn't specified any
    if !hasUserSpecifiedPaths {
        let atlURL = URL(fileURLWithPath: atlFile)
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
    return searchPaths
}

// MARK: - Built-in Metamodels and Parameters

/// The metamodels that the tool provides without a metamodel file.
///
/// A transformation names them with `-- @nsURI` directives: the Ecore metamodel by
/// `http://www.eclipse.org/emf/2002/Ecore` and the generator metamodel by
/// `http://www.eclipse.org/emf/2002/GenModel`.
///
/// - Returns: A registry that holds the built-in metamodels.
/// - Throws: An error if the generator metamodel cannot be loaded.
@MainActor
func builtInMetamodelRegistry() async throws -> ATLMetamodelRegistry {
    ATLMetamodelRegistry(packages: [EcorePackage.instance, try await GenModelPackage.load()])
}

/// Reports whether a package is one of the built-in metamodels.
///
/// - Parameter package: The package to examine.
/// - Returns: `true` if the namespace URI of the package is that of the Ecore or generator metamodel.
func isBuiltIn(_ package: EPackage) -> Bool {
    [EcorePackage.instance.nsURI, GenModelConstants.nsURI].contains(package.nsURI)
}

/// The family of `name=value` arguments that give values to module parameters.
///
/// The value is everything after the first `=`, so it can itself contain `=`; it is converted to
/// the declared type of the parameter by the module.
let moduleParameterArguments = KeyValueOption<String>(noun: "parameter")

/// Splits `name=value` arguments into module parameter values.
///
/// The value is everything after the first `=`, so it can itself contain `=`. A later argument
/// for the same name replaces an earlier one.
///
/// - Parameter arguments: The arguments as given on the command line.
/// - Returns: The textual values by parameter name.
/// - Throws: `TransformationError.invalidParameterArgument` if an argument has no name or no `=`.
func parseParameters(_ arguments: [String]) throws -> [String: String] {
    do {
        return try moduleParameterArguments.values(from: arguments)
    } catch KeyValueOptionError.missingSeparator(_, let text, _) {
        throw TransformationError.invalidParameterArgument(text)
    }
}
