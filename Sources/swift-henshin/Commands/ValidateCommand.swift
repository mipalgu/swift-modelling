//
// ValidateCommand.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import EMFBase
import Henshin

/// The command that checks a module without applying it.
///
/// The command reports what the engine would reject or cannot interpret, Henshin's checks of
/// well-definedness, and what Henshin's clean-up operation would remove or repair, together
/// with the problems of reading a Henshin Text document.
struct ValidateCommand: AsyncParsableCommand {
    /// Shorthand for the value names.
    private typealias Placeholder = SwiftHenshinVocabulary.ValueName

    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: SwiftHenshinVocabulary.Command.validate,
        abstract: "Check a module, including Henshin's clean-up checks",
        discussion: """
            Reports, without applying anything, the problems of a module: what the engine \
            would reject or cannot interpret, such as expressions outside the supported \
            JavaScript subset; Henshin's checks of well-definedness, such as rules with the \
            same signature; and, as warnings, what Henshin's clean-up operation would remove or \
            repair, such as unused parameters, trivial conditions, and imports that no node \
            uses or that are missing. A .henshin_text document also reports its syntax and \
            translation errors with their lines and columns.

            Each finding is printed on standard output as a line that starts with error: or \
            warning: and ends with its code in brackets, followed by a summary line. \
            --verbose also prints informational findings.

            \(SwiftHenshinCommand.metamodelDiscussion)

            \(SwiftHenshinCommand.encodingDiscussion)

            Exit statuses: 0 if the module has no errors (warnings allowed), 1 if it has errors \
            or cannot be read, and 64 for an invalid command line.

            Examples:
              swift-henshin validate depot.henshin
              swift-henshin validate depot.henshin_text --metamodel Depot.ecore
            """
    )

    /// The module file.
    @Argument(help: ArgumentHelp("The module to check (.henshin or .henshin_text)", valueName: Placeholder.module))
    var module: String

    /// The options with which the module is read.
    @OptionGroup var moduleOptions: ModuleOptions

    /// Checks the module and prints its findings.
    ///
    /// - Throws: `ExitCode` 1 if the module has errors, and the errors of reading it.
    @MainActor
    func run() async throws {
        let loaded = try await moduleOptions.loader.read(module)
        let findings = Self.findings(of: loaded)
        for finding in findings where finding.severity != .information || moduleOptions.verbose {
            print(FindingFormatter.line(finding, file: module))
        }
        print(FindingFormatter.summary(findings, file: module))
        if findings.contains(where: { $0.severity == .error }) {
            throw ExitCode(SwiftHenshinVocabulary.ExitStatus.failure)
        }
    }

    /// The findings of a module.
    ///
    /// - Parameter loaded: The module as read.
    /// - Returns: The problems of reading a Henshin Text document and, if it has no errors,
    ///   the findings of the validator, with the metamodel packages for the checks of imports.
    static func findings(of loaded: LoadedModule) -> [SourceDiagnostic] {
        guard loaded.errors.isEmpty else { return loaded.diagnostics }
        return loaded.diagnostics + HenshinValidator.validate(loaded.module, metamodels: loaded.packages)
    }
}
