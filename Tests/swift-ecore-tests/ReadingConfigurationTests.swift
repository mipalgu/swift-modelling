//
// ReadingConfigurationTests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for the configuration file of the `swift-ecore` commands that read models and
/// metamodels, and for `--config` and `--no-config`.
@Suite("swift-ecore - configuration file of the reading commands", .serialized)
struct ReadingConfigurationTests {
    /// The name of the configuration file.
    static let configurationFile = ".swift-modelling.json"

    /// The warning of a file that is read as ISO-8859-1 because it is not valid UTF-8.
    static let fallbackWarning = "The text is not valid UTF-8 and was read as ISO-8859-1"

    /// A KM3 metamodel whose first comment holds an e with a grave accent in ISO-8859-1, and
    /// which declares its primitive types.
    static let legacyMetamodel = "-- Biblioth\u{E8}que\n"
        + "-- @nsURI http://www.example.org/library\n-- @nsPrefix lib\n"
        + "package Library {\n  class Book {\n    attribute title : String;\n  }\n}\n"
        + "package PrimitiveTypes {\n  datatype String;\n}\n"

    /// An ASDL description of arithmetic expressions with an enumerable sum type.
    static let arithmetic = """
        module Arith {
            expr = Num(int value) | BinOp(expr left, op operator, expr right)
            op = Add | Sub
        }

        """

    /// A metamodel whose only class has an invariant that only strict AQL rejects.
    static let notes = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="notes"
            nsURI="http://www.example.org/notes" nsPrefix="notes">
          <eClassifiers xsi:type="ecore:EClass" name="Note">
            <eAnnotations source="http://www.eclipse.org/emf/2002/Ecore/OCL">
              <details key="twoWords" value="Sequence{'a'}->concat('b')->size() = 2"/>
            </eAnnotations>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// A model with one note.
    static let note = """
        <?xml version="1.0" encoding="UTF-8"?>
        <notes:Note xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:notes="http://www.example.org/notes"/>
        """

    /// The commands that read documents, with the arguments that read a metamodel.
    ///
    /// - Parameters:
    ///   - metamodel: The path of the metamodel.
    ///   - output: The path that `convert` writes.
    /// - Returns: Each command with its arguments.
    static func readingCommands(_ metamodel: String, output: String) -> [(String, [String])] {
        [
            ("inspect", [metamodel]), ("validate", [metamodel]), ("statistics", [metamodel]),
            ("query", [metamodel, "--query", "classes"]), ("compare", [metamodel, metamodel]),
            ("convert", [metamodel, output, "--force"]),
        ]
    }

    /// A repository with the documents of the tests and a nested working directory.
    struct Workspace {
        /// The root of the repository.
        let root: URL

        /// The directory the tool runs in, two levels below the root.
        var workingDirectory: URL { root.appendingPathComponent("work/nested") }

        /// The KM3 metamodel in ISO-8859-1.
        var metamodel: String { root.appendingPathComponent("Library.km3").path }

        /// The ASDL description.
        var grammar: String { root.appendingPathComponent("arith.asdl").path }

        /// The Ecore metamodel with an invariant that only strict AQL rejects.
        var notes: String { root.appendingPathComponent("notes.ecore").path }

        /// A model of ``notes``.
        var note: String { root.appendingPathComponent("note.xmi").path }

        /// The file that `convert` writes.
        var output: String { root.appendingPathComponent("Library.ecore").path }

        /// Creates the repository.
        init() throws {
            root = try createTemporaryDirectory()
            try FileManager.default.createDirectory(
                at: root.appendingPathComponent(".git"), withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true)
            try #require(ReadingConfigurationTests.legacyMetamodel.data(using: .isoLatin1))
                .write(to: URL(fileURLWithPath: metamodel))
            try ReadingConfigurationTests.arithmetic.write(toFile: grammar, atomically: true, encoding: .utf8)
            try ReadingConfigurationTests.notes.write(toFile: notes, atomically: true, encoding: .utf8)
            try ReadingConfigurationTests.note.write(toFile: note, atomically: true, encoding: .utf8)
        }

        /// Writes a file below the root.
        ///
        /// - Parameters:
        ///   - text: The contents of the file.
        ///   - path: The path of the file relative to the root.
        /// - Returns: The file.
        @discardableResult
        func write(_ text: String, to path: String = ReadingConfigurationTests.configurationFile) throws -> URL {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        }

        /// Runs a command of `swift-ecore` from the working directory.
        ///
        /// - Parameters:
        ///   - command: The command.
        ///   - arguments: Its arguments.
        /// - Returns: The result of the command.
        @MainActor
        func run(_ command: String, _ arguments: [String]) async throws -> SubprocessResult {
            try? FileManager.default.removeItem(atPath: output)
            return try await executeSwiftEcore(command: command, arguments: arguments, workingDirectory: workingDirectory)
        }

        /// Removes the repository.
        func remove() {
            cleanupTemporaryDirectory(root)
        }
    }

    // MARK: - Encoding

    @Test("reads documents in the encoding of the configuration file, without a warning")
    @MainActor
    func encodingFromFile() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "encoding": "latin1" }"#)

        for (command, arguments) in Self.readingCommands(workspace.metamodel, output: workspace.output) {
            let configured = try await workspace.run(command, arguments)
            let ignored = try await workspace.run(command, arguments + ["--no-config"])

            #expect(configured.succeeded, "\(command): \(configured.stdout)\(configured.stderr)")
            #expect(!configured.stderr.contains(Self.fallbackWarning), "\(command): \(configured.stderr)")
            #expect(ignored.succeeded, "\(command): \(ignored.stdout)\(ignored.stderr)")
            #expect(ignored.stderr.contains(Self.fallbackWarning), "\(command): \(ignored.stderr)")
        }
    }

    @Test("lets --encoding override the encoding of the configuration file")
    @MainActor
    func encodingOverride() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "encoding": "UTF-8" }"#)

        for (command, arguments) in Self.readingCommands(workspace.metamodel, output: workspace.output) {
            let configured = try await workspace.run(command, arguments)
            let overridden = try await workspace.run(command, arguments + ["--encoding", "ISO-8859-1"])

            #expect(configured.exitCode == 1, "\(command): \(configured.stdout)\(configured.stderr)")
            #expect(overridden.succeeded, "\(command): \(overridden.stdout)\(overridden.stderr)")
            #expect(!overridden.stderr.contains(Self.fallbackWarning), "\(command): \(overridden.stderr)")
        }
    }

    @Test("reads the file that --config names instead of the one found")
    @MainActor
    func explicitFile() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "encoding": "UTF-8" }"#)
        let custom = try workspace.write(#"{ "encoding": "windows-1252" }"#, to: "settings/custom.json")

        let result = try await workspace.run("inspect", [workspace.metamodel, "--config", custom.path])
        let conflicting = try await workspace.run("inspect", [workspace.metamodel, "--config", custom.path, "--no-config"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(!result.stderr.contains(Self.fallbackWarning), "\(result.stderr)")
        #expect(!conflicting.succeeded)
        #expect(conflicting.stderr.contains("--no-config"), "\(conflicting.stderr)")
    }

    // MARK: - Metamodel formats

    @Test("reads KM3 data types as the configuration file says, unless the command line says otherwise")
    @MainActor
    func km3Primitives() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "encoding": "latin1", "km3-primitives": "declared" }"#)

        let configured = try await workspace.run("inspect", [workspace.metamodel])
        let overridden = try await workspace.run("inspect", [workspace.metamodel, "--km3-primitives", "ecore"])

        #expect(configured.succeeded, "\(configured.stdout)\(configured.stderr)")
        #expect(configured.stdout.contains("Package PrimitiveTypes"), "\(configured.stdout)")
        #expect(overridden.succeeded, "\(overridden.stdout)\(overridden.stderr)")
        #expect(!overridden.stdout.contains("Package PrimitiveTypes"), "\(overridden.stdout)")
    }

    @Test("imports grammars with the options of the configuration file, unless the command line says otherwise")
    @MainActor
    func grammarImport() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(
            #"{ "asdl-enumerations": "never", "ns-uri": "http://example.org/calc", "ns-prefix": "calc" }"#)

        let configured = try await workspace.run("inspect", [workspace.grammar])
        let overridden = try await workspace.run(
            "inspect", [workspace.grammar, "--asdl-enumerations", "all-nullary", "--ns-prefix", "arith"])

        #expect(configured.succeeded, "\(configured.stdout)\(configured.stderr)")
        #expect(configured.stdout.contains("Enumerations: 0"), "\(configured.stdout)")
        #expect(configured.stdout.contains("Namespace URI: http://example.org/calc"), "\(configured.stdout)")
        #expect(configured.stdout.contains("Namespace prefix: calc"), "\(configured.stdout)")
        #expect(overridden.succeeded, "\(overridden.stdout)\(overridden.stderr)")
        #expect(overridden.stdout.contains("Enumerations: 1"), "\(overridden.stdout)")
        #expect(overridden.stdout.contains("Namespace URI: http://example.org/calc"), "\(overridden.stdout)")
        #expect(overridden.stdout.contains("Namespace prefix: arith"), "\(overridden.stdout)")
    }

    @Test("reads metamodels for create as the configuration file says")
    @MainActor
    func create() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "ns-uri": "http://example.org/calc" }"#)
        let model = workspace.root.appendingPathComponent("expression.xmi")

        let result = try await workspace.run(
            "create", ["--metamodel", workspace.grammar, "--root-class", "Num", "--output", model.path])
        let text = try? String(contentsOf: model, encoding: .utf8)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text?.contains("http://example.org/calc") == true, "\(text ?? "no output")")
    }

    // MARK: - Validation

    @Test("evaluates invariants as strictly as the configuration file says, unless the command line says otherwise")
    @MainActor
    func strictAQL() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "strict-aql": true }"#)
        let arguments = [workspace.note, "--metamodel", workspace.notes]

        let configured = try await workspace.run("validate", arguments)
        let overridden = try await workspace.run("validate", arguments + ["--no-strict-aql"])
        let ignored = try await workspace.run("validate", arguments + ["--no-config"])

        #expect(!configured.succeeded, "\(configured.stdout)")
        #expect(configured.stdout.contains("twoWords"), "\(configured.stdout)")
        #expect(overridden.succeeded, "\(overridden.stdout)\(overridden.stderr)")
        #expect(ignored.succeeded, "\(ignored.stdout)\(ignored.stderr)")
    }

    // MARK: - Unchanged behaviour

    @Test("behaves alike without a configuration file, with --no-config, and with keys for other commands")
    @MainActor
    func unchanged() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        let commands = Self.readingCommands(workspace.metamodel, output: workspace.output)
            + [("validate", [workspace.note, "--metamodel", workspace.notes]), ("inspect", [workspace.grammar])]
        var baseline: [SubprocessResult] = []
        for (command, arguments) in commands {
            baseline.append(try await workspace.run(command, arguments))
        }
        try workspace.write(#"{ "semantics": "legacy", "block-line-breaks": "kept", "container-scope": "this-resource" }"#)

        for ((command, arguments), expected) in zip(commands, baseline) {
            let ignored = try await workspace.run(command, arguments + ["--no-config"])
            let unrelated = try await workspace.run(command, arguments)
            for run in [ignored, unrelated] {
                #expect(run.exitCode == expected.exitCode, "\(command): \(run.stderr)")
                #expect(run.stdout == expected.stdout, "\(command): \(run.stdout)")
                #expect(run.stderr == expected.stderr, "\(command): \(run.stderr)")
            }
        }
    }

    @Test("behaves alike for genmodel with the default unset features in the file and without a file")
    @MainActor
    func genModelUnchanged() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        let project = workspace.root.appendingPathComponent("families")
        try FileManager.default.copyItem(
            at: ConfigurationTests.fixtureRoot.appendingPathComponent("families"), to: project)
        let ecore = project.appendingPathComponent("model/families.ecore").path
        let output = project.appendingPathComponent("model/families.genmodel")

        let plain = try await workspace.run("genmodel", [ecore])
        let plainText = try? String(contentsOf: output, encoding: .utf8)
        try workspace.write(#"{ "unset-features": "defaults" }"#)
        try? FileManager.default.removeItem(at: output)
        let configured = try await workspace.run("genmodel", [ecore])
        let configuredText = try? String(contentsOf: output, encoding: .utf8)

        #expect(plain.succeeded, "\(plain.stdout)\(plain.stderr)")
        #expect(configured.succeeded, "\(configured.stdout)\(configured.stderr)")
        #expect(plainText != nil)
        #expect(configuredText == plainText)
    }

    // MARK: - Errors

    @Test(
        "rejects an invalid value in the configuration file, naming the file, the key and the value",
        arguments: ["inspect", "validate", "statistics", "query", "compare", "convert", "create", "genmodel"])
    @MainActor
    func invalidValue(command: String) async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "encoding": "klingon" }"#)
        let arguments: [String]
        switch command {
        case "create": arguments = ["--metamodel", workspace.grammar, "--root-class", "Num", "--output", workspace.output + ".xmi", "--force"]
        case "genmodel": arguments = [workspace.notes]
        default: arguments = Self.readingCommands(workspace.metamodel, output: workspace.output).first { $0.0 == command }?.1 ?? []
        }

        let result = try await workspace.run(command, arguments)
        let ignored = try await workspace.run(command, arguments + ["--no-config"])

        #expect(result.exitCode == 1, "\(command): \(result.stdout)\(result.stderr)")
        for text in [Self.configurationFile, "klingon", "'encoding'"] {
            #expect(result.stderr.contains(text), "\(command): \(text) is missing from: \(result.stderr)")
        }
        #expect(ignored.succeeded, "\(command): \(ignored.stdout)\(ignored.stderr)")
    }

    @Test("rejects an unknown key in the configuration file, as the other tools do")
    @MainActor
    func unknownKey() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "colour": "blue" }"#)

        let result = try await workspace.run("inspect", [workspace.grammar])

        #expect(!result.succeeded)
        #expect(result.stderr.contains(Self.configurationFile), "\(result.stderr)")
        #expect(result.stderr.contains("colour"), "\(result.stderr)")
    }

    // MARK: - Help

    @Test(
        "documents --config, --no-config and the configuration file in the help",
        arguments: ["inspect", "validate", "statistics", "query", "compare", "convert", "create", "genmodel"])
    @MainActor
    func help(command: String) async throws {
        let result = try await executeSwiftEcore(command: command, arguments: ["--help"])

        #expect(result.succeeded)
        for text in ["--config <file>", "--no-config", Self.configurationFile] {
            #expect(result.stdout.contains(text), "\(command): \(text) is missing from the help")
        }
    }

    // MARK: - Level crossing

    /// A multi-level model whose bottom level refers to a clabject one level up without
    /// declaring it.
    static let crossing = """
        Model Cycling@2 {
          Node BicycleType {
            alternative : BicycleType[0..1];
          }
        }
        Cycling Catalogue {
          BicycleType Racer {}
        }
        Catalogue Inventory {
          Racer bike {
            alternative = Racer;
          }
        }

        """

    @Test("checks level crossings as the configuration file says, unless the command line says otherwise")
    @MainActor
    func levelCrossing() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        let model = try workspace.write(Self.crossing, to: "crossing.mdepth").path
        let standard = try await workspace.run("validate", [model])
        try workspace.write(#"{ "level-crossing": "non-strict" }"#)

        let configured = try await workspace.run("validate", [model])
        let overridden = try await workspace.run("validate", [model, "--level-crossing", "declared"])
        let inspected = try await workspace.run("inspect", [model])
        let converted = try await workspace.run("convert", [model, workspace.root.appendingPathComponent("c.xmi").path, "--validate", "--force"])

        #expect(!standard.succeeded, "\(standard.stdout)")
        #expect(configured.succeeded, "\(configured.stdout)\(configured.stderr)")
        #expect(!overridden.succeeded, "\(overridden.stdout)")
        #expect(inspected.stdout.contains("Level crossing: non-strict"), "\(inspected.stdout)")
        #expect(converted.succeeded, "\(converted.stdout)\(converted.stderr)")
    }

    // MARK: - Complete OCL

    /// A Complete OCL document whose invariant no note satisfies.
    static let failingConstraints = "package notes\ncontext Note\ninv Never: false\nendpackage\n"

    /// A Complete OCL document whose invariant every note satisfies.
    static let passingConstraints = "package notes\ncontext Note\ninv Always: true\nendpackage\n"

    @Test("applies the Complete OCL documents of the configuration file, relative to its directory")
    @MainActor
    func completeOCL() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(Self.failingConstraints, to: "rules/never.ocl")
        try workspace.write(#"{ "ocl": ["rules/never.ocl"] }"#)
        let arguments = [workspace.note, "--metamodel", workspace.notes]

        let configured = try await workspace.run("validate", arguments)
        let ignored = try await workspace.run("validate", arguments + ["--no-config"])
        let inspected = try await workspace.run("inspect", [workspace.notes, "--detail", "full"])

        #expect(!configured.succeeded, "\(configured.stdout)")
        #expect(configured.stdout.contains("Never"), "\(configured.stdout)")
        #expect(ignored.succeeded, "\(ignored.stdout)\(ignored.stderr)")
        #expect(inspected.succeeded, "\(inspected.stdout)\(inspected.stderr)")
        #expect(inspected.stdout.contains("Never"), "\(inspected.stdout)")
    }

    @Test("keeps absolute Complete OCL paths of the configuration file, and lets --ocl replace them")
    @MainActor
    func completeOCLAbsoluteAndOverride() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        let never = try workspace.write(Self.failingConstraints, to: "elsewhere/never.ocl")
        let always = try workspace.write(Self.passingConstraints, to: "always.ocl")
        let custom = try workspace.write(#"{ "ocl": ["\#(never.path)"] }"#, to: "settings/custom.json")
        let arguments = [workspace.note, "--metamodel", workspace.notes, "--config", custom.path]

        let configured = try await workspace.run("validate", arguments)
        let overridden = try await workspace.run("validate", arguments + ["--ocl", always.path])

        #expect(!configured.succeeded, "\(configured.stdout)")
        #expect(configured.stdout.contains("Never"), "\(configured.stdout)")
        #expect(overridden.succeeded, "\(overridden.stdout)\(overridden.stderr)")
        #expect(!overridden.stdout.contains("Never"), "\(overridden.stdout)")
    }

    @Test("rejects Complete OCL documents that are not a list of strings")
    @MainActor
    func completeOCLWrongType() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "ocl": "rules.ocl" }"#)

        let result = try await workspace.run("inspect", [workspace.notes])

        #expect(result.exitCode == 1)
        #expect(result.stderr.contains("'ocl'"), "\(result.stderr)")
        #expect(result.stderr.contains("a list of strings"), "\(result.stderr)")
    }

    // MARK: - create

    @Test("reads the metamodels of create in the encoding of --encoding or of the configuration file")
    @MainActor
    func createEncoding() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        let model = workspace.root.appendingPathComponent("book.xmi").path
        let arguments = ["--metamodel", workspace.metamodel, "--root-class", "Book", "--output", model, "--force"]

        let detected = try await workspace.run("create", arguments)
        let named = try await workspace.run("create", arguments + ["--encoding", "latin1"])
        let invalid = try await workspace.run("create", arguments + ["--encoding", "UTF-8"])
        try workspace.write(#"{ "encoding": "ISO-8859-1" }"#)
        let configured = try await workspace.run("create", arguments)

        #expect(detected.succeeded, "\(detected.stdout)\(detected.stderr)")
        #expect(detected.stderr.contains(Self.fallbackWarning), "\(detected.stderr)")
        #expect(named.succeeded, "\(named.stdout)\(named.stderr)")
        #expect(!named.stderr.contains(Self.fallbackWarning), "\(named.stderr)")
        #expect(invalid.exitCode == 1, "\(invalid.stdout)\(invalid.stderr)")
        #expect(configured.succeeded, "\(configured.stdout)\(configured.stderr)")
        #expect(!configured.stderr.contains(Self.fallbackWarning), "\(configured.stderr)")
    }

    // MARK: - genmodel

    /// Writes the generator model of the families fixture from the working directory.
    ///
    /// - Parameters:
    ///   - workspace: The repository.
    ///   - extra: The arguments after the model.
    ///   - environment: The environment variables to set.
    /// - Returns: The result of the command and the text of the generator model, if any.
    @MainActor
    private func genModel(
        in workspace: Workspace, _ extra: [String] = [], environment: [String: String?] = [:]
    ) async throws -> (result: SubprocessResult, text: String?) {
        let project = workspace.root.appendingPathComponent("families")
        if !FileManager.default.fileExists(atPath: project.path) {
            try FileManager.default.copyItem(
                at: ConfigurationTests.fixtureRoot.appendingPathComponent("families"), to: project)
        }
        let output = project.appendingPathComponent("model/families.genmodel")
        try? FileManager.default.removeItem(at: output)
        let result = try await executeSwiftEcore(
            command: "genmodel", arguments: [project.appendingPathComponent("model/families.ecore").path] + extra,
            workingDirectory: workspace.workingDirectory, environment: environment)
        return (result, try? String(contentsOf: output, encoding: .utf8))
    }

    @Test("writes the same generator model with the standard semantics, given or not, and accepts legacy")
    @MainActor
    func genModelSemantics() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let plain = try await genModel(in: workspace)
        let standard = try await genModel(in: workspace, ["--semantics", "standard", "--container-scope", "any-resource"])
        let legacy = try await genModel(in: workspace, ["--semantics", "legacy"])
        let environment = try await genModel(in: workspace, environment: [semanticsVariable: "legacy"])
        try workspace.write(#"{ "semantics": "legacy", "container-scope": "this-resource" }"#)
        let configured = try await genModel(in: workspace)

        for run in [plain, standard, legacy, environment, configured] {
            #expect(run.result.succeeded, "\(run.result.stdout)\(run.result.stderr)")
            #expect(run.text != nil)
        }
        #expect(standard.text == plain.text)
    }

    @Test("rejects an invalid value of the environment variable for genmodel, naming it")
    @MainActor
    func genModelInvalidEnvironment() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (result, text) = try await genModel(in: workspace, environment: [semanticsVariable: "0.6"])

        #expect(!result.succeeded)
        #expect(text == nil)
        #expect(result.stderr.contains(semanticsVariable), "\(result.stderr)")
    }

    @Test("documents --semantics and --container-scope for genmodel, and --encoding for create")
    @MainActor
    func newOptionsHelp() async throws {
        let genModel = try await executeSwiftEcore(command: "genmodel", arguments: ["--help"])
        let create = try await executeSwiftEcore(command: "create", arguments: ["--help"])

        for text in ["--semantics <standard|legacy>", "--container-scope", semanticsVariable] {
            #expect(genModel.stdout.contains(text), "\(text) is missing from the help of genmodel")
        }
        #expect(create.stdout.contains("--encoding <"), "\(create.stdout)")
    }

    // MARK: - Directories of Complete OCL documents

    @Test("applies every Complete OCL document of a directory given with --ocl, alone or with files")
    @MainActor
    func completeOCLDirectory() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(Self.failingConstraints, to: "rules/never.ocl")
        try workspace.write(Self.passingConstraints, to: "rules/always.ocl")
        let extra = try workspace.write(
            "package notes\ncontext Note\ninv Extra: false\nendpackage\n", to: "extra.ocl")
        let rules = workspace.root.appendingPathComponent("rules").path
        let arguments = [workspace.note, "--metamodel", workspace.notes]

        let directory = try await workspace.run("validate", arguments + ["--ocl", rules])
        let mixed = try await workspace.run("validate", arguments + ["--ocl", rules, "--ocl", extra.path])

        #expect(!directory.succeeded, "\(directory.stdout)")
        #expect(directory.stdout.contains("Never"), "\(directory.stdout)")
        #expect(directory.stdout.contains("of 2 check(s)"), "\(directory.stdout)")
        #expect(mixed.stdout.contains("Extra"), "\(mixed.stdout)")
        #expect(mixed.stdout.contains("of 3 check(s)"), "\(mixed.stdout)")
    }

    @Test("applies the directories that the configuration file lists")
    @MainActor
    func completeOCLDirectoryFromFile() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(Self.failingConstraints, to: "rules/never.ocl")
        try workspace.write(#"{ "ocl": ["rules"] }"#)

        let result = try await workspace.run("validate", [workspace.note, "--metamodel", workspace.notes])

        #expect(!result.succeeded, "\(result.stdout)")
        #expect(result.stdout.contains("Never"), "\(result.stdout)")
    }

    @Test("reports a missing Complete OCL document of the command line or the file as an error")
    @MainActor
    func completeOCLMissing() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        let arguments = [workspace.note, "--metamodel", workspace.notes]

        let commandLine = try await workspace.run("validate", arguments + ["--ocl", "absent.ocl"])
        try workspace.write(#"{ "ocl": ["absent.ocl"] }"#)
        let configured = try await workspace.run("validate", arguments)

        #expect(commandLine.exitCode == 1, "\(commandLine.stdout)\(commandLine.stderr)")
        #expect(commandLine.stderr.contains("absent.ocl"), "\(commandLine.stderr)")
        #expect(configured.exitCode == 1, "\(configured.stdout)\(configured.stderr)")
        #expect(configured.stderr.contains(workspace.root.appendingPathComponent("absent.ocl").lastPathComponent))
    }

    @Test("warns about a directory without Complete OCL documents and goes on")
    @MainActor
    func completeOCLEmptyDirectory() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        let empty = workspace.root.appendingPathComponent("empty")
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)

        let result = try await workspace.run(
            "validate", [workspace.note, "--metamodel", workspace.notes, "--ocl", empty.path])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stderr.contains("warning: \(empty.path): "), "\(result.stderr)")
    }
}
