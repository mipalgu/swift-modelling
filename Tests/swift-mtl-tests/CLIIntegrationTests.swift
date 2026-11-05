//
//  CLIIntegrationTests.swift
//  MTL
//
//  Created by Rene Hexel on 28/12/2025.
//  Copyright (c) 2025 Rene Hexel. All rights reserved.
//

import Foundation
import Testing

@Suite("CLI Integration Tests")
struct CLIIntegrationTests {

    // MARK: - Generate Command Tests

    @Test("Generate command - simple template")
    @MainActor
    func testGenerateSimpleTemplate() async throws {
        // Given
        let templateURL = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")
        let outputDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(outputDir) }

        // When
        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                templateURL.path,
                "--output", outputDir.path
            ]
        )

        // Then
        #expect(result.succeeded)
        #expect(result.stdout.contains("Generation complete"))

        // Verify stdout was created
        let stdoutFile = outputDir.appendingPathComponent("stdout")
        #expect(FileManager.default.fileExists(atPath: stdoutFile.path))

        let content = try String(contentsOf: stdoutFile, encoding: .utf8)
        #expect(content.contains("Hello, World!"))
        #expect(content.contains("This is a simple MTL template."))
    }

    @Test("Generate command - template with expressions")
    @MainActor
    func testGenerateTemplateWithExpressions() async throws {
        // Given
        let templateURL = try loadTestResource(named: "with-expressions.mtl", subdirectory: "templates")
        let outputDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(outputDir) }

        // When
        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                templateURL.path,
                "--output", outputDir.path
            ]
        )

        // Then
        #expect(result.succeeded)

        let stdoutFile = outputDir.appendingPathComponent("stdout")
        let content = try String(contentsOf: stdoutFile, encoding: .utf8)
        #expect(content.contains("Version: 1.0.0"))
        #expect(content.contains("Numbers: 6"))
    }

    @Test("Generate command - template with control flow")
    @MainActor
    func testGenerateTemplateWithControlFlow() async throws {
        // Given
        let templateURL = try loadTestResource(named: "with-control-flow.mtl", subdirectory: "templates")
        let outputDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(outputDir) }

        // When
        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                templateURL.path,
                "--output", outputDir.path
            ]
        )

        // Then
        #expect(result.succeeded)

        let stdoutFile = outputDir.appendingPathComponent("stdout")
        let content = try String(contentsOf: stdoutFile, encoding: .utf8)
        #expect(content.contains("Condition is true"))
        #expect(!content.contains("Condition is false"))
        #expect(content.contains("Items: 1, 2, 3"))
        #expect(content.contains("Message: Hello"))
    }

    @Test("Generate command - template with file blocks")
    @MainActor
    func testGenerateTemplateWithFileBlocks() async throws {
        // Given
        let templateURL = try loadTestResource(named: "with-file-blocks.mtl", subdirectory: "templates")
        let outputDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(outputDir) }

        // When
        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                templateURL.path,
                "--output", outputDir.path
            ]
        )

        // Then
        #expect(result.succeeded)

        // Verify files were created
        let output1 = outputDir.appendingPathComponent("output1.txt")
        let output2 = outputDir.appendingPathComponent("output2.txt")

        #expect(FileManager.default.fileExists(atPath: output1.path))
        #expect(FileManager.default.fileExists(atPath: output2.path))

        let content1 = try String(contentsOf: output1, encoding: .utf8)
        let content2 = try String(contentsOf: output2, encoding: .utf8)

        #expect(content1.contains("File 1 content"))
        #expect(content2.contains("File 2 content"))

        // Only line breaks lie outside the file blocks, so no stdout file is written
        let stdoutFile = outputDir.appendingPathComponent("stdout")
        #expect(!FileManager.default.fileExists(atPath: stdoutFile.path))
    }

    @Test("Generate command - keeps a stdout file that a file block wrote")
    @MainActor
    func testGenerateKeepsStdoutFileBlock() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let templateURL = scratch.appendingPathComponent("stdout-block.mtl")
        try """
            [module StdoutBlock('http://www.example.org/stdout')]

            [template public main()]
            [file ('stdout', 'overwrite', 'UTF-8')]real[/file]
            [/template]
            """.write(to: templateURL, atomically: true, encoding: .utf8)
        let outputDir = scratch.appendingPathComponent("out")

        let result = try await executeSwiftMTL(
            command: "generate", arguments: [templateURL.path, "--output", outputDir.path])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let content = try String(contentsOf: outputDir.appendingPathComponent("stdout"), encoding: .utf8)
        #expect(content == "real")
    }

    @Test("Generate command - prints the text outside file blocks with --print-standard-output")
    @MainActor
    func testGeneratePrintsStandardOutput() async throws {
        let templateURL = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")
        let outputDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(outputDir) }

        let result = try await executeSwiftMTL(
            command: "generate", arguments: [templateURL.path, "--output", outputDir.path, "--print-standard-output"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout == "Hello, World!\nThis is a simple MTL template.\n✓ Generation complete\n")
        #expect(!FileManager.default.fileExists(atPath: outputDir.appendingPathComponent("stdout").path))
    }

    @Test("Generate command - prints nothing but writes the files of a template with file blocks")
    @MainActor
    func testGeneratePrintsNothingForFileBlocks() async throws {
        let templateURL = try loadTestResource(named: "with-file-blocks.mtl", subdirectory: "templates")
        let outputDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(outputDir) }

        let result = try await executeSwiftMTL(
            command: "generate", arguments: [templateURL.path, "--output", outputDir.path, "--print-standard-output"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout == "✓ Generation complete\n")
        #expect(FileManager.default.fileExists(atPath: outputDir.appendingPathComponent("output1.txt").path))
        #expect(FileManager.default.fileExists(atPath: outputDir.appendingPathComponent("output2.txt").path))
        #expect(!FileManager.default.fileExists(atPath: outputDir.appendingPathComponent("stdout").path))
    }

    @Test("Generate command - rejects a single value passed to concat only with --strict-aql")
    @MainActor
    func testGenerateStrictAQL() async throws {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let templateURL = scratch.appendingPathComponent("concat.mtl")
        try """
            [module Concat('http://www.example.org/concat')]

            [template public main()]
            [file ('count.txt', 'overwrite', 'UTF-8')][Sequence{'a'}->concat('b')->size()/][/file]
            [/template]
            """.write(to: templateURL, atomically: true, encoding: .utf8)
        let lenientDir = scratch.appendingPathComponent("lenient")
        let strictDir = scratch.appendingPathComponent("strict")

        let lenient = try await executeSwiftMTL(
            command: "generate", arguments: [templateURL.path, "--output", lenientDir.path, "--no-config"])
        let strict = try await executeSwiftMTL(
            command: "generate", arguments: [templateURL.path, "--output", strictDir.path, "--no-config", "--strict-aql"])

        #expect(lenient.succeeded, "\(lenient.stdout)\(lenient.stderr)")
        #expect(try String(contentsOf: lenientDir.appendingPathComponent("count.txt"), encoding: .utf8) == "2")
        #expect(!strict.succeeded, "\(strict.stdout)")
        #expect(strict.stderr.contains("concat"), "\(strict.stderr)")
    }

    @Test("Generate command - describes --print-standard-output in the help")
    @MainActor
    func testGenerateHelpDescribesPrintStandardOutput() async throws {
        let result = try await executeSwiftMTL(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("--print-standard-output"))
    }

    @Test("Generate command - replaces a stdout file left by an earlier run with new text")
    @MainActor
    func testGenerateReplacesEarlierStdout() async throws {
        let templateURL = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")
        let outputDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(outputDir) }
        let stdoutFile = outputDir.appendingPathComponent("stdout")
        try "earlier".write(to: stdoutFile, atomically: true, encoding: .utf8)

        let result = try await executeSwiftMTL(
            command: "generate", arguments: [templateURL.path, "--output", outputDir.path])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let content = try String(contentsOf: stdoutFile, encoding: .utf8)
        #expect(content.contains("Hello, World!"))
        #expect(!content.contains("earlier"))
    }

    @Test("Generate command - verbose output")
    @MainActor
    func testGenerateVerboseOutput() async throws {
        // Given
        let templateURL = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")
        let outputDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(outputDir) }

        // When
        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                templateURL.path,
                "--output", outputDir.path,
                "--verbose"
            ]
        )

        // Then
        #expect(result.succeeded)
        #expect(result.stdout.contains("Parsing MTL Template"))
        #expect(result.stdout.contains("Executing Generation"))
        #expect(result.stdout.contains("Generation Complete"))
        #expect(result.stdout.contains("Templates executed:"))
        #expect(result.stdout.contains("Execution time:"))
    }

    @Test("Generate command - file not found error")
    @MainActor
    func testGenerateFileNotFound() async throws {
        // When
        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: ["/nonexistent/template.mtl"]
        )

        // Then
        #expect(!result.succeeded)
        #expect(result.stderr.contains("File not found") || result.exitCode != 0)
    }

    @Test("Generate command - invalid template syntax")
    @MainActor
    func testGenerateInvalidSyntax() async throws {
        // Given
        let templateURL = try loadTestResource(named: "invalid-syntax.mtl", subdirectory: "templates")
        let outputDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(outputDir) }

        // When
        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                templateURL.path,
                "--output", outputDir.path
            ]
        )

        // Then
        #expect(!result.succeeded)
    }

    // MARK: - Parse Command Tests

    @Test("Parse command - simple template")
    @MainActor
    func testParseSimpleTemplate() async throws {
        // Given
        let templateURL = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")

        // When
        let result = try await executeSwiftMTL(
            command: "parse",
            arguments: [templateURL.path]
        )

        // Then
        #expect(result.succeeded)
        #expect(result.stdout.contains("Module: SimpleHello"))
        #expect(result.stdout.contains("Templates (1)"))
    }

    @Test("Parse command - template with expressions")
    @MainActor
    func testParseTemplateWithExpressions() async throws {
        // Given
        let templateURL = try loadTestResource(named: "with-expressions.mtl", subdirectory: "templates")

        // When
        let result = try await executeSwiftMTL(
            command: "parse",
            arguments: [templateURL.path]
        )

        // Then
        #expect(result.succeeded)
        #expect(result.stdout.contains("Module: WithExpressions"))
        #expect(result.stdout.contains("Queries (1)"))
    }

    @Test("Parse command - detailed output")
    @MainActor
    func testParseDetailedOutput() async throws {
        // Given
        let templateURL = try loadTestResource(named: "with-control-flow.mtl", subdirectory: "templates")

        // When
        let result = try await executeSwiftMTL(
            command: "parse",
            arguments: [
                templateURL.path,
                "--detailed"
            ]
        )

        // Then
        #expect(result.succeeded)
        #expect(result.stdout.contains("Module: WithControlFlow"))
        #expect(result.stdout.contains("Templates (1)"))
        #expect(result.stdout.contains("main"))
    }

    @Test("Parse command - JSON output")
    @MainActor
    func testParseJSONOutput() async throws {
        // Given
        let templateURL = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")

        // When
        let result = try await executeSwiftMTL(
            command: "parse",
            arguments: [
                templateURL.path,
                "--json"
            ]
        )

        // Then
        #expect(result.succeeded)
        #expect(result.stdout.contains("\"module\""))
        #expect(result.stdout.contains("\"templates\""))
        #expect(result.stdout.contains("SimpleHello"))
    }

    @Test("Parse command - invalid syntax")
    @MainActor
    func testParseInvalidSyntax() async throws {
        // Given
        let templateURL = try loadTestResource(named: "invalid-syntax.mtl", subdirectory: "templates")

        // When
        let result = try await executeSwiftMTL(
            command: "parse",
            arguments: [templateURL.path]
        )

        // Then
        // Parse command doesn't fail, it just prints error message
        #expect(result.stdout.contains("Error parsing"))
    }

    @Test("Parse command - multiple templates")
    @MainActor
    func testParseMultipleTemplates() async throws {
        // Given
        let template1 = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")
        let template2 = try loadTestResource(named: "with-expressions.mtl", subdirectory: "templates")

        // When
        let result = try await executeSwiftMTL(
            command: "parse",
            arguments: [
                template1.path,
                template2.path
            ]
        )

        // Then
        #expect(result.succeeded)
        #expect(result.stdout.contains("SimpleHello"))
        #expect(result.stdout.contains("WithExpressions"))
    }

    // MARK: - Validate Command Tests

    @Test("Validate command - valid template")
    @MainActor
    func testValidateValidTemplate() async throws {
        // Given
        let templateURL = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")

        // When
        let result = try await executeSwiftMTL(
            command: "validate",
            arguments: [templateURL.path]
        )

        // Then
        #expect(result.succeeded)
        #expect(result.stdout.contains("Valid"))
        #expect(result.stdout.contains(templateURL.lastPathComponent))
    }

    @Test("Validate command - verbose output")
    @MainActor
    func testValidateVerboseOutput() async throws {
        // Given
        let templateURL = try loadTestResource(named: "with-expressions.mtl", subdirectory: "templates")

        // When
        let result = try await executeSwiftMTL(
            command: "validate",
            arguments: [
                templateURL.path,
                "--verbose"
            ]
        )

        // Then
        #expect(result.succeeded)
        #expect(result.stdout.contains("Valid"))
        #expect(result.stdout.contains("Module:"))
        #expect(result.stdout.contains("Templates:"))
    }

    @Test("Validate command - invalid template")
    @MainActor
    func testValidateInvalidTemplate() async throws {
        // Given
        let templateURL = try loadTestResource(named: "invalid-syntax.mtl", subdirectory: "templates")

        // When
        let result = try await executeSwiftMTL(
            command: "validate",
            arguments: [templateURL.path]
        )

        // Then
        #expect(!result.succeeded)
        #expect(result.stdout.contains(templateURL.lastPathComponent))
    }

    @Test("Validate command - multiple templates")
    @MainActor
    func testValidateMultipleTemplates() async throws {
        // Given
        let valid1 = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")
        let valid2 = try loadTestResource(named: "with-expressions.mtl", subdirectory: "templates")
        let invalid = try loadTestResource(named: "invalid-syntax.mtl", subdirectory: "templates")

        // When
        let result = try await executeSwiftMTL(
            command: "validate",
            arguments: [
                valid1.path,
                valid2.path,
                invalid.path
            ]
        )

        // Then
        #expect(!result.succeeded)
        #expect(result.stdout.contains("simple-hello.mtl"))
        #expect(result.stdout.contains("with-expressions.mtl"))
        #expect(result.stdout.contains("invalid-syntax.mtl"))
    }

    @Test("Validate command - file not found")
    @MainActor
    func testValidateFileNotFound() async throws {
        // When
        let result = try await executeSwiftMTL(
            command: "validate",
            arguments: ["/nonexistent/template.mtl"]
        )

        // Then
        #expect(!result.succeeded)
        #expect(result.stdout.contains("File not found"))
    }

    @Test("Validate command - all valid templates")
    @MainActor
    func testValidateAllValid() async throws {
        // Given
        let template1 = try loadTestResource(named: "simple-hello.mtl", subdirectory: "templates")
        let template2 = try loadTestResource(named: "with-expressions.mtl", subdirectory: "templates")
        let template3 = try loadTestResource(named: "with-control-flow.mtl", subdirectory: "templates")

        // When
        let result = try await executeSwiftMTL(
            command: "validate",
            arguments: [
                template1.path,
                template2.path,
                template3.path
            ]
        )

        // Then
        #expect(result.succeeded)
        #expect(result.stdout.contains("Valid") || !result.stdout.contains("Error"))
    }

    // MARK: - Model Parameter Tests

    @Test("Generate command - template with model parameter")
    @MainActor
    func testGenerateTemplateWithModelParam() async throws {
        // Given - a Company metamodel template and a Company instance model
        let templateURL = try loadTestResource(named: "with-model-param.mtl", subdirectory: "templates")
        let modelURL = try loadTestResource(named: "simple-model.xmi", subdirectory: "models")
        let outputDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(outputDir) }

        // When
        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                templateURL.path,
                "--model", modelURL.path,
                "--output", outputDir.path
            ]
        )

        // Then - generation should succeed with the model root passed as argument
        #expect(result.succeeded, "Expected generation to succeed, got stderr: \(result.stderr)")

        let stdoutFile = outputDir.appendingPathComponent("stdout")
        #expect(FileManager.default.fileExists(atPath: stdoutFile.path))

        let content = try String(contentsOf: stdoutFile, encoding: .utf8)
        #expect(content.contains("Company Report"))
        #expect(content.contains("Name:"))
    }

    @Test("Generate command - template with model parameter fails without model")
    @MainActor
    func testGenerateTemplateWithModelParamFailsWithoutModel() async throws {
        // Given
        let templateURL = try loadTestResource(named: "with-model-param.mtl", subdirectory: "templates")
        let outputDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(outputDir) }

        // When - no --model flag, so no root objects are passed as arguments
        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                templateURL.path,
                "--output", outputDir.path
            ]
        )

        // Then - should fail because template expects 1 argument but gets 0
        #expect(!result.succeeded)
        #expect(result.stderr.contains("expects 1 arguments, got 0") || result.stderr.contains("Generation failed"))
    }

    // MARK: - Help and Version Tests

    @Test("Help command")
    @MainActor
    func testHelpCommand() async throws {
        // When
        let result = try await executeSwiftMTL(
            command: "--help",
            arguments: []
        )

        // Then
        #expect(result.succeeded)
        #expect(result.stdout.contains("swift-mtl"))
        #expect(result.stdout.contains("USAGE:"))
        #expect(result.stdout.contains("generate"))
        #expect(result.stdout.contains("parse"))
        #expect(result.stdout.contains("validate"))
    }

    @Test("Version command")
    @MainActor
    func testVersionCommand() async throws {
        // When
        let result = try await executeSwiftMTL(
            command: "--version",
            arguments: []
        )

        // Then
        #expect(result.succeeded)
        #expect(result.stdout.contains("0.7.0"))
    }

    @Test("Generate help")
    @MainActor
    func testGenerateHelp() async throws {
        // When
        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: ["--help"]
        )

        // Then
        #expect(result.succeeded)
        #expect(result.stdout.contains("generate"))
        #expect(result.stdout.contains("--model"))
        #expect(result.stdout.contains("--output"))
        #expect(result.stdout.contains("--template"))
    }
}
