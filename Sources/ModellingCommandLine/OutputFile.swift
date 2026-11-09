//
// OutputFile.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation

/// Writes the files that commands produce in the encoding that ``OutputEncodingOptions`` chooses.
///
/// In UTF-8, a file is written exactly as before. In another encoding, the text is encoded by
/// the rules of its kind (see `TextEncoding.encode(document:as:)`): an XML document names the
/// encoding in its declaration and refers to a character that the encoding cannot hold by
/// number, plain text cannot hold such a character, and JSON stays UTF-8, which a warning on
/// standard error then reports. A file is written only once its text has been encoded, so an
/// error leaves no file behind, and it replaces an existing file atomically where the platform
/// can.
public enum OutputFile {
    /// Writes text to a file in an encoding.
    ///
    /// - Parameters:
    ///   - text: The text of the file.
    ///   - path: The path of the file, as given on the command line.
    ///   - encoding: The encoding of the file.
    ///   - kind: The kind of document that the text is (default: plain text).
    ///   - warn: Receives the warning that JSON was written in UTF-8 instead of the encoding
    ///     asked for (default: standard error).
    /// - Throws: ``OutputFileError/unrepresentable(path:_:)`` if the encoding cannot hold a
    ///   character of plain text, or of XML markup, or the error of the file system.
    public static func write(
        _ text: String, to path: String, encoding: TextEncoding, kind: TextDocumentKind = .text,
        warn: (String) -> Void = StandardStreams.writeToStandardError
    ) throws {
        let url = URL(fileURLWithPath: path)
        if encoding == .utf8 {
            try text.write(to: url, atomically: FileURIHandler.writesAtomically, encoding: .utf8)
            return
        }
        let encoded: EncodedText
        do {
            encoded = try encoding.encode(document: text, as: kind)
        } catch {
            throw OutputFileError.unrepresentable(path: path, error)
        }
        if encoded.encoding != encoding { warn(jsonWarning(path: path, requested: encoding)) }
        try encoded.data.write(to: url, options: writingOptions)
    }

    /// Saves a model or metamodel in an encoding.
    ///
    /// The document is rendered and written as by `ModelIO.save(_:to:format:xmiOptions:registry:)`,
    /// which it calls unchanged for UTF-8, and otherwise by
    /// `ModelIO.save(_:to:format:xmiOptions:registry:encoding:diagnostics:)`.
    ///
    /// - Parameters:
    ///   - resource: The resource to save.
    ///   - url: The location of the file to write.
    ///   - format: The format of the document, or `nil` (the default) to take it from the file
    ///     extension.
    ///   - xmiOptions: The options with which XMI is written (default: `legacy`).
    ///   - registry: The registry that provides the format handlers (default: `shared`).
    ///   - encoding: The encoding of the file.
    ///   - warn: Receives the warning that JSON was written in UTF-8 instead of the encoding
    ///     asked for (default: standard error).
    /// - Returns: The warnings recorded while the resource was written.
    /// - Throws: ``OutputFileError/unrepresentable(path:_:)`` if the encoding cannot hold a
    ///   character where no character reference can stand for it, or the error of the
    ///   serialiser or the file system.
    @discardableResult
    public static func save(
        _ resource: Resource, to url: URL, format: ModelFormat? = nil,
        xmiOptions: XMISerializationOptions = .legacy, registry: ModelFormatRegistry = .shared,
        encoding: TextEncoding, warn: (String) -> Void = StandardStreams.writeToStandardError
    ) async throws -> ConversionDiagnostics {
        if encoding == .utf8 {
            return try await ModelIO.save(resource, to: url, format: format, xmiOptions: xmiOptions, registry: registry)
        }
        var diagnostics = ConversionDiagnostics()
        let used: TextEncoding
        do {
            used = try await ModelIO.save(
                resource, to: url, format: format, xmiOptions: xmiOptions, registry: registry, encoding: encoding,
                diagnostics: &diagnostics)
        } catch let error as TextEncodingError {
            throw OutputFileError.unrepresentable(path: url.path, error)
        }
        if used != encoding { warn(jsonWarning(path: url.path, requested: encoding)) }
        return diagnostics
    }

    /// The warning that a JSON file was written in UTF-8 instead of the encoding asked for.
    ///
    /// - Parameters:
    ///   - path: The path of the file.
    ///   - requested: The encoding asked for.
    /// - Returns: A line for standard error, ending in a line break.
    public static func jsonWarning(path: String, requested: TextEncoding) -> String {
        ConversionWarningReport.warningPrefix + path + ": JSON is always written in "
            + "\(TextEncoding.utf8.name), not \(requested.name), so --\(OutputEncodingOptions.optionName) "
            + "does not apply to it\n"
    }

    /// The options with which data replaces a file on this platform.
    private static var writingOptions: Data.WritingOptions {
        FileURIHandler.writesAtomically ? .atomic : []
    }
}

/// An error that prevents a command from writing a file.
public enum OutputFileError: Error, Sendable, Hashable, CustomStringConvertible, LocalizedError {
    /// The encoding of the file cannot hold a character of its text.
    ///
    /// - Parameters:
    ///   - path: The path of the file, as given on the command line.
    ///   - error: The character, its line and column, and the encoding.
    case unrepresentable(path: String, TextEncodingError)

    /// A message that names the file, the character, its line and column, and the encoding.
    public var description: String {
        switch self {
        case .unrepresentable(let path, let error):
            return "Cannot write \(path): \(error.description)"
        }
    }

    /// The ``description`` of the error.
    public var errorDescription: String? { description }
}
