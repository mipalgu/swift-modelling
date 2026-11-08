//
// CheckCompatCommandTests.swift
// swift-aql-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import Foundation
import ModellingCommandLine
import Testing

@testable import swift_aql

/// The fixtures of the compatibility checks: two versions of a library metamodel and an
/// expression file.
private enum CompatFixture {
    /// The directory of the fixtures, relative to the resources of the tests.
    static let directory = "compat"

    /// The location of a fixture.
    ///
    /// The bundle is asked for the file first, and the layouts in which a copied resource
    /// directory can appear are then tried in turn, as for the shop fixture.
    ///
    /// - Parameter name: The name of the file.
    /// - Returns: Its path.
    /// - Throws: ``SwiftAQLTestError/fixtureNotFound(_:)`` if the file does not exist.
    static func path(_ name: String) throws -> String {
        let bundle = Bundle.module
        let subdirectory = Fixture.resourcesDirectory + "/" + directory
        if let url = bundle.url(forResource: name, withExtension: nil, subdirectory: subdirectory) {
            return url.path
        }
        let roots = [bundle.resourceURL, bundle.bundleURL, bundle.bundleURL.appendingPathComponent("Contents/Resources")]
        let candidates = roots.compactMap { $0?.appendingPathComponent(subdirectory).appendingPathComponent(name) }
        if let url = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
            return url.path
        }
        throw SwiftAQLTestError.fixtureNotFound(name)
    }

    /// The arguments that check an expression on `self : library::Library`.
    ///
    /// - Parameters:
    ///   - expression: The expression.
    ///   - required: The path of the metamodel the expression was written against, or `nil`
    ///     for the first library version.
    ///   - target: The path of the metamodel to check, or `nil` for the second library version.
    ///   - extra: Further arguments.
    /// - Returns: The arguments after the command name.
    /// - Throws: ``SwiftAQLTestError/fixtureNotFound(_:)`` if a fixture does not exist.
    static func arguments(
        _ expression: String, required: String? = nil, target: String? = nil, _ extra: [String] = []
    ) throws -> [String] {
        [
            "-e", expression, "--variable", "self=library::Library",
            "--metamodel", "library=\(try required ?? path("LibraryV1.ecore"))",
            "--target-metamodel", "library=\(try target ?? path("LibraryV2.ecore"))",
        ] + extra
    }
}

/// The name of the command.
private let checkCompat = SwiftAQLVocabulary.Command.checkCompat

@Suite("swift-aql check-compat - options")
struct CheckCompatOptionTests {
    @Test("is named check-compat and registered")
    func name() {
        #expect(checkCompat == "check-compat")
        #expect(CheckCompatCommand.configuration.commandName == checkCompat)
        #expect(SwiftAQLCommand.configuration.subcommands.contains {
            ObjectIdentifier($0) == ObjectIdentifier(CheckCompatCommand.self)
        })
        #expect(SwiftAQLVocabulary.OptionName.variable == "variable")
    }

    @Test("reads the expression, the types of the variables and the options")
    func parses() throws {
        let command = try CheckCompatCommand.parse([
            "-e", "self.books", "--variable", "self=library::Library", "--variable", "books=Sequence(library::Book)",
            "--metamodel", "library=a.ecore", "--target-metamodel", "library=b.ecore", "--mode", "total-isomorphic",
            "--lenient-lower-bounds", "--format", "json",
        ])
        #expect(command.source == .text("self.books"))
        #expect(try command.variableTypes() == ["self": "library::Library", "books": "Sequence(library::Book)"])
        #expect(command.compatibility.mode == .totalIsomorphic)
        #expect(command.compatibility.format == .json)
        #expect(try command.compatibility.checkOptions().lenientLowerBounds)
        _ = try command.parsedExpression()
    }

    @Test("reads an expression file")
    func parsesFile() throws {
        let command = try CheckCompatCommand.parse([
            "-f", try CompatFixture.path("titles.aql"), "--metamodel", "library=a.ecore",
            "--target-metamodel", "library=b.ecore",
        ])
        #expect(try command.variableTypes().isEmpty)
        _ = try command.parsedExpression()
    }

    @Test("rejects an invalid expression")
    func invalidExpression() throws {
        let command = try CheckCompatCommand.parse([
            "-e", "self.books->(", "--metamodel", "library=a.ecore", "--target-metamodel", "library=b.ecore",
        ])
        #expect(throws: SwiftAQLError.self) { try command.parsedExpression() }
    }

    @Test("rejects incomplete or malformed arguments", arguments: [
        ["--metamodel", "library=a.ecore", "--target-metamodel", "library=b.ecore"],
        ["-e", "self", "-f", "x.aql", "--metamodel", "library=a.ecore", "--target-metamodel", "library=b.ecore"],
        ["-e", "self", "--variable", "self", "--metamodel", "library=a.ecore", "--target-metamodel", "library=b.ecore"],
        ["-e", "self", "--variable", "self=", "--metamodel", "library=a.ecore", "--target-metamodel", "library=b.ecore"],
        ["-e", "self", "--metamodel", "library=a.ecore", "--metamodel", "shop=c.ecore",
         "--target-metamodel", "library=b.ecore"],
        ["-e", "self", "--metamodel", "library=a.ecore"],
    ])
    func rejects(arguments: [String]) {
        #expect(throws: (any Error).self) { try CheckCompatCommand.parse(arguments) }
    }
}

@Suite("swift-aql check-compat - end to end")
struct CheckCompatEndToEndTests {
    @Test("lists the command and documents its options and exit statuses")
    func help() async throws {
        let overview = try await runSwiftAQL(["--help"])
        #expect(overview.succeeded)
        #expect(overview.output.contains(checkCompat))
        let help = try await runSwiftAQL([checkCompat, "--help"])
        #expect(help.succeeded)
        for text in [
            "-e, --expression <expression>", "-f, --expression-file <file.aql>", "--variable <name=type>",
            "--metamodel <name=file>", "--target-metamodel <name=file>", "--mode <mode>", "--subtyping <subtyping>",
            "--rename <required=provided>", "--allow-widening", "--lenient-lower-bounds", "--format <format>",
            "--encoding", "Exit status", "inconclusive",
        ] {
            #expect(help.output.contains(text), "help lacks \(text)")
        }
    }

    @Test("accepts an expression whose uses the target metamodel keeps, with status 0")
    func compatible() async throws {
        let result = try await runSwiftAQL([checkCompat] + (try CompatFixture.arguments("self.books->collect(b | b.title)")))
        #expect(result.status == 0, "\(result.output)\(result.error)")
        #expect(result.output == "compatible (partial): 0 error(s), 0 warning(s)\n")
    }

    @Test("checks an expression read from a file")
    func expressionFile() async throws {
        var arguments = try CompatFixture.arguments("")
        arguments.replaceSubrange(0..<2, with: ["--expression-file", try CompatFixture.path("titles.aql")])
        let result = try await runSwiftAQL([checkCompat] + arguments)
        #expect(result.status == 0, "\(result.output)\(result.error)")
    }

    @Test("rejects a widened read with status 1")
    func incompatible() async throws {
        let result = try await runSwiftAQL(
            [checkCompat] + (try CompatFixture.arguments("self.books->select(b | b.pages > 100).title")))
        #expect(result.status == 1)
        #expect(result.output.contains("error: library!Book.pages"))
    }

    @Test("reports a verdict as inconclusive with status 2")
    func inconclusive() async throws {
        let result = try await runSwiftAQL([checkCompat] + (try CompatFixture.arguments("self.eContainer().name")))
        #expect(result.status == 2)
        #expect(result.output.hasPrefix("compatible (partial, inconclusive): 0 error(s), 1 warning(s)"))
        #expect(result.output.contains("hint: --rename Writer=Author"))
    }

    @Test("checks the whole metamodel in a total mode")
    func totalMode() async throws {
        let source = "self.books->collect(b | b.title)"
        let result = try await runSwiftAQL(
            [checkCompat] + (try CompatFixture.arguments(source, ["--mode", "total-non-isomorphic"])))
        #expect(result.status == 1)
    }

    @Test("accepts a narrowed read only with renamings and widening")
    func renamingsAndWidening() async throws {
        let source = "self.writers->collect(w | w.born)"
        let missing = try await runSwiftAQL([checkCompat] + (try CompatFixture.arguments(source)))
        #expect(missing.status == 1)
        #expect(missing.output.contains("hint: --rename Writer=Author"))
        let renamed = try await runSwiftAQL([checkCompat] + (try CompatFixture.arguments(
            source, ["--rename", "Writer=Author", "--rename", "Library.writers=authors"])))
        #expect(renamed.status == 1)
        #expect(renamed.output.contains("numeric widening is off"))
        let widened = try await runSwiftAQL([checkCompat] + (try CompatFixture.arguments(
            source, ["--rename", "Writer=Author,Library.writers=authors", "--allow-widening"])))
        #expect(widened.status == 0, "\(widened.output)")
    }

    @Test("ignores renamings in isomorphic modes")
    func isomorphic() async throws {
        let result = try await runSwiftAQL([checkCompat] + (try CompatFixture.arguments(
            "self.writers->collect(w | w.born)",
            ["--rename", "Writer=Author,Library.writers=authors", "--allow-widening", "--mode", "partial-isomorphic"])))
        #expect(result.status == 1)
    }

    @Test("reports a weaker lower bound as an error, or as a warning when lenient")
    func lenientLowerBounds() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let original = try String(contentsOfFile: try CompatFixture.path("LibraryV1.ecore"), encoding: .utf8)
        let optionalName = original.replacingOccurrences(of: "name=\"name\" lowerBound=\"1\"", with: "name=\"name\"")
        #expect(optionalName != original)
        let target = directory.appendingPathComponent("LibraryOptionalName.ecore")
        try optionalName.write(to: target, atomically: true, encoding: .utf8)
        let strict = try await runSwiftAQL([checkCompat] + (try CompatFixture.arguments("self.name", target: target.path)))
        #expect(strict.status == 1)
        #expect(strict.output.contains("[multiplicityMismatch]"))
        let lenient = try await runSwiftAQL([checkCompat] + (try CompatFixture.arguments(
            "self.name", target: target.path, ["--lenient-lower-bounds"])))
        #expect(lenient.status == 0)
        #expect(lenient.output.contains("warning: library!Library.name"))
    }

    @Test("applies each matching semantics")
    func semantics() async throws {
        for semantics in MatchingSemanticsSpelling.all {
            let result = try await runSwiftAQL([checkCompat] + (try CompatFixture.arguments(
                "self.books->collect(b | b.title)", ["--subtyping", semantics])))
            #expect([0, 1].contains(result.status), "\(semantics): \(result.error)")
        }
        let invalid = try await runSwiftAQL([checkCompat] + (try CompatFixture.arguments(
            "self.books", ["--subtyping", "standard"])))
        #expect(invalid.status == 64)
        let preset = try await runSwiftAQL([checkCompat] + (try CompatFixture.arguments(
            "self.books", ["--semantics", "access-refined"])))
        #expect(preset.status == 64)
    }

    @Test("writes the report as JSON with its verdict")
    func json() async throws {
        let result = try await runSwiftAQL(
            [checkCompat] + (try CompatFixture.arguments("self.eContainer().name", ["--format", "json"])))
        #expect(result.status == 2)
        let object = try #require(try JSONSerialization.jsonObject(with: Data(result.output.utf8)) as? [String: Any])
        #expect(object["compatible"] as? Bool == true)
        #expect(object["conclusive"] as? Bool == false)
        let footprint = try #require(object["footprint"] as? [String: Any])
        #expect((footprint["uncertainties"] as? [Any])?.isEmpty == false)
    }

    @Test("fails with status 3 when the check cannot be made")
    func failures() async throws {
        var missing = try CompatFixture.arguments("")
        missing.replaceSubrange(0..<2, with: ["-f", "missing.aql"])
        let notFound = try await runSwiftAQL([checkCompat] + missing)
        #expect(notFound.status == 3)
        #expect(notFound.error.contains("Error: Expression file not found or not readable: missing.aql"))
        let invalid = try await runSwiftAQL([checkCompat] + (try CompatFixture.arguments("self.books->(")))
        #expect(invalid.status == 3)
        #expect(invalid.error.contains("Error: Invalid AQL expression"))
        #expect(invalid.output.isEmpty)
        let noMetamodel = try await runSwiftAQL(
            [checkCompat] + (try CompatFixture.arguments("self.books", required: "missing.ecore")))
        #expect(noMetamodel.status == 3)
        #expect(noMetamodel.error.contains("missing.ecore"))
    }

    @Test("fails with status 64 for invalid arguments")
    func validation() async throws {
        let variable = try await runSwiftAQL([checkCompat] + (try CompatFixture.arguments(
            "self.books", ["--variable", "self"])))
        #expect(variable.status == 64)
        #expect(variable.error.contains("Invalid variable 'self'"))
        let several = try await runSwiftAQL([checkCompat] + (try CompatFixture.arguments(
            "self.books", ["--metamodel", "shop=\(try CompatFixture.path("LibraryV2.ecore"))"])))
        #expect(several.status == 64)
    }
}

/// The spellings of the matching semantics and their aliases on the command line.
private enum MatchingSemanticsSpelling {
    /// Every spelling that `--semantics` accepts.
    static let all = ["access-refined", "object-type-matching", "mof-class-matching", "steel-jezequel", "guy"]
}
