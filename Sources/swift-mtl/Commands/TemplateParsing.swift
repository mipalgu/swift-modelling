//
// TemplateParsing.swift
// swift-mtl
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import MTL
import ModellingCommandLine

extension MTLParser {
    /// Parses a template file with the modules it imports and extends, writing the warnings of
    /// reading them to standard error.
    ///
    /// A file that was read as ISO-8859-1 because it is not valid UTF-8 is reported with
    /// ``ModellingCommandLine/FileDiagnosticReport``, whether or not the template parses.
    ///
    /// - Parameter url: The template file.
    /// - Returns: The module with its imports and parent module attached.
    /// - Throws: The errors of `parse(_:)`.
    func parseReportingWarnings(_ url: URL) async throws -> MTLModule {
        defer { FileDiagnosticReport.write(decodingWarnings) }
        return try await parse(url)
    }
}
