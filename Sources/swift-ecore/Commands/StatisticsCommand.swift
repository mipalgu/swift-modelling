//
// StatisticsCommand.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import Foundation
import ModellingCommandLine

/// Command for measuring a metamodel or a model.
///
/// For a metamodel, the command counts its packages, classifiers, features, operations and
/// invariants, and measures its inheritance and the number of features per class. For a model,
/// it counts the objects of each class, the attribute values, the containment links and the
/// cross-references, and measures how deeply the objects are nested.
struct StatisticsCommand: AsyncParsableCommand {
    /// The name, summary and help of the `statistics` subcommand.
    static let configuration = CommandConfiguration(
        commandName: "statistics",
        abstract: "Measure the size and shape of a metamodel or a model",
        discussion: """
            A metamodel (.ecore) is measured by the numbers of its packages, classes, abstract \
            classes, interfaces, enumerations, literals, data types, attributes, references, \
            containment references, bidirectional reference pairs, operations and OCL \
            invariants, the deepest inheritance and the largest number of direct subclasses, \
            and the number of features per class, declared and with the inherited ones. The \
            classes are listed by their number of features, the most first.

            A model (.xmi or .json) is measured by the numbers of its objects, root objects and \
            instantiated classes, the objects of each class, the deepest containment, and the \
            numbers of attribute values, containment links and cross-references, including \
            those into other documents and those that cannot be resolved. With \
            --\(MetamodelOptions.optionName), the concrete classes of the metamodel that have \
            no objects are listed too. \(MetamodelOptions.effect)

            \(SourceEncodingOptions.discussion(reader: EncodingVocabulary.encodedDocuments))

            \(OutputEncodingOptions.discussion(writer: OutputEncodingVocabulary.report))

            \(ConfigurationVocabulary.writingDiscussion)
            """
    )

    /// The file to measure.
    @Argument(help: "Metamodel or model file to measure (.ecore, .xmi or .json)")
    var inputPath: String

    /// The metamodels of the model.
    @OptionGroup var metamodelOptions: MetamodelOptions

    /// How metamodels in KM3 and in grammar formats are read.
    @OptionGroup var formatOptions: MetamodelFormatOptions

    /// The character encoding of the documents in text formats.
    @OptionGroup var encodingOptions: SourceEncodingOptions

    /// The configuration file whose keys give the options that the command line leaves open.
    @OptionGroup var configurationOptions: ConfigurationFileOptions

    /// The character encoding of the files that the command writes.
    @OptionGroup var outputEncodingOptions: OutputEncodingOptions

    /// The options with which the documents and metamodels are read.
    ///
    /// Each option is the one given on the command line, else the value of its key in the
    /// configuration file, else its default.
    ///
    /// - Returns: The options of the readers, in the encoding of the run.
    /// - Throws: ``ModellingConfigurationError`` if the configuration file cannot be read or is
    ///   not valid.
    private func configuredLoadOptions() throws -> EcoreLoadOptions {
        formatOptions.ecoreLoadOptions(settings: try configurationOptions.settings(), encodingOptions: encodingOptions)
    }

    /// The Complete OCL documents that constrain the metamodels.
    @OptionGroup var completeOCLOptions: CompleteOCLOptions

    /// The format of the report.
    @Option(help: "Format of the report: \(ReportFormat.allCases.map(\.rawValue).joined(separator: " or "))")
    var format: ReportFormat = .text

    /// The file to write the report to.
    @Option(name: .shortAndLong, help: "File to write the report to instead of standard output")
    var output: String?

    /// Enable verbose output.
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose = false

    /// Executes the statistics command.
    ///
    /// Reads the document, measures it and writes the report as text or JSON.
    ///
    /// - Throws: ``DocumentError`` if the file cannot be read, or the error of the parser, the
    ///   encoder or the file system.
    ///   Also ``ModellingConfigurationError`` if the configuration file cannot be read or is not valid,
    ///   and `OutputFileError` if the encoding of the report cannot hold one of its characters.
    func run() async throws {
        let loadOptions = try configuredLoadOptions()
        let oclDocuments = completeOCLOptions.documents(settings: try configurationOptions.settings())
        if verbose { print("Measuring: \(inputPath)") }
        let document = try await ModelDocument.load(path: inputPath, metamodelOptions: metamodelOptions, verbose: verbose,
            ecoreLoadOptions: loadOptions, completeOCL: oclDocuments)
        let report = await Statistician.measure(document)
        withExtendedLifetime(document) {}
        let text = format == .json ? try report.json() : report.text()
        if let output {
            let encoding = outputEncodingOptions.encoding(settings: try configurationOptions.settings())
            try OutputFile.write(text, to: output, encoding: encoding, kind: format.documentKind)
            print(StatisticsVocabulary.writtenConfirmation + output)
        } else {
            print(text, terminator: "")
        }
    }
}
