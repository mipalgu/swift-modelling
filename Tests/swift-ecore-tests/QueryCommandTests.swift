import Foundation
import Testing

// MARK: - Info Query Tests

@Suite("swift-ecore query - Info query")
struct QueryInfoTests {

    @Test("should display model information with info query")
    @MainActor
    func testQueryInfo() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")

        // When: Querying for info
        let result = try await executeSwiftEcore(
            command: "query",
            arguments: [xmiFile.path, "--query", "info"]
        )

        // Then: Should display model information
        #expect(result.succeeded)
        #expect(!result.stdout.isEmpty)
    }

    @Test("should use info query as default")
    @MainActor
    func testQueryDefaultInfo() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")

        // When: Querying without explicit query type
        let result = try await executeSwiftEcore(
            command: "query",
            arguments: [xmiFile.path]
        )

        // Then: Should display model information (default behavior)
        #expect(result.succeeded)
        #expect(!result.stdout.isEmpty)
    }
}

// MARK: - Count Query Tests

@Suite("swift-ecore query - Count query")
struct QueryCountTests {

    @Test("should count elements with count query")
    @MainActor
    func testQueryCount() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")

        // When: Querying for element count
        let result = try await executeSwiftEcore(
            command: "query",
            arguments: [xmiFile.path, "--query", "count"]
        )

        // Then: Should display count information
        #expect(result.succeeded)
        #expect(
            result.stdout.contains("count") ||
            result.stdout.contains("elements") ||
            result.stdout.range(of: "\\d+", options: .regularExpression) != nil
        )
    }

    @Test("should display verbose count information")
    @MainActor
    func testQueryCountVerbose() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")

        // When: Querying with verbose flag
        let result = try await executeSwiftEcore(
            command: "query",
            arguments: [xmiFile.path, "--query", "count", "--verbose"]
        )

        // Then: Should display detailed count information
        #expect(result.succeeded)
        #expect(result.stdout.count > 20)
    }
}

// MARK: - List Classes Query Tests

@Suite("swift-ecore query - List classes query")
struct QueryListClassesTests {

    @Test("should list classes with list-classes query")
    @MainActor
    func testQueryListClasses() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")

        // When: Querying for class list
        let result = try await executeSwiftEcore(
            command: "query",
            arguments: [xmiFile.path, "--query", "list-classes"]
        )

        // Then: Should display class information
        #expect(result.succeeded)
        #expect(!result.stdout.isEmpty)
    }
}

// MARK: - Tree Query Tests

@Suite("swift-ecore query - Tree query")
struct QueryTreeTests {

    @Test("should display tree structure")
    @MainActor
    func testQueryTree() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")

        // When: Querying for tree structure
        let result = try await executeSwiftEcore(
            command: "query",
            arguments: [xmiFile.path, "--query", "tree"]
        )

        // Then: Should display tree structure
        #expect(result.succeeded)
        #expect(!result.stdout.isEmpty)
    }

    @Test("should display verbose tree structure")
    @MainActor
    func testQueryTreeVerbose() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")

        // When: Querying with verbose flag
        let result = try await executeSwiftEcore(
            command: "query",
            arguments: [xmiFile.path, "--query", "tree", "--verbose"]
        )

        // Then: Should display detailed tree
        #expect(result.succeeded)
        #expect(result.stdout.count > 20)
    }
}

// MARK: - Error Handling Tests

@Suite("swift-ecore query - Error handling")
struct QueryErrorHandlingTests {

    @Test("should report error for missing file")
    @MainActor
    func testQueryMissingFile() async throws {
        // Given: A non-existent file path
        let missingPath = "/tmp/nonexistent-\(UUID().uuidString).xmi"

        // When: Attempting to query
        let result = try await executeSwiftEcore(
            command: "query",
            arguments: [missingPath]
        )

        // Then: Should report error
        #expect(
            result.stderr.contains("not found") ||
            result.stderr.contains("does not exist") ||
            result.stdout.contains("not found") ||
            result.stdout.contains("Failed")
        )
    }

    @Test("should report error for invalid query type")
    @MainActor
    func testQueryInvalidType() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")

        // When: Using invalid query type
        let result = try await executeSwiftEcore(
            command: "query",
            arguments: [xmiFile.path, "--query", "invalid-query-type"]
        )

        // Then: Should report error or help
        #expect(
            result.stderr.contains("invalid") ||
            result.stderr.contains("unknown") ||
            result.stdout.contains("invalid") ||
            result.stdout.contains("USAGE")
        )
    }
}

// MARK: - Help and Usage Tests

@Suite("swift-ecore query - Help and usage")
struct QueryHelpTests {

    @Test("should display help when --help flag is used")
    @MainActor
    func testQueryHelp() async throws {
        // Given/When: Running query with --help
        let result = try await executeSwiftEcore(
            command: "query",
            arguments: ["--help"]
        )

        // Then: Should display help information
        #expect(result.succeeded)
        #expect(result.stdout.contains("query") || result.stdout.contains("USAGE"))
        #expect(
            result.stdout.contains("--query") ||
            result.stdout.contains("--format") ||
            result.stdout.contains("option")
        )
    }
}
