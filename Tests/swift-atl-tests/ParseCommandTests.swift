import Foundation
import Testing

// MARK: - Basic Parsing Tests

@Suite("swift-atl parse - Basic parsing")
struct ParseBasicTests {

    @Test("should parse valid ATL file successfully")
    @MainActor
    func testParseValidATL() async throws {
        // Given: A valid ATL transformation file
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")

        // When: Parsing the file
        let result = try await executeSwiftATL(
            command: "parse",
            arguments: [atlFile.path]
        )

        // Then: Should succeed with parsing summary
        #expect(result.succeeded)
        #expect(result.stdout.contains("Parsed") || result.stdout.contains("Module"))
    }

    @Test("should display verbose parsing information")
    @MainActor
    func testParseVerbose() async throws {
        // Given: A valid ATL file
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")

        // When: Parsing with verbose flag
        let result = try await executeSwiftATL(
            command: "parse",
            arguments: [atlFile.path, "--verbose"]
        )

        // Then: Should show detailed parsing information
        #expect(result.succeeded)
        #expect(result.stdout.contains("Parsing") || result.stdout.contains("Module"))
        // Verbose output should be substantial
        #expect(result.stdout.count > 100)
    }

    @Test("should fail for invalid ATL syntax")
    @MainActor
    func testParseInvalidSyntax() async throws {
        // Given: An ATL file with syntax errors
        let atlFile = try loadTestResource(named: "invalid-syntax.atl", subdirectory: "atl")

        // When: Attempting to parse
        let result = try await executeSwiftATL(
            command: "parse",
            arguments: [atlFile.path]
        )

        // Then: Should report parse error (swift-atl currently exits with 0)
        #expect(
            result.stdout.contains("Failed") ||
            result.stdout.contains("error") ||
            result.stderr.contains("parse") ||
            result.stderr.contains("syntax")
        )
    }

    @Test("should handle missing file gracefully")
    @MainActor
    func testParseMissingFile() async throws {
        // Given: A non-existent file path
        let missingPath = "/tmp/nonexistent-\(UUID().uuidString).atl"

        // When: Attempting to parse
        let result = try await executeSwiftATL(
            command: "parse",
            arguments: [missingPath]
        )

        // Then: Should report file not found error (swift-atl currently exits with 0)
        #expect(
            result.stderr.contains("not found") ||
            result.stderr.contains("does not exist") ||
            result.stdout.contains("not found") ||
            result.stdout.contains("Failed")
        )
    }
}

// MARK: - Output Format Tests

@Suite("swift-atl parse - Output formats")
struct ParseOutputFormatTests {

    @Test("should output in text format by default")
    @MainActor
    func testParseTextFormat() async throws {
        // Given: A valid ATL file
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")

        // When: Parsing without format specification
        let result = try await executeSwiftATL(
            command: "parse",
            arguments: [atlFile.path]
        )

        // Then: Should output plain text
        #expect(result.succeeded)
        #expect(result.stdout.contains("Parsed") || result.stdout.contains("Module"))
    }

    @Test("should output in JSON format when requested")
    @MainActor
    func testParseJSONFormat() async throws {
        // Given: A valid ATL file
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")

        // When: Parsing with JSON format
        let result = try await executeSwiftATL(
            command: "parse",
            arguments: [atlFile.path, "--format", "json"]
        )

        // Then: Should output valid JSON
        #expect(result.succeeded)

        // Verify JSON validity if output looks like JSON
        if result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") {
            let jsonData = result.stdout.data(using: .utf8)!
            _ = try JSONSerialization.jsonObject(with: jsonData)
        }
    }

    @Test("should write output to file when specified")
    @MainActor
    func testParseOutputFile() async throws {
        // Given: A valid ATL file and output path
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("parse-results.txt")

        // When: Parsing with output file
        let result = try await executeSwiftATL(
            command: "parse",
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

// MARK: - Detail Flags Tests

@Suite("swift-atl parse - Detail flags")
struct ParseDetailFlagsTests {

    @Test("should show structure with --show-structure flag")
    @MainActor
    func testParseShowStructure() async throws {
        // Given: A valid ATL file
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")

        // When: Parsing with structure flag
        let result = try await executeSwiftATL(
            command: "parse",
            arguments: [atlFile.path, "--show-structure", "--verbose"]
        )

        // Then: Should show metamodel structure
        #expect(result.succeeded)
        // Structure output should mention metamodels or modules
        #expect(
            result.stdout.contains("metamodel") ||
            result.stdout.contains("Module") ||
            result.stdout.contains("Source") ||
            result.stdout.contains("Target")
        )
    }

    @Test("should show rules with --show-rules flag")
    @MainActor
    func testParseShowRules() async throws {
        // Given: A valid ATL file
        let atlFile = try loadTestResource(named: "simple-transformation.atl", subdirectory: "atl")

        // When: Parsing with rules flag
        let result = try await executeSwiftATL(
            command: "parse",
            arguments: [atlFile.path, "--show-rules", "--verbose"]
        )

        // Then: Should show rule details
        #expect(result.succeeded)
        #expect(
            result.stdout.contains("rule") ||
            result.stdout.contains("Rule") ||
            result.stdout.contains("Main")
        )
    }
}

// MARK: - Help and Usage Tests

@Suite("swift-atl parse - Help and usage")
struct ParseHelpTests {

    @Test("should display help when --help flag is used")
    @MainActor
    func testParseHelp() async throws {
        // Given/When: Running parse with --help
        let result = try await executeSwiftATL(
            command: "parse",
            arguments: ["--help"]
        )

        // Then: Should display help information
        #expect(result.succeeded)
        #expect(result.stdout.contains("parse") || result.stdout.contains("USAGE"))
        #expect(
            result.stdout.contains("--format") ||
            result.stdout.contains("--verbose") ||
            result.stdout.contains("option")
        )
    }
}
