//
// ModelFileFormat.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation

/// Chooses the format in which the tools read and write a model instance file.
///
/// A format given on the command line, such as with `--input-format json`, takes precedence
/// over the extension of the file. A model instance is held as XMI or JSON: a file with the
/// extension `json` is JSON, and a file with the extension `xmi` or `ecore` is XMI. A file
/// with any other extension, or none, is written as XMI and read in the format of its
/// contents (see ``detectedInstanceFormat(of:explicit:)``).
public enum ModelFileFormat {
    /// The format in which a model instance file is written.
    ///
    /// The contents of an existing file are not examined, so a file is always written in
    /// the same format, whatever it held before.
    ///
    /// - Parameters:
    ///   - url: The location of the file.
    ///   - explicit: The name of a format given on the command line, if any, such as `json`.
    /// - Returns: ``ECore/ModelFormat/json`` if the explicit format or, without one, the file
    ///   extension names JSON, and ``ECore/ModelFormat/xmi`` otherwise.
    public static func instanceFormat(of url: URL, explicit: String? = nil) -> ModelFormat {
        let named = explicit.map { ModelFormat(fileExtension: $0) } ?? ModelFormat.detect(url: url)
        return named == .json ? .json : .xmi
    }

    /// The format in which a model instance file is read, from its contents if need be.
    ///
    /// A format given on the command line, and then the extension of the file, decide as
    /// ``instanceFormat(of:explicit:)`` does. Without either, the beginning of the file
    /// decides: XML, including an Ecore document, is XMI, and JSON is JSON, so a model that
    /// was saved as `shop.model` is read as before. A file that cannot be read is left to the
    /// reader, as XMI, so that the reader reports why.
    ///
    /// - Parameters:
    ///   - url: The location of the file.
    ///   - explicit: The name of a format given on the command line, if any, such as `json`.
    /// - Returns: ``ECore/ModelFormat/json`` or ``ECore/ModelFormat/xmi``.
    /// - Throws: ``ECore/ModelFormatError/undetectableFormat(_:)`` with the path of the file
    ///   if its extension names no format and its contents are neither XML nor JSON; the
    ///   error lists the supported formats.
    public static func detectedInstanceFormat(of url: URL, explicit: String? = nil) throws -> ModelFormat {
        if let explicit {
            return ModelFormat(fileExtension: explicit) == .json ? .json : .xmi
        }
        if let named = ModelFormat.detect(url: url) {
            return named == .json ? .json : .xmi
        }
        guard let contents = try? ModelFormat.detect(contentsOf: url) else {
            guard FileManager.default.isReadableFile(atPath: url.path) else { return .xmi }
            throw ModelFormatError.undetectableFormat(url.relativePath)
        }
        return contents == .json ? .json : .xmi
    }
}
