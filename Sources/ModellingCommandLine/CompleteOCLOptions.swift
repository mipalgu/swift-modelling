//
// CompleteOCLOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Foundation

/// The command line option that names Complete OCL documents to apply to the metamodels.
///
/// A Complete OCL document (`.ocl`) adds invariants, pre- and postconditions, definitions and
/// derivations to the classes and features of metamodels that are defined elsewhere. Each
/// document is applied after the metamodels are loaded, in command line order, so that the
/// constraints become part of the metamodels: the `validate` command checks the invariants,
/// and a metamodel that is written afterwards carries them as OCL annotations.
///
/// The option may also name a directory, which stands for every Complete OCL document directly
/// in it (not in its subdirectories), in the order of their names. The configuration file may
/// list documents and directories too, under the key ``optionName``, relative to the directory
/// of the file; documents given on the command line replace those of the file.
///
/// Commands include the option with `@OptionGroup` and pass ``documents`` or
/// ``documents(settings:warning:)`` to
/// `MetamodelOptions.resourceSet(applying:verbose:debug:options:)` or to
/// `MetamodelRegistration.applyCompleteOCL(_:to:in:verbose:diagnosticOutput:)`.
public struct CompleteOCLOptions: ParsableArguments, Sendable {
    /// The long name of the option.
    public static let optionName = "ocl"

    /// The extension of a Complete OCL document, which selects the documents of a directory.
    public static let fileExtension = "ocl"

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
            "A Complete OCL document, or a directory of them, that constrains the metamodels (can be specified multiple times)",
            discussion: CompleteOCLOptions.effect,
            valueName: CompleteOCLOptions.valueName))
    public var documents: [String] = []

    /// Creates the option with no documents.
    public init() {}

    /// Whether at least one document was given on the command line.
    public var isGiven: Bool { !documents.isEmpty }

    /// The documents that apply to a run, with each directory replaced by its documents.
    ///
    /// The documents given on the command line apply, else those of the `ocl` key of the
    /// configuration file. A path that names a directory stands for the files with the
    /// extension ``fileExtension`` directly in it, sorted by name; a directory without one is
    /// reported as a warning and contributes nothing. Any other path is kept as given, so a
    /// missing document is reported where it is read.
    ///
    /// - Parameters:
    ///   - settings: The settings of the run, whose configuration file is consulted.
    ///   - warning: Receives the message of each warning (default: writes it to standard error).
    /// - Returns: The paths of the documents, in the order in which they apply.
    public func documents(
        settings: SemanticsSettings,
        warning: (String) -> Void = { StandardStreams.writeToStandardError($0 + "\n") }
    ) -> [String] {
        let given = isGiven ? documents : settings.configuration.completeOCLDocuments ?? []
        return given.flatMap { Self.expand($0, warning: warning) }
    }

    /// The documents that a path stands for.
    ///
    /// - Parameters:
    ///   - path: A path of a document or a directory.
    ///   - warning: Receives the message of a warning about an empty directory.
    /// - Returns: The path itself, or the documents directly in the directory, sorted by name.
    static func expand(_ path: String, warning: (String) -> Void) -> [String] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return [path]
        }
        let names = (try? FileManager.default.contentsOfDirectory(atPath: path)) ?? []
        let documents = names.filter { name in
            guard (name as NSString).pathExtension.lowercased() == fileExtension else { return false }
            var nested: ObjCBool = false
            let file = (path as NSString).appendingPathComponent(name)
            return FileManager.default.fileExists(atPath: file, isDirectory: &nested) && !nested.boolValue
        }.sorted().map { (path as NSString).appendingPathComponent($0) }
        if documents.isEmpty {
            warning("warning: \(path): The directory holds no Complete OCL documents (.\(fileExtension))")
        }
        return documents
    }
}
