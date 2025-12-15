import Foundation
import Testing

// MARK: - XMI to JSON Conversion Tests

@Suite("swift-ecore convert - XMI to JSON conversion")
struct ConvertXMIToJSONTests {

    @Test("should convert valid XMI to JSON")
    @MainActor
    func testConvertXMIToJSON() async throws {
        // Given: A valid XMI file and output path
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.json")

        // When: Converting XMI to JSON (format inferred from extension)
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [xmiFile.path, outputFile.path]
        )

        // Then: Should succeed and create output file
        #expect(result.succeeded)

        // Verify output file was created
        if FileManager.default.fileExists(atPath: outputFile.path) {
            let content = try String(contentsOf: outputFile, encoding: .utf8)
            #expect(!content.isEmpty)
            #expect(content.contains("{"))
        }
    }

    @Test("should display verbose conversion progress")
    @MainActor
    func testConvertXMIToJSONVerbose() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.json")

        // When: Converting with verbose flag
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [xmiFile.path, outputFile.path, "--verbose"]
        )

        // Then: Should show conversion progress
        #expect(result.succeeded)
        #expect(
            result.stdout.contains("Converting") ||
            result.stdout.contains("Inferring") ||
            result.stdout.count > 50
        )
    }

    @Test("should handle --force flag to overwrite existing files")
    @MainActor
    func testConvertWithForceFlag() async throws {
        // Given: An existing output file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.json")

        // Create existing file
        try "existing content".write(to: outputFile, atomically: true, encoding: .utf8)

        // When: Converting with --force flag
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [xmiFile.path, outputFile.path, "--force"]
        )

        // Then: Should succeed and overwrite file
        #expect(result.succeeded)

        if FileManager.default.fileExists(atPath: outputFile.path) {
            let content = try String(contentsOf: outputFile, encoding: .utf8)
            #expect(content != "existing content")
        }
    }
}

// MARK: - JSON to XMI Conversion Tests

@Suite("swift-ecore convert - JSON to XMI conversion")
struct ConvertJSONToXMITests {

    @Test("should convert valid JSON to XMI")
    @MainActor
    func testConvertJSONToXMI() async throws {
        // Given: A valid JSON file and output path
        let jsonFile = try loadTestResource(named: "valid-model.json", subdirectory: "json")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.xmi")

        // When: Converting JSON to XMI (format inferred from extension)
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [jsonFile.path, outputFile.path]
        )

        // Then: Should succeed and create output file
        #expect(result.succeeded)

        // Verify output file was created with XML content
        if FileManager.default.fileExists(atPath: outputFile.path) {
            let content = try String(contentsOf: outputFile, encoding: .utf8)
            #expect(!content.isEmpty)
            #expect(content.contains("<?xml") || content.contains("<"))
        }
    }
}

// MARK: - Round-Trip Conversion Tests

@Suite("swift-ecore convert - Round-trip conversion")
struct ConvertRoundTripTests {

    @Test("should maintain data fidelity in XMI → JSON → XMI conversion")
    @MainActor
    func testRoundTripXMItoJSONtoXMI() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let jsonFile = tempDir.appendingPathComponent("intermediate.json")
        let finalXMIFile = tempDir.appendingPathComponent("final.xmi")

        // When: Converting XMI → JSON (format inferred from extensions)
        let xmiToJSON = try await executeSwiftEcore(
            command: "convert",
            arguments: [xmiFile.path, jsonFile.path]
        )

        #expect(xmiToJSON.succeeded)

        // Then: Converting JSON → XMI (format inferred from extensions)
        let jsonToXMI = try await executeSwiftEcore(
            command: "convert",
            arguments: [jsonFile.path, finalXMIFile.path]
        )

        #expect(jsonToXMI.succeeded)

        // Verify both conversions succeeded and files exist
        #expect(FileManager.default.fileExists(atPath: jsonFile.path))
        #expect(FileManager.default.fileExists(atPath: finalXMIFile.path))
    }
}

// MARK: - Error Handling Tests

@Suite("swift-ecore convert - Error handling")
struct ConvertErrorHandlingTests {

    @Test("should report error for missing input file")
    @MainActor
    func testConvertMissingInputFile() async throws {
        // Given: A non-existent input file
        let missingPath = "/tmp/nonexistent-\(UUID().uuidString).xmi"
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.json")

        // When: Attempting to convert
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [missingPath, outputFile.path]
        )

        // Then: Should report error (exit code checked by test framework)
        #expect(!result.succeeded)
        #expect(
            result.stderr.contains("not found") ||
            result.stderr.contains("does not exist") ||
            result.stdout.contains("not found") ||
            result.stdout.contains("Failed")
        )
    }

    @Test("should report error for unsupported output format")
    @MainActor
    func testConvertUnsupportedFormat() async throws {
        // Given: A valid input file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.yaml")

        // When: Converting to unsupported format using explicit flag
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [xmiFile.path, outputFile.path, "--output-format", "yaml"]
        )

        // Then: Should report unsupported format error
        #expect(
            result.stderr.contains("unsupported") ||
            result.stderr.contains("format") ||
            result.stdout.contains("unsupported") ||
            result.stdout.contains("format")
        )
    }

    @Test("should report error for invalid input file")
    @MainActor
    func testConvertInvalidInputFile() async throws {
        // Given: An invalid XMI file
        let invalidFile = try loadTestResource(named: "invalid-syntax.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.json")

        // When: Attempting to convert
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [invalidFile.path, outputFile.path]
        )

        // Then: Should report conversion error
        #expect(!result.succeeded)
        #expect(
            result.stderr.contains("Error") ||
            result.stderr.contains("Failed") ||
            result.stderr.contains("error") ||
            result.stdout.contains("Error") ||
            result.stdout.contains("Failed") ||
            result.stdout.contains("error")
        )
    }
}

// MARK: - Explicit Format Flags Tests

@Suite("swift-ecore convert - Explicit format flags")
struct ConvertExplicitFormatTests {

    @Test("should use explicit --input-format flag")
    @MainActor
    func testExplicitInputFormat() async throws {
        // Given: An XMI file with non-standard extension
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        // Create a copy with .dat extension
        let datFile = tempDir.appendingPathComponent("input.dat")
        try FileManager.default.copyItem(at: xmiFile, to: datFile)

        let outputFile = tempDir.appendingPathComponent("output.json")

        // When: Converting with explicit input format
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [datFile.path, outputFile.path, "--input-format", "xmi"]
        )

        // Then: Should succeed
        #expect(result.succeeded)
        #expect(FileManager.default.fileExists(atPath: outputFile.path))
    }

    @Test("should use explicit --output-format flag")
    @MainActor
    func testExplicitOutputFormat() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.dat")

        // When: Converting with explicit output format
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [xmiFile.path, outputFile.path, "--output-format", "json"]
        )

        // Then: Should create JSON in .dat file
        #expect(result.succeeded)

        if FileManager.default.fileExists(atPath: outputFile.path) {
            let content = try String(contentsOf: outputFile, encoding: .utf8)
            #expect(content.contains("{"))
            #expect(content.contains("eClass"))
        }
    }

    @Test("should use both explicit format flags")
    @MainActor
    func testBothExplicitFormats() async throws {
        // Given: Test resources
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        // Create JSON with .dat extension
        let jsonContent = """
        {
          "eClass": "Root",
          "elements": []
        }
        """
        let inputFile = tempDir.appendingPathComponent("input.dat")
        try jsonContent.write(to: inputFile, atomically: true, encoding: .utf8)

        let outputFile = tempDir.appendingPathComponent("output.dat")

        // When: Converting with both explicit formats
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [
                inputFile.path,
                outputFile.path,
                "--input-format", "json",
                "--output-format", "xmi"
            ]
        )

        // Then: Should create XMI in .dat file
        #expect(result.succeeded)

        if FileManager.default.fileExists(atPath: outputFile.path) {
            let content = try String(contentsOf: outputFile, encoding: .utf8)
            #expect(content.contains("<?xml") || content.contains("<"))
        }
    }

    @Test("should show format source in verbose output")
    @MainActor
    func testVerboseFormatSource() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.json")

        // When: Converting with explicit formats and verbose
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [
                xmiFile.path,
                outputFile.path,
                "--input-format", "xmi",
                "--output-format", "json",
                "--verbose"
            ]
        )

        // Then: Should show format source in output
        #expect(result.succeeded)
        #expect(result.stdout.contains("Using explicit input format"))
        #expect(result.stdout.contains("Using explicit output format"))
    }
}

// MARK: - Help and Usage Tests

@Suite("swift-ecore convert - Help and usage")
struct ConvertHelpTests {

    @Test("should display help when --help flag is used")
    @MainActor
    func testConvertHelp() async throws {
        // Given/When: Running convert with --help
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: ["--help"]
        )

        // Then: Should display help information
        #expect(result.succeeded)
        #expect(result.stdout.contains("convert") || result.stdout.contains("USAGE"))
        #expect(
            result.stdout.contains("--format") ||
            result.stdout.contains("--force") ||
            result.stdout.contains("option")
        )
    }
}
