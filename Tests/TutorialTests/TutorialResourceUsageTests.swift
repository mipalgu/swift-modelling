//
// TutorialResourceUsageTests.swift
// TutorialTests
//
// Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests of the rules that decide whether a resource of the catalogue is used.
@Suite("Tutorial resource usage rules")
struct TutorialResourceUsageTests {
    @Test("Names lose their scale and appearance variants and keep their extension")
    func variants() {
        #expect(TutorialResourceUsage.stemAndExtension(of: "chart~dark@2x.png") == ("chart", "png"))
        #expect(TutorialResourceUsage.stemAndExtension(of: "chart@2x~dark.png") == ("chart", "png"))
        #expect(TutorialResourceUsage.stemAndExtension(of: "chart") == ("chart", ""))
        #expect(TutorialResourceUsage.stemAndExtension(of: "model.xmi") == ("model", "xmi"))
    }

    @Test("A reference names a file exactly, by stem, or through a variant")
    func referenceMatching() {
        #expect(TutorialResourceUsage.reference("chart.svg", names: "chart.svg"))
        #expect(TutorialResourceUsage.reference("chart.svg", names: "chart~dark.svg"))
        #expect(TutorialResourceUsage.reference("chart", names: "chart@2x.png"))
        #expect(!TutorialResourceUsage.reference("chart.svg", names: "chart.png"))
        #expect(!TutorialResourceUsage.reference("chart", names: "chart-old.svg"))
    }

    @Test("Directive arguments and Markdown images are references")
    func directiveReferences() {
        let text = """
            @Image(source: "chart", alt: "A chart")
            @Code(name: "Model.ecore", file: step-01.ecore, previousFile: step-00.ecore)
            @Video(source: clip.mp4, poster: clip-poster.png)
            ![A figure](figure.png)
            """
        #expect(
            TutorialResourceUsage.directiveReferences(in: text)
                == ["chart", "step-01.ecore", "step-00.ecore", "clip.mp4", "clip-poster.png", "figure.png"])
    }

    @Test("Content tokens hold file names and the names in relative paths")
    func contentTokens() {
        let tokens = TutorialResourceUsage.contentTokens(
            in: "diff out.swift expected/Project.swift.\n-- @path F=/Families/Families.ecore\nhref=\"a.ecore#//X\"")
        #expect(tokens.isSuperset(of: ["out.swift", "Project.swift", "Families.ecore", "a.ecore"]))
        #expect(!tokens.contains("Project.swift."))
    }

    @Test("Unused resources are found after direct, transitive and Graphviz uses")
    func unusedResources() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("Example.docc")
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }
        let files: [String: String] = [
            "Tutorials/Series/Steps.tutorial": """
                @Tutorial(time: 1) {
                    @Intro(title: "Example") { @Image(source: "diagram", alt: "Diagram") }
                    @Code(name: "Terminal", file: run.sh)
                }
                """,
            "Example.md": "# Example\n\n@Image(source: overview.svg, alt: \"Overview\")\n",
            "Resources/Code/run.sh": "swift-mtl generate Gen.mtl\ndiff out.swift expected/Project.swift\n",
            "Resources/Code/expected/Project.swift": "// Generated from helper.txt\n",
            "Resources/Code/helper.txt": "no further references\n",
            "Resources/diagram.svg": "<svg/>",
            "Resources/diagram~dark.svg": "<svg/>",
            "Resources/diagram.dot": "digraph { a -> b }",
            "Resources/overview.svg": "<svg/>",
            "Resources/orphan.svg": "<svg/>",
            "Resources/orphan.dot": "digraph { }",
            "Resources/unused-instance.xmi": "<xmi/>",
            "Resources/notes.md": "@Image(source: orphan.svg, alt: \"Only an unused resource shows this\")\n",
        ]
        for (path, text) in files {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try text.write(to: url, atomically: true, encoding: .utf8)
        }

        let unused = try TutorialResourceUsage.unusedResources(inCatalogue: root, exceptions: [:])

        #expect(unused == ["notes.md", "orphan.dot", "orphan.svg", "unused-instance.xmi"])
        let excepted = try TutorialResourceUsage.unusedResources(
            inCatalogue: root, exceptions: ["unused-instance.xmi": "Read by a test fixture"])
        #expect(excepted == ["notes.md", "orphan.dot", "orphan.svg"])
    }
}
