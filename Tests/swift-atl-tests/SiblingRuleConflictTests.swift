import Foundation
import Testing

/// Tests for `swift-atl transform --sibling-rule-conflicts`, which chooses what a source element
/// that two sub-rules of the same rule both match gives: the first of them applies with a
/// warning by default, and `error` stops the run.
@Suite("swift-atl - sibling rule conflicts")
struct SiblingRuleConflictTests {
    /// The long name of the option.
    private static let option = "--sibling-rule-conflicts"

    /// The name of the configuration file.
    private static let configurationFile = ".swift-modelling.json"

    /// A metamodel of projects that contain tasks.
    static let tasks = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="tasks"
            nsURI="http://www.example.org/tasks" nsPrefix="tasks">
          <eClassifiers xsi:type="ecore:EClass" name="Project">
            <eStructuralFeatures xsi:type="ecore:EReference" name="tasks" upperBound="-1"
                eType="#//Task" containment="true"/>
          </eClassifiers>
          <eClassifiers xsi:type="ecore:EClass" name="Task">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="done"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EBoolean"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// A metamodel of named notes.
    static let notes = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="notes"
            nsURI="http://www.example.org/notes" nsPrefix="notes">
          <eClassifiers xsi:type="ecore:EClass" name="Note">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// A project with an open task and a finished task.
    static let model = """
        <?xml version="1.0" encoding="UTF-8"?>
        <tasks:Project xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:tasks="http://www.example.org/tasks">
          <tasks name="drafting"/>
          <tasks name="reviewing" done="true"/>
        </tasks:Project>
        """

    /// A transformation with two sub-rules of the same rule, both of which match a finished task.
    static let transformation = """
        -- @path Tasks=/Tasks.ecore
        -- @path Notes=/Notes.ecore

        module SiblingNotes;
        create OUT : Notes from IN : Tasks;

        abstract rule Task2Note {
            from t : Tasks!Task
            to n : Notes!Note (name <- t.name)
        }

        rule FinishedTask extends Task2Note {
            from t : Tasks!Task (t.done)
            to n : Notes!Note (name <- 'finished ' + t.name)
        }

        rule AnyTask extends Task2Note {
            from t : Tasks!Task
            to n : Notes!Note (name <- 'any ' + t.name)
        }
        """

    /// The warning that the finished task gives, as far as it is fixed by the rules.
    static let warning = "Warning: Rules 'FinishedTask' and 'AnyTask', which extend rule 'Task2Note', both match "

    /// The part of the warning that names the sub-rule that is applied.
    static let applied = "only 'FinishedTask' is applied"

    /// The error that the finished task gives when a conflict is an error.
    static let error = "both match"

    /// A directory with the metamodels, the transformation and the source model.
    struct Workspace {
        /// The temporary directory.
        let root: URL

        /// Creates the directory, marked as the root of a repository.
        ///
        /// - Throws: An error if a file cannot be written.
        init() throws {
            root = try createTemporaryDirectory()
            try FileManager.default.createDirectory(
                at: root.appendingPathComponent(".git"), withIntermediateDirectories: true)
            try write(SiblingRuleConflictTests.tasks, to: "Tasks.ecore")
            try write(SiblingRuleConflictTests.notes, to: "Notes.ecore")
            try write(SiblingRuleConflictTests.model, to: "tasks.xmi")
            try write(SiblingRuleConflictTests.transformation, to: "SiblingNotes.atl")
        }

        /// Writes a file at a path relative to the directory.
        ///
        /// - Parameters:
        ///   - text: The contents.
        ///   - path: The path, relative to the directory.
        /// - Throws: An error if the file cannot be written.
        func write(_ text: String, to path: String) throws {
            try text.write(to: root.appendingPathComponent(path), atomically: true, encoding: .utf8)
        }
    }

    /// Runs the transformation from the workspace directory.
    ///
    /// - Parameters:
    ///   - workspace: The workspace.
    ///   - target: The name of the target model.
    ///   - extra: The arguments after the models.
    /// - Returns: The result of the command and the text of the target model, if any.
    @MainActor
    private func transform(
        _ workspace: Workspace, target: String = "notes.xmi", extra: [String] = []
    ) async throws -> (result: SubprocessResult, text: String?) {
        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                "SiblingNotes.atl", "--metamodel-path", workspace.root.path, "--source", "IN=tasks.xmi",
                "--target", "OUT=\(target)",
            ] + extra,
            workingDirectory: workspace.root)
        return (result, try? String(contentsOf: workspace.root.appendingPathComponent(target), encoding: .utf8))
    }

    /// Checks that a run applied the first sub-rule and warned about the other.
    ///
    /// - Parameters:
    ///   - result: The result of the command.
    ///   - text: The text of the target model.
    private func expectWarning(_ result: SubprocessResult, _ text: String?) {
        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stderr.contains(Self.warning), "\(result.stderr)")
        #expect(result.stderr.contains("Task 'reviewing'"), "\(result.stderr)")
        #expect(result.stderr.contains(Self.applied), "\(result.stderr)")
        #expect(!result.stdout.contains(Self.warning), "\(result.stdout)")
        #expect(text?.contains("name=\"finished reviewing\"") == true, "\(text ?? "")")
        #expect(text?.contains("name=\"any drafting\"") == true, "\(text ?? "")")
        #expect(text?.contains("any reviewing") == false, "\(text ?? "")")
    }

    /// Checks that a run stopped at the conflict and wrote no target.
    ///
    /// - Parameters:
    ///   - result: The result of the command.
    ///   - text: The text of the target model, if any.
    private func expectError(_ result: SubprocessResult, _ text: String?) {
        #expect(result.exitCode == 1, "\(result.stdout)\(result.stderr)")
        let output = result.stdout + result.stderr
        #expect(output.contains("FinishedTask"), "\(output)")
        #expect(output.contains("AnyTask"), "\(output)")
        #expect(output.contains(Self.error), "\(output)")
        #expect(!output.contains(Self.applied), "\(output)")
        #expect(text == nil)
    }

    @Test("applies the first sub-rule and warns on standard error by default", arguments: [[], ["--quiet"], ["--verbose"]])
    @MainActor
    func warningByDefault(extra: [String]) async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await transform(workspace, extra: extra)

        expectWarning(result, text)
        if extra == ["--quiet"] {
            #expect(result.stdout.isEmpty, "\(result.stdout)")
        }
    }

    @Test("warns with --sibling-rule-conflicts warning as without the option")
    @MainActor
    func warningExplicit() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (implicit, implicitText) = try await transform(workspace, target: "a.xmi")
        let (explicit, explicitText) = try await transform(workspace, target: "b.xmi", extra: [Self.option, "warning"])

        expectWarning(explicit, explicitText)
        #expect(implicitText == explicitText)
        #expect(implicit.stderr == explicit.stderr)
    }

    @Test("stops with an error and writes no target with --sibling-rule-conflicts error")
    @MainActor
    func errorOnCommandLine() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (result, text) = try await transform(workspace, extra: [Self.option, "error"])

        expectError(result, text)
    }

    @Test("takes the value of the configuration file, which the command line overrides")
    @MainActor
    func configurationKey() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }
        try workspace.write(#"{ "sibling-rule-conflicts": "error" }"#, to: Self.configurationFile)

        let (configured, configuredText) = try await transform(workspace, target: "configured.xmi")
        let (overridden, overriddenText) = try await transform(
            workspace, target: "overridden.xmi", extra: [Self.option, "warning"])
        let (ignored, ignoredText) = try await transform(workspace, target: "ignored.xmi", extra: ["--no-config"])

        expectError(configured, configuredText)
        expectWarning(overridden, overriddenText)
        expectWarning(ignored, ignoredText)
    }

    @Test("lets the command line make a conflict an error over a file that asks for a warning")
    @MainActor
    func commandLineOverridesWarning() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }
        try workspace.write(#"{ "sibling-rule-conflicts": "warning" }"#, to: Self.configurationFile)

        let (result, text) = try await transform(workspace, extra: [Self.option, "error"])

        expectError(result, text)
    }

    @Test("rejects a value that is not a sibling rule conflict mode, on the command line or in the file")
    @MainActor
    func rejectsUnknownValue() async throws {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }

        let (fromCommandLine, commandLineText) = try await transform(workspace, extra: [Self.option, "ignore"])
        try workspace.write(#"{ "sibling-rule-conflicts": "ignore" }"#, to: Self.configurationFile)
        let (fromFile, fileText) = try await transform(workspace)

        #expect(!fromCommandLine.succeeded)
        #expect(fromCommandLine.stderr.contains("ignore"), "\(fromCommandLine.stderr)")
        #expect(commandLineText == nil)
        #expect(!fromFile.succeeded)
        let output = fromFile.stdout + fromFile.stderr
        for expected in ["'sibling-rule-conflicts'", "'ignore'", "warning", "error"] {
            #expect(output.contains(expected), "\(expected) is missing from: \(output)")
        }
        #expect(fileText == nil)
    }

    @Test("lists the option and its values in the help of the commands that run rules", arguments: ["transform", "generate"])
    @MainActor
    func help(command: String) async throws {
        let result = try await executeSwiftATL(command: command, arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains(Self.option))
        #expect(result.stdout.contains("warning|error"))
    }

    // MARK: - generate

    /// The bundled transformation from Ecore models to generator models.
    private static let bundledTransformation = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources/ModellingGenerators/Transformations/Ecore2GenModel.atl")

    /// Rules that annotate every class through two sub-rules of the same rule, both of which match.
    static let annotatingRules = """

        abstract rule ClassNote {
            from c : Ecore!EClass
            to a : GenModel!GenAnnotation (source <- c.name)
        }

        rule FirstClassNote extends ClassNote {
            from c : Ecore!EClass (true)
            to a : GenModel!GenAnnotation
        }

        rule SecondClassNote extends ClassNote {
            from c : Ecore!EClass
            to a : GenModel!GenAnnotation
        }
        """

    /// Creates a generator model with a copy of the bundled transformation that adds the
    /// annotating rules.
    ///
    /// - Parameters:
    ///   - extra: The arguments after the model, language and transformation.
    ///   - configuration: The contents of the configuration file, if any.
    /// - Returns: The result of the command and whether the generator model was written.
    @MainActor
    private func generate(
        _ extra: [String], configuration: String? = nil
    ) async throws -> (result: SubprocessResult, written: Bool) {
        let workspace = try Workspace()
        defer { cleanupTemporaryDirectory(workspace.root) }
        if let configuration { try workspace.write(configuration, to: Self.configurationFile) }
        let source = try String(contentsOf: Self.bundledTransformation, encoding: .utf8)
        try workspace.write(source + Self.annotatingRules, to: "Ecore2GenModel.atl")
        let output = workspace.root.appendingPathComponent("Tasks.genmodel")
        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [
                "Tasks.ecore", "--language", "genmodel", "--transformations", "Ecore2GenModel.atl", "-o", output.path,
            ] + extra,
            workingDirectory: workspace.root)
        return (result, FileManager.default.fileExists(atPath: output.path))
    }

    @Test("generate applies the first sub-rule of a replacement transformation with a warning by default")
    @MainActor
    func generateWarning() async throws {
        let (result, written) = try await generate([])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(written)
        #expect(
            result.stderr.contains("Rules 'FirstClassNote' and 'SecondClassNote', which extend rule 'ClassNote'"),
            "\(result.stderr)")
        #expect(result.stderr.contains("only 'FirstClassNote' is applied"), "\(result.stderr)")
    }

    @Test("generate stops at the conflict with --sibling-rule-conflicts error or the key of the file")
    @MainActor
    func generateError() async throws {
        let configured = #"{ "sibling-rule-conflicts": "error" }"#
        for (extra, configuration) in [([Self.option, "error"], nil), ([], configured)] {
            let (result, written) = try await generate(extra, configuration: configuration)

            #expect(!result.succeeded)
            let output = result.stdout + result.stderr
            #expect(output.contains("FirstClassNote") && output.contains("SecondClassNote"), "\(output)")
            #expect(!output.contains("is applied"), "\(output)")
            #expect(!written)
        }
        let (overridden, written) = try await generate([Self.option, "warning"], configuration: configured)
        #expect(overridden.succeeded, "\(overridden.stdout)\(overridden.stderr)")
        #expect(written)
    }
}
