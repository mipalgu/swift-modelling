//
// ConvertDocumentURITests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import Testing

/// Tests for how `swift-ecore convert` writes references from a model to elements of another
/// document: relative to the written model by default, and as absolute URIs with
/// `--document-uris absolute` or the `document-uris` key of the configuration file.
@Suite("swift-ecore convert - document URIs")
struct ConvertDocumentURITests {
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

    /// The path of the note, relative to the workspace.
    static let input = "models/notes.xmi"

    /// The path of the project, relative to the workspace.
    static let project = "models/tasks.xmi"

    /// A directory with the metamodels, the project and the note that refers to it.
    struct Workspace {
        /// The temporary directory.
        let root: URL

        /// Creates the directory.
        ///
        /// - Throws: An error if a file cannot be written.
        init() throws {
            root = try createTemporaryDirectory()
            try write(ConvertDocumentURITests.tasks, to: "Tasks.ecore")
            try write(ConvertDocumentURITests.notes, to: "Notes.ecore")
            try write(ConvertDocumentURITests.taskModel, to: ConvertDocumentURITests.project)
            try write(ConvertDocumentURITests.noteModel, to: ConvertDocumentURITests.input)
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
            return href.hasSuffix("/" + ConvertDocumentURITests.project + "#//@tasks.1")
                && absoluteForms.contains { href.contains($0) }
        }
    }

    /// Converts the note from the workspace directory.
    ///
    /// - Parameters:
    ///   - workspace: The workspace.
    ///   - output: The path of the converted model, relative to the workspace.
    ///   - absolutePaths: Whether the command line names the files by absolute paths.
    ///   - extra: The arguments after the metamodels.
    /// - Returns: The result of the command and the text of the converted model, if any.
    @MainActor
    private func convert(
        _ workspace: Workspace, to output: String, absolutePaths: Bool = true, extra: [String] = []
    ) async throws -> (result: SubprocessResult, text: String?) {
        let file = { (path: String) in absolutePaths ? workspace.root.appendingPathComponent(path).path : path }
        try FileManager.default.createDirectory(
            at: workspace.root.appendingPathComponent(output).deletingLastPathComponent(),
            withIntermediateDirectories: true)
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [
                file(Self.input), file(output), "--metamodel", file("Notes.ecore"), "--metamodel", file("Tasks.ecore"),
            ] + extra,
            workingDirectory: workspace.root)
        return (result, try? String(contentsOf: workspace.root.appendingPathComponent(output), encoding: .utf8))
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

    /// Loads a converted note and the names of the objects that it refers to.
    ///
    /// - Parameters:
    ///   - workspace: The workspace with the metamodels.
    ///   - path: The path of the converted model, relative to the workspace.
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

    /// Locations of the converted model, with the relative URI of the project in it.
    static let layouts: [(output: String, relative: String)] = [
        ("models/converted.xmi", "tasks.xmi"),
        ("output/notes.xmi", "../models/tasks.xmi"),
        ("models/nested/notes.xmi", "../tasks.xmi"),
        ("notes.xmi", "models/tasks.xmi"),
    ]

    @Test("refers to the other document by a URI relative to the output by default", arguments: layouts)
    @MainActor
    func relativeByDefault(layout: (output: String, relative: String)) async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await convert(workspace, to: layout.output)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let output = try #require(text)
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

    @Test("refers to the other document by a relative URI when the files are named by relative paths")
    @MainActor
    func relativePaths() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await convert(workspace, to: "output/notes.xmi", absolutePaths: false)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let output = try #require(text)
        #expect(Self.hrefs("blocker", in: output) == ["../models/tasks.xmi#//@tasks.1"], "\(output)")
        for absolute in workspace.absoluteForms {
            #expect(!output.contains(absolute), "\(output)")
        }
        let names = try await Self.referencedNames(in: workspace, path: "output/notes.xmi")
        #expect(names.follows == ["reviewing", "publishing"])
    }

    @Test("refers to the other document by a relative URI with the plain reference style")
    @MainActor
    func relativePlain() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await convert(workspace, to: "output/notes.xmi", extra: ["--reference-style", "plain"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let output = try #require(text)
        #expect(output.contains("../models/tasks.xmi#//@tasks.1"), "\(output)")
        #expect(!output.contains("file:"), "\(output)")
        let names = try await Self.referencedNames(in: workspace, path: "output/notes.xmi")
        #expect(names.follows == ["reviewing", "publishing"])
    }

    @Test(
        "refers to the other document by its absolute URI with --document-uris absolute",
        arguments: [[], ["--reference-style", "plain"]])
    @MainActor
    func absoluteOptOut(style: [String]) async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await convert(workspace, to: "output/notes.xmi", extra: [Self.option, "absolute"] + style)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let output = try #require(text)
        #expect(
            workspace.isAbsoluteReference(
                Self.hrefs("blocker", in: output).first ?? Self.attributeReference("blocker", in: output)),
            "\(output)")
        #expect(!output.contains("../models/tasks.xmi"), "\(output)")
        let names = try await Self.referencedNames(in: workspace, path: "output/notes.xmi")
        #expect(names.follows == ["reviewing", "publishing"])
    }

    @Test("writes the same model with --document-uris relative as without the option")
    @MainActor
    func relativeExplicit() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (implicit, implicitText) = try await convert(workspace, to: "output/notes.xmi")
        let (explicit, explicitText) = try await convert(
            workspace, to: "output/notes.xmi", extra: [Self.option, "relative", "--force"])

        #expect(implicit.succeeded, "\(implicit.stdout)\(implicit.stderr)")
        #expect(explicit.succeeded, "\(explicit.stdout)\(explicit.stderr)")
        #expect(implicitText != nil)
        #expect(implicitText == explicitText)
    }

    @Test("takes the style of the configuration file, which the command line overrides")
    @MainActor
    func configurationKey() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }
        try workspace.write(#"{ "document-uris": "absolute" }"#, to: Self.configurationFile)

        let (configured, configuredText) = try await convert(workspace, to: "output/configured.xmi")
        let (overridden, overriddenText) = try await convert(
            workspace, to: "output/overridden.xmi", extra: [Self.option, "relative"])
        let (ignored, ignoredText) = try await convert(workspace, to: "output/ignored.xmi", extra: ["--no-config"])

        #expect(configured.succeeded, "\(configured.stdout)\(configured.stderr)")
        #expect(workspace.isAbsoluteReference(Self.hrefs("blocker", in: configuredText ?? "").first), "\(configuredText ?? "")")
        #expect(overridden.succeeded, "\(overridden.stdout)\(overridden.stderr)")
        #expect(Self.hrefs("blocker", in: overriddenText ?? "") == ["../models/tasks.xmi#//@tasks.1"])
        #expect(ignored.succeeded, "\(ignored.stdout)\(ignored.stderr)")
        #expect(Self.hrefs("blocker", in: ignoredText ?? "") == ["../models/tasks.xmi#//@tasks.1"])
    }

    @Test("rejects a value of the configuration key that is not a document URI style")
    @MainActor
    func rejectsUnknownConfiguredStyle() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }
        try workspace.write(#"{ "document-uris": "sideways" }"#, to: Self.configurationFile)

        let (result, text) = try await convert(workspace, to: "output/notes.xmi")

        #expect(result.exitCode == 1)
        for expected in ["'document-uris'", "'sideways'", "relative", "absolute"] {
            #expect(result.stderr.contains(expected), "\(expected) is missing from: \(result.stderr)")
        }
        #expect(text == nil)
    }

    @Test("rejects a value that is not a document URI style")
    @MainActor
    func rejectsUnknownStyle() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await convert(workspace, to: "output/notes.xmi", extra: [Self.option, "sideways"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("sideways"), "\(result.stderr)")
        #expect(text == nil)
    }

    @Test("lists the option, its values and its key in the help of convert")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftEcore(command: "convert", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains(Self.option))
        #expect(result.stdout.contains("relative"))
        #expect(result.stdout.contains("absolute"))
        #expect(result.stdout.contains("\"document-uris\""))
    }
}
