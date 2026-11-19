//
// SubRulePrecedenceOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ArgumentParser

/// Parses a command-line value into which rule transforms an element that a rule and a rule
/// extending it both match.
///
/// The raw values of the enumeration are the command-line spellings, so no mapping is needed
/// beyond the conformance.
extension ATLSubRulePrecedence: @retroactive ExpressibleByArgument {}

/// The command line option that chooses which rule transforms a source element that a rule and
/// a rule extending it both match.
///
/// With
/// [`ATLSubRulePrecedence.eclipse`](https://mipalgu.github.io/swift-atl/documentation/atl/atlsubruleprecedence/eclipse/),
/// the default of the standard preset, the rules are tried in the order of Eclipse ATL: a rule
/// with a guard is tried before the rules extending it that have none, so those rules never
/// transform an element that it matches. With
/// [`ATLSubRulePrecedence.extendingRule`](https://mipalgu.github.io/swift-atl/documentation/atl/atlsubruleprecedence/extendingrule/),
/// the default of the legacy preset, a rule that extends another always takes precedence over it.
///
/// The `sub-rule-precedence` key of the configuration file chooses the value as well, and the
/// option overrides it. Without either, the preset decides. Commands that run the rules of a
/// transformation include the option with `@OptionGroup` and apply the value of a run to the
/// options of the engine with ``apply(to:settings:)``.
public struct SubRulePrecedenceOptions: ParsableArguments, Sendable {
    /// The long name of the option, and the key of the configuration file.
    public static let optionName = "sub-rule-precedence"

    /// The values of the option, separated as in the usage of a command.
    public static let valueList = ATLSubRulePrecedence.allCases.map(\.rawValue).joined(separator: "|")

    /// What each value of the option gives, as text for the help of the option and of a command.
    public static let values = """
        With \(ATLSubRulePrecedence.eclipse.rawValue), the default, the rules are tried in the \
        order of Eclipse ATL: a rule with a guard before the rules extending it that have none, \
        so that those rules never transform an element that it matches. With \
        \(ATLSubRulePrecedence.extendingRule.rawValue), a rule that extends another always \
        takes precedence over it, as in version 0.6, which --semantics legacy selects.
        """

    /// The value given on the command line, if any.
    @Option(
        name: .customLong(SubRulePrecedenceOptions.optionName),
        help: ArgumentHelp(
            "Which rule transforms an element that a rule and a rule extending it both match: "
                + "\(ATLSubRulePrecedence.eclipse.rawValue) (the default) or "
                + "\(ATLSubRulePrecedence.extendingRule.rawValue)",
            discussion: SubRulePrecedenceOptions.values,
            valueName: SubRulePrecedenceOptions.valueList))
    public var explicitPrecedence: ATLSubRulePrecedence?

    /// Creates the option with nothing given, which leaves the value to the configuration file
    /// and the preset.
    public init() {}

    /// The value that applies to a run.
    ///
    /// - Parameter settings: The preset and configuration file of the run.
    /// - Returns: The value given on the command line, else the `sub-rule-precedence` of the
    ///   configuration file, else that of the preset.
    public func precedence(settings: SemanticsSettings) -> ATLSubRulePrecedence {
        explicitPrecedence ?? settings.configuration.subRulePrecedence
            ?? settings.preset.atlOptions.subRulePrecedence
    }

    /// Copies the value of a run to the options of the engine.
    ///
    /// Only `subRulePrecedence` changes, so the other behaviours stay as they are.
    ///
    /// - Parameters:
    ///   - options: The options of the engine to update.
    ///   - settings: The preset and configuration file of the run.
    public func apply(to options: inout ATLOptions, settings: SemanticsSettings) {
        options.subRulePrecedence = precedence(settings: settings)
    }

    /// A paragraph that describes the option in the discussion of a command.
    ///
    /// - Parameter reader: What runs the rules, such as `the transformation`.
    /// - Returns: The paragraph, naming the option and what it applies to, followed by ``values``.
    public static func discussion(reader: String) -> String {
        "--\(optionName) chooses which rule of \(reader) transforms a source element that a rule "
            + "and a rule extending it both match. " + values
    }
}
