//
// UnitTests.swift
// swift-xtend-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import EMFBase
import Foundation
import ModellingGenerators
import Synchronization
import Testing
import Xtend

@testable import swift_xtend

/// Opens a session on the library fixtures in a directory.
///
/// - Parameters:
///   - directory: The directory that holds the fixtures.
///   - source: The Xtend source file.
///   - extra: Further arguments.
/// - Returns: The session.
/// - Throws: The errors of opening the session.
@MainActor
func librarySession(in directory: URL, source: String = Fixture.report, extra: [String] = []) async throws -> XtendSession {
    let paths = [
        source, "--model", directory.appendingPathComponent(Fixture.libraryModel).path,
        "--metamodel", directory.appendingPathComponent(Fixture.libraryMetamodel).path,
    ]
    let options = try ProgramOptions.parse([directory.appendingPathComponent(paths[0]).path] + paths.dropFirst() + extra)
    return try await XtendSession.open(options)
}

@Suite("Vocabulary and errors")
struct VocabularyTests {
    @Test("The names of the tool, commands and version")
    func names() {
        #expect(SwiftXtendVocabulary.toolName == "swift-xtend")
        #expect(SwiftXtendVocabulary.version == "0.7.0")
        #expect(SwiftXtendCommand.configuration.subcommands.count == 2)
        #expect(RunCommand.configuration.commandName == SwiftXtendVocabulary.Command.run)
        #expect(GenerateCommand.configuration.commandName == SwiftXtendVocabulary.Command.generate)
        #expect(SwiftXtendVocabulary.sourceExtension == "xtend")
    }

    @Test("Every error describes the problem")
    func descriptions() {
        #expect(SwiftXtendError.sourceNotFound("a.xtend").description.contains("a.xtend"))
        #expect(SwiftXtendError.modelNotFound("m.xmi").description == "Model file not found: m.xmi")
        #expect(SwiftXtendError.invalidProgram(1).description == "The Xtend source has 1 error")
        #expect(SwiftXtendError.invalidProgram(2).description == "The Xtend source has 2 errors")
        #expect(SwiftXtendError.noClasses.description.contains("no class"))
        #expect(SwiftXtendError.ambiguousClass(["A", "B"]).description.contains("A, B"))
        #expect(SwiftXtendError.ambiguousClass(["A"]).description.contains("--class"))
        #expect(SwiftXtendError.classNotFound("X", ["A"]).description == "The Xtend source declares no class 'X' (classes: A)")
        #expect(SwiftXtendError.classNotFound("X", []).description == "The Xtend source declares no class 'X'")
        #expect(
            SwiftXtendError.methodNotFound("m", "C", ["a", "b"]).description
                == "The class 'C' declares no method 'm' (methods: a, b)")
        #expect(SwiftXtendError.argumentBinding("m", "why").description == "Cannot call 'm': why")
        #expect(SwiftXtendError.executionFailed("report").description == "report")
        #expect(SwiftXtendError.executionFailed("report").errorDescription == "report")
    }

    @Test("Library errors are wrapped with their diagnostics")
    func wrapping() {
        let xtend = XtendError(.unknownClass, "no class")
        #expect(SwiftXtendError.execution(xtend) == .executionFailed(xtend.description))
        #expect(SwiftXtendError.execution(SwiftXtendError.noClasses) == .noClasses)
        struct Other: Error, CustomStringConvertible { var description: String { "other" } }
        #expect(SwiftXtendError.execution(Other()) == .executionFailed("other"))
    }
}

@Suite("Command line parsing")
struct ParsingTests {
    @Test("run takes a source, a method and its options")
    func run() throws {
        let command = try RunCommand.parse([
            "Report.xtend", "--method", "describe", "--argument", "1", "--argument", "2", "--object", "Emma",
            "-o", "out.xmi", "--model", "a.xmi", "--model", "b.xmi", "-m", "Library.ecore", "--class", "Report",
            "--include", "Helper.xtend", "-v", "--encoding", "latin1",
        ])
        #expect(command.programOptions.source == "Report.xtend")
        #expect(command.method == "describe")
        #expect(command.arguments == ["1", "2"])
        #expect(command.objectName == "Emma")
        #expect(command.output == "out.xmi")
        #expect(command.programOptions.models == ["a.xmi", "b.xmi"])
        #expect(command.programOptions.metamodelOptions.metamodels == ["Library.ecore"])
        #expect(command.programOptions.className == "Report")
        #expect(command.programOptions.includes == ["Helper.xtend"])
        #expect(command.programOptions.verbose)
        #expect(command.programOptions.encodingOptions.explicitEncoding != nil)
    }

    @Test("run requires a method")
    func runRequiresMethod() {
        #expect(throws: (any Error).self) { try RunCommand.parse(["Report.xtend"]) }
    }

    @Test("generate takes an output and output configurations")
    func generate() throws {
        let command = try GenerateCommand.parse([
            "G.xtend", "--model", "a.xmi", "-o", "out", "--output-configuration", "docs=d", "--output-configuration",
            "src=s", "-q",
        ])
        #expect(command.output == "out")
        #expect(command.outputConfigurations == ["docs=d", "src=s"])
        #expect(command.quiet)
        #expect(try GenerateCommand.configurationOption.values(from: command.outputConfigurations) == ["docs": "d", "src": "s"])
    }

    @Test("generate rejects a missing model, a malformed configuration, and quiet with verbose")
    func generateValidation() {
        #expect(throws: (any Error).self) { try GenerateCommand.parse(["G.xtend", "-o", "out"]) }
        #expect(throws: (any Error).self) {
            try GenerateCommand.parse(["G.xtend", "--model", "a", "-o", "out", "--output-configuration", "docs"])
        }
        #expect(throws: (any Error).self) {
            try GenerateCommand.parse(["G.xtend", "--model", "a", "-o", "out", "-q", "-v"])
        }
        #expect(throws: (any Error).self) { try GenerateCommand.parse(["G.xtend", "--model", "a"]) }
    }

    @Test("generate lists files by output configuration")
    func listing() throws {
        let command = try GenerateCommand.parse(["G.xtend", "--model", "a", "-o", "out/"])
        let plain = WrittenFile(path: "A.txt", outputConfiguration: XtendLanguage.defaultOutputConfiguration)
        #expect(command.listing(of: plain, directories: [:]) == "out/A.txt")
        let named = WrittenFile(path: "i.txt", outputConfiguration: "docs")
        #expect(command.listing(of: named, directories: ["docs": "d"]) == "docs:d/i.txt")
        #expect(command.listing(of: named, directories: [:]) == "docs:out/i.txt")
    }
}

@Suite("Argument binding")
@MainActor
struct BindingTests {
    @Test("Literals are converted to the declared types")
    func conversion() throws {
        func convert(_ text: String, _ type: String) throws -> XtendHostValue {
            try ArgumentBinder.converted(text, to: type, parameter: "p", method: "m")
        }
        #expect(try convert("7", "int").intValue == 7)
        #expect(try convert("7", "Long").intValue == 7)
        if case .double(let value) = try convert("2.5", "double") { #expect(value == 2.5) } else { Issue.record("not a double") }
        #expect(try convert("true", "boolean").boolValue == true)
        #expect(try convert("false", "Boolean").boolValue == false)
        #expect(try convert("x", "String").stringValue == "x")
        #expect(throws: SwiftXtendError.argumentBinding("m", "'x' is not a valid int for the parameter 'p'")) {
            try convert("x", "int")
        }
        #expect(throws: SwiftXtendError.self) { try convert("x", "double") }
        #expect(throws: SwiftXtendError.self) { try convert("yes", "boolean") }
    }

    @Test("Untyped literals are inferred")
    func inference() {
        #expect(ArgumentBinder.inferred("3").intValue == 3)
        if case .double(let value) = ArgumentBinder.inferred("3.5") { #expect(value == 3.5) } else { Issue.record("not a double") }
        #expect(ArgumentBinder.inferred("true").boolValue == true)
        #expect(ArgumentBinder.inferred("false").boolValue == false)
        #expect(ArgumentBinder.inferred("text").stringValue == "text")
    }

    @Test("Parameters bind to the model, its objects and literals")
    func binding() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Fixture.copyAll(to: directory)
        let session = try await librarySession(in: directory)
        let report = try session.selectClass(named: nil)
        func parameters(_ name: String) -> [XtendParameter] { report.methods.first { $0.name == name }?.parameters ?? [] }
        let binder = ArgumentBinder(models: session.models, literals: ["400"], objectName: nil)
        let library = try await binder.bind(parameters("longBooks"), method: "longBooks")
        #expect(library.count == 2)
        #expect(library[0].objectID != nil)
        #expect(library[1].intValue == 400)
        let resource = try await ArgumentBinder(models: session.models, literals: [], objectName: nil)
            .bind(parameters("resourceRoots"), method: "resourceRoots")
        if case .resource = resource[0] {} else { Issue.record("expected a resource") }
        let books = try await ArgumentBinder(models: session.models, literals: [], objectName: nil)
            .bind(parameters("allBooks"), method: "allBooks")
        #expect(books[0].elements?.count == 3)
        let emma = try await ArgumentBinder(models: session.models, literals: [], objectName: "Emma")
            .bind(parameters("pageCount"), method: "pageCount")
        let formatted = await ResultFormatter(models: session.models).format(emma[0])
        #expect(formatted == "Book(Emma)")
    }

    @Test("Binding failures name the parameter")
    func failures() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Fixture.copyAll(to: directory)
        let session = try await librarySession(in: directory)
        let report = try session.selectClass(named: nil)
        let longBooks = report.methods.first { $0.name == "longBooks" }!.parameters
        let maths = try await librarySession(in: directory, source: "Maths.xtend")
        let needsFile = try maths.selectClass(named: nil).methods.first { $0.name == "needsFile" }!.parameters
        let none = ArgumentBinder(models: [], literals: [], objectName: nil)
        await #expect(throws: SwiftXtendError.self) { try await none.bind(longBooks, method: "longBooks") }
        let withModel = ArgumentBinder(models: session.models, literals: [], objectName: nil)
        await #expect(throws: SwiftXtendError.self) { try await withModel.bind(longBooks, method: "longBooks") }
        await #expect(throws: SwiftXtendError.self) { try await withModel.bind(needsFile, method: "needsFile") }
        let surplus = ArgumentBinder(models: session.models, literals: ["1", "2", "3"], objectName: nil)
        await #expect(throws: SwiftXtendError.self) { try await surplus.bind(longBooks, method: "longBooks") }
    }

    @Test("Untyped parameters take a literal or else the first object")
    func untyped() async throws {
        let parameter = XtendParameter(name: "x", range: SourceRange(start: SourcePosition(utf8Offset: 0, line: 1, column: 1), end: SourcePosition(utf8Offset: 0, line: 1, column: 1)))
        let literal = try await ArgumentBinder(models: [], literals: ["5"], objectName: nil).bind([parameter], method: "m")
        #expect(literal[0].intValue == 5)
        await #expect(throws: SwiftXtendError.self) {
            try await ArgumentBinder(models: [], literals: [], objectName: nil).bind([parameter], method: "m")
        }
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Fixture.copyAll(to: directory)
        let session = try await librarySession(in: directory)
        let object = try await ArgumentBinder(models: session.models, literals: [], objectName: nil).bind([parameter], method: "m")
        #expect(object[0].objectID != nil)
    }
}

@Suite("Sessions and results")
@MainActor
struct SessionTests {
    @Test("A session selects the only class, a named class, or fails")
    func classes() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Fixture.copyAll(to: directory)
        let single = try await librarySession(in: directory)
        #expect(try single.selectClass(named: nil).name == "Report")
        #expect(try single.selectClass(named: "Report").qualifiedName == "Report")
        #expect(throws: SwiftXtendError.classNotFound("Nope", ["Report"])) { try single.selectClass(named: "Nope") }
        let pair = try await librarySession(in: directory, source: "Pair.xtend")
        #expect(throws: SwiftXtendError.ambiguousClass(["Pair", "Second"])) { try pair.selectClass(named: nil) }
        #expect(try pair.selectClass(named: "Second").name == "Second")
        #expect(pair.classes.count == 2)
        #expect(pair.models.count == 1)
        #expect(try pair.selectGenerator(named: nil) == nil)
        #expect(try pair.selectGenerator(named: "Second")?.name == "Second")
        let generator = try await librarySession(in: directory, source: "Helper.xtend", extra: ["--include", directory.appendingPathComponent(Fixture.catalogueGenerator).path])
        #expect(try generator.selectGenerator(named: nil)?.name == "Catalogue")
        #expect(throws: SwiftXtendError.classNotFound("Nope", ["Helper", "Catalogue"])) { try generator.selectGenerator(named: "Nope") }
    }

    @Test("A dispatch method is bound by the parameters of its dispatcher, other methods by their own")
    func parameterLists() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Fixture.copyAll(to: directory)
        let labels = try await librarySession(in: directory, source: Fixture.labels)
        let labelClass = try labels.selectClass(named: nil)
        let label = labels.parameterLists(of: "label", in: labelClass)
        #expect(label.map { $0.map { $0.type?.name } } == [["EObject"]])
        let weigh = labels.parameterLists(of: "weigh", in: labelClass)
        #expect(weigh.map { $0.map { $0.type?.name } } == [["EObject", "int"]])
        let report = try await librarySession(in: directory)
        let reportClass = try report.selectClass(named: nil)
        #expect(report.parameterLists(of: "pageCount", in: reportClass).map { $0.map { $0.type?.name } } == [["Book"]])
        #expect(report.parameterLists(of: "missing", in: reportClass).isEmpty)
    }

    @Test("A session reports missing files and invalid sources")
    func failures() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Fixture.copyAll(to: directory)
        let missingSource = try ProgramOptions.parse([directory.appendingPathComponent("Nope.xtend").path])
        await #expect(throws: SwiftXtendError.self) { try await XtendSession.open(missingSource) }
        let missingModel = try ProgramOptions.parse([
            directory.appendingPathComponent("Helper.xtend").path, "--model", directory.appendingPathComponent("no.xmi").path,
        ])
        await #expect(throws: SwiftXtendError.self) { try await XtendSession.open(missingModel) }
        let invalid = try ProgramOptions.parse([directory.appendingPathComponent("Wrong.xtend").path])
        do {
            _ = try await XtendSession.open(invalid)
            Issue.record("expected an error")
        } catch let error as SwiftXtendError {
            if case .invalidProgram(let count) = error { #expect(count > 0) } else { Issue.record("\(error)") }
        }
        let empty = directory.appendingPathComponent("Empty.xtend")
        try "".write(to: empty, atomically: true, encoding: .utf8)
        let none = try await XtendSession.open(try ProgramOptions.parse([empty.path]))
        #expect(throws: SwiftXtendError.noClasses) { try none.selectClass(named: nil) }
    }

    @Test("A metamodel file can be the model")
    func metamodelAsModel() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Fixture.copyAll(to: directory)
        let options = try ProgramOptions.parse([
            directory.appendingPathComponent("Helper.xtend").path, "--model",
            directory.appendingPathComponent("Library.ecore").path,
        ])
        let session = try await XtendSession.open(options)
        #expect(session.models.count == 1)
        #expect(await session.models[0].getRootObjects().count == 1)
    }

    @Test("Values are formatted like Xtend's toString")
    func formatting() async {
        let formatter = ResultFormatter(models: [])
        #expect(await formatter.format(.string("x")) == "x")
        #expect(await formatter.format(.int(3)) == "3")
        #expect(await formatter.format(.bool(true)) == "true")
        #expect(await formatter.format(.double(1.5)) == "1.5")
        #expect(await formatter.format(.list([.int(1), .string("a")])) == "[1, a]")
        #expect(await formatter.format(.set([.int(1)])) == "[1]")
        #expect(await formatter.format(.map([(key: .string("k"), value: .int(2))])) == "{k=2}")
        #expect(await formatter.format(.pair(.string("k"), .int(2))) == "k->2")
        #expect(await formatter.format(.other("text")) == "text")
        #expect(await formatter.format(.null) == "null")
    }

    @Test("Objects print their class and name")
    func objectFormatting() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Fixture.copyAll(to: directory)
        let session = try await librarySession(in: directory)
        let root = try #require(await session.models[0].getRootObjects().first)
        let formatter = ResultFormatter(models: session.models)
        #expect(await formatter.format(.object(root.id, session.models[0])) == "Library(City Library)")
        #expect(await formatter.format(.object(root.id, nil)) == "Library(City Library)")
        #expect(await formatter.format(.object(EUUID(), nil)).hasPrefix("EObject("))
    }

    @Test("Generated files are logged with progress")
    func logging() async throws {
        let directory = try Fixture.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let updates = UpdateBox()
        let log = GeneratedFileLog { update in updates.append(update) }
        let access = LoggingFileSystemAccess(
            base: XtendDirectoryFileSystemAccess(outputDirectory: directory), log: log)
        try await access.generateFile("a/b.txt", outputConfiguration: XtendLanguage.defaultOutputConfiguration, contents: "x")
        try await access.generateFile("c.txt", outputConfiguration: XtendLanguage.defaultOutputConfiguration, contents: "y")
        #expect(try String(contentsOf: directory.appendingPathComponent("a/b.txt"), encoding: .utf8) == "x")
        #expect(await log.files.map(\.path) == ["a/b.txt", "c.txt"])
        #expect(updates.values.map(\.completed) == [1, 2])
        #expect(updates.values.map(\.message) == ["a/b.txt", "c.txt"])
        await #expect(throws: XtendError.self) {
            try await access.generateFile("../escape.txt", outputConfiguration: XtendLanguage.defaultOutputConfiguration, contents: "")
        }
        #expect(await log.files.count == 2)
    }
}

/// A thread-safe collection of progress updates for tests.
final class UpdateBox: Sendable {
    /// The lock-protected storage.
    private let storage = Mutex<[GenerationProgressUpdate]>([])

    /// The updates received so far.
    var values: [GenerationProgressUpdate] { storage.withLock { $0 } }

    /// Adds an update.
    ///
    /// - Parameter update: The update.
    func append(_ update: GenerationProgressUpdate) { storage.withLock { $0.append(update) } }
}
