import Foundation
import Testing

/// Tests for `swift-atl generate --let-type-mismatches`, which chooses whether a typed `let`
/// in the templates whose value does not conform to the declared type is an error or a skipped
/// block.
@Suite("swift-atl generate - typed let mismatches")
struct LetTypeMismatchTests {
    /// The long name of the option.
    private static let option = "--let-type-mismatches"

    /// The text that starts the line of a warning on standard error.
    private static let warningPrefix = "warning: "

    /// A header module whose typed let binds the file name, a string, to an integer variable.
    private static let header = """
        [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
        [template public header(element : OclAny, fileName : String)][let n : Integer = fileName]// [n/][/let]// Customised[/template]
        """

    /// Generates Swift from the library fixture with the mismatching header module.
    ///
    /// - Parameter extra: The arguments after the model, language, output directory and template path.
    /// - Returns: The result of the command and the text of one generated file, if any.
    @MainActor
    private func generate(_ extra: [String]) async throws -> (result: SubprocessResult, text: String?) {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let output = fixture.scratch.appendingPathComponent("swift")
        let templates = fixture.scratch.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templates, withIntermediateDirectories: true)
        try Self.header.write(to: templates.appendingPathComponent("Header.mtl"), atomically: true, encoding: .utf8)

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [
                fixture.ecore.path, "--language", "swift", "-o", output.path, "--template-path", templates.path,
            ] + extra)
        let text = try? String(
            contentsOf: output.appendingPathComponent("library/BookCategory.swift"), encoding: .utf8)
        return (result, text)
    }

    @Test("skips the let blocks and warns once on standard error with --let-type-mismatches skip")
    @MainActor
    func skipWarns() async throws {
        let (result, text) = try await generate([Self.option, "skip"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text?.hasPrefix("// Customised\n") == true, "\(text ?? "no output")")
        let warnings = result.stderr.split(whereSeparator: \.isNewline).filter { $0.hasPrefix(Self.warningPrefix) }
        #expect(warnings.count == 1, "\(result.stderr)")
        #expect(warnings.first?.contains("'n'") == true)
    }

    @Test("fails on a mismatch by default")
    @MainActor
    func defaultFails() async throws {
        let (result, _) = try await generate([])

        #expect(!result.succeeded)
    }

    @Test("describes the option in the help of generate")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftATL(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains(Self.option))
        #expect(result.stdout.contains("error|skip"))
        #expect(result.stdout.contains("Acceleo"))
    }

    @Test("rejects a value that is not a mode")
    @MainActor
    func rejectsUnknownMode() async throws {
        let result = try await executeSwiftATL(command: "generate", arguments: [Self.option, "sometimes"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("sometimes"))
    }
}
