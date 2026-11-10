//
// OutputEncodingVocabulary.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import ModellingCommandLine

/// The words with which the commands describe the encoding of the files they write.
///
/// Each phrase names the files to which `--output-encoding` applies in a command, for the
/// paragraph that `OutputEncodingOptions.discussion(writer:configurable:)` adds to its help,
/// except ``generated``, which is a sentence of its own.
enum OutputEncodingVocabulary {
    /// The files of a command that writes a report with `--output`.
    static let report = "the report that --output writes"

    /// The files of the validate command.
    static let validationReport = "the report that --report writes"

    /// The files of the convert command.
    static let converted = "the converted model or metamodel"

    /// The files of the create command.
    static let created = "the model that the command writes"

    /// The files of the genmodel command.
    static let genModel = "the generator model"

    /// The sentence on `--output-encoding` in the discussion of the generate command.
    ///
    /// The option describes the rules for XML, plain text and JSON in its own help, so the
    /// discussion only names the files that the encoding does not apply to.
    static let generated = "A template that names the charset of its file keeps it, whatever "
        + "--\(OutputEncodingOptions.optionName) says."
}

extension ReportFormat {
    /// The kind of document that a report in this format is, which decides how it is encoded.
    ///
    /// A JSON report is always written in UTF-8; a text report is plain text.
    var documentKind: TextDocumentKind { self == .json ? .json : .text }
}
