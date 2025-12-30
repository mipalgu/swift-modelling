import Testing
import Foundation

/// Test suite for Ecore Tutorial 05: JSON and XMI Formats
/// Validates each step of the format conversion tutorial
@Suite("Tutorial: JSON and XMI Formats")
struct Ecore05Tests {

    let tutorialResourcesPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")
        .appendingPathComponent("SwiftModelling")
        .appendingPathComponent("SwiftModelling.docc")
        .appendingPathComponent("Resources")

    // MARK: - Section 1: Understanding Serialisation Formats

    @Test("Step 1: Validate starting XMI model")
    func testStep01StartingXMIModel() async throws {
        // Verify we start with the XMI model from Tutorial 04
        let startingPath = tutorialResourcesPath.appendingPathComponent("step-22-concrete-instances.xmi")

        #expect(FileManager.default.fileExists(atPath: startingPath.path))

        let content = try String(contentsOf: startingPath, encoding: .utf8)

        // Verify XMI structure
        #expect(content.contains("xmi:XMI"))
        #expect(content.contains("xmlns:company=\"http://www.example.org/company\""))

        // Verify Employee and Manager instances
        #expect(content.contains("xsi:type=\"company:Employee\""))
        #expect(content.contains("xsi:type=\"company:Manager\""))
        #expect(content.contains("employeeId=\"E001\""))
        #expect(content.contains("department=\"Engineering\""))
    }

    @Test("Step 2: Convert to JSON command exists")
    func testStep02ConvertToJSONCommand() async throws {
        // Load the convert to JSON command script
        let convertPath = tutorialResourcesPath.appendingPathComponent("step-24-convert-to-json.sh")

        #expect(FileManager.default.fileExists(atPath: convertPath.path))

        let content = try String(contentsOf: convertPath, encoding: .utf8)

        // Verify command structure
        #expect(content.contains("swift-ecore"))
        #expect(content.contains("convert"))
        #expect(content.contains("company-model.xmi"))
        #expect(content.contains("company-model.json"))
    }

    @Test("Step 3: Validate JSON representation")
    func testStep03JSONRepresentation() async throws {
        // Load the JSON model
        let jsonPath = tutorialResourcesPath.appendingPathComponent("step-25-company-model.json")

        #expect(FileManager.default.fileExists(atPath: jsonPath.path))

        let content = try String(contentsOf: jsonPath, encoding: .utf8)

        // Verify JSON structure markers
        #expect(content.contains("\"$type\""))
        #expect(content.contains("\"$id\""))

        // Verify Company element
        #expect(content.contains("\"$type\": \"company:Company\""))
        #expect(content.contains("\"$id\": \"company1\""))
        #expect(content.contains("\"name\": \"Tech Innovations Ltd\""))

        // Verify employees array
        #expect(content.contains("\"employees\""))

        // Verify Employee instances in JSON
        #expect(content.contains("\"$type\": \"company:Employee\""))
        #expect(content.contains("\"employeeId\": \"E001\""))
        #expect(content.contains("\"employeeId\": \"E002\""))

        // Verify Manager instance in JSON
        #expect(content.contains("\"$type\": \"company:Manager\""))
        #expect(content.contains("\"department\": \"Engineering\""))

        // Verify enum values
        #expect(content.contains("\"status\": \"FULL_TIME\""))
        #expect(content.contains("\"status\": \"PART_TIME\""))
    }

    // MARK: - Section 2: Converting Between Formats

    @Test("Step 4: Convert to XMI command exists")
    func testStep04ConvertToXMICommand() async throws {
        // Load the convert to XMI command script
        let convertPath = tutorialResourcesPath.appendingPathComponent("step-26-convert-to-xmi.sh")

        #expect(FileManager.default.fileExists(atPath: convertPath.path))

        let content = try String(contentsOf: convertPath, encoding: .utf8)

        // Verify command structure
        #expect(content.contains("swift-ecore"))
        #expect(content.contains("convert"))
        #expect(content.contains("company-model.json"))
        #expect(content.contains("company-roundtrip.xmi"))
    }

    @Test("Step 5: Compare roundtrip command exists")
    func testStep05CompareRoundtripCommand() async throws {
        // Load the compare roundtrip command script
        let comparePath = tutorialResourcesPath.appendingPathComponent("step-27-compare-roundtrip.sh")

        #expect(FileManager.default.fileExists(atPath: comparePath.path))

        let content = try String(contentsOf: comparePath, encoding: .utf8)

        // Verify command structure
        #expect(content.contains("diff"))
        #expect(content.contains("company-model.xmi"))
        #expect(content.contains("company-roundtrip.xmi"))
    }

    // MARK: - Section 3: Format Trade-offs and Best Practices

    @Test("Step 6: Validate JSON command exists")
    func testStep06ValidateJSONCommand() async throws {
        // Load the validate JSON command script
        let validatePath = tutorialResourcesPath.appendingPathComponent("step-28-validate-json.sh")

        #expect(FileManager.default.fileExists(atPath: validatePath.path))

        let content = try String(contentsOf: validatePath, encoding: .utf8)

        // Verify command structure
        #expect(content.contains("swift-ecore"))
        #expect(content.contains("validate"))
        #expect(content.contains("company-model.json"))
        #expect(content.contains("--metamodel"))
        #expect(content.contains("Company.ecore"))
    }

    @Test("Step 7: Inspect JSON command exists")
    func testStep07InspectJSONCommand() async throws {
        // Load the inspect JSON command script
        let inspectPath = tutorialResourcesPath.appendingPathComponent("step-29-inspect-json.sh")

        #expect(FileManager.default.fileExists(atPath: inspectPath.path))

        let content = try String(contentsOf: inspectPath, encoding: .utf8)

        // Verify command structure
        #expect(content.contains("swift-ecore"))
        #expect(content.contains("inspect"))
        #expect(content.contains("company-model.json"))
        #expect(content.contains("--detail full"))
    }

    @Test("Step 8: Batch convert command exists")
    func testStep08BatchConvertCommand() async throws {
        // Load the batch convert command script
        let batchPath = tutorialResourcesPath.appendingPathComponent("step-30-batch-convert.sh")

        #expect(FileManager.default.fileExists(atPath: batchPath.path))

        let content = try String(contentsOf: batchPath, encoding: .utf8)

        // Verify command structure
        #expect(content.contains("for file in *.xmi"))
        #expect(content.contains("swift-ecore convert"))
        #expect(content.contains("${file%.xmi}.json"))
    }

    // MARK: - Comprehensive Validation

    @Test("Tutorial completeness: All steps present")
    func testTutorialCompleteness() async throws {
        // Verify all tutorial files exist
        let steps = [
            "step-22-concrete-instances.xmi",  // Starting point
            "step-24-convert-to-json.sh",
            "step-25-company-model.json",
            "step-26-convert-to-xmi.sh",
            "step-27-compare-roundtrip.sh",
            "step-28-validate-json.sh",
            "step-29-inspect-json.sh",
            "step-30-batch-convert.sh"
        ]

        for step in steps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            #expect(FileManager.default.fileExists(atPath: path.path), "Missing file: \(step)")
        }
    }

    @Test("JSON format structure validation")
    func testJSONFormatStructure() async throws {
        let jsonPath = tutorialResourcesPath.appendingPathComponent("step-25-company-model.json")
        let content = try String(contentsOf: jsonPath, encoding: .utf8)

        // Verify it's valid JSON by attempting to parse
        let data = content.data(using: .utf8)!
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])

        // Verify root is a dictionary
        #expect(jsonObject is [String: Any])

        let root = jsonObject as! [String: Any]

        // Verify required top-level fields
        #expect(root["$type"] as? String == "company:Company")
        #expect(root["$id"] as? String == "company1")
        #expect(root["name"] as? String == "Tech Innovations Ltd")
        #expect(root["employees"] is [Any])

        let employees = root["employees"] as! [Any]
        #expect(employees.count == 3)
    }

    @Test("JSON to XMI semantic equivalence")
    func testJSONToXMISemanticEquivalence() async throws {
        // Load both formats
        let xmiPath = tutorialResourcesPath.appendingPathComponent("step-22-concrete-instances.xmi")
        let jsonPath = tutorialResourcesPath.appendingPathComponent("step-25-company-model.json")

        let xmiContent = try String(contentsOf: xmiPath, encoding: .utf8)
        let jsonContent = try String(contentsOf: jsonPath, encoding: .utf8)

        // Verify same company name in both
        #expect(xmiContent.contains("name=\"Tech Innovations Ltd\""))
        #expect(jsonContent.contains("\"name\": \"Tech Innovations Ltd\""))

        // Verify same employee IDs in both
        #expect(xmiContent.contains("employeeId=\"E001\""))
        #expect(jsonContent.contains("\"employeeId\": \"E001\""))

        #expect(xmiContent.contains("employeeId=\"E002\""))
        #expect(jsonContent.contains("\"employeeId\": \"E002\""))

        // Verify same department in both
        #expect(xmiContent.contains("department=\"Engineering\""))
        #expect(jsonContent.contains("\"department\": \"Engineering\""))

        // Verify same status values in both
        #expect(xmiContent.contains("status=\"FULL_TIME\""))
        #expect(jsonContent.contains("\"status\": \"FULL_TIME\""))

        #expect(xmiContent.contains("status=\"PART_TIME\""))
        #expect(jsonContent.contains("\"status\": \"PART_TIME\""))
    }

    @Test("JSON type markers consistency")
    func testJSONTypeMarkersConsistency() async throws {
        let jsonPath = tutorialResourcesPath.appendingPathComponent("step-25-company-model.json")
        let content = try String(contentsOf: jsonPath, encoding: .utf8)

        // Count type markers (should be 4: 1 Company + 2 Employee + 1 Manager)
        let typeCount = content.components(separatedBy: "\"$type\"").count - 1
        #expect(typeCount == 4)

        // Count ID markers (should be 4: same as types)
        let idCount = content.components(separatedBy: "\"$id\"").count - 1
        #expect(idCount == 4)

        // Verify specific types
        #expect(content.contains("\"$type\": \"company:Company\""))
        #expect(content.contains("\"$type\": \"company:Employee\""))
        #expect(content.contains("\"$type\": \"company:Manager\""))
    }

    @Test("Conversion command bidirectionality")
    func testConversionCommandBidirectionality() async throws {
        // Load both conversion commands
        let toJsonPath = tutorialResourcesPath.appendingPathComponent("step-24-convert-to-json.sh")
        let toXmiPath = tutorialResourcesPath.appendingPathComponent("step-26-convert-to-xmi.sh")

        let toJsonContent = try String(contentsOf: toJsonPath, encoding: .utf8)
        let toXmiContent = try String(contentsOf: toXmiPath, encoding: .utf8)

        // Both should use the convert command
        #expect(toJsonContent.contains("swift-ecore convert"))
        #expect(toXmiContent.contains("swift-ecore convert"))

        // Verify XMI → JSON direction
        #expect(toJsonContent.contains(".xmi"))
        #expect(toJsonContent.contains(".json"))

        // Verify JSON → XMI direction
        #expect(toXmiContent.contains(".json"))
        #expect(toXmiContent.contains(".xmi"))
    }

    @Test("Format-agnostic command validation")
    func testFormatAgnosticCommandValidation() async throws {
        // Load validation and inspection commands
        let validatePath = tutorialResourcesPath.appendingPathComponent("step-28-validate-json.sh")
        let inspectPath = tutorialResourcesPath.appendingPathComponent("step-29-inspect-json.sh")

        let validateContent = try String(contentsOf: validatePath, encoding: .utf8)
        let inspectContent = try String(contentsOf: inspectPath, encoding: .utf8)

        // Both should work with JSON files
        #expect(validateContent.contains("company-model.json"))
        #expect(inspectContent.contains("company-model.json"))

        // Validate should reference metamodel
        #expect(validateContent.contains("--metamodel"))
        #expect(validateContent.contains("Company.ecore"))

        // Inspect should show full detail
        #expect(inspectContent.contains("--detail full"))
    }
}
