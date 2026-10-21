//
// ReferenceStyleOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore

/// Parses a command-line value into a reference style.
///
/// The raw values of the enumeration are the command-line spellings, so no
/// mapping is needed beyond the conformance.
extension XMIReferenceStyle: @retroactive ExpressibleByArgument {}

/// The command line option that chooses how a written XMI model spells references into itself.
///
/// With ``XMIReferenceStyle/encoded``, the default, a command writes a model in its usual
/// layout, where a reference to an object of the same document holds a fragment with a
/// leading `#`, such as `#//@classifiers.0`. With ``XMIReferenceStyle/plain``, the model is
/// written in the layout of the Eclipse Modeling Framework, with references as attribute values,
/// and a reference into the same document holds the fragment alone, such as `//@classifiers.0`,
/// as Eclipse writes XMI model files. Both styles load again.
///
/// Commands that write model instances include the option with `@OptionGroup`, and obtain the
/// options of their XMI serialiser from ``serializationOptions`` or apply the chosen style to
/// options of their own with ``apply(to:)``.
public struct ReferenceStyleOptions: ParsableArguments, Sendable {
    /// The long name of the option.
    public static let optionName = "reference-style"

    /// The values of the option, separated as in the usage of a command.
    public static let valueList = XMIReferenceStyle.allCases.map(\.rawValue).joined(separator: "|")

    /// What each value of the option writes, as text for the help of the option and of a command.
    public static let styles = """
        With \(XMIReferenceStyle.encoded.rawValue), the default, an XMI model keeps its usual \
        layout and a reference to an object of the same document keeps the leading # of its \
        fragment, such as #//@classifiers.0. With \(XMIReferenceStyle.plain.rawValue), the model \
        is written in the layout of the Eclipse Modeling Framework, with references as attribute \
        values holding the fragment alone, such as //@classifiers.0, as Eclipse writes XMI model \
        files. Both styles load again.
        """

    /// How references into the written document are spelt.
    @Option(
        name: .customLong(ReferenceStyleOptions.optionName),
        help: ArgumentHelp(
            "How an XMI model spells references into itself; "
                + "\(XMIReferenceStyle.plain.rawValue) writes them as Eclipse writes XMI model files",
            discussion: ReferenceStyleOptions.styles,
            valueName: ReferenceStyleOptions.valueList))
    public var referenceStyle: XMIReferenceStyle = .encoded

    /// Creates the option with the encoded reference style.
    public init() {}

    /// A paragraph that describes the option in the discussion of a command.
    ///
    /// - Parameter written: What the command writes, in the plural, such as `target models`.
    /// - Returns: The paragraph, naming the option and what it applies to, followed by ``styles``.
    public static func discussion(written: String) -> String {
        "--\(optionName) chooses how XMI \(written) spell references to objects of the same "
            + "document. " + styles
    }

    /// The options with which a command writes an XMI model in the chosen style.
    ///
    /// The encoded style keeps the layout of ``XMISerializationOptions/legacy``, so a command
    /// writes the same text as without the option. The plain style applies only to references
    /// written as attributes, so it selects the layout of ``XMISerializationOptions/emf`` with
    /// the plain style applied.
    public var serializationOptions: XMISerializationOptions {
        guard referenceStyle != .encoded else { return .legacy }
        var options = XMISerializationOptions.emf
        apply(to: &options)
        return options
    }

    /// Copies the reference style given on the command line to serialisation options.
    ///
    /// - Parameter options: The serialisation options to update.
    public func apply(to options: inout XMISerializationOptions) {
        options.referenceStyle = referenceStyle
    }
}
