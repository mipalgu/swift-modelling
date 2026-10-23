//
// ValidateCommand.swift
// ECore
//
//  Created by Rene Hexel on 3/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import Foundation
import ModellingCommandLine

/// Command for validating models and metamodels for correctness.
///
/// The validate command checks the structural integrity and compliance of model files,
/// supporting XMI, JSON, and Ecore formats. With one or more `--metamodel` files, a model is
/// read with the classes and data types of those metamodels, and a JSON model whose classes
/// they do not define is rejected.
struct ValidateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Validate models and metamodels for correctness"
    )

    /// Path to the model file to validate.
    @Argument(help: "Path to the model file to validate")
    var inputPath: String

    /// The metamodels that the model is validated against.
    @OptionGroup var metamodelOptions: MetamodelOptions

    /// Enable verbose output.
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    /// Executes the validate command.
    ///
    /// Validates the specified model file and reports any errors or warnings found.
    ///
    /// - Throws: `ValidationError` if validation fails.
    func run() async throws {
        if verbose {
            print("Validating: \(inputPath)")
            for metamodel in metamodelOptions.metamodels {
                print("Using metamodel: \(metamodel)")
            }
        }

        let inputURL = URL(fileURLWithPath: inputPath)

        guard FileManager.default.fileExists(atPath: inputPath) else {
            throw ValidationError.fileNotFound(inputPath)
        }

        let resourceSet = try await metamodelOptions.resourceSet(verbose: verbose)

        // Determine file type
        let fileExtension = inputURL.pathExtension.lowercased()

        switch ModelFormat.detect(url: inputURL) {
        case .xmi:
            try await validateXMI(at: inputURL, resourceSet: resourceSet)
        case .json:
            try await validateJSON(at: inputURL, resourceSet: resourceSet)
        case .ecore:
            try await validateEcore(at: inputURL, resourceSet: resourceSet)
        case nil:
            throw ValidationError.unsupportedFormat(fileExtension)
        }
        withExtendedLifetime(resourceSet) {}

        print("Validation completed successfully")
    }

    /// Validates an XMI file.
    ///
    /// - Parameters:
    ///   - url: The URL of the XMI file to validate.
    ///   - resourceSet: The resource set with the registered metamodels, if any were given.
    /// - Throws: `ValidationError.parsingFailed` if parsing fails.
    private func validateXMI(at url: URL, resourceSet: ResourceSet?) async throws {
        if verbose { print("Validating XMI file...") }

        do {
            let parsedResource = try await load(url, format: .xmi, resourceSet: resourceSet)
            let objects = await parsedResource.getRootObjects()

            if verbose {
                print("Found \(objects.count) root object(s)")
                for (index, obj) in objects.enumerated() {
                    if let eObj = obj as? DynamicEObject {
                        print("   \(index + 1). \(eObj.eClass.name) (id: \(eObj.id))")
                    }
                }
            }
        } catch {
            throw ValidationError.parsingFailed("XMI", error.localizedDescription)
        }
    }

    /// Validates a JSON file.
    ///
    /// With registered metamodels, the classes of the document must be classes of those
    /// metamodels.
    ///
    /// - Parameters:
    ///   - url: The URL of the JSON file to validate.
    ///   - resourceSet: The resource set with the registered metamodels, if any were given.
    /// - Throws: `ValidationError.parsingFailed` if parsing fails.
    private func validateJSON(at url: URL, resourceSet: ResourceSet?) async throws {
        if verbose { print("Validating JSON file...") }

        do {
            let parsedResource = try await load(url, format: .json, resourceSet: resourceSet)
            let objects = await parsedResource.getRootObjects()

            if verbose {
                print("Found \(objects.count) root object(s)")
                for (index, obj) in objects.enumerated() {
                    if let eObj = obj as? DynamicEObject {
                        print("   \(index + 1). \(eObj.eClass.name) (id: \(eObj.id))")
                    }
                }
            }
        } catch {
            throw ValidationError.parsingFailed("JSON", error.localizedDescription)
        }
    }

    /// Validates an Ecore metamodel file.
    ///
    /// - Parameters:
    ///   - url: The URL of the Ecore file to validate.
    ///   - resourceSet: The resource set with the registered metamodels that the metamodel may
    ///     refer to, if any were given.
    /// - Throws: `ValidationError.parsingFailed` if parsing fails.
    private func validateEcore(at url: URL, resourceSet: ResourceSet?) async throws {
        if verbose { print("Validating Ecore metamodel...") }

        do {
            let parsedResource = try await load(url, format: .xmi, resourceSet: resourceSet)
            let packages = await parsedResource.getRootObjects().compactMap { $0 as? EPackage }

            if verbose {
                print("Found \(packages.count) package(s)")
                for package in packages {
                    print(
                        "   \(package.name) - \(package.eClassifiers.count) classifier(s)"
                    )
                }
            }
        } catch {
            throw ValidationError.parsingFailed("Ecore", error.localizedDescription)
        }
    }

    /// Reads a document in a given format.
    ///
    /// With registered metamodels, the classes of a JSON document must be classes of those
    /// metamodels. An Ecore document is read as XMI.
    ///
    /// - Parameters:
    ///   - url: The URL of the document.
    ///   - format: The format in which the document is read, ``ECore/ModelFormat/xmi`` or
    ///     ``ECore/ModelFormat/json``.
    ///   - resourceSet: The resource set with the registered metamodels, if any were given.
    /// - Returns: The resource that holds the objects of the document.
    /// - Throws: The error of the file system or of the parser.
    private func load(_ url: URL, format: ModelFormat, resourceSet: ResourceSet?) async throws -> Resource {
        let options = ModelIO.LoadOptions(requiresMetamodel: resourceSet != nil)
        return try await ModelIO.load(
            url: url, format: format, resourceSet: resourceSet ?? ResourceSet(), options: options
        ).resource
    }
}
