//
// GenerationOptions.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// The settings of generating code from a generator model.
///
/// The options mirror the flags of the Eclipse generator that apply to templates: directories
/// that override templates, forced overwriting of existing files and writing differences beside
/// existing files instead of changing them.
///
/// ## Existing files
///
/// When a file to write exists already, the options decide what happens, in this order:
/// 1. With ``forceOverwrite`` the generated text replaces the file.
/// 2. With ``diff`` (or an explicit ``redirectionPattern``) the generated text is written beside
///    the file and the file stays as it is.
/// 3. Otherwise a template set that declares a merge keeps the parts that were edited by hand
///    and regenerates the rest; without a merge declaration the file is replaced.
///
/// ## Example
///
/// ```swift
/// var options = GenerationOptions()
/// options.templatePaths = [URL(fileURLWithPath: "my-templates")]
/// options.diff = true
/// ```
public struct GenerationOptions: Sendable, Equatable {
    /// Directories searched for template files before the bundled template set.
    ///
    /// Each directory holds either a directory named after the language, or the files of the set.
    public var templatePaths: [URL]

    /// Whether generated text replaces existing files without merging or redirection.
    public var forceOverwrite: Bool

    /// Whether the generated text of an existing file is written beside it, named by the diff pattern.
    public var diff: Bool

    /// The pattern for the name of a file written beside an existing file, with `{0}` standing for
    /// the name of the existing file; `nil` uses the default pattern when ``diff`` is set.
    public var redirectionPattern: String?

    /// Whether the source directory of the generator model is part of the output location.
    ///
    /// `nil` follows the default of the template set.
    public var includeSourceRoot: Bool?

    /// The line delimiter written to files; `nil` follows the template set.
    public var lineDelimiter: String?

    /// Creates a set of options.
    ///
    /// - Parameters:
    ///   - templatePaths: Directories searched before the bundled template set.
    ///   - forceOverwrite: Whether to replace existing files.
    ///   - diff: Whether to write the generated text of existing files beside them.
    ///   - redirectionPattern: The name pattern for files written beside existing files.
    ///   - includeSourceRoot: Whether the source directory is part of the output location.
    ///   - lineDelimiter: The line delimiter to write.
    public init(
        templatePaths: [URL] = [], forceOverwrite: Bool = false, diff: Bool = false,
        redirectionPattern: String? = nil, includeSourceRoot: Bool? = nil,
        lineDelimiter: String? = nil
    ) {
        self.templatePaths = templatePaths
        self.forceOverwrite = forceOverwrite
        self.diff = diff
        self.redirectionPattern = redirectionPattern
        self.includeSourceRoot = includeSourceRoot
        self.lineDelimiter = lineDelimiter
    }

    /// The redirection pattern that applies, if any.
    public var effectiveRedirectionPattern: String? {
        redirectionPattern ?? (diff ? TemplateSetConstants.diffRedirectionPattern : nil)
    }
}

/// A report of how far generation has come, suitable for a progress bar.
///
/// The total is known when the template set can say how many files it writes; otherwise it is `nil`
/// and only the count of completed files is meaningful.
public struct GenerationProgressUpdate: Sendable, Equatable {
    /// What the pipeline is doing or has just done.
    public let message: String

    /// The number of files written so far.
    public let completed: Int

    /// The number of files that will be written, if known.
    public let total: Int?

    /// The completed share of the work between zero and one, or `nil` if the total is not known.
    public var fraction: Double? {
        guard let total, total > 0 else { return nil }
        return min(1, Double(completed) / Double(total))
    }

    /// Creates a progress report.
    ///
    /// - Parameters:
    ///   - message: What the pipeline is doing.
    ///   - completed: The number of files written so far.
    ///   - total: The number of files to write, if known.
    public init(message: String, completed: Int = 0, total: Int? = nil) {
        self.message = message
        self.completed = completed
        self.total = total
    }
}

/// A receiver of progress reports from code generation.
public typealias GenerationProgressReporter = @Sendable (GenerationProgressUpdate) -> Void

/// The outcome of generating code from a generator model.
public struct GenerationResult: Sendable, Equatable {
    /// The directory that files were written relative to.
    public let outputDirectory: URL

    /// The files that the templates wrote, in the order they were written.
    ///
    /// With redirection a file may have been written beside an existing one under another name;
    /// the entries name the intended targets.
    public let files: [URL]

    /// The language of the template set that was used.
    public let language: String

    /// The number of generator packages that were processed.
    public let packageCount: Int
}
