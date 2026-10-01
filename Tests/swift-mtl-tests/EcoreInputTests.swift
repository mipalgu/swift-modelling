import Foundation
import Testing

/// Tests for supplying Ecore metamodels to `swift-mtl generate`, either as input
/// models (`--model X.ecore`) or purely for registration (`--metamodel X.ecore`).
@Suite("Ecore input tests")
struct EcoreInputTests {
    /// Runs `swift-mtl generate` for a template and the given extra arguments.
    ///
    /// - Parameters:
    ///   - template: The template resource name in `Resources/templates`.
    ///   - arguments: The arguments following the template path, excluding `--output`.
    ///   - output: The name of the file the template writes in the output directory.
    /// - Returns: The subprocess result and the generated file contents, if any.
    @MainActor
    private func generate(
        template: String,
        arguments: [String],
        output: String
    ) async throws -> (result: SubprocessResult, content: String?) {
        let templateURL = try loadTestResource(named: template, subdirectory: "templates")
        let outputDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(outputDir) }

        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [templateURL.path] + arguments + ["--output", outputDir.path]
        )
        let file = outputDir.appendingPathComponent(output)
        let content = try? String(contentsOf: file, encoding: .utf8)
        return (result, content)
    }

    private func modelPath(_ name: String) throws -> String {
        try loadTestResource(named: name, subdirectory: "models").path
    }

    @Test("--model with an ecore file passes the EPackage as template argument")
    @MainActor
    func ecoreModelPassesPackage() async throws {
        let (result, content) = try await generate(
            template: "ecore-package-arg.mtl",
            arguments: ["--model", try modelPath("company.ecore")],
            output: "arg.txt"
        )

        #expect(result.succeeded, "stderr: \(result.stderr)")
        #expect(content?.contains("Package argument received") == true)
    }

    @Test(
        "Template reads the name of an EPackage",
        .disabled("requires reflective Ecore metamodel objects")
    )
    @MainActor
    func ecoreModelPackageName() async throws {
        let (result, content) = try await generate(
            template: "ecore-package-name.mtl",
            arguments: ["--model", try modelPath("company.ecore")],
            output: "package.txt"
        )

        #expect(result.succeeded, "stderr: \(result.stderr)")
        #expect(content?.contains("Package: company") == true)
    }

    @Test(
        "Template navigates class names of an EPackage",
        .disabled("requires reflective Ecore metamodel objects")
    )
    @MainActor
    func ecoreModelNavigatesClasses() async throws {
        let (result, content) = try await generate(
            template: "ecore-package-classes.mtl",
            arguments: ["--model", try modelPath("company.ecore")],
            output: "classes.txt"
        )

        #expect(result.succeeded, "stderr: \(result.stderr)")
        #expect(content?.contains("Package: company") == true)
        #expect(content?.contains("Class: Company") == true)
        #expect(content?.contains("Class: Department") == true)
    }

    @Test("--metamodel registers without becoming a template argument")
    @MainActor
    func metamodelIsNotAnArgument() async throws {
        // with-model-param.mtl expects exactly one argument (the Company instance)
        let (result, _) = try await generate(
            template: "with-model-param.mtl",
            arguments: [
                "--metamodel", try modelPath("company.ecore"),
                "--model", try modelPath("simple-model.xmi"),
            ],
            output: "stdout"
        )

        #expect(result.succeeded, "stderr: \(result.stderr)")
    }

    @Test("--model with ecore plus instance model yields two arguments")
    @MainActor
    func ecoreModelCountsAsArgument() async throws {
        let (result, _) = try await generate(
            template: "with-model-param.mtl",
            arguments: [
                "--model", try modelPath("company.ecore"),
                "--model", try modelPath("simple-model.xmi"),
            ],
            output: "stdout"
        )

        #expect(!result.succeeded)
        #expect(result.stderr.contains("expects 1 arguments, got 2"))
    }

    @Test("--metamodel may be repeated")
    @MainActor
    func metamodelRepeatable() async throws {
        let (result, _) = try await generate(
            template: "with-model-param.mtl",
            arguments: [
                "--metamodel", try modelPath("company.ecore"),
                "--metamodel", try modelPath("company.ecore"),
                "--model", try modelPath("simple-model.xmi"),
            ],
            output: "stdout"
        )

        #expect(result.succeeded, "stderr: \(result.stderr)")
    }

    @Test("Argument order follows the command line: package first")
    @MainActor
    func packageThenInstance() async throws {
        let (result, content) = try await generate(
            template: "package-then-company.mtl",
            arguments: [
                "--model", try modelPath("company.ecore"),
                "--model", try modelPath("simple-model.xmi"),
            ],
            output: "order.txt"
        )

        #expect(result.succeeded, "stderr: \(result.stderr)")
        #expect(content?.contains("Company: Tech Innovations Ltd") == true)
    }

    @Test("Argument order follows the command line: instance first")
    @MainActor
    func instanceThenPackage() async throws {
        let (result, content) = try await generate(
            template: "company-then-package.mtl",
            arguments: [
                "--model", try modelPath("simple-model.xmi"),
                "--model", try modelPath("company.ecore"),
            ],
            output: "order.txt"
        )

        #expect(result.succeeded, "stderr: \(result.stderr)")
        #expect(content?.contains("Company: Tech Innovations Ltd") == true)
    }

    @Test("Verbose output distinguishes metamodel and input model roles")
    @MainActor
    func verboseRoles() async throws {
        let (result, _) = try await generate(
            template: "ecore-package-arg.mtl",
            arguments: [
                "--metamodel", try modelPath("company.ecore"),
                "--model", try modelPath("company.ecore"),
                "--verbose",
            ],
            output: "arg.txt"
        )

        #expect(result.succeeded, "stderr: \(result.stderr)")
        #expect(result.stdout.contains("Loading metamodel (registered only):"))
        #expect(result.stdout.contains("Loading metamodel (registered and used as input model):"))
        #expect(result.stdout.contains("Metamodels: "))
        #expect(result.stdout.contains("Input Models: "))
    }

    @Test("Generate help documents --metamodel")
    @MainActor
    func helpMentionsMetamodel() async throws {
        let result = try await executeSwiftMTL(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("--metamodel"))
    }

    @Test("Missing --metamodel file is reported")
    @MainActor
    func missingMetamodel() async throws {
        let (result, _) = try await generate(
            template: "simple-hello.mtl",
            arguments: ["--metamodel", "/nonexistent/none.ecore"],
            output: "stdout"
        )

        #expect(!result.succeeded)
        #expect(result.stderr.contains("File not found"))
    }
}
