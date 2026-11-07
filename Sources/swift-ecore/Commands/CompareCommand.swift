//
// CompareCommand.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import Foundation
import ModellingCommandLine

/// Command for comparing two metamodels or two models.
///
/// The command reports what was added, removed or changed between an original and a revised
/// document, one line per difference, followed by a summary line. It can also count the
/// elements or objects of both documents, which shows at a glance whether a migration kept
/// every object.
struct CompareCommand: AsyncParsableCommand {
    /// The name, summary and help of the `compare` subcommand.
    static let configuration = CommandConfiguration(
        commandName: "compare",
        abstract: "Compare two metamodels or two models and report their differences",
        discussion: """
            Two metamodels (.ecore) are compared package by package. Packages, classifiers, \
            features, operations and literals are matched by name; a metamodel with a single \
            root package is compared with the single root package of the other, even if it was \
            renamed. Added and removed elements are reported, as are changes of namespaces, \
            kinds, abstract and interface flags, supertypes, feature types, multiplicities, \
            containment, opposites, flags, default values, literal values, operation \
            signatures and instance classes.

            Two models (.xmi or .json) are compared object by object. Objects are matched by \
            class and identity: the value of the identifying attribute of their class, else \
            the value that names them, else their location. Added and removed objects are \
            reported, and for matched objects every changed attribute value and \
            non-containment reference. Without a metamodel, an XMI model and a JSON model name \
            the classes of their objects differently, so a warning suggests \
            --\(MetamodelOptions.optionName) when two such models are compared.

            Each difference is a line that starts with + (added), - (removed) or ~ (changed). \
            --\(ComparisonVocabulary.summaryOption) shows counts instead: for models the \
            objects of each class in both files, for metamodels their packages, classes and \
            features. --\(MetamodelOptions.optionName) registers metamodels for both models, \
            so a model and its migrated counterpart can be compared with the metamodels of \
            both. \(MetamodelOptions.effect)

            The command succeeds whether or not the documents differ; with \
            --\(ComparisonVocabulary.exitCodeOption) it exits with status 1 if they do.
            """
    )

    /// The original document.
    @Argument(help: "The original metamodel or model (.ecore, .xmi or .json)")
    var originalPath: String

    /// The revised document.
    @Argument(help: "The revised metamodel or model, of the same kind as the original")
    var revisedPath: String

    /// The metamodels of the models.
    @OptionGroup var metamodelOptions: MetamodelOptions

    /// How the data types of a KM3 metamodel are read.
    @OptionGroup var km3Options: KM3Options

    /// Whether to show the counts only.
    @Flag(
        name: .customLong(ComparisonVocabulary.summaryOption),
        help: "Show the numbers of objects of each class, or of metamodel elements, instead of every difference")
    var summary = false

    /// The features and elements to leave out.
    @Option(
        name: .customLong(ComparisonVocabulary.ignoreOption),
        help: ArgumentHelp(
            "A feature, metamodel element or property to leave out, as a name or as Class.feature (can be specified multiple times)",
            valueName: "name"))
    var ignore: [String] = []

    /// The format of the report.
    @Option(help: "Format of the report: \(ReportFormat.allCases.map(\.rawValue).joined(separator: " or "))")
    var format: ReportFormat = .text

    /// The file to write the report to.
    @Option(name: .shortAndLong, help: "File to write the report to instead of standard output")
    var output: String?

    /// Whether differences make the command fail.
    @Flag(
        name: .customLong(ComparisonVocabulary.exitCodeOption),
        help: "Exit with status 1 if the documents differ")
    var exitCode = false

    /// Enable verbose output.
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose = false

    /// Executes the compare command.
    ///
    /// Reads both documents, compares them and writes the report as text or JSON.
    ///
    /// - Throws: ``ComparisonError`` if one document is a metamodel and the other a model,
    ///   ``DocumentError`` if a file cannot be read, `ExitCode` with status 1 if the documents
    ///   differ and `--exit-code` is given, or the error of the parser, the encoder or the
    ///   file system.
    func run() async throws {
        try checkKinds(ModelFormat.detect(url: URL(fileURLWithPath: originalPath)),
                       ModelFormat.detect(url: URL(fileURLWithPath: revisedPath)))
        if verbose {
            print("Original: \(originalPath)")
            print("Revised: \(revisedPath)")
        }
        let original = try await ModelDocument.load(path: originalPath, metamodelOptions: metamodelOptions, verbose: verbose,
            km3Options: km3Options.readOptions)
        let revised = try await ModelDocument.load(path: revisedPath, metamodelOptions: metamodelOptions, verbose: verbose,
            km3Options: km3Options.readOptions)
        try checkKinds(original.format, revised.format)
        let report = await compare(original, revised)
        withExtendedLifetime((original, revised)) {}

        let text = format == .json ? try report.json() : report.text()
        if let output {
            try text.write(to: URL(fileURLWithPath: output), atomically: true, encoding: .utf8)
            print(report.summary.text)
            print(ComparisonVocabulary.writtenConfirmation + output)
        } else {
            print(text, terminator: "")
        }
        if exitCode, report.hasDifferences {
            StandardOutput.flush()
            throw ExitCode(1)
        }
    }

    /// Compares two documents of the same kind.
    ///
    /// - Parameters:
    ///   - original: The original document.
    ///   - revised: The revised document.
    /// - Returns: The report.
    private func compare(_ original: ModelDocument, _ revised: ModelDocument) async -> ComparisonReport {
        let files = ComparedFiles(original: original.fileName, revised: revised.fileName)
        let filter = ComparisonFilter(ignore)
        guard !original.isMetamodel else {
            let differences = MetamodelComparer.compare(original: original.packages, revised: revised.packages, filter: filter)
            var report = ComparisonReport(files: files, kind: .metamodel, differences: differences, summaryOnly: summary)
            if summary {
                let before = MetamodelComparer.counts(of: original.packages)
                let after = MetamodelComparer.counts(of: revised.packages)
                report.elementCounts = ComparisonVocabulary.ElementCount.allCases.map { count in
                    CountComparison(name: count.rawValue, original: before[count] ?? 0, revised: after[count] ?? 0)
                }
            }
            return report
        }
        if let warning = Self.untypedFormatsWarning(original, revised) {
            FileHandle.standardError.write(Data((warning + "\n").utf8))
        }
        let comparer = ModelComparer(
            original: await ModelCatalogue.build(for: original), revised: await ModelCatalogue.build(for: revised),
            filter: filter)
        let outcome = await comparer.compare()
        if verbose { print("Matched \(outcome.matched) object(s)") }
        var report = ComparisonReport(
            files: files, kind: .model, differences: outcome.differences, objects: outcome.objects, summaryOnly: summary)
        if summary {
            let counts = comparer.classCounts()
            report.classCounts = counts
            report.totals = CountComparison(
                name: ComparisonVocabulary.totalName, original: comparer.original.entries.count,
                revised: comparer.revised.entries.count)
        }
        return report
    }

    /// The warning for two models in different formats whose classes no metamodel defines.
    ///
    /// - Parameters:
    ///   - original: The original model.
    ///   - revised: The revised model.
    /// - Returns: ``ComparisonVocabulary/untypedFormatsWarning(original:revised:)`` if the models
    ///   are in different formats, were read without a metamodel, and either of them has a class
    ///   that its reader made up; otherwise `nil`.
    static func untypedFormatsWarning(_ original: ModelDocument, _ revised: ModelDocument) -> String? {
        guard original.format != revised.format, !original.hasMetamodel, !revised.hasMetamodel,
            original.hasUntypedClasses || revised.hasUntypedClasses
        else { return nil }
        return ComparisonVocabulary.untypedFormatsWarning(
            original: "\(original.fileName) (\(original.formatName))",
            revised: "\(revised.fileName) (\(revised.formatName))")
    }

    /// Checks that two documents are of the same kind.
    ///
    /// - Parameters:
    ///   - original: The format of the original document, if known.
    ///   - revised: The format of the revised document, if known.
    /// - Throws: ``ComparisonError/mixedKinds(metamodel:model:)`` if exactly one of them is a metamodel.
    private func checkKinds(_ original: ModelFormat?, _ revised: ModelFormat?) throws {
        guard let original, let revised, (original == .ecore) != (revised == .ecore) else { return }
        let originalName = URL(fileURLWithPath: originalPath).lastPathComponent
        let revisedName = URL(fileURLWithPath: revisedPath).lastPathComponent
        throw original == .ecore
            ? ComparisonError.mixedKinds(metamodel: originalName, model: revisedName)
            : ComparisonError.mixedKinds(metamodel: revisedName, model: originalName)
    }
}
