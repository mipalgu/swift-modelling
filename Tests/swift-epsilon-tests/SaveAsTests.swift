//
// SaveAsTests.swift
// swift-epsilon-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import EMFBase
import Foundation
import Testing

/// Tests for how swift-epsilon writes models that refer to each other to new files: each
/// written model takes the location of its file before any is written, so that the written
/// models refer to each other at their new locations, whichever is written first.
@Suite("swift-epsilon - models saved together at new locations", .serialized)
struct SaveAsTests {
    /// The path of the written project, relative to the workspace.
    static let writtenProject = "output/tasks.xmi"

    /// The path of the written note, relative to the workspace.
    static let writtenNote = "output/notes.xmi"

    /// The arguments that read the project and the note that refers to it, and name both metamodels.
    static let modelArguments = [
        "--model", "Tasks=\(DocumentURITests.project)", "--model", "Notes=models/notes.xmi",
        "-m", "Tasks.ecore", "-m", "Notes.ecore",
    ]

    /// The `--store` arguments that write the project and the note to the output directory, in
    /// either order.
    static let storeOrders: [[String]] = [
        ["--store", "Tasks=\(writtenProject)", "--store", "Notes=\(writtenNote)"],
        ["--store", "Notes=\(writtenNote)", "--store", "Tasks=\(writtenProject)"],
    ]

    /// The document URI style that writes the URIs of other documents relative to the model.
    static let relative = "relative"

    /// The document URI styles, as given on the command line.
    static let styles = [relative, "absolute"]

    /// Checks that a written note refers to the project written beside it.
    ///
    /// The models that were read are removed first, so that the references of the note resolve
    /// only if they name the written project.
    ///
    /// - Parameters:
    ///   - workspace: The workspace.
    ///   - style: The document URI style with which the note was written.
    /// - Throws: An error if the note cannot be read or a reference does not resolve.
    static func expectNoteRefersToWrittenProject(in workspace: DocumentURITests.Workspace, style: String) async throws {
        let text = try #require(workspace.text(at: writtenNote))
        let blocker = try #require(DocumentURITests.hrefs("blocker", in: text).first, "\(text)")
        if style == relative {
            #expect(blocker == "tasks.xmi#//@tasks.1", "\(text)")
            #expect(!text.contains("file:"), "\(text)")
        } else {
            #expect(blocker.hasPrefix("file:"), "\(text)")
            #expect(blocker.hasSuffix("/" + writtenProject + "#//@tasks.1"), "\(text)")
        }
        #expect(!text.contains("models/tasks.xmi"), "\(text)")
        try FileManager.default.removeItem(at: workspace.root.appendingPathComponent("models"))
        let names = try await DocumentURITests.referencedNames(in: workspace, path: writtenNote)
        #expect(names.blocker == "reviewing")
        #expect(names.follows == ["reviewing", "publishing"])
    }

    @Test(
        "eol run stores models that refer to each other in a new directory, referring to each other there",
        arguments: storeOrders, styles)
    func storedTogether(stores: [String], style: String) async throws {
        let workspace = try DocumentURITests.Workspace()
        defer { workspace.remove() }

        let run = try await runSwiftEpsilon(
            ["eol", "run", "rename.eol"] + Self.modelArguments + stores + [DocumentURITests.option, style],
            in: workspace.root)

        #expect(run.succeeded, "\(run.error)")
        #expect(workspace.text(at: Self.writtenNote)?.contains("name=\"renamed\"") == true)
        try await Self.expectNoteRefersToWrittenProject(in: workspace, style: style)
    }

    @Test("etl transform writes a target that refers to the source stored beside it", arguments: styles)
    func targetBesideStoredSource(style: String) async throws {
        let workspace = try DocumentURITests.Workspace()
        defer { workspace.remove() }

        let run = try await runSwiftEpsilon(
            ["etl", "transform", "notes.etl", "--target", "Notes=\(Self.writtenNote)", "--store",
             "Tasks=\(Self.writtenProject)"] + DocumentURITests.projectArguments + [DocumentURITests.option, style],
            in: workspace.root)

        #expect(run.succeeded, "\(run.error)")
        try await Self.expectNoteRefersToWrittenProject(in: workspace, style: style)
    }

    @Test("eol run refuses to write two models to the same file and writes neither")
    func sameFile() async throws {
        let workspace = try DocumentURITests.Workspace()
        defer { workspace.remove() }

        let run = try await runSwiftEpsilon(
            ["eol", "run", "rename.eol"] + Self.modelArguments
                + ["--store", "Tasks=\(Self.writtenNote)", "--store", "Notes=output/../\(Self.writtenNote)"],
            in: workspace.root)

        #expect(!run.succeeded)
        #expect(run.error.contains(Self.writtenNote), "\(run.error)")
        #expect(run.error.contains("same file"), "\(run.error)")
        #expect(workspace.text(at: Self.writtenNote) == nil)
    }

    @Test("eol run refuses to write a model over the file of another model it has read")
    func fileOfAnotherModel() async throws {
        let workspace = try DocumentURITests.Workspace()
        defer { workspace.remove() }
        let project = workspace.text(at: DocumentURITests.project)

        let run = try await runSwiftEpsilon(
            ["eol", "run", "rename.eol"] + Self.modelArguments + ["--store", "Notes=\(DocumentURITests.project)"],
            in: workspace.root)

        #expect(!run.succeeded)
        #expect(run.error.contains(DocumentURITests.project), "\(run.error)")
        #expect(workspace.text(at: DocumentURITests.project) == project)
    }

    @Test("eol run stores two models in each other's files, each referring to the other at its new file")
    func swapped() async throws {
        let workspace = try DocumentURITests.Workspace()
        defer { workspace.remove() }
        try workspace.write(DocumentURITests.taskModel, to: "models/other.xmi")

        let run = try await runSwiftEpsilon(
            ["eol", "run", "rename.eol", "--model", "Tasks=models/tasks.xmi", "--model", "Other=models/other.xmi",
             "--model", "Notes=models/notes.xmi", "-m", "Tasks.ecore", "-m", "Notes.ecore",
             "--store", "Tasks=models/other.xmi", "--store", "Other=models/tasks.xmi", "--store", "Notes"],
            in: workspace.root)

        #expect(run.succeeded, "\(run.error)")
        let note = try #require(workspace.text(at: "models/notes.xmi"))
        #expect(DocumentURITests.hrefs("blocker", in: note) == ["other.xmi#//@tasks.1"], "\(note)")
    }
}
