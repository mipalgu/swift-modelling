//
// CompleteOCLOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser

/// The command line option that names Complete OCL documents to apply to the metamodels.
///
/// A Complete OCL document (`.ocl`) adds invariants, pre- and postconditions, definitions and
/// derivations to the classes and features of metamodels that are defined elsewhere. Each
/// document is applied after the metamodels are loaded, in command line order, so that the
/// constraints become part of the metamodels: the `validate` command checks the invariants,
/// and a metamodel that is written afterwards carries them as OCL annotations.
///
/// Commands include the option with `@OptionGroup` and pass ``documents`` to
/// `MetamodelOptions.resourceSet(applying:verbose:debug:options:)` or to
/// `MetamodelRegistration.applyCompleteOCL(_:to:in:verbose:diagnosticOutput:)`.
public struct CompleteOCLOptions: ParsableArguments, Sendable {
    /// The long name of the option.
    public static let optionName = "ocl"

    /// The name of the value of the option in the usage of a command.
    public static let valueName = "file.ocl"

    /// What the option does, as a paragraph for the help of the option and of a command.
    public static let effect = """
        A Complete OCL document adds constraints to the classes of the metamodels given with \
        --\(MetamodelOptions.optionName), or of the metamodel that is read if none is given. \
        The documents apply after the metamodels are loaded, in command line order. What a \
        document cannot apply, such as a context that no metamodel declares, is reported on \
        standard error.
        """

    /// The paths of the Complete OCL documents, in command line order.
    @Option(
        name: .customLong(CompleteOCLOptions.optionName),
        help: ArgumentHelp(
            "A Complete OCL document that constrains the metamodels (can be specified multiple times)",
            discussion: CompleteOCLOptions.effect,
            valueName: CompleteOCLOptions.valueName))
    public var documents: [String] = []

    /// Creates the option with no documents.
    public init() {}

    /// Whether at least one document was given on the command line.
    public var isGiven: Bool { !documents.isEmpty }
}
