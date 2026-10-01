import Foundation

@testable import ModellingGenerators

/// A fixture project that has been turned into a generator model, with a place for generated code.
struct GeneratedProject {
    /// The scratch copy of the fixture.
    let project: FixtureProject

    /// The generator model that was written beside the source model.
    let genModel: URL

    /// The directory that Java is generated into.
    var output: URL { project.root.appendingPathComponent("java") }

    /// The location of a generated file.
    ///
    /// - Parameter path: The path relative to the output directory.
    func file(_ path: String) -> URL { output.appendingPathComponent(path) }

    /// Reads a generated file.
    ///
    /// - Parameter path: The path relative to the output directory.
    /// - Returns: The text of the file.
    func text(_ path: String) throws -> String {
        try String(contentsOf: file(path), encoding: .utf8)
    }

    /// The paths of all generated files, relative to the output directory and sorted.
    func generatedPaths() -> [String] {
        let base = output.standardizedFileURL.path
        guard
            let enumerator = FileManager.default.enumerator(
                at: output, includingPropertiesForKeys: [.isRegularFileKey])
        else { return [] }
        var paths: [String] = []
        for case let url as URL in enumerator {
            let isFile = (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false
            if isFile { paths.append(String(url.standardizedFileURL.path.dropFirst(base.count + 1))) }
        }
        return paths.sorted()
    }

    /// Imports a fixture into a generator model.
    ///
    /// - Parameters:
    ///   - fixture: The name of the fixture directory.
    ///   - stem: The file stem of the source model.
    ///   - options: The import options.
    /// - Returns: The project with its generator model.
    @MainActor
    static func make(
        _ fixture: String, stem: String, options: GenModelImportOptions = GenModelImportOptions()
    ) async throws -> GeneratedProject {
        let project = try FixtureProject.make(fixture)
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [project.model("\(stem).ecore")], options: options)
        return GeneratedProject(project: project, genModel: result.url)
    }

    /// Generates code with a template set.
    ///
    /// - Parameters:
    ///   - language: The language of the template set.
    ///   - options: The generation options.
    ///   - progress: A receiver of progress reports.
    /// - Returns: The result of the generation.
    @MainActor
    @discardableResult
    func generate(
        language: String = "java", options: GenerationOptions = GenerationOptions(),
        progress: @escaping GenerationProgressReporter = { _ in }
    ) async throws -> GenerationResult {
        try await GenerationPipeline.generate(
            genModelURL: genModel, language: language, outputDirectory: output, options: options,
            progress: progress)
    }

    /// Removes the scratch copy.
    func remove() { project.remove() }
}

/// Runs template text against a generator model by overriding the main module of the Java template set.
struct TemplateHarness {
    /// The imports that every harness module declares.
    static let importedModules = [
        "JavaNames", "JavaImports", "JavaTypes", "JavaDocumentation", "Header", "EnumClass", "ClassQueries",
        "ClassModelInfo", "ClassFeature", "ClassOperation",
    ]

    /// The generator project the templates run against.
    let generated: GeneratedProject

    /// Creates the override directory for a main template body.
    ///
    /// - Parameter body: The text of the main template. It receives `genModel`.
    /// - Returns: The directory to pass as a template path.
    static func overrideDirectory(body: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-harness")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let imports = importedModules.map { "[import \($0)/]" }.joined(separator: "\n")
        let module = """
            [module generate('http://www.eclipse.org/emf/2002/GenModel', 'http://swift-modelling.org/typemapping/1.0')/]
            \(imports)
            [template public generate(genModel : GenModel)]
            [file ('result.txt')]\(body)[/file]
            [/template]
            [template public fileCount(genModel : GenModel)]
            [file ('count')]1[/file]
            [/template]

            """
        try module.write(
            to: directory.appendingPathComponent("generate.mtl"), atomically: true, encoding: .utf8)
        return directory
    }

    /// Evaluates template text.
    ///
    /// - Parameter body: The text of the main template body, written on one line so that no line
    ///   breaks are added.
    /// - Returns: The text that the template wrote.
    @MainActor
    func run(_ body: String) async throws -> String {
        let directory = try Self.overrideDirectory(body: body)
        defer { try? FileManager.default.removeItem(at: directory) }
        try await generated.generate(options: GenerationOptions(templatePaths: [directory]))
        return try generated.text("result.txt")
    }
}
