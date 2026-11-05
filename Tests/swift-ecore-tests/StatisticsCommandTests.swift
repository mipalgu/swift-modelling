import Foundation
import Testing

/// Runs the statistics command and requires it to succeed.
///
/// - Parameter arguments: The arguments after the subcommand.
/// - Returns: The standard output of the command.
@MainActor
private func statistics(_ arguments: [String]) async throws -> String {
    let result = try await executeSwiftEcore(command: "statistics", arguments: arguments)
    #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
    return result.stdout
}

@Suite("swift-ecore statistics - Metamodels")
struct StatisticsMetamodelTests {
    @Test("measures the elements, inheritance and features of a metamodel")
    @MainActor
    func metamodel() async throws {
        let staff = try loadTestResource(named: "staff.ecore", subdirectory: "ecore")

        let output = try await statistics([staff.path])

        #expect(
            output == """
                Metamodel: staff.ecore (Ecore)
                Packages: 1
                Classes: 5
                  Abstract: 2
                  Interfaces: 0
                Enumerations: 1
                  Literals: 2
                Data types: 0
                Attributes: 4
                References: 2
                  Containment: 1
                  Bidirectional pairs: 0
                Operations: 0
                OCL invariants: 0
                Maximum inheritance depth: 2 (Manager)
                Maximum direct subclasses: 1 (Employee)
                Features per class:
                  Declared: average 1.20, maximum 2 (Office)
                  With inherited: average 2.20, maximum 4 (Manager)
                Classes by number of features:
                  Manager: 4 (1 declared)
                  Employee: 3 (1 declared)
                  Office: 2 (2 declared)
                  Person: 2 (2 declared)
                  Contact: 0 (0 declared)

                """)
    }

    @Test("counts containment, bidirectional pairs once, interfaces, data types, operations and subpackages")
    @MainActor
    func references() async throws {
        let classifiers = try loadTestResource(named: "classifiers.ecore", subdirectory: "ecore")
        let shop = try loadTestResource(named: "shop-v2.ecore", subdirectory: "compare")

        let classifierOutput = try await statistics([classifiers.path])
        let shopOutput = try await statistics([shop.path])

        #expect(classifierOutput.contains("References: 5\n  Containment: 2\n  Bidirectional pairs: 2\n"))
        #expect(classifierOutput.contains("Maximum direct subclasses: 3 (NamedElement)\n"))
        #expect(shopOutput.contains("Packages: 2\nClasses: 8\n  Abstract: 1\n  Interfaces: 1\n"))
        #expect(shopOutput.contains("Enumerations: 2\n  Literals: 5\nData types: 1\n"))
        #expect(shopOutput.contains("Operations: 1\n"))
    }

    @Test("counts the OCL invariants of a metamodel")
    @MainActor
    func invariants() async throws {
        let ledger = try loadTestResource(named: "ledger.ecore", subdirectory: "ecore")

        let output = try await statistics([ledger.path])

        #expect(output.contains("OCL invariants: 4\n"))
    }

    @Test("writes the measurements as JSON")
    @MainActor
    func json() async throws {
        let staff = try loadTestResource(named: "staff.ecore", subdirectory: "ecore")

        let output = try await statistics([staff.path, "--format", "json"])

        let json = try #require(try JSONSerialization.jsonObject(with: Data(output.utf8)) as? [String: Any])
        #expect(json["kind"] as? String == "metamodel")
        #expect(json["file"] as? String == "staff.ecore")
        let metamodel = try #require(json["metamodel"] as? [String: Any])
        #expect(metamodel["classes"] as? Int == 5)
        #expect(metamodel["attributes"] as? Int == 4)
        let depth = try #require(metamodel["maximumInheritanceDepth"] as? [String: Any])
        #expect(depth["count"] as? Int == 2)
        #expect(depth["className"] as? String == "Manager")
        let inherited = try #require(metamodel["allFeatures"] as? [String: Any])
        #expect(inherited["average"] as? Double == 2.2)
        let ranking = try #require(metamodel["classesByFeatures"] as? [[String: Any]])
        #expect(ranking.first?["name"] as? String == "Manager")
        #expect(ranking.first?["features"] as? Int == 4)
        #expect(ranking.first?["declared"] as? Int == 1)
        #expect(json["model"] == nil)
    }
}

@Suite("swift-ecore statistics - Models")
struct StatisticsModelTests {
    @Test("measures the objects, values and links of a model")
    @MainActor
    func model() async throws {
        let model = try loadTestResource(named: "enterprise.xmi", subdirectory: "xmi")
        let metamodel = try loadTestResource(named: "enterprise.ecore", subdirectory: "ecore")

        let output = try await statistics([model.path, "-m", metamodel.path])

        #expect(
            output == """
                Model: enterprise.xmi (XMI)
                Objects: 8
                Root objects: 1
                Classes instantiated: 4
                Objects per class:
                  Company: 1
                  Department: 2
                  Member: 3
                  Team: 2
                Maximum containment depth: 3
                Attribute values: 8
                Containment links: 7
                Cross-references: 1
                  Into other documents: 0
                  Unresolved: 0
                Concrete classes without instances: 0

                """)
    }

    @Test("lists the concrete classes of the metamodel that have no instances")
    @MainActor
    func classesWithoutInstances() async throws {
        let model = try loadTestResource(named: "shop-v1.xmi", subdirectory: "compare")
        let metamodel = try loadTestResource(named: "shop-v1.ecore", subdirectory: "compare")

        let output = try await statistics([model.path, "--metamodel", metamodel.path])

        #expect(output.hasSuffix("Concrete classes without instances: 1\n  Coupon\n"))
        #expect(output.contains("Attribute values: 18\n"))
    }

    @Test("counts references into other documents and those that cannot be resolved")
    @MainActor
    func externalReferences() async throws {
        let resolved = try loadTestResource(named: "enterprise-project.xmi", subdirectory: "xmi")
        let dangling = try loadTestResource(named: "enterprise-dangling.xmi", subdirectory: "xmi")
        let metamodel = try loadTestResource(named: "enterprise.ecore", subdirectory: "ecore")

        let resolvedOutput = try await statistics([resolved.path, "-m", metamodel.path])
        let danglingOutput = try await statistics([dangling.path, "-m", metamodel.path])

        #expect(resolvedOutput.contains("Cross-references: 1\n  Into other documents: 1\n  Unresolved: 0\n"))
        #expect(danglingOutput.contains("Cross-references: 1\n  Into other documents: 1\n  Unresolved: 1\n"))
    }

    @Test("leaves out the classes without instances when no metamodel is given")
    @MainActor
    func withoutMetamodel() async throws {
        let model = try loadTestResource(named: "enterprise.json", subdirectory: "json")

        let output = try await statistics([model.path])

        #expect(output.hasPrefix("Model: enterprise.json (JSON)\nObjects: 8\n"))
        #expect(!output.contains("without instances"))
    }

    @Test("counts the references of classes inferred without a metamodel")
    @MainActor
    func referencesWithoutMetamodel() async throws {
        let model = try loadTestResource(named: "staff.xmi", subdirectory: "xmi")

        let output = try await statistics([model.path])

        #expect(output.contains("Attribute values: 7\nContainment links: 2\nCross-references: 1\n  Into other documents: 0\n  Unresolved: 0\n"))
    }

    @Test("writes the measurements of a model as JSON to a file")
    @MainActor
    func jsonOutput() async throws {
        let model = try loadTestResource(named: "staff.xmi", subdirectory: "xmi")
        let metamodel = try loadTestResource(named: "staff.ecore", subdirectory: "ecore")
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let file = directory.appendingPathComponent("statistics.json")

        let output = try await statistics([model.path, "-m", metamodel.path, "--format", "json", "-o", file.path])

        #expect(output == "Statistics written: \(file.path)\n")
        let json = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        #expect(json["kind"] as? String == "model")
        let statistics = try #require(json["model"] as? [String: Any])
        #expect(statistics["objects"] as? Int == 3)
        #expect(statistics["crossReferences"] as? Int == 1)
        #expect(statistics["classesWithoutInstances"] as? [String] == [])
        let classes = try #require(statistics["classes"] as? [[String: Any]])
        #expect(classes.map { $0["name"] as? String } == ["Employee", "Manager", "Office"])
    }

    @Test("reports what it reads in verbose mode")
    @MainActor
    func verbose() async throws {
        let model = try loadTestResource(named: "staff.xmi", subdirectory: "xmi")

        let output = try await statistics([model.path, "--verbose"])

        #expect(output.hasPrefix("Measuring: \(model.path)\n"))
    }

    @Test("reports a missing file")
    @MainActor
    func missingFile() async throws {
        let missing = "/tmp/nonexistent-\(UUID().uuidString).ecore"

        let result = try await executeSwiftEcore(command: "statistics", arguments: [missing])

        #expect(result.exitCode != 0)
        #expect(result.stderr.contains("Error: File not found: \(missing)"))
    }
}
