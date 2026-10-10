import Foundation
import Testing

@testable import ModellingGenerators

/// Checks the text of the C++ code that the template set writes for fixtures.
@Suite("C++ model text")
struct CppModelTextTests {
    /// The comment line that tags the member below it as generated.
    static let tag = "// @generated"

    /// Generates a fixture and reads some of its files.
    ///
    /// - Parameters:
    ///   - fixture: The name of the fixture.
    ///   - paths: The paths of the files to read.
    /// - Returns: The text of the files in the same order.
    @MainActor
    func files(_ fixture: String, _ paths: [String]) async throws -> [String] {
        let golden = try #require(CppGoldenCase.named(fixture))
        let generated = try await generateCpp(golden)
        defer { generated.remove() }
        return try paths.map { try generated.text($0) }
    }

    /// Generates a fixture and reads all of its files.
    @MainActor
    func allFiles(_ fixture: String) async throws -> [String: String] {
        let golden = try #require(CppGoldenCase.named(fixture))
        let generated = try await generateCpp(golden)
        defer { generated.remove() }
        return Dictionary(uniqueKeysWithValues: try generated.generatedPaths().map { ($0, try generated.text($0)) })
    }

    /// Generates an extra model and reads all of its files.
    @MainActor
    func extraFiles(_ model: CppExtraModel) async throws -> [String: String] {
        let generated = try await model.generate()
        defer { generated.remove() }
        return Dictionary(uniqueKeysWithValues: try generated.generatedPaths().map { ($0, try generated.text($0)) })
    }

    /// Generates the model of the values and reads all of its files.
    @MainActor
    func valuesFiles() async throws -> [String: String] { try await extraFiles(.values) }

    /// Generates the model with several packages and reads all of its files.
    @MainActor
    func crossFiles() async throws -> [String: String] { try await extraFiles(.cross) }

    /// The declarations of a header that the generated tag does not precede.
    ///
    /// A declaration is a line of code in a scope that holds declarations: the file, a namespace, a class, a structure
    /// or an enumeration. The bodies of functions and the lists in them hold statements.
    ///
    /// - Parameter text: The text of a header.
    /// - Returns: The trimmed untagged declarations, in order.
    static func untaggedDeclarations(in text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")
        let declaringPrefixes = ["namespace ", "class ", "struct ", "enum class "]
        let labels = ["public:", "private:", "protected:"]
        var scopes: [Bool] = []
        var untagged: [String] = []
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isCode =
                !trimmed.isEmpty && !trimmed.hasPrefix("//") && !trimmed.hasPrefix("#") && !trimmed.hasPrefix("}")
                && !labels.contains(trimmed)
            if isCode && (scopes.last ?? true) {
                let previous = index > 0 ? lines[index - 1].trimmingCharacters(in: .whitespaces) : ""
                if previous != tag { untagged.append(trimmed) }
            }
            if trimmed.hasPrefix("//") { continue }
            var quoted = false
            var escaped = false
            for character in trimmed {
                if escaped {
                    escaped = false
                } else if quoted {
                    if character == "\\" { escaped = true } else if character == "\"" { quoted = false }
                } else if character == "\"" {
                    quoted = true
                } else if character == "{" {
                    scopes.append(declaringPrefixes.contains { trimmed.hasPrefix($0) })
                } else if character == "}" && !scopes.isEmpty {
                    scopes.removeLast()
                }
            }
        }
        return untagged
    }

    // MARK: - Layout of the text

    @Test("Documentation comment and declaration stand on lines of their own", arguments: CppGoldenCase.all)
    @MainActor
    func declarationsHaveTheirOwnLines(_ golden: CppGoldenCase) async throws {
        let generated = try await generateCpp(golden)
        defer { generated.remove() }
        for path in generated.generatedPaths() {
            let lines = try generated.text(path).components(separatedBy: "\n")
            for (index, line) in lines.enumerated() where index > 0 {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let declaresType = ["class ", "struct ", "enum class ", "namespace ", "using "].contains {
                    line.hasPrefix($0)
                }
                if declaresType {
                    #expect(lines[index - 1] == Self.tag, "\(path): the declaration '\(trimmed)' does not follow the tag")
                    #expect(!line.contains("///"), "\(path): a comment shares the line of '\(trimmed)'")
                }
            }
        }
    }

    @Test("Every member of a generated file carries the generated tag", arguments: CppGoldenCase.all)
    @MainActor
    func membersAreTagged(_ golden: CppGoldenCase) async throws {
        let generated = try await generateCpp(golden)
        defer { generated.remove() }
        for path in generated.generatedPaths() {
            #expect(Self.untaggedDeclarations(in: try generated.text(path)).isEmpty, "\(path) has untagged members")
        }
    }

    @Test("The scan for untagged members finds a missing tag")
    func scanFindsMissingTags() {
        let text = "namespace a {\n\n// @generated\nclass B {\npublic:\n    int x;\n    // @generated\n    int y() { return 1; }\n};\n\n}\n"
        #expect(Self.untaggedDeclarations(in: text) == ["namespace a {", "int x;"])
    }

    @Test("Every member is documented with documentation comments", arguments: CppGoldenCase.all)
    @MainActor
    func membersAreDocumented(_ golden: CppGoldenCase) async throws {
        let generated = try await generateCpp(golden)
        defer { generated.remove() }
        for path in generated.generatedPaths() {
            let lines = try generated.text(path).components(separatedBy: "\n")
            for (index, line) in lines.enumerated() where index > 0 && line.trimmingCharacters(in: .whitespaces) == Self.tag {
                let next = lines[index + 1].trimmingCharacters(in: .whitespaces)
                if next.hasPrefix("namespace ") { continue }
                #expect(
                    lines[index - 1].trimmingCharacters(in: .whitespaces).hasPrefix("///"),
                    "\(path): '\(next)' has no documentation comment")
            }
        }
    }

    @Test("Headers start with a guard, include what they use once and in order, and end with a line feed", arguments: CppGoldenCase.all)
    @MainActor
    func includesDeclareTheTypesInUse(_ golden: CppGoldenCase) async throws {
        let generated = try await generateCpp(golden)
        defer { generated.remove() }
        let uses: [(pattern: String, header: String)] = [
            (#"std::string(?![_a-z])"#, "<string>"), (#"std::string_view"#, "<string_view>"),
            (#"std::vector"#, "<vector>"), (#"std::(shared|weak)_ptr|std::make_shared"#, "<memory>"),
            (#"std::optional|std::nullopt"#, "<optional>"), (#"std::u?int(8|16|32|64)_t"#, "<cstdint>"),
            (#"std::any"#, "<any>"), (#"std::chrono"#, "<chrono>"),
        ]
        let paths = Set(generated.generatedPaths())
        for path in generated.generatedPaths() {
            let text = try generated.text(path)
            #expect(text.hasPrefix("#pragma once\n"), "\(path) does not start with the include guard")
            #expect(text.hasSuffix("\n") && !text.hasSuffix("\n\n"), "\(path) does not end in one line feed")
            #expect(!text.contains("\u{2014}"), "\(path) has an em-dash")
            let includes = text.components(separatedBy: "\n").filter { $0.hasPrefix("#include ") }
            #expect(includes == includes.sorted() && Set(includes).count == includes.count, "\(path) includes in order, once")
            for (pattern, header) in uses where text.range(of: pattern, options: .regularExpression) != nil {
                #expect(includes.contains("#include \(header)"), "\(path) lacks \(header)")
            }
            for include in includes where include.hasPrefix("#include \"") {
                let target = String(include.dropFirst("#include \"".count).dropLast())
                #expect(paths.contains(target), "\(path) includes \(target), which is not generated")
            }
        }
    }

    @Test("The file header names the file and carries the copyright text")
    @MainActor
    func header() async throws {
        let text = try await files("library", ["library/Book.hpp"])[0]
        #expect(
            text.hasPrefix(
                "#pragma once\n\n//\n//  Book.hpp\n//\n//  Copyright 2026 Example Pty Ltd\n//\n\n"
                    + "#include \"EObject.hpp\"\n#include \"library/BookCategory.hpp\"\n#include \"library/ISBN.hpp\"\n"
                    + "#include \"library/Lendable.hpp\"\n#include \"library/LibraryPackage.hpp\"\n"
                    + "#include \"library/Named.hpp\"\n#include <cstdint>\n#include <memory>\n#include <string>\n\n"
            ))
        let bare = try await files("bare", ["bare/Thing.hpp"])[0]
        #expect(bare.hasPrefix("#pragma once\n\n//\n//  Thing.hpp\n//\n\n#include "))
    }

    // MARK: - The support header

    @Test("The support header is the same for every model and has no copyright text")
    @MainActor
    func supportHeader() async throws {
        let library = try await files("library", ["EObject.hpp"])[0]
        let bare = try await files("bare", ["EObject.hpp"])[0]
        let values = try await valuesFiles()["EObject.hpp"]
        #expect(library == bare)
        #expect(library == values)
        #expect(!library.contains("Copyright"))
        #expect(library.hasPrefix("#pragma once\n\n//\n//  EObject.hpp\n//\n\n#include <cstdint>\n#include <string_view>\n#include <vector>\n"))
    }

    @Test("The support header declares the root class and the descriptions")
    @MainActor
    func supportDeclarations() async throws {
        let text = try await files("library", ["EObject.hpp"])[0]
        for declaration in [
            "class EObject {", "    virtual ~EObject() = default;", "    virtual const ClassInfo &eClass() const = 0;",
            "    EObject(const EObject &) = delete;", "    EObject &operator=(const EObject &) = delete;",
            "protected:\n", "    EObject() = default;", "enum class FeatureKind : std::int32_t {", "    attribute,",
            "    reference,", "    containment,", "struct FeatureInfo {", "    std::string_view name;",
            "    FeatureKind kind = FeatureKind::attribute;", "    bool many = false;", "    std::string_view typeName;",
            "struct ClassInfo {", "    bool isAbstract = false;", "    std::vector<std::string_view> superTypes;",
            "    std::vector<FeatureInfo> features;", "struct PackageInfo {", "    std::string_view nsURI;",
            "    std::vector<ClassInfo> classes;",
            "inline bool isKindOf(const EObject &object, std::string_view className) {",
        ] {
            #expect(text.contains(declaration), "the support header lacks '\(declaration)'")
        }
        #expect(!text.contains("\nnamespace "), "the support header is not in a namespace")
    }

    // MARK: - Names

    @Test("Names that C++ reserves are renamed, and members need no renaming because of their prefix")
    @MainActor
    func reservedNames() async throws {
        let all = try await allFiles("cnames")
        let vehicle = try #require(all["cnames/Vehicle.hpp"])
        let accessors: [(feature: String, type: String)] = [
            ("Int", "std::int32_t"), ("Class", "const std::string &"), ("Namespace", "const std::string &"),
            ("New", "std::int32_t"), ("Delete", "bool"), ("Template", "const std::string &"), ("This", "const std::string &"),
            ("Signed", "double"), ("NULL", "const std::string &"), ("EObject", "const std::string &"), ("Bool", "bool"),
        ]
        for (feature, type) in accessors {
            #expect(vehicle.contains("    virtual \(type)\(type.hasSuffix("&") ? "" : " ")get\(feature)() const = 0;"), "get\(feature)")
            #expect(vehicle.contains("get\(feature)() const override { return m_"), "the implementation of get\(feature)")
        }
        #expect(vehicle.contains("    std::int32_t m_new = 0;\n"))
        #expect(vehicle.contains("    bool m_delete = false;\n"))
        #expect(vehicle.contains("    std::string m_NULL;\n"))
        #expect(vehicle.contains("    virtual void setClass(const std::string &value) = 0;"))
        let truck = try #require(all["cnames/Truck.hpp"])
        #expect(truck.contains("    std::int32_t getOperator() const { return m_operator; }"))
        #expect(truck.contains("    const std::string &getGoto() const { return m_goto; }"))
    }

    @Test("Classes, enumeration literals, data types and namespaces that C++ reserves get a trailing underscore")
    @MainActor
    func renamedTypes() async throws {
        let all = try await allFiles("cnames")
        let staticClass = try #require(all["cnames/static_.hpp"])
        #expect(staticClass.contains("class static_ final : public virtual EObject {"))
        #expect(staticClass.contains("//  static_.hpp\n"))
        #expect(staticClass.contains("/// @brief A class whose name is a keyword.\n"))
        #expect(try #require(all["cnames/FILE_.hpp"]).contains("class FILE_ final : public virtual EObject {"))
        let root = try #require(all["cnames/EObject_.hpp"])
        #expect(root.contains("class EObject_ final : public virtual EObject {"))
        #expect(root.contains("    const std::string &getEClass() const { return m_eClass; }"))
        #expect(root.contains("CnamesPackage::instance().eObjectClass()"))
        let mode = try #require(all["cnames/Mode.hpp"])
        for literal in ["and_ = 0", "default_ = 1", "int_ = 2", "NULL_ = 3", "new_ = 4", "true_ = 5"] {
            #expect(mode.contains("    \(literal),\n"), "the enumerator \(literal)")
        }
        #expect(mode.contains(#"    case Mode::NULL_: return "NULL";"#))
        #expect(mode.contains(#"    if (text == "default") return Mode::default_;"#))
        let size = try #require(all["cnames/size_t_.hpp"])
        #expect(size.contains("using size_t_ = std::optional<std::int64_t>;\n"))
        let wheel = try #require(all["cnames/delete/Wheel.hpp"])
        #expect(wheel.contains("\nnamespace cnames::delete_ {\n"))
        #expect(wheel.contains("::cnames::Vehicle"), "a class of another package is written with its namespace")
        #expect(try #require(all["cnames/delete/DeletePackage.hpp"]).contains("class DeletePackage final {"))
        let package = try #require(all["cnames/CnamesPackage.hpp"])
        #expect(package.contains("const ClassInfo &staticClass() const {"))
        #expect(package.contains(#"ClassInfo{"static", false,"#))
        let vehicle = try #require(all["cnames/Vehicle.hpp"])
        #expect(vehicle.contains("std::weak_ptr<static_> m_static;"))
        #expect(vehicle.contains("std::vector<std::shared_ptr<::cnames::delete_::Wheel>> m_wheels;"))
        #expect(vehicle.contains("\nnamespace cnames::delete_ { class Wheel; }\n"))
        let factory = try #require(all["cnames/CnamesFactory.hpp"])
        #expect(factory.contains("std::shared_ptr<static_> createStatic() const { return std::make_shared<static_>(); }"))
        #expect(factory.contains(#"if (className == "static") return createStatic();"#))
        #expect(factory.contains(#"if (className == "EObject") return createEObject();"#))
    }

    @Test("Packages are named from their prefix, and nested packages get namespaces and directories of their own")
    @MainActor
    func packageNames() async throws {
        let org = try await allFiles("organisation")
        #expect(Set(org.keys).isSuperset(of: ["organisation/OrgPackage.hpp", "organisation/OrgFactory.hpp"]))
        #expect(org["organisation/OrgPackage.hpp"]?.contains("class OrgPackage final {") == true)
        let nested = try await allFiles("nested")
        let projects = try #require(nested["company/projects/ProjPackage.hpp"])
        #expect(projects.contains("\nnamespace company::projects {\n"))
        #expect(projects.contains("class ProjPackage final {"))
        let archive = try #require(nested["company/projects/archive/Record.hpp"])
        #expect(archive.contains("\nnamespace company::projects::archive {\n"))
        #expect(archive.contains("ArchivePackage::instance().recordClass()"))
        #expect(archive.contains("\nnamespace company::projects { class Project; }\n"))
        #expect(archive.contains("    std::shared_ptr<::company::projects::Project> getProject() const { return m_project.lock(); }"))
        #expect(archive.contains("#include \"company/projects/archive/ArchivePackage.hpp\""))
        let families = try await allFiles("families")
        #expect(families["Families/FamiliesPackage.hpp"]?.contains("\nnamespace Families {\n") == true)
    }

    // MARK: - Abstract base classes and concrete classes

    @Test("Abstract classes and interfaces are abstract base classes; classes with instances are final classes")
    @MainActor
    func baseClassesAndClasses() async throws {
        let all = try await allFiles("library")
        let named = try #require(all["library/Named.hpp"])
        #expect(named.contains("class Named : public virtual EObject {"))
        #expect(named.contains("    virtual ~Named() = default;"))
        #expect(named.contains("protected:\n    /// @brief Creates the part of an object that this class describes.\n    // @generated\n    Named() = default;"))
        #expect(named.contains("    virtual const std::string &getName() const = 0;"))
        #expect(named.contains("    virtual void setName(const std::string &value) = 0;"))
        #expect(!named.contains("final"))
        #expect(!named.contains("m_name"), "an abstract class owns no storage")
        let lendable = try #require(all["library/Lendable.hpp"])
        #expect(lendable.contains("class Lendable : public virtual EObject {"))
        #expect(lendable.contains("    virtual std::int32_t getLoanDays() const = 0;"))
        let book = try #require(all["library/Book.hpp"])
        #expect(book.contains("class Book final : public virtual Named, public virtual Lendable {"))
        #expect(!book.contains("class Named"))
        #expect(book.contains("    const ClassInfo &eClass() const override { return LibraryPackage::instance().bookClass(); }"))
        #expect(book.contains("    const std::string &getName() const override { return m_name; }"), "an inherited accessor overrides")
        #expect(book.contains("    std::int32_t getLoanDays() const override { return m_loanDays; }"))
        #expect(book.contains("    std::int32_t getPages() const { return m_pages; }"), "an accessor that no base declares does not override")
        #expect(book.contains("private:\n"))
        #expect(!book.contains("    virtual "), "a concrete class declares nothing virtual of its own")
    }

    @Test("A class that others extend is an abstract base class with a final class that carries a suffix")
    @MainActor
    func extendedClasses() async throws {
        let all = try await allFiles("cnames")
        let vehicle = try #require(all["cnames/Vehicle.hpp"])
        #expect(vehicle.contains("class Vehicle : public virtual EObject {"))
        #expect(vehicle.contains("class VehicleImpl final : public virtual Vehicle {"))
        #expect(vehicle.contains("/// @brief The implementation of the Vehicle class.\n// @generated\nclass VehicleImpl"))
        #expect(vehicle.contains("    virtual std::int32_t getInt() const = 0;"))
        #expect(vehicle.contains("    std::int32_t getInt() const override { return m_int; }"), "the final class overrides its own features too")
        #expect(vehicle.contains("CnamesPackage::instance().vehicleClass()"))
        let truck = try #require(all["cnames/Truck.hpp"])
        #expect(truck.contains("class Truck final : public virtual Vehicle {"))
        #expect(truck.contains("#include \"cnames/Vehicle.hpp\""))
        #expect(truck.contains("    std::int32_t getInt() const override { return m_int; }"), "a subclass implements inherited features")
        #expect(truck.contains("    std::int32_t m_int = 0;"))
        let driver = try #require(all["cnames/Driver.hpp"])
        #expect(driver.contains("    std::shared_ptr<Vehicle> getVehicle() const { return m_vehicle.lock(); }"))
        #expect(driver.contains("\nnamespace cnames { class Vehicle; }\n"))
        #expect(!driver.contains("#include \"cnames/Vehicle.hpp\""), "a reference needs no more than a declaration")
        let shape = try #require(all["cnames/Shape.hpp"])
        #expect(shape.contains("class Shape : public virtual EObject {"))
        #expect(!shape.contains("final"))
        let factory = try #require(all["cnames/CnamesFactory.hpp"])
        #expect(factory.contains("std::shared_ptr<VehicleImpl> createVehicle() const { return std::make_shared<VehicleImpl>(); }"))
        #expect(factory.contains("std::shared_ptr<Truck> createTruck() const { return std::make_shared<Truck>(); }"))
        #expect(!factory.contains("createShape"))
        #expect(factory.contains(#"if (className == "Vehicle") return createVehicle();"#))
    }

    @Test("Concrete classes never derive from each other, and every base class is abstract", arguments: CppGoldenCase.all)
    @MainActor
    func concreteClassesAreLeaves(_ golden: CppGoldenCase) async throws {
        let generated = try await generateCpp(golden)
        defer { generated.remove() }
        var finals = Set<String>()
        var bases = Set<String>()
        for path in generated.generatedPaths() {
            for line in try generated.text(path).components(separatedBy: "\n") where line.hasPrefix("class ") {
                let words = line.dropFirst("class ".count).components(separatedBy: " ")
                if words.count > 1 && words[1] == "final" { finals.insert(words[0]) }
                if let colon = line.range(of: " : ") {
                    for base in line[colon.upperBound...].dropLast(2).components(separatedBy: ", ") {
                        #expect(base.hasPrefix("public virtual "), "\(path): '\(base)' is not a virtual base")
                        bases.insert(String(base.dropFirst("public virtual ".count)).components(separatedBy: "::").last ?? "")
                    }
                }
            }
        }
        #expect(finals.isDisjoint(with: bases), "a final class is a base class")
    }

    @Test("Bases are virtual, so a class that reaches the root along two paths has one copy of it")
    @MainActor
    func virtualInheritance() async throws {
        let all = try await valuesFiles()
        let d = try #require(all["values/D.hpp"])
        #expect(d.contains("class D : public virtual B, public virtual C {"))
        #expect(d.contains("class DImpl final : public virtual D {"))
        let b = try #require(all["values/B.hpp"])
        #expect(b.contains("class B : public virtual A {"))
        #expect(try #require(all["values/F.hpp"]).contains("class F final : public virtual D {"))
        let z = try #require(all["values/Z.hpp"])
        #expect(z.contains("class Z final : public virtual X, public virtual Y {"))
        #expect(z.components(separatedBy: "getLabel() const override").count == 2, "a feature of two bases is implemented once")
        #expect(z.components(separatedBy: "    std::string m_label;\n").count == 2, "and stored once")
    }

    @Test("Types of other packages are written with their namespaces, and a subclass includes its base")
    @MainActor
    func otherPackages() async throws {
        let all = try await crossFiles()
        let base = try #require(all["cross/Base.hpp"])
        #expect(base.contains("    virtual ::cross::sub::Level getLevel() const = 0;"))
        #expect(base.contains("    virtual const ::cross::sub::Tag &getTag() const = 0;"))
        #expect(base.contains("    virtual std::vector<std::shared_ptr<::cross::sub::Child>> &getKids() = 0;"))
        #expect(base.contains("    ::cross::sub::Level m_level = ::cross::sub::Level::High;\n"))
        #expect(base.contains("    std::vector<::cross::sub::Level> m_levels;\n"))
        #expect(base.contains("\nnamespace cross::sub { class Child; }\n"))
        #expect(base.contains("#include \"cross/sub/Level.hpp\"\n"))
        #expect(base.contains("#include \"cross/sub/Tag.hpp\"\n"))
        #expect(!base.contains("#include \"cross/sub/Child.hpp\""))
        let child = try #require(all["cross/sub/Child.hpp"])
        #expect(child.contains("\nnamespace cross::sub {\n"))
        #expect(child.contains("class Child final : public virtual ::cross::Base {"))
        #expect(child.contains("#include \"cross/Base.hpp\"\n"))
        #expect(child.contains("    Level getLevel() const override { return m_level; }"))
        #expect(child.contains("    Level m_level = Level::High;\n"))
        #expect(child.contains("    std::shared_ptr<::cross::Base> getParent() const { return m_parent.lock(); }"))
        #expect(child.contains("    std::weak_ptr<Child> m_other;\n"))
        #expect(child.contains("SubPackage::instance().childClass()"))
        let package = try #require(all["cross/sub/SubPackage.hpp"])
        #expect(package.contains(#"ClassInfo{"Child", false, {"Base"}, {"#))
    }

    // MARK: - Features

    @Test("Attributes are stored by value with their defaults, strings and vectors start empty")
    @MainActor
    func attributeStorage() async throws {
        let book = try await files("library", ["library/Book.hpp"])[0]
        #expect(book.contains("    std::int32_t m_loanDays = 14;\n"))
        #expect(book.contains("    bool m_onLoan = false;\n"))
        #expect(book.contains("    std::string m_name;\n"))
        #expect(book.contains("    std::int32_t m_pages = 100;\n"))
        #expect(book.contains("    BookCategory m_category = BookCategory::Mystery;\n"))
        #expect(book.contains("    ISBN m_isbn;\n"))
        #expect(book.contains("    const ISBN &getIsbn() const { return m_isbn; }"))
        #expect(book.contains("    BookCategory getCategory() const { return m_category; }"))
        #expect(book.contains("    void setCategory(BookCategory value) { m_category = value; }"))
        let writer = try await files("library", ["library/Writer.hpp"])[0]
        #expect(writer.contains("    std::vector<std::string> m_aliases;\n"))
        #expect(writer.contains("    std::vector<std::string> &getAliases() { return m_aliases; }"))
        #expect(writer.contains("    const std::vector<std::string> &getAliases() const { return m_aliases; }"))
        #expect(!writer.contains("setAliases"), "a many-valued feature is changed through its vector")
    }

    @Test("Defaults of the model become C++ values")
    @MainActor
    func defaults() async throws {
        let all = try await allFiles("cnames")
        let vehicle = try #require(all["cnames/Vehicle.hpp"])
        #expect(vehicle.contains("    double m_signed = 1.5;\n"))
        #expect(vehicle.contains("    bool m_bool = true;\n"))
        #expect(vehicle.contains(#"    std::string m_default = "say \"hi\"\n\\there";"# + "\n"))
        #expect(vehicle.contains("    Mode m_mode = Mode::and_;\n"))
        #expect(vehicle.contains("    std::int64_t m_size_t = 0;\n"))
        #expect(vehicle.contains("    std::vector<Mode> m_modes;\n"))
        #expect(try #require(all["cnames/Truck.hpp"]).contains(#"    std::string m_goto = "N/A";"# + "\n"))
    }

    @Test("Every type of the table is stored as its C++ type, boxed ones as optional values")
    @MainActor
    func valueTypes() async throws {
        let all = try await valuesFiles()
        let a = try #require(all["values/A.hpp"])
        for line in [
            "    std::int32_t m_x = -3;", "    std::optional<std::int32_t> m_boxed = 7;", "    std::optional<bool> m_flag;",
            "    char16_t m_letter = 81;", "    float m_ratio = 0.25;", "    std::chrono::system_clock::time_point m_when;",
            "    std::vector<std::uint8_t> m_blob;", "    std::any m_any;", "    std::string m_big;",
            "    std::vector<Colour> m_colours;", "    Empty m_empty = static_cast<Empty>(0);",
            "    std::int64_t m_huge = 99999999999;", "    std::int8_t m_tiny = 0;", "    std::int16_t m_small = 0;",
            "    std::string m_money;", #"    std::string m_quote = "say \"hi\"\n\\there";"#,
            "    std::optional<char16_t> m_maybeLetter;", "    double m_precise = 2.5;",
        ] {
            #expect(a.contains(line + "\n"), "'\(line)' is missing")
        }
        for line in [
            "    std::optional<std::int32_t> getBoxed() const override { return m_boxed; }",
            "    void setBoxed(std::optional<std::int32_t> value) override { m_boxed = value; }",
            "    std::chrono::system_clock::time_point getWhen() const override { return m_when; }",
            "    const std::vector<std::uint8_t> &getBlob() const override { return m_blob; }",
            "    const std::any &getAny() const override { return m_any; }",
            "    char16_t getLetter() const override { return m_letter; }",
            "    virtual std::optional<std::int32_t> getBoxed() const = 0;",
            "    virtual std::vector<Colour> &getColours() = 0;",
            "    virtual const std::vector<Colour> &getColours() const = 0;",
        ] {
            #expect(a.contains(line + "\n"), "'\(line)' is missing")
        }
        let empty = try #require(all["values/Empty.hpp"])
        #expect(empty.contains("enum class Empty : std::int32_t {\n};\n"))
        #expect(empty.contains("inline std::optional<Empty> parseEmpty([[maybe_unused]] std::string_view text) {"))
        let colour = try #require(all["values/Colour.hpp"])
        #expect(colour.contains("    crimson = 0,\n"), "a literal that repeats a value is an enumerator with that value")
        #expect(colour.contains(#"    case Colour::red: return "red";"#))
        #expect(!colour.contains("case Colour::crimson"), "only the first literal of a value is converted to text")
        #expect(colour.contains(#"    if (text == "crimson") return Colour::crimson;"#))
        for header in ["<any>", "<chrono>", "<cstdint>", "<optional>", "<string>", "<vector>"] {
            #expect(a.contains("#include \(header)\n"), "A lacks \(header)")
        }
    }

    @Test("Single references that do not contain are weak; contained and many-valued ones are strong")
    @MainActor
    func ownership() async throws {
        let book = try await files("library", ["library/Book.hpp"])[0]
        #expect(book.contains("    std::weak_ptr<Writer> m_author;\n"))
        #expect(book.contains("    std::shared_ptr<Writer> getAuthor() const { return m_author.lock(); }"))
        #expect(book.contains("    void setAuthor(const std::shared_ptr<Writer> &value) { m_author = value; }"))
        #expect(book.contains("\nnamespace library { class Writer; }\n"))
        #expect(!book.contains("#include \"library/Writer.hpp\""), "a reference needs no more than a declaration")
        let library = try await files("library", ["library/Library.hpp"])[0]
        #expect(library.contains("    std::vector<std::shared_ptr<Book>> m_books;\n"))
        #expect(!library.contains("weak_ptr"))
        let writer = try await files("library", ["library/Writer.hpp"])[0]
        #expect(writer.contains("    std::vector<std::weak_ptr<Book>> m_books;\n"))
        let canvas = try await files("classes", ["classes/Canvas.hpp"])[0]
        #expect(canvas.contains("    std::shared_ptr<Shape> m_background;\n"), "a containment is strong")
        #expect(canvas.contains("    std::weak_ptr<Shape> m_selected;\n"))
        #expect(canvas.contains("    std::vector<std::weak_ptr<Shape>> m_favourites;\n"))
        #expect(canvas.contains("    std::vector<std::shared_ptr<Shape>> m_shapes;\n"))
        let ecore = try await files("ecoretypes", ["bridge/Span.hpp"])[0]
        #expect(ecore.contains("    std::vector<std::shared_ptr<EObject>> m_supports;\n"))
        #expect(ecore.contains("    std::weak_ptr<Span> m_next;\n"))
        #expect(ecore.contains("    std::any m_payload;\n"))
    }

    @Test("Setting a reference does not change its opposite")
    @MainActor
    func oppositesAreNotKeptInStep() async throws {
        let book = try await files("library", ["library/Book.hpp"])[0]
        #expect(book.contains("void setAuthor(const std::shared_ptr<Writer> &value) { m_author = value; }"))
        let driver = try await files("cnames", ["cnames/Driver.hpp"])[0]
        #expect(driver.contains("void setVehicle(const std::shared_ptr<Vehicle> &value) { m_vehicle = value; }"))
    }

    // MARK: - Other classifiers

    @Test("Enumerations are scoped enumerations with functions for the text of their literals")
    @MainActor
    func enumerations() async throws {
        let all = try await allFiles("enumerations")
        let colour = try #require(all["enumerations/Colour.hpp"])
        #expect(colour.contains("enum class Colour : std::int32_t {"))
        #expect(colour.contains("    Amber = 1,\n"))
        #expect(colour.contains("    Yellow = 1,\n"))
        #expect(colour.contains(#"    case Colour::Amber: return "amber";"#))
        #expect(!colour.contains("case Colour::Yellow"))
        #expect(colour.contains(#"    if (text == "yellow") return Colour::Yellow;"#))
        #expect(colour.contains("constexpr std::string_view literalOf(Colour value) {"))
        #expect(colour.contains("inline std::optional<Colour> parseColour(std::string_view text) {"))
        #expect(colour.contains("    return std::nullopt;\n"))
        let mode = try #require(all["enumerations/Mode.hpp"])
        #expect(mode.contains("    default_ = 0,\n"))
        #expect(mode.contains("    _ = 3,\n"))
        #expect(mode.contains(#"case Mode::quote: return "say \"hi\"";"#))
        let empty = try #require(all["enumerations/Empty.hpp"])
        #expect(empty.contains("enum class Empty : std::int32_t {\n};\n"))
        let light = try #require(all["enumerations/Light.hpp"])
        #expect(light.contains("#include \"enumerations/Colour.hpp\""))
        #expect(light.contains("#include \"enumerations/Mode.hpp\""))
        #expect(light.contains("    Colour m_colour = Colour::Red;\n"))
        #expect(light.contains("    Mode m_mode = Mode::default_;\n"))
    }

    @Test("Data types become aliases of the mapped type")
    @MainActor
    func dataTypes() async throws {
        let all = try await allFiles("datatypes")
        #expect(all["datatypes/Count.hpp"]?.contains("using Count = std::int32_t;\n") == true)
        #expect(all["datatypes/Stamp.hpp"]?.contains("using Stamp = std::chrono::system_clock::time_point;\n") == true)
        #expect(all["datatypes/Hidden.hpp"]?.contains("using Hidden = std::string;\n") == true)
        #expect(all["datatypes/Anything.hpp"]?.contains("using Anything = std::any;\n") == true)
        #expect(all["datatypes/Stamp.hpp"]?.contains("\n#include <chrono>\n") == true)
        #expect(all["datatypes/Anything.hpp"]?.contains("\n#include <any>\n") == true)
    }

    @Test("The package description holds the classes, their supertypes and features, and accessors for them")
    @MainActor
    func packageDescription() async throws {
        let package = try await files("library", ["library/LibraryPackage.hpp"])[0]
        #expect(package.contains("class LibraryPackage final {"))
        #expect(package.contains("    static const LibraryPackage &instance() {\n        static const LibraryPackage description;\n        return description;\n    }"))
        #expect(package.contains("    std::string_view name() const { return m_info.name; }"))
        #expect(package.contains("    std::string_view nsURI() const { return m_info.nsURI; }"))
        #expect(package.contains("    std::string_view nsPrefix() const { return m_info.nsPrefix; }"))
        #expect(package.contains("    const PackageInfo &info() const { return m_info; }"))
        #expect(package.contains("    const ClassInfo &bookClass() const { return m_info.classes[2]; }"))
        #expect(package.contains("    const ClassInfo &namedClass() const { return m_info.classes[0]; }"))
        #expect(package.contains(#"        m_info.name = "library";"#))
        #expect(package.contains(#"        m_info.nsURI = "http://swift-modelling.org/test/library/1.0";"#))
        #expect(package.contains(#"        m_info.nsPrefix = "lib";"#))
        #expect(package.contains(#"            ClassInfo{"Named", true, {}, {"#))
        #expect(package.contains(#"            ClassInfo{"Book", false, {"Named", "Lendable"}, {"#))
        #expect(package.contains(#"                FeatureInfo{"name", FeatureKind::attribute, false, "EString"},"#))
        #expect(package.contains(#"                FeatureInfo{"aliases", FeatureKind::attribute, true, "EString"},"#))
        #expect(package.contains(#"                FeatureInfo{"category", FeatureKind::attribute, false, "BookCategory"},"#))
        #expect(package.contains(#"                FeatureInfo{"author", FeatureKind::reference, false, "Writer"},"#))
        #expect(package.contains(#"                FeatureInfo{"books", FeatureKind::containment, true, "Book"},"#))
        #expect(package.contains("    PackageInfo m_info;"))
        #expect(!package.contains("#include \"library/"), "the description includes no class")
        let values = try await valuesFiles()
        let description = try #require(values["values/ValuesPackage.hpp"])
        #expect(description.contains(#"ClassInfo{"F", false, {"A", "B", "C", "D"}, {"#), "all supertypes, not only the direct one")
        #expect(description.contains(#"ClassInfo{"A", false, {}, {"#))
        #expect(description.components(separatedBy: #"FeatureInfo{"x", FeatureKind::attribute, false, "EInt"},"#).count - 1 >= 5)
    }

    @Test("The factory creates the classes that have instances, and creates by the name of a class")
    @MainActor
    func factory() async throws {
        let factory = try await files("library", ["library/LibraryFactory.hpp"])[0]
        #expect(factory.contains("class LibraryFactory final {"))
        #expect(factory.contains("    static const LibraryFactory &instance() {\n        static const LibraryFactory factory;\n        return factory;\n    }"))
        #expect(factory.contains("    std::shared_ptr<Book> createBook() const { return std::make_shared<Book>(); }"))
        #expect(factory.contains("    std::shared_ptr<Library> createLibrary() const { return std::make_shared<Library>(); }"))
        #expect(!factory.contains("createNamed") && !factory.contains("createLendable"))
        #expect(factory.contains("    std::shared_ptr<EObject> create([[maybe_unused]] std::string_view className) const {"))
        #expect(factory.contains(#"        if (className == "Book") return createBook();"#))
        #expect(factory.contains("        return nullptr;\n"))
        for header in ["EObject.hpp", "library/Book.hpp", "library/Library.hpp", "library/Writer.hpp"] {
            #expect(factory.contains("#include \"\(header)\"\n"), "the factory lacks \(header)")
        }
        #expect(!factory.contains("library/Named.hpp"))
    }

    @Test("Operations of the model are not part of the generated code")
    @MainActor
    func operationsAreNotGenerated() async throws {
        let all = try await allFiles("classes")
        #expect(all.values.allSatisfy { !$0.contains("area(") && !$0.contains("move(") })
    }

    @Test("Model documentation becomes documentation comments, its first paragraph the brief description")
    @MainActor
    func documentation() async throws {
        let level = try await files("documented", ["documented/Level.hpp"])[0]
        #expect(level.contains("/// @brief The levels of an alarm.\n/// Higher levels need quicker action.\n// @generated\nenum class Level"))
        #expect(level.contains("    /// @brief Immediate action.\n    /// Wake somebody.\n    // @generated\n    High = 1,"))
        #expect(level.contains("    /// @deprecated use High\n    // @generated\n    Old = 2,"), "a comment that starts with a command is left alone")
        #expect(level.contains("    /// @brief The Low literal.\n"), "an undocumented element gets a generated description")
        let vehicle = try await files("cnames", ["cnames/Vehicle.hpp"])[0]
        #expect(vehicle.contains("/// @brief A vehicle, which other classes extend.\n///\n/// Its features are named with words that C and C++ reserve.\n// @generated\nclass Vehicle"))
        let book = try await files("library", ["library/Book.hpp"])[0]
        #expect(book.contains("/// @brief The Book class.\n///\n/// Part of the library package.\n// @generated\nclass Book final"))
        #expect(book.contains("    /// @brief Changes the pages attribute.\n    /// @param value The new value.\n"))
        #expect(book.contains("    /// @return The current value of the pages attribute.\n"))
    }
}
