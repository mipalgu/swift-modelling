import Foundation
import Testing

@Suite("swift-ecore convert - Output option, validation and round trips")
struct ConvertOptionsTests {
    @Test("takes the output file from --output or -o")
    @MainActor
    func outputOption() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let model = try loadTestResource(named: "enterprise.xmi", subdirectory: "xmi")

        for (index, spelling) in ["--output", "-o"].enumerated() {
            let output = directory.appendingPathComponent("model\(index).json")
            let result = try await executeSwiftEcore(command: "convert", arguments: [model.path, spelling, output.path])

            #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
            #expect(FileManager.default.fileExists(atPath: output.path))
        }
    }

    @Test("rejects an output file given twice or not at all")
    @MainActor
    func outputRequired() async throws {
        let model = try loadTestResource(named: "enterprise.xmi", subdirectory: "xmi")

        let twice = try await executeSwiftEcore(command: "convert", arguments: [model.path, "/tmp/a.json", "-o", "/tmp/b.json"])
        let never = try await executeSwiftEcore(command: "convert", arguments: [model.path])

        for result in [twice, never] {
            #expect(!result.succeeded)
            #expect(result.stderr.contains("Give the output file either as the second argument or with --output"))
        }
    }

    @Test("writes a model that passes validation")
    @MainActor
    func validModel() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let model = try loadTestResource(named: "ledger-valid.xmi", subdirectory: "xmi")
        let metamodel = try loadTestResource(named: "ledger.ecore", subdirectory: "ecore")
        let output = directory.appendingPathComponent("ledger.json")

        let result = try await executeSwiftEcore(
            command: "convert", arguments: [model.path, output.path, "--validate", "-m", metamodel.path])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(FileManager.default.fileExists(atPath: output.path))
    }

    @Test("writes nothing for a model that fails validation")
    @MainActor
    func invalidModel() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let model = try loadTestResource(named: "ledger-invalid.xmi", subdirectory: "xmi")
        let metamodel = try loadTestResource(named: "ledger.ecore", subdirectory: "ecore")
        let output = directory.appendingPathComponent("ledger.json")

        let result = try await executeSwiftEcore(
            command: "convert", arguments: [model.path, output.path, "--validate", "-m", metamodel.path])

        #expect(!result.succeeded)
        #expect(result.stdout.contains("Checking constraint: positiveAmount (Entry '1', //@entries.0) ... violated"))
        #expect(result.stderr.contains("The model has 4 validation error(s); no output was written"))
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test("reads back the JSON that it writes, with and without the metamodel")
    @MainActor
    func jsonRoundTrip() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let model = try loadTestResource(named: "staff.xmi", subdirectory: "xmi")
        let metamodel = try loadTestResource(named: "staff.ecore", subdirectory: "ecore")
        let json = directory.appendingPathComponent("staff.json")
        let xmi = directory.appendingPathComponent("staff-roundtrip.xmi")
        let again = directory.appendingPathComponent("staff-roundtrip.json")
        let untyped = directory.appendingPathComponent("untyped.json")
        let untypedXMI = directory.appendingPathComponent("untyped.xmi")

        let steps: [[String]] = [
            [model.path, json.path, "-m", metamodel.path],
            [json.path, xmi.path, "-m", metamodel.path],
            [xmi.path, again.path, "-m", metamodel.path],
            [model.path, untyped.path],
            [untyped.path, untypedXMI.path],
        ]
        for arguments in steps {
            let result = try await executeSwiftEcore(command: "convert", arguments: arguments)
            #expect(result.succeeded, "\(arguments): \(result.stdout)\(result.stderr)")
        }

        #expect(try Data(contentsOf: json) == Data(contentsOf: again))
        let validation = try await executeSwiftEcore(command: "validate", arguments: [xmi.path, "-m", metamodel.path])
        #expect(validation.succeeded, "\(validation.stdout)\(validation.stderr)")
        #expect(try String(contentsOf: untypedXMI, encoding: .utf8).contains("name=\"Grace\""))
    }
}
