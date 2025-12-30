import Testing
import Foundation

/// Test suite for Ecore Tutorial 01: Creating Your First Ecore Metamodel
/// Validates each step of the Company metamodel tutorial
@Suite("Tutorial: Creating Your First Ecore Metamodel")
struct Ecore01Tests {

    let tutorialResourcesPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")
        .appendingPathComponent("SwiftModelling")
        .appendingPathComponent("SwiftModelling.docc")
        .appendingPathComponent("Resources")

    // MARK: - Section 1: Understanding Ecore Metamodels

    @Test("Step 1: Validate empty package structure")
    func testStep01EmptyPackage() async throws {
        // Load the empty package
        let packagePath = tutorialResourcesPath.appendingPathComponent("step-01-empty-package.ecore")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: packagePath.path))

        // Verify it's valid XMI
        let content = try String(contentsOf: packagePath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("ecore:EPackage"))

        // Verify package metadata
        #expect(content.contains("name=\"company\""))
        #expect(content.contains("nsURI=\"http://www.example.org/company\""))
        #expect(content.contains("nsPrefix=\"company\""))

        // Verify package is empty (no classifiers)
        #expect(!content.contains("eClassifiers"))
    }

    // MARK: - Section 2: Defining Model Classes

    @Test("Step 2: Validate Person class added")
    func testStep02PersonClass() async throws {
        // Load the metamodel with Person class
        let personClassPath = tutorialResourcesPath.appendingPathComponent("step-02-person-class.ecore")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: personClassPath.path))

        let content = try String(contentsOf: personClassPath, encoding: .utf8)

        // Verify package structure
        #expect(content.contains("ecore:EPackage"))
        #expect(content.contains("name=\"company\""))

        // Verify Person class exists
        #expect(content.contains("eClassifiers"))
        #expect(content.contains("xsi:type=\"ecore:EClass\""))
        #expect(content.contains("name=\"Person\""))

        // Verify Person has no attributes yet
        #expect(!content.contains("eStructuralFeatures"))
    }

    @Test("Step 3: Validate Person attributes added")
    func testStep03PersonAttributes() async throws {
        // Load the metamodel with Person attributes
        let attributesPath = tutorialResourcesPath.appendingPathComponent("step-03-person-attributes.ecore")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: attributesPath.path))

        let content = try String(contentsOf: attributesPath, encoding: .utf8)

        // Verify Person class still exists
        #expect(content.contains("name=\"Person\""))

        // Verify structural features exist
        #expect(content.contains("eStructuralFeatures"))

        // Verify name attribute
        #expect(content.contains("xsi:type=\"ecore:EAttribute\""))
        #expect(content.contains("name=\"name\""))
        #expect(content.contains("eType=\"ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString\""))

        // Verify email attribute
        #expect(content.contains("name=\"email\""))

        // Count attributes (should be 2)
        let attributeCount = content.components(separatedBy: "xsi:type=\"ecore:EAttribute\"").count - 1
        #expect(attributeCount == 2)
    }

    @Test("Step 4: Validate Company class added")
    func testStep04CompanyClass() async throws {
        // Load the metamodel with Company class
        let companyPath = tutorialResourcesPath.appendingPathComponent("step-04-company-class.ecore")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: companyPath.path))

        let content = try String(contentsOf: companyPath, encoding: .utf8)

        // Verify both classes exist
        #expect(content.contains("name=\"Person\""))
        #expect(content.contains("name=\"Company\""))

        // Count classes (should be 2)
        let classCount = content.components(separatedBy: "xsi:type=\"ecore:EClass\"").count - 1
        #expect(classCount == 2)

        // Verify Company has name attribute
        let companySection = content.components(separatedBy: "name=\"Company\"").last ?? ""
        #expect(companySection.contains("name=\"name\""))
        #expect(companySection.contains("EString"))

        // Verify Person still has both attributes (name and email)
        #expect(content.contains("name=\"Person\""))
        let personStart = content.range(of: "name=\"Person\"")!.upperBound
        let personEnd = content.range(of: "name=\"Company\"")!.lowerBound
        let personSection = String(content[personStart..<personEnd])
        let personAttributeCount = personSection.components(separatedBy: "xsi:type=\"ecore:EAttribute\"").count - 1
        #expect(personAttributeCount == 2)
    }

    // MARK: - Section 3: Validating Your Metamodel

    @Test("Step 5: Validate command script exists")
    func testStep05ValidateCommand() async throws {
        // Load the validate command script
        let validatePath = tutorialResourcesPath.appendingPathComponent("step-05-validate-command.sh")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: validatePath.path))

        let content = try String(contentsOf: validatePath, encoding: .utf8)

        // Verify command structure
        #expect(content.contains("swift-ecore"))
        #expect(content.contains("validate"))
        #expect(content.contains("Company.ecore"))
    }

    @Test("Step 6: Inspect command script exists")
    func testStep06InspectCommand() async throws {
        // Load the inspect command script
        let inspectPath = tutorialResourcesPath.appendingPathComponent("step-06-inspect-command.sh")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: inspectPath.path))

        let content = try String(contentsOf: inspectPath, encoding: .utf8)

        // Verify command structure
        #expect(content.contains("swift-ecore"))
        #expect(content.contains("inspect"))
        #expect(content.contains("Company.ecore"))
        #expect(content.contains("--detail full"))
    }

    // MARK: - Comprehensive Validation

    @Test("Tutorial completeness: All steps present")
    func testTutorialCompleteness() async throws {
        // Verify all tutorial files exist
        let steps = [
            "step-01-empty-package.ecore",
            "step-02-person-class.ecore",
            "step-03-person-attributes.ecore",
            "step-04-company-class.ecore",
            "step-05-validate-command.sh",
            "step-06-inspect-command.sh"
        ]

        for step in steps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            #expect(FileManager.default.fileExists(atPath: path.path), "Missing file: \(step)")
        }
    }

    @Test("Metamodel progression: Empty → Person → Attributes → Company")
    func testMetamodelProgression() async throws {
        // Step 1: Empty package has no classes
        let step1 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-01-empty-package.ecore"))
        let step1ClassCount = step1.components(separatedBy: "eClassifiers").count - 1
        #expect(step1ClassCount == 0)

        // Step 2: One class (Person), no attributes
        let step2 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-02-person-class.ecore"))
        let step2ClassCount = step2.components(separatedBy: "xsi:type=\"ecore:EClass\"").count - 1
        let step2AttrCount = step2.components(separatedBy: "eStructuralFeatures").count - 1
        #expect(step2ClassCount == 1)
        #expect(step2AttrCount == 0)

        // Step 3: One class (Person), two attributes
        let step3 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-03-person-attributes.ecore"))
        let step3ClassCount = step3.components(separatedBy: "xsi:type=\"ecore:EClass\"").count - 1
        let step3AttrCount = step3.components(separatedBy: "xsi:type=\"ecore:EAttribute\"").count - 1
        #expect(step3ClassCount == 1)
        #expect(step3AttrCount == 2)

        // Step 4: Two classes (Person + Company), three attributes total
        let step4 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-04-company-class.ecore"))
        let step4ClassCount = step4.components(separatedBy: "xsi:type=\"ecore:EClass\"").count - 1
        let step4AttrCount = step4.components(separatedBy: "xsi:type=\"ecore:EAttribute\"").count - 1
        #expect(step4ClassCount == 2)
        #expect(step4AttrCount == 3)
    }

    @Test("Namespace consistency across all steps")
    func testNamespaceConsistency() async throws {
        let ecoreSteps = [
            "step-01-empty-package.ecore",
            "step-02-person-class.ecore",
            "step-03-person-attributes.ecore",
            "step-04-company-class.ecore"
        ]

        for step in ecoreSteps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            let content = try String(contentsOf: path, encoding: .utf8)

            // Verify consistent namespace across all steps
            #expect(content.contains("name=\"company\""), "Inconsistent package name in \(step)")
            #expect(content.contains("nsURI=\"http://www.example.org/company\""), "Inconsistent nsURI in \(step)")
            #expect(content.contains("nsPrefix=\"company\""), "Inconsistent nsPrefix in \(step)")
        }
    }

    @Test("XML well-formedness of all metamodel files")
    func testXMLWellFormedness() async throws {
        let ecoreSteps = [
            "step-01-empty-package.ecore",
            "step-02-person-class.ecore",
            "step-03-person-attributes.ecore",
            "step-04-company-class.ecore"
        ]

        for step in ecoreSteps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            let content = try String(contentsOf: path, encoding: .utf8)

            // Verify XML declaration
            #expect(content.hasPrefix("<?xml"), "\(step) missing XML declaration")

            // Verify encoding
            #expect(content.contains("encoding=\"UTF-8\""), "\(step) missing UTF-8 encoding")

            // Verify root element
            #expect(content.contains("<ecore:EPackage"), "\(step) missing root EPackage")
            #expect(content.contains("</ecore:EPackage>"), "\(step) missing closing EPackage tag")

            // Verify namespace declarations
            #expect(content.contains("xmlns:xmi=\"http://www.omg.org/XMI\""), "\(step) missing XMI namespace")
            #expect(content.contains("xmlns:ecore=\"http://www.eclipse.org/emf/2002/Ecore\""), "\(step) missing Ecore namespace")
        }
    }
}
