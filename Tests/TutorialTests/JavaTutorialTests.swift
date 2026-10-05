import Foundation
import Testing

/// The reason that the tests of the extended library example are skipped.
private let referenceRootReason =
    "EMF_REFERENCE_ROOT is not set; skipping the tests that run the tutorials on the extended library example"

/// The reason that the tests that compile Java are skipped.
private let compileReason =
    "EMF_RUNTIME_CLASSPATH is not set (Scripts/fetch-emf-runtime.sh prints it); skipping the compile test"

/// The reason that the tests that run shell snippets are skipped.
private let shellReason = "the shell snippets of the tutorials need /bin/sh"

/// Whether a Java compiler is on the search path.
private var javacAvailable: Bool {
    let search = ProcessInfo.processInfo.environment["PATH"] ?? ""
    return search.split(separator: ":").contains {
        FileManager.default.isExecutableFile(atPath: "\($0)/javac")
    }
}

/// The class path of the EMF runtime that the environment names, if any.
private var runtimeClassPath: String? {
    ProcessInfo.processInfo.environment["EMF_RUNTIME_CLASSPATH"].flatMap { $0.isEmpty ? nil : $0 }
}

/// Replaces the text of a Java member, from the start of its documentation comment to its closing brace.
///
/// - Parameters:
///   - text: The Java source.
///   - signature: The signature line of the member, without indentation.
///   - replacement: The new text of the member, including its comment.
/// - Returns: The source with the member replaced, or nil if the member was not found.
private func replacingMember(in text: String, signature: String, with replacement: String) -> String? {
    var lines = text.components(separatedBy: "\n")
    guard let signatureIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == signature }),
        let start = lines[..<signatureIndex].lastIndex(where: {
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("/**")
        }),
        let end = lines[signatureIndex...].firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "}" })
    else { return nil }
    let new = replacement.hasSuffix("\n") ? String(replacement.dropLast()) : replacement
    lines.replaceSubrange(start...end, with: new.components(separatedBy: "\n"))
    return lines.joined(separator: "\n")
}

/// Marks a member as owned by the programmer and puts a marker comment in its body.
///
/// - Parameters:
///   - text: The Java source.
///   - signature: The signature line of the member, without indentation.
///   - marker: The text of the comment to add to the body.
///   - keep: Whether to change the tag to `@generated NOT`.
/// - Returns: The edited source, or nil if the member was not found.
private func editing(_ text: String, signature: String, marker: String, keep: Bool) -> String? {
    var lines = text.components(separatedBy: "\n")
    guard let signatureIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == signature }),
        let brace = lines[signatureIndex...].firstIndex(where: { $0.contains("{") })
    else { return nil }
    lines.insert("// \(marker)", at: brace + 1)
    if keep {
        guard let tag = lines[..<signatureIndex].lastIndex(where: { $0.contains("@generated") }) else {
            return nil
        }
        lines[tag] = lines[tag] + " NOT"
    }
    return lines.joined(separator: "\n")
}

@Suite("Tutorial Java-01: From Ecore to a Generator Model", .enabled(if: JavaTutorial.shellAvailable, Comment(rawValue: shellReason)))
struct JavaTutorial01Tests {
    @Test("Steps 1 to 5: download, validate and look at the model", arguments: JavaTutorialSubject.available)
    func inspectModel(_ subject: JavaTutorialSubject) async throws {
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }

        let download = try JavaTutorial.text(1, 1)
        #expect(
            download.trimmingCharacters(in: .whitespacesAndNewlines)
                == "curl -LO https://raw.githubusercontent.com/eclipse-emf/org.eclipse.emf/master/"
                + "examples/org.eclipse.emf.examples.library/model/extlibrary.ecore")

        let validated = try await workspace.require(1, 2)
        #expect(validated.output.contains(try JavaTutorial.text(1, 3).trimmingCharacters(in: .newlines)))

        let queried = try await workspace.require(1, 4)
        #expect(queried.output.contains("Total objects: 1"))
        #expect(queried.output.contains("EPackage: 1"))

        let counted = try await workspace.require(1, 5)
        #expect(counted.output.trimmingCharacters(in: .whitespacesAndNewlines) == "\(subject.classCount)")
    }

    @Test("Steps 6 to 8: create the generator model", arguments: JavaTutorialSubject.available)
    func createGenModel(_ subject: JavaTutorialSubject) async throws {
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }

        let created = try await workspace.require(1, 6)

        #expect(created.output.hasPrefix("Wrote "))
        #expect(created.output.contains(JavaTutorialSubject.genModelFileName))
        #expect(try JavaTutorial.text(1, 7).hasPrefix("Wrote "))
        let genModel = try workspace.read(JavaTutorialSubject.genModelFileName)
        #expect(genModel.contains("<genmodel:GenModel"))
        #expect(genModel.contains("prefix=\"EXTLibrary\""))
        #expect(genModel.contains("basePackage=\"org.eclipse.emf.examples\""))
        #expect(genModel.contains("ecoreClass=\"extlibrary.ecore#//Book\""))
        #expect(genModel.contains("<foreignModel>extlibrary.ecore</foreignModel>"))
        #expect(genModel.contains("<genEnums "))
        #expect(genModel.components(separatedBy: "<genClasses ").count - 1 == subject.classCount)
    }

    @Test("Step 9: choose settings with options", arguments: JavaTutorialSubject.available)
    func genModelOptions(_ subject: JavaTutorialSubject) async throws {
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }

        try await workspace.require(1, 9)

        #expect(workspace.exists("generated/extlibrary.genmodel"))
        #expect(!workspace.exists("extlibrary.genmodel"))
        let genModel = try workspace.read("generated/extlibrary.genmodel")
        #expect(genModel.contains("complianceLevel=\"17.0\""))
        #expect(genModel.contains("copyrightText=\"Copyright 2026 Example Pty Ltd\""))
        #expect(genModel.contains("modelPluginID=\"org.example.extlibrary\""))
        #expect(genModel.contains("modelDirectory=\"/org.example.extlibrary/src\""))
        #expect(genModel.contains("ecoreClass=\"../extlibrary.ecore#//Book\""))
    }

    @Test("Step 10: reload keeps edited settings", arguments: JavaTutorialSubject.available)
    func reload(_ subject: JavaTutorialSubject) async throws {
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }
        try await workspace.require(1, 6)
        let edited = try workspace.read("extlibrary.genmodel")
            .replacingOccurrences(of: "complianceLevel=\"17.0\"", with: "complianceLevel=\"11.0\"")
        try workspace.write(edited, to: "extlibrary.genmodel")
        let model = try workspace.read("extlibrary.ecore")
        try workspace.write(
            model.replacingOccurrences(
                of: "</ecore:EPackage>",
                with: "  <eClassifiers xsi:type=\"ecore:EClass\" name=\"Newcomer\"/>\n</ecore:EPackage>"),
            to: "extlibrary.ecore")

        try await workspace.require(1, 10)

        let reloaded = try workspace.read("extlibrary.genmodel")
        #expect(reloaded.contains("complianceLevel=\"11.0\""))
        #expect(reloaded.contains("extlibrary.ecore#//Newcomer"))

        let overridden = try await workspace.shell(
            "swift-ecore genmodel extlibrary.ecore --reload extlibrary.genmodel --jdk-level 21.0 --output other.genmodel"
        )
        #expect(overridden.succeeded)
        #expect(try workspace.read("other.genmodel").contains("complianceLevel=\"21.0\""))
    }
}

@Suite("Tutorial Java-02: From a Generator Model to Java", .enabled(if: JavaTutorial.shellAvailable, Comment(rawValue: shellReason)))
struct JavaTutorial02Tests {
    /// Creates the generator models of the first tutorial.
    private func prepare(_ subject: JavaTutorialSubject) async throws -> JavaTutorialWorkspace {
        let workspace = try JavaTutorialWorkspace(subject)
        try await workspace.require(1, 6)
        try await workspace.require(1, 9)
        return workspace
    }

    @Test("Steps 1 to 4: generate Java and list the files", arguments: JavaTutorialSubject.available)
    func generate(_ subject: JavaTutorialSubject) async throws {
        let workspace = try await prepare(subject)
        defer { workspace.remove() }

        let generated = try await workspace.require(2, 1)

        #expect(generated.output.contains("Generated \(subject.fileCount) files in: "))
        #expect(try JavaTutorial.text(2, 2).contains("Generated "))
        let listed = try await workspace.require(2, 3)
        let listing = listed.output.split(separator: "\n").map(String.init)
        #expect(Set(listing) == Set(workspace.files(below: "src").map { "src/\($0)" }))
        #expect(listing.count == subject.fileCount)
        let directory = subject.packageDirectory
        for name in [
            "Book", "BookCategory", "EXTLibraryFactory", "EXTLibraryPackage", "impl/BookImpl",
            "impl/EXTLibraryFactoryImpl", "impl/EXTLibraryPackageImpl", "util/EXTLibrarySwitch",
        ] {
            #expect(workspace.exists("src/\(directory)/\(name).java"), "\(name).java was not generated")
        }
    }

    @Test("Steps 7 and 8: generate a project", arguments: JavaTutorialSubject.available)
    func modelDirectory(_ subject: JavaTutorialSubject) async throws {
        let workspace = try await prepare(subject)
        defer { workspace.remove() }

        try await workspace.require(2, 7)

        for name in ["META-INF/MANIFEST.MF", "build.properties", "plugin.properties", "plugin.xml"] {
            #expect(workspace.exists("project/org.example.extlibrary/\(name)"), "\(name) was not generated")
        }
        #expect(
            workspace.exists("project/org.example.extlibrary/src/\(subject.packageDirectory)/Book.java"))
    }

    @Test(
        "Steps 9 to 12: regenerate, preview and overwrite",
        arguments: JavaTutorialSubject.available)
    func regenerate(_ subject: JavaTutorialSubject) async throws {
        let workspace = try await prepare(subject)
        defer { workspace.remove() }
        try await workspace.require(2, 1)
        let file = "src/\(subject.packageDirectory)/impl/BookImpl.java"
        let original = try workspace.read(file)
        let kept = try #require(
            editing(original, signature: subject.editedSignature, marker: "hand-written", keep: true))
        let damaged = try #require(
            editing(kept, signature: subject.damagedSignature, marker: "damaged", keep: false))
        try workspace.write(damaged, to: file)

        try await workspace.require(2, 10)

        let merged = try workspace.read(file)
        #expect(merged.contains("// hand-written"), "a member marked @generated NOT is kept")
        #expect(merged.contains("@generated NOT"))
        #expect(!merged.contains("// damaged"), "a member with a plain @generated tag is regenerated")

        let redamaged = try #require(
            editing(merged, signature: subject.damagedSignature, marker: "damaged again", keep: false))
        try workspace.write(redamaged, to: file)
        try await workspace.require(2, 11)
        #expect(try workspace.read(file) == redamaged, "the preview leaves the file alone")
        let preview = try workspace.read("src/\(subject.packageDirectory)/impl/.BookImpl.java.new")
        #expect(!preview.contains("damaged again"))
        #expect(!preview.contains("hand-written"))
        #expect(preview.contains(subject.editedSignature))

        try await workspace.require(2, 12)
        let forced = try workspace.read(file)
        #expect(!forced.contains("hand-written"))
        #expect(!forced.contains("damaged again"))
        #expect(forced == original)
    }

    @Test("Steps 13 and 14: generate in one step", arguments: JavaTutorialSubject.available)
    func singleStep(_ subject: JavaTutorialSubject) async throws {
        let workspace = try await prepare(subject)
        defer { workspace.remove() }
        try await workspace.require(2, 1)

        let atl = try await workspace.require(2, 13)

        #expect(atl.output.contains("Generated \(subject.fileCount) files in: "))
        let expected = workspace.files(below: "src")
        #expect(workspace.files(below: "src-atl") == expected)
        for name in expected {
            #expect(try workspace.read("src/\(name)") == workspace.read("src-atl/\(name)"), "\(name) differs")
        }

        try await workspace.require(2, 14)
        #expect(workspace.exists("src-direct/\(subject.packageName)/Book.java"))
        #expect(workspace.files(below: "src-direct").count == subject.fileCount)
    }

    @Test("Steps 15 and 16: replace a template", arguments: JavaTutorialSubject.available)
    func templatePath(_ subject: JavaTutorialSubject) async throws {
        let workspace = try await prepare(subject)
        defer { workspace.remove() }
        try workspace.write(try JavaTutorial.text(2, 15), to: "my-templates/Header.mtl")

        try await workspace.require(2, 16)

        let files = workspace.files(below: "src-custom")
        #expect(files.count == subject.fileCount)
        for name in files {
            #expect(
                try workspace.read("src-custom/\(name)").hasPrefix(
                    "/**\n * Generated for the extended library example.\n */\npackage "),
                "\(name) has the wrong header")
        }
    }

    @Test(
        "Steps 22 and 23: compile the result",
        .enabled(if: runtimeClassPath != nil, Comment(rawValue: compileReason)),
        .enabled(if: javacAvailable, "no javac found; skipping the compile test"),
        arguments: JavaTutorialSubject.available)
    func compile(_ subject: JavaTutorialSubject) async throws {
        let workspace = try await prepare(subject)
        defer { workspace.remove() }
        try await workspace.require(2, 1)

        let compiled = try await workspace.require(2, 23)

        #expect(compiled.output.isEmpty)
        let classes = workspace.files(below: "classes").filter { $0.hasSuffix(".class") }
        #expect(!classes.isEmpty)
        #expect(classes.contains("\(subject.packageDirectory)/Book.class"))
    }

    @Test("Step 22: fetching the runtime uses the script of the repository")
    func fetchRuntimeSnippet() throws {
        let snippet = try JavaTutorial.text(2, 22)
        #expect(snippet.contains("EMF_RUNTIME_CLASSPATH"))
        #expect(snippet.contains("Scripts/fetch-emf-runtime.sh"))
        #expect(
            FileManager.default.isExecutableFile(
                atPath: JavaTutorialSubject.repositoryRoot
                    .appendingPathComponent("Scripts/fetch-emf-runtime.sh").path))
    }
}

@Suite("Tutorials Java-01 and Java-02: the extended library example")
struct JavaTutorialExtendedLibraryTests {
    @Test("the model that the tutorial downloads is available", .enabled(if: JavaTutorialSubject.referenceRoot != nil, Comment(rawValue: referenceRootReason)))
    func modelIsAvailable() throws {
        let subject = try #require(JavaTutorialSubject.extendedLibrary)
        #expect(FileManager.default.fileExists(atPath: subject.source.path))
        #expect(subject.source.lastPathComponent == JavaTutorialSubject.modelFileName)
    }

    @Test(
        "the excerpts shown by the tutorials appear in the generated files",
        .enabled(if: JavaTutorialSubject.referenceRoot != nil && JavaTutorial.shellAvailable, Comment(rawValue: referenceRootReason)))
    func excerpts() async throws {
        let subject = try #require(JavaTutorialSubject.extendedLibrary)
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }
        let created = try await workspace.require(1, 6)
        try await workspace.require(1, 9)
        let generated = try await workspace.require(2, 1)
        try await workspace.require(2, 7)
        let directory = subject.packageDirectory

        let genModelExcerpt = try JavaTutorial.text(1, 8)
        #expect(
            try workspace.read("extlibrary.genmodel").contains(genModelExcerpt))
        #expect(
            created.output.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("extlibrary.genmodel"))
        #expect(generated.output.contains("Generated 36 files in: "))

        let book = JavaTutorial.normalised(try workspace.read("src/\(directory)/Book.java"))
        #expect(book.contains(JavaTutorial.normalised(try JavaTutorial.text(2, 5))))
        let bookImpl = JavaTutorial.normalised(try workspace.read("src/\(directory)/impl/BookImpl.java"))
        #expect(bookImpl.contains(JavaTutorial.normalised(try JavaTutorial.text(2, 6))))

        let listing = workspace.files(below: "src").map { "src/\($0)" }
        for line in try JavaTutorial.text(2, 4).split(separator: "\n") where line != "..." {
            #expect(listing.contains(String(line)), "\(line) is not generated")
        }

        let projectFiles = workspace.files(below: "project").map { "project/\($0)" }
        for line in try JavaTutorial.text(2, 8).split(separator: "\n") where line != "..." {
            #expect(projectFiles.contains(String(line)), "\(line) is not generated")
        }
    }

    @Test(
        "the edit that the tutorial shows survives regeneration",
        .enabled(if: JavaTutorialSubject.referenceRoot != nil && JavaTutorial.shellAvailable, Comment(rawValue: referenceRootReason)))
    func editedMember() async throws {
        let subject = try #require(JavaTutorialSubject.extendedLibrary)
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }
        try await workspace.require(1, 6)
        try await workspace.require(2, 1)
        let file = "src/\(subject.packageDirectory)/impl/BookImpl.java"
        let excerpt = try JavaTutorial.text(2, 9)
        let edited = try #require(
            replacingMember(in: try workspace.read(file), signature: subject.editedSignature, with: excerpt))
        try workspace.write(edited, to: file)

        try await workspace.require(2, 10)

        #expect(
            JavaTutorial.normalised(try workspace.read(file)).contains(JavaTutorial.normalised(excerpt)))
    }
}

@Suite("Tutorials Java-01 and Java-02: the files the tutorials use")
struct JavaTutorialResourceTests {
    /// The tutorial files and the numbers of their code directories.
    private static let tutorials = [
        (file: "Java-01-ecore-to-genmodel.tutorial", number: 1),
        (file: "Java-02-genmodel-to-java.tutorial", number: 2),
    ]

    /// The names of the files that a tutorial gives to `@Code`.
    private func codeFiles(of tutorial: String) throws -> [String] {
        let text = try String(
            contentsOf: JavaTutorial.tutorialRoot.appendingPathComponent(tutorial), encoding: .utf8)
        return text.components(separatedBy: "@Code(").dropFirst().compactMap { part in
            guard let range = part.range(of: "file: ") else { return nil }
            return String(part[range.upperBound...].prefix { $0 != ")" })
        }
    }

    @Test("every code file that a tutorial shows exists and every code file is shown", arguments: Self.tutorials)
    func codeFilesMatch(_ tutorial: (file: String, number: Int)) throws {
        let shown = try codeFiles(of: tutorial.file)
        let directory = JavaTutorial.codeDirectory(tutorial.number)
        let present = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { !$0.hasPrefix(".") }
        #expect(Set(shown) == Set(present))
    }

    @Test("the table of contents lists both tutorials in a chapter of their own")
    func tableOfContents() throws {
        let root = JavaTutorial.tutorialRoot.deletingLastPathComponent()
        let contents = try String(contentsOf: root.appendingPathComponent("Tutorials.tutorial"), encoding: .utf8)
        let landing = try String(contentsOf: root.appendingPathComponent("Tutorials.md"), encoding: .utf8)
        #expect(contents.contains("@Chapter(name: \"Java Code Generation\")"))
        for name in ["Java-01-ecore-to-genmodel", "Java-02-genmodel-to-java"] {
            #expect(contents.contains("@TutorialReference(tutorial: \"doc:\(name)\")"))
            #expect(landing.contains("<doc:\(name)>"))
        }
    }

    @Test("the header template of the tutorial keeps the queries of the bundled module")
    func headerTemplateKeepsQueries() throws {
        let bundled = try String(
            contentsOf: JavaTutorialSubject.repositoryRoot.appendingPathComponent(
                "Sources/ModellingGenerators/Templates/java/Header.mtl"),
            encoding: .utf8)
        let tutorial = try JavaTutorial.text(2, 15)
        let queries = bundled.components(separatedBy: "\n").filter { $0.hasPrefix("[query ") }
        #expect(!queries.isEmpty)
        for query in queries {
            #expect(tutorial.contains(query), "the tutorial template lacks \(query)")
        }
        #expect(tutorial.contains("[template public header(element : OclAny)]"))
    }

    @Test("the tutorials and their files contain no em-dash")
    func noEmDash() throws {
        var urls = try FileManager.default.contentsOfDirectory(
            at: JavaTutorial.tutorialRoot, includingPropertiesForKeys: nil)
        for number in [1, 2] {
            urls += try FileManager.default.contentsOfDirectory(
                at: JavaTutorial.codeDirectory(number), includingPropertiesForKeys: nil)
        }
        for url in urls {
            let text = try String(contentsOf: url, encoding: .utf8)
            #expect(!text.contains("\u{2014}"), "\(url.lastPathComponent) has an em-dash")
            #expect(!text.contains("&mdash;"), "\(url.lastPathComponent) has an em-dash")
        }
    }
}

@Suite(
    "Tutorials Java-01 and Java-02: generator model presets",
    .enabled(if: JavaTutorial.shellAvailable, Comment(rawValue: shellReason)))
struct JavaTutorialPresetTests {
    /// The setting that the interactive wizard gives to the root class.
    private static let wizardRoot =
        "rootExtendsClass=\"org.eclipse.emf.ecore.impl.MinimalEObjectImpl$Container\""

    @Test("Step 11: the wizard preset", arguments: JavaTutorialSubject.available)
    func wizardPreset(_ subject: JavaTutorialSubject) async throws {
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }

        try await workspace.require(1, 11)

        let genModel = try workspace.read("wizard/extlibrary.genmodel")
        #expect(genModel.contains("operationReflection=\"true\""))
        #expect(genModel.contains("importOrganizing=\"true\""))
        #expect(genModel.contains(Self.wizardRoot))
    }

    @Test("Step 12: the headless preset is the default", arguments: JavaTutorialSubject.available)
    func headlessPreset(_ subject: JavaTutorialSubject) async throws {
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }

        try await workspace.require(1, 12)
        try await workspace.require(1, 6)

        let headless = try workspace.read("headless/extlibrary.genmodel")
        #expect(!headless.contains("operationReflection=\"true\""))
        #expect(!headless.contains("importOrganizing=\"true\""))
        #expect(!headless.contains("MinimalEObjectImpl"))
        let plain = try workspace.read("extlibrary.genmodel")
        #expect(!plain.contains("operationReflection=\"true\""))
        #expect(!plain.contains("importOrganizing=\"true\""))
    }

    @Test("Step 13: single settings override a preset", arguments: JavaTutorialSubject.available)
    func individualSettings(_ subject: JavaTutorialSubject) async throws {
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }

        try await workspace.require(1, 13)

        let custom = try workspace.read("custom/extlibrary.genmodel")
        #expect(custom.contains("operationReflection=\"true\""))
        #expect(custom.contains("importOrganizing=\"true\""))
        #expect(custom.contains(Self.wizardRoot))

        let negated = try await workspace.shell(
            "swift-ecore genmodel extlibrary.ecore --defaults wizard --no-operation-reflection "
                + "--no-import-organizing --output negated/extlibrary.genmodel")
        #expect(negated.succeeded)
        let genModel = try workspace.read("negated/extlibrary.genmodel")
        #expect(!genModel.contains("operationReflection=\"true\""))
        #expect(!genModel.contains("importOrganizing=\"true\""))
        #expect(genModel.contains(Self.wizardRoot))

        let rooted = try await workspace.shell(
            "swift-ecore genmodel extlibrary.ecore --root-extends-class org.example.Base "
                + "--output rooted/extlibrary.genmodel")
        #expect(rooted.succeeded)
        #expect(try workspace.read("rooted/extlibrary.genmodel").contains("rootExtendsClass=\"org.example.Base\""))
    }

    @Test("the presets decide how generated files import the model package", arguments: JavaTutorialSubject.available)
    func importStyle(_ subject: JavaTutorialSubject) async throws {
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }
        let wildcard = "import \(subject.packageName).*;"

        for (name, flags) in [("headless", "--defaults headless"), ("wizard", "--defaults wizard"),
            ("on", "--import-organizing"), ("off", "--defaults wizard --no-import-organizing")]
        {
            let result = try await workspace.shell(
                "swift-ecore generate --language java \(JavaTutorialSubject.modelFileName) \(flags) -o out-\(name)")
            #expect(result.succeeded, "\(result.error)")
        }

        func wildcardFiles(_ name: String) throws -> [String] {
            try workspace.files(below: "out-\(name)").filter { try workspace.read("out-\(name)/\($0)").contains(wildcard) }
        }
        #expect(!(try wildcardFiles("headless")).isEmpty, "unorganised imports use a wildcard for the model package")
        #expect(try wildcardFiles("off") == (try wildcardFiles("headless")))
        #expect(try wildcardFiles("wizard").isEmpty)
        #expect(try wildcardFiles("on").isEmpty)
        let organised = try workspace.read("out-on/\(subject.packageName)/impl/BookImpl.java")
        let groups = organised.components(separatedBy: "\n").filter { $0.hasPrefix("import ") }
        let firstOther = try #require(groups.firstIndex { $0.hasPrefix("import \(subject.packageName).") })
        let lastOrg = try #require(groups.lastIndex { $0.hasPrefix("import org.") })
        #expect(lastOrg < firstOther, "org imports come before the other imports")
    }

    @Test("Step 21 without the code style: presets in the single step", arguments: JavaTutorialSubject.available)
    func presetsInOneStep(_ subject: JavaTutorialSubject) async throws {
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }
        let impl = "\(subject.packageDirectory)/impl/BookImpl.java"
        let explicit = "import org.eclipse.emf.examples.\(subject.packageName).Book;"

        let atl = try await workspace.shell(
            "swift-atl generate extlibrary.ecore --language java --base-package org.eclipse.emf.examples "
                + "--prefix EXTLibrary --defaults wizard --output src-wizard")
        let direct = try await workspace.shell(
            "swift-ecore generate --language java extlibrary.ecore --defaults wizard -o src-ecore")

        #expect(atl.succeeded, "\(atl.error)")
        #expect(direct.succeeded, "\(direct.error)")
        #expect(try workspace.read("src-wizard/\(impl)").contains(explicit))
        #expect(workspace.exists("src-ecore/\(subject.packageName)/Book.java"))
    }

    @Test("reload keeps existing values unless a flag or the preset is given", arguments: JavaTutorialSubject.available)
    func reloadWithPresets(_ subject: JavaTutorialSubject) async throws {
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }
        try await workspace.require(1, 6)

        let kept = try await workspace.shell(
            "swift-ecore genmodel extlibrary.ecore --reload extlibrary.genmodel --output kept.genmodel")
        let wizard = try await workspace.shell(
            "swift-ecore genmodel extlibrary.ecore --reload extlibrary.genmodel --defaults wizard "
                + "--output wizard.genmodel")
        let flagged = try await workspace.shell(
            "swift-ecore genmodel extlibrary.ecore --reload extlibrary.genmodel --operation-reflection "
                + "--output flagged.genmodel")

        #expect(kept.succeeded && wizard.succeeded && flagged.succeeded)
        #expect(!(try workspace.read("kept.genmodel")).contains("operationReflection=\"true\""))
        #expect(try workspace.read("wizard.genmodel").contains("importOrganizing=\"true\""))
        let single = try workspace.read("flagged.genmodel")
        #expect(single.contains("operationReflection=\"true\""))
        #expect(!single.contains("importOrganizing=\"true\""))
    }

    @Test("the flags are rejected for a generator model and for built-in languages", arguments: JavaTutorialSubject.available)
    func flagsRejected(_ subject: JavaTutorialSubject) async throws {
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }
        try await workspace.require(1, 6)

        let genModel = try await workspace.shell(
            "swift-ecore generate --language java extlibrary.genmodel --defaults wizard -o out")
        let builtIn = try await workspace.shell(
            "swift-ecore generate --language swift extlibrary.ecore --defaults wizard -o out-swift")

        #expect(!genModel.succeeded)
        #expect(!builtIn.succeeded)
    }
}

@Suite(
    "Tutorials Java-01 and Java-02: code style",
    .enabled(if: JavaTutorial.shellAvailable, Comment(rawValue: shellReason)))
struct JavaTutorialCodeStyleTests {
    @Test("Steps 17 to 20: the two code styles", arguments: JavaTutorialSubject.available)
    func codeStyles(_ subject: JavaTutorialSubject) async throws {
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }
        try await workspace.require(1, 6)
        let impl = "\(subject.packageDirectory)/impl/BookImpl.java"

        try await workspace.require(2, 17)
        try await workspace.require(2, 18)
        let plain = try await workspace.shell(
            "swift-ecore generate --language java extlibrary.genmodel -o src-default")

        let emf = try workspace.read("src-emf/\(impl)")
        let eclipse = try workspace.read("src-eclipse/\(impl)")
        #expect(plain.succeeded)
        #expect(try workspace.read("src-default/\(impl)") == eclipse, "eclipse is the default style")
        #expect(emf.contains("\n  public "))
        #expect(!emf.contains("\t"))
        #expect(eclipse.contains("\n\tpublic "))
        #expect(!eclipse.contains("\n  public "))
        #expect(eclipse.contains(") {\n"))
        #expect(!emf.contains(") {\n"))
        #expect(
            JavaTutorial.normalised(emf) == JavaTutorial.normalised(eclipse),
            "the styles differ only in white space")
    }

    @Test("Steps 19 and 20: the excerpts of the two code styles", arguments: JavaTutorialSubject.available.filter { $0.packageName == "extlibrary" })
    func codeStyleExcerpts(_ subject: JavaTutorialSubject) async throws {
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }
        try await workspace.require(1, 6)
        try await workspace.require(2, 17)
        try await workspace.require(2, 18)
        let impl = "\(subject.packageDirectory)/impl/BookImpl.java"

        #expect(try workspace.read("src-emf/\(impl)").contains(try JavaTutorial.text(2, 19)))
        #expect(try workspace.read("src-eclipse/\(impl)").contains(try JavaTutorial.text(2, 20)))
        #expect(try workspace.read("src-eclipse/\(impl)").contains(try JavaTutorial.text(2, 6)))
    }

    @Test("the code style is rejected when unknown", arguments: JavaTutorialSubject.available)
    func unknownCodeStyle(_ subject: JavaTutorialSubject) async throws {
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }
        try await workspace.require(1, 6)

        let result = try await workspace.shell(
            "swift-ecore generate --language java extlibrary.genmodel --code-style gnu -o out")

        #expect(!result.succeeded)
        #expect(result.error.contains("gnu"))
    }

    @Test("Step 21: presets and code style in the single step", arguments: JavaTutorialSubject.available)
    func presetsInOneStep(_ subject: JavaTutorialSubject) async throws {
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }

        try await workspace.require(2, 21)

        let impl = try workspace.read("src-wizard/\(subject.packageDirectory)/impl/BookImpl.java")
        #expect(impl.contains("\(subject.editedSignature)\n  {"))
        #expect(impl.contains("import org.eclipse.emf.examples.\(subject.packageName).Book;"))
    }

    @Test("generate accepts the presets with an Ecore model", arguments: JavaTutorialSubject.available)
    func generateFromEcore(_ subject: JavaTutorialSubject) async throws {
        let workspace = try JavaTutorialWorkspace(subject)
        defer { workspace.remove() }

        let result = try await workspace.shell(
            "swift-ecore generate --language java extlibrary.ecore --defaults wizard "
                + "--code-style emf -o src-ecore")

        #expect(result.succeeded, "\(result.error)")
        #expect(workspace.exists("src-ecore/\(subject.packageName)/Book.java"))
    }
}
