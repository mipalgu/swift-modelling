//
// MetamodelOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore

/// The command line option that names the Ecore metamodels of a model.
///
/// Each metamodel is registered with a resource set that the command's parsers and serialisers
/// use. With the metamodels, a model is read with the classes and data types they define, and
/// written with package-qualified classes and typed references. Without the option, classes
/// are inferred from the document itself.
///
/// Commands include the option with `@OptionGroup` and obtain the resource set from
/// ``resourceSet(verbose:)``.
public struct MetamodelOptions: ParsableArguments, Sendable {
    /// The long name of the option.
    public static let optionName = "metamodel"

    /// The short name of the option.
    public static let shortName: Character = "m"

    /// The name of the value of the option in the usage of a command.
    public static let valueName = "file.ecore"

    /// What the option does, as a paragraph for the help of the option and of a command.
    public static let effect = """
        The metamodel is registered under its namespace URI, so the model is read with the \
        classes and data types it defines and written with package-qualified classes and typed \
        references. Without a metamodel, classes are inferred from the document.
        """

    /// The paths of the Ecore metamodel files, in command line order.
    @Option(
        name: [.customShort(MetamodelOptions.shortName), .customLong(MetamodelOptions.optionName)],
        help: ArgumentHelp(
            "An Ecore metamodel of the model (can be specified multiple times)",
            discussion: MetamodelOptions.effect,
            valueName: MetamodelOptions.valueName))
    public var metamodels: [String] = []

    /// Creates the option with no metamodels.
    public init() {}

    /// Whether at least one metamodel was given on the command line.
    public var isGiven: Bool { !metamodels.isEmpty }

    /// Loads the metamodels given on the command line into a new resource set.
    ///
    /// - Parameter verbose: Whether to print progress to standard output.
    /// - Returns: A resource set with every metamodel registered, or `nil` if none was given.
    /// - Throws: ``MetamodelRegistrationError/fileNotFound(_:)`` if a file does not exist, or
    ///   the error of the parser if a file cannot be loaded.
    @MainActor
    public func resourceSet(verbose: Bool = false) async throws -> ResourceSet? {
        guard isGiven else { return nil }
        return try await MetamodelRegistration.resourceSet(registering: metamodels, verbose: verbose)
    }
}
