import Testing
import Foundation

/// Test suite for MTL Tutorials
/// Validates each step of all 8 MTL tutorials
@Suite("MTL Tutorials")
struct MTLTutorialTests {

    let tutorialResourcesPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")
        .appendingPathComponent("SwiftModelling")
        .appendingPathComponent("SwiftModelling.docc")
        .appendingPathComponent("Resources")

    // MARK: - Tutorial 01: Hello World Template

    @Test("Tutorial 01: All step files exist")
    func testTutorial01FilesExist() async throws {
        let steps = [
            "mtl-step-01-module.mtl",
            "mtl-step-02-template.mtl",
            "mtl-step-03-content.mtl",
            "mtl-step-04-generate-console.sh",
            "mtl-step-05-generate-file.sh",
            "mtl-step-06-output.txt",
            "mtl-step-07-with-comments.mtl",
            "mtl-step-08-validate.sh"
        ]

        for step in steps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            #expect(FileManager.default.fileExists(atPath: path.path), "Missing: \(step)")
        }
    }

    @Test("Tutorial 01 Step 1: Module declaration")
    func testTutorial01Step01() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-01-module.mtl"), encoding: .utf8)
        #expect(content.contains("[module HelloWorld('http://example.com')]"))
    }

    @Test("Tutorial 01 Step 2: Template definition")
    func testTutorial01Step02() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-02-template.mtl"), encoding: .utf8)
        #expect(content.contains("[template main()]"))
        #expect(content.contains("[/template]"))
    }

    @Test("Tutorial 01 Step 3: Static content")
    func testTutorial01Step03() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-03-content.mtl"), encoding: .utf8)
        #expect(content.contains("Hello, World!"))
        #expect(content.contains("simplest MTL template"))
    }

    @Test("Tutorial 01 Step 7: Comments")
    func testTutorial01Step07() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-07-with-comments.mtl"), encoding: .utf8)
        #expect(content.contains("[comment]"))
        #expect(content.contains("[/comment]"))
    }

    // MARK: - Tutorial 02: Expressions and Variables

    @Test("Tutorial 02: All step files exist")
    func testTutorial02FilesExist() async throws {
        let steps = [
            "mtl-step-09-arithmetic.mtl",
            "mtl-step-10-string-concat.mtl",
            "mtl-step-11-generate-expressions.sh",
            "mtl-step-12-simple-query.mtl",
            "mtl-step-13-call-query.mtl",
            "mtl-step-14-query-params.mtl",
            "mtl-step-15-let-binding.mtl",
            "mtl-step-16-multiple-let.mtl"
        ]

        for step in steps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            #expect(FileManager.default.fileExists(atPath: path.path), "Missing: \(step)")
        }
    }

    @Test("Tutorial 02 Step 1: Arithmetic expressions")
    func testTutorial02Step01() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-09-arithmetic.mtl"), encoding: .utf8)
        #expect(content.contains("[5 + 3/]"))
        #expect(content.contains("[10 - 4/]"))
        #expect(content.contains("[6 * 7/]"))
    }

    @Test("Tutorial 02 Step 2: String concatenation")
    func testTutorial02Step02() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-10-string-concat.mtl"), encoding: .utf8)
        #expect(content.contains("['Hello' + ' ' + 'World'/]"))
    }

    @Test("Tutorial 02 Step 3: Query definition")
    func testTutorial02Step03() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-12-simple-query.mtl"), encoding: .utf8)
        #expect(content.contains("[query getVersion() : String = '1.0.0'/]"))
    }

    @Test("Tutorial 02 Step 4: Query with parameters")
    func testTutorial02Step04() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-14-query-params.mtl"), encoding: .utf8)
        #expect(content.contains("[query square(n : Integer) : Integer"))
        #expect(content.contains("[query fullName(first : String, last : String) : String"))
    }

    @Test("Tutorial 02 Step 5: Let binding")
    func testTutorial02Step05() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-15-let-binding.mtl"), encoding: .utf8)
        #expect(content.contains("[let version = '1.0.0']"))
        #expect(content.contains("[/let]"))
    }

    @Test("Tutorial 02 Step 6: Nested let bindings")
    func testTutorial02Step06() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-16-multiple-let.mtl"), encoding: .utf8)
        #expect(content.contains("[let firstName = 'John']"))
        #expect(content.contains("[let lastName = 'Doe']"))
        #expect(content.contains("[let fullName = firstName + ' ' + lastName]"))
    }

    // MARK: - Tutorial 03: Control Flow

    @Test("Tutorial 03: All step files exist")
    func testTutorial03FilesExist() async throws {
        let steps = [
            "mtl-step-17-simple-if.mtl",
            "mtl-step-18-if-else.mtl",
            "mtl-step-19-elseif.mtl",
            "mtl-step-20-let-if-combo.mtl",
            "mtl-step-21-nested-let.mtl"
        ]

        for step in steps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            #expect(FileManager.default.fileExists(atPath: path.path), "Missing: \(step)")
        }
    }

    @Test("Tutorial 03 Step 1: If statement")
    func testTutorial03Step01() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-17-simple-if.mtl"), encoding: .utf8)
        #expect(content.contains("[if (true)]"))
        #expect(content.contains("[/if]"))
    }

    @Test("Tutorial 03 Step 2: If-else")
    func testTutorial03Step02() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-18-if-else.mtl"), encoding: .utf8)
        #expect(content.contains("[if (false)]"))
        #expect(content.contains("[else]"))
        #expect(content.contains("[/if]"))
    }

    @Test("Tutorial 03 Step 3: ElseIf chain")
    func testTutorial03Step03() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-19-elseif.mtl"), encoding: .utf8)
        #expect(content.contains("[elseif (value < 20)]"))
    }

    // MARK: - Tutorial 04: File Blocks

    @Test("Tutorial 04: All step files exist")
    func testTutorial04FilesExist() async throws {
        let steps = [
            "mtl-step-22-basic-file.mtl",
            "mtl-step-23-multiple-files.mtl",
            "mtl-step-24-generate-files.sh",
            "mtl-step-25-file-modes.mtl"
        ]

        for step in steps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            #expect(FileManager.default.fileExists(atPath: path.path), "Missing: \(step)")
        }
    }

    @Test("Tutorial 04 Step 1: Basic file block")
    func testTutorial04Step01() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-22-basic-file.mtl"), encoding: .utf8)
        #expect(content.contains("[file ('greeting.txt', 'overwrite', 'UTF-8')]"))
        #expect(content.contains("[/file]"))
    }

    @Test("Tutorial 04 Step 2: Multiple file blocks")
    func testTutorial04Step02() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-23-multiple-files.mtl"), encoding: .utf8)
        let fileBlockCount = content.components(separatedBy: "[file (").count - 1
        #expect(fileBlockCount == 2)
    }

    @Test("Tutorial 04 Step 3: File modes")
    func testTutorial04Step03() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-25-file-modes.mtl"), encoding: .utf8)
        #expect(content.contains("'overwrite'"))
        #expect(content.contains("'append'"))
        #expect(content.contains("'create'"))
    }

    // MARK: - Tutorial 05: Queries and Macros

    @Test("Tutorial 05: All step files exist")
    func testTutorial05FilesExist() async throws {
        let steps = [
            "mtl-step-26-math-queries.mtl",
            "mtl-step-27-boolean-queries.mtl",
            "mtl-step-28-simple-macro.mtl",
            "mtl-step-29-use-macro.mtl",
            "mtl-step-30-multiple-macros.mtl"
        ]

        for step in steps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            #expect(FileManager.default.fileExists(atPath: path.path), "Missing: \(step)")
        }
    }

    @Test("Tutorial 05 Step 1: Mathematical queries")
    func testTutorial05Step01() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-26-math-queries.mtl"), encoding: .utf8)
        #expect(content.contains("[query square(n : Integer) : Integer"))
        #expect(content.contains("[query cube(n : Integer) : Integer"))
    }

    @Test("Tutorial 05 Step 2: Boolean queries")
    func testTutorial05Step02() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-27-boolean-queries.mtl"), encoding: .utf8)
        #expect(content.contains("[query isEven(n : Integer) : Boolean"))
    }

    @Test("Tutorial 05 Step 3: Macro definition")
    func testTutorial05Step03() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-28-simple-macro.mtl"), encoding: .utf8)
        #expect(content.contains("[macro section(title : String, content : Body)]"))
        #expect(content.contains("[/macro]"))
    }

    @Test("Tutorial 05 Step 4: Macro usage")
    func testTutorial05Step04() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-29-use-macro.mtl"), encoding: .utf8)
        #expect(content.contains("[codeBlock('swift')]"))
        #expect(content.contains("[/codeBlock]"))
    }

    // MARK: - Tutorial 06: Code Generation from Models

    @Test("Tutorial 06: All step files exist")
    func testTutorial06FilesExist() async throws {
        let steps = [
            "mtl-step-31-metamodel-module.mtl",
            "mtl-step-32-model-template.mtl",
            "mtl-step-33-generate-from-model.sh",
            "mtl-step-34-navigate-refs.mtl",
            "mtl-step-35-iterate-collection.mtl"
        ]

        for step in steps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            #expect(FileManager.default.fileExists(atPath: path.path), "Missing: \(step)")
        }
    }

    @Test("Tutorial 06 Step 1: Metamodel module")
    func testTutorial06Step01() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-31-metamodel-module.mtl"), encoding: .utf8)
        #expect(content.contains("http://www.example.org/company"))
    }

    @Test("Tutorial 06 Step 2: Model template parameter")
    func testTutorial06Step02() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-32-model-template.mtl"), encoding: .utf8)
        #expect(content.contains("[template main(c : Company)]"))
    }

    @Test("Tutorial 06 Step 3: Navigate references")
    func testTutorial06Step03() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-34-navigate-refs.mtl"), encoding: .utf8)
        #expect(content.contains("[c.employees->size()/]"))
    }

    @Test("Tutorial 06 Step 4: Iterate collection")
    func testTutorial06Step04() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-35-iterate-collection.mtl"), encoding: .utf8)
        #expect(content.contains("[for (emp : Person | c.employees)]"))
        #expect(content.contains("[/for]"))
    }

    // MARK: - Tutorial 07: Protected Areas

    @Test("Tutorial 07: All step files exist")
    func testTutorial07FilesExist() async throws {
        let steps = [
            "mtl-step-36-basic-protected.mtl",
            "mtl-step-37-custom-markers.mtl"
        ]

        for step in steps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            #expect(FileManager.default.fileExists(atPath: path.path), "Missing: \(step)")
        }
    }

    @Test("Tutorial 07 Step 1: Basic protected area")
    func testTutorial07Step01() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-36-basic-protected.mtl"), encoding: .utf8)
        #expect(content.contains("[protected ('custom-methods')]"))
        #expect(content.contains("[/protected]"))
    }

    @Test("Tutorial 07 Step 2: Custom markers")
    func testTutorial07Step02() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-37-custom-markers.mtl"), encoding: .utf8)
        #expect(content.contains("[protected ('custom-init', '// START_CUSTOM', '// END_CUSTOM')]"))
    }

    // MARK: - Tutorial 08: Complete Code Generator

    @Test("Tutorial 08: All step files exist")
    func testTutorial08FilesExist() async throws {
        let steps = [
            "mtl-step-38-main-generator.mtl",
            "mtl-step-39-class-helper.mtl",
            "mtl-step-40-generate-project.sh"
        ]

        for step in steps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            #expect(FileManager.default.fileExists(atPath: path.path), "Missing: \(step)")
        }
    }

    @Test("Tutorial 08 Step 1: Main generator")
    func testTutorial08Step01() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-38-main-generator.mtl"), encoding: .utf8)
        #expect(content.contains("[template main(pkg : EPackage)]"))
        #expect(content.contains("[template generateClass(cls : EClass)]"))
    }

    @Test("Tutorial 08 Step 2: Helper template")
    func testTutorial08Step02() async throws {
        let content = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-39-class-helper.mtl"), encoding: .utf8)
        #expect(content.contains("[for (attr : EAttribute | cls.eStructuralFeatures->filter(EAttribute))]"))
    }

    // MARK: - Comprehensive Validation

    @Test("All MTL tutorials: Template syntax validation")
    func testAllMTLTemplatesSyntax() async throws {
        let mtlFiles = try FileManager.default.contentsOfDirectory(at: tutorialResourcesPath, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "mtl" }

        for file in mtlFiles {
            let content = try String(contentsOf: file, encoding: .utf8)

            // Every MTL file should have a module
            #expect(content.contains("[module "), "\(file.lastPathComponent) missing module declaration")

            // Check for balanced brackets (simplified check)
            let openBrackets = content.components(separatedBy: "[").count - 1
            let closeBrackets = content.components(separatedBy: "]").count - 1
            #expect(openBrackets == closeBrackets, "\(file.lastPathComponent) has unbalanced brackets")
        }
    }

    @Test("MTL progression: Complexity increases across tutorials")
    func testMTLComplexityProgression() async throws {
        // Tutorial 01: Simple static text
        let tut01 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-03-content.mtl"), encoding: .utf8)
        #expect(!tut01.contains("[query"))
        #expect(!tut01.contains("[macro"))
        #expect(!tut01.contains("[file"))

        // Tutorial 02: Adds expressions and queries
        let tut02 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-12-simple-query.mtl"), encoding: .utf8)
        #expect(tut02.contains("[query"))

        // Tutorial 03: Adds control flow
        let tut03 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-17-simple-if.mtl"), encoding: .utf8)
        #expect(tut03.contains("[if"))

        // Tutorial 04: Adds file blocks
        let tut04 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-22-basic-file.mtl"), encoding: .utf8)
        #expect(tut04.contains("[file"))

        // Tutorial 05: Adds macros
        let tut05 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-28-simple-macro.mtl"), encoding: .utf8)
        #expect(tut05.contains("[macro"))

        // Tutorial 06: Adds model navigation
        let tut06 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-32-model-template.mtl"), encoding: .utf8)
        #expect(tut06.contains("Company"))

        // Tutorial 07: Adds protected areas
        let tut07 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-36-basic-protected.mtl"), encoding: .utf8)
        #expect(tut07.contains("[protected"))

        // Tutorial 08: Combines everything
        let tut08 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("mtl-step-38-main-generator.mtl"), encoding: .utf8)
        #expect(tut08.contains("[template main(pkg : EPackage)]"))
        #expect(tut08.contains("[file"))
        #expect(tut08.contains("[for"))
    }
}
