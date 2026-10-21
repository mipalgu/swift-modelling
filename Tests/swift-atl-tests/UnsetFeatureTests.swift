import Foundation
import Testing

/// Tests for `swift-atl --unset-features`, which chooses how transformations read structural
/// features that a model does not set.
@Suite("swift-atl - reading unset features")
struct UnsetFeatureTests {
    /// The long name of the option.
    private static let option = "--unset-features"

    /// A metamodel of tasks that have a name and a Boolean without a declared default.
    static let tasks = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="tasks"
            nsURI="http://www.example.org/tasks" nsPrefix="tasks">
          <eClassifiers xsi:type="ecore:EClass" name="Task">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="done"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EBoolean"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// A metamodel of report entries that have a name.
    static let reports = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="reports"
            nsURI="http://www.example.org/reports" nsPrefix="reports">
          <eClassifiers xsi:type="ecore:EClass" name="Entry">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// Two tasks: one leaves `done` unset, the other sets it to `true`.
    static let model = """
        <?xml version="1.0" encoding="UTF-8"?>
        <xmi:XMI xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns="http://www.example.org/tasks">
          <Task name="drafting"/>
          <Task name="reviewing" done="true"/>
        </xmi:XMI>
        """

    /// A transformation that reports the tasks that are not done and the tasks that are.
    static let transformation = """
        -- @path Tasks=/Tasks.ecore
        -- @path Reports=/Reports.ecore

        module OpenTasks;
        create OUT : Reports from IN : Tasks;

        rule Open {
            from t : Tasks!Task (t.done = false)
            to e : Reports!Entry (
                name <- 'open ' + t.name
            )
        }

        rule Finished {
            from t : Tasks!Task (t.done = true)
            to e : Reports!Entry (
                name <- 'finished ' + t.name
            )
        }
        """

    /// Runs the transformation with extra arguments.
    ///
    /// - Parameter extra: The arguments after the source and target models.
    /// - Returns: The result of the command and the text of the target model, if any.
    @MainActor
    private func transform(_ extra: [String]) async throws -> (result: SubprocessResult, text: String?) {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let atl = scratch.appendingPathComponent("OpenTasks.atl")
        let source = scratch.appendingPathComponent("tasks.xmi")
        let target = scratch.appendingPathComponent("reports.xmi")
        try Self.tasks.write(
            to: scratch.appendingPathComponent("Tasks.ecore"), atomically: true, encoding: .utf8)
        try Self.reports.write(
            to: scratch.appendingPathComponent("Reports.ecore"), atomically: true, encoding: .utf8)
        try Self.model.write(to: source, atomically: true, encoding: .utf8)
        try Self.transformation.write(to: atl, atomically: true, encoding: .utf8)

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--metamodel-path", scratch.path, "--source", "IN=\(source.path)",
                "--target", "OUT=\(target.path)",
            ] + extra)
        return (result, try? String(contentsOf: target, encoding: .utf8))
    }

    @Test("reads an unset Boolean as false by default, as the Eclipse Modeling Framework does")
    @MainActor
    func defaultReadsFalse() async throws {
        let (result, text) = try await transform([])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text?.contains("open drafting") == true, "\(text ?? "no output")")
        #expect(text?.contains("finished reviewing") == true)
    }

    @Test("reads an unset Boolean as false with --unset-features defaults")
    @MainActor
    func explicitDefaults() async throws {
        let (result, text) = try await transform([Self.option, "defaults"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text?.contains("open drafting") == true, "\(text ?? "no output")")
        #expect(text?.contains("finished reviewing") == true)
    }

    @Test("reads an unset Boolean as undefined with --unset-features undefined, failing both guards")
    @MainActor
    func undefinedFailsGuard() async throws {
        let (result, text) = try await transform([Self.option, "undefined"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text?.contains("drafting") == false, "\(text ?? "no output")")
        #expect(text?.contains("finished reviewing") == true)
    }

    @Test("rejects a value that is not a mode")
    @MainActor
    func rejectsUnknownMode() async throws {
        let (result, _) = try await transform([Self.option, "sometimes"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("sometimes"))
    }

    @Test("describes the option in the help of transform and generate", arguments: ["transform", "generate"])
    @MainActor
    func help(command: String) async throws {
        let result = try await executeSwiftATL(command: command, arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains(Self.option))
        #expect(result.stdout.contains("undefined"))
        #expect(result.stdout.contains("Eclipse Modeling Framework"))
    }
}
