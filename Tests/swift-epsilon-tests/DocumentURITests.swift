//
// DocumentURITests.swift
// swift-epsilon-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import Testing

/// Tests for how the commands of swift-epsilon write references from a target or stored model
/// to elements of another document: relative to the written model by default, and as absolute
/// URIs with `--document-uris absolute` or the `document-uris` key of the configuration file.
@Suite("swift-epsilon - document URIs of written models", .serialized)
struct DocumentURITests {
    /// The long name of the option.
    static let option = "--document-uris"

    /// The name of the configuration file.
    static let configurationFile = ".swift-modelling.json"

    /// A metamodel of projects that contain tasks.
    static let tasks = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="tasks"
            nsURI="http://www.example.org/tasks" nsPrefix="tasks">
          <eClassifiers xsi:type="ecore:EClass" name="Project">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
            <eStructuralFeatures xsi:type="ecore:EReference" name="tasks" upperBound="-1"
                eType="#//Task" containment="true"/>
          </eClassifiers>
          <eClassifiers xsi:type="ecore:EClass" name="Task">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="done"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EBoolean"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// A metamodel of notes, each referring to one task and to a list of tasks of the metamodel of
    /// projects beside it.
    static let notes = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="notes"
            nsURI="http://www.example.org/notes" nsPrefix="notes">
          <eClassifiers xsi:type="ecore:EClass" name="Note">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
            <eStructuralFeatures xsi:type="ecore:EReference" name="blocker"
                eType="ecore:EClass Tasks.ecore#//Task"/>
            <eStructuralFeatures xsi:type="ecore:EReference" name="follows" upperBound="-1"
                eType="ecore:EClass Tasks.ecore#//Task"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// A project with three tasks, of which the last two are done.
    static let taskModel = """
        <?xml version="1.0" encoding="UTF-8"?>
        <tasks:Project xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:tasks="http://www.example.org/tasks" name="release">
          <tasks name="drafting"/>
          <tasks name="reviewing" done="true"/>
          <tasks name="publishing" done="true"/>
        </tasks:Project>
        """

    /// A note that refers to the tasks that are done, in a project beside it.
    static let noteModel = """
        <?xml version="1.0" encoding="UTF-8"?>
        <notes:Note xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:notes="http://www.example.org/notes" name="drafting">
          <blocker href="tasks.xmi#//@tasks.1"/>
          <follows href="tasks.xmi#//@tasks.1"/>
          <follows href="tasks.xmi#//@tasks.2"/>
        </notes:Note>
        """

    /// A program that creates a note for the open task, referring to the tasks that are done.
    static let program = """
        var done = Tasks!Task.all.select(t | t.done);
        var note = new Notes!Note;
        note.name = Tasks!Task.all.select(t | not t.done).first().name;
        note.blocker = done.first();
        note.follows.addAll(done);
        """

    /// A transformation that writes a note for each open task, referring to the tasks that are
    /// done, which no rule transforms.
    static let transformation = """
        rule OpenTask transform t : Tasks!Task to n : Notes!Note {
          guard : not t.done
          n.name = t.name;
          n.blocker = Tasks!Task.all.select(x | x.done).first();
          n.follows.addAll(Tasks!Task.all.select(x | x.done));
        }
        """

    /// A program that renames the note it is given.
    static let rename = """
        Notes!Note.all.first().name = 'renamed';
        """

    /// The path of the project, relative to the workspace.
    static let project = "models/tasks.xmi"

    /// A directory with the metamodels, the project, a note that refers to it and the programs.
    struct Workspace {
        /// The temporary directory.
        let root: URL

        /// Creates the directory.
        ///
        /// - Throws: An error if a file cannot be written.
        init() throws {
            root = try Fixture.temporaryDirectory()
            try write(DocumentURITests.tasks, to: "Tasks.ecore")
            try write(DocumentURITests.notes, to: "Notes.ecore")
            try write(DocumentURITests.taskModel, to: DocumentURITests.project)
            try write(DocumentURITests.noteModel, to: "models/notes.xmi")
            try write(DocumentURITests.program, to: "note.eol")
            try write(DocumentURITests.transformation, to: "notes.etl")
            try write(DocumentURITests.rename, to: "rename.eol")
        }

        /// Writes a file at a path relative to the directory, creating its directory.
        ///
        /// - Parameters:
        ///   - text: The contents.
        ///   - path: The path, relative to the directory.
        /// - Throws: An error if the file cannot be written.
        func write(_ text: String, to path: String) throws {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try text.write(to: url, atomically: true, encoding: .utf8)
        }

        /// Reads a file at a path relative to the directory.
        ///
        /// - Parameter path: The path, relative to the directory.
        /// - Returns: The text of the file, or `nil` if it cannot be read.
        func text(at path: String) -> String? {
            try? String(contentsOf: root.appendingPathComponent(path), encoding: .utf8)
        }

        /// The texts by which a written file could name the directory.
        var absoluteForms: [String] {
            [root.path, root.standardizedFileURL.path, root.resolvingSymlinksInPath().path]
        }

        /// Whether a reference names the first finished task of the project by an absolute file URI.
        ///
        /// The URI names the directory in one of its ``absoluteForms``, or in the form in which
        /// the current directory of the tool names it.
        ///
        /// - Parameter href: The reference.
        /// - Returns: `true` if the reference is such a URI.
        func isAbsoluteReference(_ href: String?) -> Bool {
            guard let href, href.hasPrefix("file:") else { return false }
            return href.hasSuffix("/" + DocumentURITests.project + "#//@tasks.1")
                && absoluteForms.contains { href.contains($0) }
        }

        /// Removes the directory.
        func remove() {
            try? FileManager.default.removeItem(at: root)
        }
    }

    /// The arguments that read the project and name both metamodels.
    static let projectArguments = ["--model", "Tasks=\(project)", "-m", "Tasks.ecore", "-m", "Notes.ecore"]

    /// Runs the program that creates a note into a target model.
    ///
    /// - Parameters:
    ///   - workspace: The workspace.
    ///   - target: The path of the target model, relative to the workspace.
    ///   - extra: Further arguments.
    /// - Returns: The result of the command and the text of the target model, if any.
    private func createNote(
        in workspace: Workspace, target: String, extra: [String] = []
    ) async throws -> (run: ToolRun, text: String?) {
        let run = try await runSwiftEpsilon(
            ["eol", "run", "note.eol", "--target", "Notes=\(target)"] + Self.projectArguments + extra, in: workspace.root)
        return (run, workspace.text(at: target))
    }

    /// The `href` values of the elements of a feature in an XMI text, in order.
    ///
    /// - Parameters:
    ///   - feature: The name of the feature.
    ///   - text: The XMI document.
    /// - Returns: The values of the `href` attributes.
    static func hrefs(_ feature: String, in text: String) -> [String] {
        let opening = "<\(feature) href=\""
        return text.split(separator: "\n").compactMap { line in
            guard let start = line.range(of: opening) else { return nil }
            let rest = line[start.upperBound...]
            return rest.firstIndex(of: "\"").map { String(rest[..<$0]) }
        }
    }

    /// The last reference that an attribute of a feature holds in an XMI text.
    ///
    /// A model written in the plain reference style holds references as attribute values, each
    /// possibly preceded by the class of its target.
    ///
    /// - Parameters:
    ///   - feature: The name of the feature.
    ///   - text: The XMI document.
    /// - Returns: The last whitespace-separated part of the first attribute of the feature.
    static func attributeReference(_ feature: String, in text: String) -> String? {
        guard let start = text.range(of: " \(feature)=\"") else { return nil }
        let rest = text[start.upperBound...]
        return rest.firstIndex(of: "\"").flatMap { rest[..<$0].split(separator: " ").last.map(String.init) }
    }

    /// Loads a written note and the names of the objects that it refers to.
    ///
    /// - Parameters:
    ///   - workspace: The workspace with the metamodels.
    ///   - path: The path of the note, relative to the workspace.
    /// - Returns: The name of the blocker and the names of the followed objects.
    /// - Throws: An error if the model cannot be loaded or a reference does not resolve.
    static func referencedNames(in workspace: Workspace, path: String) async throws -> (blocker: String, follows: [String]) {
        let set = ResourceSet()
        let loaded = try await ModelIO.load(
            url: workspace.root.appendingPathComponent(path), resourceSet: set,
            metamodels: [workspace.root.appendingPathComponent("Tasks.ecore"), workspace.root.appendingPathComponent("Notes.ecore")])
        let note = try #require(await loaded.resource.getRootObjects().first as? DynamicEObject)
        var names: [String] = []
        for value in elements(of: note.eGet("blocker")) + elements(of: note.eGet("follows")) {
            let proxy = try #require(value as? ResourceProxy, "\(value)")
            let object = try #require(await proxy.resolveObject(in: set) as? DynamicEObject, "\(proxy)")
            names.append(try #require(object.eGet("name") as? String))
        }
        return (try #require(names.first), Array(names.dropFirst()))
    }

    /// The elements of a single or many-valued feature value.
    ///
    /// - Parameter value: The value of the feature.
    /// - Returns: The elements of a list, the value itself, or nothing for an unset feature.
    static func elements(of value: (any EcoreValue)?) -> [any EcoreValue] {
        switch value {
        case let proxies as [ResourceProxy]: return proxies
        case let array as EcoreValueArray: return array.values
        case let single?: return [single]
        case nil: return []
        }
    }

    /// Checks that a written note refers to the project by a relative URI and holds no absolute path.
    ///
    /// - Parameters:
    ///   - text: The text of the note.
    ///   - relative: The relative URI of the project from the note.
    ///   - workspace: The workspace.
    ///   - path: The path of the note, relative to the workspace.
    private func expectRelative(_ text: String?, _ relative: String, in workspace: Workspace, path: String) async throws {
        let output = try #require(text)
        #expect(Self.hrefs("blocker", in: output) == [relative + "#//@tasks.1"], "\(output)")
        #expect(Self.hrefs("follows", in: output) == [relative + "#//@tasks.1", relative + "#//@tasks.2"], "\(output)")
        #expect(!output.contains("file:"), "\(output)")
        for absolute in workspace.absoluteForms {
            #expect(!output.contains(absolute), "\(output)")
        }
        let names = try await Self.referencedNames(in: workspace, path: path)
        #expect(names.blocker == "reviewing")
        #expect(names.follows == ["reviewing", "publishing"])
    }

    /// Locations of the target model, with the relative URI of the project in it.
    static let layouts: [(target: String, relative: String)] = [
        ("models/notes-out.xmi", "tasks.xmi"),
        ("output/notes.xmi", "../models/tasks.xmi"),
        ("notes.xmi", "models/tasks.xmi"),
    ]

    @Test("eol run refers from a target model to another model by a relative URI by default", arguments: layouts)
    func targetRelativeByDefault(layout: (target: String, relative: String)) async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (run, text) = try await createNote(in: workspace, target: layout.target)

        #expect(run.succeeded, "\(run.error)")
        try await expectRelative(text, layout.relative, in: workspace, path: layout.target)
    }

    @Test("etl transform refers from a target model to a source model by a relative URI by default")
    func transformRelativeByDefault() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let run = try await runSwiftEpsilon(
            ["etl", "transform", "notes.etl", "--target", "Notes=output/notes.xmi"] + Self.projectArguments,
            in: workspace.root)

        #expect(run.succeeded, "\(run.error)")
        try await expectRelative(
            workspace.text(at: "output/notes.xmi"), "../models/tasks.xmi", in: workspace, path: "output/notes.xmi")
    }

    @Test("eol run stores a model in another directory with its references relative to the new file")
    func storedRelative() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let run = try await runSwiftEpsilon(
            ["eol", "run", "rename.eol", "--model", "Notes=models/notes.xmi", "--store", "Notes=output/notes.xmi",
             "-m", "Tasks.ecore", "-m", "Notes.ecore"], in: workspace.root)

        #expect(run.succeeded, "\(run.error)")
        let text = workspace.text(at: "output/notes.xmi")
        #expect(text?.contains("name=\"renamed\"") == true, "\(text ?? "")")
        try await expectRelative(text, "../models/tasks.xmi", in: workspace, path: "output/notes.xmi")
    }

    @Test("eol run stores a model in place with its references still relative")
    func storedInPlace() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let run = try await runSwiftEpsilon(
            ["eol", "run", "rename.eol", "--model", "Notes=models/notes.xmi", "--store", "Notes",
             "-m", "Tasks.ecore", "-m", "Notes.ecore"], in: workspace.root)

        #expect(run.succeeded, "\(run.error)")
        try await expectRelative(workspace.text(at: "models/notes.xmi"), "tasks.xmi", in: workspace, path: "models/notes.xmi")
    }

    @Test(
        "writes the absolute URI of the other model with --document-uris absolute",
        arguments: [[], ["--reference-style", "plain"]])
    func absoluteOptOut(style: [String]) async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (run, text) = try await createNote(in: workspace, target: "output/notes.xmi", extra: [Self.option, "absolute"] + style)

        #expect(run.succeeded, "\(run.error)")
        let output = try #require(text)
        #expect(
            workspace.isAbsoluteReference(
                Self.hrefs("blocker", in: output).first ?? Self.attributeReference("blocker", in: output)),
            "\(output)")
        #expect(!output.contains("../models/tasks.xmi"), "\(output)")
        let names = try await Self.referencedNames(in: workspace, path: "output/notes.xmi")
        #expect(names.follows == ["reviewing", "publishing"])
    }

    @Test("refers to the other model by a relative URI with the plain reference style")
    func relativePlain() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (run, text) = try await createNote(in: workspace, target: "output/notes.xmi", extra: ["--reference-style", "plain"])

        #expect(run.succeeded, "\(run.error)")
        let output = try #require(text)
        #expect(output.contains("../models/tasks.xmi#//@tasks.1"), "\(output)")
        #expect(!output.contains("file:"), "\(output)")
        let names = try await Self.referencedNames(in: workspace, path: "output/notes.xmi")
        #expect(names.blocker == "reviewing")
    }

    @Test("writes the same target with --document-uris relative as without the option")
    func relativeExplicit() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (implicit, implicitText) = try await createNote(in: workspace, target: "output/a.xmi")
        let (explicit, explicitText) = try await createNote(
            in: workspace, target: "output/b.xmi", extra: [Self.option, "relative"])

        #expect(implicit.succeeded, "\(implicit.error)")
        #expect(explicit.succeeded, "\(explicit.error)")
        #expect(implicitText != nil)
        #expect(implicitText == explicitText)
    }

    @Test("takes the style of the configuration file, which the command line overrides")
    func configurationKey() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "document-uris": "absolute" }"#, to: Self.configurationFile)

        let (configured, configuredText) = try await createNote(in: workspace, target: "output/configured.xmi")
        let (overridden, overriddenText) = try await createNote(
            in: workspace, target: "output/overridden.xmi", extra: [Self.option, "relative"])
        let (ignored, ignoredText) = try await createNote(in: workspace, target: "output/ignored.xmi", extra: ["--no-config"])

        #expect(configured.succeeded, "\(configured.error)")
        #expect(workspace.isAbsoluteReference(Self.hrefs("blocker", in: configuredText ?? "").first), "\(configuredText ?? "")")
        #expect(overridden.succeeded, "\(overridden.error)")
        #expect(Self.hrefs("blocker", in: overriddenText ?? "") == ["../models/tasks.xmi#//@tasks.1"])
        #expect(ignored.succeeded, "\(ignored.error)")
        #expect(Self.hrefs("blocker", in: ignoredText ?? "") == ["../models/tasks.xmi#//@tasks.1"])
    }

    @Test("rejects a value that is not a document URI style, on the command line or in the file")
    func rejectsUnknownStyle() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (fromCommandLine, commandLineText) = try await createNote(
            in: workspace, target: "output/notes.xmi", extra: [Self.option, "sideways"])
        try workspace.write(#"{ "document-uris": "sideways" }"#, to: Self.configurationFile)
        let (fromFile, fileText) = try await createNote(in: workspace, target: "output/notes.xmi")

        #expect(fromCommandLine.status == 64, "\(fromCommandLine.error)")
        #expect(fromCommandLine.error.contains("sideways"), "\(fromCommandLine.error)")
        #expect(commandLineText == nil)
        #expect(fromFile.status == 1, "\(fromFile.error)")
        for expected in ["'document-uris'", "'sideways'", "relative", "absolute"] {
            #expect(fromFile.error.contains(expected), "\(expected) is missing from: \(fromFile.error)")
        }
        #expect(fileText == nil)
    }

    @Test("lists the option and its values in the help of the commands that write models", arguments: [
        ["eol", "run"], ["evl", "validate"], ["etl", "transform"],
    ])
    func help(command: [String]) async throws {
        let run = try await runSwiftEpsilon(command + ["--help"])

        #expect(run.succeeded)
        #expect(run.output.contains(Self.option))
        #expect(run.output.contains("relative"))
        #expect(run.output.contains("absolute"))
    }
}
