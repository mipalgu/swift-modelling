import Foundation
import Testing

@Suite("swift-ecore create")
struct CreateCommandTests {
    /// Runs the create command in a fresh directory.
    ///
    /// - Parameters:
    ///   - output: The name of the file to write.
    ///   - rootClass: The class of the root object.
    ///   - extra: Further arguments.
    /// - Returns: The result and the directory, which the caller removes.
    @MainActor
    private func create(_ output: String, rootClass: String, _ extra: [String] = []) async throws -> (SubprocessResult, URL) {
        let directory = try createTemporaryDirectory()
        let metamodel = try loadTestResource(named: "staff.ecore", subdirectory: "ecore")
        let result = try await executeSwiftEcore(
            command: "create",
            arguments: ["--metamodel", metamodel.path, "--root-class", rootClass, "--output", directory.appendingPathComponent(output).path] + extra)
        return (result, directory)
    }

    @Test("writes an XMI model with one object of the class, which validates")
    @MainActor
    func xmi() async throws {
        let (result, directory) = try await create("office.xmi", rootClass: "Office")
        defer { cleanupTemporaryDirectory(directory) }
        let file = directory.appendingPathComponent("office.xmi")

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let text = try String(contentsOf: file, encoding: .utf8)
        #expect(text.contains("<staff:Office"))
        #expect(text.contains("xmlns:staff=\"http://example.org/staff\""))
        let metamodel = try loadTestResource(named: "staff.ecore", subdirectory: "ecore")
        let validation = try await executeSwiftEcore(command: "validate", arguments: [file.path, "-m", metamodel.path])
        #expect(validation.succeeded, "\(validation.stdout)\(validation.stderr)")
    }

    @Test("writes a JSON model when the output format asks for it")
    @MainActor
    func json() async throws {
        let (result, directory) = try await create("office.data", rootClass: "Office", ["--output-format", "json"])
        defer { cleanupTemporaryDirectory(directory) }

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let text = try String(contentsOf: directory.appendingPathComponent("office.data"), encoding: .utf8)
        #expect(text.contains("\"eClass\" : \"http://example.org/staff#//Office\""))
    }

    @Test("rejects an abstract class")
    @MainActor
    func abstractClass() async throws {
        let (result, directory) = try await create("person.xmi", rootClass: "Person")
        defer { cleanupTemporaryDirectory(directory) }

        #expect(!result.succeeded)
        #expect(result.stderr.contains("The class Person is abstract and cannot be instantiated"))
    }

    @Test("rejects an unknown class and names the classes that can be created")
    @MainActor
    func unknownClass() async throws {
        let (result, directory) = try await create("x.xmi", rootClass: "Desk")
        defer { cleanupTemporaryDirectory(directory) }

        #expect(!result.succeeded)
        #expect(result.stderr.contains("No metamodel defines the class Desk. Classes: Employee, Manager, Office"))
    }

    @Test("keeps an existing file unless forced")
    @MainActor
    func existingFile() async throws {
        let (first, directory) = try await create("office.xmi", rootClass: "Office")
        defer { cleanupTemporaryDirectory(directory) }
        let metamodel = try loadTestResource(named: "staff.ecore", subdirectory: "ecore")
        let path = directory.appendingPathComponent("office.xmi").path
        let arguments = ["-m", metamodel.path, "--root-class", "Office", "-o", path]

        let again = try await executeSwiftEcore(command: "create", arguments: arguments)
        let forced = try await executeSwiftEcore(command: "create", arguments: arguments + ["--force"])

        #expect(first.succeeded)
        #expect(!again.succeeded)
        #expect(again.stderr.contains("already exists"))
        #expect(forced.succeeded, "\(forced.stdout)\(forced.stderr)")
    }

    @Test("requires a metamodel")
    @MainActor
    func missingMetamodel() async throws {
        let result = try await executeSwiftEcore(command: "create", arguments: ["--root-class", "Office", "--output", "/tmp/x.xmi"])

        #expect(result.exitCode == 64)
        #expect(result.stderr.contains("--metamodel"))
    }
}
