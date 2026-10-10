import Foundation
import Testing

@Suite("swift-atl generate - C")
struct CGenerateCommandTests {
    /// The options that make the output equal to the golden files.
    private static let goldenOptions = [
        "--base-package", "org.example", "--copyright", "Copyright 2026 Example Pty Ltd",
    ]

    /// The directory that holds the C files that generating the library fixture must produce.
    private static let expectedC = LibraryFixture.fixtureRoot.appendingPathComponent("library/expected-c")

    /// The directory that C is generated into.
    private func cOutput(_ fixture: LibraryFixture) -> URL { fixture.scratch.appendingPathComponent("c") }

    @Test("generates exactly the golden files from an Ecore model")
    @MainActor
    func generatesFromEcore() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = cOutput(fixture)

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "c"] + Self.goldenOptions + ["-o", output.path])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(result.stdout.range(of: #"Generated [0-9]+ files in:"#, options: .regularExpression) != nil)
        let expected = LibraryFixture.files(below: Self.expectedC)
        #expect(!expected.isEmpty)
        #expect(LibraryFixture.files(below: output) == expected)
        for path in expected {
            let actual = try? String(contentsOf: output.appendingPathComponent(path), encoding: .utf8)
            let golden = try String(contentsOf: Self.expectedC.appendingPathComponent(path), encoding: .utf8)
            #expect(actual == golden, "\(path) differs from the golden file")
        }
    }

    @Test("generates from the generator model that the genmodel language writes")
    @MainActor
    func generatesFromGenModel() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = cOutput(fixture)

        let created = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "genmodel"] + Self.goldenOptions)
        #expect(created.succeeded, "\(created.stderr)")
        let result = try await executeSwiftATL(
            command: "generate", arguments: [fixture.genModel.path, "--language", "c", "-o", output.path])

        #expect(result.succeeded, "\(result.stderr)")
        let header = try String(contentsOf: output.appendingPathComponent("library/library.h"), encoding: .utf8)
        #expect(header.contains("struct Book {\n"))
        #expect(header.hasPrefix("//\n//  library.h\n//\n//  Copyright 2026 Example Pty Ltd\n//\n"))
    }

    @Test("writes below the model directory on request")
    @MainActor
    func modelDirectory() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = cOutput(fixture)

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "c", "-o", output.path, "--model-directory"])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent("library/src/library/library.h").path))
    }

    @Test("accepts the template path and keeps hand edits when the code is generated again")
    @MainActor
    func templatePathAndMerge() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = cOutput(fixture)
        let templates = fixture.scratch.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templates, withIntermediateDirectories: true)
        try """
        [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
        [template public header(element : OclAny, fileName : String)]// Customised[/template]
        """.write(to: templates.appendingPathComponent("Header.mtl"), atomically: true, encoding: .utf8)
        let arguments = [
            fixture.ecore.path, "--language", "c", "-o", output.path, "--template-path", templates.path,
        ]
        let first = try await executeSwiftATL(command: "generate", arguments: arguments)
        #expect(first.succeeded, "\(first.stderr)")
        let file = output.appendingPathComponent("library/library.c")
        #expect(try String(contentsOf: file, encoding: .utf8).hasPrefix("// Customised\n"))

        var edited = try String(contentsOf: file, encoding: .utf8)
        edited += "\nint answer(void) {\n    return 42;\n}\n"
        try edited.write(to: file, atomically: true, encoding: .utf8)
        let again = try await executeSwiftATL(command: "generate", arguments: arguments)

        #expect(again.succeeded, "\(again.stderr)")
        #expect(try String(contentsOf: file, encoding: .utf8) == edited)
    }

    @Test("generates the names of the C and C++ keywords with a trailing underscore")
    @MainActor
    func keywordNames() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = cOutput(fixture)
        let ecore = LibraryFixture.fixtureRoot.appendingPathComponent("cnames/model/cnames.ecore")

        let result = try await executeSwiftATL(
            command: "generate", arguments: [ecore.path, "--language", "c", "-o", output.path])

        #expect(result.succeeded, "\(result.stderr)")
        let header = try String(contentsOf: output.appendingPathComponent("cnames/cnames.h"), encoding: .utf8)
        #expect(header.contains("typedef struct static_ static_;\n"))
        #expect(header.contains("    bool union_;\n"))
    }

    @Test("the generator model defaults apply and a code style is not offered")
    @MainActor
    func defaultsAndStyles() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = cOutput(fixture)

        let wizard = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "c", "--defaults", "wizard", "-o", output.path])
        let style = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "c", "--code-style", "emf", "-o", output.path + "-x"])

        #expect(wizard.succeeded, "\(wizard.stderr)")
        #expect(!style.succeeded)
        #expect(style.stderr.contains("emf"))
    }
}
