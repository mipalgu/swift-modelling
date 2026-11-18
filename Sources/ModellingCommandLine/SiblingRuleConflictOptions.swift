//
// SiblingRuleConflictOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ArgumentParser

/// Parses a command-line value into what a source element that two sub-rules match gives.
///
/// The raw values of the enumeration are the command-line spellings, so no mapping is needed
/// beyond the conformance.
extension ATLSiblingRuleConflicts: @retroactive ExpressibleByArgument {}

/// The command line option that chooses what a source element that two sub-rules of the same
/// rule both match gives.
///
/// Two rules that extend the same rule can both match a source element. With
/// [`ATLSiblingRuleConflicts.warning`](https://mipalgu.github.io/swift-atl/documentation/atl/atlsiblingruleconflicts/warning/),
/// the default of both presets, the first of them that Eclipse ATL tries transforms the element,
/// and the run reports a warning on standard error that names the element, the sub-rules and
/// the rule they extend, and says which sub-rule is applied. With
/// [`ATLSiblingRuleConflicts.error`](https://mipalgu.github.io/swift-atl/documentation/atl/atlsiblingruleconflicts/error/),
/// the run stops with an error instead and writes no target model.
///
/// The `sibling-rule-conflicts` key of the configuration file chooses the value as well, and
/// the option overrides it. Commands that run the rules of a transformation include the option
/// with `@OptionGroup` and apply the value of a run to the options of the engine with
/// ``apply(to:settings:)``.
public struct SiblingRuleConflictOptions: ParsableArguments, Sendable {
    /// The long name of the option, and the key of the configuration file.
    public static let optionName = "sibling-rule-conflicts"

    /// The values of the option, separated as in the usage of a command.
    public static let valueList = ATLSiblingRuleConflicts.allCases.map(\.rawValue).joined(separator: "|")

    /// What each value of the option gives, as text for the help of the option and of a command.
    public static let values = """
        With \(ATLSiblingRuleConflicts.warning.rawValue), the default, a source element that two \
        rules extending the same rule both match is transformed by the first of them that \
        Eclipse ATL tries, the rules with a guard before those without one, each in declaration \
        order, and a warning on standard error names the element, the rules and the rule they \
        extend. With \(ATLSiblingRuleConflicts.error.rawValue), such a match stops the run with \
        an error, and no target model is written.
        """

    /// The value given on the command line, if any.
    @Option(
        name: .customLong(SiblingRuleConflictOptions.optionName),
        help: ArgumentHelp(
            "What a source element that two rules extending the same rule both match gives: "
                + "\(ATLSiblingRuleConflicts.warning.rawValue) (the default) or "
                + "\(ATLSiblingRuleConflicts.error.rawValue)",
            discussion: SiblingRuleConflictOptions.values,
            valueName: SiblingRuleConflictOptions.valueList))
    public var explicitConflicts: ATLSiblingRuleConflicts?

    /// Creates the option with nothing given, which leaves the value to the configuration file
    /// and the preset.
    public init() {}

    /// The value that applies to a run.
    ///
    /// - Parameter settings: The preset and configuration file of the run.
    /// - Returns: The value given on the command line, else the `sibling-rule-conflicts` of the
    ///   configuration file, else that of the preset.
    public func conflicts(settings: SemanticsSettings) -> ATLSiblingRuleConflicts {
        explicitConflicts ?? settings.configuration.siblingRuleConflicts
            ?? settings.preset.atlOptions.siblingRuleConflicts
    }

    /// Copies the value of a run to the options of the engine.
    ///
    /// Only `siblingRuleConflicts` changes, so the other behaviours stay as they are.
    ///
    /// - Parameters:
    ///   - options: The options of the engine to update.
    ///   - settings: The preset and configuration file of the run.
    public func apply(to options: inout ATLOptions, settings: SemanticsSettings) {
        options.siblingRuleConflicts = conflicts(settings: settings)
    }

    /// A paragraph that describes the option in the discussion of a command.
    ///
    /// - Parameter reader: What runs the rules, such as `the transformation`.
    /// - Returns: The paragraph, naming the option and what it applies to, followed by ``values``.
    public static func discussion(reader: String) -> String {
        "--\(optionName) chooses what happens when rules of \(reader) that extend the same rule "
            + "both match a source element. " + values
    }
}
