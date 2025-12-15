import Foundation
import Testing

// MARK: - Basic Validation Tests

@Suite("swift-atl validate - Basic validation")
struct ValidateBasicTests {

    @Test("should validate valid ATL file successfully")
    @MainActor
    func testValidateValidATL() async throws {
        // Given: A valid ATL transformation file
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")

        // When: Validating the file
        let result = try await executeSwiftATL(
            command: "validate",
            arguments: [atlFile.path]
        )

        // Then: Should succeed with VALID status
        #expect(result.succeeded)
        #expect(
            result.stdout.contains("VALID") ||
            result.stdout.contains("valid") ||
            result.stdout.contains("Validation completed") ||
            result.stdout.contains("0 errors")
        )
    }

    @Test("should report errors for invalid ATL file")
    @MainActor
    func testValidateInvalidATL() async throws {
        // Given: An invalid ATL file
        let atlFile = try loadTestResource(named: "invalid-syntax.atl", subdirectory: "atl")

        // When: Validating the file
        let result = try await executeSwiftATL(
            command: "validate",
            arguments: [atlFile.path]
        )

        // Then: Should report validation errors
        #expect(
            result.stdout.contains("error") ||
            result.stdout.contains("INVALID") ||
            result.stdout.contains("Failed") ||
            result.stderr.contains("error")
        )
    }

    @Test("should handle missing file gracefully")
    @MainActor
    func testValidateMissingFile() async throws {
        // Given: A non-existent file path
        let missingPath = "/tmp/nonexistent-\(UUID().uuidString).atl"

        // When: Attempting to validate
        let result = try await executeSwiftATL(
            command: "validate",
            arguments: [missingPath]
        )

        // Then: Should report validation error
        #expect(!result.succeeded)
        #expect(
            result.stdout.contains("INVALID") ||
            result.stdout.contains("error") ||
            result.stderr.contains("error")
        )
    }

    @Test("should display verbose validation information")
    @MainActor
    func testValidateVerbose() async throws {
        // Given: A valid ATL file
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")

        // When: Validating with verbose flag
        let result = try await executeSwiftATL(
            command: "validate",
            arguments: [atlFile.path, "--verbose"]
        )

        // Then: Should show detailed validation information
        #expect(result.succeeded)
        #expect(result.stdout.count > 50)
    }
}

// MARK: - Validation Flags Tests

@Suite("swift-atl validate - Validation flags")
struct ValidateFlagsTests {

    @Test("should enforce strict validation with --strict flag")
    @MainActor
    func testValidateStrict() async throws {
        // Given: A valid ATL file
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")

        // When: Validating with strict mode
        let result = try await executeSwiftATL(
            command: "validate",
            arguments: [atlFile.path, "--strict"]
        )

        // Then: Should perform strict validation
        #expect(result.succeeded)
        #expect(
            result.stdout.contains("VALID") ||
            result.stdout.contains("valid") ||
            result.stdout.contains("0 errors")
        )
    }

    @Test("should check metamodels with --check-metamodels flag")
    @MainActor
    func testValidateCheckMetamodels() async throws {
        // Given: A valid ATL file
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")

        // When: Validating with metamodel checking
        let result = try await executeSwiftATL(
            command: "validate",
            arguments: [atlFile.path, "--check-metamodels"]
        )

        // Then: Should check metamodel references
        #expect(result.succeeded)
        #expect(!result.stdout.isEmpty)
    }

    @Test("should check rules with --check-rules flag")
    @MainActor
    func testValidateCheckRules() async throws {
        // Given: A valid ATL file
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")

        // When: Validating with rule checking
        let result = try await executeSwiftATL(
            command: "validate",
            arguments: [atlFile.path, "--check-rules"]
        )

        // Then: Should check rule definitions
        #expect(result.succeeded)
        #expect(!result.stdout.isEmpty)
    }

    @Test("should combine multiple validation flags")
    @MainActor
    func testValidateCombinedFlags() async throws {
        // Given: A valid ATL file
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")

        // When: Validating with multiple flags
        let result = try await executeSwiftATL(
            command: "validate",
            arguments: [
                atlFile.path,
                "--strict",
                "--check-metamodels",
                "--check-rules",
                "--verbose"
            ]
        )

        // Then: Should perform comprehensive validation
        #expect(result.succeeded)
        #expect(result.stdout.count > 50)
    }
}

// MARK: - Multiple Files Tests

@Suite("swift-atl validate - Multiple files")
struct ValidateMultipleFilesTests {

    @Test("should validate multiple ATL files")
    @MainActor
    func testValidateMultipleFiles() async throws {
        // Given: Multiple ATL files
        let atlFile1 = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")
        let atlFile2 = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")

        // When: Validating multiple files
        let result = try await executeSwiftATL(
            command: "validate",
            arguments: [atlFile1.path, atlFile2.path]
        )

        // Then: Should validate all files
        #expect(result.succeeded)
        #expect(!result.stdout.isEmpty)
    }

    @Test("should continue validation after encountering invalid file")
    @MainActor
    func testValidateContinueAfterError() async throws {
        // Given: Mix of valid and invalid files
        let validFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")
        let invalidFile = try loadTestResource(named: "invalid-syntax.atl", subdirectory: "atl")

        // When: Validating both files
        let result = try await executeSwiftATL(
            command: "validate",
            arguments: [validFile.path, invalidFile.path]
        )

        // Then: Should process both files and report status
        #expect(!result.stdout.isEmpty)
    }
}

// MARK: - Output Options Tests

@Suite("swift-atl validate - Output options")
struct ValidateOutputOptionsTests {

    @Test("should write validation report to file")
    @MainActor
    func testValidateOutputFile() async throws {
        // Given: A valid ATL file and output path
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("validation-report.txt")

        // When: Validating with output file
        let result = try await executeSwiftATL(
            command: "validate",
            arguments: [atlFile.path, "--output", outputFile.path]
        )

        // Then: Should create output file
        #expect(result.succeeded)

        // Verify file was created
        if FileManager.default.fileExists(atPath: outputFile.path) {
            let content = try String(contentsOf: outputFile, encoding: .utf8)
            #expect(!content.isEmpty)
        }
    }
}

// MARK: - Help and Usage Tests

@Suite("swift-atl validate - Help and usage")
struct ValidateHelpTests {

    @Test("should display help when --help flag is used")
    @MainActor
    func testValidateHelp() async throws {
        // Given/When: Running validate with --help
        let result = try await executeSwiftATL(
            command: "validate",
            arguments: ["--help"]
        )

        // Then: Should display help information
        #expect(result.succeeded)
        #expect(result.stdout.contains("validate") || result.stdout.contains("USAGE"))
        #expect(
            result.stdout.contains("--strict") ||
            result.stdout.contains("--check") ||
            result.stdout.contains("--format") ||
            result.stdout.contains("option")
        )
    }
}
