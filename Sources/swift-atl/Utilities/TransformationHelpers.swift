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

/// Detects the model format based on file extension.
///
/// Examines the file extension of the provided path and returns the corresponding
/// model format. Supports XMI, Ecore, and JSON file extensions.
///
/// - Parameter path: The file path to analyse
/// - Returns: The detected model format, defaulting to XMI if unrecognised
func detectFormat(from path: String) -> ModelFormat {
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
/// extension and uses the corresponding parser to load the resource. It
/// provides verbose output when requested, displaying the number of objects
/// loaded.
///
/// - Parameters:
///   - path: The file path to load from.
///   - format: The model format to use for parsing.
///   - verbose: Whether to print verbose output.
/// - Returns: The loaded resource containing the model.
/// - Throws: `TransformationError.modelFileNotFound` if the file doesn't exist.
func loadModel(from path: String, format: ModelFormat, verbose: Bool) async throws -> Resource {
    let url = URL(fileURLWithPath: path)

    guard FileManager.default.fileExists(atPath: path) else {
        throw TransformationError.modelFileNotFound(path)
    }

    if verbose {
        print("  Loading \(format.description) model from: \(path)")
    }

    let resource: Resource
    switch format {
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

// MARK: - Model Argument Parsing

/// Parses model arguments in ALIAS=path format.
///
/// Processes an array of model argument strings in the format "ALIAS=path",
/// loading each model using the appropriate parser based on file extension.
/// The function maintains the order of models using an ordered dictionary.
///
/// - Parameters:
///   - arguments: Array of model argument strings in ALIAS=path format.
///   - verbose: Whether to print verbose output during loading.
/// - Returns: Ordered dictionary mapping model aliases to loaded resources.
/// - Throws: `TransformationError.invalidModelArgument` if argument format is invalid.
func parseModelArguments(_ arguments: [String], verbose: Bool) async throws
    -> OrderedDictionary<String, Resource>
{
    var models: OrderedDictionary<String, Resource> = [:]

    for argument in arguments {
        // Parse "ALIAS=path" format
        let components = argument.split(separator: "=", maxSplits: 1)
        guard components.count == 2 else {
            throw TransformationError.invalidModelArgument(
                "Expected format: ALIAS=path, got: \(argument)"
            )
        }

        let alias = String(components[0])
        let path = String(components[1])

        if verbose {
            print("Loading model '\(alias)' from: \(path)")
        }

        // Detect format and load
        let format = detectFormat(from: path)
        let resource = try await loadModel(from: path, format: format, verbose: verbose)

        models[alias] = resource
    }

    return models
}

// MARK: - Model Saving

/// Saves a resource to a file using the appropriate serialiser.
///
/// Serialises the provided resource to the specified file path using either
/// XMI or JSON format based on the format parameter. Provides verbose output
/// when requested, including object counts and file paths.
///
/// - Parameters:
///   - resource: The resource containing model data to save
///   - path: The destination file path where the model will be written
///   - format: The model format to use for serialisation (XMI or JSON)
///   - verbose: Whether to print verbose output during saving
/// - Throws: Serialisation errors if saving fails, or file system errors
func saveModel(_ resource: Resource, to path: String, format: ModelFormat, verbose: Bool)
    async throws
{
    let url = URL(fileURLWithPath: path)

    if verbose {
        let count = await resource.count()
        print("  Saving \(count) objects to \(format.description) file: \(path)")
    }

    let content: String
    switch format {
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
/// Processes an array of target model specifications in ALIAS=path format,
/// saving each corresponding resource from the targets dictionary to its
/// specified file path. Skips models that were not created during transformation.
///
/// - Parameters:
///   - targets: Ordered dictionary of target resources to save.
///   - paths: Array of ALIAS=path specifications for output files.
///   - verbose: Whether to print verbose output during saving.
/// - Throws: `TransformationError.invalidModelArgument` if path format is invalid.
func saveTargetModels(
    _ targets: OrderedDictionary<String, Resource>,
    paths: [String],
    verbose: Bool
) async throws {
    if verbose && !paths.isEmpty {
        print("Saving target models...")
    }

    for pathSpec in paths {
        let components = pathSpec.split(separator: "=", maxSplits: 1)
        guard components.count == 2 else {
            throw TransformationError.invalidModelArgument(
                "Expected format: ALIAS=path, got: \(pathSpec)"
            )
        }

        let alias = String(components[0])
        let path = String(components[1])

        guard let resource = targets[alias] else {
            if verbose {
                print("Warning: Target model '\(alias)' not found (may not have been created)")
            }
            continue
        }

        let format = detectFormat(from: path)
        try await saveModel(resource, to: path, format: format, verbose: verbose)
    }
}
