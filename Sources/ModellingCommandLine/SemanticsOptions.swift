//
// SemanticsOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ATL
import ArgumentParser
import MTL

/// A set of behaviours of the modelling languages, chosen as a whole.
///
/// Each case gives every behaviour that has an alternative a value at once: ``standard`` the
/// behaviour documented for this release, and ``legacy`` the behaviour of version 0.6. The raw
/// value of each case is its command-line spelling.
public enum SemanticsPreset: String, CaseIterable, Sendable, ExpressibleByArgument {
    /// The behaviour documented for this release, which is the default.
    case standard

    /// The behaviour of version 0.6.
    case legacy

    /// The behaviours of the template language that the preset gives.
    ///
    /// - Returns: `MTLOptions.standard` or `MTLOptions.legacy`.
    public var mtlOptions: MTLOptions {
        switch self {
        case .standard: return .standard
        case .legacy: return .legacy
        }
    }

    /// The behaviours of the transformation language that the preset gives.
    ///
    /// - Returns: `ATLOptions.standard` or `ATLOptions.legacy`.
    public var atlOptions: ATLOptions {
        switch self {
        case .standard: return .standard
        case .legacy: return .legacy
        }
    }
}

/// The command line option that chooses the behaviours of the modelling languages as a whole.
///
/// `--semantics standard`, the default, selects the behaviour documented for this release, and
/// `--semantics legacy` that of version 0.6. The option sets every behaviour that
/// ``MTLSemanticsOptions`` and ``ATLSemanticsOptions`` offer; an option of those groups that is
/// given on the command line overrides the preset, whatever the order of the options.
///
/// Commands include the option with `@OptionGroup` once, next to the groups whose behaviours it
/// presets, and pass ``semantics`` to them.
public struct SemanticsOptions: ParsableArguments, Sendable {
    /// The long name of the option.
    public static let optionName = "semantics"

    /// The values of the option, separated as in the usage of a command.
    public static let valueList = SemanticsPreset.allCases.map(\.rawValue).joined(separator: "|")

    /// The preset of behaviours.
    @Option(
        name: .customLong(SemanticsOptions.optionName),
        help: ArgumentHelp(
            "The behaviours of the languages: \(SemanticsPreset.standard.rawValue) (the default) "
                + "or \(SemanticsPreset.legacy.rawValue), as in version 0.6",
            discussion: """
                \(SemanticsPreset.standard.rawValue) selects the behaviour documented for this \
                release, and \(SemanticsPreset.legacy.rawValue) that of version 0.6, for every \
                behaviour option of the command. A behaviour option that is given as well \
                overrides the preset.
                """,
            valueName: SemanticsOptions.valueList))
    public var semantics: SemanticsPreset = .standard

    /// Creates the option with the behaviour documented for this release.
    public init() {}

    /// A paragraph that describes the option in the discussion of a command.
    ///
    /// - Returns: The paragraph, naming the option, its values and the precedence of the
    ///   options that it presets.
    public static func discussion() -> String {
        "--\(optionName) \(SemanticsPreset.legacy.rawValue) selects the behaviour of version 0.6 "
            + "for every behaviour option of the command, and --\(optionName) "
            + "\(SemanticsPreset.standard.rawValue), the default, the behaviour of this release. "
            + "A behaviour option given on the command line overrides the preset."
    }
}
