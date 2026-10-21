import Foundation
import Testing

/// Tests that `swift-atl transform` writes the elements of a target model in the namespace of
/// the target metamodel.
@Suite("swift-atl - namespaces of target models")
struct TargetNamespaceTests {
    /// The namespace URI of the target metamodel of the fixture transformation.
    private static let namespace = "http://www.example.org/reports"

    /// The namespace URI of the Ecore metamodel.
    private static let ecoreNamespace = "http://www.eclipse.org/emf/2002/Ecore"

    /// Runs the open tasks transformation, whose target class `Entry` starts with an `E`.
    ///
    /// - Parameter targetName: The file name of the target model.
    /// - Returns: The result of the command and the text of the target model, if any.
    @MainActor
    private func transform(targetName: String) async throws -> (result: SubprocessResult, text: String?) {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let atl = scratch.appendingPathComponent("OpenTasks.atl")
        let source = scratch.appendingPathComponent("tasks.xmi")
        let target = scratch.appendingPathComponent(targetName)
        try UnsetFeatureTests.tasks.write(
            to: scratch.appendingPathComponent("Tasks.ecore"), atomically: true, encoding: .utf8)
        try UnsetFeatureTests.reports.write(
            to: scratch.appendingPathComponent("Reports.ecore"), atomically: true, encoding: .utf8)
        try UnsetFeatureTests.model.write(to: source, atomically: true, encoding: .utf8)
        try UnsetFeatureTests.transformation.write(to: atl, atomically: true, encoding: .utf8)

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--metamodel-path", scratch.path, "--source", "IN=\(source.path)",
                "--target", "OUT=\(target.path)",
            ])
        return (result, try? String(contentsOf: target, encoding: .utf8))
    }

    @Test("writes XMI target elements in the namespace of the target metamodel")
    @MainActor
    func xmiTargetNamespace() async throws {
        let (result, text) = try await transform(targetName: "reports.xmi")

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let output = try #require(text)
        #expect(output.contains("xmlns:reports=\"\(Self.namespace)\""), "\(output)")
        #expect(output.contains("<reports:Entry"), "\(output)")
        #expect(!output.contains(Self.ecoreNamespace), "\(output)")
    }

    @Test("writes JSON target classes qualified by the namespace of the target metamodel")
    @MainActor
    func jsonTargetNamespace() async throws {
        let (result, text) = try await transform(targetName: "reports.json")

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let data = try #require(text?.data(using: .utf8))
        let roots = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        #expect(roots.map { $0["eClass"] as? String } == Array(repeating: Self.namespace + "#//Entry", count: 2))
    }
}
