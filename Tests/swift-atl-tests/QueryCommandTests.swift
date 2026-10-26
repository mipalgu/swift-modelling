import Foundation
import Testing

/// A scratch project holding a small process flow metamodel, a model and queries over it.
private struct FlowProject {
    /// The metamodel of process flows: a diagram of steps joined by transitions.
    static let metamodel = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore"
            name="Flow" nsURI="http://example.org/flow" nsPrefix="flow">
          <eClassifiers xsi:type="ecore:EClass" name="Diagram">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
            <eStructuralFeatures xsi:type="ecore:EReference" name="steps" upperBound="-1" eType="#//Step" containment="true"/>
            <eStructuralFeatures xsi:type="ecore:EReference" name="transitions" upperBound="-1" eType="#//Transition" containment="true"/>
          </eClassifiers>
          <eClassifiers xsi:type="ecore:EClass" name="Step">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
          </eClassifiers>
          <eClassifiers xsi:type="ecore:EClass" name="Transition">
            <eStructuralFeatures xsi:type="ecore:EReference" name="source" eType="#//Step"/>
            <eStructuralFeatures xsi:type="ecore:EReference" name="target" eType="#//Step"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// A diagram with three steps in a row.
    static let model = """
        <?xml version="1.0" encoding="UTF-8"?>
        <flow:Diagram xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:flow="http://example.org/flow" name="Order">
          <steps name="Receive"/>
          <steps name="Pack"/>
          <steps name="Ship"/>
          <transitions source="//@steps.0" target="//@steps.1"/>
          <transitions source="//@steps.1" target="//@steps.2"/>
        </flow:Diagram>
        """

    /// The helpers that describe a diagram in the Graphviz dot language.
    static let dotHelpers = """
        helper context Flow!Diagram def : dot : String =
            'digraph ' + self.name.quoted() + ' {\\n'
            + self.steps->iterate(s; text : String = '' | text + '  ' + s.name.quoted() + ';\\n')
            + self.transitions->iterate(t; text : String = '' |
                text + '  ' + t.source.name.quoted() + ' -> ' + t.target.name.quoted() + ';\\n')
            + '}\\n';

        helper context String def : quoted() : String = '"' + self + '"';
        """

    /// The query that writes the dot description of the diagram to a file.
    static func dotQuery(writingTo path: String = "flow.dot") -> String {
        """
        -- @path Flow=Flow.ecore
        query Flow2Dot = Flow!Diagram.allInstances()->first().dot.writeTo('\(path)');

        \(dotHelpers)
        """
    }

    /// The dot description that the query writes for the model.
    static let expectedDot = """
        digraph "Order" {
          "Receive";
          "Pack";
          "Ship";
          "Receive" -> "Pack";
          "Pack" -> "Ship";
        }

        """

    /// The scratch directory of the project.
    let directory: URL

    /// The metamodel file.
    var metamodelFile: URL { directory.appendingPathComponent("Flow.ecore") }

    /// The model file.
    var modelFile: URL { directory.appendingPathComponent("order.xmi") }

    /// Creates a project in a new scratch directory.
    static func make() throws -> FlowProject {
        let project = FlowProject(directory: try createTemporaryDirectory())
        try metamodel.write(to: project.metamodelFile, atomically: true, encoding: .utf8)
        try model.write(to: project.modelFile, atomically: true, encoding: .utf8)
        return project
    }

    /// Writes an ATL file into the project.
    ///
    /// - Parameters:
    ///   - source: The ATL source.
    ///   - name: The file name.
    /// - Returns: The location of the file.
    func write(_ source: String, as name: String) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try source.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// The text of a file in the project, or `nil` if it does not exist.
    func text(of path: String, in base: URL? = nil) -> String? {
        try? String(
            contentsOf: (base ?? directory).appendingPathComponent(path), encoding: .utf8)
    }

    /// Removes the project.
    func remove() { cleanupTemporaryDirectory(directory) }
}

@Suite("swift-atl query")
struct QueryCommandTests {

    @Test("writes the dot file that an ATL query builds from an XMI model")
    @MainActor
    func writesDotFile() async throws {
        let project = try FlowProject.make()
        defer { project.remove() }
        let query = try project.write(FlowProject.dotQuery(), as: "Flow2Dot.atl")
        let output = project.directory.appendingPathComponent("graphs")

        let result = try await executeSwiftATL(
            command: "query",
            arguments: [
                query.path, "--source", project.modelFile.path,
                "--output-directory", output.path,
            ])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(project.text(of: "flow.dot", in: output) == FlowProject.expectedDot)
        #expect(result.stdout == "true\n")
    }

    @Test("writes relative to the current directory by default")
    @MainActor
    func defaultOutputDirectory() async throws {
        let project = try FlowProject.make()
        defer { project.remove() }
        let query = try project.write(FlowProject.dotQuery(writingTo: "out/flow.dot"), as: "Q.atl")
        let workingDirectory = project.directory.appendingPathComponent("work")
        try FileManager.default.createDirectory(
            at: workingDirectory, withIntermediateDirectories: true)

        let result = try await executeSwiftATL(
            command: "query", arguments: [query.path, "--source", project.modelFile.path],
            workingDirectory: workingDirectory)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(project.text(of: "out/flow.dot", in: workingDirectory) == FlowProject.expectedDot)
    }

    @Test("prints a string result as it is, and other values as ATL writes them")
    @MainActor
    func printsResult() async throws {
        let project = try FlowProject.make()
        defer { project.remove() }
        let dot = try project.write(
            "-- @path Flow=Flow.ecore\nquery Dot = Flow!Diagram.allInstances()->first().dot;\n"
                + FlowProject.dotHelpers, as: "Dot.atl")
        let names = try project.write(
            "-- @path Flow=Flow.ecore\nquery Names = Flow!Step.allInstances()->collect(s | s.name);\n",
            as: "Names.atl")

        let printed = try await executeSwiftATL(
            command: "query", arguments: [dot.path, "--source", "Flow=\(project.modelFile.path)"])
        #expect(printed.succeeded, "\(printed.stdout)\(printed.stderr)")
        #expect(printed.stdout == FlowProject.expectedDot)

        let listed = try await executeSwiftATL(
            command: "query", arguments: [names.path, "--source", project.modelFile.path])
        #expect(listed.succeeded, "\(listed.stdout)\(listed.stderr)")
        #expect(listed.stdout == "Sequence{'Receive', 'Pack', 'Ship'}\n")

        let quiet = try await executeSwiftATL(
            command: "query",
            arguments: [names.path, "--source", project.modelFile.path, "--no-print-result"])
        #expect(quiet.succeeded, "\(quiet.stdout)\(quiet.stderr)")
        #expect(quiet.stdout.isEmpty)
    }

    @Test("rejects a path that leads outside the output directory")
    @MainActor
    func rejectsEscapingPath() async throws {
        let project = try FlowProject.make()
        defer { project.remove() }
        let query = try project.write(
            FlowProject.dotQuery(writingTo: "../escape.dot"), as: "Escape.atl")
        let output = project.directory.appendingPathComponent("out")

        let result = try await executeSwiftATL(
            command: "query",
            arguments: [
                query.path, "--source", project.modelFile.path, "--output-directory", output.path,
            ])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("'../escape.dot'"), "\(result.stderr)")
        #expect(project.text(of: "escape.dot") == nil)
    }

    @Test("writes to an absolute path only when unrestricted paths are allowed")
    @MainActor
    func absolutePaths() async throws {
        let project = try FlowProject.make()
        defer { project.remove() }
        let target = project.directory.appendingPathComponent("absolute.dot").path
        let query = try project.write(FlowProject.dotQuery(writingTo: target), as: "Absolute.atl")
        let output = project.directory.appendingPathComponent("out")
        let arguments = [
            query.path, "--source", project.modelFile.path, "--output-directory", output.path,
        ]

        let rejected = try await executeSwiftATL(command: "query", arguments: arguments)
        #expect(!rejected.succeeded)
        #expect(rejected.stderr.contains(target), "\(rejected.stderr)")
        #expect(project.text(of: "absolute.dot") == nil)

        let allowed = try await executeSwiftATL(
            command: "query", arguments: arguments + ["--allow-unrestricted-paths"])
        #expect(allowed.succeeded, "\(allowed.stdout)\(allowed.stderr)")
        #expect(project.text(of: "absolute.dot") == FlowProject.expectedDot)
    }

    @Test("names input models and binds metamodels given on the command line")
    @MainActor
    func namedModels() async throws {
        let project = try FlowProject.make()
        defer { project.remove() }
        let query = try project.write(
            """
            query Count = Flow!Step.allInstancesFrom('IN')->size() + thisModule.offset;
            -- @param offset : Integer = 0
            """, as: "Count.atl")

        let result = try await executeSwiftATL(
            command: "query",
            arguments: [
                query.path, "--metamodel", "Flow=\(project.metamodelFile.path)",
                "--source", "IN:Flow=\(project.modelFile.path)", "--param", "offset=10",
            ])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout == "13\n")
    }

    @Test("reports a metamodel without a package")
    @MainActor
    func missingMetamodel() async throws {
        let project = try FlowProject.make()
        defer { project.remove() }
        let query = try project.write(
            "query Count = Flow!Step.allInstances()->size();", as: "Count.atl")

        let result = try await executeSwiftATL(
            command: "query", arguments: [query.path, "--source", "IN:Flow=\(project.modelFile.path)"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("Flow"), "\(result.stderr)")
        #expect(result.stderr.contains("--metamodel"), "\(result.stderr)")
    }

    @Test("rejects a transformation module, which transform runs")
    @MainActor
    func rejectsModule() async throws {
        let project = try FlowProject.make()
        defer { project.remove() }
        let module = try project.write(
            "-- @path Flow=Flow.ecore\nmodule M;\ncreate OUT : Flow from IN : Flow;\n", as: "M.atl")

        let result = try await executeSwiftATL(
            command: "query", arguments: [module.path, "--source", project.modelFile.path])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("transform"), "\(result.stderr)")
    }

    @Test("transform rejects a query unit and names the query command")
    @MainActor
    func transformRejectsQuery() async throws {
        let project = try FlowProject.make()
        defer { project.remove() }
        let query = try project.write(FlowProject.dotQuery(), as: "Flow2Dot.atl")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [query.path, "--source", project.modelFile.path])

        #expect(!result.succeeded)
        #expect(result.stdout.contains("swift-atl query"), "\(result.stdout)")
        #expect(project.text(of: "flow.dot") == nil)
    }

    @Test("transform fails clearly when a do block calls writeTo, and writes no file")
    @MainActor
    func transformCannotWriteFiles() async throws {
        let project = try FlowProject.make()
        defer { project.remove() }
        let module = try project.write(
            """
            -- @path Flow=Flow.ecore
            module Writer;
            create OUT : Flow from IN : Flow;
            entrypoint rule Write() { do { 'text'.writeTo('written.txt'); } }
            """, as: "Writer.atl")
        let output = project.directory.appendingPathComponent("out.xmi")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                module.path, "--source", "IN=\(project.modelFile.path)", "--target",
                "OUT=\(output.path)",
            ])

        let report = "\(result.stdout)\(result.stderr)"
        #expect(!result.succeeded, "\(report)")
        #expect(report.contains("writeTo"), "\(report)")
        #expect(report.contains("disabled"), "\(report)")
        #expect(project.text(of: "written.txt") == nil)
        #expect(project.text(of: "written.txt", in: URL(fileURLWithPath: ".")) == nil)
    }

    @Test("rejects an output directory that is a regular file")
    @MainActor
    func outputDirectoryIsFile() async throws {
        let project = try FlowProject.make()
        defer { project.remove() }
        let query = try project.write(FlowProject.dotQuery(), as: "Flow2Dot.atl")
        let file = try project.write("not a directory", as: "occupied")

        let result = try await executeSwiftATL(
            command: "query",
            arguments: [
                query.path, "--source", project.modelFile.path, "--output-directory", file.path,
            ])

        #expect(!result.succeeded)
        #expect(result.stderr.contains(file.path), "\(result.stderr)")
        #expect(result.stderr.contains("directory"), "\(result.stderr)")
        #expect(project.text(of: "occupied") == "not a directory")
    }

    @Test("validate accepts a query unit")
    @MainActor
    func validateQuery() async throws {
        let project = try FlowProject.make()
        defer { project.remove() }
        let query = try project.write(FlowProject.dotQuery(), as: "Flow2Dot.atl")

        let result = try await executeSwiftATL(command: "validate", arguments: [query.path])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
    }

    @Test("describes its options in the help text")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftATL(command: "query", arguments: ["--help"])

        #expect(result.succeeded)
        for option in [
            "--source", "--metamodel", "--output-directory", "--allow-unrestricted-paths",
            "--print-result", "--param", "writeTo",
        ] {
            #expect(result.stdout.contains(option), "\(option)")
        }
    }
}
