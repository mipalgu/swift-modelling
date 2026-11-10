//
// GeneratedFileLog.swift
// swift-xtend
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ModellingGenerators
import Xtend

/// A file that a generator has written.
struct WrittenFile: Sendable, Equatable {
    /// The relative path of the file within its output location.
    let path: String

    /// The name of the output configuration the file was written to.
    let outputConfiguration: String
}

/// Records the files that a generator writes and reports each one as progress.
actor GeneratedFileLog {
    /// The files written so far, in order.
    private(set) var files: [WrittenFile] = []

    /// The writer that receives the progress of the run.
    private let reporter: GenerationProgressReporter

    /// Creates a log.
    ///
    /// - Parameter reporter: The writer that receives one update for each file written.
    init(reporter: @escaping GenerationProgressReporter) {
        self.reporter = reporter
    }

    /// Records a file and reports progress.
    ///
    /// - Parameter file: The file.
    func record(_ file: WrittenFile) {
        files.append(file)
        reporter(GenerationProgressUpdate(message: file.path, completed: files.count))
    }
}

/// A file system access that writes files to directories and logs each file.
struct LoggingFileSystemAccess: XtendFileSystemAccess {
    /// The access that writes the files.
    let base: XtendDirectoryFileSystemAccess

    /// The log that records the files.
    let log: GeneratedFileLog

    /// Writes a generated file and records it.
    ///
    /// - Parameters:
    ///   - path: The relative path of the file.
    ///   - outputConfiguration: The name of the output configuration.
    ///   - contents: The text of the file.
    /// - Throws: The error of the directory access.
    func generateFile(_ path: String, outputConfiguration: String, contents: String) async throws {
        try await base.generateFile(path, outputConfiguration: outputConfiguration, contents: contents)
        await log.record(WrittenFile(path: path, outputConfiguration: outputConfiguration))
    }
}
