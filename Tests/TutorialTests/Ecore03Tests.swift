import Testing
import Foundation

/// Test suite for Ecore Tutorial 03: Metamodel Relationships
/// Validates each step of the EReference and relationship tutorial
@Suite("Tutorial: Metamodel Relationships")
struct Ecore03Tests {

    let tutorialResourcesPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")
        .appendingPathComponent("SwiftModelling")
        .appendingPathComponent("SwiftModelling.docc")
        .appendingPathComponent("Resources")

    // MARK: - Section 1: Understanding EReference

    @Test("Step 1: Validate starting metamodel")
    func testStep01StartingMetamodel() async throws {
        // Verify we start with the Company metamodel from Tutorial 01
        let startingPath = tutorialResourcesPath.appendingPathComponent("step-04-company-class.ecore")

        #expect(FileManager.default.fileExists(atPath: startingPath.path))

        let content = try String(contentsOf: startingPath, encoding: .utf8)

        // Verify both classes exist
        #expect(content.contains("name=\"Person\""))
        #expect(content.contains("name=\"Company\""))

        // Verify no references yet
        #expect(!content.contains("ecore:EReference"))
        #expect(!content.contains("eType=\"#//"))
    }

    @Test("Step 2: Validate employees reference added")
    func testStep02EmployeesReference() async throws {
        // Load the metamodel with employees reference
        let refPath = tutorialResourcesPath.appendingPathComponent("step-12-company-with-employees-ref.ecore")

        #expect(FileManager.default.fileExists(atPath: refPath.path))

        let content = try String(contentsOf: refPath, encoding: .utf8)

        // Verify Company class still has name attribute
        #expect(content.contains("name=\"Company\""))
        #expect(content.contains("ecore:EAttribute"))

        // Verify EReference exists
        #expect(content.contains("ecore:EReference"))
        #expect(content.contains("name=\"employees\""))

        // Verify reference properties
        #expect(content.contains("upperBound=\"-1\""))  // Unlimited
        #expect(content.contains("eType=\"#//Person\""))  // References Person

        // Verify NOT containment yet
        #expect(!content.contains("containment=\"true\""))
    }

    // MARK: - Section 2: Containment References

    @Test("Step 3: Validate containment reference")
    func testStep03ContainmentReference() async throws {
        // Load the metamodel with containment
        let containmentPath = tutorialResourcesPath.appendingPathComponent("step-13-containment-reference.ecore")

        #expect(FileManager.default.fileExists(atPath: containmentPath.path))

        let content = try String(contentsOf: containmentPath, encoding: .utf8)

        // Verify reference still exists
        #expect(content.contains("name=\"employees\""))
        #expect(content.contains("eType=\"#//Person\""))
        #expect(content.contains("upperBound=\"-1\""))

        // Verify containment is now true
        #expect(content.contains("containment=\"true\""))
    }

    @Test("Step 4: Validate containment instance structure")
    func testStep04ContainmentInstance() async throws {
        // Load the model instance with containment
        let instancePath = tutorialResourcesPath.appendingPathComponent("step-15-containment-instance.xmi")

        #expect(FileManager.default.fileExists(atPath: instancePath.path))

        let content = try String(contentsOf: instancePath, encoding: .utf8)

        // Verify XMI structure
        #expect(content.contains("xmi:XMI"))
        #expect(content.contains("xmlns:company=\"http://www.example.org/company\""))

        // Verify Company element
        #expect(content.contains("<company:Company"))
        #expect(content.contains("xmi:id=\"company1\""))
        #expect(content.contains("name=\"Tech Innovations Ltd\""))

        // Verify Person elements are nested inside Company (containment)
        let companyStart = content.range(of: "<company:Company")!.lowerBound
        let companyEnd = content.range(of: "</company:Company>")!.upperBound
        let companySection = String(content[companyStart..<companyEnd])

        // Check all three employees are nested
        #expect(companySection.contains("<employees"))
        let employeeCount = companySection.components(separatedBy: "<employees").count - 1
        #expect(employeeCount == 3)

        // Verify employee data
        #expect(companySection.contains("xmi:id=\"person1\""))
        #expect(companySection.contains("name=\"Alice Johnson\""))
        #expect(companySection.contains("xmi:id=\"person2\""))
        #expect(companySection.contains("name=\"Bob Smith\""))
        #expect(companySection.contains("xmi:id=\"person3\""))
        #expect(companySection.contains("name=\"Carol Williams\""))
    }

    // MARK: - Section 3: Bidirectional References

    @Test("Step 5: Validate bidirectional reference")
    func testStep05BidirectionalReference() async throws {
        // Load the metamodel with bidirectional references
        let bidirectionalPath = tutorialResourcesPath.appendingPathComponent("step-14-bidirectional-reference.ecore")

        #expect(FileManager.default.fileExists(atPath: bidirectionalPath.path))

        let content = try String(contentsOf: bidirectionalPath, encoding: .utf8)

        // Verify Company → Person reference (employees)
        #expect(content.contains("name=\"employees\""))
        #expect(content.contains("upperBound=\"-1\""))
        #expect(content.contains("eType=\"#//Person\""))
        #expect(content.contains("containment=\"true\""))

        // Verify Company's employees has eOpposite
        let companySection = content.components(separatedBy: "name=\"Company\"")[1]
        #expect(companySection.contains("eOpposite=\"#//Person/employer\""))

        // Verify Person → Company reference (employer)
        let personStart = content.range(of: "name=\"Person\"")!.upperBound
        let personEnd = content.range(of: "name=\"Company\"")!.lowerBound
        let personSection = String(content[personStart..<personEnd])

        #expect(personSection.contains("name=\"employer\""))
        #expect(personSection.contains("eType=\"#//Company\""))
        #expect(personSection.contains("eOpposite=\"#//Company/employees\""))

        // Verify Person's employer is NOT containment (only check in Person section)
        #expect(!personSection.contains("containment=\"true\""))
    }

    @Test("Step 6: Inspect references command exists")
    func testStep06InspectReferencesCommand() async throws {
        // Load the inspect command script
        let inspectPath = tutorialResourcesPath.appendingPathComponent("step-16-inspect-references.sh")

        #expect(FileManager.default.fileExists(atPath: inspectPath.path))

        let content = try String(contentsOf: inspectPath, encoding: .utf8)

        // Verify command structure
        #expect(content.contains("swift-ecore"))
        #expect(content.contains("inspect"))
        #expect(content.contains("Company.ecore"))
        #expect(content.contains("--detail full"))
        #expect(content.contains("--show-references"))
    }

    // MARK: - Comprehensive Validation

    @Test("Tutorial completeness: All steps present")
    func testTutorialCompleteness() async throws {
        // Verify all tutorial files exist
        let steps = [
            "step-04-company-class.ecore",  // Starting point
            "step-12-company-with-employees-ref.ecore",
            "step-13-containment-reference.ecore",
            "step-14-bidirectional-reference.ecore",
            "step-15-containment-instance.xmi",
            "step-16-inspect-references.sh"
        ]

        for step in steps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            #expect(FileManager.default.fileExists(atPath: path.path), "Missing file: \(step)")
        }
    }

    @Test("Reference progression: No refs → Simple ref → Containment → Bidirectional")
    func testReferenceProgression() async throws {
        // Step 1: No references
        let step1 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-04-company-class.ecore"), encoding: .utf8)
        let step1RefCount = step1.components(separatedBy: "ecore:EReference").count - 1
        #expect(step1RefCount == 0)

        // Step 2: One reference (employees), not containment
        let step2 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-12-company-with-employees-ref.ecore"), encoding: .utf8)
        let step2RefCount = step2.components(separatedBy: "ecore:EReference").count - 1
        let step2Containment = step2.contains("containment=\"true\"")
        #expect(step2RefCount == 1)
        #expect(!step2Containment)

        // Step 3: One reference, now with containment
        let step3 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-13-containment-reference.ecore"), encoding: .utf8)
        let step3RefCount = step3.components(separatedBy: "ecore:EReference").count - 1
        let step3Containment = step3.contains("containment=\"true\"")
        #expect(step3RefCount == 1)
        #expect(step3Containment)

        // Step 4: Two references (bidirectional), one with containment
        let step4 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-14-bidirectional-reference.ecore"), encoding: .utf8)
        let step4RefCount = step4.components(separatedBy: "ecore:EReference").count - 1
        let step4OppositeCount = step4.components(separatedBy: "eOpposite=").count - 1
        #expect(step4RefCount == 2)
        #expect(step4OppositeCount == 2)  // Both sides have eOpposite
    }

    @Test("Namespace consistency across all files")
    func testNamespaceConsistency() async throws {
        let ecoreSteps = [
            "step-12-company-with-employees-ref.ecore",
            "step-13-containment-reference.ecore",
            "step-14-bidirectional-reference.ecore"
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

    @Test("EReference attributes validation")
    func testEReferenceAttributes() async throws {
        // Load the employees reference metamodel
        let refPath = tutorialResourcesPath.appendingPathComponent("step-12-company-with-employees-ref.ecore")
        let content = try String(contentsOf: refPath, encoding: .utf8)

        // Extract the EReference element
        let refPattern = #/name="employees"[^>]+/#
        let matches = content.matches(of: refPattern)
        #expect(matches.count == 1)

        let refElement = String(matches[0].0)

        // Verify required attributes
        #expect(refElement.contains("upperBound="), "Missing upperBound attribute")
        #expect(refElement.contains("eType="), "Missing eType attribute")

        // Verify correct values
        #expect(refElement.contains("upperBound=\"-1\""), "Incorrect upperBound")
        #expect(refElement.contains("eType=\"#//Person\""), "Incorrect eType")
    }

    @Test("Containment affects XMI structure")
    func testContainmentXMIStructure() async throws {
        let instancePath = tutorialResourcesPath.appendingPathComponent("step-15-containment-instance.xmi")
        let content = try String(contentsOf: instancePath, encoding: .utf8)

        // With containment, Person elements should be nested inside Company
        // Not at the root level like in step-09-company-with-employees.xmi

        // Count top-level Company elements (should be 1)
        // Normalize line endings for cross-platform compatibility
        let normalizedContent = content.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalizedContent.components(separatedBy: "\n")
        let topLevelCompanies = lines.filter { $0.trimmingCharacters(in: .whitespaces).starts(with: "<company:Company") }.count
        #expect(topLevelCompanies == 1)

        // Count top-level Person elements (should be 0 with containment)
        let topLevelPersons = lines.filter { $0.trimmingCharacters(in: .whitespaces).starts(with: "<company:Person") }.count
        #expect(topLevelPersons == 0)

        // Verify employees are children of Company (indented)
        let employeeLines = lines.filter { $0.contains("<employees") }
        #expect(employeeLines.count == 3)

        // All employee lines should be indented (not at column 0)
        for line in employeeLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            #expect(line.count > trimmed.count, "Employee not indented (not contained)")
        }
    }

    @Test("Bidirectional eOpposite symmetry")
    func testBidirectionalSymmetry() async throws {
        let bidirectionalPath = tutorialResourcesPath.appendingPathComponent("step-14-bidirectional-reference.ecore")
        let content = try String(contentsOf: bidirectionalPath, encoding: .utf8)

        // Company.employees should reference Person.employer
        #expect(content.contains("name=\"employees\""))
        #expect(content.contains("eOpposite=\"#//Person/employer\""))

        // Person.employer should reference Company.employees
        #expect(content.contains("name=\"employer\""))
        #expect(content.contains("eOpposite=\"#//Company/employees\""))

        // Verify the references point to each other symmetrically
        let companyToPersonRef = content.range(of: "name=\"employees\"")!
        let personToCompanyRef = content.range(of: "name=\"employer\"")!

        // Both should exist
        #expect(companyToPersonRef.lowerBound < content.endIndex)
        #expect(personToCompanyRef.lowerBound < content.endIndex)
    }

    @Test("XML well-formedness of all metamodel files")
    func testXMLWellFormedness() async throws {
        let ecoreSteps = [
            "step-12-company-with-employees-ref.ecore",
            "step-13-containment-reference.ecore",
            "step-14-bidirectional-reference.ecore"
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
