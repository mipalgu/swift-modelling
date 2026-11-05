import Foundation
import Testing

/// The path of a validation fixture.
///
/// - Parameter name: The path of the file within the resources, such as `xmi/ledger-valid.xmi`.
/// - Returns: The absolute path.
private func resource(_ name: String) throws -> String {
    let url = URL(fileURLWithPath: name)
    return try loadTestResource(named: url.lastPathComponent, subdirectory: url.deletingLastPathComponent().relativePath).path
}

@Suite("swift-ecore validate - Several files")
struct ValidateMultipleFilesTests {
    @Test("validates every file and summarises the results")
    @MainActor
    func allValid() async throws {
        let first = try resource("xmi/ledger-valid.xmi")
        let second = try resource("xmi/staff.xmi")
        let metamodels = ["-m", try resource("ecore/ledger.ecore"), "-m", try resource("ecore/staff.ecore")]

        let result = try await executeSwiftEcore(command: "validate", arguments: [first, second] + metamodels)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(
            result.stdout == """
                Validating: \(first)
                OCL invariants: 7 of 7 check(s) satisfied
                \(first): valid
                Validating: \(second)
                \(second): valid
                Validated 2 files: 2 valid, 0 invalid

                """)
        #expect(result.stderr.isEmpty)
    }

    @Test("continues after an invalid or unreadable file and fails at the end")
    @MainActor
    func someInvalid() async throws {
        let valid = try resource("xmi/ledger-valid.xmi")
        let invalid = try resource("xmi/ledger-invalid.xmi")
        let missing = "/tmp/nonexistent-\(UUID().uuidString).xmi"

        let result = try await executeSwiftEcore(
            command: "validate", arguments: [valid, invalid, missing, "--metamodel", try resource("ecore/ledger.ecore")])

        #expect(result.exitCode == 1)
        #expect(
            result.stdout == """
                Validating: \(valid)
                OCL invariants: 7 of 7 check(s) satisfied
                \(valid): valid
                Validating: \(invalid)
                Checking constraint: uniqueNumbers (Ledger, /) ... violated
                Checking constraint: positiveAmount (Entry '1', //@entries.0) ... violated
                Checking constraint: namedPayee (Entry '1', //@entries.1) ... violated
                Checking constraint: debitsAreSmall (Entry '1', //@entries.1) ... violated
                OCL invariants: 3 of 7 check(s) satisfied
                \(invalid): invalid (4 error(s), 0 warning(s))
                Validating: \(missing)
                error: File not found: \(missing)
                \(missing): invalid (1 error(s), 0 warning(s))
                Validated 3 files: 1 valid, 2 invalid

                """)
        #expect(result.stderr.contains("Error: Validation failed for 2 of 3 files: \(invalid), \(missing)"))
    }

    @Test("counts a file that cannot be parsed as invalid")
    @MainActor
    func unparsable() async throws {
        let valid = try resource("xmi/valid-model.xmi")
        let broken = try resource("xmi/invalid-syntax.xmi")

        let result = try await executeSwiftEcore(command: "validate", arguments: [broken, valid])

        #expect(result.exitCode == 1)
        #expect(result.stdout.contains("Validating: \(broken)\nerror: Failed to parse XMI: "))
        #expect(result.stdout.contains("\(broken): invalid (1 error(s), 0 warning(s))\nValidating: \(valid)\n"))
        #expect(result.stdout.hasSuffix("\(valid): valid\nValidated 2 files: 1 valid, 1 invalid\n"))
    }

    @Test("validates metamodels and models together, with warnings failing in strict mode")
    @MainActor
    func strict() async throws {
        let metamodel = try resource("ecore/staff.ecore")
        let model = try resource("xmi/staff.xmi")

        let lenient = try await executeSwiftEcore(
            command: "validate", arguments: [metamodel, model, "--check-abstract-classes"])
        let strict = try await executeSwiftEcore(
            command: "validate", arguments: [metamodel, model, "--check-abstract-classes", "--strict"])

        #expect(lenient.succeeded, "\(lenient.stdout)\(lenient.stderr)")
        #expect(lenient.stdout.contains("\(metamodel): valid\n"))
        #expect(!strict.succeeded)
        #expect(strict.stdout.contains("\(metamodel): invalid (0 error(s), 1 warning(s))\n"))
        #expect(strict.stderr.contains("Error: Validation failed for "))
    }

    @Test("writes a JSON array of the reports of every file")
    @MainActor
    func jsonReport() async throws {
        let valid = try resource("xmi/ledger-valid.xmi")
        let invalid = try resource("xmi/ledger-invalid.xmi")
        let missing = "/tmp/nonexistent-\(UUID().uuidString).json"
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let file = directory.appendingPathComponent("report.json")

        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [
                valid, invalid, missing, "-m", try resource("ecore/ledger.ecore"), "--format", "json", "--report", file.path,
            ])

        #expect(result.exitCode == 1)
        #expect(result.stdout.contains("Validated 3 files: 1 valid, 2 invalid\nValidation report written: \(file.path)\n"))
        let reports = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [[String: Any]])
        #expect(reports.map { $0["file"] as? String } == ["ledger-valid.xmi", "ledger-invalid.xmi", URL(fileURLWithPath: missing).lastPathComponent])
        #expect(reports.map { $0["valid"] as? Bool } == [true, false, false])
        let findings = try #require(reports[2]["findings"] as? [[String: Any]])
        #expect(findings.first?["code"] as? String == "document.unreadable")
        #expect(findings.first?["message"] as? String == "File not found: \(missing)")
        #expect(reports[2]["format"] as? String == "JSON")
    }

    @Test("prints a JSON array to standard output")
    @MainActor
    func jsonOutput() async throws {
        let first = try resource("xmi/ledger-valid.xmi")
        let second = try resource("xmi/ledger-valid.xmi")

        let result = try await executeSwiftEcore(
            command: "validate", arguments: [first, second, "-m", try resource("ecore/ledger.ecore"), "--format", "json"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let reports = try #require(try JSONSerialization.jsonObject(with: Data(result.stdout.utf8)) as? [[String: Any]])
        #expect(reports.count == 2)
    }

    @Test("writes the text of every file to a text report")
    @MainActor
    func textReport() async throws {
        let first = try resource("xmi/ledger-valid.xmi")
        let second = try resource("xmi/ledger-invalid.xmi")
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let file = directory.appendingPathComponent("report.txt")

        let result = try await executeSwiftEcore(
            command: "validate", arguments: [first, second, "-m", try resource("ecore/ledger.ecore"), "--report", file.path])

        #expect(result.exitCode == 1)
        let written = try String(contentsOf: file, encoding: .utf8)
        #expect(written.hasPrefix("Validating: \(first)\n"))
        #expect(written.hasSuffix("Validated 2 files: 1 valid, 1 invalid\n"))
        #expect(result.stdout == written + "Validation report written: \(file.path)\n")
    }

    @Test("describes the contents of every file in verbose mode")
    @MainActor
    func verbose() async throws {
        let first = try resource("xmi/ledger-valid.xmi")
        let second = try resource("xmi/staff.xmi")
        let metamodel = try resource("ecore/ledger.ecore")

        let result = try await executeSwiftEcore(command: "validate", arguments: [first, second, "-m", metamodel, "-v"])

        #expect(result.stdout.hasPrefix("Using metamodel: \(metamodel)\nValidating: \(first)\n"))
        #expect(result.stdout.contains("Found 1 root object(s)\n"))
        #expect(result.stdout.components(separatedBy: "Validating: ").count == 3)
    }

    @Test("requires at least one file")
    @MainActor
    func noFiles() async throws {
        let result = try await executeSwiftEcore(command: "validate", arguments: [])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("Missing expected argument"))
    }

    @Test("stops when a metamodel cannot be read")
    @MainActor
    func missingMetamodel() async throws {
        let missing = "/tmp/nonexistent-\(UUID().uuidString).ecore"

        let result = try await executeSwiftEcore(
            command: "validate", arguments: [try resource("xmi/staff.xmi"), try resource("xmi/staff.xmi"), "-m", missing])

        #expect(!result.succeeded)
        #expect(!result.stdout.contains("Validated "))
        #expect(result.stderr.contains(missing))
    }
}
