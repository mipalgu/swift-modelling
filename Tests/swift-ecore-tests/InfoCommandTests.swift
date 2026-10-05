import Foundation
import Testing

@Suite("swift-ecore info - Information display")
struct InfoCommandTests {

    @Test("should display version and available commands")
    @MainActor
    func testInfoDisplaysVersionAndCommands() async throws {
        // Given: The swift-ecore executable

        // When: Running the info command
        let result = try await executeSwiftEcore(command: "info")

        // Then: Should show version and available commands
        #expect(result.succeeded)
        #expect(result.stdout.contains("Swift Ecore"))
        #expect(result.stdout.contains("validate"))
        #expect(result.stdout.contains("convert"))
        #expect(result.stdout.contains("query"))
    }

    @Test("should report the version that --version reports")
    @MainActor
    func testInfoReportsToolVersion() async throws {
        let version = try await executeSwiftEcore(command: "--version")
        let info = try await executeSwiftEcore(command: "info")

        #expect(version.succeeded)
        let number = version.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(!number.isEmpty)
        #expect(info.stdout.contains("Swift Ecore v\(number)\n"))
    }

    @Test("should exit with code 0")
    @MainActor
    func testInfoExitsSuccessfully() async throws {
        // Given/When: Running info command
        let result = try await executeSwiftEcore(command: "info")

        // Then: Should exit successfully
        #expect(result.exitCode == 0)
        #expect(result.succeeded)
    }

    @Test("should not write to stderr")
    @MainActor
    func testInfoNoErrors() async throws {
        // Given/When: Running info command
        let result = try await executeSwiftEcore(command: "info")

        // Then: Should not produce errors
        #expect(result.stderr.isEmpty)
    }
}
