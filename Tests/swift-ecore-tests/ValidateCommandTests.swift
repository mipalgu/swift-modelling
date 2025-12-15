import Foundation
import Testing

// MARK: - XMI Validation Tests

@Suite("swift-ecore validate - XMI validation")
struct ValidateXMITests {

    @Test("should validate valid XMI file successfully")
    @MainActor
    func testValidateValidXMI() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")

        // When: Validating the file
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [xmiFile.path]
        )

        // Then: Should succeed with confirmation message
        #expect(result.succeeded)
        #expect(result.stdout.contains("Validation") || result.stdout.contains("Valid"))
    }

    @Test("should report error for invalid XMI syntax")
    @MainActor
    func testValidateInvalidXMLSyntax() async throws {
        // Given: An XMI file with syntax errors
        let xmiFile = try loadTestResource(named: "invalid-syntax.xmi", subdirectory: "xmi")

        // When: Attempting to validate
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [xmiFile.path]
        )

        // Then: Should fail with parsing error
        #expect(!result.succeeded)
        #expect(result.exitCode == 1)
        #expect(!result.stderr.isEmpty || result.stdout.contains("error") || result.stdout.contains("Failed"))
    }

    @Test("should report error for missing file")
    @MainActor
    func testValidateMissingFile() async throws {
        // Given: A non-existent file path
        let missingPath = "/tmp/nonexistent-model-\(UUID().uuidString).xmi"

        // When: Attempting to validate
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [missingPath]
        )

        // Then: Should fail with file not found error
        #expect(!result.succeeded)
        #expect(
            result.stderr.contains("not found") ||
            result.stderr.contains("does not exist") ||
            result.stdout.contains("not found") ||
            result.stdout.contains("does not exist")
        )
    }

    @Test("should display verbose output when --verbose flag is used")
    @MainActor
    func testValidateVerboseOutput() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")

        // When: Validating with verbose flag
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [xmiFile.path, "--verbose"]
        )

        // Then: Should show detailed progress
        #expect(result.succeeded)
        // Verbose output should be longer than non-verbose
        #expect(result.stdout.count > 50)
    }
}

// MARK: - JSON Validation Tests

@Suite("swift-ecore validate - JSON validation")
struct ValidateJSONTests {

    @Test("should validate valid JSON file successfully")
    @MainActor
    func testValidateValidJSON() async throws {
        // Given: A valid JSON model file
        let jsonFile = try loadTestResource(named: "valid-model.json", subdirectory: "json")

        // When: Validating the file
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [jsonFile.path]
        )

        // Then: Should succeed
        #expect(result.succeeded)
        #expect(result.stdout.contains("Validation") || result.stdout.contains("Valid"))
    }

    @Test("should report error for invalid JSON format")
    @MainActor
    func testValidateInvalidJSON() async throws {
        // Given: A JSON file with format errors
        let jsonFile = try loadTestResource(named: "invalid-format.json", subdirectory: "json")

        // When: Attempting to validate
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [jsonFile.path]
        )

        // Then: Should fail with parsing error
        #expect(!result.succeeded)
        #expect(
            result.stderr.contains("JSON") ||
            result.stderr.contains("parse") ||
            result.stdout.contains("Failed") ||
            result.stdout.contains("error")
        )
    }
}

// MARK: - Unsupported Format Tests

@Suite("swift-ecore validate - Unsupported formats")
struct ValidateUnsupportedFormatTests {

    @Test("should reject unsupported file format")
    @MainActor
    func testValidateUnsupportedFormat() async throws {
        // Given: A file with unsupported extension
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let unsupportedFile = tempDir.appendingPathComponent("model.txt")
        try "Some content".write(to: unsupportedFile, atomically: true, encoding: .utf8)

        // When: Attempting to validate
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [unsupportedFile.path]
        )

        // Then: Should fail with unsupported format error
        #expect(!result.succeeded)
        #expect(
            result.stderr.contains("Unsupported") ||
            result.stderr.contains("format") ||
            result.stdout.contains("Unsupported") ||
            result.stdout.contains("not supported")
        )
    }
}

// MARK: - Help and Usage Tests

@Suite("swift-ecore validate - Help and usage")
struct ValidateHelpTests {

    @Test("should display help when --help flag is used")
    @MainActor
    func testValidateHelp() async throws {
        // Given/When: Running validate with --help
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: ["--help"]
        )

        // Then: Should display help information
        #expect(result.succeeded)
        #expect(result.stdout.contains("validate") || result.stdout.contains("USAGE"))
        #expect(result.stdout.contains("--verbose") || result.stdout.contains("option"))
    }
}
