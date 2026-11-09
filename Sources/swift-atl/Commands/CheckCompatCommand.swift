//
// CheckCompatCommand.swift
// swift-atl
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ArgumentParser
import Foundation
import ModelTyping
import ModellingCommandLine

/// The command that checks whether an ATL transformation can be used with other metamodels.
///
/// The transformation is parsed, its footprint is extracted against the metamodels that it was
/// written against, and the target metamodels are checked against that footprint. Source
/// metamodels are checked for what the transformation reads, target metamodels for what it
/// creates and writes. The report is printed to standard output, and the exit status tells
/// the verdict (see ``ModellingCommandLine/CompatibilityVerdict``).
struct CheckCompatCommand: AsyncParsableCommand {
    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: CompatibilityCheckOptions.commandName,
        abstract: "Check whether a transformation can be used with other metamodels",
        discussion: """
            \(CompatibilityCheckOptions.discussion(module: "the transformation"))

            Each --\(CompatibilityCheckOptions.OptionName.metamodel) is named after a \
            metamodel of the module header, such as Families in IN : Families. The metamodels \
            of source models are checked for what the transformation reads, and those of \
            target models for what it creates and writes. A metamodel of the header without \
            --\(CompatibilityCheckOptions.OptionName.metamodel) is not checked, which makes the \
            verdict inconclusive.

            \(SourceEncodingOptions.discussion(reader: "the transformation", configurable: false))

            Examples:
                swift-atl check-compat Families2Persons.atl \\
                    --metamodel Families=Families.ecore \\
                    --metamodel Persons=Persons.ecore \\
                    --target-metamodel Families=FamiliesV2.ecore
                swift-atl check-compat Families2Persons.atl \\
                    --metamodel Families=Families.ecore \\
                    --metamodel Persons=Persons.ecore \\
                    --target-metamodel Families=FamiliesV2.ecore \\
                    --rename Member.firstName=givenName
                swift-atl check-compat Families2Persons.atl \\
                    --metamodel Families=Families.ecore \\
                    --metamodel Persons=Persons.ecore \\
                    --target-metamodel Persons=PersonsV2.ecore \\
                    --mode total-isomorphic --subtyping mof-class-matching --format json
            """
    )

    /// The ATL transformation to check.
    @Argument(help: "The ATL transformation to check")
    var atlFile: String

    /// The metamodels, the mode and the options of the check.
    @OptionGroup(title: "Compatibility")
    var compatibility: CompatibilityCheckOptions

    /// The character encoding of the ATL source.
    @OptionGroup var encodingOptions: SourceEncodingOptions

    /// Parses the transformation.
    ///
    /// The transformation is read in the encoding that `--encoding` names, or as UTF-8 with a
    /// fallback to ISO-8859-1, and parsed with the behaviours of this release.
    ///
    /// - Returns: The module.
    /// - Throws: ``ModellingCommandLine/CompatibilityCheckError/moduleNotFound(_:)`` if the file
    ///   does not exist, or the error of the file system or of the parser.
    func module() async throws -> ATLModule {
        try CompatibilityCheckOptions.requireModule(at: atlFile)
        let source = try SourceFile.text(at: atlFile, encoding: encodingOptions.explicitEncoding)
        return try await ATLParser(options: .standard).parseContent(
            source, filename: URL(fileURLWithPath: atlFile).lastPathComponent)
    }

    /// Checks the transformation and prints the report.
    ///
    /// - Throws: `ExitCode` with the status of the verdict unless it is compatible, or with
    ///   ``ModellingCommandLine/CompatibilityVerdict/failureExitStatus`` if the transformation
    ///   or a metamodel cannot be read, or a metamodel is not one of the module header.
    func run() async throws {
        try await compatibility.run(encoding: encodingOptions.explicitEncoding) { metamodels in
            let module = try await module()
            try metamodels.requireDeclared(in: ATLFootprintExtractor.roles(of: module).keys)
            return ReuseChecker.check(
                atl: module, required: metamodels.required, provided: metamodels.provided,
                mode: compatibility.mode, options: try compatibility.checkOptions())
        }
    }
}
