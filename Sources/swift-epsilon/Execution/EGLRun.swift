//
// EGLRun.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EGL
import EMFBase
import EOL
import Foundation
import ModellingCommandLine

/// Renders Epsilon Generation Language templates and runs EGX coordination modules against
/// the models of a workspace.
enum EGLRun {
    /// Whether a file is an EGX coordination module rather than a template.
    ///
    /// - Parameter path: The path of the file.
    /// - Returns: `true` if the extension of the file is that of EGX, in any case.
    static func isCoordination(_ path: String) -> Bool {
        URL(fileURLWithPath: path).pathExtension.lowercased() == SwiftEpsilonVocabulary.FileExtension.coordination
    }

    /// Reads, parses and renders a template.
    ///
    /// The template reads the parameters of the run as variables.
    ///
    /// - Parameters:
    ///   - template: The path of the template.
    ///   - workspace: The models of the run.
    ///   - output: Where the code of the template prints with `print` (standard output by default).
    ///   - errorOutput: Where the template prints errors (standard error by default).
    /// - Returns: The generated text.
    /// - Throws: The errors of reading and parsing the template, and the `EOLError` that the
    ///   template raises.
    static func render(
        template: String, workspace: ModelWorkspace, output: any EOLOutputStream = EOLStandardOutput(),
        errorOutput: any EOLOutputStream = EOLStandardOutput(error: true)
    ) async throws -> String {
        let parsed = try SourceReader(encoding: workspace.configuration.encoding).module(at: template) {
            EGLSyntax.parse($0, document: $1)
        }
        workspace.log("Rendering \(template)")
        let runner = EGLTemplateRunner(interpreter: workspace.makeInterpreter(output: output, errorOutput: errorOutput))
        return try await runner.render(parsed, variables: workspace.variables)
    }

    /// Writes generated text to a file, keeping the protected regions of an existing file.
    ///
    /// - Parameters:
    ///   - text: The generated text.
    ///   - path: The path of the file.
    ///   - merging: Whether the enabled protected regions of an existing file are kept.
    ///   - encoding: The character encoding in which the file is read and written (default: UTF-8).
    /// - Returns: What happened to the file, and the warnings about protected regions whose
    ///   contents were lost.
    /// - Throws: ``OutputFileError`` if the encoding cannot hold a character of the text,
    ///   ``SwiftEpsilonError/notDecodable(_:_:)`` if an existing file is not valid in the encoding,
    ///   and the error of the file system if the file cannot be read or written.
    static func write(_ text: String, to path: String, merging: Bool, encoding: TextEncoding = .utf8) throws -> (
        status: EGXFileStatus, diagnostics: [SourceDiagnostic]
    ) {
        let url = URL(fileURLWithPath: path)
        let existing = FileManager.default.fileExists(atPath: path) ? try Self.read(url, encoding: encoding) : nil
        var text = text
        var diagnostics: [SourceDiagnostic] = []
        if let existing, merging {
            let merged = EGLProtectedRegions.merge(generated: text, existing: existing, document: path)
            text = merged.text
            diagnostics = merged.diagnostics
        }
        let status: EGXFileStatus = existing == nil ? .created : existing == text ? .unchanged : .updated
        if status != .unchanged {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try OutputFile.write(text, to: path, encoding: encoding)
        }
        return (status, diagnostics)
    }

    /// Reads an existing output file in an encoding.
    ///
    /// - Parameters:
    ///   - url: The location of the file.
    ///   - encoding: The character encoding of the file.
    /// - Returns: The text of the file.
    /// - Throws: ``SwiftEpsilonError/notDecodable(_:_:)`` if the file is not valid in the
    ///   encoding, and the error of the file system if it cannot be read.
    private static func read(_ url: URL, encoding: TextEncoding) throws -> String {
        if encoding == .utf8 { return try String(contentsOf: url, encoding: .utf8) }
        guard let text = encoding.decode(try Data(contentsOf: url)) else {
            throw SwiftEpsilonError.notDecodable(url.path, encoding)
        }
        return text
    }

    /// Reads, parses and runs an EGX coordination module.
    ///
    /// The rules of the module write their files below the output directory; the templates they
    /// name are read relative to the module.
    ///
    /// - Parameters:
    ///   - coordination: The path of the module.
    ///   - workspace: The models of the run.
    ///   - outputDirectory: The directory against which the target paths of the rules are resolved.
    ///   - allowsPathsOutsideOutput: Whether rules may write outside the output directory.
    ///   - encoding: The character encoding of the files that the rules write (default: UTF-8).
    ///   - progress: What is told about each file that is written, with the number written so far.
    ///   - output: Where the module and its templates print (standard output by default).
    ///   - errorOutput: Where they print errors (standard error by default).
    /// - Returns: The rule applications and the warnings about protected regions.
    /// - Throws: The errors of reading and parsing the module, and the `EOLError` that a rule or
    ///   template raises.
    static func generate(
        coordination: String, workspace: ModelWorkspace, outputDirectory: String, allowsPathsOutsideOutput: Bool,
        encoding: TextEncoding = .utf8,
        progress: @escaping (Int) -> Void = { _ in }, output: any EOLOutputStream = EOLStandardOutput(),
        errorOutput: any EOLOutputStream = EOLStandardOutput(error: true)
    ) async throws -> EGXResult {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: outputDirectory, isDirectory: &isDirectory), !isDirectory.boolValue {
            throw SwiftEpsilonError.outputNotDirectory(outputDirectory)
        }
        let reader = SourceReader(encoding: workspace.configuration.encoding)
        let module = try reader.module(at: coordination) { EGXSyntax.parse($0, document: $1) }
        workspace.log("Generating with \(coordination) into \(outputDirectory)")
        let fileSystem = ReportingFileSystem(
            base: EGXDirectoryFileSystem(
                base: URL(fileURLWithPath: outputDirectory, isDirectory: true),
                allowsPathsOutsideBase: allowsPathsOutsideOutput, encoding: encoding),
            report: progress)
        let generator = EGXGenerator(
            interpreter: workspace.makeInterpreter(output: output, errorOutput: errorOutput),
            templateLoader: reader.moduleLoader, fileSystem: fileSystem)
        let result = try await generator.generate(module)
        workspace.log("Applied \(result.files.count) rule\(result.files.count == 1 ? "" : SwiftEpsilonVocabulary.Validation.pluralSuffix), wrote \(fileSystem.written) files")
        return result
    }
}

/// A file system that tells a receiver about each file that is written to another file system.
final class ReportingFileSystem: EGXFileSystem {
    /// The file system that reads and writes the files.
    let base: any EGXFileSystem

    /// What is told about each file written, with the number written so far.
    let report: (Int) -> Void

    /// The number of files written so far.
    private(set) var written = 0

    /// Creates a reporting file system.
    ///
    /// - Parameters:
    ///   - base: The file system that reads and writes the files.
    ///   - report: What is told about each file written, with the number written so far.
    init(base: any EGXFileSystem, report: @escaping (Int) -> Void) {
        self.base = base
        self.report = report
    }

    /// Reads a file of the underlying file system.
    ///
    /// - Parameter path: The target path.
    /// - Returns: The text, or `nil` if the file does not exist.
    /// - Throws: The error of the underlying file system.
    func read(_ path: String) throws -> String? { try base.read(path) }

    /// Writes a file to the underlying file system and reports it.
    ///
    /// - Parameters:
    ///   - text: The text.
    ///   - path: The target path.
    /// - Throws: The error of the underlying file system.
    func write(_ text: String, to path: String) throws {
        try base.write(text, to: path)
        written += 1
        report(written)
    }
}
