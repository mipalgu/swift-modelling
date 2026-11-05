//
// BatchValidation.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation

extension ValidationReport {
    /// Creates the report of a file that could not be read.
    ///
    /// The report holds one error with the code ``ValidationCode/unreadable`` and the message of
    /// the error, so the file counts as invalid.
    ///
    /// - Parameters:
    ///   - path: The path of the file as given on the command line.
    ///   - error: Why the file could not be read.
    ///   - metamodelPaths: The metamodel files given on the command line.
    ///   - strict: Whether warnings count as errors.
    init(unreadable path: String, error: any Error, metamodelPaths: [String], strict: Bool) {
        let url = URL(fileURLWithPath: path)
        let format = ModelFormat.detect(url: url)
        file = url.lastPathComponent
        kind = format == .ecore ? .metamodel : .model
        self.format = format.map { $0 == .ecore ? ModelVocabulary.ecoreFormatName : $0.rawValue.uppercased() }
            ?? url.pathExtension.uppercased()
        metamodels = metamodelPaths
        self.strict = strict
        findings = [
            ValidationFinding(severity: .error, code: ValidationCode.unreadable, message: error.localizedDescription)
        ]
        errors = 1
        warnings = 0
        valid = false
        abstractClasses = nil
        constraints = nil
    }

    /// The reports of several files as one JSON array, with sorted keys and indentation.
    ///
    /// - Parameter reports: The reports, in the order of the files.
    /// - Returns: The JSON text, ending with a line break.
    /// - Throws: The error of the encoder.
    static func json(of reports: [ValidationReport]) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(reports), as: UTF8.self) + "\n"
    }
}

extension BatchValidationVocabulary {
    /// The line with the result of one file.
    ///
    /// - Parameters:
    ///   - report: The report of the file.
    ///   - path: The path of the file as given on the command line.
    /// - Returns: For example `model.xmi: valid` or `model.xmi: invalid (2 error(s), 0 warning(s))`.
    static func result(of report: ValidationReport, path: String) -> String {
        guard !report.valid else { return "\(path): \(valid)" }
        return "\(path): \(invalid) (\(report.errors) error(s), \(report.warnings) warning(s))"
    }

    /// The line that counts the valid and invalid files.
    ///
    /// - Parameters:
    ///   - files: The number of files validated.
    ///   - invalid: The number of invalid files.
    /// - Returns: For example `Validated 3 files: 2 valid, 1 invalid`.
    static func summary(files: Int, invalid: Int) -> String {
        "Validated \(files) files: \(files - invalid) \(valid), \(invalid) \(self.invalid)"
    }
}
