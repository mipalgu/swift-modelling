import Testing
import Foundation

/// Test suite for MTL Advanced Tutorial 01: UML to Swift Code Generation
/// Validates the complete code generation pipeline from UML models to Swift source
@Suite("Advanced Tutorial: UML to Swift Code Generation")
struct MTLAdvanced01Tests {

    static let tutorialCodePath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")
        .appendingPathComponent("SwiftModelling")
        .appendingPathComponent("SwiftModelling.docc")
        .appendingPathComponent("Resources")
        .appendingPathComponent("Code")
        .appendingPathComponent("MTL-Advanced-01")

    // MARK: - Section 1: CLI Validation

    @Test("CLI: Validate UML metamodel via swift-ecore")
    @MainActor
    func testCLIValidateUMLMetamodel() async throws {
        let umlEcorePath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("uml-class.ecore")

        #expect(FileManager.default.fileExists(atPath: umlEcorePath.path), "UML metamodel should exist")

        // Use swift-ecore validate to ensure the metamodel can be loaded
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [umlEcorePath.path]
        )

        #expect(result.succeeded, "UML metamodel should validate successfully: \(result.stderr)")
    }

    @Test("CLI: Validate sample UML model via swift-ecore")
    @MainActor
    func testCLIValidateSampleModel() async throws {
        let samplePath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("sample-model.xmi")

        #expect(FileManager.default.fileExists(atPath: samplePath.path), "Sample UML model should exist")

        // Use swift-ecore validate to ensure the model can be loaded
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [samplePath.path]
        )

        #expect(result.succeeded, "Sample UML model should validate successfully: \(result.stderr)")
    }

    // MARK: - Section 2: Validate UML Metamodel Content

    @Test("Content: Validate UML metamodel structure")
    func testStep01ValidateUMLMetamodel() async throws {
        let umlEcorePath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("uml-class.ecore")

        #expect(FileManager.default.fileExists(atPath: umlEcorePath.path))

        let content = try String(contentsOf: umlEcorePath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("ecore:EPackage"))
        #expect(content.contains("name=\"UML\""))
        #expect(content.contains("nsURI=\"http://www.example.org/uml\""))

        // Verify key classes exist
        #expect(content.contains("name=\"Package\""))
        #expect(content.contains("name=\"Class\""))
        #expect(content.contains("name=\"Property\""))
        #expect(content.contains("name=\"Operation\""))
        #expect(content.contains("name=\"Protocol\""))
        #expect(content.contains("name=\"Enumeration\""))
    }

    @Test("Step 1.2: Validate UML metamodel Swift-specific features")
    func testStep02ValidateSwiftFeatures() async throws {
        let umlEcorePath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("uml-class.ecore")
        let content = try String(contentsOf: umlEcorePath, encoding: .utf8)

        // Swift-specific features
        #expect(content.contains("name=\"isStruct\""))
        #expect(content.contains("name=\"isFinal\""))
        #expect(content.contains("name=\"isAsync\""))
        #expect(content.contains("name=\"throws\""))
        #expect(content.contains("name=\"isOptional\""))
        #expect(content.contains("name=\"isCollection\""))

        // Visibility enum with Swift values
        #expect(content.contains("name=\"VisibilityKind\""))
        #expect(content.contains("name=\"public\""))
        #expect(content.contains("name=\"private\""))
        #expect(content.contains("name=\"internal\""))
        #expect(content.contains("name=\"fileprivate\""))
    }

    // MARK: - Section 2: Validate MTL Template

    @Test("Step 2.1: Validate MTL template module")
    func testStep03ValidateMTLModule() async throws {
        let mtlPath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("uml2swift.mtl")

        #expect(FileManager.default.fileExists(atPath: mtlPath.path))

        let content = try String(contentsOf: mtlPath, encoding: .utf8)

        // Verify module declaration
        #expect(content.contains("[module UML2Swift('http://www.example.org/uml')]"))
    }

    @Test("Step 2.2: Validate class generation templates")
    func testStep04ValidateClassTemplates() async throws {
        let mtlPath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("uml2swift.mtl")
        let content = try String(contentsOf: mtlPath, encoding: .utf8)

        // Main entry point
        #expect(content.contains("[template main(pkg : Package)]"))

        // Class generation
        #expect(content.contains("[template generateClassFile(cls : Class)]"))
        #expect(content.contains("[template generateClassDeclaration(cls : Class)]"))
        #expect(content.contains("[template generateInheritance(cls : Class)]"))
        #expect(content.contains("[template generateInitialiser(cls : Class)]"))
    }

    @Test("Step 2.3: Validate property generation templates")
    func testStep05ValidatePropertyTemplates() async throws {
        let mtlPath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("uml2swift.mtl")
        let content = try String(contentsOf: mtlPath, encoding: .utf8)

        #expect(content.contains("[template generateProperty(prop : Property)]"))
        #expect(content.contains("[template generateTypeName(prop : TypedElement)]"))
        #expect(content.contains("[template generateDefaultValue(prop : Property)]"))

        // Check for Swift-specific syntax
        #expect(content.contains("let"))
        #expect(content.contains("var"))
    }

    @Test("Step 2.4: Validate operation generation templates")
    func testStep06ValidateOperationTemplates() async throws {
        let mtlPath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("uml2swift.mtl")
        let content = try String(contentsOf: mtlPath, encoding: .utf8)

        #expect(content.contains("[template generateOperation(op : Operation)]"))
        #expect(content.contains("[template generateParameters(op : Operation)]"))
        #expect(content.contains("[template generateReturnType(op : Operation)]"))

        // Check for async/throws
        #expect(content.contains("async"))
        #expect(content.contains("throws"))
    }

    @Test("Step 2.5: Validate protocol generation templates")
    func testStep07ValidateProtocolTemplates() async throws {
        let mtlPath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("uml2swift.mtl")
        let content = try String(contentsOf: mtlPath, encoding: .utf8)

        #expect(content.contains("[template generateProtocolFile(proto : Protocol)]"))
        #expect(content.contains("protocol"))
        #expect(content.contains("{ get"))
    }

    @Test("Step 2.6: Validate enumeration generation templates")
    func testStep08ValidateEnumTemplates() async throws {
        let mtlPath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("uml2swift.mtl")
        let content = try String(contentsOf: mtlPath, encoding: .utf8)

        #expect(content.contains("[template generateEnumFile(enum : Enumeration)]"))
        #expect(content.contains("enum"))
        #expect(content.contains("case"))
    }

    // MARK: - Section 3: Validate Sample UML Model

    @Test("Step 3.1: Validate sample model structure")
    func testStep09ValidateSampleModel() async throws {
        let samplePath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("sample-model.xmi")

        #expect(FileManager.default.fileExists(atPath: samplePath.path))

        let content = try String(contentsOf: samplePath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("xmi:XMI"))
        #expect(content.contains("uml:Package"))
        #expect(content.contains("name=\"TaskManager\""))
    }

    @Test("Step 3.2: Validate sample model classifiers")
    func testStep10ValidateSampleClassifiers() async throws {
        let samplePath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("sample-model.xmi")
        let content = try String(contentsOf: samplePath, encoding: .utf8)

        // Primitive types
        #expect(content.contains("uml:PrimitiveType"))
        #expect(content.contains("name=\"String\""))
        #expect(content.contains("name=\"Int\""))
        #expect(content.contains("name=\"Bool\""))
        #expect(content.contains("name=\"Date\""))

        // Protocol
        #expect(content.contains("uml:Protocol"))
        #expect(content.contains("name=\"Identifiable\""))
        #expect(content.contains("name=\"TaskRepository\""))

        // Enumerations
        #expect(content.contains("uml:Enumeration"))
        #expect(content.contains("name=\"Priority\""))
        #expect(content.contains("name=\"Status\""))

        // Classes
        #expect(content.contains("uml:Class"))
        #expect(content.contains("name=\"Task\""))
        #expect(content.contains("name=\"Project\""))
    }

    @Test("Step 3.3: Validate Task class properties")
    func testStep11ValidateTaskProperties() async throws {
        let samplePath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("sample-model.xmi")
        let content = try String(contentsOf: samplePath, encoding: .utf8)

        // Task should be a struct
        #expect(content.contains("name=\"Task\"") && content.contains("isStruct=\"true\""))

        // Task properties
        #expect(content.contains("name=\"title\""))
        #expect(content.contains("name=\"description\" isOptional=\"true\""))
        #expect(content.contains("name=\"priority\""))
        #expect(content.contains("name=\"tags\" isCollection=\"true\""))
    }

    // MARK: - Section 4: Validate Expected Output

    @Test("Step 4.1: Validate expected output files exist")
    func testStep12ValidateExpectedFilesExist() async throws {
        let expectedPath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected")

        let expectedFiles = [
            "Identifiable.swift",
            "Priority.swift",
            "Status.swift",
            "Task.swift",
            "Project.swift",
            "TaskRepository.swift"
        ]

        for file in expectedFiles {
            let filePath = expectedPath.appendingPathComponent(file)
            #expect(FileManager.default.fileExists(atPath: filePath.path), "Missing: \(file)")
        }
    }

    @Test("Step 4.2: Validate Identifiable protocol")
    func testStep13ValidateIdentifiable() async throws {
        let filePath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected/Identifiable.swift")
        let content = try String(contentsOf: filePath, encoding: .utf8)

        #expect(content.contains("protocol Identifiable"))
        #expect(content.contains("var id: String { get }"))
        #expect(content.contains("import Foundation"))
    }

    @Test("Step 4.3: Validate Priority enum")
    func testStep14ValidatePriority() async throws {
        let filePath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected/Priority.swift")
        let content = try String(contentsOf: filePath, encoding: .utf8)

        #expect(content.contains("enum Priority: Int"))
        #expect(content.contains("case low = 0"))
        #expect(content.contains("case medium = 1"))
        #expect(content.contains("case high = 2"))
        #expect(content.contains("case critical = 3"))
    }

    @Test("Step 4.4: Validate Status enum")
    func testStep15ValidateStatus() async throws {
        let filePath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected/Status.swift")
        let content = try String(contentsOf: filePath, encoding: .utf8)

        #expect(content.contains("enum Status"))
        #expect(content.contains("case pending"))
        #expect(content.contains("case inProgress"))
        #expect(content.contains("case completed"))
        #expect(content.contains("case cancelled"))
    }

    @Test("Step 4.5: Validate Task struct")
    func testStep16ValidateTask() async throws {
        let filePath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected/Task.swift")
        let content = try String(contentsOf: filePath, encoding: .utf8)

        // Struct declaration with protocol
        #expect(content.contains("struct Task: Identifiable"))

        // Properties
        #expect(content.contains("let id: String"))
        #expect(content.contains("var title: String"))
        #expect(content.contains("var description: String? = nil"))
        #expect(content.contains("var priority: Priority = .medium"))
        #expect(content.contains("var tags: [String] = []"))

        // Initialiser
        #expect(content.contains("init(id: String, title: String)"))

        // Methods
        #expect(content.contains("func isOverdue(currentDate: Date) -> Bool"))
        #expect(content.contains("func markComplete()"))
    }

    @Test("Step 4.6: Validate Project class")
    func testStep17ValidateProject() async throws {
        let filePath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected/Project.swift")
        let content = try String(contentsOf: filePath, encoding: .utf8)

        // Class declaration
        #expect(content.contains("class Project: Identifiable"))

        // Properties
        #expect(content.contains("var tasks: [Task] = []"))
        #expect(content.contains("var isActive: Bool = true"))

        // Async/throws method
        #expect(content.contains("func fetchRemoteTasks() async throws"))
    }

    @Test("Step 4.7: Validate TaskRepository protocol")
    func testStep18ValidateTaskRepository() async throws {
        let filePath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected/TaskRepository.swift")
        let content = try String(contentsOf: filePath, encoding: .utf8)

        #expect(content.contains("protocol TaskRepository"))
        #expect(content.contains("func save(task: Task) throws"))
        #expect(content.contains("func findById(id: String) -> Task?"))
        #expect(content.contains("func findAll() -> [Task]"))
        #expect(content.contains("func delete(id: String) throws"))
    }

    // MARK: - Section 5: Swift Syntax Validation

    @Test("Step 5.1: Validate Swift MARK comments")
    func testStep19ValidateMARKComments() async throws {
        let filePath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected/Task.swift")
        let content = try String(contentsOf: filePath, encoding: .utf8)

        #expect(content.contains("// MARK: - Properties"))
        #expect(content.contains("// MARK: - Initialisation"))
        #expect(content.contains("// MARK: - Methods"))
    }

    @Test("Step 5.2: Validate documentation comments")
    func testStep20ValidateDocumentation() async throws {
        let taskPath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected/Task.swift")
        let taskContent = try String(contentsOf: taskPath, encoding: .utf8)
        #expect(taskContent.contains("/// Represents a task in the system"))

        let priorityPath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected/Priority.swift")
        let priorityContent = try String(contentsOf: priorityPath, encoding: .utf8)
        #expect(priorityContent.contains("/// Task priority levels"))
    }

    @Test("Step 5.3: Validate generated file headers")
    func testStep21ValidateFileHeaders() async throws {
        let expectedPath = MTLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected")
        let files = try FileManager.default.contentsOfDirectory(at: expectedPath, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }

        for file in files {
            let content = try String(contentsOf: file, encoding: .utf8)
            let filename = file.deletingPathExtension().lastPathComponent

            #expect(content.contains("// \(filename).swift"), "Missing header in \(file.lastPathComponent)")
            #expect(content.contains("// Generated from UML model"), "Missing generation comment in \(file.lastPathComponent)")
            #expect(content.contains("import Foundation"), "Missing import in \(file.lastPathComponent)")
        }
    }
}
