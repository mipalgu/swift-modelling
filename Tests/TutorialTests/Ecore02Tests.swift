import Testing
import Foundation

/// Test suite for Ecore Tutorial 02: Working with Model Instances
/// Validates each step of the model instance creation tutorial
@Suite("Tutorial: Working with Model Instances")
struct Ecore02Tests {

    let tutorialResourcesPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")
        .appendingPathComponent("SwiftModelling")
        .appendingPathComponent("SwiftModelling.docc")
        .appendingPathComponent("Resources")

    // MARK: - Section 1: Understanding Model Instances

    @Test("Step 1: Validate metamodel is available")
    func testStep01MetamodelAvailable() async throws {
        // Verify the Company metamodel from Tutorial 01 is available
        let metamodelPath = tutorialResourcesPath.appendingPathComponent("step-04-company-class.ecore")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: metamodelPath.path))

        let content = try String(contentsOf: metamodelPath, encoding: .utf8)

        // Verify it defines Person and Company classes
        #expect(content.contains("name=\"Person\""))
        #expect(content.contains("name=\"Company\""))
        #expect(content.contains("name=\"name\""))
        #expect(content.contains("name=\"email\""))
    }

    @Test("Step 2: Validate empty model structure")
    func testStep02EmptyModel() async throws {
        // Load the empty model
        let emptyModelPath = tutorialResourcesPath.appendingPathComponent("step-07-empty-company-model.xmi")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: emptyModelPath.path))

        let content = try String(contentsOf: emptyModelPath, encoding: .utf8)

        // Verify it's valid XMI
        #expect(content.contains("<?xml"))
        #expect(content.contains("xmi:XMI"))
        #expect(content.contains("xmi:version=\"2.0\""))

        // Verify namespace declaration
        #expect(content.contains("xmlns:xmi=\"http://www.omg.org/XMI\""))
        #expect(content.contains("xmlns:company=\"http://www.example.org/company\""))

        // Verify model is empty (no instances)
        #expect(!content.contains("<company:Person"))
        #expect(!content.contains("<company:Company"))
    }

    // MARK: - Section 2: Creating Model Instances

    @Test("Step 3: Validate Person instance created")
    func testStep03PersonInstance() async throws {
        // Load the model with Person instance
        let personInstancePath = tutorialResourcesPath.appendingPathComponent("step-08-person-instance.xmi")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: personInstancePath.path))

        let content = try String(contentsOf: personInstancePath, encoding: .utf8)

        // Verify XMI structure
        #expect(content.contains("xmi:XMI"))
        #expect(content.contains("xmlns:company=\"http://www.example.org/company\""))

        // Verify Person instance exists
        #expect(content.contains("<company:Person"))
        #expect(content.contains("xmi:id=\"person1\""))

        // Verify Person attributes
        #expect(content.contains("name=\"Alice Johnson\""))
        #expect(content.contains("email=\"alice@example.com\""))

        // Verify only one instance
        let instanceCount = content.components(separatedBy: "<company:Person").count - 1
        #expect(instanceCount == 1)

        // Verify no Company instances
        #expect(!content.contains("<company:Company"))
    }

    @Test("Step 4: Validate multiple instances created")
    func testStep04MultipleInstances() async throws {
        // Load the model with Company and multiple Persons
        let multipleInstancesPath = tutorialResourcesPath.appendingPathComponent("step-09-company-with-employees.xmi")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: multipleInstancesPath.path))

        let content = try String(contentsOf: multipleInstancesPath, encoding: .utf8)

        // Verify Company instance
        #expect(content.contains("<company:Company"))
        #expect(content.contains("xmi:id=\"company1\""))
        #expect(content.contains("name=\"Tech Innovations Ltd\""))

        // Count Company instances (should be 1)
        let companyCount = content.components(separatedBy: "<company:Company").count - 1
        #expect(companyCount == 1)

        // Verify Person instances
        #expect(content.contains("xmi:id=\"person1\""))
        #expect(content.contains("xmi:id=\"person2\""))
        #expect(content.contains("xmi:id=\"person3\""))

        // Count Person instances (should be 3)
        let personCount = content.components(separatedBy: "<company:Person").count - 1
        #expect(personCount == 3)

        // Verify specific person data
        #expect(content.contains("name=\"Alice Johnson\""))
        #expect(content.contains("email=\"alice@techinnovations.com\""))
        #expect(content.contains("name=\"Bob Smith\""))
        #expect(content.contains("email=\"bob@techinnovations.com\""))
        #expect(content.contains("name=\"Carol Williams\""))
        #expect(content.contains("email=\"carol@techinnovations.com\""))
    }

    // MARK: - Section 3: Validating Model Instances

    @Test("Step 5: Validate command script exists")
    func testStep05ValidateCommand() async throws {
        // Load the validate command script
        let validatePath = tutorialResourcesPath.appendingPathComponent("step-10-validate-model.sh")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: validatePath.path))

        let content = try String(contentsOf: validatePath, encoding: .utf8)

        // Verify command structure
        #expect(content.contains("swift-ecore"))
        #expect(content.contains("validate"))
        #expect(content.contains("company-model.xmi"))
        #expect(content.contains("--metamodel"))
        #expect(content.contains("Company.ecore"))
    }

    @Test("Step 6: Query command script exists")
    func testStep06QueryCommand() async throws {
        // Load the query command script
        let queryPath = tutorialResourcesPath.appendingPathComponent("step-11-query-model.sh")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: queryPath.path))

        let content = try String(contentsOf: queryPath, encoding: .utf8)

        // Verify command structure
        #expect(content.contains("swift-ecore"))
        #expect(content.contains("query"))
        #expect(content.contains("company-model.xmi"))
        #expect(content.contains("--metamodel"))
        #expect(content.contains("Company.ecore"))
        #expect(content.contains("--query"))
        #expect(content.contains("list-classes"))
    }

    // MARK: - Comprehensive Validation

    @Test("Tutorial completeness: All steps present")
    func testTutorialCompleteness() async throws {
        // Verify all tutorial files exist
        let steps = [
            "step-04-company-class.ecore",  // From Tutorial 01
            "step-07-empty-company-model.xmi",
            "step-08-person-instance.xmi",
            "step-09-company-with-employees.xmi",
            "step-10-validate-model.sh",
            "step-11-query-model.sh"
        ]

        for step in steps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            #expect(FileManager.default.fileExists(atPath: path.path), "Missing file: \(step)")
        }
    }

    @Test("Model progression: Empty → One Person → Multiple Instances")
    func testModelProgression() async throws {
        // Step 1: Empty model has no instances
        let step1 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-07-empty-company-model.xmi"), encoding: .utf8)
        // Count actual instance elements (not namespace declarations)
        let step1PersonCount = step1.components(separatedBy: "<company:Person").count - 1
        let step1CompanyCount = step1.components(separatedBy: "<company:Company").count - 1
        #expect(step1PersonCount == 0)
        #expect(step1CompanyCount == 0)

        // Step 2: One Person instance, no Company
        let step2 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-08-person-instance.xmi"), encoding: .utf8)
        let step2PersonCount = step2.components(separatedBy: "<company:Person").count - 1
        let step2CompanyCount = step2.components(separatedBy: "<company:Company").count - 1
        #expect(step2PersonCount == 1)
        #expect(step2CompanyCount == 0)

        // Step 3: One Company and three Persons
        let step3 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-09-company-with-employees.xmi"), encoding: .utf8)
        let step3PersonCount = step3.components(separatedBy: "<company:Person").count - 1
        let step3CompanyCount = step3.components(separatedBy: "<company:Company").count - 1
        #expect(step3PersonCount == 3)
        #expect(step3CompanyCount == 1)
    }

    @Test("Namespace consistency across all models")
    func testNamespaceConsistency() async throws {
        let xmiSteps = [
            "step-07-empty-company-model.xmi",
            "step-08-person-instance.xmi",
            "step-09-company-with-employees.xmi"
        ]

        for step in xmiSteps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            let content = try String(contentsOf: path, encoding: .utf8)

            // Verify consistent namespace across all steps
            #expect(content.contains("xmlns:xmi=\"http://www.omg.org/XMI\""), "Missing XMI namespace in \(step)")
            #expect(content.contains("xmlns:company=\"http://www.example.org/company\""), "Missing company namespace in \(step)")
            #expect(content.contains("xmi:version=\"2.0\""), "Wrong XMI version in \(step)")
        }
    }

    @Test("XMI well-formedness of all model files")
    func testXMIWellFormedness() async throws {
        let xmiSteps = [
            "step-07-empty-company-model.xmi",
            "step-08-person-instance.xmi",
            "step-09-company-with-employees.xmi"
        ]

        for step in xmiSteps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            let content = try String(contentsOf: path, encoding: .utf8)

            // Verify XML declaration
            #expect(content.hasPrefix("<?xml"), "\(step) missing XML declaration")

            // Verify encoding
            #expect(content.contains("encoding=\"UTF-8\""), "\(step) missing UTF-8 encoding")

            // Verify root element
            #expect(content.contains("<xmi:XMI"), "\(step) missing root XMI element")
            #expect(content.contains("</xmi:XMI>"), "\(step) missing closing XMI tag")
        }
    }

    @Test("All instances have unique xmi:id values")
    func testUniqueInstanceIDs() async throws {
        let multipleInstancesPath = tutorialResourcesPath.appendingPathComponent("step-09-company-with-employees.xmi")
        let content = try String(contentsOf: multipleInstancesPath, encoding: .utf8)

        // Extract all xmi:id values
        let idPattern = #/xmi:id="([^"]+)"/#
        let matches = content.matches(of: idPattern)
        let ids = matches.map { String($0.1) }

        // Verify we have 4 IDs (1 Company + 3 Persons)
        #expect(ids.count == 4)

        // Verify all IDs are unique
        let uniqueIDs = Set(ids)
        #expect(uniqueIDs.count == ids.count, "Duplicate xmi:id values found")

        // Verify expected IDs
        #expect(ids.contains("company1"))
        #expect(ids.contains("person1"))
        #expect(ids.contains("person2"))
        #expect(ids.contains("person3"))
    }

    @Test("Instance attributes conform to metamodel types")
    func testInstanceAttributeConformance() async throws {
        let personInstancePath = tutorialResourcesPath.appendingPathComponent("step-08-person-instance.xmi")
        let content = try String(contentsOf: personInstancePath, encoding: .utf8)

        // Person should have name (String) and email (String) attributes
        // Extract the Person element
        let personPattern = #/<company:Person[^>]+>/#
        let matches = content.matches(of: personPattern)
        #expect(matches.count == 1)

        let personElement = String(matches[0].0)

        // Verify both required attributes are present
        #expect(personElement.contains("name="), "Person missing name attribute")
        #expect(personElement.contains("email="), "Person missing email attribute")
        #expect(personElement.contains("xmi:id="), "Person missing xmi:id attribute")

        // Verify attribute values are quoted strings
        #expect(personElement.contains("name=\""), "name attribute not properly quoted")
        #expect(personElement.contains("email=\""), "email attribute not properly quoted")
    }

    @Test("Company instances have correct structure")
    func testCompanyInstanceStructure() async throws {
        let multipleInstancesPath = tutorialResourcesPath.appendingPathComponent("step-09-company-with-employees.xmi")
        let content = try String(contentsOf: multipleInstancesPath, encoding: .utf8)

        // Extract the Company element
        let companyPattern = #/<company:Company[^>]+\/?>/#
        let matches = content.matches(of: companyPattern)
        #expect(matches.count == 1)

        let companyElement = String(matches[0].0)

        // Verify Company has name attribute
        #expect(companyElement.contains("name="), "Company missing name attribute")
        #expect(companyElement.contains("xmi:id="), "Company missing xmi:id attribute")

        // Verify Company name value
        #expect(companyElement.contains("name=\"Tech Innovations Ltd\""), "Incorrect company name")
    }
}
