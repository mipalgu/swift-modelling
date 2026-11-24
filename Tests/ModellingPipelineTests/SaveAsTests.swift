//
// SaveAsTests.swift
// ModellingPipelineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingGenerators
import ModellingPipeline
import Testing

/// Tests for how save steps save models as their files: each model takes the location of its
/// file, and consecutive save steps give all their models their locations before any is written.
@Suite("ModelPipeline - saving models as new documents")
@MainActor
struct PipelineSaveAsTests {
    /// The path of the saved project, relative to the workspace.
    nonisolated static let savedProject = "output/tasks.xmi"

    /// The path of the saved note, relative to the workspace.
    nonisolated static let savedNote = "output/notes.xmi"

    /// The XMI options that write the URIs of other documents in full.
    nonisolated static let absoluteOptions: XMISerializationOptions = {
        var options = ModelPipeline.defaultXMIOptions
        options.relativeURIs = false
        return options
    }()

    /// The steps that register the metamodels and load the project and the note.
    ///
    /// - Parameter workspace: The workspace.
    /// - Returns: The steps.
    static func loadSteps(in workspace: SaveDocumentURITests.Workspace) -> [ModelPipeline.Step] {
        [
            .registerMetamodels([workspace.url("Tasks.ecore"), workspace.url("Notes.ecore")]),
            .load(name: "tasks", url: workspace.url("models/tasks.xmi")),
            .load(name: "note", url: workspace.url("models/notes.xmi")),
        ]
    }

    @Test(
        "consecutive save steps write models that refer to each other against their new files",
        arguments: [false, true], [true, false])
    func savedTogether(noteFirst: Bool, relative: Bool) async throws {
        let workspace = try SaveDocumentURITests.Workspace()
        defer { workspace.remove() }
        let options = relative ? ModelPipeline.defaultXMIOptions : Self.absoluteOptions
        let saves: [ModelPipeline.Step] = [
            .save(name: "tasks", url: workspace.url(Self.savedProject), xmiOptions: options),
            .save(name: "note", url: workspace.url(Self.savedNote), xmiOptions: options),
        ]

        let result = try await ModelPipeline(steps: Self.loadSteps(in: workspace) + (noteFirst ? saves.reversed() : saves))
            .run()

        let text = try workspace.text(at: Self.savedNote)
        let blocker = try #require(SaveDocumentURITests.hrefs("blocker", in: text).first, "\(text)")
        if relative {
            #expect(blocker == "tasks.xmi#//@tasks.1", "\(text)")
        } else {
            #expect(blocker.hasPrefix("file:"), "\(text)")
            #expect(blocker.hasSuffix("/" + Self.savedProject + "#//@tasks.1"), "\(text)")
        }
        #expect(!text.contains("models/tasks.xmi"), "\(text)")
        #expect(
            result.models["tasks"]?.uri
                == DocumentRelocation.canonicalURI(of: workspace.url(Self.savedProject)))
        try FileManager.default.removeItem(at: workspace.url("models"))
        let names = try await SaveDocumentURITests.referencedNames(in: workspace, path: Self.savedNote)
        #expect(names == ["reviewing", "reviewing", "publishing"])
    }

    @Test("a model saved alone to a new file is written as a copy of it would be")
    func aloneAsCopy() async throws {
        let workspace = try SaveDocumentURITests.Workspace()
        defer { workspace.remove() }
        let copySet = ResourceSet()
        let copy = try await ModelIO.load(
            url: workspace.url("models/notes.xmi"), resourceSet: copySet,
            metamodels: [workspace.url("Tasks.ecore"), workspace.url("Notes.ecore")])
        var diagnostics = ConversionDiagnostics()
        try FileManager.default.createDirectory(at: workspace.url("copy"), withIntermediateDirectories: true)
        try await ModelIO.save(
            copy.resource, to: workspace.url("copy/notes.xmi"), xmiOptions: ModelPipeline.defaultXMIOptions,
            diagnostics: &diagnostics)

        _ = try await ModelPipeline(
            steps: Self.loadSteps(in: workspace) + [.save(name: "note", url: workspace.url("copy/saved.xmi"))]
        ).run()

        #expect(try workspace.text(at: "copy/saved.xmi") == workspace.text(at: "copy/notes.xmi"))
    }

    @Test("two models saved to the same file are an error that writes neither")
    func sameFile() async throws {
        let workspace = try SaveDocumentURITests.Workspace()
        defer { workspace.remove() }
        let steps = Self.loadSteps(in: workspace) + [
            .save(name: "tasks", url: workspace.url(Self.savedNote)),
            .save(name: "note", url: workspace.url("output/../" + Self.savedNote)),
        ]

        await #expect(throws: DocumentRelocationError.self) { _ = try await ModelPipeline(steps: steps).run() }
        #expect(!FileManager.default.fileExists(atPath: workspace.url(Self.savedNote).path))
    }

    @Test("a model saved by two steps takes the first file and is copied to the second")
    func savedTwice() async throws {
        let workspace = try SaveDocumentURITests.Workspace()
        defer { workspace.remove() }

        let result = try await ModelPipeline(
            steps: Self.loadSteps(in: workspace) + [
                .save(name: "tasks", url: workspace.url(Self.savedProject)),
                .save(name: "tasks", url: workspace.url("backup/tasks.xmi")),
                .save(name: "note", url: workspace.url(Self.savedNote)),
            ]
        ).run()

        #expect(result.models["tasks"]?.uri == DocumentRelocation.canonicalURI(of: workspace.url(Self.savedProject)))
        #expect(FileManager.default.fileExists(atPath: workspace.url("backup/tasks.xmi").path))
        let text = try workspace.text(at: Self.savedNote)
        #expect(SaveDocumentURITests.hrefs("blocker", in: text) == ["tasks.xmi#//@tasks.1"], "\(text)")
    }

    @Test("models keep their locations when a file of the run cannot be written")
    func failedSaveRestores() async throws {
        let workspace = try SaveDocumentURITests.Workspace()
        defer { workspace.remove() }
        try workspace.write("not a directory", to: "blocked")
        let set = ResourceSet()

        await #expect(throws: (any Error).self) {
            _ = try await ModelPipeline(
                steps: Self.loadSteps(in: workspace) + [
                    .save(name: "tasks", url: workspace.url(Self.savedProject)),
                    .save(name: "note", url: workspace.url("blocked/notes.xmi")),
                ]
            ).run(in: set)
        }

        let uris = await set.getResources().map(\.uri)
        #expect(uris.contains(DocumentRelocation.canonicalURI(of: workspace.url("models/tasks.xmi"))), "\(uris)")
        #expect(uris.contains(DocumentRelocation.canonicalURI(of: workspace.url("models/notes.xmi"))), "\(uris)")
    }
}
