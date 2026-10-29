//
// SemanticsOptionsTests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for the options of `swift-ecore generate` that choose between the behaviour of this
/// release and that of version 0.6 for the templates.
@Suite("swift-ecore generate - semantics options", .serialized)
struct SemanticsOptionsTests {
    /// An option that is passed to every run, so that typed `let` mismatches are observable
    /// without failing the run.
    private static let skipMismatches = ["--let-type-mismatches", "skip"]

    /// The fixtures shared with the generator library tests.
    private static let fixtureRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ModellingGeneratorsTests/Resources")

    /// A header module whose output shows one behaviour per line.
    static let probe = """
        [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
        [template public header(element : OclAny, fileName : String)]
        // probe
        [if (false)]never[/if]
        // args=[Sequence{'a'}->append(Sequence{'b', 'c'})->flatten()->size()/]
        // kinds=[OrderedSet{'a'}->including('a')->size()/]
        // single=['a'->including('a')->size()/]
        // lettypes=[let n : Integer = fileName]unchecked[/let]
        // end
        [/template]
        """

    /// A header module that passes a single object to a collection-typed parameter.
    static let parameterProbe = """
        [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
        [query public count(s : Sequence(OclAny)) : Integer = s->size()/]
        [template public header(element : OclAny, fileName : String)]// params=[count(element)/]
        [/template]
        """

    /// The start of a generated file with the behaviour of this release.
    static let standardHeader = """
        // probe
        // args=3
        // kinds=1
        // single=1
        // lettypes=
        // end

        """

    /// The start of a generated file with the behaviour of version 0.6.
    static let legacyHeader = """
        // probe

        // args=2
        // kinds=2
        // single=2
        // lettypes=unchecked
        // end

        """

    /// Generates Swift from the library Ecore model with a header module.
    ///
    /// - Parameters:
    ///   - header: The text of the header module.
    ///   - extra: The arguments after the model, output directory and template path.
    /// - Returns: The result of the command and the text of one generated file, if any.
    @MainActor
    private func generate(header: String = Self.probe, _ extra: [String]) async throws
        -> (result: SubprocessResult, text: String?)
    {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let project = scratch.appendingPathComponent("library")
        try FileManager.default.copyItem(at: Self.fixtureRoot.appendingPathComponent("library"), to: project)
        let templates = scratch.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templates, withIntermediateDirectories: true)
        try header.write(to: templates.appendingPathComponent("Header.mtl"), atomically: true, encoding: .utf8)
        let output = scratch.appendingPathComponent("swift")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                "--language", "swift", project.appendingPathComponent("model/library.ecore").path,
                "-o", output.path, "--template-path", templates.path,
            ] + extra)
        let text = try? String(contentsOf: output.appendingPathComponent("library/Book.swift"), encoding: .utf8)
        return (result, text)
    }

    @Test("generates with the behaviour of this release by default and with --semantics standard")
    @MainActor
    func standard() async throws {
        for preset in [[], ["--semantics", "standard"]] {
            let (result, text) = try await generate(Self.skipMismatches + preset)

            #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
            #expect(text?.hasPrefix(Self.standardHeader) == true, "\(preset): \(text ?? "no output")")
        }
    }

    @Test("generates as version 0.6 with --semantics legacy")
    @MainActor
    func legacy() async throws {
        let (result, text) = try await generate(Self.skipMismatches + ["--semantics", "legacy"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text?.hasPrefix(Self.legacyHeader) == true, "\(text ?? "no output")")
    }

    /// Each option with each of its values, given against the preset whose behaviour differs,
    /// and the start of the generated file that results.
    static let cases: [(arguments: [String], header: String)] = [
        (["--block-line-breaks", "kept"], standardHeader.replacingOccurrences(of: "probe\n", with: "probe\n\n")),
        (["--semantics", "legacy", "--block-line-breaks", "acceleo"], legacyHeader.replacingOccurrences(of: "probe\n\n", with: "probe\n")),
        (["--collection-arguments", "first-element"], standardHeader.replacingOccurrences(of: "args=3", with: "args=2")),
        (["--semantics", "legacy", "--collection-arguments", "whole"], legacyHeader.replacingOccurrences(of: "args=2", with: "args=3")),
        (["--collection-kinds", "sequences"], standardHeader.replacingOccurrences(of: "kinds=1\n// single=1", with: "kinds=2\n// single=2")),
        (["--semantics", "legacy", "--collection-kinds", "distinguished"], legacyHeader.replacingOccurrences(of: "kinds=2", with: "kinds=1")),
        (["--single-value-collections", "sequence"], standardHeader.replacingOccurrences(of: "single=1", with: "single=2")),
        (
            ["--semantics", "legacy", "--collection-kinds", "distinguished", "--single-value-collections", "set"],
            legacyHeader.replacingOccurrences(of: "kinds=2\n// single=2", with: "kinds=1\n// single=1")
        ),
        (["--no-check-let-types"], standardHeader.replacingOccurrences(of: "lettypes=", with: "lettypes=unchecked")),
        (["--semantics", "legacy", "--check-let-types"], legacyHeader.replacingOccurrences(of: "lettypes=unchecked", with: "lettypes=")),
        (["--container-lookup", "registered-objects"], standardHeader),
        (["--semantics", "legacy", "--container-lookup", "resources"], legacyHeader),
        (["--no-cache-containers"], standardHeader),
        (["--semantics", "legacy", "--cache-containers"], legacyHeader),
    ]

    @Test("selects each value of each option", arguments: cases.indices)
    @MainActor
    func option(index: Int) async throws {
        let (arguments, header) = Self.cases[index]
        let (result, text) = try await generate(Self.skipMismatches + arguments)

        #expect(result.succeeded, "\(arguments): \(result.stdout)\(result.stderr)")
        #expect(text?.hasPrefix(header) == true, "\(arguments): \(text ?? "no output")")
    }

    @Test("passes a single object to a collection parameter only with --collection-parameters conforming")
    @MainActor
    func collectionParameters() async throws {
        let exact = try await generate(header: Self.parameterProbe, ["--collection-parameters", "exact"])
        let conforming = try await generate(
            header: Self.parameterProbe, ["--semantics", "legacy", "--collection-parameters", "conforming"])

        #expect(!exact.result.succeeded)
        #expect((exact.result.stdout + exact.result.stderr).contains("count"))
        #expect(conforming.result.succeeded, "\(conforming.result.stderr)")
        #expect(conforming.text?.hasPrefix("// params=1\n") == true, "\(conforming.text ?? "no output")")
    }

    @Test("describes every option in the help of generate")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftEcore(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        for text in [
            "--semantics <standard|legacy>", "--block-line-breaks <acceleo|kept>",
            "--collection-parameters <conforming|exact>", "--check-let-types/--no-check-let-types",
            "--cache-containers/--no-cache-containers", "--collection-arguments <whole|first-element>",
            "--collection-kinds <distinguished|sequences>", "--single-value-collections <set|sequence>",
            "--container-lookup <resources|registered-objects>",
        ] {
            #expect(result.stdout.contains(text), "\(text)")
        }
    }

    @Test("rejects a preset that does not exist")
    @MainActor
    func rejectsUnknownPreset() async throws {
        let result = try await executeSwiftEcore(command: "generate", arguments: ["--semantics", "0.5"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("0.5"))
    }
}
