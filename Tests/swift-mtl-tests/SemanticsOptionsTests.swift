//
// SemanticsOptionsTests.swift
// swift-mtl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for the options of `swift-mtl generate` that choose between the behaviour of this
/// release and that of version 0.6, for a template file and for a template set.
@Suite("swift-mtl generate - semantics options")
struct SemanticsOptionsTests {
    /// How the templates are given to the command.
    enum Mode: String, CaseIterable, Sendable {
        /// A template file, run by the generator directly.
        case templateFile

        /// A template set, run through a generation step.
        case templateSet
    }

    /// An option that is passed to every run, so that typed `let` mismatches are observable
    /// without failing the run.
    private static let skipMismatches = ["--let-type-mismatches", "skip"]

    /// A module whose output shows one behaviour per line.
    private static let probe = """
        [module Probe('http://www.eclipse.org/emf/2002/Ecore')]

        [template public main(p : ecore::EPackage)]
        [file ('result.txt', 'overwrite', 'UTF-8')]
        start
        [if (false)]never[/if]
        args=[Sequence{'a'}->append(Sequence{'b', 'c'})->flatten()->size()/]
        kinds=[OrderedSet{'a'}->including('a')->size()/]
        single=['a'->including('a')->size()/]
        container=[p.eClassifiers->first().eStructuralFeatures->first().eContainer().name/]
        lettypes=[let n : Integer = 'text']unchecked[/let]
        end
        [/file]
        [/template]
        """

    /// A module that passes a single object to a collection-typed parameter.
    private static let parameterProbe = """
        [module Probe('http://www.eclipse.org/emf/2002/Ecore')]

        [query public count(s : Sequence(ecore::EClassifier)) : Integer = s->size()/]

        [template public main(p : ecore::EPackage)]
        [file ('result.txt', 'overwrite', 'UTF-8')]
        params=[count(p.eClassifiers->first())/]
        [/file]
        [/template]
        """

    /// An Ecore model with a class that has an attribute.
    private static let model = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="lib"
            nsURI="http://www.example.org/lib" nsPrefix="lib">
          <eClassifiers xsi:type="ecore:EClass" name="Book">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="title"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// The output of the probe with the behaviour of this release.
    static let standardOutput = """
        start
        args=3
        kinds=1
        single=1
        container=Book
        lettypes=
        end

        """

    /// The output of the probe with the behaviour of version 0.6, as swift-mtl 0.6.2 writes it.
    static let legacyOutput = """
        start

        args=2
        kinds=2
        single=2
        container=
        lettypes=unchecked
        end

        """

    /// Writes a text file, creating its directory.
    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Generates with a module and extra arguments.
    ///
    /// - Parameters:
    ///   - module: The text of the module.
    ///   - mode: Whether the module is given as a template file or as a template set.
    ///   - extra: The arguments after the template, model and output directory.
    /// - Returns: The result of the command and the generated text, if any.
    @MainActor
    private func generate(
        _ module: String = Self.probe, mode: Mode, _ extra: [String]
    ) async throws -> (result: SubprocessResult, text: String?) {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let model = scratch.appendingPathComponent("lib.ecore")
        let output = scratch.appendingPathComponent("out")
        try write(Self.model, to: model)
        let source: [String]
        switch mode {
        case .templateFile:
            let template = scratch.appendingPathComponent("Probe.mtl")
            try write(module, to: template)
            source = [template.path]
        case .templateSet:
            let set = scratch.appendingPathComponent("sets/probe")
            try write(
                #"{ "name": "probe", "mainModule": "Probe", "mainTemplate": "main" }"#,
                to: set.appendingPathComponent("templateset.json"))
            try write(module, to: set.appendingPathComponent("Probe.mtl"))
            source = ["--template-set", set.path]
        }
        let result = try await executeSwiftMTL(
            command: "generate", arguments: source + ["--model", model.path, "--output", output.path] + extra)
        let text = try? String(contentsOf: output.appendingPathComponent("result.txt"), encoding: .utf8)
        return (result, text)
    }

    @Test("generates with the behaviour of this release by default", arguments: Mode.allCases)
    @MainActor
    func standardByDefault(mode: Mode) async throws {
        let (result, text) = try await generate(mode: mode, Self.skipMismatches)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text == Self.standardOutput)
    }

    @Test("generates as version 0.6 with --semantics legacy", arguments: Mode.allCases)
    @MainActor
    func legacyPreset(mode: Mode) async throws {
        let (result, text) = try await generate(mode: mode, Self.skipMismatches + ["--semantics", "legacy"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text == Self.legacyOutput)
    }

    @Test("generates with the behaviour of this release with --semantics standard", arguments: Mode.allCases)
    @MainActor
    func standardPreset(mode: Mode) async throws {
        let (result, text) = try await generate(mode: mode, Self.skipMismatches + ["--semantics", "standard"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text == Self.standardOutput)
    }

    /// Each option with each of its values, given against the preset whose behaviour differs,
    /// and a line of the output that only that value writes.
    static let cases: [(arguments: [String], line: String)] = [
        (["--block-line-breaks", "kept"], "start\n\nargs="),
        (["--semantics", "legacy", "--block-line-breaks", "acceleo"], "start\nargs="),
        (["--collection-arguments", "first-element"], "\nargs=2\n"),
        (["--semantics", "legacy", "--collection-arguments", "whole"], "\nargs=3\n"),
        (["--collection-kinds", "sequences"], "\nkinds=2\n"),
        (["--semantics", "legacy", "--collection-kinds", "distinguished"], "\nkinds=1\n"),
        (["--single-value-collections", "sequence"], "\nsingle=2\n"),
        (
            ["--semantics", "legacy", "--collection-kinds", "distinguished", "--single-value-collections", "set"],
            "\nsingle=1\n"
        ),
        (["--container-lookup", "registered-objects"], "\ncontainer=\n"),
        (["--semantics", "legacy", "--container-lookup", "resources"], "\ncontainer=Book\n"),
        (["--no-check-let-types"], "\nlettypes=unchecked\n"),
        (["--semantics", "legacy", "--check-let-types"], "\nlettypes=\n"),
    ]

    @Test("selects each value of each option", arguments: cases.indices, Mode.allCases)
    @MainActor
    func option(index: Int, mode: Mode) async throws {
        let (arguments, line) = Self.cases[index]
        let (result, text) = try await generate(mode: mode, Self.skipMismatches + arguments)

        #expect(result.succeeded, "\(arguments): \(result.stdout)\(result.stderr)")
        #expect(text?.contains(line) == true, "\(arguments): \(text ?? "no output")")
    }

    @Test("accepts both forms of --cache-containers without changing the output", arguments: Mode.allCases)
    @MainActor
    func cacheContainers(mode: Mode) async throws {
        let uncached = try await generate(mode: mode, Self.skipMismatches + ["--no-cache-containers"])
        let cached = try await generate(
            mode: mode, Self.skipMismatches + ["--semantics", "legacy", "--cache-containers"])

        #expect(uncached.result.succeeded, "\(uncached.result.stderr)")
        #expect(uncached.text == Self.standardOutput)
        #expect(cached.result.succeeded, "\(cached.result.stderr)")
        #expect(cached.text == Self.legacyOutput)
    }

    @Test("passes a single object to a collection parameter only with --collection-parameters conforming", arguments: Mode.allCases)
    @MainActor
    func collectionParameters(mode: Mode) async throws {
        let exact = try await generate(Self.parameterProbe, mode: mode, ["--collection-parameters", "exact"])
        let conforming = try await generate(
            Self.parameterProbe, mode: mode, ["--semantics", "legacy", "--collection-parameters", "conforming"])
        let legacy = try await generate(Self.parameterProbe, mode: mode, ["--semantics", "legacy"])

        #expect(!exact.result.succeeded)
        #expect((exact.result.stdout + exact.result.stderr).contains("count"))
        #expect(conforming.result.succeeded, "\(conforming.result.stderr)")
        #expect(conforming.text == "params=1\n")
        #expect(!legacy.result.succeeded)
    }

    @Test("lets an option override the preset whatever their order", arguments: Mode.allCases)
    @MainActor
    func precedence(mode: Mode) async throws {
        let before = try await generate(
            mode: mode, Self.skipMismatches + ["--block-line-breaks", "acceleo", "--semantics", "legacy"])
        let after = try await generate(
            mode: mode, Self.skipMismatches + ["--semantics", "legacy", "--block-line-breaks", "acceleo"])

        let expected = Self.legacyOutput.replacingOccurrences(of: "start\n\n", with: "start\n")
        #expect(before.text == expected)
        #expect(after.text == expected)
    }

    @Test("rejects values that are not modes", arguments: [
        "--semantics", "--block-line-breaks", "--collection-parameters", "--collection-arguments",
        "--collection-kinds", "--single-value-collections", "--container-lookup",
    ])
    @MainActor
    func rejectsUnknownValues(option: String) async throws {
        let (result, _) = try await generate(mode: .templateFile, [option, "sometimes"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("sometimes"))
    }

    @Test("describes every option and its values in the help")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftMTL(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        for text in [
            "--semantics <standard|legacy>", "--block-line-breaks <acceleo|kept>",
            "--collection-parameters <conforming|exact>", "--check-let-types/--no-check-let-types",
            "--cache-containers/--no-cache-containers", "--collection-arguments <whole|first-element>",
            "--collection-kinds <distinguished|sequences>", "--single-value-collections <set|sequence>",
            "--container-lookup <resources|registered-objects>", "version 0.6",
        ] {
            #expect(result.stdout.contains(text), "\(text)")
        }
    }
}
