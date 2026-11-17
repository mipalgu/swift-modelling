import ECore
import EMFBase
import Foundation
import Testing

/// Tests for how `swift-atl transform` writes references from a target model to elements of a
/// source model: relative to the target by default, and as absolute URIs with
/// `--document-uris absolute`.
@Suite("swift-atl - document URIs of target models")
struct DocumentURITests {
    /// The long name of the option.
    private static let option = "--document-uris"

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
    static let model = """
        <?xml version="1.0" encoding="UTF-8"?>
        <tasks:Project xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:tasks="http://www.example.org/tasks" name="release">
          <tasks name="drafting"/>
          <tasks name="reviewing" done="true"/>
          <tasks name="publishing" done="true"/>
        </tasks:Project>
        """

    /// A transformation that writes a note for each open task, referring to the tasks that are
    /// done, which no rule transforms, so that the note refers to them in the source model.
    static let transformation = """
        -- @path Tasks=/Tasks.ecore
        -- @path Notes=/Notes.ecore

        module TaskNotes;
        create OUT : Notes from IN : Tasks;

        rule OpenTask {
            from t : Tasks!Task (t.done = false)
            to n : Notes!Note (
                name <- t.name,
                blocker <- Tasks!Task.allInstances()->select(x | x.done)->first(),
                follows <- Tasks!Task.allInstances()->select(x | x.done)
            )
        }
        """

    /// A directory with the metamodels, the transformation and the source model.
    struct Workspace {
        /// The temporary directory.
        let root: URL
        /// The transformation.
        let atl: URL
        /// The metamodel of the source model.
        let tasksMetamodel: URL
        /// The metamodel of the target model.
        let notesMetamodel: URL

        /// Creates the directory, with the source model at a path relative to it.
        ///
        /// - Parameter source: The path of the source model, relative to the directory.
        /// - Throws: An error if a file cannot be written.
        init(source: String) throws {
            root = try createTemporaryDirectory()
            atl = root.appendingPathComponent("TaskNotes.atl")
            tasksMetamodel = root.appendingPathComponent("Tasks.ecore")
            notesMetamodel = root.appendingPathComponent("Notes.ecore")
            try DocumentURITests.tasks.write(to: tasksMetamodel, atomically: true, encoding: .utf8)
            try DocumentURITests.notes.write(to: notesMetamodel, atomically: true, encoding: .utf8)
            try DocumentURITests.transformation.write(to: atl, atomically: true, encoding: .utf8)
            try write(DocumentURITests.model, to: source)
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
    }

    /// Runs the transformation from the workspace directory with paths relative to it.
    ///
    /// - Parameters:
    ///   - workspace: The workspace.
    ///   - source: The path of the source model, relative to the workspace.
    ///   - target: The path of the target model, relative to the workspace.
    ///   - absolutePaths: Whether the command line names the models by absolute paths.
    ///   - extra: The arguments after the source and target models.
    /// - Returns: The result of the command and the text of the target model, if any.
    @MainActor
    private func transform(
        _ workspace: Workspace, source: String, target: String, absolutePaths: Bool = true, extra: [String] = []
    ) async throws -> (result: SubprocessResult, text: String?) {
        let sourcePath = absolutePaths ? workspace.root.appendingPathComponent(source).path : source
        let targetPath = absolutePaths ? workspace.root.appendingPathComponent(target).path : target
        try FileManager.default.createDirectory(
            at: workspace.root.appendingPathComponent(target).deletingLastPathComponent(),
            withIntermediateDirectories: true)
        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                workspace.atl.path, "--metamodel-path", workspace.root.path, "--source", "IN=\(sourcePath)",
                "--target", "OUT=\(targetPath)",
            ] + extra,
            workingDirectory: workspace.root)
        return (result, try? String(contentsOf: workspace.root.appendingPathComponent(target), encoding: .utf8))
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

    /// Loads a target model and the names of the objects that its note refers to.
    ///
    /// - Parameters:
    ///   - workspace: The workspace with the metamodels.
    ///   - target: The path of the target model, relative to the workspace.
    /// - Returns: The name of the blocker and the names of the followed objects.
    /// - Throws: An error if the model cannot be loaded or a reference does not resolve.
    static func referencedNames(in workspace: Workspace, target: String) async throws
        -> (blocker: String, follows: [String])
    {
        let set = ResourceSet()
        let loaded = try await ModelIO.load(
            url: workspace.root.appendingPathComponent(target), resourceSet: set,
            metamodels: [workspace.tasksMetamodel, workspace.notesMetamodel])
        let note = try #require(await loaded.resource.getRootObjects().first as? DynamicEObject)
        var names: [String] = []
        for value in elements(of: note.eGet("blocker")) + elements(of: note.eGet("follows")) {
            let proxy = try #require(value as? ResourceProxy, "\(value)")
            let object = try #require(await proxy.resolveObject(in: set) as? DynamicEObject, "\(proxy)")
            names.append(try #require(object.eGet("name") as? String))
        }
        return (names[0], Array(names.dropFirst()))
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

    /// Locations of the source and target models, with the relative URI of the source in the target.
    static let layouts: [(source: String, target: String, relative: String)] = [
        ("tasks.xmi", "notes.xmi", "tasks.xmi"),
        ("models/tasks.xmi", "output/notes.xmi", "../models/tasks.xmi"),
        ("tasks.xmi", "output/notes.xmi", "../tasks.xmi"),
        ("models/tasks.xmi", "notes.xmi", "models/tasks.xmi"),
    ]

    @Test("refers to untransformed source elements by a relative URI by default", arguments: layouts)
    @MainActor
    func relativeByDefault(layout: (source: String, target: String, relative: String)) async throws {
        let workspace = try Workspace(source: layout.source)
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await transform(workspace, source: layout.source, target: layout.target)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let output = try #require(text)
        #expect(Self.hrefs("blocker", in: output) == [layout.relative + "#//@tasks.1"], "\(output)")
        #expect(Self.hrefs("follows", in: output) == [layout.relative + "#//@tasks.1", layout.relative + "#//@tasks.2"], "\(output)")
        #expect(!output.contains("file:"), "\(output)")
        for absolute in workspace.absoluteForms {
            #expect(!output.contains(absolute), "\(output)")
        }
        let names = try await Self.referencedNames(in: workspace, target: layout.target)
        #expect(names.blocker == "reviewing")
        #expect(names.follows == ["reviewing", "publishing"])
    }

    @Test("refers to source elements by a relative URI when the models are named by relative paths")
    @MainActor
    func relativePaths() async throws {
        let workspace = try Workspace(source: "models/tasks.xmi")
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await transform(
            workspace, source: "models/tasks.xmi", target: "output/notes.xmi", absolutePaths: false)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let output = try #require(text)
        #expect(Self.hrefs("blocker", in: output) == ["../models/tasks.xmi#//@tasks.1"], "\(output)")
        for absolute in workspace.absoluteForms {
            #expect(!output.contains(absolute), "\(output)")
        }
        let names = try await Self.referencedNames(in: workspace, target: "output/notes.xmi")
        #expect(names.follows == ["reviewing", "publishing"])
    }

    @Test("refers to source elements by a relative URI with the plain reference style")
    @MainActor
    func relativePlain() async throws {
        let workspace = try Workspace(source: "models/tasks.xmi")
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await transform(
            workspace, source: "models/tasks.xmi", target: "output/notes.xmi", extra: ["--reference-style", "plain"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let output = try #require(text)
        #expect(output.contains("blocker=\"../models/tasks.xmi#//@tasks.1\""), "\(output)")
        #expect(output.contains("follows=\"../models/tasks.xmi#//@tasks.1 ../models/tasks.xmi#//@tasks.2\""), "\(output)")
        #expect(!output.contains("file:"), "\(output)")
        let names = try await Self.referencedNames(in: workspace, target: "output/notes.xmi")
        #expect(names.blocker == "reviewing")
    }

    @Test(
        "refers to source elements by a relative URI in a JSON target",
        arguments: [true, false])
    @MainActor
    func relativeJSON(absolutePaths: Bool) async throws {
        let workspace = try Workspace(source: "models/tasks.xmi")
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await transform(
            workspace, source: "models/tasks.xmi", target: "output/notes.json", absolutePaths: absolutePaths)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let output = try #require(text)
        #expect(output.contains("\"../models/tasks.xmi#//@tasks.1\""), "\(output)")
        #expect(!output.contains("file:"), "\(output)")
        for absolute in workspace.absoluteForms {
            #expect(!output.contains(absolute), "\(output)")
        }
        let names = try await Self.referencedNames(in: workspace, target: "output/notes.json")
        #expect(names.follows == ["reviewing", "publishing"])
    }

    @Test(
        "refers to source elements by absolute URIs with --document-uris absolute",
        arguments: [[], ["--reference-style", "plain"]])
    @MainActor
    func absoluteOptOut(style: [String]) async throws {
        let workspace = try Workspace(source: "models/tasks.xmi")
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await transform(
            workspace, source: "models/tasks.xmi", target: "output/notes.xmi", extra: [Self.option, "absolute"] + style)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let output = try #require(text)
        let sourceURI = URIReference.canonicalise(
            workspace.root.appendingPathComponent("models/tasks.xmi").absoluteString)
        #expect(output.contains("\(sourceURI)#//@tasks.1"), "\(output)")
        #expect(!output.contains("../models/tasks.xmi"), "\(output)")
        let names = try await Self.referencedNames(in: workspace, target: "output/notes.xmi")
        #expect(names.follows == ["reviewing", "publishing"])
    }

    @Test("writes the same target with --document-uris relative as without the option")
    @MainActor
    func relativeExplicit() async throws {
        let workspace = try Workspace(source: "models/tasks.xmi")
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (implicit, implicitText) = try await transform(workspace, source: "models/tasks.xmi", target: "output/a.xmi")
        let (explicit, explicitText) = try await transform(
            workspace, source: "models/tasks.xmi", target: "output/b.xmi", extra: [Self.option, "relative"])

        #expect(implicit.succeeded, "\(implicit.stdout)\(implicit.stderr)")
        #expect(explicit.succeeded, "\(explicit.stdout)\(explicit.stderr)")
        #expect(implicitText != nil)
        #expect(implicitText == explicitText)
    }

    @Test("takes the style of the configuration file, which the command line overrides")
    @MainActor
    func configurationKey() async throws {
        let workspace = try Workspace(source: "models/tasks.xmi")
        defer { cleanupTemporaryDirectory(workspace.root) }
        try workspace.write(#"{ "document-uris": "absolute" }"#, to: ".swift-modelling.json")
        let sourceURI = URIReference.canonicalise(
            workspace.root.appendingPathComponent("models/tasks.xmi").absoluteString)

        let (configured, configuredText) = try await transform(
            workspace, source: "models/tasks.xmi", target: "output/configured.xmi")
        let (overridden, overriddenText) = try await transform(
            workspace, source: "models/tasks.xmi", target: "output/overridden.xmi", extra: [Self.option, "relative"])
        let (ignored, ignoredText) = try await transform(
            workspace, source: "models/tasks.xmi", target: "output/ignored.xmi", extra: ["--no-config"])

        #expect(configured.succeeded, "\(configured.stdout)\(configured.stderr)")
        #expect(Self.hrefs("blocker", in: configuredText ?? "") == ["\(sourceURI)#//@tasks.1"], "\(configuredText ?? "")")
        #expect(overridden.succeeded, "\(overridden.stdout)\(overridden.stderr)")
        #expect(Self.hrefs("blocker", in: overriddenText ?? "") == ["../models/tasks.xmi#//@tasks.1"])
        #expect(ignored.succeeded, "\(ignored.stdout)\(ignored.stderr)")
        #expect(Self.hrefs("blocker", in: ignoredText ?? "") == ["../models/tasks.xmi#//@tasks.1"])
        let names = try await Self.referencedNames(in: workspace, target: "output/configured.xmi")
        #expect(names.follows == ["reviewing", "publishing"])
    }

    @Test("rejects a value of the configuration key that is not a document URI style")
    @MainActor
    func rejectsUnknownConfiguredStyle() async throws {
        let workspace = try Workspace(source: "tasks.xmi")
        defer { cleanupTemporaryDirectory(workspace.root) }
        try workspace.write(#"{ "document-uris": "sideways" }"#, to: ".swift-modelling.json")

        let (result, text) = try await transform(workspace, source: "tasks.xmi", target: "notes.xmi")

        #expect(!result.succeeded)
        for expected in ["'document-uris'", "'sideways'", "relative", "absolute"] {
            #expect(result.stderr.contains(expected), "\(expected) is missing from: \(result.stderr)")
        }
        #expect(text == nil)
    }

    @Test("rejects a value that is not a document URI style")
    @MainActor
    func rejectsUnknownStyle() async throws {
        let workspace = try Workspace(source: "tasks.xmi")
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await transform(
            workspace, source: "tasks.xmi", target: "notes.xmi", extra: [Self.option, "sideways"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("sideways"), "\(result.stderr)")
        #expect(text == nil)
    }

    @Test("lists the option and its values in the help of transform")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftATL(command: "transform", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains(Self.option))
        #expect(result.stdout.contains("relative"))
        #expect(result.stdout.contains("absolute"))
    }
}
