//
// SwiftEpsilon.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ModellingCommandLine

/// The main command-line interface for Swift Epsilon.
///
/// Swift Epsilon runs programs of the Epsilon model management languages against models: it
/// runs Epsilon Object Language (EOL) programs, validates models against Epsilon Validation
/// Language (EVL) constraints, transforms models with Epsilon Transformation Language (ETL)
/// rules, and generates text with Epsilon Generation Language (EGL) templates and EGX rules.
///
/// ## Available Commands
///
/// - **eol run**: run an EOL program
/// - **evl validate**: check models against EVL constraints and critiques
/// - **etl transform**: transform source models into target models
/// - **egl generate**: render a template, or run EGX rules that write files
///
/// ## Example Usage
///
/// ```bash
/// swift-epsilon eol run report.eol --model Bank=bank.xmi -m Bank.ecore
/// swift-epsilon evl validate rules.evl --model Bank=bank.xmi -m Bank.ecore
/// swift-epsilon etl transform bank2ledger.etl --model Bank=bank.xmi --target Ledger=ledger.xmi \
///     -m Bank.ecore -m Ledger.ecore
/// swift-epsilon egl generate accounts.egx --model Bank=bank.xmi -m Bank.ecore --output generated
/// ```
@main
struct SwiftEpsilonCommand: AsyncParsableCommand {
    /// The name, summary, version and command groups of the tool.
    static let configuration = CommandConfiguration(
        commandName: SwiftEpsilonVocabulary.toolName,
        abstract: "Epsilon model management languages command-line tool",
        discussion: """
            Copyright (c) 2026 Rene Hexel.
            All rights reserved.

            Swift Epsilon runs programs of the Epsilon languages against models in XMI, JSON \
            or UML format: Epsilon Object Language (EOL) programs, Epsilon Validation Language \
            (EVL) constraints, Epsilon Transformation Language (ETL) transformations, and \
            Epsilon Generation Language (EGL) templates with their EGX rules.
            """,
        version: SwiftEpsilonVocabulary.version,
        subcommands: [
            EOLCommand.self,
            EVLCommand.self,
            ETLCommand.self,
            EGLCommand.self,
        ]
    )

    /// A paragraph that describes how models are bound to names.
    static let modelDiscussion = """
        Each --\(SwiftEpsilonVocabulary.OptionName.model) name=file reads a model that \
        programs refer to by its name, as in Bank!Account.all, or by an alias given as \
        name,alias=file. An unqualified type name, such as Account, refers to the first \
        model whose metamodel defines it. Give the metamodels of the models with \
        --\(MetamodelOptions.optionName); each model is typed by those whose namespace \
        URIs its file uses, and a model file that is itself a metamodel, such as an Ecore \
        file, is typed by the Ecore metamodel. A model is only written if \
        --\(SwiftEpsilonVocabulary.OptionName.store) names it, once the run has succeeded.
        """

    /// A paragraph that describes the parameters of a program.
    static let parameterDiscussion = """
        Each --\(SwiftEpsilonVocabulary.OptionName.parameter) name=value becomes a global \
        variable of the program. --\(SwiftEpsilonVocabulary.OptionName.maximumCallDepth) \
        limits the depth of nested operation calls. With \
        --\(SwiftEpsilonVocabulary.OptionName.verbose), every step is reported on standard \
        error. The configuration file may name the encoding of the source files and the \
        container lookup scope of the models.
        """

    /// A paragraph that describes the exit statuses that every command shares.
    static let exitDiscussion = """
        The command exits with status 0 on success, with status 1 if a file cannot be read, \
        a source file has syntax errors or the program raises an error, and with status 64 \
        if the command line is not valid. Errors and warnings are written to standard error.
        """
}

/// The command group of the Epsilon Object Language.
struct EOLCommand: AsyncParsableCommand {
    /// The name, summary and subcommands of the group.
    static let configuration = CommandConfiguration(
        commandName: SwiftEpsilonVocabulary.Group.eol,
        abstract: "Run Epsilon Object Language (EOL) programs",
        subcommands: [EOLRunCommand.self]
    )
}

/// The command group of the Epsilon Validation Language.
struct EVLCommand: AsyncParsableCommand {
    /// The name, summary and subcommands of the group.
    static let configuration = CommandConfiguration(
        commandName: SwiftEpsilonVocabulary.Group.evl,
        abstract: "Validate models with Epsilon Validation Language (EVL) constraints",
        subcommands: [EVLValidateCommand.self]
    )
}

/// The command group of the Epsilon Transformation Language.
struct ETLCommand: AsyncParsableCommand {
    /// The name, summary and subcommands of the group.
    static let configuration = CommandConfiguration(
        commandName: SwiftEpsilonVocabulary.Group.etl,
        abstract: "Transform models with Epsilon Transformation Language (ETL) rules",
        subcommands: [ETLTransformCommand.self]
    )
}

/// The command group of the Epsilon Generation Language.
struct EGLCommand: AsyncParsableCommand {
    /// The name, summary and subcommands of the group.
    static let configuration = CommandConfiguration(
        commandName: SwiftEpsilonVocabulary.Group.egl,
        abstract: "Generate text with Epsilon Generation Language (EGL) templates and EGX rules",
        subcommands: [EGLGenerateCommand.self]
    )
}

/// The checks that every command makes of its models and parameters before it runs.
enum CommandLineCheck {
    /// Checks the model bindings and parameters of a command line.
    ///
    /// - Parameters:
    ///   - models: The options that bind models.
    ///   - execution: The options that control the run.
    ///   - targets: The values of `--target` (default: none).
    /// - Throws: A validation error that describes the first binding or parameter that is not valid.
    static func check(models: ModelOptions, execution: ExecutionOptions, targets: [String] = []) throws {
        do {
            _ = try ModelPlan(models: models.models, targets: targets, stores: models.stores)
            _ = try ParameterValue.parameters(from: execution.parameters)
        } catch {
            throw ValidationError(String(describing: error))
        }
    }
}
