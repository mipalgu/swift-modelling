//
// TextDocumentLoading.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation

/// Loads model documents, reading those in text formats in the character encoding of a run.
///
/// A document in a text format, such as a multi-level model in the MetaDepth notation
/// (`.mdepth`), is read in the encoding given with `--encoding` or the `encoding` key of the
/// configuration file (see ``SourceEncodingOptions``). Without one, it is read as UTF-8 and, if
/// it is not valid UTF-8, as ISO-8859-1 with a warning on standard error that names the file and
/// the place of the first byte that is not UTF-8, as a source file is. With an encoding, a
/// document that is not valid in it is an error that names the file and the encoding. XMI and
/// JSON documents are decoded as their own rules prescribe, so the encoding does not change how
/// they are read and they never cause a warning.
public enum TextDocumentLoading {
    /// The warnings of reading a document as ISO-8859-1 because it is not valid UTF-8.
    ///
    /// - Parameter diagnostics: The diagnostics of loading a document.
    /// - Returns: The decoding warnings among them, in order.
    public static func decodingWarnings(in diagnostics: [SourceDiagnostic]) -> [SourceDiagnostic] {
        diagnostics.filter { $0.code == TextDecodingDiagnostic.decodedAsISOLatin1 }
    }

    /// Loads a model document in a character encoding.
    ///
    /// The document is loaded as `ModelIO.load(url:format:resourceSet:options:)` loads it, with
    /// the encoding as the `textEncoding` of the options. The warnings of reading it as
    /// ISO-8859-1, whether its reader reports them with the diagnostics of the load or of the
    /// resource, are written once with ``FileDiagnosticReport`` through `diagnosticOutput`; its
    /// other diagnostics are left to the caller.
    ///
    /// - Parameters:
    ///   - isolation: The actor the load runs on, by default that of the caller.
    ///   - url: The location of the document.
    ///   - path: The path of the document as the user named it, or `nil` for the relative path
    ///     of the URL.
    ///   - format: The format in which the document is read, or `nil` (the default) for the
    ///     format that its extension or its contents name.
    ///   - resourceSet: The resource set that receives the document.
    ///   - options: The options of the load; their `textEncoding` is replaced by `encoding`.
    ///   - encoding: The encoding of a document in a text format, or `nil` to read UTF-8 with
    ///     a fallback to ISO-8859-1.
    ///   - diagnosticOutput: The writer that receives the report of the decoding warnings, or
    ///     `nil` (the default) for standard error.
    /// - Returns: The loaded document.
    /// - Throws: ``SourceFileError/malformed(path:encoding:)`` if the document is not valid in
    ///   the encoding, and the errors of the reader.
    public static func load(
        isolation: isolated (any Actor)? = #isolation,
        url: URL, path: String? = nil, format: ModelFormat? = nil, resourceSet: ResourceSet,
        options: ModelIO.LoadOptions = ModelIO.LoadOptions(), encoding: TextEncoding?,
        diagnosticOutput: ((String) -> Void)? = nil
    ) async throws -> ModelIO.Loaded {
        let name = path ?? url.relativePath
        var options = options
        options.textEncoding = encoding
        let loaded: ModelIO.Loaded
        do {
            loaded = try await ModelIO.load(url: url, format: format, resourceSet: resourceSet, options: options)
        } catch TextDecodingError.malformed(let malformed) {
            throw SourceFileError.malformed(path: name, encoding: malformed)
        }
        let reported = loaded.diagnostics.warnings.compactMap { warning -> SourceDiagnostic? in
            guard case .sourceDiagnostic(let diagnostic) = warning.kind else { return nil }
            return diagnostic
        }
        FileDiagnosticReport.write(
            decodingWarnings(in: reported + (await loaded.resource.loadDiagnostics)), file: name,
            to: diagnosticOutput ?? FileDiagnosticReport.writeToStandardError)
        return loaded
    }
}
