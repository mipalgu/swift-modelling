//
// CodeStyleOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ModellingGenerators

/// The command line option that chooses the code style of generated text.
///
/// A template set may offer several code styles, such as different indentation and brace
/// placement for the code it writes. The option names one of them; without it the template set
/// applies its default style. A template set that offers no code styles, such as `swift`, `c` or `cpp`,
/// rejects the option.
///
/// Commands include the option with `@OptionGroup`, and apply it to their generation options with
/// ``apply(to:)``.
public struct CodeStyleOptions: ParsableArguments, Sendable {
    /// The name of the code style.
    @Option(
        name: .customLong("code-style"),
        help: ArgumentHelp(
            "The code style of the generated text, one of the styles of the template set",
            discussion: """
                The code styles of the bundled template sets are listed in the discussion of the \
                command. A template set without code styles rejects the option. Existing files are \
                merged in the style that is chosen: every generated member takes the new style, \
                while members marked @generated NOT and members you wrote keep their layout.
                """,
            valueName: "style"))
    public var codeStyle: String?

    /// Creates the option with no style chosen.
    public init() {}

    /// Whether a code style was given on the command line.
    public var isGiven: Bool { codeStyle != nil }

    /// Copies the code style given on the command line to generation options.
    ///
    /// - Parameter options: The generation options to update.
    public func apply(to options: inout GenerationOptions) {
        if let codeStyle { options.codeStyle = codeStyle }
    }

    /// The code styles of the bundled template sets, as text for the help of a command.
    ///
    /// - Returns: One entry for each language that offers code styles, such as
    ///   `java: eclipse (default), emf`, separated by semicolons; `none` if there are none.
    public static func bundledStyleList() -> String {
        let entries = TemplateSet.bundledCodeStyles().map { entry in
            let names = entry.styles.map { $0 == entry.defaultStyle ? "\($0) (default)" : $0 }
            return "\(entry.language): " + names.joined(separator: ", ")
        }
        return entries.isEmpty ? "none" : entries.joined(separator: "; ")
    }
}
