//
// LetTypeMismatchOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import MTL
import ModellingGenerators

/// Parses a command-line value into a mode of handling typed `let` mismatches.
///
/// The raw values of the enumeration are the command-line spellings, so no
/// mapping is needed beyond the conformance.
extension MTLLetTypeMismatches: @retroactive ExpressibleByArgument {}

/// The command line option that chooses how a typed `let` treats a value that does not conform.
///
/// A `let` variable in a template may declare a type, as in `[let n : Integer = e]`. By default a
/// value that does not conform to that type is an error that stops the generation. The `skip`
/// mode follows the OMG MOFM2T specification and Acceleo 3 instead, which treat a typed `let` as
/// a type test: the `let` block is skipped and the generation continues, and the command writes a
/// warning to standard error with ``GenerationWarningReport``. The option applies only while `let`
/// types are checked, as ``MTLSemanticsOptions/checksLetTypes`` selects.
///
/// The configuration file may choose the mode too; an option given on the command line
/// overrides it. The preset of ``SemanticsOptions`` does not change the mode.
///
/// Commands include the option with `@OptionGroup`, and either pass
/// ``letTypeMismatches(settings:)`` to the generator they run or apply it to their generation
/// options with ``apply(to:settings:)``.
public struct LetTypeMismatchOptions: ParsableArguments, Sendable {
    /// The long name of the option.
    public static let optionName = "let-type-mismatches"

    /// The values of the option, separated as in the usage of a command.
    public static let valueList = MTLLetTypeMismatches.allCases.map(\.rawValue).joined(separator: "|")

    /// How a typed `let` treats a value that does not conform to its declared type.
    @Option(
        name: .customLong(LetTypeMismatchOptions.optionName),
        help: ArgumentHelp(
            "How a typed let treats a value of another type: \(MTLLetTypeMismatches.error.rawValue) "
                + "(the default) or \(MTLLetTypeMismatches.skip.rawValue), which skips the let block "
                + "with a warning, as Acceleo 3 does",
            discussion: """
                With \(MTLLetTypeMismatches.error.rawValue), a value that does not conform to the \
                declared type of a let variable, such as a string for [let n : Integer = e], stops \
                the generation with an error. With \(MTLLetTypeMismatches.skip.rawValue), the let \
                block is skipped and the generation continues, as in Acceleo 3, and a warning that \
                names the variable and both types is written to standard error. Null conforms to \
                every type. With --\(MTLSemanticsOptions.inversionPrefix)\(MTLSemanticsOptions.OptionName.checkLetTypes), \
                values are bound unchecked and the option has no effect.
                """,
            valueName: LetTypeMismatchOptions.valueList))
    public var explicitLetTypeMismatches: MTLLetTypeMismatches?

    /// The mode that applies when neither the command line nor the configuration file
    /// chooses one, `MTLLetTypeMismatches.error`.
    public static let defaultMode = MTLLetTypeMismatches.error

    /// The mode given on the command line, or ``defaultMode`` if none is.
    ///
    /// The mode that applies to a run also depends on the configuration file;
    /// ``letTypeMismatches(settings:)`` resolves it. Setting this property gives the mode as if
    /// on the command line.
    public var letTypeMismatches: MTLLetTypeMismatches {
        get { explicitLetTypeMismatches ?? Self.defaultMode }
        set { explicitLetTypeMismatches = newValue }
    }

    /// Creates the option with nothing given, which treats mismatches as errors unless the
    /// configuration file says otherwise.
    public init() {}

    /// The mode that applies to a run.
    ///
    /// The mode does not depend on the preset: it is the mode given on the command line, else
    /// the `let-type-mismatches` of the configuration file, else ``defaultMode``.
    ///
    /// - Parameter settings: The settings of the run, whose configuration file is consulted.
    /// - Returns: How a typed `let` treats a value that does not conform to its declared type.
    public func letTypeMismatches(settings: SemanticsSettings) -> MTLLetTypeMismatches {
        explicitLetTypeMismatches ?? settings.configuration.letTypeMismatches ?? Self.defaultMode
    }

    /// A paragraph that describes the option in the discussion of a command.
    ///
    /// - Parameter reader: What declares the typed `let` blocks, in the plural, such as `the templates`.
    /// - Returns: The paragraph, naming the option, its values and the semantics of each.
    public static func discussion(reader: String) -> String {
        "--\(optionName) chooses what happens when a typed let in \(reader) receives a value that "
            + "does not conform to its declared type. With \(MTLLetTypeMismatches.error.rawValue), the "
            + "default, the generation stops with an error. With \(MTLLetTypeMismatches.skip.rawValue), "
            + "the let block is skipped, as in Acceleo 3, and a warning is written to standard error."
    }

    /// Copies the mode given on the command line to generation options.
    ///
    /// - Parameter options: The generation options to update.
    public func apply(to options: inout GenerationOptions) {
        options.mtlOptions.letTypeMismatches = letTypeMismatches
    }

    /// Copies the mode that applies to a run to generation options.
    ///
    /// - Parameters:
    ///   - options: The generation options to update.
    ///   - settings: The settings of the run, whose configuration file is consulted.
    public func apply(to options: inout GenerationOptions, settings: SemanticsSettings) {
        options.mtlOptions.letTypeMismatches = letTypeMismatches(settings: settings)
    }
}
