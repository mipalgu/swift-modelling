//
// DocumentURITests.swift
// swift-henshin-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import EMFBase
import Foundation
import Testing

/// Tests for how `swift-henshin apply` writes references from the transformed model to
/// elements of another document: relative to the written model by default, and as absolute
/// URIs with `--document-uris absolute` or the `document-uris` key of the configuration file.
@Suite("swift-henshin apply - document URIs")
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

    /// A metamodel of notes, each referring to one object and to a list of objects of any class.
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
                eType="ecore:EClass http://www.eclipse.org/emf/2002/Ecore#//EObject"/>
            <eStructuralFeatures xsi:type="ecore:EReference" name="follows" upperBound="-1"
                eType="ecore:EClass http://www.eclipse.org/emf/2002/Ecore#//EObject"/>
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

    /// A module with a rule that renames a note.
    static let module = """
        ePackageImport notes

        rule rename(IN newName:EString, VAR oldName:EString) {
        	graph {
        		node note:Note {
        			name = oldName
        			set name = newName
        		}
        	}
        }
        """

    /// The path of the note, relative to the workspace.
    static let input = "models/notes.xmi"

    /// The path of the project, relative to the workspace.
    static let project = "models/tasks.xmi"

    /// A directory with the metamodels, the module, the project and the note that refers to it.
    struct Workspace {
        /// The temporary directory.
        let root: URL

        /// Creates the directory, marked as the root of a repository.
        ///
        /// - Throws: An error if a file cannot be written.
        init() throws {
            root = try Fixture.temporaryDirectory()
            try FileManager.default.createDirectory(
                at: root.appendingPathComponent(".git"), withIntermediateDirectories: true)
            try write(DocumentURITests.tasks, to: "Tasks.ecore")
            try write(DocumentURITests.notes, to: "Notes.ecore")
            try write(DocumentURITests.module, to: "notes.henshin_text")
            try write(DocumentURITests.taskModel, to: DocumentURITests.project)
            try write(DocumentURITests.noteModel, to: DocumentURITests.input)
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

    /// Renames the note, writing it to a file or printing it.
    ///
    /// - Parameters:
    ///   - workspace: The workspace.
    ///   - output: The path of the written model, relative to the workspace, or `nil` to print it.
    ///   - extra: Further arguments.
    /// - Returns: The result of the command and the text of the transformed model, if any.
    private func rename(
        in workspace: Workspace, to output: String? = nil, extra: [String] = []
    ) async throws -> (run: ToolRun, text: String?) {
        let destination = output.map { ["-o", $0] } ?? []
        if let output {
            try FileManager.default.createDirectory(
                at: workspace.root.appendingPathComponent(output).deletingLastPathComponent(),
                withIntermediateDirectories: true)
        }
        let run = try await runSwiftHenshin(
            ["apply", "notes.henshin_text", Self.input, "-u", "rename", "--param", "newName=renamed"] + destination
                + extra, in: workspace.root)
        return (run, output.map(workspace.text(at:)) ?? (run.succeeded ? run.output : nil))
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

    /// Locations of the written model, with the relative URI of the project in it.
    static let layouts: [(output: String, relative: String)] = [
        ("models/renamed.xmi", "tasks.xmi"),
        ("output/notes.xmi", "../models/tasks.xmi"),
        ("notes.xmi", "models/tasks.xmi"),
    ]

    @Test("writes references to the other model relative to the output by default", arguments: layouts)
    func relativeByDefault(layout: (output: String, relative: String)) async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (run, text) = try await rename(in: workspace, to: layout.output)

        #expect(run.succeeded, "\(run.error)")
        let output = try #require(text)
        #expect(output.contains("name=\"renamed\""), "\(output)")
        #expect(Self.hrefs("blocker", in: output) == [layout.relative + "#//@tasks.1"], "\(output)")
        #expect(
            Self.hrefs("follows", in: output) == [layout.relative + "#//@tasks.1", layout.relative + "#//@tasks.2"],
            "\(output)")
        #expect(!output.contains("file:"), "\(output)")
        for absolute in workspace.absoluteForms {
            #expect(!output.contains(absolute), "\(output)")
        }
        let names = try await Self.referencedNames(in: workspace, path: layout.output)
        #expect(names.blocker == "reviewing")
        #expect(names.follows == ["reviewing", "publishing"])
    }

    @Test("prints references to the other model relative to the model that was read")
    func printedRelative() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (run, text) = try await rename(in: workspace)

        #expect(run.succeeded, "\(run.error)")
        let output = try #require(text)
        #expect(Self.hrefs("blocker", in: output) == ["tasks.xmi#//@tasks.1"], "\(output)")
        #expect(!output.contains("file:"), "\(output)")
        for absolute in workspace.absoluteForms {
            #expect(!output.contains(absolute), "\(output)")
        }
    }

    @Test("writes and prints the absolute URI of the other model with --document-uris absolute")
    func absoluteOptOut() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (written, writtenText) = try await rename(in: workspace, to: "output/notes.xmi", extra: [Self.option, "absolute"])
        let (printed, printedText) = try await rename(in: workspace, extra: [Self.option, "absolute"])

        #expect(written.succeeded, "\(written.error)")
        #expect(workspace.isAbsoluteReference(Self.hrefs("blocker", in: writtenText ?? "").first), "\(writtenText ?? "")")
        #expect(printed.succeeded, "\(printed.error)")
        #expect(workspace.isAbsoluteReference(Self.hrefs("blocker", in: printedText ?? "").first), "\(printedText ?? "")")
        let names = try await Self.referencedNames(in: workspace, path: "output/notes.xmi")
        #expect(names.follows == ["reviewing", "publishing"])
    }

    @Test("writes the same model with --document-uris relative as without the option")
    func relativeExplicit() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let (implicit, implicitText) = try await rename(in: workspace, to: "output/a.xmi")
        let (explicit, explicitText) = try await rename(in: workspace, to: "output/b.xmi", extra: [Self.option, "relative"])

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

        let (configured, configuredText) = try await rename(in: workspace, to: "output/configured.xmi")
        let (overridden, overriddenText) = try await rename(
            in: workspace, to: "output/overridden.xmi", extra: [Self.option, "relative"])
        let (ignored, ignoredText) = try await rename(in: workspace, to: "output/ignored.xmi", extra: ["--no-config"])

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

        let (fromCommandLine, commandLineText) = try await rename(
            in: workspace, to: "output/notes.xmi", extra: [Self.option, "sideways"])
        try workspace.write(#"{ "document-uris": "sideways" }"#, to: Self.configurationFile)
        let (fromFile, fileText) = try await rename(in: workspace, to: "output/notes.xmi")

        #expect(fromCommandLine.status == ExitCode.validationFailure.rawValue, "\(fromCommandLine.error)")
        #expect(fromCommandLine.error.contains("sideways"), "\(fromCommandLine.error)")
        #expect(commandLineText == nil)
        #expect(fromFile.status == 1, "\(fromFile.error)")
        for expected in ["'document-uris'", "'sideways'", "relative", "absolute"] {
            #expect(fromFile.error.contains(expected), "\(expected) is missing from: \(fromFile.error)")
        }
        #expect(fileText == nil)
    }

    @Test("lists the option, its values and its key in the help of apply")
    func help() async throws {
        let run = try await runSwiftHenshin(["apply", "--help"])

        #expect(run.succeeded)
        #expect(run.output.contains(Self.option))
        #expect(run.output.contains("relative"))
        #expect(run.output.contains("absolute"))
        #expect(run.output.contains("\"document-uris\""))
    }
}
