//
// InspectCommand.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import Foundation
import ModellingCommandLine

/// Command for inspecting the structure of a metamodel or a model.
///
/// For a metamodel, the command lists its packages with their classes, enumerations and data
/// types; in full detail every class with its attributes, references, operations and invariants.
/// For a model, it counts the objects of each class; in full detail it shows every object with
/// its values, nested as the objects contain each other.
struct InspectCommand: AsyncParsableCommand {
    /// The name, summary and help of the `inspect` subcommand.
    static let configuration = CommandConfiguration(
        commandName: "inspect",
        abstract: "Show the structure of a metamodel or a model",
        discussion: """
            A metamodel (.ecore) is shown package by package. The summary lists the classes, \
            enumerations and data types; --detail full adds the attributes and references of \
            every class with their types, multiplicities, containment and opposites, its \
            operations and OCL invariants, and the literals of every enumeration.

            A model (.xmi or .json) is shown with the number of objects of each class; --detail \
            full adds every object with its values, nested as the objects contain each other.

            --show-supertypes adds the inheritance: all supertypes, subclasses and inherited \
            features of every class, and the class hierarchy. --show-references adds the \
            references of every class and the reference graph, or for a model every reference \
            between its objects. --show-attributes lists the attributes of every class also in a \
            summary.

            --\(MetamodelOptions.optionName) names an Ecore metamodel of the model. \
            \(MetamodelOptions.effect)
            """
    )

    /// The file to inspect.
    @Argument(help: "Metamodel or model file to inspect (.ecore, .xmi or .json)")
    var inputPath: String

    /// How much detail to show.
    @Option(help: "How much to show: \(InspectionDetail.allCases.map(\.rawValue).joined(separator: " or "))")
    var detail: InspectionDetail = .summary

    /// Whether to show the inheritance.
    @Flag(help: "Show supertypes, subclasses, inherited features and the class hierarchy")
    var showSupertypes = false

    /// Whether to show the references.
    @Flag(help: "Show the references of every class and the reference graph")
    var showReferences = false

    /// Whether to show the attributes in a summary.
    @Flag(help: "Show the attributes of every class, also in a summary")
    var showAttributes = false

    /// The format of the report.
    @Option(help: "Format of the report: \(ReportFormat.allCases.map(\.rawValue).joined(separator: " or "))")
    var format: ReportFormat = .text

    /// The file to write the report to.
    @Option(name: .shortAndLong, help: "File to write the report to instead of standard output")
    var output: String?

    /// The metamodels of the model.
    @OptionGroup var metamodelOptions: MetamodelOptions

    /// Enable verbose output.
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose = false

    /// Executes the inspect command.
    ///
    /// Reads the document, builds its report and writes it as text or JSON.
    ///
    /// - Throws: ``DocumentError`` if the file cannot be read, or the error of the parser, the
    ///   encoder or the file system.
    func run() async throws {
        if verbose { print("Inspecting: \(inputPath)") }
        let document = try await ModelDocument.load(path: inputPath, metamodelOptions: metamodelOptions, verbose: verbose)
        let options = InspectionOptions(
            detail: detail, showAttributes: showAttributes, showReferences: showReferences, showSupertypes: showSupertypes)
        let report = await Inspector.inspect(document, options: options)
        withExtendedLifetime(document) {}
        let text = format == .json ? try report.json() : InspectionTextRenderer.render(report)
        if let output {
            try text.write(to: URL(fileURLWithPath: output), atomically: true, encoding: .utf8)
            print("Inspection written: \(output)")
        } else {
            print(text, terminator: "")
        }
    }
}
