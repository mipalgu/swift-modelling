//
// OutputSaveAsTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingCommandLine
import Testing

/// Tests for saving the models of a command as their files, each taking the location of its file.
@Suite("OutputFile - saving models as their files")
struct OutputSaveAsTests {
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
            <eStructuralFeatures xsi:type="ecore:EReference" name="note"
                eType="ecore:EClass http://www.eclipse.org/emf/2002/Ecore#//EObject"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// A project whose first task refers to a note beside it, and whose second task refers to
    /// the first.
    static let taskModel = """
        <?xml version="1.0" encoding="UTF-8"?>
        <tasks:Project xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:tasks="http://www.example.org/tasks" name="release">
          <tasks name="drafting"><note href="note.xmi#/"/></tasks>
          <tasks name="reviewing \u{e9}"><note href="#//@tasks.0"/></tasks>
        </tasks:Project>
        """

    /// A note, itself a project, whose task refers back to the first task of the project.
    static let noteModel = """
        <?xml version="1.0" encoding="UTF-8"?>
        <tasks:Project xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:tasks="http://www.example.org/tasks" name="note">
          <tasks name="remember"><note href="tasks.xmi#//@tasks.0"/></tasks>
        </tasks:Project>
        """

    /// A directory with the metamodel, the project and the note, loaded into one resource set.
    struct Workspace {
        /// The temporary directory.
        let root: URL

        /// The resource set that holds the models.
        let resourceSet = ResourceSet()

        /// The project.
        let project: Resource

        /// The note.
        let note: Resource

        /// Creates the directory and loads the models.
        ///
        /// - Throws: An error if a file cannot be written or read.
        init() async throws {
            root = FileManager.default.temporaryDirectory.appendingPathComponent("output-save-as")
                .appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(
                at: root.appendingPathComponent("models"), withIntermediateDirectories: true)
            try OutputSaveAsTests.tasks.write(to: root.appendingPathComponent("Tasks.ecore"), atomically: true, encoding: .utf8)
            try OutputSaveAsTests.taskModel.write(to: root.appendingPathComponent("models/tasks.xmi"), atomically: true, encoding: .utf8)
            try OutputSaveAsTests.noteModel.write(to: root.appendingPathComponent("models/note.xmi"), atomically: true, encoding: .utf8)
            try await ModelIO.registerMetamodels(at: [root.appendingPathComponent("Tasks.ecore")], in: resourceSet)
            project = try await ModelIO.load(url: root.appendingPathComponent("models/tasks.xmi"), resourceSet: resourceSet).resource
            note = try await ModelIO.load(url: root.appendingPathComponent("models/note.xmi"), resourceSet: resourceSet).resource
        }

        /// The path of a file in the directory.
        ///
        /// - Parameter path: The path, relative to the directory.
        /// - Returns: The absolute path.
        func path(_ path: String) -> String { root.appendingPathComponent(path).path }

        /// Reads a file of the directory.
        ///
        /// - Parameter path: The path, relative to the directory.
        /// - Returns: The contents, or `nil` if there is no such file.
        func data(at path: String) -> Data? { try? Data(contentsOf: root.appendingPathComponent(path)) }

        /// Reads a text file of the directory.
        ///
        /// - Parameter path: The path, relative to the directory.
        /// - Returns: The text, or an empty string if there is no such file.
        func text(at path: String) -> String { data(at: path).map { String(decoding: $0, as: UTF8.self) } ?? "" }

        /// Removes the directory.
        func remove() { try? FileManager.default.removeItem(at: root) }
    }

    /// The options that write the URIs of other documents relative to the written file.
    static let relative: XMISerializationOptions = {
        var options = XMISerializationOptions.legacy
        options.relativeURIs = true
        return options
    }()

    @Test("models that refer to each other refer to each other at their new files", arguments: [false, true], [true, false])
    func together(noteFirst: Bool, relativeURIs: Bool) async throws {
        let workspace = try await Workspace()
        defer { workspace.remove() }
        var options = Self.relative
        options.relativeURIs = relativeURIs
        let models = [
            OutputModel(workspace.project, path: workspace.path("out/tasks.xmi"), xmiOptions: options),
            OutputModel(workspace.note, path: workspace.path("out/note.xmi"), xmiOptions: options),
        ]
        try FileManager.default.createDirectory(at: workspace.root.appendingPathComponent("out"), withIntermediateDirectories: true)

        try await OutputFile.saveAs(noteFirst ? models.reversed() : models, encoding: .utf8)

        let project = workspace.text(at: "out/tasks.xmi")
        let note = workspace.text(at: "out/note.xmi")
        if relativeURIs {
            #expect(project.contains("href=\"note.xmi#/\""), "\(project)")
            #expect(note.contains("href=\"tasks.xmi#//@tasks.0\""), "\(note)")
        } else {
            #expect(project.contains("out/note.xmi#/\""), "\(project)")
            #expect(note.contains("out/tasks.xmi#//@tasks.0\""), "\(note)")
        }
        #expect(!project.contains("models/"), "\(project)")
        #expect(!note.contains("models/"), "\(note)")
        #expect(workspace.project.uri == OutputFile.documentURI(ofPath: workspace.path("out/tasks.xmi")))
        #expect(workspace.note.uri == OutputFile.documentURI(ofPath: workspace.path("out/note.xmi")))
    }

    @Test(
        "a model saved alone to a new file is written byte for byte as a copy",
        arguments: [("xmi", TextEncoding.utf8), ("xmi", .isoLatin1), ("json", .utf8)])
    func aloneAsCopy(fileExtension: String, encoding: TextEncoding) async throws {
        let copied = try await Workspace()
        defer { copied.remove() }
        let workspace = try await Workspace()
        defer { workspace.remove() }
        let path = "out/project." + fileExtension
        for root in [copied.root, workspace.root] {
            try FileManager.default.createDirectory(at: root.appendingPathComponent("out"), withIntermediateDirectories: true)
        }
        try await OutputFile.save(
            copied.project, to: URL(fileURLWithPath: copied.path(path)), xmiOptions: Self.relative, encoding: encoding,
            warn: { _ in })

        try await OutputFile.saveAs(
            workspace.project, to: workspace.path(path), xmiOptions: Self.relative, encoding: encoding, warn: { _ in })

        let copy = try #require(copied.data(at: path))
        #expect(copy == workspace.data(at: path))
        #expect(workspace.project.uri == OutputFile.documentURI(ofPath: workspace.path(path)))
    }

    @Test("a model saved back to its own file keeps its location")
    func inPlace() async throws {
        let workspace = try await Workspace()
        defer { workspace.remove() }
        let uri = workspace.project.uri

        try await OutputFile.saveAs(workspace.project, to: workspace.path("models/tasks.xmi"), xmiOptions: Self.relative, encoding: .utf8)

        #expect(workspace.project.uri == uri)
        #expect(workspace.text(at: "models/tasks.xmi").contains("href=\"note.xmi#/\""))
    }

    @Test("two models given the same file are an error that names both paths and writes nothing")
    func sameFile() async throws {
        let workspace = try await Workspace()
        defer { workspace.remove() }
        let first = "out/one.xmi"
        let second = "out/../out/one.xmi"
        let projectURI = workspace.project.uri

        let error = await #expect(throws: OutputFileError.self) {
            try await OutputFile.saveAs(
                [OutputModel(workspace.project, path: workspace.path(first)), OutputModel(workspace.note, path: workspace.path(second))],
                encoding: .utf8)
        }

        #expect(error == .sameFile(path: workspace.path(second), other: workspace.path(first)))
        #expect(error?.description.contains("same file") == true)
        #expect(error?.description.contains(workspace.path(second)) == true)
        #expect(workspace.data(at: first) == nil)
        #expect(workspace.project.uri == projectURI)
    }

    @Test("a file of another model that is not written is an error that changes nothing")
    func fileInUse() async throws {
        let workspace = try await Workspace()
        defer { workspace.remove() }
        let before = workspace.data(at: "models/tasks.xmi")
        let noteURI = workspace.note.uri

        let error = await #expect(throws: OutputFileError.self) {
            try await OutputFile.saveAs(workspace.note, to: workspace.path("models/tasks.xmi"), encoding: .utf8)
        }

        #expect(error == .fileInUse(path: workspace.path("models/tasks.xmi")))
        #expect(error?.description.contains(workspace.path("models/tasks.xmi")) == true)
        #expect(workspace.data(at: "models/tasks.xmi") == before)
        #expect(workspace.note.uri == noteURI)
    }

    @Test("models can take each other's files")
    func swapped() async throws {
        let workspace = try await Workspace()
        defer { workspace.remove() }

        try await OutputFile.saveAs(
            [
                OutputModel(workspace.project, path: workspace.path("models/note.xmi"), xmiOptions: Self.relative),
                OutputModel(workspace.note, path: workspace.path("models/tasks.xmi"), xmiOptions: Self.relative),
            ], encoding: .utf8)

        #expect(workspace.text(at: "models/note.xmi").contains("name=\"release\""))
        #expect(workspace.text(at: "models/note.xmi").contains("href=\"tasks.xmi#/\""))
        #expect(workspace.text(at: "models/tasks.xmi").contains("href=\"note.xmi#//@tasks.0\""))
    }

    @Test("a model given two files takes the first and is copied to the second")
    func copy() async throws {
        let workspace = try await Workspace()
        defer { workspace.remove() }
        try FileManager.default.createDirectory(at: workspace.root.appendingPathComponent("out"), withIntermediateDirectories: true)

        try await OutputFile.saveAs(
            [
                OutputModel(workspace.project, path: workspace.path("out/tasks.xmi"), xmiOptions: Self.relative),
                OutputModel(workspace.project, path: workspace.path("models/backup.xmi"), xmiOptions: Self.relative),
                OutputModel(workspace.project, path: workspace.path("out/tasks.xmi"), xmiOptions: Self.relative),
            ], encoding: .utf8)

        #expect(workspace.project.uri == OutputFile.documentURI(ofPath: workspace.path("out/tasks.xmi")))
        #expect(workspace.text(at: "models/backup.xmi").contains("href=\"note.xmi#/\""))
        #expect(workspace.text(at: "out/tasks.xmi").contains("href=\"../models/note.xmi#/\""))
    }

    @Test("models keep their locations when a file cannot be written")
    func failedWriteRestores() async throws {
        let workspace = try await Workspace()
        defer { workspace.remove() }
        let projectURI = workspace.project.uri
        let noteURI = workspace.note.uri

        await #expect(throws: (any Error).self) {
            try await OutputFile.saveAs(
                [
                    OutputModel(workspace.project, path: workspace.path("models/new-tasks.xmi")),
                    OutputModel(workspace.note, path: workspace.path("missing/note.xmi")),
                ], encoding: .utf8)
        }

        #expect(workspace.project.uri == projectURI)
        #expect(workspace.note.uri == noteURI)
    }
}
