//
// CheckCompatCommandTests.swift
// swift-atl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Foundation
import Testing

@testable import swift_atl

/// The fixtures of the compatibility checks: the families to persons transformation and
/// revisions of its metamodels.
private enum CompatFixture {
    /// The directory of the fixtures within the resources of the tests.
    static let directory = "compat"

    /// The location of a fixture.
    ///
    /// - Parameter name: The name of the file.
    /// - Returns: Its path.
    /// - Throws: `TestError.resourceNotFound` if it does not exist.
    static func path(_ name: String) throws -> String {
        try loadTestResource(named: name, subdirectory: directory).path
    }

    /// The arguments that check the transformation with its original metamodels and targets.
    ///
    /// - Parameters:
    ///   - families: The fixture of the families metamodel to check, or `nil` for none.
    ///   - persons: The fixture of the persons metamodel to check, or `nil` for none.
    ///   - extra: Further arguments.
    /// - Returns: The arguments after the command name.
    /// - Throws: `TestError.resourceNotFound` if a fixture does not exist.
    static func arguments(
        families: String? = "Families.ecore", persons: String? = "Persons.ecore", _ extra: [String] = []
    ) throws -> [String] {
        var arguments = [
            try path("Families2Persons.atl"),
            "--metamodel", "Families=\(try path("Families.ecore"))",
            "--metamodel", "Persons=\(try path("Persons.ecore"))",
        ]
        if let families { arguments += ["--target-metamodel", "Families=\(try path(families))"] }
        if let persons { arguments += ["--target-metamodel", "Persons=\(try path(persons))"] }
        return arguments + extra
    }
}

/// The name of the command.
private let checkCompat = "check-compat"

@Suite("swift-atl check-compat - options")
struct CheckCompatOptionTests {
    @Test("is named check-compat")
    func name() {
        #expect(CheckCompatCommand.configuration.commandName == checkCompat)
        #expect(SwiftATLCommand.configuration.subcommands.contains { ObjectIdentifier($0) == ObjectIdentifier(CheckCompatCommand.self) })
    }

    @Test("parses the transformation, metamodels and defaults")
    func parsesDefaults() throws {
        let command = try CheckCompatCommand.parse([
            "f.atl", "--metamodel", "Families=a.ecore", "--target-metamodel", "Families=b.ecore",
        ])
        #expect(command.atlFile == "f.atl")
        #expect(command.compatibility.mode == .partial)
        #expect(command.compatibility.semantics == .accessRefined)
        #expect(command.compatibility.format == .text)
        #expect(try command.compatibility.requiredMetamodelFiles() == ["Families": "a.ecore"])
    }

    @Test("rejects incomplete or malformed arguments", arguments: [
        ["f.atl", "--metamodel", "Families=a.ecore"],
        ["f.atl", "--target-metamodel", "Families=b.ecore"],
        ["f.atl", "--metamodel", "a.ecore", "--target-metamodel", "Families=b.ecore"],
        ["f.atl", "--metamodel", "Families=a.ecore", "--target-metamodel", "Persons=b.ecore"],
        ["f.atl", "--metamodel", "Families=a.ecore", "--target-metamodel", "Families=b.ecore", "--rename", "x"],
        ["f.atl", "--metamodel", "Families=a.ecore", "--target-metamodel", "Families=b.ecore", "--mode", "total"],
        ["--metamodel", "Families=a.ecore", "--target-metamodel", "Families=b.ecore"],
    ])
    func rejects(arguments: [String]) {
        #expect(throws: (any Error).self) { try CheckCompatCommand.parse(arguments) }
    }

    @Test("parses the transformation that it checks")
    func parsesModule() async throws {
        let command = try CheckCompatCommand.parse(try CompatFixture.arguments())
        let module = try await command.module()
        #expect(module.name == "Families2Persons")
    }
}

@Suite("swift-atl check-compat - end to end")
struct CheckCompatEndToEndTests {
    @Test("lists the command and documents its options and exit statuses")
    @MainActor
    func help() async throws {
        let overview = try await executeSwiftATL(command: "--help")
        #expect(overview.succeeded)
        #expect(overview.stdout.contains(checkCompat))
        let help = try await executeSwiftATL(command: checkCompat, arguments: ["--help"])
        #expect(help.succeeded)
        for text in [
            "--metamodel <name=file>", "--target-metamodel <name=file>", "--mode <mode>", "total-isomorphic",
            "total-non-isomorphic", "partial-isomorphic", "--subtyping <subtyping>", "access-refined",
            "object-type-matching", "mof-class-matching", "steel-jezequel", "guy", "--rename <required=provided>",
            "--allow-widening", "--lenient-lower-bounds", "--format <format>", "--encoding",
            "Exit status", "default: partial", "default: access-refined",
        ] {
            #expect(help.stdout.contains(text), "help lacks \(text)")
        }
        #expect(!help.stdout.contains("--semantics"))
        #expect(!help.stdout.contains("\u{2014}"))
    }

    @Test("accepts the original metamodels with status 0")
    @MainActor
    func compatible() async throws {
        let result = try await executeSwiftATL(command: checkCompat, arguments: try CompatFixture.arguments())
        #expect(result.exitCode == 0, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.hasPrefix("compatible (partial): 0 error(s), 0 warning(s)"))
    }

    @Test("rejects a renamed source feature with status 1 and a hint, and accepts the renaming")
    @MainActor
    func renamedSource() async throws {
        let rejected = try await executeSwiftATL(
            command: checkCompat, arguments: try CompatFixture.arguments(families: "FamiliesV2.ecore"))
        #expect(rejected.exitCode == 1)
        #expect(rejected.stdout.hasPrefix("incompatible (partial): 1 error(s)"))
        #expect(rejected.stdout.contains("error: Families!Member.firstName"))
        #expect(rejected.stdout.contains("hint: --rename Member.firstName=givenName"))
        let renamed = try await executeSwiftATL(
            command: checkCompat,
            arguments: try CompatFixture.arguments(families: "FamiliesV2.ecore", ["--rename", "Member.firstName=givenName"]))
        #expect(renamed.exitCode == 0, "\(renamed.stdout)")
    }

    @Test("rejects target changes that break the output and accepts benign additions with warnings")
    @MainActor
    func targetRevisions() async throws {
        let broken = try await executeSwiftATL(
            command: checkCompat, arguments: try CompatFixture.arguments(persons: "PersonsV2.ecore"))
        #expect(broken.exitCode == 1)
        #expect(broken.stdout.contains("[abstractInstantiation]"))
        #expect(broken.stdout.contains("[featureNotChangeable]"))
        let extended = try await executeSwiftATL(
            command: checkCompat, arguments: try CompatFixture.arguments(persons: "PersonsV3.ecore"))
        #expect(extended.exitCode == 0)
        #expect(extended.stdout.hasPrefix("compatible (partial): 0 error(s), 2 warning(s)"))
    }

    @Test("leaves a metamodel without a target unchanged")
    @MainActor
    func unchangedMetamodel() async throws {
        let result = try await executeSwiftATL(
            command: checkCompat, arguments: try CompatFixture.arguments(families: nil, persons: "PersonsV3.ecore"))
        #expect(result.exitCode == 0)
    }

    @Test("reports a verdict as inconclusive with status 2 when a header metamodel is not given")
    @MainActor
    func inconclusive() async throws {
        let result = try await executeSwiftATL(command: checkCompat, arguments: [
            try CompatFixture.path("Families2Persons.atl"),
            "--metamodel", "Families=\(try CompatFixture.path("Families.ecore"))",
            "--target-metamodel", "Families=\(try CompatFixture.path("Families.ecore"))",
        ])
        #expect(result.exitCode == 2)
        #expect(result.stdout.hasPrefix("compatible (partial, inconclusive)"))
        #expect(result.stdout.contains("uncertain: line 2: no model type was given for metamodel 'Persons'"))
    }

    @Test("ignores renamings in isomorphic modes")
    @MainActor
    func isomorphicMode() async throws {
        let result = try await executeSwiftATL(command: checkCompat, arguments: try CompatFixture.arguments(
            families: "FamiliesV2.ecore", persons: "PersonsV3.ecore",
            ["--mode", "total-isomorphic", "--rename", "Member.firstName=givenName"]))
        #expect(result.exitCode == 1)
        #expect(result.stdout.contains("error: Families!Member.firstName"))
    }

    @Test("applies the published MOF class matching by name and by alias")
    @MainActor
    func publishedSemantics() async throws {
        for semantics in ["mof-class-matching", "guy"] {
            let result = try await executeSwiftATL(command: checkCompat, arguments: try CompatFixture.arguments(
                families: "FamiliesV2.ecore", persons: "PersonsV3.ecore",
                ["--mode", "total-non-isomorphic", "--rename", "Member.firstName=givenName", "--subtyping", semantics]))
            #expect(result.exitCode == 1)
            let errors = result.stdout.components(separatedBy: consoleText("\n")).filter { $0.hasPrefix("error: ") }
            #expect(errors.count == 1)
            #expect(errors.first?.hasPrefix("error: Persons!Person.registration") == true)
        }
    }

    @Test("writes the report as JSON with its verdict")
    @MainActor
    func json() async throws {
        let result = try await executeSwiftATL(
            command: checkCompat,
            arguments: try CompatFixture.arguments(families: "FamiliesV2.ecore", ["--format", "json"]))
        #expect(result.exitCode == 1)
        let object = try #require(try JSONSerialization.jsonObject(with: Data(result.stdout.utf8)) as? [String: Any])
        #expect(object["compatible"] as? Bool == false)
        #expect(object["conclusive"] as? Bool == true)
        #expect(object["mode"] as? String == "partial")
        let diagnostics = try #require(object["diagnostics"] as? [[String: Any]])
        #expect(diagnostics.first?["code"] as? String == "missingFeature")
        #expect(object["footprint"] != nil)
        #expect((object["renamingHints"] as? [Any])?.count == 1)
    }

    @Test("reads the transformation in the encoding given, or warns when it falls back")
    @MainActor
    func encoding() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let source = try String(contentsOfFile: try CompatFixture.path("Families2Persons.atl"), encoding: .utf8)
        let latin1 = directory.appendingPathComponent("Latin1.atl")
        try #require(("-- Familles \u{E9}tendues\n" + source).data(using: .isoLatin1)).write(to: latin1)
        var arguments = try CompatFixture.arguments()
        arguments[0] = latin1.path
        let detected = try await executeSwiftATL(command: checkCompat, arguments: arguments)
        #expect(detected.exitCode == 0)
        #expect(detected.stderr.contains("ISO-8859-1"))
        let explicit = try await executeSwiftATL(command: checkCompat, arguments: arguments + ["--encoding", "latin1"])
        #expect(explicit.exitCode == 0)
        #expect(explicit.stderr.isEmpty)
    }

    @Test("fails with status 3 when the check cannot be made")
    @MainActor
    func failures() async throws {
        var missing = try CompatFixture.arguments()
        missing[0] = "missing.atl"
        let notFound = try await executeSwiftATL(command: checkCompat, arguments: missing)
        #expect(notFound.exitCode == 3)
        #expect(notFound.stderr.contains("Error: File not found: missing.atl"))
        #expect(notFound.stdout.isEmpty)

        let invalid = try await executeSwiftATL(command: checkCompat, arguments: [
            try loadTestResource(named: "invalid-syntax.atl", subdirectory: "atl").path,
            "--metamodel", "Families=\(try CompatFixture.path("Families.ecore"))",
            "--target-metamodel", "Families=\(try CompatFixture.path("Families.ecore"))",
        ])
        #expect(invalid.exitCode == 3)
        #expect(invalid.stderr.hasPrefix("Error: "))

        let undeclared = try await executeSwiftATL(command: checkCompat, arguments: [
            try CompatFixture.path("Families2Persons.atl"),
            "--metamodel", "People=\(try CompatFixture.path("Persons.ecore"))",
            "--target-metamodel", "People=\(try CompatFixture.path("PersonsV3.ecore"))",
        ])
        #expect(undeclared.exitCode == 3)
        #expect(undeclared.stderr.contains("declares no metamodel named People (it declares: Families, Persons)"))

        let noMetamodel = try await executeSwiftATL(command: checkCompat, arguments: [
            try CompatFixture.path("Families2Persons.atl"),
            "--metamodel", "Families=missing.ecore", "--target-metamodel", "Families=missing.ecore",
        ])
        #expect(noMetamodel.exitCode == 3)
        #expect(noMetamodel.stderr.contains("missing.ecore"))
    }

    @Test("fails with status 64 for invalid arguments")
    @MainActor
    func validation() async throws {
        let unmatched = try await executeSwiftATL(command: checkCompat, arguments: [
            try CompatFixture.path("Families2Persons.atl"),
            "--metamodel", "Families=\(try CompatFixture.path("Families.ecore"))",
            "--target-metamodel", "Persons=\(try CompatFixture.path("Persons.ecore"))",
        ])
        #expect(unmatched.exitCode == ExitCode.validationFailure.rawValue)
        #expect(unmatched.stderr.contains("--target-metamodel names 'Persons', which no --metamodel names"))
        let rename = try await executeSwiftATL(
            command: checkCompat, arguments: try CompatFixture.arguments(["--rename", "Member.firstName"]))
        #expect(rename.exitCode == ExitCode.validationFailure.rawValue)
        #expect(rename.stderr.contains("Invalid renaming 'Member.firstName'"))
        let semantics = try await executeSwiftATL(
            command: checkCompat, arguments: try CompatFixture.arguments(["--semantics", "legacy"]))
        #expect(semantics.exitCode == ExitCode.validationFailure.rawValue)
    }
}
