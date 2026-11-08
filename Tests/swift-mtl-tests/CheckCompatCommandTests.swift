//
// CheckCompatCommandTests.swift
// swift-mtl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@testable import swift_mtl

/// The fixtures of the compatibility checks: library templates and revisions of their metamodel.
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

    /// The arguments that check a template module written against the first library version.
    ///
    /// - Parameters:
    ///   - template: The fixture of the template module.
    ///   - target: The fixture of the library metamodel to check.
    ///   - extra: Further arguments.
    /// - Returns: The arguments after the command name.
    /// - Throws: `TestError.resourceNotFound` if a fixture does not exist.
    static func arguments(
        _ template: String = "catalogue.mtl", target: String = "LibraryV2.ecore", extra: [String] = []
    ) throws -> [String] {
        [
            try path(template),
            "--metamodel", "library=\(try path("LibraryV1.ecore"))",
            "--target-metamodel", "library=\(try path(target))",
        ] + extra
    }
}

/// The name of the command.
private let checkCompat = "check-compat"

@Suite("swift-mtl check-compat - options")
struct CheckCompatOptionTests {
    @Test("is named check-compat and registered")
    func name() {
        #expect(CheckCompatCommand.configuration.commandName == checkCompat)
        #expect(SwiftMTLCommand.configuration.subcommands.contains {
            ObjectIdentifier($0) == ObjectIdentifier(CheckCompatCommand.self)
        })
    }

    @Test("parses the template module, the metamodel and the options")
    func parses() throws {
        let command = try CheckCompatCommand.parse([
            "catalogue.mtl", "-m", "library=a.ecore", "--target-metamodel", "library=b.ecore",
            "--mode", "partial-isomorphic", "--subtyping", "steel-jezequel", "--allow-widening",
        ])
        #expect(command.template == "catalogue.mtl")
        #expect(command.compatibility.mode == .partialIsomorphic)
        #expect(command.compatibility.semantics == .objectTypeMatching)
        #expect(try command.compatibility.checkOptions().allowsNumericWidening)
    }

    @Test("checks a template module against one metamodel only")
    func singleMetamodel() {
        #expect(throws: (any Error).self) {
            try CheckCompatCommand.parse([
                "catalogue.mtl", "--metamodel", "library=a.ecore", "--metamodel", "shop=b.ecore",
                "--target-metamodel", "library=c.ecore",
            ])
        }
    }
}

@Suite("swift-mtl check-compat - end to end")
struct CheckCompatEndToEndTests {
    @Test("lists the command and documents its options and exit statuses")
    @MainActor
    func help() async throws {
        let overview = try await executeSwiftMTL(command: "--help")
        #expect(overview.succeeded)
        #expect(overview.stdout.contains(checkCompat))
        let help = try await executeSwiftMTL(command: checkCompat, arguments: ["--help"])
        #expect(help.succeeded)
        for text in [
            "<template>", "--metamodel <name=file>", "--target-metamodel <name=file>", "--mode <mode>",
            "--subtyping <subtyping>", "--rename <required=provided>", "--allow-widening",
            "--lenient-lower-bounds", "--format <format>", "--encoding", "Exit status", "one metamodel",
        ] {
            #expect(help.stdout.contains(text), "help lacks \(text)")
        }
    }

    @Test("accepts a refined extension of the metamodel with status 0")
    @MainActor
    func compatible() async throws {
        let result = try await executeSwiftMTL(
            command: checkCompat, arguments: try CompatFixture.arguments(target: "LibraryV1Refined.ecore"))
        #expect(result.exitCode == 0, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.hasPrefix("compatible (partial): 0 error(s), 0 warning(s)"))
    }

    @Test("rejects a revision with status 1 and suggests renamings")
    @MainActor
    func incompatible() async throws {
        let result = try await executeSwiftMTL(command: checkCompat, arguments: try CompatFixture.arguments())
        #expect(result.exitCode == 1)
        #expect(result.stdout.hasPrefix("incompatible (partial): 3 error(s), 1 warning(s)"))
        #expect(result.stdout.contains("error: library!Writer: provided metamodel has no class 'Writer'"))
        #expect(result.stdout.contains("hint: --rename Writer=Author"))
    }

    @Test("narrows the errors down with renamings, and keeps a widened read an error")
    @MainActor
    func renamingsAndWidening() async throws {
        let result = try await executeSwiftMTL(
            command: checkCompat,
            arguments: try CompatFixture.arguments(extra: ["--rename", "Writer=Author", "--allow-widening"]))
        #expect(result.exitCode == 1)
        let errors = result.stdout.split(separator: "\n").filter { $0.hasPrefix("error: ") }
        #expect(errors.count == 1)
        #expect(errors.first?.hasPrefix("error: library!Book.pages") == true)
        #expect(errors.first?.contains("when read") == true)
    }

    @Test("reports a verdict as inconclusive with status 2")
    @MainActor
    func inconclusive() async throws {
        let result = try await executeSwiftMTL(command: checkCompat, arguments: try CompatFixture.arguments("shelf.mtl"))
        #expect(result.exitCode == 2)
        #expect(result.stdout.hasPrefix("compatible (partial, inconclusive): 0 error(s), 1 warning(s)"))
        #expect(result.stdout.contains("uncertain: line 4: feature 'name' applied to an expression of unknown type"))
    }

    @Test("checks the whole metamodel in a total mode")
    @MainActor
    func totalMode() async throws {
        let partial = try await executeSwiftMTL(
            command: checkCompat,
            arguments: try CompatFixture.arguments(target: "LibraryV2.ecore", extra: ["--rename", "Writer=Author", "--allow-widening"]))
        let total = try await executeSwiftMTL(
            command: checkCompat,
            arguments: try CompatFixture.arguments(
                target: "LibraryV2.ecore", extra: ["--rename", "Writer=Author", "--allow-widening", "--mode", "total-non-isomorphic"]))
        #expect(total.exitCode == 1)
        #expect(total.stdout.hasPrefix("incompatible (totalNonIsomorphic)"))
        let partialErrors = partial.stdout.split(separator: "\n").filter { $0.hasPrefix("error: ") }
        let totalErrors = total.stdout.split(separator: "\n").filter { $0.hasPrefix("error: ") }
        #expect(totalErrors.count > partialErrors.count)
    }

    @Test("writes the report as JSON with its verdict")
    @MainActor
    func json() async throws {
        let result = try await executeSwiftMTL(
            command: checkCompat, arguments: try CompatFixture.arguments("shelf.mtl", extra: ["--format", "json"]))
        #expect(result.exitCode == 2)
        let object = try #require(try JSONSerialization.jsonObject(with: Data(result.stdout.utf8)) as? [String: Any])
        #expect(object["compatible"] as? Bool == true)
        #expect(object["conclusive"] as? Bool == false)
        #expect((object["diagnostics"] as? [Any])?.count == 1)
    }

    @Test("fails with status 3 when the check cannot be made")
    @MainActor
    func failures() async throws {
        var missing = try CompatFixture.arguments()
        missing[0] = "missing.mtl"
        let notFound = try await executeSwiftMTL(command: checkCompat, arguments: missing)
        #expect(notFound.exitCode == 3)
        #expect(notFound.stderr.contains("Error: File not found: missing.mtl"))

        var invalid = try CompatFixture.arguments()
        invalid[0] = try loadTestResource(named: "invalid-syntax.mtl", subdirectory: "templates").path
        let unparsable = try await executeSwiftMTL(command: checkCompat, arguments: invalid)
        #expect(unparsable.exitCode == 3)
        #expect(unparsable.stderr.contains("Error: "))
        #expect(unparsable.stdout.isEmpty)
    }

    @Test("fails with status 64 for invalid arguments")
    @MainActor
    func validation() async throws {
        let several = try await executeSwiftMTL(
            command: checkCompat,
            arguments: try CompatFixture.arguments(extra: ["--metamodel", "shop=\(try CompatFixture.path("LibraryV2.ecore"))"]))
        #expect(several.exitCode == 64)
        #expect(several.stderr.contains("Give one --metamodel, not several (library, shop)"))
        let mode = try await executeSwiftMTL(
            command: checkCompat, arguments: try CompatFixture.arguments(extra: ["--mode", "totalIsomorphic"]))
        #expect(mode.exitCode == 64)
    }
}
