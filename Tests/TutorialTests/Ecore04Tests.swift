import Testing
import Foundation

/// Test suite for Ecore Tutorial 04: Advanced Metamodel Features
/// Validates each step of the EEnum, inheritance, and abstract class tutorial
@Suite("Tutorial: Advanced Metamodel Features")
struct Ecore04Tests {

    let tutorialResourcesPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")
        .appendingPathComponent("SwiftModelling")
        .appendingPathComponent("SwiftModelling.docc")
        .appendingPathComponent("Resources")

    // MARK: - Section 1: Understanding EEnum

    @Test("Step 1: Validate starting metamodel with bidirectional references")
    func testStep01StartingMetamodel() async throws {
        // Verify we start with the bidirectional metamodel from Tutorial 03
        let startingPath = tutorialResourcesPath.appendingPathComponent("step-14-bidirectional-reference.ecore")

        #expect(FileManager.default.fileExists(atPath: startingPath.path))

        let content = try String(contentsOf: startingPath, encoding: .utf8)

        // Verify both classes exist
        #expect(content.contains("name=\"Person\""))
        #expect(content.contains("name=\"Company\""))

        // Verify bidirectional references
        #expect(content.contains("name=\"employees\""))
        #expect(content.contains("name=\"employer\""))
        #expect(content.contains("eOpposite=\"#//Person/employer\""))
        #expect(content.contains("eOpposite=\"#//Company/employees\""))

        // Verify no enum yet
        #expect(!content.contains("ecore:EEnum"))
    }

    @Test("Step 2: Validate employment status enum added")
    func testStep02EmploymentStatusEnum() async throws {
        // Load the metamodel with employment status enum
        let enumPath = tutorialResourcesPath.appendingPathComponent("step-17-employment-status-enum.ecore")

        #expect(FileManager.default.fileExists(atPath: enumPath.path))

        let content = try String(contentsOf: enumPath, encoding: .utf8)

        // Verify EEnum exists
        #expect(content.contains("ecore:EEnum"))
        #expect(content.contains("name=\"EmploymentStatus\""))

        // Verify enum literals
        #expect(content.contains("name=\"FULL_TIME\""))
        #expect(content.contains("name=\"PART_TIME\""))
        #expect(content.contains("name=\"CONTRACTOR\""))

        // Verify literal values
        #expect(content.contains("value=\"0\""))
        #expect(content.contains("value=\"1\""))
        #expect(content.contains("value=\"2\""))

        // Person should not have status attribute yet
        let personStart = content.range(of: "name=\"Person\"")!.upperBound
        let personEnd = content.range(of: "name=\"Company\"")!.lowerBound
        let personSection = String(content[personStart..<personEnd])
        #expect(!personSection.contains("name=\"status\""))
    }

    @Test("Step 3: Validate Person with status attribute")
    func testStep03PersonWithStatus() async throws {
        // Load the metamodel with status attribute
        let statusPath = tutorialResourcesPath.appendingPathComponent("step-18-person-with-status.ecore")

        #expect(FileManager.default.fileExists(atPath: statusPath.path))

        let content = try String(contentsOf: statusPath, encoding: .utf8)

        // Verify enum still exists
        #expect(content.contains("name=\"EmploymentStatus\""))

        // Verify Person has status attribute
        let personStart = content.range(of: "name=\"Person\"")!.upperBound
        let personEnd = content.range(of: "name=\"Employee\"") ?? content.range(of: "name=\"Company\"")!
        let personSection = String(content[personStart..<personEnd.lowerBound])

        #expect(personSection.contains("name=\"status\""))
        #expect(personSection.contains("eType=\"#//EmploymentStatus\""))
    }

    // MARK: - Section 2: Class Inheritance

    @Test("Step 4: Validate employee hierarchy with inheritance")
    func testStep04EmployeeHierarchy() async throws {
        // Load the metamodel with employee hierarchy
        let hierarchyPath = tutorialResourcesPath.appendingPathComponent("step-19-employee-hierarchy.ecore")

        #expect(FileManager.default.fileExists(atPath: hierarchyPath.path))

        let content = try String(contentsOf: hierarchyPath, encoding: .utf8)

        // Verify Person still exists
        #expect(content.contains("name=\"Person\""))

        // Verify Employee class with inheritance
        #expect(content.contains("name=\"Employee\""))
        #expect(content.contains("eSuperTypes=\"#//Person\""))

        // Verify Employee has employeeId
        let employeeStart = content.range(of: "name=\"Employee\"")!.upperBound
        let employeeEnd = content.range(of: "name=\"Manager\"")!.lowerBound
        let employeeSection = String(content[employeeStart..<employeeEnd])
        #expect(employeeSection.contains("name=\"employeeId\""))

        // Verify Manager class with inheritance
        #expect(content.contains("name=\"Manager\""))

        let managerStart = content.range(of: "name=\"Manager\"")!.upperBound
        let managerEnd = content.range(of: "name=\"Company\"")!.lowerBound
        let managerSection = String(content[managerStart..<managerEnd])
        #expect(managerSection.contains("eSuperTypes=\"#//Person\""))
        #expect(managerSection.contains("name=\"department\""))
    }

    @Test("Step 5: Inspect hierarchy command exists")
    func testStep05InspectHierarchyCommand() async throws {
        // Load the inspect hierarchy command script
        let inspectPath = tutorialResourcesPath.appendingPathComponent("step-20-inspect-hierarchy.sh")

        #expect(FileManager.default.fileExists(atPath: inspectPath.path))

        let content = try String(contentsOf: inspectPath, encoding: .utf8)

        // Verify command structure
        #expect(content.contains("swift-ecore"))
        #expect(content.contains("inspect"))
        #expect(content.contains("Company.ecore"))
        #expect(content.contains("--detail full"))
        #expect(content.contains("--show-supertypes"))
    }

    // MARK: - Section 3: Abstract Classes

    @Test("Step 6: Validate abstract Person class")
    func testStep06AbstractPerson() async throws {
        // Load the metamodel with abstract Person
        let abstractPath = tutorialResourcesPath.appendingPathComponent("step-21-abstract-person.ecore")

        #expect(FileManager.default.fileExists(atPath: abstractPath.path))

        let content = try String(contentsOf: abstractPath, encoding: .utf8)

        // Verify Person is marked abstract
        #expect(content.contains("name=\"Person\""))
        #expect(content.contains("abstract=\"true\""))

        // Verify Employee and Manager are NOT abstract
        let employeeStart = content.range(of: "name=\"Employee\"")!.lowerBound
        let employeeEnd = content.range(of: "name=\"Manager\"")!.lowerBound
        let employeeSection = String(content[employeeStart..<employeeEnd])
        #expect(!employeeSection.contains("abstract=\"true\""))

        let managerStart = content.range(of: "name=\"Manager\"")!.lowerBound
        let managerEnd = content.range(of: "name=\"Company\"")!.lowerBound
        let managerSection = String(content[managerStart..<managerEnd])
        #expect(!managerSection.contains("abstract=\"true\""))
    }

    @Test("Step 7: Validate concrete instances in XMI")
    func testStep07ConcreteInstances() async throws {
        // Load the XMI with concrete instances
        let instancePath = tutorialResourcesPath.appendingPathComponent("step-22-concrete-instances.xmi")

        #expect(FileManager.default.fileExists(atPath: instancePath.path))

        let content = try String(contentsOf: instancePath, encoding: .utf8)

        // Verify XMI structure
        #expect(content.contains("xmi:XMI"))
        #expect(content.contains("xmlns:company=\"http://www.example.org/company\""))

        // Verify NO direct Person instances (it's abstract)
        #expect(!content.contains("xsi:type=\"company:Person\""))
        #expect(!content.contains("<company:Person"))

        // Verify Employee instances
        #expect(content.contains("xsi:type=\"company:Employee\""))
        #expect(content.contains("employeeId=\"E001\""))
        #expect(content.contains("employeeId=\"E002\""))

        // Verify Manager instance
        #expect(content.contains("xsi:type=\"company:Manager\""))
        #expect(content.contains("department=\"Engineering\""))

        // Verify enum values are used
        #expect(content.contains("status=\"FULL_TIME\""))
        #expect(content.contains("status=\"PART_TIME\""))
    }

    @Test("Step 8: Validate abstract command exists")
    func testStep08ValidateAbstractCommand() async throws {
        // Load the validate abstract command script
        let validatePath = tutorialResourcesPath.appendingPathComponent("step-23-validate-abstract.sh")

        #expect(FileManager.default.fileExists(atPath: validatePath.path))

        let content = try String(contentsOf: validatePath, encoding: .utf8)

        // Verify command structure
        #expect(content.contains("swift-ecore"))
        #expect(content.contains("validate"))
        #expect(content.contains("Company.ecore"))
        #expect(content.contains("--check-abstract-classes"))
    }

    // MARK: - Comprehensive Validation

    @Test("Tutorial completeness: All steps present")
    func testTutorialCompleteness() async throws {
        // Verify all tutorial files exist
        let steps = [
            "step-14-bidirectional-reference.ecore",  // Starting point
            "step-17-employment-status-enum.ecore",
            "step-18-person-with-status.ecore",
            "step-19-employee-hierarchy.ecore",
            "step-20-inspect-hierarchy.sh",
            "step-21-abstract-person.ecore",
            "step-22-concrete-instances.xmi",
            "step-23-validate-abstract.sh"
        ]

        for step in steps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            #expect(FileManager.default.fileExists(atPath: path.path), "Missing file: \(step)")
        }
    }

    @Test("EEnum progression: No enum → Enum → Enum with usage")
    func testEEnumProgression() async throws {
        // Step 1: No enum
        let step1 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-14-bidirectional-reference.ecore"))
        #expect(!step1.contains("ecore:EEnum"))

        // Step 2: Enum defined but not used
        let step2 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-17-employment-status-enum.ecore"))
        #expect(step2.contains("ecore:EEnum"))
        #expect(step2.contains("name=\"EmploymentStatus\""))
        let step2PersonStart = step2.range(of: "name=\"Person\"")!.upperBound
        let step2PersonEnd = step2.range(of: "name=\"Company\"")!.lowerBound
        let step2PersonSection = String(step2[step2PersonStart..<step2PersonEnd])
        #expect(!step2PersonSection.contains("name=\"status\""))

        // Step 3: Enum used in Person
        let step3 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-18-person-with-status.ecore"))
        let step3PersonStart = step3.range(of: "name=\"Person\"")!.upperBound
        let step3PersonEnd = step3.range(of: "name=\"Company\"")!.lowerBound
        let step3PersonSection = String(step3[step3PersonStart..<step3PersonEnd])
        #expect(step3PersonSection.contains("name=\"status\""))
        #expect(step3PersonSection.contains("eType=\"#//EmploymentStatus\""))
    }

    @Test("Inheritance progression: No hierarchy → Hierarchy → Abstract base")
    func testInheritanceProgression() async throws {
        // Step 1: No Employee/Manager classes
        let step1 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-18-person-with-status.ecore"))
        #expect(!step1.contains("name=\"Employee\""))
        #expect(!step1.contains("name=\"Manager\""))
        #expect(!step1.contains("eSuperTypes"))

        // Step 2: Employee and Manager inherit from Person
        let step2 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-19-employee-hierarchy.ecore"))
        #expect(step2.contains("name=\"Employee\""))
        #expect(step2.contains("name=\"Manager\""))
        let step2SuperTypesCount = step2.components(separatedBy: "eSuperTypes=\"#//Person\"").count - 1
        #expect(step2SuperTypesCount == 2)  // Both Employee and Manager

        // Person should NOT be abstract yet
        #expect(!step2.contains("abstract=\"true\""))

        // Step 3: Person is now abstract
        let step3 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-21-abstract-person.ecore"))
        let step3PersonStart = step3.range(of: "name=\"Person\"")!.lowerBound
        let step3PersonEnd = step3.range(of: "name=\"Employee\"")!.lowerBound
        let step3PersonSection = String(step3[step3PersonStart..<step3PersonEnd])
        #expect(step3PersonSection.contains("abstract=\"true\""))
    }

    @Test("Namespace consistency across all metamodel files")
    func testNamespaceConsistency() async throws {
        let ecoreSteps = [
            "step-17-employment-status-enum.ecore",
            "step-18-person-with-status.ecore",
            "step-19-employee-hierarchy.ecore",
            "step-21-abstract-person.ecore"
        ]

        for step in ecoreSteps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            let content = try String(contentsOf: path, encoding: .utf8)

            // Verify consistent namespace
            #expect(content.contains("name=\"company\""), "Inconsistent package name in \(step)")
            #expect(content.contains("nsURI=\"http://www.example.org/company\""), "Inconsistent nsURI in \(step)")
            #expect(content.contains("nsPrefix=\"company\""), "Inconsistent nsPrefix in \(step)")
        }
    }

    @Test("EEnum structure validation")
    func testEEnumStructure() async throws {
        // Load a metamodel with enum
        let enumPath = tutorialResourcesPath.appendingPathComponent("step-17-employment-status-enum.ecore")
        let content = try String(contentsOf: enumPath, encoding: .utf8)

        // Extract EEnum section
        let enumStart = content.range(of: "xsi:type=\"ecore:EEnum\"")!.lowerBound
        let enumEnd = content.range(of: "</eClassifiers>")!.upperBound
        let enumSection = String(content[enumStart..<enumEnd])

        // Verify structure
        #expect(enumSection.contains("name=\"EmploymentStatus\""))

        // Count literals
        let literalCount = enumSection.components(separatedBy: "<eLiterals").count - 1
        #expect(literalCount == 3)

        // Verify each literal has name and value
        #expect(enumSection.contains("<eLiterals name=\"FULL_TIME\" value=\"0\""))
        #expect(enumSection.contains("<eLiterals name=\"PART_TIME\" value=\"1\""))
        #expect(enumSection.contains("<eLiterals name=\"CONTRACTOR\" value=\"2\""))
    }

    @Test("XMI concrete type validation")
    func testXMIConcreteTypes() async throws {
        let instancePath = tutorialResourcesPath.appendingPathComponent("step-22-concrete-instances.xmi")
        let content = try String(contentsOf: instancePath, encoding: .utf8)

        // Count employee instances (should be 2)
        let employeeCount = content.components(separatedBy: "xsi:type=\"company:Employee\"").count - 1
        #expect(employeeCount == 2)

        // Count manager instances (should be 1)
        let managerCount = content.components(separatedBy: "xsi:type=\"company:Manager\"").count - 1
        #expect(managerCount == 1)

        // Verify enum values in instances
        let fullTimeCount = content.components(separatedBy: "status=\"FULL_TIME\"").count - 1
        #expect(fullTimeCount == 2)  // Two full-time employees

        let partTimeCount = content.components(separatedBy: "status=\"PART_TIME\"").count - 1
        #expect(partTimeCount == 1)  // One part-time employee
    }

    @Test("XML well-formedness of all metamodel files")
    func testXMLWellFormedness() async throws {
        let ecoreSteps = [
            "step-17-employment-status-enum.ecore",
            "step-18-person-with-status.ecore",
            "step-19-employee-hierarchy.ecore",
            "step-21-abstract-person.ecore"
        ]

        for step in ecoreSteps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            let content = try String(contentsOf: path, encoding: .utf8)

            // Verify XML structure
            #expect(content.hasPrefix("<?xml"), "\(step) missing XML declaration")
            #expect(content.contains("encoding=\"UTF-8\""), "\(step) missing UTF-8 encoding")
            #expect(content.contains("<ecore:EPackage"), "\(step) missing root EPackage")
            #expect(content.contains("</ecore:EPackage>"), "\(step) missing closing EPackage tag")
        }
    }
}
