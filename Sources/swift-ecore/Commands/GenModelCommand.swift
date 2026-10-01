//
// GenModelCommand.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Foundation
import ModellingGenerators

/// Command for creating a generator model from Ecore models.
///
/// The genmodel command imports one or more Ecore models into a `.genmodel` file with the
/// settings that the Eclipse Ecore importer gives a freshly imported model. An existing
/// generator model can be reloaded, which keeps its settings while the structure follows the
/// current Ecore models.
struct GenModelCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "genmodel",
        abstract: "Create a generator model (.genmodel) from Ecore models",
        discussion: """
            The generator model is written beside the first Ecore model, named after it, unless \
            --output says otherwise. The model project is the --model-project option if given; \
            otherwise it is the parent directory of an Ecore model that lives in a directory \
            named 'model' (the Eclipse layout <project>/model/<name>.ecore), and the name of the \
            root package in any other case.

            Use --prefix Name to set the prefix of the root package, or --prefix package=Name to \
            set the prefix of one package; the option can be repeated.

            With --reload, the settings of the existing generator model are kept. Options that are \
            given explicitly override the existing settings. Elements are matched by name.
            """
    )

    /// The Ecore models to import.
    @Argument(
        help: ArgumentHelp(
            "The Ecore models to import; the first one names the output", valueName: "model.ecore"),
        completion: .file(extensions: ["ecore"]))
    var models: [String]

    /// The base package of the root packages.
    @Option(help: "The base package of the root packages")
    var basePackage: String?

    /// The prefixes of packages, either `Name` or `package=Name`.
    @Option(help: "A package prefix: Name for the root package, or package=Name for one package")
    var prefix: [String] = []

    /// The name of the model project.
    @Option(help: "The name of the model project")
    var modelProject: String?

    /// The plug-in identifier of the model project.
    @Option(name: .customLong("model-plugin-id"), help: "The plug-in identifier of the model project")
    var modelPluginID: String?

    /// The source directory of the model project.
    @Option(help: "The source directory of the model project, such as /project/src")
    var modelDirectory: String?

    /// The copyright text.
    @Option(help: "The copyright text")
    var copyright: String?

    /// The compliance level of the generated code.
    @Option(help: "The compliance level of the generated code, such as 17.0")
    var jdkLevel: String?

    /// The existing generator model whose settings are kept.
    @Option(help: "An existing generator model whose settings are kept")
    var reload: String?

    /// The generator model to write.
    @Option(name: .shortAndLong, help: "The generator model to write")
    var output: String?

    /// Enable verbose output.
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    /// Executes the genmodel command.
    ///
    /// - Throws: ``GenerationError`` if a model is missing or unreadable, the import fails,
    ///   or the output cannot be written.
    @MainActor
    func run() async throws {
        let options = importOptions()
        let result: GenModelResult
        if verbose {
            result = try await GenerationPipeline.ecoreToGenModel(
                ecoreURLs: models.map { URL(fileURLWithPath: $0) }, options: options,
                progress: { print($0) })
        } else {
            result = try await GenerationPipeline.ecoreToGenModel(
                ecoreURLs: models.map { URL(fileURLWithPath: $0) }, options: options)
        }
        if verbose {
            print(
                "Packages: \(result.packageCount), classes: \(result.classCount), "
                    + "enumerations: \(result.enumCount), data types: \(result.dataTypeCount), "
                    + "features: \(result.featureCount), operations: \(result.operationCount)")
        }
        print("Wrote \(result.url.path)")
    }

    /// Converts the command line to import options.
    ///
    /// - Returns: The options that the command line describes.
    func importOptions() -> GenModelImportOptions {
        var options = GenModelImportOptions()
        options.basePackage = basePackage
        for entry in prefix {
            if let separator = entry.firstIndex(of: GenModelImportConstants.assignmentSeparatorCharacter) {
                let name = String(entry[..<separator])
                options.packagePrefixes[name] = String(entry[entry.index(after: separator)...])
            } else {
                options.prefix = entry
            }
        }
        options.modelProject = modelProject
        options.modelPluginID = modelPluginID
        options.modelDirectory = modelDirectory
        options.copyright = copyright
        options.complianceLevel = jdkLevel
        options.reload = reload.map { URL(fileURLWithPath: $0) }
        options.output = output.map { URL(fileURLWithPath: $0) }
        return options
    }
}
