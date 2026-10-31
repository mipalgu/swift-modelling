//
// GenerationOptions.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import MTL

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
/// ## Behaviours
///
/// ``mtlOptions`` selects the behaviours of the templates and of their expressions:
/// `MTLOptions.standard` the behaviour documented for this release, and `MTLOptions.legacy`
/// that of version 0.6, which options created with the initialiser of that version keep.
///
/// ## Example
///
/// ```swift
/// var options = GenerationOptions(mtlOptions: .standard)
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

    /// The name of the code style to write, one of the styles of the template set; `nil` follows
    /// the default style of the template set.
    public var codeStyle: String?

    /// The behaviours of the template language and its expression language.
    ///
    /// Options created with ``init(templatePaths:forceOverwrite:diff:redirectionPattern:includeSourceRoot:lineDelimiter:codeStyle:mtlOptions:)``
    /// carry the value given there, such as `MTLOptions.standard` for the behaviour documented
    /// for this release. Options created with the initialiser of version 0.6 carry
    /// `MTLOptions.legacy`, so that the templates behave as they did in that version.
    public var mtlOptions: MTLOptions

    /// How the templates read structural features that a model does not set.
    ///
    /// With ``UnsetFeatureReads/defaults``, the default, an unset attribute reads as its
    /// declared default or the default of its data type, and an unset many-valued feature as an
    /// empty collection, as in the Eclipse Modeling Framework. With
    /// ``UnsetFeatureReads/undefined`` every unset feature reads as undefined. The setting is
    /// part of ``mtlOptions``.
    public var unsetFeatureReads: UnsetFeatureReads {
        get { mtlOptions.unsetFeatureReads }
        set { mtlOptions.unsetFeatureReads = newValue }
    }

    /// The objects whose containers a model answers for during the generation, if configured.
    ///
    /// The generation pipelines create the resource set into which they load the generator
    /// model, its Ecore models and the data models of the template set with this scope as its
    /// default, so that `eContainer()` and the services that depend on it answer in this scope.
    /// With `nil`, the default, the resource set configures no scope and its resources keep the
    /// behaviour of a resource set without one.
    public var containerLookupScope: ContainerLookupScope? = nil

    /// Creates a set of options whose templates behave as in version 0.6.
    ///
    /// The options carry `MTLOptions.legacy` with the given way of reading unset features.
    ///
    /// - Parameters:
    ///   - templatePaths: Directories searched before the bundled template set.
    ///   - forceOverwrite: Whether to replace existing files.
    ///   - diff: Whether to write the generated text of existing files beside them.
    ///   - redirectionPattern: The name pattern for files written beside existing files.
    ///   - includeSourceRoot: Whether the source directory is part of the output location.
    ///   - lineDelimiter: The line delimiter to write.
    ///   - codeStyle: The name of the code style to write.
    ///   - unsetFeatureReads: How the templates read features that a model does not set.
    @available(
        *, deprecated,
        message: "Use init(templatePaths:forceOverwrite:diff:redirectionPattern:includeSourceRoot:lineDelimiter:codeStyle:mtlOptions:); pass mtlOptions: .legacy to keep the behaviour of version 0.6"
    )
    public init(
        templatePaths: [URL] = [], forceOverwrite: Bool = false, diff: Bool = false,
        redirectionPattern: String? = nil, includeSourceRoot: Bool? = nil,
        lineDelimiter: String? = nil, codeStyle: String? = nil,
        unsetFeatureReads: UnsetFeatureReads = .defaults
    ) {
        var mtlOptions = MTLOptions.legacy
        mtlOptions.unsetFeatureReads = unsetFeatureReads
        self.init(
            templatePaths: templatePaths, forceOverwrite: forceOverwrite, diff: diff,
            redirectionPattern: redirectionPattern, includeSourceRoot: includeSourceRoot,
            lineDelimiter: lineDelimiter, codeStyle: codeStyle, mtlOptions: mtlOptions)
    }

    /// Creates a set of options with the given behaviours of the templates.
    ///
    /// Pass `MTLOptions.standard` for the behaviour documented for this release, or
    /// `MTLOptions.legacy` for that of version 0.6.
    ///
    /// ```swift
    /// let options = GenerationOptions(diff: true, mtlOptions: .standard)
    /// ```
    ///
    /// - Parameters:
    ///   - templatePaths: Directories searched before the bundled template set (default: none).
    ///   - forceOverwrite: Whether to replace existing files (default: `false`).
    ///   - diff: Whether to write the generated text of existing files beside them
    ///     (default: `false`).
    ///   - redirectionPattern: The name pattern for files written beside existing files
    ///     (default: none).
    ///   - includeSourceRoot: Whether the source directory is part of the output location
    ///     (default: as the template set says).
    ///   - lineDelimiter: The line delimiter to write (default: as the template set says).
    ///   - codeStyle: The name of the code style to write (default: the default style of the
    ///     template set).
    ///   - mtlOptions: The behaviours of the template language and its expression language,
    ///     including how unset features read.
    public init(
        templatePaths: [URL] = [], forceOverwrite: Bool = false, diff: Bool = false,
        redirectionPattern: String? = nil, includeSourceRoot: Bool? = nil,
        lineDelimiter: String? = nil, codeStyle: String? = nil, mtlOptions: MTLOptions
    ) {
        self.templatePaths = templatePaths
        self.forceOverwrite = forceOverwrite
        self.diff = diff
        self.redirectionPattern = redirectionPattern
        self.includeSourceRoot = includeSourceRoot
        self.lineDelimiter = lineDelimiter
        self.codeStyle = codeStyle
        self.mtlOptions = mtlOptions
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

    /// The distinct warnings of the templates, in the order in which they were first reported.
    ///
    /// Each warning is a `SourceDiagnostic`, such as a `let` block that was skipped because its
    /// value does not conform to the declared type of its variable.
    public internal(set) var warnings: [SourceDiagnostic] = []
}
