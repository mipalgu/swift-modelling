import Foundation
import Testing

@testable import ModellingGenerators

@Suite("Regenerating Java files")
struct JavaRegenerationTests {
    /// The path of the library enumeration in the generated output.
    static let bookCategory = "org/example/library/BookCategory.java"

    /// Generates the library once so that its file can be edited.
    @MainActor
    static func generatedLibrary() async throws -> GeneratedProject {
        let generated = try await GeneratedProject.make(
            "library", stem: "library", options: GenModelImportOptions(basePackage: "org.example"))
        try await generated.generate()
        return generated
    }

    /// Marks a method as maintained by hand and gives it another body.
    static func editByHand(_ text: String) -> String {
        guard let method = text.range(of: "public static BookCategory getByName"),
            let tag = text.range(of: "@generated", options: .backwards, range: text.startIndex..<method.lowerBound)
        else { return text }
        var edited = text
        edited.replaceSubrange(tag, with: "@generated NOT")
        edited = edited.replacingOccurrences(
            of: "if (result.getName().equals(name))", with: "if (result.getName().equalsIgnoreCase(name))")
        return edited
    }

    @Test("A method marked as not generated survives regeneration")
    @MainActor
    func keepsHandEditedMethods() async throws {
        let generated = try await Self.generatedLibrary()
        defer { generated.remove() }
        let edited = Self.editByHand(try generated.text(Self.bookCategory))
        #expect(edited.contains("@generated NOT"))
        try edited.write(to: generated.file(Self.bookCategory), atomically: true, encoding: .utf8)

        try await generated.generate()
        let regenerated = try generated.text(Self.bookCategory)
        #expect(regenerated.contains("equalsIgnoreCase(name)"))
        #expect(regenerated.contains("@generated NOT"))
    }

    @Test("Members that carry no generated tag are kept")
    @MainActor
    func keepsAddedMembers() async throws {
        let generated = try await Self.generatedLibrary()
        defer { generated.remove() }
        var text = try generated.text(Self.bookCategory)
        let closing = try #require(text.range(of: "}", options: .backwards))
        text.replaceSubrange(
            closing, with: "\n  public int answer()\n  {\n    return 42;\n  }\n}")
        try text.write(to: generated.file(Self.bookCategory), atomically: true, encoding: .utf8)

        try await generated.generate()
        #expect(try generated.text(Self.bookCategory).contains("public int answer()"))
    }

    @Test("Generated members are regenerated when their content was damaged")
    @MainActor
    func regeneratesGeneratedMembers() async throws {
        let generated = try await Self.generatedLibrary()
        defer { generated.remove() }
        let original = try generated.text(Self.bookCategory)
        let damaged = original.replacingOccurrences(of: "return literal;", with: "return \"damaged\";")
        #expect(damaged != original)
        try damaged.write(to: generated.file(Self.bookCategory), atomically: true, encoding: .utf8)

        try await generated.generate()
        let regenerated = try generated.text(Self.bookCategory)
        #expect(!regenerated.contains("damaged"))
        #expect(regenerated == original)
    }

    @Test("Forcing the overwrite replaces hand-edited files")
    @MainActor
    func forceOverwrite() async throws {
        let generated = try await Self.generatedLibrary()
        defer { generated.remove() }
        let original = try generated.text(Self.bookCategory)
        try Self.editByHand(original).write(
            to: generated.file(Self.bookCategory), atomically: true, encoding: .utf8)

        try await generated.generate(options: GenerationOptions(forceOverwrite: true))
        #expect(try generated.text(Self.bookCategory) == original)
    }

    @Test("The diff option writes beside an existing file and leaves it alone")
    @MainActor
    func diffOption() async throws {
        let generated = try await Self.generatedLibrary()
        defer { generated.remove() }
        let original = try generated.text(Self.bookCategory)
        let edited = Self.editByHand(original)
        try edited.write(to: generated.file(Self.bookCategory), atomically: true, encoding: .utf8)

        try await generated.generate(options: GenerationOptions(diff: true))
        #expect(try generated.text(Self.bookCategory) == edited)
        let redirected = "org/example/library/.BookCategory.java.new"
        #expect(try generated.text(redirected) == original)
    }

    @Test("An explicit redirection pattern is honoured")
    @MainActor
    func redirectionPattern() async throws {
        let generated = try await Self.generatedLibrary()
        defer { generated.remove() }
        let edited = Self.editByHand(try generated.text(Self.bookCategory))
        try edited.write(to: generated.file(Self.bookCategory), atomically: true, encoding: .utf8)

        try await generated.generate(options: GenerationOptions(redirectionPattern: "{0}.generated"))
        #expect(FileManager.default.fileExists(atPath: generated.file("org/example/library/BookCategory.java.generated").path))
    }

    @Test("Regenerating unchanged output does not touch the files")
    @MainActor
    func unchangedOutput() async throws {
        let generated = try await Self.generatedLibrary()
        defer { generated.remove() }
        let before = try generated.text(Self.bookCategory)
        try await generated.generate(options: GenerationOptions(diff: true))
        #expect(try generated.text(Self.bookCategory) == before)
        #expect(!FileManager.default.fileExists(atPath: generated.file("org/example/library/.BookCategory.java.new").path))
    }
}
