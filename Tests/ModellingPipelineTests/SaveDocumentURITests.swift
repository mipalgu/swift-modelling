//
// SaveDocumentURITests.swift
// ModellingPipelineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingPipeline
import Testing

/// Tests for how the save step of a pipeline writes references to elements of other documents:
/// relative to the written file unless the step is given options of its own.
@Suite("ModelPipeline - document URIs of saved models")
@MainActor
struct SaveDocumentURITests {
    /// A metamodel of projects that contain tasks.
    nonisolated static let tasks = """
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
    nonisolated static let notes = """
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
    nonisolated static let taskModel = """
        <?xml version="1.0" encoding="UTF-8"?>
        <tasks:Project xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:tasks="http://www.example.org/tasks" name="release">
          <tasks name="drafting"/>
          <tasks name="reviewing" done="true"/>
          <tasks name="publishing" done="true"/>
        </tasks:Project>
        """

    /// A note that refers to the tasks that are done, in a project beside it.
    nonisolated static let noteModel = """
        <?xml version="1.0" encoding="UTF-8"?>
        <notes:Note xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:notes="http://www.example.org/notes" name="drafting">
          <blocker href="tasks.xmi#//@tasks.1"/>
          <follows href="tasks.xmi#//@tasks.1"/>
          <follows href="tasks.xmi#//@tasks.2"/>
        </notes:Note>
        """

    /// A directory with the metamodels, the project and the note that refers to it.
    struct Workspace {
        /// The temporary directory.
        let root: URL

        /// Creates the directory.
        ///
        /// - Throws: An error if a file cannot be written.
        init() throws {
            root = FileManager.default.temporaryDirectory.appendingPathComponent("pipeline-document-uris")
                .appendingPathComponent(UUID().uuidString)
            try write(SaveDocumentURITests.tasks, to: "Tasks.ecore")
            try write(SaveDocumentURITests.notes, to: "Notes.ecore")
            try write(SaveDocumentURITests.taskModel, to: "models/tasks.xmi")
            try write(SaveDocumentURITests.noteModel, to: "models/notes.xmi")
        }

        /// The location of a file in the directory.
        ///
        /// - Parameter path: The path, relative to the directory.
        /// - Returns: The location.
        func url(_ path: String) -> URL { root.appendingPathComponent(path) }

        /// Writes a file at a path relative to the directory, creating its directory.
        ///
        /// - Parameters:
        ///   - text: The contents.
        ///   - path: The path, relative to the directory.
        /// - Throws: An error if the file cannot be written.
        func write(_ text: String, to path: String) throws {
            try FileManager.default.createDirectory(
                at: url(path).deletingLastPathComponent(), withIntermediateDirectories: true)
            try text.write(to: url(path), atomically: true, encoding: .utf8)
        }

        /// Reads a file at a path relative to the directory.
        ///
        /// - Parameter path: The path, relative to the directory.
        /// - Returns: The text of the file.
        /// - Throws: An error if the file cannot be read.
        func text(at path: String) throws -> String {
            try String(contentsOf: url(path), encoding: .utf8)
        }

        /// The texts by which a written file could name the directory.
        var absoluteForms: [String] {
            [root.path, root.standardizedFileURL.path, root.resolvingSymlinksInPath().path]
        }

        /// The canonical file URI of the project.
        var projectURI: String { URIReference.canonicalise(url("models/tasks.xmi").absoluteString) }

        /// Removes the directory.
        func remove() {
            try? FileManager.default.removeItem(at: root)
        }
    }

    /// Loads the note and saves it with a save step.
    ///
    /// - Parameters:
    ///   - workspace: The workspace.
    ///   - path: The path of the saved model, relative to the workspace.
    ///   - save: The save step for a model named `note` and a location.
    /// - Returns: The text of the saved model.
    /// - Throws: The errors of the pipeline and of reading the saved file.
    private func saveNote(
        in workspace: Workspace, to path: String, with save: (URL) -> ModelPipeline.Step
    ) async throws -> String {
        _ = try await ModelPipeline(steps: [
            .registerMetamodels([workspace.url("Tasks.ecore"), workspace.url("Notes.ecore")]),
            .load(name: "note", url: workspace.url("models/notes.xmi")),
            save(workspace.url(path)),
        ]).run()
        return try workspace.text(at: path)
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

    /// Loads a saved note and the names of the objects that its blocker and follows refer to.
    ///
    /// - Parameters:
    ///   - workspace: The workspace with the metamodels.
    ///   - path: The path of the note, relative to the workspace.
    /// - Returns: The names in the order of the references.
    /// - Throws: An error if the model cannot be loaded or a reference does not resolve.
    static func referencedNames(in workspace: Workspace, path: String) async throws -> [String] {
        let set = ResourceSet()
        let loaded = try await ModelIO.load(
            url: workspace.url(path), resourceSet: set,
            metamodels: [workspace.url("Tasks.ecore"), workspace.url("Notes.ecore")])
        let note = try #require(await loaded.resource.getRootObjects().first as? DynamicEObject)
        var values: [any EcoreValue] = []
        for feature in ["blocker", "follows"] {
            switch note.eGet(feature) {
            case let proxies as [ResourceProxy]: values += proxies
            case let array as EcoreValueArray: values += array.values
            case let single?: values.append(single)
            case nil: break
            }
        }
        var names: [String] = []
        for value in values {
            let proxy = try #require(value as? ResourceProxy, "\(value)")
            let object = try #require(await proxy.resolveObject(in: set) as? DynamicEObject, "\(proxy)")
            names.append(try #require(object.eGet("name") as? String))
        }
        return names
    }

    @Test("writes relative URIs in the default layout unless given options")
    func defaultOptions() {
        var expected = XMISerializationOptions.legacy
        expected.relativeURIs = true
        #expect(ModelPipeline.defaultXMIOptions == expected)
    }

    @Test(
        "refers to the other document relative to the saved file by default",
        arguments: [("output/notes.xmi", "../models/tasks.xmi"), ("models/copy.xmi", "tasks.xmi"), ("notes.xmi", "models/tasks.xmi")])
    func relativeByDefault(path: String, relative: String) async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let text = try await saveNote(in: workspace, to: path) { .save(name: "note", url: $0) }

        #expect(Self.hrefs("blocker", in: text) == [relative + "#//@tasks.1"], "\(text)")
        #expect(Self.hrefs("follows", in: text) == [relative + "#//@tasks.1", relative + "#//@tasks.2"], "\(text)")
        #expect(!text.contains("file:"), "\(text)")
        for absolute in workspace.absoluteForms {
            #expect(!text.contains(absolute), "\(text)")
        }
        #expect(try await Self.referencedNames(in: workspace, path: path) == ["reviewing", "reviewing", "publishing"])
    }

    @Test("keeps the meaning of the options that the step is given")
    func explicitOptions() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let legacy = try await saveNote(in: workspace, to: "output/legacy.xmi") {
            .save(name: "note", url: $0, xmiOptions: .legacy)
        }
        let emf = try await saveNote(in: workspace, to: "output/emf.xmi") {
            .save(name: "note", url: $0, xmiOptions: .emf)
        }

        #expect(Self.hrefs("blocker", in: legacy) == ["\(workspace.projectURI)#//@tasks.1"], "\(legacy)")
        #expect(emf.contains("../models/tasks.xmi#//@tasks.1"), "\(emf)")
        #expect(!emf.contains("file:"), "\(emf)")
        #expect(try await Self.referencedNames(in: workspace, path: "output/legacy.xmi") == ["reviewing", "reviewing", "publishing"])
    }
}
