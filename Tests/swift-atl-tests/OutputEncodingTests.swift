//
// OutputEncodingTests.swift
// swift-atl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for the character encoding in which the commands of `swift-atl` write files.
///
/// Files are written in UTF-8 unless `--output-encoding` or the `output-encoding` key of the
/// configuration file names another encoding. XML names the encoding in its declaration and
/// refers to a character that the encoding cannot hold by number, plain text cannot hold
/// such a character, and JSON stays UTF-8 with a warning.
@Suite("swift-atl - output encodings", .serialized)
struct OutputEncodingTests {
    /// The option that names the encoding of written files.
    static let option = "--output-encoding"

    /// Text that ISO-8859-1 can hold.
    static let latin1Text = "Café"

    /// Text with a character, the euro sign, that ISO-8859-1 cannot hold.
    static let euroText = "Café €"

    /// A directory name that ISO-8859-1 can hold, with characters that have no decomposed
    /// form, so that the file system keeps them as they are.
    static let latin1Directory = "Price£×"

    /// A directory name with a character, the euro sign, that ISO-8859-1 cannot hold.
    static let euroDirectory = "Price £€"

    /// The euro sign as XML refers to it by number.
    static let euroReference = "&#x20AC;"

    /// The words of the warning that a JSON file was written in UTF-8.
    static let jsonWarning = "JSON is always written in UTF-8"

    /// Encodes text in ISO-8859-1.
    ///
    /// - Parameter text: Text whose characters are all below U+0100.
    /// - Returns: One byte per character.
    static func latin1(_ text: String) -> Data {
        Data(text.unicodeScalars.map { UInt8($0.value) })
    }

    /// Decodes ISO-8859-1.
    ///
    /// - Parameter data: The bytes.
    /// - Returns: One character per byte.
    static func decodeLatin1(_ data: Data) -> String {
        String(String.UnicodeScalarView(data.map { Unicode.Scalar($0) }))
    }

    /// Whether data contains a sequence of bytes.
    ///
    /// - Parameters:
    ///   - data: The data to search.
    ///   - bytes: The bytes to find.
    /// - Returns: `true` if the bytes occur in the data.
    static func contains(_ data: Data, _ bytes: Data) -> Bool {
        data.range(of: bytes) != nil
    }

    // MARK: - transform

    /// The kinds of target that `transform` writes.
    enum Target: String, CaseIterable, Sendable {
        /// An instance of a metamodel file, written as XMI.
        case xmi = "persons.xmi"
        /// A generator model, written in the layout of the Eclipse Modeling Framework.
        case genModel = "names.genmodel"
        /// An instance of a metamodel file, written as JSON.
        case json = "persons.json"
    }

    /// The metamodel of the targets that are not generator models.
    static let persons = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" \
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" \
        xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="Persons" \
        nsURI="http://www.example.org/persons" nsPrefix="persons">
          <eClassifiers xsi:type="ecore:EClass" name="Person">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="fullName" \
        eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// Runs `transform` with a transformation that writes a name to a target.
    ///
    /// - Parameters:
    ///   - target: The kind of target.
    ///   - workspace: The repository with the library fixture.
    ///   - name: The name that the target holds.
    ///   - extra: The options after the arguments of the command.
    /// - Returns: The result of the command and the target file.
    @MainActor
    static func transform(
        _ target: Target, in workspace: ConfigurationTests.Workspace, name: String = euroText, _ extra: [String] = []
    ) async throws -> (result: SubprocessResult, file: URL) {
        let atl: String
        if target == .genModel {
            atl = """
                -- @nsURI Ecore=http://www.eclipse.org/emf/2002/Ecore
                -- @nsURI GenModel=http://www.eclipse.org/emf/2002/GenModel
                module Naming;
                create OUT : GenModel from IN : Ecore;

                entrypoint rule Root() {
                    to m : GenModel!GenModel (
                        modelName <- '\(name)'
                    )
                }
                """
        } else {
            try workspace.write(persons, to: "Persons.ecore")
            atl = """
                -- @nsURI Ecore=http://www.eclipse.org/emf/2002/Ecore
                -- @path Persons=/Persons.ecore
                module Naming;
                create OUT : Persons from IN : Ecore;

                entrypoint rule Root() {
                    to p : Persons!Person (
                        fullName <- '\(name)'
                    )
                }
                """
        }
        let transformation = try workspace.write(atl, to: "Naming.atl")
        let file = workspace.root.appendingPathComponent(target.rawValue)
        try? FileManager.default.removeItem(at: file)
        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                transformation.path, "--source", "IN=\(workspace.fixture.ecore.path)", "--target",
                "OUT=\(file.path)",
            ] + extra,
            workingDirectory: workspace.workingDirectory)
        return (result, file)
    }

    @Test("transform writes the same bytes without the option as with UTF-8", arguments: Target.allCases)
    @MainActor
    func transformDefault(target: Target) async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }

        let implicit = try await Self.transform(target, in: workspace)
        let implicitData = try Data(contentsOf: implicit.file)
        let explicit = try await Self.transform(target, in: workspace, [Self.option, "UTF-8"])
        let explicitData = try Data(contentsOf: explicit.file)

        #expect(implicit.result.succeeded, "\(implicit.result.stdout)\(implicit.result.stderr)")
        #expect(explicit.result.succeeded, "\(explicit.result.stdout)\(explicit.result.stderr)")
        #expect(implicitData == explicitData)
        #expect(Self.contains(implicitData, Data(Self.euroText.utf8)))
        #expect(!implicit.result.stderr.contains(Self.jsonWarning))
    }

    @Test(
        "transform writes XML targets in another encoding, with the declaration naming it",
        arguments: [Target.xmi, Target.genModel])
    @MainActor
    func transformLatin1(target: Target) async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }

        let (result, file) = try await Self.transform(target, in: workspace, [Self.option, "latin1"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let data = try Data(contentsOf: file)
        let text = Self.decodeLatin1(data)
        #expect(text.hasPrefix(#"<?xml version="1.0" encoding="ISO-8859-1"?>"#), "\(text)")
        #expect(text.contains("Café " + Self.euroReference), "\(text)")
        #expect(Self.contains(data, Self.latin1("Café ")))
        #expect(String(data: data, encoding: .utf8) == nil)
    }

    @Test("transform writes a JSON target in UTF-8 with a warning when another encoding is named")
    @MainActor
    func transformJSON() async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }

        let (result, file) = try await Self.transform(.json, in: workspace, [Self.option, "ISO-8859-1"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stderr.contains(Self.jsonWarning), "\(result.stderr)")
        #expect(result.stderr.contains(file.path), "\(result.stderr)")
        #expect(Self.contains(try Data(contentsOf: file), Data(Self.euroText.utf8)))
    }

    @Test("transform takes the encoding from the configuration file, which the option overrides")
    @MainActor
    func transformConfiguration() async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }
        let reference = try await Self.transform(.genModel, in: workspace)
        let utf8 = try Data(contentsOf: reference.file)
        try workspace.write(#"{ "output-encoding": "latin1" }"#)

        let configured = try await Self.transform(.genModel, in: workspace)
        let configuredText = Self.decodeLatin1(try Data(contentsOf: configured.file))
        let overridden = try await Self.transform(.genModel, in: workspace, [Self.option, "UTF-8"])

        #expect(configured.result.succeeded, "\(configured.result.stdout)\(configured.result.stderr)")
        #expect(configuredText.contains(#"encoding="ISO-8859-1""#), "\(configuredText)")
        #expect(overridden.result.succeeded, "\(overridden.result.stdout)\(overridden.result.stderr)")
        #expect(try Data(contentsOf: overridden.file) == utf8)
    }

    @Test("transform rejects an unknown encoding, listing the supported ones")
    @MainActor
    func transformUnknownEncoding() async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }

        let (result, file) = try await Self.transform(.xmi, in: workspace, [Self.option, "EBCDIC"])

        #expect(!result.succeeded)
        for name in ["EBCDIC", "UTF-8", "ISO-8859-1", "windows-1252"] {
            #expect(result.stderr.contains(name), "\(name) is missing from: \(result.stderr)")
        }
        #expect(!FileManager.default.fileExists(atPath: file.path))
    }

    // MARK: - Reports

    /// The commands that write a report with `--output`.
    enum ReportCommand: String, CaseIterable, Sendable {
        case parse, analyze, validate, test
    }

    /// Runs a report command on a transformation in a directory with a name, writing the report.
    ///
    /// - Parameters:
    ///   - command: The command to run.
    ///   - workspace: The repository with the library fixture.
    ///   - directory: The name of the directory that holds the transformation, which the
    ///     report names.
    ///   - report: The name of the report file.
    ///   - extra: The options after the arguments of the command.
    /// - Returns: The result of the command and the report file.
    @MainActor
    static func report(
        _ command: ReportCommand, in workspace: ConfigurationTests.Workspace, directory: String = latin1Directory,
        report: String = "report.txt", _ extra: [String] = []
    ) async throws -> (result: SubprocessResult, file: URL) {
        let atl = try workspace.write(ConfigurationTests.transformation, to: "\(directory)/Range.atl")
        let file = workspace.root.appendingPathComponent(report)
        try? FileManager.default.removeItem(at: file)
        var arguments = [atl.path, "--output", file.path]
        if command == .test { arguments += ["--timeout", "5"] }
        let result = try await executeSwiftATL(
            command: command.rawValue, arguments: arguments + extra, workingDirectory: workspace.workingDirectory)
        return (result, file)
    }

    @Test("a report is written in UTF-8 by default and in the encoding named", arguments: ReportCommand.allCases)
    @MainActor
    func reportEncoding(command: ReportCommand) async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }

        let implicit = try await Self.report(command, in: workspace)
        let implicitData = try Data(contentsOf: implicit.file)
        let explicit = try await Self.report(command, in: workspace, [Self.option, "UTF-8"])
        let explicitData = try Data(contentsOf: explicit.file)
        let latin1 = try await Self.report(command, in: workspace, [Self.option, "ISO-8859-1"])
        let latin1Data = try Data(contentsOf: latin1.file)

        for run in [implicit, explicit, latin1] {
            #expect(run.result.succeeded, "\(command): \(run.result.stdout)\(run.result.stderr)")
        }
        #expect(Self.contains(implicitData, Data("/\(Self.latin1Directory)/Range.atl".utf8)), "\(command)")
        #expect(Self.contains(explicitData, Data("/\(Self.latin1Directory)/Range.atl".utf8)), "\(command)")
        #expect(Self.contains(latin1Data, Self.latin1("/\(Self.latin1Directory)/Range.atl")), "\(command)")
        #expect(!Self.contains(latin1Data, Data(Self.latin1Directory.utf8)), "\(command)")
    }

    @Test(
        "a report with a character that the encoding cannot hold is an error naming the file, line and column",
        arguments: ReportCommand.allCases)
    @MainActor
    func reportUnrepresentable(command: ReportCommand) async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }

        let (result, file) = try await Self.report(
            command, in: workspace, directory: Self.euroDirectory, [Self.option, "ISO-8859-1"])

        #expect(!result.succeeded, "\(command): \(result.stdout)\(result.stderr)")
        let output = result.stdout + result.stderr
        for expected in [file.path, "U+20AC", "line ", "column ", "ISO-8859-1"] {
            #expect(output.contains(expected), "\(command): \(expected) is missing from: \(output)")
        }
        #expect(!FileManager.default.fileExists(atPath: file.path), "\(command)")
    }

    @Test("a report takes the encoding from the configuration file, which the option overrides", arguments: ReportCommand.allCases)
    @MainActor
    func reportConfiguration(command: ReportCommand) async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "output-encoding": "latin1" }"#)

        let configured = try await Self.report(command, in: workspace)
        let configuredData = try Data(contentsOf: configured.file)
        let overridden = try await Self.report(command, in: workspace, [Self.option, "UTF-8"])
        let overriddenData = try Data(contentsOf: overridden.file)

        #expect(configured.result.succeeded, "\(command): \(configured.result.stdout)\(configured.result.stderr)")
        #expect(Self.contains(configuredData, Self.latin1("/\(Self.latin1Directory)/")), "\(command)")
        #expect(overridden.result.succeeded, "\(command): \(overridden.result.stdout)\(overridden.result.stderr)")
        #expect(Self.contains(overriddenData, Data("/\(Self.latin1Directory)/".utf8)), "\(command)")
    }

    @Test("parse writes an XML report whose declaration names the encoding")
    @MainActor
    func parseXML() async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }

        let (result, file) = try await Self.report(
            .parse, in: workspace, directory: Self.euroDirectory, report: "report.xml",
            ["--format", "xml", Self.option, "ISO-8859-1"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let text = Self.decodeLatin1(try Data(contentsOf: file))
        #expect(text.hasPrefix(#"<?xml version="1.0" encoding="ISO-8859-1"?>"#), "\(text)")
        #expect(text.contains("/Price £\(Self.euroReference)/Range.atl"), "\(text)")
    }

    @Test(
        "a JSON report is written in UTF-8 with a warning when another encoding is named",
        arguments: [ReportCommand.parse, ReportCommand.analyze])
    @MainActor
    func reportJSON(command: ReportCommand) async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }

        let (result, file) = try await Self.report(
            command, in: workspace, directory: Self.euroDirectory, report: "report.json",
            ["--format", "json", Self.option, "ISO-8859-1"])

        #expect(result.succeeded, "\(command): \(result.stdout)\(result.stderr)")
        #expect(result.stderr.contains(Self.jsonWarning), "\(command): \(result.stderr)")
        let text = String(data: try Data(contentsOf: file), encoding: .utf8)
        #expect(text?.contains(Self.euroDirectory) == true, "\(command): \(text ?? "not UTF-8")")
    }

    // MARK: - query

    /// Runs a query that writes text to a file in its output directory.
    ///
    /// - Parameters:
    ///   - workspace: The repository with the library fixture.
    ///   - text: The text that the query writes with `writeTo`.
    ///   - extra: The options after the arguments of the command.
    /// - Returns: The result of the command and the written file.
    @MainActor
    static func query(
        in workspace: ConfigurationTests.Workspace, text: String, _ extra: [String] = []
    ) async throws -> (result: SubprocessResult, file: URL) {
        let query = try workspace.write(
            """
            -- @nsURI Ecore=http://www.eclipse.org/emf/2002/Ecore
            query Write = 'ab\\n\(text)'.writeTo('written.txt');
            """, to: "Write.atl")
        let directory = workspace.root.appendingPathComponent("out")
        let file = directory.appendingPathComponent("written.txt")
        try? FileManager.default.removeItem(at: file)
        let result = try await executeSwiftATL(
            command: "query",
            arguments: [query.path, "--source", workspace.fixture.ecore.path, "--output-directory", directory.path]
                + extra,
            workingDirectory: workspace.workingDirectory)
        return (result, file)
    }

    @Test("query writes writeTo files in UTF-8 by default and in the encoding named")
    @MainActor
    func queryEncoding() async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }

        let implicit = try await Self.query(in: workspace, text: Self.euroText)
        let implicitData = try Data(contentsOf: implicit.file)
        let explicit = try await Self.query(in: workspace, text: Self.euroText, [Self.option, "UTF-8"])
        let explicitData = try Data(contentsOf: explicit.file)
        let windows = try await Self.query(in: workspace, text: Self.euroText, [Self.option, "cp1252"])
        let windowsData = try Data(contentsOf: windows.file)

        for run in [implicit, explicit, windows] {
            #expect(run.result.succeeded, "\(run.result.stdout)\(run.result.stderr)")
        }
        #expect(implicitData == Data("ab\n\(Self.euroText)".utf8))
        #expect(explicitData == implicitData)
        #expect(windowsData == Data([0x61, 0x62, 0x0A, 0x43, 0x61, 0x66, 0xE9, 0x20, 0x80]))
    }

    @Test("query reports a writeTo character that the encoding cannot hold with the file, line and column")
    @MainActor
    func queryUnrepresentable() async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }

        let (result, file) = try await Self.query(in: workspace, text: Self.euroText, [Self.option, "latin1"])

        #expect(!result.succeeded)
        for expected in ["written.txt", "U+20AC", "line 2, column 6", "ISO-8859-1"] {
            #expect(result.stderr.contains(expected), "\(expected) is missing from: \(result.stderr)")
        }
        #expect(!FileManager.default.fileExists(atPath: file.path))
    }

    @Test("query takes the encoding of writeTo from the configuration file, which the option overrides")
    @MainActor
    func queryConfiguration() async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "output-encoding": "latin1" }"#)

        let configured = try await Self.query(in: workspace, text: Self.latin1Text)
        let configuredData = try Data(contentsOf: configured.file)
        let overridden = try await Self.query(in: workspace, text: Self.latin1Text, [Self.option, "UTF-8"])

        #expect(configured.result.succeeded, "\(configured.result.stdout)\(configured.result.stderr)")
        #expect(configuredData == Self.latin1("ab\n\(Self.latin1Text)"))
        #expect(overridden.result.succeeded, "\(overridden.result.stdout)\(overridden.result.stderr)")
        #expect(try Data(contentsOf: overridden.file) == Data("ab\n\(Self.latin1Text)".utf8))
    }

    // MARK: - generate

    /// Writes a template set `note` that writes text to `note.txt`.
    ///
    /// - Parameters:
    ///   - text: The text of the file.
    ///   - fixture: The fixture whose scratch directory receives the set.
    /// - Returns: The directory to give with `--template-path`.
    static func writeTemplates(_ text: String, in fixture: LibraryFixture) throws -> URL {
        let languages = fixture.scratch.appendingPathComponent("languages")
        let note = languages.appendingPathComponent("note")
        try FileManager.default.createDirectory(at: note, withIntermediateDirectories: true)
        try Data(#"{ "name": "note", "mainModule": "generate", "mainTemplate": "generate" }"#.utf8)
            .write(to: note.appendingPathComponent("templateset.json"))
        try Data(
            """
            [module generate('http://www.eclipse.org/emf/2002/GenModel')/]
            [template public generate(genModel : GenModel)]
            [file ('note.txt')]\(text)[/file]
            [/template]
            """.utf8
        ).write(to: note.appendingPathComponent("generate.mtl"))
        return languages
    }

    /// Runs `generate` with the template set `note`.
    ///
    /// - Parameters:
    ///   - text: The text that the template writes.
    ///   - extra: The options after the arguments of the command.
    /// - Returns: The result of the command and the bytes of `note.txt`, if it was written.
    @MainActor
    static func generateNote(_ text: String, _ extra: [String] = []) async throws
        -> (result: SubprocessResult, data: Data?)
    {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let languages = try writeTemplates(text, in: fixture)
        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [
                fixture.ecore.path, "--language", "note", "--template-path", languages.path, "-o",
                fixture.output.path,
            ] + extra)
        let data = try? Data(contentsOf: fixture.output.appendingPathComponent("note.txt"))
        return (result, data)
    }

    @Test("generate writes the files of a template set in UTF-8 by default and in the encoding named")
    @MainActor
    func generateEncoding() async throws {
        let implicit = try await Self.generateNote(Self.euroText)
        let explicit = try await Self.generateNote(Self.euroText, [Self.option, "UTF-8"])
        let windows = try await Self.generateNote(Self.euroText, [Self.option, "windows-1252"])

        for run in [implicit, explicit, windows] {
            #expect(run.result.succeeded, "\(run.result.stdout)\(run.result.stderr)")
        }
        #expect(implicit.data == Data(Self.euroText.utf8))
        #expect(explicit.data == implicit.data)
        #expect(windows.data == Data([0x43, 0x61, 0x66, 0xE9, 0x20, 0x80]))
    }

    @Test("generate reports a character that the encoding cannot hold with the file, line and column")
    @MainActor
    func generateUnrepresentable() async throws {
        let (result, data) = try await Self.generateNote("ab\n" + Self.euroText, [Self.option, "ISO-8859-1"])

        #expect(!result.succeeded)
        let output = result.stdout + result.stderr
        for expected in ["note.txt", "U+20AC", "line 2, column 6"] {
            #expect(output.contains(expected), "\(expected) is missing from: \(output)")
        }
        #expect(data == nil)
    }

    @Test("generate writes a generator model in the encoding named, with the declaration naming it")
    @MainActor
    func generateGenModel() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = fixture.scratch.appendingPathComponent("named.genmodel")

        let arguments = [
            fixture.ecore.path, "--language", "genmodel", "--copyright", Self.euroText, "-o", output.path,
        ]
        let implicit = try await executeSwiftATL(command: "generate", arguments: arguments)
        let utf8 = try Data(contentsOf: output)
        let explicit = try await executeSwiftATL(command: "generate", arguments: arguments + [Self.option, "UTF-8"])
        let explicitData = try Data(contentsOf: output)
        let latin1 = try await executeSwiftATL(command: "generate", arguments: arguments + [Self.option, "latin1"])
        let text = Self.decodeLatin1(try Data(contentsOf: output))

        for result in [implicit, explicit, latin1] {
            #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        }
        #expect(explicitData == utf8)
        #expect(Self.contains(utf8, Data(Self.euroText.utf8)))
        #expect(text.hasPrefix(#"<?xml version="1.0" encoding="ISO-8859-1"?>"#), "\(text)")
        #expect(text.contains("Café " + Self.euroReference), "\(text)")
    }

    @Test("generate takes the encoding from the configuration file, which the option overrides")
    @MainActor
    func generateConfiguration() async throws {
        let workspace = try ConfigurationTests.Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "output-encoding": "latin1" }"#)
        let languages = try Self.writeTemplates(Self.latin1Text, in: workspace.fixture)
        let output = workspace.root.appendingPathComponent("generated")
        let arguments = [
            workspace.fixture.ecore.path, "--language", "note", "--template-path", languages.path, "-o", output.path,
        ]
        let note = output.appendingPathComponent("note.txt")

        let configured = try await executeSwiftATL(
            command: "generate", arguments: arguments, workingDirectory: workspace.workingDirectory)
        let configuredData = try? Data(contentsOf: note)
        let overridden = try await executeSwiftATL(
            command: "generate", arguments: arguments + ["--force-overwrite", Self.option, "UTF-8"],
            workingDirectory: workspace.workingDirectory)
        let overriddenData = try? Data(contentsOf: note)

        #expect(configured.succeeded, "\(configured.stdout)\(configured.stderr)")
        #expect(configuredData == Self.latin1(Self.latin1Text))
        #expect(overridden.succeeded, "\(overridden.stdout)\(overridden.stderr)")
        #expect(overriddenData == Data(Self.latin1Text.utf8))
    }

    // MARK: - Help

    @Test(
        "the help of each command that writes files describes the option",
        arguments: ["transform", "query", "generate", "parse", "analyze", "validate", "test"])
    @MainActor
    func help(command: String) async throws {
        let result = try await executeSwiftATL(command: command, arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains(Self.option), "\(command): \(result.stdout)")
    }
}
