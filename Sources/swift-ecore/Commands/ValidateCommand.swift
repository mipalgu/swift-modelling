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
import ModellingGenerators

/// Command for validating models and metamodels for correctness.
///
/// A metamodel is checked against the constraints of Ecore. A model is checked for references
/// into other documents that cannot be resolved; with one or more `--metamodel` files it is also
/// checked against those metamodels: every class and feature must be defined, values must fit
/// their types and bounds, no object may be an instance of an abstract class, and every OCL
/// invariant of the metamodel must hold. Bounds are checked as the Eclipse Modeling Framework
/// checks them, or with `--require-explicit-values` so that every required single-valued
/// feature needs a value that the model sets. Several files are validated one after the other
/// with the same metamodels and options, and the command fails if any of them is invalid.
struct ValidateCommand: AsyncParsableCommand {
    /// The name, summary and help of the `validate` subcommand.
    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Validate models and metamodels for correctness",
        discussion: """
            A metamodel (.ecore) is checked against the constraints of Ecore, such as \
            well-formed names, consistent bounds and opposites, and acyclic inheritance.

            A model (.xmi or .json) is checked for references into other documents that name \
            no object. With --\(MetamodelOptions.optionName), it is checked against the \
            metamodel: every class and feature must be defined by it, values must fit the \
            types and bounds of their features, references must lead to objects of the right \
            class, no object may be an instance of an abstract class, and every OCL invariant \
            of the metamodel must hold. \(MetamodelOptions.effect)

            Multiplicities follow the Eclipse Modeling Framework: a required single-valued \
            feature that the model leaves unset is accepted when it reads as a default, such as \
            the first literal of an enumeration, false, zero, or the default value of the \
            feature, but not when it has none, such as a string or a reference, or when it is \
            unsettable. --\(ValidateCommand.requireExplicitValuesOption) reports every required \
            single-valued feature that the model leaves unset, which suits models written by \
            hand or migrated from another format; models that the Eclipse Modeling Framework \
            saves omit default values and may then fail.

            Problems are reported as errors or warnings, followed by a summary. The command \
            fails if there is an error, or with --strict also if there is a warning. \
            --\(MTLSemanticsOptions.OptionName.strictAQL) is unrelated to --strict: it makes the \
            OCL invariants reject the expressions that Eclipse AQL rejects, such as a union of a \
            sequence with a set.

            Several files are validated one after the other with the same metamodels and \
            options. The findings of each file follow a line that names it and precede a line \
            with its result; a file that cannot be read counts as invalid. A final line counts \
            the valid and invalid files, and the command fails if any file is invalid. With \
            --format json, the report is an array with one report per file.
            """
    )

    /// Paths to the model or metamodel files to validate, in command line order.
    @Argument(help: "Paths to the model or metamodel files to validate")
    var inputPaths: [String]

    /// The metamodels that the model is validated against.
    @OptionGroup var metamodelOptions: MetamodelOptions

    /// Whether abstract classes are checked explicitly.
    @Flag(help: "List the abstract classes of a metamodel and whether concrete classes extend them, or check that no object of a model is an instance of one")
    var checkAbstractClasses = false

    /// Whether warnings count as errors.
    @Flag(help: "Fail on warnings as well as on errors")
    var strict = false

    /// The long name of the flag that makes required features need values of their own.
    static let requireExplicitValuesOption = "require-explicit-values"

    /// Whether every required single-valued feature needs a value that the model sets.
    @Flag(
        name: .customLong(ValidateCommand.requireExplicitValuesOption),
        help: "Report required features that the model leaves unset even when they read as a default, unlike the Eclipse Modeling Framework")
    var requireExplicitValues = false

    /// Whether OCL invariants reject the expressions that Eclipse AQL rejects.
    @Flag(
        name: .customLong(MTLSemanticsOptions.OptionName.strictAQL),
        help: MTLSemanticsOptions.strictAQLHelp)
    var strictAQL = false

    /// The format of the report.
    @Option(help: "Format of the report: \(ReportFormat.allCases.map(\.rawValue).joined(separator: " or "))")
    var format: ReportFormat = .text

    /// The file to write the report to.
    @Option(help: "File to write the report to, in the format of --format")
    var report: String?

    /// Enable verbose output.
    @Flag(name: .shortAndLong, help: "Enable verbose output, including every satisfied OCL invariant")
    var verbose: Bool = false

    /// Executes the validate command.
    ///
    /// Reads each document, checks it and reports what it found.
    ///
    /// - Throws: ``ValidationError`` if a single file cannot be read or does not pass
    ///   validation, ``BatchValidationError`` if one of several files is invalid, or the error
    ///   of a metamodel, the encoder or the file system.
    func run() async throws {
        guard inputPaths.count == 1, let inputPath = inputPaths.first else {
            return try await validateAll()
        }
        if verbose {
            print("Validating: \(inputPath)")
            for metamodel in metamodelOptions.metamodels {
                print("Using metamodel: \(metamodel)")
            }
        }
        let document = try await load(inputPath)
        if verbose { await describeContents(of: document) }
        let result = await check(document)

        let rendered = format == .json ? try result.json() : result.text(verbose: verbose)
        if let report {
            try rendered.write(to: URL(fileURLWithPath: report), atomically: true, encoding: .utf8)
            print(result.text(verbose: verbose), terminator: "")
            print("Validation report written: \(report)")
        } else {
            print(rendered, terminator: "")
        }
        guard result.valid else {
            StandardOutput.flush()
            throw ValidationError.failed(errors: result.errors, warnings: result.warnings, strict: strict)
        }
        if report != nil || format == .text {
            print("Validation completed successfully")
        }
    }

    /// Validates several files one after the other and reports on each and on all of them.
    ///
    /// A file that cannot be read counts as invalid; a metamodel that cannot be read stops the
    /// validation. On an interactive terminal, a progress bar shows how many files have been
    /// validated.
    ///
    /// - Throws: ``BatchValidationError`` if a file is invalid, or the error of a metamodel, the
    ///   encoder or the file system.
    private func validateAll() async throws {
        if verbose {
            for metamodel in metamodelOptions.metamodels { print("Using metamodel: \(metamodel)") }
        }
        let progress = GenerationProgressBar(verbose: false)
        let printsText = format == .text || report != nil
        var results: [ValidationReport] = []
        var text = ""
        for (index, path) in inputPaths.enumerated() {
            let header = BatchValidationVocabulary.fileHeading + path + "\n"
            if verbose {
                print(header, terminator: "")
            } else {
                progress.show(
                    GenerationProgressUpdate(message: BatchValidationVocabulary.progressMessage, completed: index, total: inputPaths.count))
            }
            let result: ValidationReport
            do {
                let document = try await load(path)
                if verbose { await describeContents(of: document) }
                result = await check(document)
            } catch let error as MetamodelRegistrationError {
                progress.finish()
                throw error
            } catch {
                result = ValidationReport(unreadable: path, error: error, metamodelPaths: metamodelOptions.metamodels, strict: strict)
            }
            progress.finish()
            results.append(result)
            let body = result.text(verbose: verbose) + BatchValidationVocabulary.result(of: result, path: path) + "\n"
            text += header + body
            if printsText { print(verbose ? body : header + body, terminator: "") }
        }
        let invalid = zip(inputPaths, results).filter { !$0.1.valid }.map(\.0)
        let summary = BatchValidationVocabulary.summary(files: results.count, invalid: invalid.count) + "\n"
        text += summary
        if printsText { print(summary, terminator: "") }
        if let report {
            let rendered = format == .json ? try ValidationReport.json(of: results) : text
            try rendered.write(to: URL(fileURLWithPath: report), atomically: true, encoding: .utf8)
            print("Validation report written: \(report)")
        } else if format == .json {
            print(try ValidationReport.json(of: results), terminator: "")
        }
        guard invalid.isEmpty else {
            StandardOutput.flush()
            throw BatchValidationError.invalidFiles(invalid, of: inputPaths.count)
        }
    }

    /// Checks a document with the options of the command.
    ///
    /// - Parameter document: The document.
    /// - Returns: The report of the document.
    private func check(_ document: ModelDocument) async -> ValidationReport {
        let options = ValidationOptions(
            strict: strict, checkAbstractClasses: checkAbstractClasses, strictAQL: strictAQL,
            requiresExplicitValues: requireExplicitValues)
        let outcome = await ModelChecker(document: document, options: options).check()
        withExtendedLifetime(document) {}
        return ValidationReport(
            document: document, metamodelPaths: metamodelOptions.metamodels, strict: strict,
            findings: outcome.findings, abstractClasses: outcome.abstractClasses, constraints: outcome.constraints)
    }

    /// Reads a document, reporting a file that cannot be parsed with its format.
    ///
    /// - Parameter inputPath: The path of the file.
    /// - Returns: The document.
    /// - Throws: ``ValidationError`` if the file does not exist, has an unknown format or cannot
    ///   be parsed, or the error of a metamodel.
    private func load(_ inputPath: String) async throws -> ModelDocument {
        do {
            return try await ModelDocument.load(
                path: inputPath, metamodelOptions: metamodelOptions, requiresMetamodel: metamodelOptions.isGiven,
                verbose: verbose)
        } catch DocumentError.fileNotFound(let path) {
            throw ValidationError.fileNotFound(path)
        } catch DocumentError.unsupportedFormat(let format) {
            throw ValidationError.unsupportedFormat(format)
        } catch let error as MetamodelRegistrationError {
            throw error
        } catch {
            let format = ModelFormat.detect(url: URL(fileURLWithPath: inputPath))?.rawValue.uppercased() ?? ""
            throw ValidationError.parsingFailed(format, error.localizedDescription)
        }
    }

    /// Prints the root objects or packages of a document.
    ///
    /// - Parameter document: The document.
    private func describeContents(of document: ModelDocument) async {
        if document.isMetamodel {
            print("Found \(document.packages.count) package(s)")
            for package in document.packages {
                print("   \(package.name) - \(package.eClassifiers.count) classifier(s)")
            }
            return
        }
        let objects = await ModelCatalogue.build(for: document)
        print("Found \(objects.roots.count) root object(s)")
        for (index, id) in objects.roots.enumerated() {
            if let entry = objects.entry(for: id) { print("   \(index + 1). \(objects.labelWithLocation(of: entry.object))") }
        }
    }
}
