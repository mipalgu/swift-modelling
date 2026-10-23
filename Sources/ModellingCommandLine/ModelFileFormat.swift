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
/// over the extension of the file. A model instance is held as XMI or JSON: an Ecore file is
/// read and written as XMI, and so is a file whose format is unknown.
public enum ModelFileFormat {
    /// The format in which a model instance file is read or written.
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
}
