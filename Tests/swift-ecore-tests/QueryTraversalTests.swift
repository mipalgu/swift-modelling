import Foundation
import Testing

/// The tutorial resource that defines the employee hierarchy of the Ecore tutorials.
private let employeeHierarchy = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("Sources/SwiftModelling/SwiftModelling.docc/Resources/step-19-employee-hierarchy.ecore")

/// Runs a query and returns its standard output, requiring the command to succeed.
///
/// - Parameters:
///   - file: The model or metamodel to query.
///   - query: The query expression.
///   - metamodel: The metamodel of a model, if any.
/// - Returns: The standard output of the command.
@MainActor
private func query(_ file: URL, _ query: String, metamodel: URL? = nil) async throws -> String {
    var arguments = [file.path, "--query", query]
    if let metamodel { arguments += ["--metamodel", metamodel.path] }
    let result = try await executeSwiftEcore(command: "query", arguments: arguments)
    #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
    return result.stdout
}

// MARK: - Tree Query

@Suite("swift-ecore query - Complete containment trees")
struct QueryCompleteTreeTests {
    /// The tree of the enterprise model, three levels of containment below its root.
    static let enterpriseTree = """
        Object Tree
        ===========
        +-- Company 'Acme' (/)
            |-- departments: Department 'Research' (//@departments.0)
            |   |-- teams: Team 'Compilers' (//@departments.0/@teams.0)
            |   |   |-- members: Member 'Ada' (//@departments.0/@teams.0/@members.0)
            |   |   +-- members: Member 'Grace' (//@departments.0/@teams.0/@members.1)
            |   +-- teams: Team 'Databases' (//@departments.0/@teams.1)
            |       +-- members: Member 'Edgar' (//@departments.0/@teams.1/@members.0)
            +-- departments: Department 'Sales' (//@departments.1)

        """

    @Test("shows every package, classifier, feature and literal of a metamodel")
    @MainActor
    func metamodelTree() async throws {
        let output = try await query(employeeHierarchy, "tree")

        #expect(
            output == """
                Metamodel Tree
                ==============
                +-- EPackage company (http://www.example.org/company)
                    |-- EEnum EmploymentStatus
                    |   |-- EEnumLiteral FULL_TIME = 0
                    |   |-- EEnumLiteral PART_TIME = 1
                    |   +-- EEnumLiteral CONTRACTOR = 2
                    |-- EClass Person
                    |   |-- EAttribute name: EString [0..1]
                    |   |-- EAttribute email: EString [0..1]
                    |   |-- EAttribute status: EmploymentStatus [0..1]
                    |   +-- EReference employer: Company [0..1] (container)
                    |-- EClass Employee (extends Person)
                    |   +-- EAttribute employeeId: EString [0..1]
                    |-- EClass Manager (extends Person)
                    |   +-- EAttribute department: EString [0..1]
                    +-- EClass Company
                        |-- EAttribute name: EString [0..1]
                        +-- EReference employees: Person [0..*] (containment)

                """)
    }

    @Test("shows abstract classes, data type references and empty classes of a metamodel")
    @MainActor
    func metamodelTreeFlags() async throws {
        let output = try await query(try loadTestResource(named: "staff.ecore", subdirectory: "ecore"), "tree")

        #expect(output.contains("    |-- EClass Person (abstract)\n    |   |-- EAttribute name: EString [0..1]\n"))
        #expect(output.contains("    |-- EClass Manager (extends Employee)\n    |   +-- EReference reports: Employee [0..*]\n"))
        #expect(output.contains("    |-- EClass Contact (abstract)\n    +-- EClass Office\n"))
    }

    @Test("shows every object of an XMI model with its class and name at its depth")
    @MainActor
    func xmiModelTree() async throws {
        let model = try loadTestResource(named: "enterprise.xmi", subdirectory: "xmi")
        let metamodel = try loadTestResource(named: "enterprise.ecore", subdirectory: "ecore")

        #expect(try await query(model, "tree", metamodel: metamodel) == Self.enterpriseTree)
    }

    @Test("shows every object of a JSON model, with or without its metamodel")
    @MainActor
    func jsonModelTree() async throws {
        let model = try loadTestResource(named: "enterprise.json", subdirectory: "json")
        let metamodel = try loadTestResource(named: "enterprise.ecore", subdirectory: "ecore")

        #expect(try await query(model, "tree", metamodel: metamodel) == Self.enterpriseTree)
        #expect(try await query(model, "tree") == Self.enterpriseTree)
    }

    @Test("shows every object of an XMI model read without its metamodel")
    @MainActor
    func xmiModelTreeWithoutMetamodel() async throws {
        let output = try await query(try loadTestResource(named: "enterprise.xmi", subdirectory: "xmi"), "tree")

        #expect(output.contains("|   |   +-- members: members 'Grace' (//@departments.0/@teams.0/@members.1)\n"))
        #expect(output.contains("    +-- departments: departments 'Sales' (//@departments.1)\n"))
        #expect(output.split(separator: "\n").count == 10)
    }

    @Test("shows each root of a document with several roots")
    @MainActor
    func severalRoots() async throws {
        let model = try loadTestResource(named: "classifiers-two-roots.xmi", subdirectory: "xmi")
        let metamodel = try loadTestResource(named: "classifiers.ecore", subdirectory: "ecore")

        #expect(
            try await query(model, "tree", metamodel: metamodel) == """
                Object Tree
                ===========
                |-- Package 'library' (/0)
                |   |-- classifiers: DataType 'String' (/0/@classifiers.0)
                |   +-- classifiers: Class 'Book' (/0/@classifiers.1)
                |       +-- attributes: Attribute 'title' (/0/@classifiers.1/@attributes.0)
                +-- Package 'shop' (/1)
                    |-- classifiers: Class 'Order' (/1/@classifiers.0)
                    +-- classifiers: DataType 'Money' (/1/@classifiers.1)

                """)
    }
}

// MARK: - Whole-Document Queries

@Suite("swift-ecore query - Whole documents")
struct QueryWholeDocumentTests {
    @Test("counts the contained objects as well as the roots")
    @MainActor
    func countIncludesContents() async throws {
        let model = try loadTestResource(named: "enterprise.xmi", subdirectory: "xmi")

        #expect(try await query(model, "count") == "Total objects: 8\n")
        let info = try await query(model, "info", metamodel: try loadTestResource(named: "enterprise.ecore", subdirectory: "ecore"))
        #expect(info.contains("Root objects: 1\nTotal objects: 8\n"))
        #expect(info.contains("  * Member: 3\n"))
        #expect(info.contains("Metamodels: http://example.org/enterprise\n"))
    }

    @Test("lists the classes of all objects of a model, also under the name classes")
    @MainActor
    func listClassesOfModel() async throws {
        let model = try loadTestResource(named: "staff.xmi", subdirectory: "xmi")
        let metamodel = try loadTestResource(named: "staff.ecore", subdirectory: "ecore")
        let expected = """
            Classes
            =======
            * Employee: 1 (extends Person)
            * Manager: 1 (extends Employee)
            * Office: 1

            """

        #expect(try await query(model, "list-classes", metamodel: metamodel) == expected)
        #expect(try await query(model, "classes", metamodel: metamodel) == expected)
        #expect(try await query(model, "CLASSES", metamodel: metamodel) == expected)
    }

    @Test("lists every class of a metamodel with its supertypes")
    @MainActor
    func listClassesOfMetamodel() async throws {
        let output = try await query(employeeHierarchy, "classes")

        #expect(
            output == """
                Classes
                =======
                * Person
                * Employee (extends Person)
                * Manager (extends Person)
                * Company

                """)
    }

    @Test("shows the inheritance hierarchy of a metamodel")
    @MainActor
    func hierarchy() async throws {
        let output = try await query(try loadTestResource(named: "staff.ecore", subdirectory: "ecore"), "hierarchy")

        #expect(
            output == """
                Class Hierarchy
                ===============
                |-- Person (abstract)
                |   +-- Employee
                |       +-- Manager
                |-- Contact (abstract)
                +-- Office

                """)
    }

    @Test("finds the objects of a class and its subclasses at any depth, keeping the case of the name")
    @MainActor
    func findIncludesSubclasses() async throws {
        let output = try await query(
            try loadTestResource(named: "staff.xmi", subdirectory: "xmi"), "find Employee",
            metamodel: try loadTestResource(named: "staff.ecore", subdirectory: "ecore"))

        #expect(output.hasPrefix("Objects matching 'Employee'\n===========================\nFound 2 match(es)\n"))
        #expect(output.contains("1. Employee 'Ada' (//@staff.0)\n   name = \"Ada\"\n   grade = SENIOR\n   employeeId = \"E1\"\n"))
        #expect(output.contains("2. Manager 'Grace' (//@staff.1)\n"))
        #expect(output.contains("   reports -> Employee 'Ada' (//@staff.0)\n"))
    }

    @Test("finds nested objects of a model read without a metamodel")
    @MainActor
    func findNestedObjects() async throws {
        let output = try await query(try loadTestResource(named: "enterprise.json", subdirectory: "json"), "find Member")

        #expect(output.contains("Found 3 match(es)"))
        #expect(output.contains("3. Member 'Edgar' (//@departments.0/@teams.1/@members.0)"))
        #expect(output.contains("   mentor -> Member 'Ada' (//@departments.0/@teams.0/@members.0)"))
    }

    @Test("finds metamodel elements by their metaclass")
    @MainActor
    func findInMetamodel() async throws {
        let output = try await query(employeeHierarchy, "find EAttribute")

        #expect(output.contains("Found 6 match(es)"))
        #expect(output.contains("4. EAttribute employeeId (//Employee/employeeId)"))
    }

    @Test("describes a metamodel with its packages and the kinds of its elements")
    @MainActor
    func metamodelInfo() async throws {
        let output = try await query(employeeHierarchy, "info")

        #expect(output.contains("Root objects: 1 (EPackage company)"))
        #expect(output.contains("  * company (http://www.example.org/company): 4 class(es), 1 enumeration(s), 0 data type(s)"))
        #expect(output.contains("  * EClass: 4\n"))
    }

    @Test("follows a reference into another document")
    @MainActor
    func crossDocumentReference() async throws {
        let output = try await query(
            try loadTestResource(named: "enterprise-project.xmi", subdirectory: "xmi"), "find Department",
            metamodel: try loadTestResource(named: "enterprise.ecore", subdirectory: "ecore"))

        #expect(output.contains("   partners -> Department 'Finance' in enterprise-shared.xmi#/1"))
    }

    @Test("rejects find without a class name")
    @MainActor
    func findWithoutClass() async throws {
        let model = try loadTestResource(named: "enterprise.xmi", subdirectory: "xmi")
        let result = try await executeSwiftEcore(command: "query", arguments: [model.path, "--query", "find"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("find requires a class name"))
    }
}
