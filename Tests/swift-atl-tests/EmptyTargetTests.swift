import Foundation
import Testing

/// Tests that `swift-atl transform` writes a target model whose rules match nothing.
@Suite("swift-atl - empty target models")
struct EmptyTargetTests {
    /// A transformation whose guards hold for none of the tasks of the fixture.
    static let transformation = """
        -- @path Tasks=/Tasks.ecore
        -- @path Reports=/Reports.ecore

        module NoTasks;
        create OUT : Reports from IN : Tasks;

        rule Nobody {
            from t : Tasks!Task (t.name = 'nobody')
            to e : Reports!Entry (
                name <- t.name
            )
        }
        """

    /// Runs the transformation whose rules match nothing.
    ///
    /// - Parameter targetName: The file name of the target model.
    /// - Returns: The result of the command and the text of the target model, if any.
    @MainActor
    private func transform(targetName: String) async throws -> (result: SubprocessResult, text: String?) {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let atl = scratch.appendingPathComponent("NoTasks.atl")
        let source = scratch.appendingPathComponent("tasks.xmi")
        let target = scratch.appendingPathComponent(targetName)
        try UnsetFeatureTests.tasks.write(
            to: scratch.appendingPathComponent("Tasks.ecore"), atomically: true, encoding: .utf8)
        try UnsetFeatureTests.reports.write(
            to: scratch.appendingPathComponent("Reports.ecore"), atomically: true, encoding: .utf8)
        try UnsetFeatureTests.model.write(to: source, atomically: true, encoding: .utf8)
        try Self.transformation.write(to: atl, atomically: true, encoding: .utf8)

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--metamodel-path", scratch.path, "--source", "IN=\(source.path)",
                "--target", "OUT=\(target.path)",
            ])
        return (result, try? String(contentsOf: target, encoding: .utf8))
    }

    @Test("writes an XMI document without elements when no rule matches")
    @MainActor
    func emptyXMITarget() async throws {
        let (result, text) = try await transform(targetName: "reports.xmi")

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let output = try #require(text, "\(result.stdout)\(result.stderr)")
        #expect(output.contains("<xmi:XMI"), "\(output)")
        #expect(!output.contains("Entry"), "\(output)")
    }

    @Test("writes an empty JSON array when no rule matches")
    @MainActor
    func emptyJSONTarget() async throws {
        let (result, text) = try await transform(targetName: "reports.json")

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let output = try #require(text, "\(result.stdout)\(result.stderr)")
        let data = try #require(output.data(using: .utf8))
        let roots = try JSONSerialization.jsonObject(with: data) as? [Any]
        #expect(roots?.isEmpty == true, "\(output)")
    }
}
