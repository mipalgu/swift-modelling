//
// RunConfiguration.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingCommandLine

/// Everything that a command line says about one run, resolved and checked.
///
/// The configuration combines the models, metamodels, parameters and settings of a command
/// line, including those that the configuration file contributes, so that the run itself does
/// not consult the options again.
struct RunConfiguration: Sendable {
    /// The models that the run binds.
    var plan: ModelPlan

    /// The paths of the metamodels, in command line order.
    var metamodels: [String] = []

    /// The options with which metamodels are read.
    var metamodelLoadOptions = EcoreLoadOptions()

    /// The parameters of the program by name.
    var parameters: [String: ParameterValue] = [:]

    /// The maximum depth of nested operation calls.
    var maximumCallDepth = SwiftEpsilonVocabulary.defaultMaximumCallDepth

    /// The character encoding of source files, or `nil` to read UTF-8 and fall back to ISO-8859-1.
    var encoding: TextEncoding?

    /// The settings of the run, which choose the container lookup scope of the models.
    var settings = SemanticsSettings()

    /// The options with which stored XMI models are written.
    var xmiOptions = XMISerializationOptions.legacy

    /// Whether each step is reported on standard error.
    var verbose = false

    /// Creates a configuration from models alone, with the default settings.
    ///
    /// - Parameter plan: The models that the run binds.
    init(plan: ModelPlan) {
        self.plan = plan
    }

    /// Resolves a configuration from the options of a command line.
    ///
    /// - Parameters:
    ///   - models: The options that bind models and name their metamodels.
    ///   - execution: The options that control how the program runs.
    ///   - targets: The values of `--target` (default: none).
    ///   - environment: The environment variables from which the preset may come.
    ///   - currentDirectory: The directory from which the configuration file is found.
    /// - Throws: The errors of reading the models and parameters, and those of reading the
    ///   configuration file.
    init(
        models: ModelOptions, execution: ExecutionOptions, targets: [String] = [],
        environment: [String: String] = ProcessInfo.processInfo.environment,
        currentDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    ) throws {
        plan = try ModelPlan(models: models.models, targets: targets, stores: models.stores)
        settings = try execution.semanticsOptions.settings(environment: environment, currentDirectory: currentDirectory)
        metamodels = models.metamodelOptions.metamodels
        metamodelLoadOptions = models.formatOptions.ecoreLoadOptions(settings: settings)
        parameters = try ParameterValue.parameters(from: execution.parameters)
        maximumCallDepth = execution.maximumCallDepth
        encoding = execution.encodingOptions.encoding(settings: settings)
        xmiOptions = models.referenceStyleOptions.serializationOptions
        verbose = execution.verbose
    }
}
