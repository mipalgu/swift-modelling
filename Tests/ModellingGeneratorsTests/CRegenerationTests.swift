import Foundation
import Testing

@testable import ModellingGenerators

@Suite("Regenerating C files")
struct CRegenerationTests {
    /// The source file that the tests edit, relative to the output directory.
    static let source = "library/library.c"

    /// The header that the tests edit, relative to the output directory.
    static let header = "library/library.h"

    /// The support header that the tests edit, relative to the output directory.
    static let support = "EObject.h"

    /// The getter of the pages of a book, whose body the tests change.
    static let pagesGetter = "int32_t Book_get_pages(const Book *self) {\n    return self->pages;"

    /// Generates the library fixture once.
    @MainActor
    func library() async throws -> GeneratedProject {
        let golden = try #require(CGoldenCase.named("library"))
        return try await generateC(golden)
    }

    /// Replaces the first occurrence of a text in a generated file.
    func edit(_ generated: GeneratedProject, _ path: String, _ old: String, with new: String) throws {
        let text = try generated.text(path)
        let range = try #require(text.range(of: old), "'\(old)' is not in \(path)")
        var edited = text
        edited.replaceSubrange(range, with: new)
        try edited.write(to: generated.file(path), atomically: true, encoding: .utf8)
    }

    /// How often a text occurs in another.
    func count(of needle: String, in text: String) -> Int {
        text.components(separatedBy: needle).count - 1
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
            generated, Self.source, "// @generated\n" + Self.pagesGetter,
            with: "// @generated NOT\nint32_t Book_get_pages(const Book *self) {\n    return self->pages + 1;")
        try edit(
            generated, Self.source, "// @generated\nbool Book_get_onLoan",
            with: "/// A helper written by hand.\nint shout(void) {\n    return 42;\n}\n\n// @generated\nbool Book_get_onLoan")

        try await generated.generate()

        let text = try generated.text(Self.source)
        #expect(text.contains("return self->pages + 1;"))
        #expect(text.contains("// @generated NOT"))
        #expect(text.contains("int shout(void) {\n    return 42;\n}\n"))
        #expect(count(of: "int32_t Book_get_pages(const Book *self) {", in: text) == 1, "the member is not repeated")
    }

    @Test("A generated member that was changed is written again")
    @MainActor
    func regeneratesTaggedMembers() async throws {
        let generated = try await library()
        defer { generated.remove() }
        let original = try generated.text(Self.source)
        try edit(generated, Self.source, "    return self->loanDays;\n}", with: "    return 12345;\n}")

        try await generated.generate()

        #expect(try generated.text(Self.source) == original)
    }

    @Test("A generated member that the model no longer produces is removed, and a missing one is added")
    @MainActor
    func removesAndAddsMembers() async throws {
        let generated = try await library()
        defer { generated.remove() }
        let original = try generated.text(Self.source)
        try edit(
            generated, Self.source, "// @generated\nbool Book_get_onLoan",
            with: "// @generated\nint obsolete(void) {\n    return 0;\n}\n\n// @generated\nbool Book_get_onLoan")
        try edit(
            generated, Self.source,
            "// @generated\nvoid Book_set_onLoan(Book *self, bool value) {\n    self->onLoan = value;\n}\n\n", with: "")
        #expect(try generated.text(Self.source).contains("obsolete"))
        #expect(!(try generated.text(Self.source).contains("void Book_set_onLoan")))

        try await generated.generate()

        #expect(try generated.text(Self.source) == original)
    }

    @Test("Declarations, macros, includes and fields written by hand stay in a header, also inside the block with C linkage")
    @MainActor
    func keepsHandWrittenHeaderMembers() async throws {
        let generated = try await library()
        defer { generated.remove() }
        try edit(
            generated, Self.header, "\n#ifdef __cplusplus\n}\n#endif\n\n#endif",
            with: "\n/// A declaration written by hand.\nint shout(void);\n\n#ifdef __cplusplus\n}\n#endif\n\n#endif")
        try edit(
            generated, Self.header, "void Book_set_pages(Book *self, int32_t value);\n",
            with: "void Book_set_pages(Book *self, int32_t value);\n\n/// A second declaration written by hand.\nint whisper(void);\n")
        try edit(
            generated, Self.header, "    EObject eObject;\n\n    /// @brief The name attribute.",
            with: "    EObject eObject;\n\n    /// A field written by hand.\n    int handwritten;\n\n    /// @brief The name attribute.")
        try edit(generated, Self.header, "#include <stdint.h>\n", with: "#include <stdint.h>\n#include <limits.h>\n")
        try edit(
            generated, Self.header, "#ifdef __cplusplus\n// @generated\nextern \"C\" {",
            with: "#define HANDWRITTEN 1\n\n#ifdef __cplusplus\n// @generated\nextern \"C\" {")
        let edited = try generated.text(Self.header)

        try await generated.generate()

        let text = try generated.text(Self.header)
        #expect(text == edited)
        for kept in ["int shout(void);", "int whisper(void);", "    int handwritten;\n", "#include <limits.h>\n", "#define HANDWRITTEN 1\n"] {
            #expect(count(of: kept, in: text) == 1, "'\(kept)' did not survive once")
        }
    }

    @Test("A hand-written include of a source file stays beside the generated ones")
    @MainActor
    func keepsHandWrittenIncludes() async throws {
        let generated = try await library()
        defer { generated.remove() }
        try edit(generated, Self.source, "#include <stdlib.h>\n", with: "#include <math.h>\n#include <stdlib.h>\n")

        try await generated.generate()

        let text = try generated.text(Self.source)
        #expect(count(of: "#include <math.h>\n", in: text) == 1)
        #expect(count(of: "#include <stdlib.h>\n", in: text) == 1)
        #expect(count(of: "#include \"library/library.h\"\n", in: text) == 1)
    }

    @Test("The support header is regenerated like any other header")
    @MainActor
    func regeneratesSupportHeader() async throws {
        let generated = try await library()
        defer { generated.remove() }
        let original = try generated.text(Self.support)
        try edit(
            generated, Self.support, "        object->eClass->destroy(object);", with: "        object->eClass->destroy(NULL);")
        try edit(
            generated, Self.support, "#ifdef __cplusplus\n// @generated\nextern \"C\" {",
            with: "#define HANDWRITTEN_SUPPORT 1\n\n#ifdef __cplusplus\n// @generated\nextern \"C\" {")

        try await generated.generate()

        let text = try generated.text(Self.support)
        #expect(text.contains("        object->eClass->destroy(object);"))
        #expect(!text.contains("destroy(NULL)"))
        #expect(text.contains("#define HANDWRITTEN_SUPPORT 1\n"))
        #expect(text.replacingOccurrences(of: "#define HANDWRITTEN_SUPPORT 1\n\n", with: "") == original)
    }

    @Test("Forcing the overwrite replaces edits")
    @MainActor
    func forcedOverwrite() async throws {
        let generated = try await library()
        defer { generated.remove() }
        let original = try generated.text(Self.source)
        try edit(
            generated, Self.source, "// @generated\n" + Self.pagesGetter,
            with: "// @generated NOT\nint32_t Book_get_pages(const Book *self) {\n    return self->pages + 1;")

        try await generated.generate(options: GenerationOptions(forceOverwrite: true))

        #expect(try generated.text(Self.source) == original)
    }

    @Test("The diff option writes the generated text beside an existing file")
    @MainActor
    func diff() async throws {
        let generated = try await library()
        defer { generated.remove() }
        let original = try generated.text(Self.source)
        try edit(generated, Self.source, "    return self->loanDays;\n}", with: "    return 12345;\n}")
        let damaged = try generated.text(Self.source)

        try await generated.generate(options: GenerationOptions(diff: true))

        #expect(try generated.text(Self.source) == damaged)
        #expect(try generated.text("library/.library.c.new") == original)
    }
}
