//
// DocumentURIOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore

/// How a written model spells the URIs of the other documents that it refers to.
///
/// The raw value of each case is its spelling on the command line.
public enum DocumentURIStyle: String, Sendable, CaseIterable, ExpressibleByArgument {
    /// The URI of another document is written relative to the written model, such as
    /// `tasks.xmi` or `../models/tasks.xmi`, where both are files on the same drive.
    case relative

    /// The URI of another document is written in full, such as `file:///…/tasks.xmi` for a
    /// model that was read from a file.
    case absolute
}

/// The command line option that chooses how a written XMI model refers to other documents.
///
/// With ``DocumentURIStyle/relative``, the default, a reference to an element of another
/// document, such as an element of a source model that a transformation leaves unchanged,
/// names that document relative to the written model (`../models/tasks.xmi#//@tasks.1`), so
/// the written model holds no absolute path and keeps working when the models are moved
/// together. With ``DocumentURIStyle/absolute``, the reference holds the full URI of the
/// document. A URI that cannot be expressed relative to the written model, such as one on
/// another drive or of another scheme, is written in full either way.
///
/// The `document-uris` key of the configuration file chooses the style as well, and the option
/// overrides it.
///
/// Commands that write model instances include the option with `@OptionGroup` and apply the
/// style of a run to the options of their XMI serialiser with ``apply(to:settings:)``, or
/// obtain those options from ``serializationOptions(settings:)`` or, together with a reference
/// style, from ``ReferenceStyleOptions/serializationOptions(settings:documentURIs:)``.
public struct DocumentURIOptions: ParsableArguments, Sendable {
    /// The long name of the option, and the key of the configuration file.
    public static let optionName = "document-uris"

    /// The style that applies when neither the command line nor the configuration file chooses one.
    public static let defaultStyle = DocumentURIStyle.relative

    /// The values of the option, separated as in the usage of a command.
    public static let valueList = DocumentURIStyle.allCases.map(\.rawValue).joined(separator: "|")

    /// What each value of the option writes, as text for the help of the option and of a command.
    public static let styles = """
        With \(DocumentURIStyle.relative.rawValue), the default, a reference to an element of \
        another document names that document relative to the written model, such as \
        ../models/tasks.xmi#//@tasks.1, so the model holds no absolute path. With \
        \(DocumentURIStyle.absolute.rawValue), it names the document by its full URI, such as \
        a file: URI. A URI that cannot be made relative, such as one on another drive, is \
        written in full either way.
        """

    /// The style given on the command line, if any.
    @Option(
        name: .customLong(DocumentURIOptions.optionName),
        help: ArgumentHelp(
            "How an XMI model refers to other documents; "
                + "\(DocumentURIStyle.absolute.rawValue) writes their full URIs",
            discussion: DocumentURIOptions.styles,
            valueName: DocumentURIOptions.valueList))
    public var explicitStyle: DocumentURIStyle?

    /// The style given on the command line, or ``defaultStyle`` if none is.
    ///
    /// The style that applies to a run of a command that reads a configuration file also depends
    /// on that file; ``style(settings:)`` resolves it. Setting this property gives the style as
    /// if on the command line.
    public var style: DocumentURIStyle {
        get { explicitStyle ?? Self.defaultStyle }
        set { explicitStyle = newValue }
    }

    /// Creates the option with nothing given, which writes relative URIs unless the
    /// configuration file says otherwise.
    public init() {}

    /// The style that applies to a run.
    ///
    /// - Parameter settings: The settings of the run, whose configuration file is consulted.
    /// - Returns: The style given on the command line, else the `document-uris` of the
    ///   configuration file, else ``defaultStyle``.
    public func style(settings: SemanticsSettings) -> DocumentURIStyle {
        explicitStyle ?? settings.configuration.documentURIs ?? Self.defaultStyle
    }

    /// The options with which a command that offers no reference style writes an XMI model.
    ///
    /// - Parameter settings: The settings of the run, whose configuration file is consulted.
    /// - Returns: The layout of
    ///   [`XMISerializationOptions.legacy`](https://mipalgu.github.io/swift-ecore/documentation/ecore/xmiserializationoptions/legacy/),
    ///   writing the URIs of other documents in the style of ``style(settings:)``.
    public func serializationOptions(settings: SemanticsSettings) -> XMISerializationOptions {
        var options = XMISerializationOptions.legacy
        apply(to: &options, settings: settings)
        return options
    }

    /// A paragraph that describes the option in the discussion of a command.
    ///
    /// - Parameter written: What the command writes, in the plural, such as `target models`.
    /// - Returns: The paragraph, naming the option and what it applies to, followed by ``styles``.
    public static func discussion(written: String) -> String {
        "--\(optionName) chooses how XMI \(written) refer to elements of other documents. " + styles
    }

    /// Copies the style given on the command line to serialisation options.
    ///
    /// Only
    /// [`relativeURIs`](https://mipalgu.github.io/swift-ecore/documentation/ecore/xmiserializationoptions/relativeuris/)
    /// changes, so the options keep their layout.
    ///
    /// - Parameter options: The serialisation options to update.
    public func apply(to options: inout XMISerializationOptions) {
        options.relativeURIs = style == .relative
    }

    /// Copies the style of a run to serialisation options.
    ///
    /// Only
    /// [`relativeURIs`](https://mipalgu.github.io/swift-ecore/documentation/ecore/xmiserializationoptions/relativeuris/)
    /// changes, so the options keep their layout.
    ///
    /// - Parameters:
    ///   - options: The serialisation options to update.
    ///   - settings: The settings of the run, whose configuration file is consulted.
    public func apply(to options: inout XMISerializationOptions, settings: SemanticsSettings) {
        options.relativeURIs = style(settings: settings) == .relative
    }
}
