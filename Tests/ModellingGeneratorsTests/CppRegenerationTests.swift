import Foundation
import Testing

@testable import ModellingGenerators

@Suite("Regenerating C++ headers")
struct CppRegenerationTests {
    /// The file that the tests edit, relative to the output directory.
    static let writer = "library/Writer.hpp"

    /// The getter of the name that the writer inherits, with its tag.
    static let nameGetter = "    // @generated\n    const std::string &getName() const override { return m_name; }"

    /// The setter of the name that the writer inherits.
    static let nameSetter = "void setName(const std::string &value) override { m_name = value; }"

    /// Generates the library fixture once.
    @MainActor
    func library() async throws -> GeneratedProject {
        let golden = try #require(CppGoldenCase.named("library"))
        return try await generateCpp(golden)
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
            generated, Self.writer, Self.nameGetter,
            with: "    // @generated NOT\n    const std::string &getName() const override { return m_name; /* kept */ }")
        try edit(
            generated, Self.writer, "private:\n",
            with: "    /// A helper written by hand.\n    std::string shout() const { return getName() + \"!\"; }\n\nprivate:\n")

        try await generated.generate()

        let text = try generated.text(Self.writer)
        #expect(text.contains("/* kept */"))
        #expect(text.contains("// @generated NOT"))
        #expect(text.contains("std::string shout() const"))
        #expect(text.components(separatedBy: "getName() const override").count == 2, "the member is not repeated")
    }

    @Test("A generated member that was changed is written again")
    @MainActor
    func regeneratesTaggedMembers() async throws {
        let generated = try await library()
        defer { generated.remove() }
        let original = try generated.text(Self.writer)
        try edit(generated, Self.writer, Self.nameSetter, with: "void setName(const std::string &value) override { m_name = value + \"?\"; }")

        try await generated.generate()

        #expect(try generated.text(Self.writer) == original)
    }

    @Test("A generated member that was removed comes back")
    @MainActor
    func restoresRemovedMembers() async throws {
        let generated = try await library()
        defer { generated.remove() }
        let original = try generated.text(Self.writer)
        try edit(
            generated, Self.writer,
            "\n    /// @brief The storage of the aliases attribute.\n    // @generated\n    std::vector<std::string> m_aliases;\n",
            with: "")
        #expect(try generated.text(Self.writer) != original)

        try await generated.generate()

        let text = try generated.text(Self.writer)
        #expect(text.contains("    std::vector<std::string> m_aliases;\n"))
        #expect(text.components(separatedBy: "    std::vector<std::string> m_aliases;\n").count == 2, "the member is not repeated")
    }

    @Test("Includes written by hand are kept, and the generated ones are not repeated")
    @MainActor
    func keepsIncludes() async throws {
        let generated = try await library()
        defer { generated.remove() }
        try edit(generated, Self.writer, "#include <vector>\n", with: "#include <vector>\n#include <cstdio>\n")

        try await generated.generate()

        let includes = try generated.text(Self.writer).components(separatedBy: "\n").filter { $0.hasPrefix("#include ") }
        #expect(includes.contains("#include <cstdio>"))
        #expect(Set(includes).count == includes.count)
        #expect(includes.filter { $0 == "#include <vector>" }.count == 1)
    }

    @Test("A header that was edited still compiles after it is generated again")
    @MainActor
    func regeneratedHeadersKeepTheirStructure() async throws {
        let generated = try await library()
        defer { generated.remove() }
        try edit(
            generated, Self.writer, "private:\n",
            with: "    /// A helper written by hand.\n    std::string shout() const { return getName() + \"!\"; }\n\nprivate:\n")
        try await generated.generate()
        let text = try generated.text(Self.writer)
        #expect(CppModelTextTests.untaggedDeclarations(in: text) == ["std::string shout() const { return getName() + \"!\"; }"])
        #expect(text.hasSuffix("};\n\n}\n"))
    }

    @Test("Forcing the overwrite replaces edits")
    @MainActor
    func forcedOverwrite() async throws {
        let generated = try await library()
        defer { generated.remove() }
        let original = try generated.text(Self.writer)
        try edit(
            generated, Self.writer, Self.nameGetter,
            with: "    // @generated NOT\n    const std::string &getName() const override { return m_name; /* kept */ }")

        try await generated.generate(options: GenerationOptions(forceOverwrite: true))

        #expect(try generated.text(Self.writer) == original)
    }

    @Test("The diff option writes the generated text beside an existing file")
    @MainActor
    func diff() async throws {
        let generated = try await library()
        defer { generated.remove() }
        let original = try generated.text(Self.writer)
        try edit(generated, Self.writer, Self.nameSetter, with: "void setName(const std::string &value) override { m_name = value + \"?\"; }")
        let damaged = try generated.text(Self.writer)

        try await generated.generate(options: GenerationOptions(diff: true))

        #expect(try generated.text(Self.writer) == damaged)
        #expect(try generated.text("library/.Writer.hpp.new") == original)
    }
}
