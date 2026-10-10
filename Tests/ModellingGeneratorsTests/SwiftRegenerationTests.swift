import Foundation
import Testing

@testable import ModellingGenerators

@Suite("Regenerating Swift files")
struct SwiftRegenerationTests {
    /// The file that the tests edit, relative to the output directory.
    static let writer = "library/Writer.swift"

    /// Generates the library fixture once.
    @MainActor
    func library() async throws -> GeneratedProject {
        let golden = try #require(SwiftGoldenCase.named("library"))
        return try await generateSwift(golden)
    }

    /// Replaces the first occurrence of a text in a generated file.
    func edit(_ generated: GeneratedProject, _ path: String, _ old: String, with new: String) throws {
        let text = try generated.text(path)
        let range = try #require(text.range(of: old), "'\(old)' is not in \(path)")
        var edited = text
        edited.replaceSubrange(range, with: new)
        try edited.write(to: generated.file(path), atomically: true, encoding: .utf8)
    }

    @Test("Generating again changes nothing")
    @MainActor
    func idempotent() async throws {
        let generated = try await library()
        defer { generated.remove() }
        let before = try generated.generatedPaths().map { try generated.text($0) }
        try await generated.generate()
        #expect(try generated.generatedPaths().map { try generated.text($0) } == before)
    }

    @Test("A member marked as not generated is kept, and so are members written by hand")
    @MainActor
    func keepsEdits() async throws {
        let generated = try await library()
        defer { generated.remove() }
        try edit(
            generated, Self.writer, "    // @generated\n    public var name: String? {",
            with: "    // @generated NOT\n    public var name: String? {")
        try edit(
            generated, Self.writer, "get { eStorage.withLock { $0.name } }",
            with: "get { eStorage.withLock { $0.name?.uppercased() } }")
        try edit(
            generated, Self.writer, "    /// Compares two objects",
            with: "    /// A helper written by hand.\n    public func shout() -> String { (name ?? \"\") + \"!\" }\n\n    /// Compares two objects")

        try await generated.generate()

        let text = try generated.text(Self.writer)
        #expect(text.contains("$0.name?.uppercased()"))
        #expect(text.contains("// @generated NOT"))
        #expect(text.contains("public func shout() -> String"))
        #expect(text.components(separatedBy: "public var name: String?").count == 2, "the member is not repeated")
    }

    @Test("A generated member that was changed is written again")
    @MainActor
    func regeneratesTaggedMembers() async throws {
        let generated = try await library()
        defer { generated.remove() }
        let original = try generated.text(Self.writer)
        try edit(
            generated, Self.writer, "get { eStorage.withLock { $0.name } }",
            with: "get { eStorage.withLock { $0.name?.uppercased() } }")

        try await generated.generate()

        #expect(try generated.text(Self.writer) == original)
    }

    @Test("Forcing the overwrite replaces edits")
    @MainActor
    func forcedOverwrite() async throws {
        let generated = try await library()
        defer { generated.remove() }
        let original = try generated.text(Self.writer)
        try edit(
            generated, Self.writer, "    // @generated\n    public var name: String? {",
            with: "    // @generated NOT\n    public var name: String? {")

        try await generated.generate(options: GenerationOptions(forceOverwrite: true))

        #expect(try generated.text(Self.writer) == original)
    }

    @Test("The diff option writes the generated text beside an existing file")
    @MainActor
    func diff() async throws {
        let generated = try await library()
        defer { generated.remove() }
        let original = try generated.text(Self.writer)
        try edit(
            generated, Self.writer, "get { eStorage.withLock { $0.name } }",
            with: "get { eStorage.withLock { $0.name?.uppercased() } }")
        let damaged = try generated.text(Self.writer)

        try await generated.generate(options: GenerationOptions(diff: true))

        #expect(try generated.text(Self.writer) == damaged)
        #expect(try generated.text("library/.Writer.swift.new") == original)
    }
}
