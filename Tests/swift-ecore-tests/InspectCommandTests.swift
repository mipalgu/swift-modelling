import Foundation
import Testing

/// Runs the inspect command and requires it to succeed.
///
/// - Parameter arguments: The arguments after the subcommand.
/// - Returns: The standard output of the command.
@MainActor
private func inspect(_ arguments: [String]) async throws -> String {
    let result = try await executeSwiftEcore(command: "inspect", arguments: arguments)
    #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
    return result.stdout
}

@Suite("swift-ecore inspect - Metamodels")
struct InspectMetamodelTests {
    @Test("summarises the packages and classifiers of a metamodel")
    @MainActor
    func summary() async throws {
        let staff = try loadTestResource(named: "staff.ecore", subdirectory: "ecore")

        let output = try await inspect([staff.path])

        #expect(output.hasPrefix("Metamodel: staff.ecore (Ecore)\n"))
        #expect(output.contains("Package staff\n  Namespace URI: http://example.org/staff\n  Namespace prefix: staff\n"))
        #expect(output.contains("  Classes: 5 (2 abstract)\n  Enumerations: 1\n  Data types: 0\n"))
        #expect(output.contains("  Abstract class Person\n  Class Employee extends Person\n  Class Manager extends Employee\n"))
        #expect(!output.contains("Attributes:"))
    }

    @Test("shows every feature with its type, multiplicity, containment and opposite in full detail")
    @MainActor
    func fullDetail() async throws {
        let classifiers = try loadTestResource(named: "classifiers.ecore", subdirectory: "ecore")

        let output = try await inspect([classifiers.path, "--detail", "full"])

        #expect(output.contains("  Abstract class NamedElement\n    Attributes:\n      name: EString [0..1]\n"))
        #expect(output.contains("      classifiers: Classifier [0..*], containment, opposite Classifier.package\n"))
        #expect(output.contains("      package: Package [0..1], container, opposite Package.classifiers\n"))
        #expect(output.contains("      isAbstract: EBoolean [0..1], default false\n"))
        #expect(output.contains("      type: Classifier [1..1]\n"))
        #expect(!output.contains("Inheritance hierarchy:"))
    }

    @Test("lists enumeration literals with their values")
    @MainActor
    func literals() async throws {
        let staff = try loadTestResource(named: "staff.ecore", subdirectory: "ecore")

        let output = try await inspect([staff.path, "--detail", "full"])

        #expect(output.contains("  Enumeration Grade\n    JUNIOR = 0\n    SENIOR = 1\n"))
    }

    @Test("shows inherited features, subclasses and the class hierarchy")
    @MainActor
    func supertypes() async throws {
        let staff = try loadTestResource(named: "staff.ecore", subdirectory: "ecore")

        let output = try await inspect([staff.path, "--detail", "full", "--show-supertypes"])

        #expect(output.contains("  Abstract class Person\n    Subclasses: Employee\n"))
        #expect(output.contains("  Class Manager extends Employee\n    All supertypes: Person, Employee\n"))
        #expect(output.contains("      grade: Grade [0..1], from Person\n      employeeId: EString [0..1], from Employee\n"))
        #expect(
            output.hasSuffix(
                "Inheritance hierarchy:\n  Person (abstract)\n    Employee\n      Manager\n  Contact (abstract)\n  Office\n"))
    }

    @Test("shows the reference graph")
    @MainActor
    func references() async throws {
        let staff = try loadTestResource(named: "staff.ecore", subdirectory: "ecore")

        let output = try await inspect([staff.path, "--show-references"])

        #expect(output.contains("  Class Manager extends Employee\n    References:\n      reports: Employee [0..*]\n"))
        #expect(
            output.hasSuffix(
                "Reference graph:\n  Manager.reports -> Employee [0..*]\n  Office.staff -> Person [0..*], containment\n"))
        #expect(!output.contains("Attributes:"))
    }

    @Test("lists attributes in a summary when asked to")
    @MainActor
    func attributes() async throws {
        let staff = try loadTestResource(named: "staff.ecore", subdirectory: "ecore")

        let output = try await inspect([staff.path, "--show-attributes"])

        #expect(output.contains("  Class Office\n    Attributes:\n      city: EString [0..1]\n"))
        #expect(!output.contains("References:"))
    }

    @Test("writes the report as JSON to a file")
    @MainActor
    func jsonOutput() async throws {
        let staff = try loadTestResource(named: "staff.ecore", subdirectory: "ecore")
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let file = directory.appendingPathComponent("structure.json")

        let output = try await inspect([staff.path, "--format", "json", "--output", file.path, "--detail", "full"])

        #expect(output.contains("Inspection written: \(file.path)"))
        let json = try #require(
            try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        #expect(json["kind"] as? String == "metamodel")
        let packages = try #require(json["packages"] as? [[String: Any]])
        let classes = try #require(packages.first?["classes"] as? [[String: Any]])
        #expect(classes.map { $0["name"] as? String } == ["Person", "Employee", "Manager", "Contact", "Office"])
        #expect(classes[0]["abstract"] as? Bool == true)
    }
}

@Suite("swift-ecore inspect - Models")
struct InspectModelTests {
    @Test("counts the objects of each class of a model")
    @MainActor
    func summary() async throws {
        let model = try loadTestResource(named: "enterprise.json", subdirectory: "json")
        let metamodel = try loadTestResource(named: "enterprise.ecore", subdirectory: "ecore")

        let output = try await inspect([model.path, "--metamodel", metamodel.path])

        #expect(output.hasPrefix("Model: enterprise.json (JSON)\n"))
        #expect(output.contains("Root objects: 1\nObjects: 8\n"))
        #expect(output.contains("Classes:\n  Company: 1\n  Department: 2\n  Member: 3\n  Team: 2\n"))
        #expect(!output.contains("Objects:\n  Company"))
    }

    @Test("shows every object with its values, nested as they are contained")
    @MainActor
    func fullDetail() async throws {
        let model = try loadTestResource(named: "enterprise.xmi", subdirectory: "xmi")
        let metamodel = try loadTestResource(named: "enterprise.ecore", subdirectory: "ecore")

        let output = try await inspect([model.path, "-m", metamodel.path, "--detail", "full"])

        #expect(
            output.contains(
                """
                Objects:
                  Company 'Acme' (/)
                    name = "Acme"
                    departments:
                      Department 'Research' (//@departments.0)
                        name = "Research"
                        teams:
                          Team 'Compilers' (//@departments.0/@teams.0)
                            name = "Compilers"
                            members:
                              Member 'Ada' (//@departments.0/@teams.0/@members.0)
                                name = "Ada"
                              Member 'Grace' (//@departments.0/@teams.0/@members.1)
                                name = "Grace"
                                mentor -> Member 'Ada' (//@departments.0/@teams.0/@members.0)
                """))
    }

    @Test("lists the references between the objects of a model")
    @MainActor
    func references() async throws {
        let model = try loadTestResource(named: "enterprise.xmi", subdirectory: "xmi")
        let metamodel = try loadTestResource(named: "enterprise.ecore", subdirectory: "ecore")

        let output = try await inspect([model.path, "-m", metamodel.path, "--show-references", "--show-supertypes"])

        #expect(
            output.contains(
                "Cross references:\n  Member 'Grace' (//@departments.0/@teams.0/@members.1).mentor -> Member 'Ada' (//@departments.0/@teams.0/@members.0)\n"))
        #expect(output.contains("Inheritance hierarchy:\n  Company\n  Department\n  Team\n  Member\n"))
    }

    @Test("reports a file that does not exist")
    @MainActor
    func missingFile() async throws {
        let result = try await executeSwiftEcore(command: "inspect", arguments: ["/tmp/missing-\(UUID().uuidString).ecore"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("File not found"))
    }
}
