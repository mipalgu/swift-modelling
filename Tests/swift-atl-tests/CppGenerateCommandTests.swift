import Foundation
import Testing

@Suite("swift-atl generate - C++")
struct CppGenerateCommandTests {
    /// The options that make the output equal to the golden files.
    private static let goldenOptions = [
        "--base-package", "org.example", "--copyright", "Copyright 2026 Example Pty Ltd",
    ]

    /// The directory that holds the C++ files that generating the library fixture must produce.
    private static let expectedCpp = LibraryFixture.fixtureRoot.appendingPathComponent("library/expected-cpp")

    /// The directory that C++ is generated into.
    private func cppOutput(_ fixture: LibraryFixture) -> URL { fixture.scratch.appendingPathComponent("cpp") }

    @Test("generates exactly the golden files from an Ecore model")
    @MainActor
    func generatesFromEcore() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = cppOutput(fixture)

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "cpp"] + Self.goldenOptions + ["-o", output.path])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(result.stdout.range(of: #"Generated [0-9]+ files in:"#, options: .regularExpression) != nil)
        let expected = LibraryFixture.files(below: Self.expectedCpp)
        #expect(!expected.isEmpty)
        #expect(LibraryFixture.files(below: output) == expected)
        for path in expected {
            let actual = try? String(contentsOf: output.appendingPathComponent(path), encoding: .utf8)
            let golden = try String(contentsOf: Self.expectedCpp.appendingPathComponent(path), encoding: .utf8)
            #expect(actual == golden, "\(path) differs from the golden file")
        }
    }

    @Test("generates from the generator model that the genmodel language writes")
    @MainActor
    func generatesFromGenModel() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = cppOutput(fixture)

        let created = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "genmodel"] + Self.goldenOptions)
        #expect(created.succeeded, "\(created.stderr)")
        let result = try await executeSwiftATL(
            command: "generate", arguments: [fixture.genModel.path, "--language", "cpp", "-o", output.path])

        #expect(result.succeeded, "\(result.stderr)")
        let book = try String(contentsOf: output.appendingPathComponent("library/Book.hpp"), encoding: .utf8)
        #expect(book.contains("class Book final : public virtual Named, public virtual Lendable {"))
        #expect(book.hasPrefix("#pragma once\n\n//\n//  Book.hpp\n//\n//  Copyright 2026 Example Pty Ltd\n//\n"))
    }

    @Test("writes below the model directory on request")
    @MainActor
    func modelDirectory() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = cppOutput(fixture)

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "cpp", "-o", output.path, "--model-directory"])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent("library/src/library/Book.hpp").path))
        #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent("library/src/EObject.hpp").path))
    }

    @Test("accepts the template path and keeps hand edits when the code is generated again")
    @MainActor
    func templatePathAndMerge() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = cppOutput(fixture)
        let templates = fixture.scratch.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templates, withIntermediateDirectories: true)
        try """
        [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
        [template public header(element : OclAny, fileName : String)]// Customised[/template]
        """.write(to: templates.appendingPathComponent("Header.mtl"), atomically: true, encoding: .utf8)
        let arguments = [
            fixture.ecore.path, "--language", "cpp", "-o", output.path, "--template-path", templates.path,
        ]
        let first = try await executeSwiftATL(command: "generate", arguments: arguments)
        #expect(first.succeeded, "\(first.stderr)")
        let file = output.appendingPathComponent("library/BookCategory.hpp")
        #expect(try String(contentsOf: file, encoding: .utf8).hasPrefix("#pragma once\n\n// Customised\n"))

        var edited = try String(contentsOf: file, encoding: .utf8)
        let closing = try #require(edited.range(of: "}", options: .backwards))
        edited.replaceSubrange(closing, with: "\ninline int answer() { return 42; }\n\n}")
        try edited.write(to: file, atomically: true, encoding: .utf8)
        let again = try await executeSwiftATL(command: "generate", arguments: arguments)

        #expect(again.succeeded, "\(again.stderr)")
        #expect(try String(contentsOf: file, encoding: .utf8).contains("inline int answer() { return 42; }"))
    }

    @Test("the generator model defaults apply and a code style is not offered")
    @MainActor
    func defaultsAndStyles() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = cppOutput(fixture)

        let wizard = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "cpp", "--defaults", "wizard", "-o", output.path])
        let style = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "cpp", "--code-style", "emf", "-o", output.path + "-x"])

        #expect(wizard.succeeded, "\(wizard.stderr)")
        #expect(!style.succeeded)
        #expect(style.stderr.contains("emf"))
    }

    @Test("writes the names that C++ reserves with a trailing underscore")
    @MainActor
    func reservedNames() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("cpp")
        let ecore = LibraryFixture.fixtureRoot.appendingPathComponent("cnames/model/cnames.ecore")

        let result = try await executeSwiftATL(
            command: "generate", arguments: [ecore.path, "--language", "cpp", "-o", output.path])

        #expect(result.succeeded, "\(result.stderr)")
        let keyword = try String(contentsOf: output.appendingPathComponent("cnames/static_.hpp"), encoding: .utf8)
        #expect(keyword.contains("class static_ final : public virtual EObject {"))
    }
}
