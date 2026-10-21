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

// MARK: - Metamodel Validation Tests

@Suite("swift-ecore validate - Metamodels")
struct ValidateMetamodelTests {
    /// The long name of the option that registers a metamodel.
    static let option = "--metamodel"

    /// The short name of the option that registers a metamodel.
    static let shortOption = "-m"

    /// The namespace URI of the classifier metamodel.
    static let namespace = "http://example.org/classifiers"

    /// A package whose class gives its integer `rank` a value that is not a number.
    static let mistypedRank = """
        {
          "eClass": "http://example.org/classifiers#//Package",
          "name": "library",
          "classifiers": [
            { "eClass": "http://example.org/classifiers#//Class", "name": "Book", "rank": "many" }
          ]
        }
        """

    /// A root whose class the classifier metamodel does not define.
    static let undefinedClass = """
        { "eClass": "http://example.org/classifiers#//Widget", "name": "gadget" }
        """

    /// A package that conforms to the classifier metamodel.
    static let conforming = """
        {
          "eClass": "http://example.org/classifiers#//Package",
          "name": "library",
          "classifiers": [
            { "eClass": "http://example.org/classifiers#//Class", "name": "Book", "rank": 3 }
          ]
        }
        """

    /// Validates a JSON document, optionally with the classifier metamodel.
    ///
    /// - Parameters:
    ///   - json: The text of the JSON document.
    ///   - metamodelOption: The spelling of the metamodel option, or `nil` to validate without one.
    /// - Returns: The result of the command.
    @MainActor
    private func validate(json: String, metamodelOption: String?) async throws -> SubprocessResult {
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }
        let file = tempDir.appendingPathComponent("model.json")
        try json.write(to: file, atomically: true, encoding: .utf8)
        var arguments = [file.path]
        if let metamodelOption {
            let metamodel = try loadTestResource(named: "classifiers.ecore", subdirectory: "ecore")
            arguments += [metamodelOption, metamodel.path]
        }
        return try await executeSwiftEcore(command: "validate", arguments: arguments)
    }

    @Test("accepts a JSON model that conforms to the metamodel", arguments: [option, shortOption])
    @MainActor
    func conformingJSON(option: String) async throws {
        let result = try await validate(json: Self.conforming, metamodelOption: option)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
    }

    @Test("rejects a JSON value that the data type of the metamodel cannot read", arguments: [option, shortOption])
    @MainActor
    func mistypedValue(option: String) async throws {
        let without = try await validate(json: Self.mistypedRank, metamodelOption: nil)
        let with = try await validate(json: Self.mistypedRank, metamodelOption: option)

        #expect(without.succeeded, "\(without.stdout)\(without.stderr)")
        #expect(!with.succeeded)
        #expect(with.stderr.contains("JSON"), "\(with.stderr)")
    }

    @Test("rejects a JSON class that the metamodel does not define")
    @MainActor
    func undefinedJSONClass() async throws {
        let without = try await validate(json: Self.undefinedClass, metamodelOption: nil)
        let with = try await validate(json: Self.undefinedClass, metamodelOption: Self.option)

        #expect(without.succeeded, "\(without.stdout)\(without.stderr)")
        #expect(!with.succeeded)
        #expect(with.stderr.contains("Widget"), "\(with.stderr)")
    }

    @Test("reads an XMI model with the classes of the metamodel")
    @MainActor
    func xmiWithMetamodel() async throws {
        let metamodel = try loadTestResource(named: "classifiers.ecore", subdirectory: "ecore")
        let xmiFile = try loadTestResource(named: "classifiers-two-roots.xmi", subdirectory: "xmi")

        let result = try await executeSwiftEcore(
            command: "validate", arguments: [xmiFile.path, Self.option, metamodel.path, "--verbose"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.contains("Found 2 root object(s)"))
        #expect(result.stdout.contains(Self.namespace), "\(result.stdout)")
    }

    @Test("reports a metamodel file that does not exist")
    @MainActor
    func missingMetamodel() async throws {
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let missing = "/tmp/nonexistent-metamodel-\(UUID().uuidString).ecore"

        let result = try await executeSwiftEcore(
            command: "validate", arguments: [xmiFile.path, Self.option, missing])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("File not found"), "\(result.stderr)")
        #expect(result.stderr.contains(missing))
    }

    @Test("lists --metamodel in the help")
    @MainActor
    func helpListsMetamodel() async throws {
        let result = try await executeSwiftEcore(command: "validate", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains(Self.option))
        #expect(result.stdout.contains(Self.shortOption))
    }
}
