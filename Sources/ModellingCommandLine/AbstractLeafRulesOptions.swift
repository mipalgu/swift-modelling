//
// AbstractLeafRulesOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ArgumentParser

/// Parses a command-line value into what a source element gives that an abstract rule matches
/// when no rule extends that abstract rule.
///
/// The raw values of the enumeration are the command-line spellings, so no mapping is needed
/// beyond the conformance.
extension ATLAbstractLeafRules: @retroactive ExpressibleByArgument {}

/// The command line option that chooses what a source element gives that an abstract rule matches
/// when no rule extends that abstract rule.
///
/// With
/// [`ATLAbstractLeafRules.error`](https://mipalgu.github.io/swift-atl/documentation/atl/atlabstractleafrules/error/),
/// the default of the standard preset, the run stops with an error that names the rule and the
/// element, as Eclipse ATL fails, because such a rule cannot be applied. With
/// [`ATLAbstractLeafRules.ignore`](https://mipalgu.github.io/swift-atl/documentation/atl/atlabstractleafrules/ignore/),
/// the default of the legacy preset, an abstract rule that no rule extends never matches, so it
/// transforms nothing.
///
/// The `abstract-leaf-rules` key of the configuration file chooses the value as well, and the
/// option overrides it. Without either, the preset decides. Commands that run the rules of a
/// transformation include the option with `@OptionGroup` and apply the value of a run to the
/// options of the engine with ``apply(to:settings:)``.
public struct AbstractLeafRulesOptions: ParsableArguments, Sendable {
    /// The long name of the option, and the key of the configuration file.
    public static let optionName = "abstract-leaf-rules"

    /// The values of the option, separated as in the usage of a command.
    public static let valueList = ATLAbstractLeafRules.allCases.map(\.rawValue).joined(separator: "|")

    /// What each value of the option gives, as text for the help of the option and of a command.
    public static let values = """
        With \(ATLAbstractLeafRules.error.rawValue), the default, the run stops with an error that \
        names the rule and the element, as Eclipse ATL fails, because such a rule cannot be \
        applied. With \(ATLAbstractLeafRules.ignore.rawValue), an abstract rule that no rule \
        extends never matches, so it transforms nothing, as in version 0.6, which --semantics \
        legacy selects.
        """

    /// The value given on the command line, if any.
    @Option(
        name: .customLong(AbstractLeafRulesOptions.optionName),
        help: ArgumentHelp(
            "What an element gives that an abstract rule matches when no rule extends it: "
                + "\(ATLAbstractLeafRules.error.rawValue) (the default) or "
                + "\(ATLAbstractLeafRules.ignore.rawValue)",
            discussion: AbstractLeafRulesOptions.values,
            valueName: AbstractLeafRulesOptions.valueList))
    public var explicitLeafRules: ATLAbstractLeafRules?

    /// Creates the option with nothing given, which leaves the value to the configuration file
    /// and the preset.
    public init() {}

    /// The value that applies to a run.
    ///
    /// - Parameter settings: The preset and configuration file of the run.
    /// - Returns: The value given on the command line, else the `abstract-leaf-rules` of the
    ///   configuration file, else that of the preset.
    public func leafRules(settings: SemanticsSettings) -> ATLAbstractLeafRules {
        explicitLeafRules ?? settings.configuration.abstractLeafRules
            ?? settings.preset.atlOptions.abstractLeafRules
    }

    /// Copies the value of a run to the options of the engine.
    ///
    /// Only `abstractLeafRules` changes, so the other behaviours stay as they are.
    ///
    /// - Parameters:
    ///   - options: The options of the engine to update.
    ///   - settings: The preset and configuration file of the run.
    public func apply(to options: inout ATLOptions, settings: SemanticsSettings) {
        options.abstractLeafRules = leafRules(settings: settings)
    }

    /// A paragraph that describes the option in the discussion of a command.
    ///
    /// - Parameter reader: What runs the rules, such as `the transformation`.
    /// - Returns: The paragraph, naming the option and what it applies to, followed by ``values``.
    public static func discussion(reader: String) -> String {
        "--\(optionName) chooses what a source element gives that an abstract rule of \(reader) "
            + "matches when no rule extends it. " + values
    }
}
