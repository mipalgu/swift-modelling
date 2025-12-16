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
import OrderedCollections

// MARK: - Model Format Detection

/// Detects the model format based on file extension or explicit override.
///
/// Examines the file extension of the provided path and returns the corresponding
/// model format. Supports XMI, Ecore, and JSON file extensions. If an explicit
/// format is provided, it takes precedence over the file extension.
///
/// - Parameters:
///   - path: The file path to analyse.
///   - explicitFormat: Optional explicit format override (e.g., "xmi", "json").
/// - Returns: The detected or specified model format.
func detectFormat(from path: String, explicitFormat: String? = nil) -> ModelFormat {
    if let explicit = explicitFormat?.lowercased() {
        switch explicit {
        case "xmi", "ecore":
            return .xmi
        case "json":
            return .json
        default:
            return .xmi  // Default to XMI for unknown formats
        }
    }

    let pathExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
    switch pathExtension {
    case "xmi", "ecore":
        return .xmi
    case "json":
        return .json
    default:
        return .xmi  // Default to XMI
    }
}

// MARK: - Model Loading

/// Loads a model from a file using the appropriate parser.
///
/// This function automatically detects the model format based on the file
/// extension and uses the corresponding parser to load the resource. An
/// explicit format can be provided to override the automatic detection.
/// Provides verbose output when requested, displaying the number of objects
/// loaded.
///
/// - Parameters:
///   - path: The file path to load from.
///   - format: The model format to use for parsing (can be overridden by explicitFormat).
///   - explicitFormat: Optional explicit format string override (e.g., "xmi", "json").
///   - verbose: Whether to print verbose output.
/// - Returns: The loaded resource containing the model.
/// - Throws: `TransformationError.modelFileNotFound` if the file doesn't exist.
func loadModel(
    from path: String,
    format: ModelFormat,
    explicitFormat: String? = nil,
    verbose: Bool
) async throws -> Resource {
    let url = URL(fileURLWithPath: path)

    guard FileManager.default.fileExists(atPath: path) else {
        throw TransformationError.modelFileNotFound(path)
    }

    let actualFormat = explicitFormat != nil ? detectFormat(from: path, explicitFormat: explicitFormat) : format

    if verbose {
        if let explicit = explicitFormat {
            print("  Loading \(actualFormat.description) model (format override: \(explicit)) from: \(path)")
        } else {
            print("  Loading \(actualFormat.description) model from: \(path)")
        }
    }

    let resource: Resource
    switch actualFormat {
    case .xmi:
        let parser = XMIParser()
        resource = try await parser.parse(url)
    case .json:
        let parser = JSONParser()
        resource = try await parser.parse(url)
    }

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
///   - explicitFormat: Optional explicit format override for all models
///   - verbose: Whether to print verbose output during loading
/// - Returns: Ordered dictionary mapping aliases to loaded resources
/// - Throws: `TransformationError` if loading fails
func loadModelsFromMapping(
    _ mapping: OrderedDictionary<String, String>,
    explicitFormat: String? = nil,
    verbose: Bool
) async throws -> OrderedDictionary<String, Resource> {

    var models: OrderedDictionary<String, Resource> = [:]

    for (alias, path) in mapping {
        if verbose {
            print("Loading model '\(alias)' from: \(path)")
        }

        let format = detectFormat(from: path, explicitFormat: explicitFormat)
        let resource = try await loadModel(
            from: path,
            format: format,
            explicitFormat: explicitFormat,
            verbose: verbose
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
/// Serialises the provided resource to the specified file path using either
/// XMI or JSON format based on the format parameter. An explicit format can
/// be provided to override the format determined from the file extension.
/// Provides verbose output when requested.
///
/// - Parameters:
///   - resource: The resource to save.
///   - path: The destination file path.
///   - format: The model format to use for serialisation (can be overridden by explicitFormat).
///   - explicitFormat: Optional explicit format string override (e.g., "xmi", "json").
///   - verbose: Whether to print verbose output during saving.
/// - Throws: Serialisation errors if saving fails.
func saveModel(
    _ resource: Resource,
    to path: String,
    format: ModelFormat,
    explicitFormat: String? = nil,
    verbose: Bool
) async throws {
    let url = URL(fileURLWithPath: path)

    let actualFormat = explicitFormat != nil ? detectFormat(from: path, explicitFormat: explicitFormat) : format

    if verbose {
        let count = await resource.count()
        if let explicit = explicitFormat {
            print("  Saving \(count) objects to \(actualFormat.description) file (format override: \(explicit)): \(path)")
        } else {
            print("  Saving \(count) objects to \(actualFormat.description) file: \(path)")
        }
    }

    let content: String
    switch actualFormat {
    case .xmi:
        let serializer = XMISerializer()
        content = try await serializer.serialize(resource)
    case .json:
        let serializer = JSONSerializer()
        content = try await serializer.serialize(resource)
    }

    try content.write(to: url, atomically: true, encoding: .utf8)

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
/// - Throws: Serialisation errors if saving fails
func saveTargetModelsFromMapping(
    _ targets: OrderedDictionary<String, Resource>,
    mapping: OrderedDictionary<String, String>,
    explicitFormat: String? = nil,
    verbose: Bool
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

        let format = detectFormat(from: path, explicitFormat: explicitFormat)
        try await saveModel(
            resource,
            to: path,
            format: format,
            explicitFormat: explicitFormat,
            verbose: verbose
        )
    }
}
