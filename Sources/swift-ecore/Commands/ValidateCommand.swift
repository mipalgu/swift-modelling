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

/// Command for validating models and metamodels for correctness.
///
/// The validate command checks the structural integrity and compliance of model files,
/// supporting XMI, JSON, and Ecore formats.
struct ValidateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Validate models and metamodels for correctness"
    )

    /// Path to the model file to validate.
    @Argument(help: "Path to the model file to validate")
    var inputPath: String

    /// Optional metamodel file for validation.
    @Option(name: .shortAndLong, help: "Metamodel file for validation (optional)")
    var metamodel: String?

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
            if let metamodel = metamodel {
                print("Using metamodel: \(metamodel)")
            }
        }

        let inputURL = URL(fileURLWithPath: inputPath)

        guard FileManager.default.fileExists(atPath: inputPath) else {
            throw ValidationError.fileNotFound(inputPath)
        }

        // Determine file type
        let fileExtension = inputURL.pathExtension.lowercased()

        switch fileExtension {
        case "xmi":
            try await validateXMI(at: inputURL)
        case "json":
            try await validateJSON(at: inputURL)
        case "ecore":
            try await validateEcore(at: inputURL)
        default:
            throw ValidationError.unsupportedFormat(fileExtension)
        }

        print("Validation completed successfully")
    }

    /// Validates an XMI file.
    ///
    /// - Parameter url: The URL of the XMI file to validate.
    /// - Throws: `ValidationError.parsingFailed` if parsing fails.
    private func validateXMI(at url: URL) async throws {
        if verbose { print("Validating XMI file...") }

        _ = Resource(uri: url.absoluteString)
        let parser = XMIParser()

        do {
            let parsedResource = try await parser.parse(url)
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
    /// - Parameter url: The URL of the JSON file to validate.
    /// - Throws: `ValidationError.parsingFailed` if parsing fails.
    private func validateJSON(at url: URL) async throws {
        if verbose { print("Validating JSON file...") }

        _ = Resource(uri: url.absoluteString)
        let parser = JSONParser()

        do {
            let parsedResource = try await parser.parse(url)
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
    /// - Parameter url: The URL of the Ecore file to validate.
    /// - Throws: `ValidationError.parsingFailed` if parsing fails.
    private func validateEcore(at url: URL) async throws {
        if verbose { print("Validating Ecore metamodel...") }

        _ = Resource(uri: url.absoluteString)
        let parser = XMIParser()

        do {
            let parsedResource = try await parser.parse(url)
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
}
