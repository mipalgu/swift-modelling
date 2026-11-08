//
// CheckCompatCommand.swift
// swift-mtl
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Foundation
import MTL
import ModelTyping
import ModellingCommandLine

/// The command that checks whether an MTL template module can be used with another metamodel.
///
/// The module is parsed with the modules it imports and extends, its footprint is extracted
/// against the metamodel that it was written against, and the target metamodel is checked
/// against that footprint for what the templates and queries read. The report is printed to
/// standard output, and the exit status tells the verdict (see
/// ``ModellingCommandLine/CompatibilityVerdict``).
struct CheckCompatCommand: AsyncParsableCommand {
    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: CompatibilityCheckOptions.commandName,
        abstract: "Check whether a template module can be used with another metamodel",
        discussion: """
            \(CompatibilityCheckOptions.discussion(module: "the template module"))

            A template module is checked against one metamodel. The name of \
            --\(CompatibilityCheckOptions.OptionName.metamodel) is the name under which the \
            findings refer to it, conventionally the name of its package, which also qualifies \
            the types of the module, such as library in library::Book. The modules that the \
            module imports or extends are checked with it.

            \(SourceEncodingOptions.discussion(reader: "the template module and the modules it imports", configurable: false))

            Examples:
                swift-mtl check-compat catalogue.mtl \\
                    --metamodel library=Library.ecore \\
                    --target-metamodel library=LibraryV2.ecore
                swift-mtl check-compat catalogue.mtl \\
                    --metamodel library=Library.ecore \\
                    --target-metamodel library=LibraryV2.ecore \\
                    --rename Writer=Author --rename Book.isbn=ISBN --allow-widening
                swift-mtl check-compat catalogue.mtl \\
                    --metamodel library=Library.ecore \\
                    --target-metamodel library=LibraryV2.ecore \\
                    --mode total-non-isomorphic --format json
            """
    )

    /// The template module to check.
    @Argument(help: "The MTL template module to check")
    var template: String

    /// The metamodel, the mode and the options of the check.
    @OptionGroup(title: "Compatibility")
    var compatibility: CompatibilityCheckOptions

    /// The character encoding of the template module and the modules it imports.
    @OptionGroup var encodingOptions: SourceEncodingOptions

    /// Checks that the command line names one metamodel.
    ///
    /// - Throws: A validation error if several metamodels are given.
    func validate() throws {
        try compatibility.validateSingleMetamodel()
    }

    /// Checks the template module and prints the report.
    ///
    /// - Throws: `ExitCode` with the status of the verdict unless it is compatible, or with
    ///   ``ModellingCommandLine/CompatibilityVerdict/failureExitStatus`` if the module or the
    ///   metamodels cannot be read.
    @MainActor
    func run() async throws {
        try await compatibility.run { metamodels in
            let sole = try metamodels.requireSole()
            try CompatibilityCheckOptions.requireModule(at: template)
            let parser = MTLParser(enableDebugging: false, encoding: encodingOptions.explicitEncoding)
            let module = try await parser.parseReportingWarnings(URL(fileURLWithPath: template))
            return ReuseChecker.check(
                mtl: module, metamodelName: sole.name, required: sole.required, provided: sole.provided,
                mode: compatibility.mode, options: try compatibility.checkOptions())
        }
    }
}
