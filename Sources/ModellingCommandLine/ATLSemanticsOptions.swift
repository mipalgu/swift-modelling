//
// ATLSemanticsOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ArgumentParser
import ModellingGenerators

/// Parses a command-line value into the syntax of collection ranges.
extension ATLCollectionRangeSyntax: @retroactive ExpressibleByArgument {}

/// The command line options that choose the behaviours of ATL source.
///
/// Each option selects one behaviour of `ATLOptions`. An option that is not given takes the
/// value of the preset that ``SemanticsOptions`` chooses, so `--semantics legacy` gives the
/// behaviour of version 0.6 unless an option of this group says otherwise. The values of the
/// options are the raw values of the enumerations of the ATL library.
///
/// Commands include the options with `@OptionGroup`, and either pass ``atlOptions(preset:)`` to
/// the parser they run or apply the options to their import options with ``apply(to:preset:)``.
public struct ATLSemanticsOptions: ParsableArguments, Sendable {
    /// The long names of the options.
    public enum OptionName {
        /// The option that chooses `ATLOptions.collectionRangeSyntax`.
        public static let collectionRangeSyntax = "collection-range-syntax"
    }

    /// Whether collection literals accept integer ranges.
    @Option(
        name: .customLong(OptionName.collectionRangeSyntax),
        help: ArgumentHelp(
            "Integer ranges in collection literals: \(ATLCollectionRangeSyntax.ocl.rawValue) (the "
                + "default) or \(ATLCollectionRangeSyntax.eclipse.rawValue), as in version 0.6",
            discussion: """
                With \(ATLCollectionRangeSyntax.ocl.rawValue), a collection literal such as \
                Sequence{0, 2..4} accepts the integer ranges of OCL. With \
                \(ATLCollectionRangeSyntax.eclipse.rawValue), ranges are a syntax error, as in \
                Eclipse ATL.
                """,
            valueName: MTLSemanticsOptions.valueList(ATLCollectionRangeSyntax.self)))
    public var collectionRangeSyntax: ATLCollectionRangeSyntax?

    /// Creates the options with nothing set, which leaves every behaviour to the preset.
    public init() {}

    /// The behaviours of ATL source that the options and a preset select.
    ///
    /// - Parameter preset: The preset whose behaviours apply where no option was given.
    /// - Returns: The options of the preset, with each option given on the command line in place.
    public func atlOptions(preset: SemanticsPreset) -> ATLOptions {
        var options = preset.atlOptions
        if let collectionRangeSyntax { options.collectionRangeSyntax = collectionRangeSyntax }
        return options
    }

    /// Copies the behaviours that the options and a preset select to the options of an import.
    ///
    /// - Parameters:
    ///   - options: The import options to update.
    ///   - preset: The preset whose behaviours apply where no option was given.
    public func apply(to options: inout GenModelImportOptions, preset: SemanticsPreset) {
        options.atlOptions = atlOptions(preset: preset)
    }

    /// A paragraph that describes the options in the discussion of a command.
    ///
    /// - Parameter reader: What is read as ATL source, such as `the transformation`.
    /// - Returns: The paragraph, naming the options and how to get the behaviour of version 0.6.
    public static func discussion(reader: String) -> String {
        "--\(OptionName.collectionRangeSyntax) chooses whether \(reader) may use integer ranges "
            + "such as Sequence{1..3}: \(ATLCollectionRangeSyntax.ocl.rawValue), the default, "
            + "accepts them, and \(ATLCollectionRangeSyntax.eclipse.rawValue), as in version 0.6 "
            + "and with --\(SemanticsOptions.optionName) \(SemanticsPreset.legacy.rawValue), "
            + "rejects them."
    }
}
