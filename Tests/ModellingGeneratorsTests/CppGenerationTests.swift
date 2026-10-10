import Foundation
import Testing

@testable import ModellingGenerators

/// A fixture together with the files that the C++ template set must generate for it.
struct CppGoldenCase: Sendable, CustomTestStringConvertible {
    /// The name of the fixture directory.
    let fixture: String

    /// The file stem of the source model.
    let stem: String

    /// The import options that the expectations were reviewed for.
    let options: GenModelImportOptions

    /// The expected files, relative to the output directory and sorted.
    let files: [String]

    var testDescription: String { fixture }

    /// The folder of the expectations, below the fixture.
    static let expectationFolder = "expected-cpp"

    /// Every fixture with committed C++ expectations.
    static let all: [CppGoldenCase] = [
        CppGoldenCase(
            fixture: "library", stem: "library",
            options: GenModelImportOptions(basePackage: "org.example", copyright: "Copyright 2026 Example Pty Ltd"),
            files: [
                "EObject.hpp",
                "library/Book.hpp",
                "library/BookCategory.hpp",
                "library/ISBN.hpp",
                "library/Lendable.hpp",
                "library/Library.hpp",
                "library/LibraryFactory.hpp",
                "library/LibraryPackage.hpp",
                "library/Named.hpp",
                "library/Writer.hpp",
            ]),
        CppGoldenCase(
            fixture: "nested", stem: "company",
            options: GenModelImportOptions(basePackage: "org.example.company", packagePrefixes: ["projects": "Proj"]),
            files: [
                "EObject.hpp",
                "company/Company.hpp",
                "company/CompanyFactory.hpp",
                "company/CompanyPackage.hpp",
                "company/people/Employee.hpp",
                "company/people/PeopleFactory.hpp",
                "company/people/PeoplePackage.hpp",
                "company/people/Person.hpp",
                "company/projects/ProjFactory.hpp",
                "company/projects/ProjPackage.hpp",
                "company/projects/Project.hpp",
                "company/projects/Status.hpp",
                "company/projects/archive/ArchiveFactory.hpp",
                "company/projects/archive/ArchivePackage.hpp",
                "company/projects/archive/Record.hpp",
            ]),
        CppGoldenCase(
            fixture: "enumerations", stem: "enumerations",
            options: GenModelImportOptions(basePackage: "org.example.traffic"),
            files: [
                "EObject.hpp",
                "enumerations/Colour.hpp",
                "enumerations/Empty.hpp",
                "enumerations/EnumerationsFactory.hpp",
                "enumerations/EnumerationsPackage.hpp",
                "enumerations/Light.hpp",
                "enumerations/Mode.hpp",
            ]),
        CppGoldenCase(
            fixture: "classes", stem: "classes",
            options: GenModelImportOptions(basePackage: "org.example.shapes"),
            files: [
                "EObject.hpp",
                "classes/Canvas.hpp",
                "classes/Circle.hpp",
                "classes/ClassesFactory.hpp",
                "classes/ClassesPackage.hpp",
                "classes/Colour.hpp",
                "classes/Named.hpp",
                "classes/Shape.hpp",
            ]),
        CppGoldenCase(
            fixture: "maps", stem: "maps",
            options: GenModelImportOptions(),
            files: [
                "EObject.hpp",
                "maps/Dictionary.hpp",
                "maps/MapsFactory.hpp",
                "maps/MapsPackage.hpp",
                "maps/StringToIntEntry.hpp",
            ]),
        CppGoldenCase(
            fixture: "documented", stem: "documented",
            options: GenModelImportOptions(basePackage: "org.example.alarm"),
            files: [
                "EObject.hpp",
                "documented/DocumentedFactory.hpp",
                "documented/DocumentedPackage.hpp",
                "documented/Level.hpp",
            ]),
        CppGoldenCase(
            fixture: "datatypes", stem: "datatypes",
            options: GenModelImportOptions(basePackage: "org.example.types"),
            files: [
                "EObject.hpp",
                "datatypes/Anything.hpp",
                "datatypes/Class.hpp",
                "datatypes/Colour.hpp",
                "datatypes/Count.hpp",
                "datatypes/DatatypesFactory.hpp",
                "datatypes/DatatypesPackage.hpp",
                "datatypes/Gizmo.hpp",
                "datatypes/Hidden.hpp",
                "datatypes/Stamp.hpp",
                "datatypes/Thing.hpp",
            ]),
        CppGoldenCase(
            fixture: "families", stem: "families",
            options: GenModelImportOptions(basePackage: "org.example.families"),
            files: [
                "EObject.hpp",
                "Families/FamiliesFactory.hpp",
                "Families/FamiliesPackage.hpp",
                "Families/Family.hpp",
                "Families/Member.hpp",
            ]),
        CppGoldenCase(
            fixture: "organisation", stem: "organisation",
            options: GenModelImportOptions(prefix: "Org"),
            files: [
                "EObject.hpp",
                "organisation/OrgFactory.hpp",
                "organisation/OrgPackage.hpp",
                "organisation/Organisation.hpp",
                "organisation/Person.hpp",
                "organisation/Team.hpp",
            ]),
        CppGoldenCase(
            fixture: "ecoretypes", stem: "bridge",
            options: GenModelImportOptions(basePackage: "org.example.bridge"),
            files: [
                "EObject.hpp",
                "bridge/BridgeFactory.hpp",
                "bridge/BridgePackage.hpp",
                "bridge/Span.hpp",
            ]),
        CppGoldenCase(
            fixture: "bare", stem: "bare",
            options: GenModelImportOptions(),
            files: [
                "EObject.hpp",
                "bare/BareFactory.hpp",
                "bare/BarePackage.hpp",
                "bare/Thing.hpp",
            ]),
        CppGoldenCase(
            fixture: "cnames", stem: "cnames",
            options: GenModelImportOptions(),
            files: [
                "EObject.hpp",
                "cnames/CnamesFactory.hpp",
                "cnames/CnamesPackage.hpp",
                "cnames/Driver.hpp",
                "cnames/EObject_.hpp",
                "cnames/FILE_.hpp",
                "cnames/Mode.hpp",
                "cnames/Shape.hpp",
                "cnames/Truck.hpp",
                "cnames/Vehicle.hpp",
                "cnames/delete/DeleteFactory.hpp",
                "cnames/delete/DeletePackage.hpp",
                "cnames/delete/Wheel.hpp",
                "cnames/size_t_.hpp",
                "cnames/static_.hpp",
            ]),
    ]

    /// The case of a fixture.
    ///
    /// - Parameter fixture: The name of the fixture directory.
    /// - Returns: The case, or `nil` if the fixture has none.
    static func named(_ fixture: String) -> CppGoldenCase? { all.first { $0.fixture == fixture } }
}

/// A model of its own that the fixtures do not cover, generated like a fixture from a scratch directory.
struct CppExtraModel: Sendable, CustomTestStringConvertible {
    /// The name of the project, the model and the package.
    let name: String

    /// The Ecore model.
    let ecore: String

    var testDescription: String { name }

    /// A model that covers the kinds of features and types the fixtures lack: boxed values, characters, floating
    /// point numbers, byte arrays, dates, several inheritance paths to one class, a feature that two unrelated
    /// supertypes declare, an enumeration without literals, and a class that other classes extend.
    static let values = CppExtraModel(
        name: "values",
        ecore: #"""
<?xml version="1.0" encoding="UTF-8"?>
<ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore"
    name="values" nsURI="http://example.org/values" nsPrefix="val">
  <eClassifiers xsi:type="ecore:EClass" name="A">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="x" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EInt" defaultValueLiteral="-3"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="boxed" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EIntegerObject" defaultValueLiteral="7"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="flag" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EBooleanObject"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="letter" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EChar" defaultValueLiteral="Q"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="ratio" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EFloat" defaultValueLiteral="0.25"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="when" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EDate"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="blob" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EByteArray"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="any" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EJavaObject"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="big" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EBigInteger" defaultValueLiteral="12345678901234567890"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="colours" upperBound="-1" eType="#//Colour"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="empty" eType="#//Empty"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="huge" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//ELong" defaultValueLiteral="99999999999"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="tiny" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EByte"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="small" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EShort"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="money" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EBigDecimal"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="quote" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString" defaultValueLiteral="say &quot;hi&quot;&#xA;\there"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="maybeLetter" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//ECharacterObject"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="precise" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EDouble" defaultValueLiteral="2.5"/>
  </eClassifiers>
  <eClassifiers xsi:type="ecore:EClass" name="B" eSuperTypes="#//A">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="bee" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
  </eClassifiers>
  <eClassifiers xsi:type="ecore:EClass" name="C" eSuperTypes="#//A">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="see" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
  </eClassifiers>
  <eClassifiers xsi:type="ecore:EClass" name="D" eSuperTypes="#//B #//C">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="dee" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="parts" upperBound="-1" eType="#//F" containment="true"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="friend" eType="#//F"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="owner" eType="#//D"/>
  </eClassifiers>
  <eClassifiers xsi:type="ecore:EClass" name="F" eSuperTypes="#//D"/>
  <eClassifiers xsi:type="ecore:EClass" name="X" abstract="true">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="label" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
  </eClassifiers>
  <eClassifiers xsi:type="ecore:EClass" name="Y" abstract="true">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="label" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
  </eClassifiers>
  <eClassifiers xsi:type="ecore:EClass" name="Z" eSuperTypes="#//X #//Y"/>
  <eClassifiers xsi:type="ecore:EEnum" name="Colour">
    <eLiterals name="red"/>
    <eLiterals name="green" value="1"/>
    <eLiterals name="crimson" value="0"/>
  </eClassifiers>
  <eClassifiers xsi:type="ecore:EEnum" name="Empty"/>
</ecore:EPackage>
"""#)

    /// A model with a class and an enumeration in a subpackage and a subclass in the subpackage of a class of the
    /// package above, so that types of other packages are written with their namespaces.
    static let cross = CppExtraModel(
        name: "cross",
        ecore: #"""
<?xml version="1.0" encoding="UTF-8"?>
<ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore"
    name="cross" nsURI="http://example.org/cross" nsPrefix="cr">
  <eClassifiers xsi:type="ecore:EClass" name="Base">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="level" eType="#//sub/Level" defaultValueLiteral="High"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="levels" upperBound="-1" eType="#//sub/Level"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="tag" eType="#//sub/Tag"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="kids" upperBound="-1" eType="#//sub/Child" containment="true" eOpposite="#//sub/Child/parent"/>
  </eClassifiers>
  <eSubpackages name="sub" nsURI="http://example.org/cross/sub" nsPrefix="sub">
    <eClassifiers xsi:type="ecore:EClass" name="Child" eSuperTypes="#//Base">
      <eStructuralFeatures xsi:type="ecore:EReference" name="parent" eType="#//Base" eOpposite="#//Base/kids"/>
      <eStructuralFeatures xsi:type="ecore:EReference" name="other" eType="#//sub/Child"/>
    </eClassifiers>
    <eClassifiers xsi:type="ecore:EEnum" name="Level">
      <eLiterals name="Low"/>
      <eLiterals name="High" value="1"/>
    </eClassifiers>
    <eClassifiers xsi:type="ecore:EDataType" name="Tag" instanceClassName="java.lang.String"/>
  </eSubpackages>
</ecore:EPackage>
"""#)

    /// Every extra model.
    static let all = [values, cross]

    /// Imports the model into a generator model in a scratch project.
    ///
    /// - Returns: The project, whose output directory is for C++; the caller removes it.
    @MainActor
    func make() async throws -> GeneratedProject {
        let scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-genmodel-tests")
            .appendingPathComponent(UUID().uuidString)
        let root = scratch.appendingPathComponent(name)
        let directory = root.appendingPathComponent("model")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let source = directory.appendingPathComponent("\(name).ecore")
        try ecore.write(to: source, atomically: true, encoding: .utf8)
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [source], options: GenModelImportOptions())
        return GeneratedProject(project: FixtureProject(root: root), genModel: result.url, language: "cpp")
    }

    /// Generates the model with the C++ template set.
    ///
    /// - Returns: The generated project; the caller removes it.
    @MainActor
    func generate() async throws -> GeneratedProject {
        let generated = try await make()
        try await generated.generate()
        return generated
    }
}

/// Generates a fixture with the C++ template set.
///
/// - Parameters:
///   - golden: The fixture to generate.
///   - options: The generation options.
/// - Returns: The generated project; the caller removes it.
@MainActor
func generateCpp(
    _ golden: CppGoldenCase, options: GenerationOptions = GenerationOptions()
) async throws -> GeneratedProject {
    let generated = try await GeneratedProject.make(
        golden.fixture, stem: golden.stem, options: golden.options, language: "cpp")
    try await generated.generate(options: options)
    return generated
}

@Suite("C++ generation")
struct CppGenerationTests {
    @Test("Generated files match the reviewed expectations", arguments: CppGoldenCase.all)
    @MainActor
    func goldenFiles(_ golden: CppGoldenCase) async throws {
        let generated = try await generateCpp(golden)
        defer { generated.remove() }

        let paths = generated.generatedPaths()
        #expect(paths == golden.files, "the generated files differ from the expected files")
        if GoldenFiles.isRecording {
            let folder = GoldenFiles.sourceFixtures.appendingPathComponent(
                "\(golden.fixture)/\(CppGoldenCase.expectationFolder)")
            try? FileManager.default.removeItem(at: folder)
        }
        for path in paths {
            try GoldenFiles.check(
                try generated.text(path),
                against: "\(golden.fixture)/\(CppGoldenCase.expectationFolder)/\(path)", path)
        }
    }

    @Test("Every generated enumeration is a scoped enumeration with a sized integer type", arguments: CppGoldenCase.all)
    @MainActor
    func enumerationsHaveASizedIntegerType(_ golden: CppGoldenCase) async throws {
        let generated = try await generateCpp(golden)
        defer { generated.remove() }
        for path in generated.generatedPaths() {
            let text = try generated.text(path)
            for line in text.split(separator: "\n") where line.hasPrefix("enum class ") {
                #expect(
                    line.hasSuffix(" : std::int32_t {"),
                    "\(path) does not give the enumeration a sized integer type: \(line)")
            }
        }
    }

    @Test("Every fixture generates without error", arguments: CppGoldenCase.all)
    @MainActor
    func everyFixtureGenerates(_ golden: CppGoldenCase) async throws {
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, language: "cpp")
        defer { generated.remove() }
        let result = try await generated.generate()
        #expect(result.language == "cpp")
        #expect(result.files.count == generated.generatedPaths().count)
        #expect(result.packageCount >= 1)
        #expect(generated.generatedPaths().allSatisfy { $0.hasSuffix(".hpp") })
    }

    @Test("Generating twice yields identical files")
    @MainActor
    func determinism() async throws {
        let golden = try #require(CppGoldenCase.named("library"))
        let generated = try await generateCpp(golden)
        defer { generated.remove() }
        let first = try generated.generatedPaths().map { try generated.text($0) }
        try FileManager.default.removeItem(at: generated.output)
        try await generated.generate()
        let second = try generated.generatedPaths().map { try generated.text($0) }
        #expect(first == second)
        #expect(!first.isEmpty)
    }

    @Test("The result lists the files in the order they were written")
    @MainActor
    func resultListsFiles() async throws {
        let golden = try #require(CppGoldenCase.named("enumerations"))
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options, language: "cpp")
        defer { generated.remove() }
        let result = try await generated.generate()
        #expect(result.language == "cpp")
        #expect(result.packageCount == 1)
        let names = result.files.map(\.lastPathComponent)
        let expectedOrder = [
            "EObject.hpp", "EnumerationsPackage.hpp", "EnumerationsFactory.hpp", "Light.hpp", "Colour.hpp",
            "Mode.hpp", "Empty.hpp",
        ]
        #expect(names.isSubsequence(containing: expectedOrder), "unexpected file order: \(names)")
        #expect(result.outputDirectory.path == generated.output.standardizedFileURL.path)
    }

    @Test("The source directory of the generator model can be part of the layout")
    @MainActor
    func sourceRootLayout() async throws {
        let golden = try #require(CppGoldenCase.named("library"))
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options, language: "cpp")
        defer { generated.remove() }
        let result = try await generated.generate(options: GenerationOptions(includeSourceRoot: true))
        #expect(Set(generated.generatedPaths()) == Set(golden.files.map { "library/src/" + $0 }))
        #expect(result.outputDirectory.lastPathComponent == "src")
    }

    @Test("Progress reports count the files and know the total")
    @MainActor
    func progressCounts() async throws {
        let golden = try #require(CppGoldenCase.named("nested"))
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options, language: "cpp")
        defer { generated.remove() }
        let collector = ProgressCollector()
        try await generated.generate(progress: { collector.add($0) })
        let updates = collector.updates
        let fileUpdates = updates.filter { $0.message.hasPrefix("Generated ") }
        #expect(fileUpdates.count == golden.files.count)
        #expect(fileUpdates.map(\.completed) == Array(1...fileUpdates.count))
        #expect(fileUpdates.allSatisfy { $0.total == fileUpdates.count })
        #expect(fileUpdates.last?.fraction == 1)
        #expect(updates.last?.message == "Done")
    }

    @Test("Every package writes a package description and a factory, and the support header is written once")
    @MainActor
    func packageFiles() async throws {
        let golden = try #require(CppGoldenCase.named("nested"))
        let generated = try await generateCpp(golden)
        defer { generated.remove() }
        let paths = generated.generatedPaths()
        #expect(paths.filter { $0.hasSuffix("EObject.hpp") } == ["EObject.hpp"])
        for (directory, prefix) in [
            ("company", "Company"), ("company/people", "People"), ("company/projects", "Proj"),
            ("company/projects/archive", "Archive"),
        ] {
            #expect(paths.contains("\(directory)/\(prefix)Package.hpp"), "\(directory) has no package description")
            #expect(paths.contains("\(directory)/\(prefix)Factory.hpp"), "\(directory) has no factory")
        }
    }
}
