import Foundation
import Testing

@testable import ModellingGenerators

@Suite("Generator models of models reached through symbolic links")
struct GenModelSymbolicLinkTests {
    /// A copy of a fixture project together with a symbolic link to it.
    struct Linked {
        let project: FixtureProject
        let link: URL

        /// The location of a file of the project through the symbolic link.
        func viaLink(_ path: String) -> URL { link.appendingPathComponent(path) }

        /// The location of a file of the project by its real path.
        func real(_ path: String) -> URL { project.root.appendingPathComponent(path) }

        /// Copies the fixture and links to it from another scratch directory.
        static func make(_ fixture: String) throws -> Linked {
            let project = try FixtureProject.make(fixture)
            let holder = FileManager.default.temporaryDirectory
                .appendingPathComponent("swift-modelling-links").appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: holder, withIntermediateDirectories: true)
            let link = holder.appendingPathComponent("linked")
            try FileManager.default.createSymbolicLink(at: link, withDestinationURL: project.root)
            return Linked(project: project, link: link)
        }

        func remove() {
            project.remove()
            try? FileManager.default.removeItem(at: link.deletingLastPathComponent())
        }
    }

    @Test("The canonical form resolves links in the directory, also below directories that do not exist")
    func canonicalForm() throws {
        let linked = try Linked.make("families")
        defer { linked.remove() }
        let real = FileLocations.canonical(linked.real("model/families.ecore"))
        #expect(FileLocations.canonical(linked.viaLink("model/families.ecore")) == real)
        #expect(
            FileLocations.canonical(linked.viaLink("new/deeper/out.genmodel"))
                == FileLocations.canonical(linked.real("new/deeper/out.genmodel")))
        #expect(FileLocations.canonical(linked.viaLink("model/../model/families.ecore")) == real)
    }

    @Test("A model imported through a link refers to itself by a plain relative name")
    @MainActor
    func importThroughLink() async throws {
        let linked = try Linked.make("families")
        defer { linked.remove() }
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [linked.viaLink("model/families.ecore")])
        let text = try String(contentsOf: result.url, encoding: .utf8)
        #expect(text.contains("<foreignModel>families.ecore</foreignModel>"))
        #expect(text.contains(#"ecorePackage="families.ecore#/""#))
        #expect(text.contains(#"ecoreClass="families.ecore#//Family""#))
        #expect(!text.contains(".."))
    }

    @Test("The output and the source may reach the same directory by different paths")
    @MainActor
    func mixedPaths() async throws {
        let linked = try Linked.make("families")
        defer { linked.remove() }
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [linked.real("model/families.ecore")],
            options: GenModelImportOptions(output: linked.viaLink("model/families.genmodel")))
        let text = try String(contentsOf: result.url, encoding: .utf8)
        #expect(text.contains("<foreignModel>families.ecore</foreignModel>"))
        #expect(!text.contains(".."))

        let other = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [linked.viaLink("model/families.ecore")],
            options: GenModelImportOptions(output: linked.real("model/other.genmodel")))
        #expect(try String(contentsOf: other.url, encoding: .utf8).contains("<foreignModel>families.ecore</foreignModel>"))
    }

    @Test("An output in another directory is related to the source through the link")
    @MainActor
    func otherDirectory() async throws {
        let linked = try Linked.make("families")
        defer { linked.remove() }
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [linked.viaLink("model/families.ecore")],
            options: GenModelImportOptions(output: linked.viaLink("gen/deeper/families.genmodel")))
        let text = try String(contentsOf: result.url, encoding: .utf8)
        #expect(text.contains("<foreignModel>../../model/families.ecore</foreignModel>"))
        #expect(text.contains(#"ecoreClass="../../model/families.ecore#//Family""#))
    }

    @Test("A reload through a link keeps the settings and the plain references")
    @MainActor
    func reloadThroughLink() async throws {
        let linked = try Linked.make("families")
        defer { linked.remove() }
        let first = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [linked.real("model/families.ecore")],
            options: GenModelImportOptions(defaults: .wizard))
        var edited = try String(contentsOf: first.url, encoding: .utf8)
        edited = edited.replacingOccurrences(
            of: #"modelName="Families""#, with: #"modelName="Kin""#)
        try edited.write(to: first.url, atomically: true, encoding: .utf8)

        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [linked.viaLink("model/families.ecore")],
            options: GenModelImportOptions(reload: linked.viaLink("model/families.genmodel")))
        let text = try String(contentsOf: result.url, encoding: .utf8)
        #expect(result.reloaded)
        #expect(text.contains(#"modelName="Kin""#))
        #expect(text.contains(#"operationReflection="true""#))
        #expect(text.contains("<foreignModel>families.ecore</foreignModel>"))
        #expect(!text.contains(".."))
    }
}
