import Foundation
import Testing

@Suite("swift-atl generate - Swift")
struct SwiftGenerateCommandTests {
    /// The options that make the output equal to the golden files.
    private static let goldenOptions = [
        "--base-package", "org.example", "--copyright", "Copyright 2026 Example Pty Ltd",
    ]

    /// The directory that holds the Swift files that generating the library fixture must produce.
    private static let expectedSwift = LibraryFixture.fixtureRoot.appendingPathComponent("library/expected-swift")

    /// The directory that Swift is generated into.
    private func swiftOutput(_ fixture: LibraryFixture) -> URL { fixture.scratch.appendingPathComponent("swift") }

    @Test("generates exactly the golden files from an Ecore model")
    @MainActor
    func generatesFromEcore() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = swiftOutput(fixture)

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "swift"] + Self.goldenOptions + ["-o", output.path])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(result.stdout.range(of: #"Generated [0-9]+ files in:"#, options: .regularExpression) != nil)
        let expected = LibraryFixture.files(below: Self.expectedSwift)
        #expect(!expected.isEmpty)
        #expect(LibraryFixture.files(below: output) == expected)
        for path in expected {
            let actual = try? String(contentsOf: output.appendingPathComponent(path), encoding: .utf8)
            let golden = try String(contentsOf: Self.expectedSwift.appendingPathComponent(path), encoding: .utf8)
            #expect(actual == golden, "\(path) differs from the golden file")
        }
    }

    @Test("generates from the generator model that the genmodel language writes")
    @MainActor
    func generatesFromGenModel() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = swiftOutput(fixture)

        let created = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "genmodel"] + Self.goldenOptions)
        #expect(created.succeeded, "\(created.stderr)")
        let result = try await executeSwiftATL(
            command: "generate", arguments: [fixture.genModel.path, "--language", "swift", "-o", output.path])

        #expect(result.succeeded, "\(result.stderr)")
        let book = try String(contentsOf: output.appendingPathComponent("library/Book.swift"), encoding: .utf8)
        #expect(book.contains("public final class Book: EObject, Named, Lendable {"))
        #expect(book.hasPrefix("//\n//  Book.swift\n//\n//  Copyright 2026 Example Pty Ltd\n//\n"))
    }

    @Test("writes below the model directory on request")
    @MainActor
    func modelDirectory() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = swiftOutput(fixture)

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "swift", "-o", output.path, "--model-directory"])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent("library/src/library/Book.swift").path))
    }

    @Test("accepts the template path and keeps hand edits when the code is generated again")
    @MainActor
    func templatePathAndMerge() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = swiftOutput(fixture)
        let templates = fixture.scratch.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templates, withIntermediateDirectories: true)
        try """
        [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
        [template public header(element : OclAny, fileName : String)]// Customised[/template]
        """.write(to: templates.appendingPathComponent("Header.mtl"), atomically: true, encoding: .utf8)
        let arguments = [
            fixture.ecore.path, "--language", "swift", "-o", output.path, "--template-path", templates.path,
        ]
        let first = try await executeSwiftATL(command: "generate", arguments: arguments)
        #expect(first.succeeded, "\(first.stderr)")
        let file = output.appendingPathComponent("library/BookCategory.swift")
        #expect(try String(contentsOf: file, encoding: .utf8).hasPrefix("// Customised\n"))

        var edited = try String(contentsOf: file, encoding: .utf8)
        let closing = try #require(edited.range(of: "}", options: .backwards))
        edited.replaceSubrange(closing, with: "\n    public var answer: Int { 42 }\n}")
        try edited.write(to: file, atomically: true, encoding: .utf8)
        let again = try await executeSwiftATL(command: "generate", arguments: arguments)

        #expect(again.succeeded, "\(again.stderr)")
        #expect(try String(contentsOf: file, encoding: .utf8).contains("public var answer: Int { 42 }"))
    }

    @Test("the generator model defaults apply and a code style is not offered")
    @MainActor
    func defaultsAndStyles() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = swiftOutput(fixture)

        let wizard = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "swift", "--defaults", "wizard", "-o", output.path])
        let style = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "swift", "--code-style", "emf", "-o", output.path + "-x"])

        #expect(wizard.succeeded, "\(wizard.stderr)")
        #expect(!style.succeeded)
        #expect(style.stderr.contains("emf"))
    }
}
