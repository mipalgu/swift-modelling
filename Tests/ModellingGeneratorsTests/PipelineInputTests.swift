import Foundation
import Synchronization
import Testing

@testable import ModellingGenerators

@Suite("Generating from Ecore models, generator models and replacement transformations")
struct PipelineInputTests {
    /// The generated enumeration of the library fixture.
    static let bookCategory = "org/example/library/BookCategory.java"

    private static let options = GenModelImportOptions(
        basePackage: "org.example", copyright: "Copyright 2026 Example Pty Ltd")

    // MARK: - Input kinds

    @Test("An Ecore model is imported on the way and leaves no generator model behind")
    @MainActor
    func ecoreInput() async throws {
        let project = try FixtureProject.make("library")
        defer { project.remove() }
        let output = project.root.appendingPathComponent("java")

        let result = try await GenerationPipeline.generate(
            inputURL: project.model("library.ecore"), language: "java", outputDirectory: output,
            importOptions: Self.options)

        #expect(result.files.contains { $0.path.hasSuffix(Self.bookCategory) })
        #expect(!FileManager.default.fileExists(atPath: project.model("library.genmodel").path))
        let expected = try String(contentsOf: project.javaExpectation(Self.bookCategory), encoding: .utf8)
        #expect(try String(contentsOf: output.appendingPathComponent(Self.bookCategory), encoding: .utf8) == expected)
    }

    @Test("A generator model is generated from directly, whatever the import options say")
    @MainActor
    func genModelInput() async throws {
        let generated = try await GeneratedProject.make("library", stem: "library", options: Self.options)
        defer { generated.remove() }

        let result = try await GenerationPipeline.generate(
            inputURL: generated.genModel, language: "java", outputDirectory: generated.output,
            importOptions: GenModelImportOptions(basePackage: "ignored.package"))

        #expect(result.files.contains { $0.path.hasSuffix(Self.bookCategory) })
        #expect(!result.files.contains { $0.path.contains("ignored") })
    }

    @Test("Any other kind of input is refused")
    @MainActor
    func unsupportedInput() async throws {
        let scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-genmodel-tests").appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: scratch) }
        let other = scratch.appendingPathComponent("model.xmi")
        try "<x/>".write(to: other, atomically: true, encoding: .utf8)

        await #expect(throws: GenerationError.unsupportedInput(other.path)) {
            _ = try await GenerationPipeline.generate(
                inputURL: other, language: "java", outputDirectory: scratch)
        }
        #expect(GenerationError.unsupportedInput("a.xmi").description.contains("neither a generator model"))
    }

    @Test("The progress reports of an import precede those of the generation")
    @MainActor
    func progressOrder() async throws {
        let project = try FixtureProject.make("library")
        defer { project.remove() }
        let messages = ProgressLog()

        _ = try await GenerationPipeline.generate(
            inputURL: project.model("library.ecore"), language: "java",
            outputDirectory: project.root.appendingPathComponent("java"), importOptions: Self.options,
            progress: { messages.append($0.message) })

        let all = messages.messages
        let transforming = try #require(all.firstIndex { $0.hasPrefix("Transforming") })
        let generated = try #require(all.firstIndex { $0.hasPrefix("Generated") })
        #expect(transforming < generated)
    }

    // MARK: - Replacement transformation

    /// The bundled transformation with the model directory changed.
    private static func customisedTransformation(in directory: URL) throws -> URL {
        let bundled = try #require(GenModelTransformation.resourceURL)
        let text = try String(contentsOf: bundled, encoding: .utf8)
            .replacingOccurrences(of: "'/'.concat(thisModule.projectName).concat('/src')", with: "'/custom/src'")
        #expect(text.contains("/custom/src"))
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("Ecore2GenModel.atl")
        try text.write(to: file, atomically: true, encoding: .utf8)
        return file
    }

    @Test("A replacement transformation file or directory is used instead of the bundled one")
    @MainActor
    func replacementTransformation() async throws {
        let project = try FixtureProject.make("library")
        defer { project.remove() }
        let directory = project.root.appendingPathComponent("transformations")
        let file = try Self.customisedTransformation(in: directory)

        for (index, location) in [file, directory].enumerated() {
            var options = Self.options
            options.transformation = location
            options.output = project.root.appendingPathComponent("replaced\(index).genmodel")
            let result = try await GenerationPipeline.ecoreToGenModel(
                ecoreURLs: [project.model("library.ecore")], options: options)
            #expect(
                try String(contentsOf: result.url, encoding: .utf8).contains("modelDirectory=\"/custom/src\""))
        }
    }

    @Test("A replacement transformation that is missing or incomplete is reported")
    @MainActor
    func missingReplacement() async throws {
        let project = try FixtureProject.make("library")
        defer { project.remove() }
        let empty = project.root.appendingPathComponent("empty")
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)

        for location in [project.root.appendingPathComponent("absent.atl"), empty] {
            var options = Self.options
            options.transformation = location
            await #expect(throws: GenerationError.self) {
                _ = try await GenerationPipeline.ecoreToGenModel(
                    ecoreURLs: [project.model("library.ecore")], options: options)
            }
        }
        let message = GenerationError.transformationUnavailable("x").description
        #expect(message.contains("unavailable"))
    }

    @Test("The default import options keep the bundled transformation")
    func defaultTransformation() {
        #expect(GenModelImportOptions().transformation == nil)
    }

    // MARK: - Prefix arguments

    @Test("A prefix without an assignment names the root package and one with an assignment a package")
    func prefixArguments() {
        var options = GenModelImportOptions()

        options.addPrefix("Library")
        options.addPrefix("people=Ppl")
        options.addPrefix("expr=a=b")

        #expect(options.prefix == "Library")
        #expect(options.packagePrefixes == ["people": "Ppl", "expr": "a=b"])
    }

    // MARK: - Languages

    @Test("The pseudo-language never names a template set")
    func pseudoLanguage() {
        #expect(TemplateSetConstants.genModelLanguage == "genmodel")
        #expect(!TemplateSet.availableLanguages().contains(TemplateSetConstants.genModelLanguage))
        #expect(TemplateSet.availableLanguages().contains("java"))
    }
}

/// Collects progress messages from a `@Sendable` closure.
final class ProgressLog: Sendable {
    private let storage = Mutex<[String]>([])

    /// The messages in the order they were received.
    var messages: [String] { storage.withLock { $0 } }

    /// Records a message.
    func append(_ message: String) { storage.withLock { $0.append(message) } }
}

@Suite("Progress bar")
struct ProgressBarTests {
    @Test("A report with a total fills the bar in proportion and shows the counts")
    func rendersTotal() {
        let half = GenerationProgressBar.render(
            GenerationProgressUpdate(message: "Generated A.java", completed: 1, total: 2))
        let full = GenerationProgressBar.render(
            GenerationProgressUpdate(message: "Done", completed: 2, total: 2))

        #expect(half == "[" + String(repeating: "=", count: 12) + String(repeating: " ", count: 12) + "] 1/2 Generated A.java")
        #expect(full == "[" + String(repeating: "=", count: 24) + "] 2/2 Done")
    }

    @Test("A report without a total shows the number of finished files")
    func rendersWithoutTotal() {
        let text = GenerationProgressBar.render(GenerationProgressUpdate(message: "Working", completed: 3))

        #expect(text == "Working (3 files)")
    }

    @Test("The reporter is a closure that shows reports")
    func reporterIsUsable() {
        let bar = GenerationProgressBar(verbose: false)
        bar.reporter(GenerationProgressUpdate(message: "quiet", completed: 0, total: 1))
        bar.finish()

        #expect(!bar.verbose)
    }
}
