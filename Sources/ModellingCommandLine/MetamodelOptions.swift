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
        The metamodel is a file in a metamodel format: \(MetamodelOptions.formatList), or an \
        EMOF document in an .xmi file. Every root package of the metamodel is \
        registered under its namespace URI, so the model is read with the classes and data types \
        it defines and written with package-qualified classes and typed references. A root \
        package without a namespace URI is loaded with a warning; it is registered under its \
        name if it comes from KM3, which has no namespaces. Without a metamodel, classes are \
        inferred from the document.
        """

    /// The formats in which a metamodel is read, as ``effect`` lists them.
    ///
    /// They are Ecore and JSON, followed by every other format whose built-in handler may hold
    /// a metamodel or converts its models into metamodels, such as UML, each named as
    /// `MetamodelRegistration.formatList(_:)` names it.
    public static let formatList: String = {
        let preferred: [ModelFormat] = [.ecore, .json]
        let others = ModelFormatRegistry.builtInHandlers
            .filter { $0.role != .model || $0 is any MetamodelConvertingModelFormatHandler }.compactMap(\.format)
        return MetamodelRegistration.formatList(preferred + others.filter { !preferred.contains($0) })
    }()

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
    /// Verbose output reports each registered metamodel; the trace of the XMI parser is
    /// printed only for debugging.
    ///
    /// - Parameters:
    ///   - verbose: Whether to print progress to standard output.
    ///   - debug: Whether the parser prints its trace of each metamodel document to standard output.
    ///   - options: The options with which the metamodels are read, such as those of KM3
    ///     (default options).
    /// - Returns: A resource set with every metamodel registered, or `nil` if none was given.
    /// - Throws: ``MetamodelRegistrationError/fileNotFound(_:)`` if a file does not exist, or
    ///   the error of the parser if a file cannot be loaded.
    @MainActor
    public func resourceSet(
        verbose: Bool = false, debug: Bool = false, options: EcoreLoadOptions = EcoreLoadOptions()
    ) async throws -> ResourceSet? {
        try await resourceSet(applying: [], verbose: verbose, debug: debug, options: options)
    }

    /// Loads the metamodels given on the command line into a new resource set and constrains
    /// them with Complete OCL documents.
    ///
    /// The documents apply to the metamodels together, in order, as
    /// `MetamodelRegistration.applyCompleteOCL(_:to:in:verbose:diagnosticOutput:)` describes.
    ///
    /// - Parameters:
    ///   - documents: The paths of the Complete OCL documents, such as those of ``CompleteOCLOptions``.
    ///   - verbose: Whether to print progress to standard output.
    ///   - debug: Whether the parser prints its trace of each metamodel document to standard output.
    ///   - options: The options with which the metamodels are read (default options).
    /// - Returns: A resource set with every metamodel registered and constrained, or `nil` if
    ///   no metamodel was given.
    /// - Throws: ``MetamodelRegistrationError/fileNotFound(_:)`` if a file does not exist, or
    ///   the error of the parser if a file cannot be loaded.
    @MainActor
    public func resourceSet(
        applying documents: [String], verbose: Bool = false, debug: Bool = false,
        options: EcoreLoadOptions = EcoreLoadOptions()
    ) async throws -> ResourceSet? {
        guard isGiven else { return nil }
        return try await MetamodelRegistration.resourceSet(
            registering: metamodels, applying: documents, verbose: verbose, debug: debug, options: options)
    }
}
