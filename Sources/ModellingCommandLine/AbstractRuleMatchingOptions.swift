//
// AbstractRuleMatchingOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ArgumentParser

/// Parses a command-line value into what a source element gives that an abstract rule matches but
/// none of the rules extending it match.
///
/// The raw values of the enumeration are the command-line spellings, so no mapping is needed
/// beyond the conformance.
extension ATLAbstractRuleMatching: @retroactive ExpressibleByArgument {}

/// The command line option that chooses what a source element gives that an abstract rule matches
/// but none of the rules extending it match.
///
/// With
/// [`ATLAbstractRuleMatching.eclipse`](https://mipalgu.github.io/swift-atl/documentation/atl/atlabstractrulematching/eclipse/),
/// the default of the standard preset, an abstract rule is tried like any other rule, as in Eclipse
/// ATL: once it matches an element, only the rules extending it can transform the element, so the
/// rules declared after it are not tried. With
/// [`ATLAbstractRuleMatching.skip`](https://mipalgu.github.io/swift-atl/documentation/atl/atlabstractrulematching/skip/),
/// the default of the legacy preset, an abstract rule none of whose sub-rules match an element is
/// passed over, and the rules declared after it are tried next.
///
/// The `abstract-rule-matching` key of the configuration file chooses the value as well, and the
/// option overrides it. Without either, the preset decides. Commands that run the rules of a
/// transformation include the option with `@OptionGroup` and apply the value of a run to the
/// options of the engine with ``apply(to:settings:)``.
public struct AbstractRuleMatchingOptions: ParsableArguments, Sendable {
    /// The long name of the option, and the key of the configuration file.
    public static let optionName = "abstract-rule-matching"

    /// The values of the option, separated as in the usage of a command.
    public static let valueList = ATLAbstractRuleMatching.allCases.map(\.rawValue).joined(separator: "|")

    /// What each value of the option gives, as text for the help of the option and of a command.
    public static let values = """
        With \(ATLAbstractRuleMatching.eclipse.rawValue), the default, an abstract rule is tried \
        like any other rule, as in Eclipse ATL: once it matches an element, only the rules \
        extending it can transform the element, and the rules declared after it are not tried. \
        With \(ATLAbstractRuleMatching.skip.rawValue), an abstract rule none of whose sub-rules \
        match an element is passed over and the rules declared after it are tried next, as in \
        version 0.6, which --semantics legacy selects.
        """

    /// The value given on the command line, if any.
    @Option(
        name: .customLong(AbstractRuleMatchingOptions.optionName),
        help: ArgumentHelp(
            "What an element gives that an abstract rule matches but none of its sub-rules match: "
                + "\(ATLAbstractRuleMatching.eclipse.rawValue) (the default) or "
                + "\(ATLAbstractRuleMatching.skip.rawValue)",
            discussion: AbstractRuleMatchingOptions.values,
            valueName: AbstractRuleMatchingOptions.valueList))
    public var explicitMatching: ATLAbstractRuleMatching?

    /// Creates the option with nothing given, which leaves the value to the configuration file
    /// and the preset.
    public init() {}

    /// The value that applies to a run.
    ///
    /// - Parameter settings: The preset and configuration file of the run.
    /// - Returns: The value given on the command line, else the `abstract-rule-matching` of the
    ///   configuration file, else that of the preset.
    public func matching(settings: SemanticsSettings) -> ATLAbstractRuleMatching {
        explicitMatching ?? settings.configuration.abstractRuleMatching
            ?? settings.preset.atlOptions.abstractRuleMatching
    }

    /// Copies the value of a run to the options of the engine.
    ///
    /// Only `abstractRuleMatching` changes, so the other behaviours stay as they are.
    ///
    /// - Parameters:
    ///   - options: The options of the engine to update.
    ///   - settings: The preset and configuration file of the run.
    public func apply(to options: inout ATLOptions, settings: SemanticsSettings) {
        options.abstractRuleMatching = matching(settings: settings)
    }

    /// A paragraph that describes the option in the discussion of a command.
    ///
    /// - Parameter reader: What runs the rules, such as `the transformation`.
    /// - Returns: The paragraph, naming the option and what it applies to, followed by ``values``.
    public static func discussion(reader: String) -> String {
        "--\(optionName) chooses what a source element gives that an abstract rule of \(reader) "
            + "matches but none of the rules extending it match. " + values
    }
}
