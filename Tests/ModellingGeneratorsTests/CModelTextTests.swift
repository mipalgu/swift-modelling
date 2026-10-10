import Foundation
import Testing

@testable import ModellingGenerators

/// Checks the text of the C code that the template set writes for fixtures.
@Suite("C model text")
struct CModelTextTests {
    /// Generates a fixture and reads all of its files.
    ///
    /// - Parameter fixture: The name of the fixture.
    /// - Returns: The text of every generated file by its path relative to the output directory.
    @MainActor
    func allFiles(_ fixture: String) async throws -> [String: String] {
        let golden = try #require(CGoldenCase.named(fixture))
        let generated = try await generateC(golden)
        defer { generated.remove() }
        return Dictionary(uniqueKeysWithValues: try generated.generatedPaths().map { ($0, try generated.text($0)) })
    }

    // MARK: - Layout of the text

    @Test("Documentation comment, tag and declaration stand on lines of their own", arguments: CGoldenCase.all)
    @MainActor
    func declarationsHaveTheirOwnLines(_ golden: CGoldenCase) async throws {
        let generated = try await generateC(golden)
        defer { generated.remove() }
        for path in generated.generatedPaths() {
            let lines = try generated.text(path).components(separatedBy: "\n")
            for (index, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed == "// @generated" {
                    let next = lines[index + 1].trimmingCharacters(in: .whitespaces)
                    #expect(!next.isEmpty && !next.hasPrefix("//"), "\(path): the tag on line \(index + 1) has no declaration")
                }
                #expect(!line.contains("///<"), "\(path): a trailing documentation comment on line \(index + 1)")
                if line.contains("///") {
                    #expect(trimmed.hasPrefix("///"), "\(path): a comment shares a line with code on line \(index + 1)")
                }
            }
        }
    }

    @Test("Every member of a generated file carries the generated tag", arguments: CGoldenCase.all)
    @MainActor
    func membersAreTagged(_ golden: CGoldenCase) async throws {
        let generated = try await generateC(golden)
        defer { generated.remove() }
        for path in generated.generatedPaths() {
            let lines = try generated.text(path).components(separatedBy: "\n")
            let isPackageHeader = path.hasSuffix(".h") && path != "EObject.h"
            for (index, line) in lines.enumerated() where index > 0 {
                let topLevel =
                    !line.hasPrefix(" ") && !line.isEmpty
                    && !["#", "/", "}", "{", ")"].contains { line.hasPrefix($0) }
                let field =
                    isPackageHeader && line.hasPrefix("    ") && !line.hasPrefix("     ")
                    && !line.hasPrefix("    //")
                if topLevel || field {
                    #expect(
                        lines[index - 1].trimmingCharacters(in: .whitespaces) == "// @generated",
                        "\(path): '\(line.trimmingCharacters(in: .whitespaces))' lacks the generated tag")
                }
            }
        }
    }

    @Test("Files include the headers of the types in use, sorted and once", arguments: CGoldenCase.all)
    @MainActor
    func includesDeclareTheTypesInUse(_ golden: CGoldenCase) async throws {
        let generated = try await generateC(golden)
        defer { generated.remove() }
        for path in generated.generatedPaths() {
            let text = try generated.text(path)
            let includes = text.components(separatedBy: "\n").filter { $0.hasPrefix("#include ") }
            #expect(includes == includes.sorted() && Set(includes).count == includes.count, "\(path): includes in order, once")
            #expect(!text.contains("\u{2014}"), "\(path) has an em-dash")
            if path.hasSuffix(".h") {
                if path != "EObject.h" { #expect(includes.contains("#include \"EObject.h\""), "\(path) lacks EObject.h") }
                if text.contains("bool ") { #expect(includes.contains("#include <stdbool.h>"), "\(path) lacks stdbool.h") }
                if text.contains("size_t ") { #expect(includes.contains("#include <stddef.h>"), "\(path) lacks stddef.h") }
                if text.contains("int32_t ") || text.contains("int64_t ") || text.contains("uint8_t ") {
                    #expect(includes.contains("#include <stdint.h>"), "\(path) lacks stdint.h")
                }
            } else {
                let header = String(path.dropLast(2)) + ".h"
                #expect(includes.contains("#include \"\(header)\""), "\(path) lacks its own header")
                if text.contains("free(") || text.contains("malloc(") {
                    #expect(includes.contains("#include <stdlib.h>"), "\(path) lacks stdlib.h")
                }
                if text.contains("strcmp(") || text.contains("memmove(") {
                    #expect(includes.contains("#include <string.h>"), "\(path) lacks string.h")
                }
            }
        }
    }

    @Test("The file headers name the file and carry the copyright text")
    @MainActor
    func headers() async throws {
        let library = try await allFiles("library")
        #expect(
            library["library/library.h"]?.hasPrefix(
                "//\n//  library.h\n//\n//  Copyright 2026 Example Pty Ltd\n//\n\n#ifndef LIBRARY_LIBRARY_H\n#define LIBRARY_LIBRARY_H\n\n#include \"EObject.h\"\n#include <stdbool.h>\n#include <stddef.h>\n#include <stdint.h>\n\n#ifdef __cplusplus\n// @generated\nextern \"C\" {\n#endif\n\n"
            ) == true)
        #expect(
            library["library/library.c"]?.hasPrefix(
                "//\n//  library.c\n//\n//  Copyright 2026 Example Pty Ltd\n//\n\n#include \"library/library.h\"\n#include <stdlib.h>\n#include <string.h>\n\n"
            ) == true)
        let bare = try await allFiles("bare")
        #expect(bare["bare/bare.h"]?.hasPrefix("//\n//  bare.h\n//\n\n#ifndef BARE_BARE_H\n") == true)
        #expect(bare["EObject.h"]?.hasPrefix("//\n//  EObject.h\n//\n\n#ifndef EOBJECT_H\n#define EOBJECT_H\n\n") == true)
    }

    @Test("The declarations of a header stand in a block with C linkage")
    @MainActor
    func cLinkage() async throws {
        let all = try await allFiles("library")
        for path in ["EObject.h", "library/library.h"] {
            let text = try #require(all[path])
            #expect(text.contains("#ifdef __cplusplus\n// @generated\nextern \"C\" {\n#endif\n"))
            #expect(text.hasSuffix("#ifdef __cplusplus\n}\n#endif\n\n#endif\n"))
        }
    }

    // MARK: - The support header

    @Test("The support header declares the object header, the descriptions and the helper functions")
    @MainActor
    func supportHeader() async throws {
        let text = try #require(try await allFiles("bare")["EObject.h"])
        #expect(text.contains("struct EObject {\n    /// @brief The description of the class of the object.\n    // @generated\n    const EClassInfo *eClass;\n};\n"))
        #expect(text.contains("    EFeatureKind_Attribute,\n"))
        #expect(text.contains("    EFeatureKind_Containment\n"))
        #expect(text.contains("    EObject *(*create)(void);\n"))
        #expect(text.contains("    void (*destroy)(EObject *);\n"))
        #expect(text.contains("    const EClassInfo *const *superTypes;\n"))
        #expect(text.contains("    uint8_t *bytes;\n"))
        #expect(text.contains("#define EList(ItemType) struct { ItemType *items; size_t count; size_t capacity; }\n"))
        for function in [
            "static inline bool EClassInfo_conformsTo(const EClassInfo *candidate, const EClassInfo *eClass) {",
            "static inline bool EObject_isKindOf(const EObject *object, const EClassInfo *eClass) {",
            "static inline void EObject_destroy(EObject *object) {",
            "static inline char *EObject_duplicateString(const char *text) {",
            "static inline bool EObject_duplicateBytes(EByteArray value, EByteArray *copy) {",
            "static inline void *EObject_grown(void *items, size_t *capacity, size_t itemSize) {",
        ] {
            #expect(text.contains("// @generated\n" + function + "\n"), "\(function) is missing or untagged")
        }
        #expect(!text.contains("strdup"), "strdup is not ISO C")
        #expect(text.contains("if (*capacity > SIZE_MAX / 2) {"), "the growth of a list is checked for overflow")
        #expect(text.contains("grown > SIZE_MAX / itemSize"), "the size of a list is checked for overflow")
    }

    // MARK: - Names

    @Test("Names that C or C++ reserve get a trailing underscore wherever they name a type, field or parameter")
    @MainActor
    func escapedNames() async throws {
        let all = try await allFiles("cnames")
        let header = try #require(all["cnames/cnames.h"])
        for declaration in [
            "int32_t int_", "char *register_", "bool union_", "char *class_", "char *namespace_", "int32_t new_",
            "bool delete_", "char *template_", "char *this_", "double signed_", "char *NULL_", "char *eObject_",
            "bool bool_", "char *default_", "int64_t size_t_",
        ] {
            #expect(header.contains("    \(declaration);\n"), "the field '\(declaration)' is missing")
        }
        #expect(header.contains("typedef struct static_ static_;\n"))
        #expect(header.contains("typedef struct FILE_ FILE_;\n"))
        #expect(header.contains("typedef struct EObject_ EObject_;\n"))
        #expect(header.contains("struct static_ {\n"))
        #expect(header.contains("    static_ *static__;\n"), "a field that takes the name of a type in use is escaped once more")
        #expect(header.contains("typedef int64_t size_t_;\n"))
        #expect(header.contains("void Vehicle_set_int(Vehicle *self, int32_t value);\n"), "function names need no escape")
        #expect(header.contains("static_ *Vehicle_get_static(const Vehicle *self);\n"))
        #expect(header.contains("static_ *static__create(void);\n"))
        #expect(header.contains("extern const EClassInfo static__class;\n"))
        #expect(header.contains("EObject_ *EObject__create(void);\n"), "a class named like the support header gets its own prefix")
        #expect(header.contains("void EObject__destroy(EObject_ *self);\n"))
        #expect(header.contains("bool EObject__set_eClass(EObject_ *self, const char *value);\n"))
        #expect(header.contains("    Mode_NULL = 3,\n"), "constants are made of two words")
        #expect(header.contains("    Mode_default = 1,\n"))
        #expect(header.contains("    EList(Mode) modes;\n"))
        #expect(header.contains("Mode Vehicle_item_modes(const Vehicle *self, size_t index);\n"))
        #expect(!header.contains("    int int;"))
    }

    @Test("Names in nested packages get directories, guards and descriptions of their own")
    @MainActor
    func nestedPackages() async throws {
        let all = try await allFiles("cnames")
        let wheel = try #require(all["cnames/delete/delete.h"])
        #expect(wheel.contains("#ifndef CNAMES_DELETE_DELETE_H\n#define CNAMES_DELETE_DELETE_H\n"))
        #expect(wheel.contains("    char *auto_;\n"))
        #expect(wheel.contains("    EObject *virtual_;\n"), "a class that others extend is a plain object")
        #expect(wheel.contains("extern const EPackageInfo DeletePackage;\n"))
        #expect(wheel.contains("EObject *DeleteFactory_create(const EClassInfo *eClass);\n"))
        let source = try #require(all["cnames/delete/delete.c"])
        #expect(source.contains("#include \"cnames/delete/delete.h\"\n"))
        #expect(source.contains("    .nsURI = \"http://swift-modelling.org/test/cnames/delete\",\n"))
        let root = try #require(all["cnames/cnames.h"])
        #expect(root.contains("typedef struct Wheel Wheel;\n"), "a class of another package is declared but not defined")
        #expect(root.contains("    EList(Wheel *) wheels;\n"))
        #expect(!root.contains("struct Wheel {"))
        #expect(!root.contains("#include \"cnames/delete/delete.h\""), "headers do not include each other for classes")
    }

    @Test("Packages are named from their prefix")
    @MainActor
    func packageNames() async throws {
        let org = try await allFiles("organisation")
        let header = try #require(org["organisation/organisation.h"])
        #expect(header.contains("extern const EPackageInfo OrgPackage;\n"))
        #expect(header.contains("EObject *OrgFactory_create(const EClassInfo *eClass);\n"))
        let source = try #require(org["organisation/organisation.c"])
        #expect(source.contains("static const EClassInfo *const OrgPackage_classes[] = {\n"))
        #expect(source.contains("const EPackageInfo OrgPackage = {\n"))
        let nested = try await allFiles("nested")
        let projects = try #require(nested["company/projects/projects.h"])
        #expect(projects.contains("extern const EPackageInfo ProjPackage;\n"))
        #expect(projects.contains("EObject *ProjFactory_create(const EClassInfo *eClass);\n"))
        let archive = try #require(nested["company/projects/archive/archive.h"])
        #expect(archive.contains("extern const EPackageInfo ArchivePackage;\n"))
        #expect(archive.contains("#ifndef COMPANY_PROJECTS_ARCHIVE_ARCHIVE_H\n"))
    }

    // MARK: - Classes

    @Test("Abstract classes and interfaces have a description and nothing else; classes with instances have a structure")
    @MainActor
    func structuresAndDescriptions() async throws {
        let all = try await allFiles("library")
        let header = try #require(all["library/library.h"])
        #expect(header.contains("extern const EClassInfo Named_class;\n"))
        #expect(header.contains("extern const EClassInfo Lendable_class;\n"))
        #expect(!header.contains("struct Named"))
        #expect(!header.contains("struct Lendable"))
        #expect(!header.contains("Named_create"))
        #expect(!header.contains("Lendable_get_loanDays"))
        #expect(header.contains("typedef struct Book Book;\n"))
        #expect(header.contains("struct Book {\n"))
        #expect(header.contains("Book *Book_create(void);\n"))
        #expect(header.contains("void Book_destroy(Book *self);\n"))
        let source = try #require(all["library/library.c"])
        #expect(source.contains("    .isAbstract = true,\n"))
        #expect(source.contains("    .create = NULL,\n    .destroy = NULL\n};\n"))
        #expect(source.contains("    .create = Book_create_object,\n    .destroy = Book_destroy_object\n};\n"))
        #expect(source.contains("static const EClassInfo *const Book_superTypes[] = { &Named_class, &Lendable_class };\n"))
        #expect(source.contains("    .superTypeCount = 2,\n"))
    }

    @Test("A class keeps a copy of the features it inherits, the inherited ones first")
    @MainActor
    func inheritedFeatures() async throws {
        let all = try await allFiles("library")
        let header = try #require(all["library/library.h"])
        let book = try #require(header.range(of: "struct Book {\n"))
        let end = try #require(header.range(of: "\n};\n", range: book.upperBound..<header.endIndex))
        let fields = header[book.upperBound..<end.lowerBound].components(separatedBy: "\n").filter {
            $0.hasPrefix("    ") && !$0.hasPrefix("    //") && !$0.trimmingCharacters(in: .whitespaces).isEmpty
        }
        #expect(
            fields.map { $0.trimmingCharacters(in: .whitespaces) } == [
                "EObject eObject;", "char *name;", "int32_t loanDays;", "bool onLoan;", "int32_t pages;",
                "BookCategory category;", "ISBN isbn;", "Writer *author;", "Library *library;",
            ])
        #expect(header.contains("const char *Book_get_name(const Book *self);\n"))
        #expect(header.contains("int32_t Book_get_loanDays(const Book *self);\n"))
        let source = try #require(all["library/library.c"])
        #expect(source.contains("    { .name = \"name\", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = \"EString\" },\n"))
        #expect(source.contains("    .featureCount = 8,\n"))
    }

    @Test("A class that others extend keeps its structure, and references to it are plain objects")
    @MainActor
    func extendedClasses() async throws {
        let all = try await allFiles("cnames")
        let header = try #require(all["cnames/cnames.h"])
        #expect(header.contains("struct Vehicle {\n"))
        #expect(header.contains("struct Truck {\n"))
        #expect(header.contains("Vehicle *Vehicle_create(void);\n"))
        let driver = try #require(header.range(of: "struct Driver {\n"))
        #expect(header[driver.upperBound...].hasPrefix("    /// @brief The header that every model object starts with"))
        #expect(header.contains("    EObject *vehicle;\n"))
        #expect(header.contains("    Driver *driver;\n"))
        #expect(header.contains("    Truck *trailer;\n"), "a class that nobody extends is referred to by its structure")
        let source = try #require(all["cnames/cnames.c"])
        #expect(source.contains("static const EClassInfo *const Truck_superTypes[] = { &Vehicle_class };\n"))
    }

    @Test("A class without features or supertypes has no empty tables")
    @MainActor
    func emptyTables() async throws {
        let source = try #require(try await allFiles("bare")["bare/bare.c"])
        #expect(!source.contains("Thing_features"))
        #expect(!source.contains("Thing_superTypes"))
        #expect(source.contains("    .superTypes = NULL,\n    .superTypeCount = 0,\n    .features = NULL,\n    .featureCount = 0,\n"))
        let documented = try #require(try await allFiles("documented")["documented/documented.c"])
        #expect(!documented.contains("DocumentedPackage_classes"), "a package without classes has no list of classes")
        #expect(documented.contains("    .classes = NULL,\n    .classCount = 0\n"))
    }

    // MARK: - Features

    @Test("Attributes are fields of the C type, with the model defaults as initial values")
    @MainActor
    func attributeTypes() async throws {
        let all = try await allFiles("library")
        let header = try #require(all["library/library.h"])
        #expect(header.contains("    int32_t loanDays;\n"))
        #expect(header.contains("    bool onLoan;\n"))
        #expect(header.contains("    char *name;\n"))
        #expect(header.contains("    BookCategory category;\n"))
        #expect(header.contains("    ISBN isbn;\n"))
        #expect(header.contains("    EList(char *) aliases;\n"))
        #expect(header.contains("    EList(Book *) books;\n"))
        let source = try #require(all["library/library.c"])
        #expect(source.contains("    self->loanDays = 14;\n"))
        #expect(source.contains("    self->pages = 100;\n"))
        #expect(source.contains("    self->onLoan = false;\n"))
        #expect(source.contains("    self->category = BookCategory_Mystery;\n"))
        #expect(source.contains("    self->name = NULL;\n"))
        #expect(source.contains("    self->aliases.items = NULL;\n    self->aliases.count = 0;\n    self->aliases.capacity = 0;\n"))
        #expect(source.contains("    self->eObject.eClass = &Book_class;\n"))
    }

    @Test("Defaults of the model become C values")
    @MainActor
    func defaults() async throws {
        let cnames = try await allFiles("cnames")
        let source = try #require(cnames["cnames/cnames.c"])
        #expect(source.contains("    self->signed_ = 1.5;\n"))
        #expect(source.contains("    self->bool_ = true;\n"))
        #expect(source.contains("    self->mode = Mode_and;\n"))
        #expect(source.contains("    self->default_ = EObject_duplicateString(\"say \\\"hi\\\"\\n\\\\there\");\n"))
        #expect(source.contains("    self->goto_ = EObject_duplicateString(\"N/A\");\n"))
        #expect(source.contains("    if (self->default_ == NULL) {\n        Vehicle_destroy(self);\n        return NULL;\n    }\n"))
        let classes = try await allFiles("classes")
        let shapes = try #require(classes["classes/classes.c"])
        #expect(shapes.contains("    self->visible = true;\n"))
        #expect(shapes.contains("    self->weight = 1.5;\n"))
        #expect(shapes.contains("    self->colour = Colour_Green;\n"))
        #expect(shapes.contains("    self->radius = 0.0;\n"))
    }

    @Test("References are pointers; containment owns its targets and plain references do not")
    @MainActor
    func ownership() async throws {
        let library = try await allFiles("library")
        let source = try #require(library["library/library.c"])
        #expect(source.contains("    EObject_destroy((EObject *)self->books.items[index]);\n"))
        #expect(source.contains("        EObject_destroy((EObject *)self->books.items[position]);\n"))
        #expect(source.contains("    Library_clear_books(self);\n"))
        let writer = try #require(source.range(of: "void Writer_destroy(Writer *self) {\n"))
        let writerEnd = try #require(source.range(of: "\n}\n", range: writer.upperBound..<source.endIndex))
        #expect(!source[writer.lowerBound..<writerEnd.upperBound].contains("EObject_destroy"), "a plain reference owns nothing")
        let classes = try await allFiles("classes")
        let canvas = try #require(classes["classes/classes.c"])
        #expect(canvas.contains("    if (self->background != value) {\n        EObject_destroy((EObject *)self->background);\n        self->background = value;\n    }\n"))
        #expect(canvas.contains("void Canvas_set_selected(Canvas *self, EObject *value) {\n    self->selected = value;\n}\n"))
        let ecore = try await allFiles("ecoretypes")
        let span = try #require(ecore["bridge/bridge.h"])
        #expect(span.contains("    EList(EObject *) supports;\n"), "a class of Ecore is a plain object")
        #expect(span.contains("    void *payload;\n"), "an unknown value is a pointer that the object does not own")
        #expect(span.contains("    Span *next;\n"))
    }

    @Test("Text and bytes are copied when they are stored, and a failed copy keeps the old value")
    @MainActor
    func copiedValues() async throws {
        let library = try await allFiles("library")
        let source = try #require(library["library/library.c"])
        #expect(source.contains(
            "bool Book_set_name(Book *self, const char *value) {\n    char *copy = EObject_duplicateString(value);\n    if (copy == NULL && value != NULL) {\n        return false;\n    }\n    free(self->name);\n    self->name = copy;\n    return true;\n}\n"))
        #expect(source.contains("const char *Book_get_name(const Book *self) {\n    return self->name;\n}\n"))
        #expect(source.contains("bool Writer_add_aliases(Writer *self, const char *value) {\n    char *copy = EObject_duplicateString(value);\n"))
        #expect(source.contains("            free(copy);\n            return false;\n"))
        #expect(source.contains("    free(self->aliases.items[index]);\n"))
    }

    @Test("Many-valued features grow through the checked helper and shift values on removal")
    @MainActor
    func lists() async throws {
        let source = try #require(try await allFiles("library")["library/library.c"])
        #expect(source.contains("size_t Writer_count_aliases(const Writer *self) {\n    return self->aliases.count;\n}\n"))
        #expect(source.contains("    if (index >= self->aliases.count) {\n        return NULL;\n    }\n    return self->aliases.items[index];\n"))
        #expect(source.contains("        void *items = EObject_grown(self->aliases.items, &self->aliases.capacity, sizeof *self->aliases.items);\n"))
        #expect(source.contains("        if (items == NULL) {\n"))
        #expect(source.contains("    memmove(&self->aliases.items[index], &self->aliases.items[index + 1], (self->aliases.count - index - 1) * sizeof *self->aliases.items);\n"))
        #expect(source.contains("    self->aliases.count--;\n"))
        #expect(source.contains("void Writer_clear_aliases(Writer *self) {\n"))
        #expect(!source.contains("realloc("), "growth goes through the helper")
    }

    @Test("Every allocation is checked and the generated code avoids functions that are not ISO C11", arguments: CGoldenCase.all)
    @MainActor
    func allocationsAreChecked(_ golden: CGoldenCase) async throws {
        let generated = try await generateC(golden)
        defer { generated.remove() }
        for path in generated.generatedPaths() where path.hasSuffix(".c") {
            let lines = try generated.text(path).components(separatedBy: "\n")
            for (index, line) in lines.enumerated() where line.contains("malloc(") {
                #expect(lines[index + 1] == "    if (self == NULL) {", "\(path): the allocation on line \(index + 1) is not checked")
            }
            let text = lines.joined(separator: "\n")
            #expect(!text.contains("strdup("), "\(path) calls strdup")
            #expect(!text.contains("alloca("), "\(path) calls alloca")
            #expect(!text.contains("gets("), "\(path) calls gets")
        }
    }

    // MARK: - Other classifiers

    @Test("Enumerations are enums with a constant for every literal, repeated values included")
    @MainActor
    func enumerations() async throws {
        let all = try await allFiles("enumerations")
        let header = try #require(all["enumerations/enumerations.h"])
        #expect(header.contains("enum Colour {\n"))
        #expect(header.contains("    Colour_Amber = 1,\n"))
        #expect(header.contains("    Colour_Yellow = 1,\n"))
        #expect(header.contains("    /// @brief The Yellow literal, which has the value of Amber.\n"))
        #expect(header.contains("typedef enum Colour Colour;\n"))
        #expect(header.contains("const char *Colour_literal(Colour value);\n"))
        #expect(header.contains("bool Colour_from_literal(const char *literal, Colour *value);\n"))
        #expect(header.contains("    Mode__ = 3,\n"))
        #expect(header.contains("typedef int Empty;\n"), "an enumeration without literals is an integer")
        #expect(!header.contains("enum Empty"))
        #expect(header.contains("const char *Empty_literal(Empty value);\n"))
        let source = try #require(all["enumerations/enumerations.c"])
        #expect(source.contains("    case Colour_Amber:\n        return \"amber\";\n"))
        #expect(!source.contains("    case Colour_Yellow:"), "a repeated value cannot be a second case")
        #expect(source.contains("    if (strcmp(literal, \"yellow\") == 0) {\n        *value = Colour_Yellow;\n        return true;\n    }\n"))
        #expect(source.contains("    case Mode_quote:\n        return \"say \\\"hi\\\"\";\n"))
        #expect(source.contains("const char *Empty_literal(Empty value) {\n    (void)value;\n    return NULL;\n}\n"))
        #expect(source.contains("    if (literal == NULL || value == NULL) {\n        return false;\n    }\n"))
    }

    @Test("Documentation comes from the model with a brief tag, and falls back to a generated summary")
    @MainActor
    func documentation() async throws {
        let documented = try #require(try await allFiles("documented")["documented/documented.h"])
        #expect(documented.contains("/// @brief The levels of an alarm.\n/// Higher levels need quicker action.\n// @generated\nenum Level {\n"))
        #expect(documented.contains("    /// @brief Immediate action.\n    /// Wake somebody.\n    // @generated\n    Level_High = 1,\n"))
        #expect(documented.contains("    /// @deprecated use High\n    // @generated\n    Level_Old = 2,\n"))
        #expect(documented.contains("    /// @brief The Low literal.\n"))
        let classes = try #require(try await allFiles("classes")["classes/classes.h"])
        #expect(classes.contains("/// @brief A shape on a canvas.\n/// Shapes know their bounds.\n/// @since 1.2\n// @generated\nextern const EClassInfo Shape_class;\n"))
        #expect(classes.contains("    /// @brief The label of the shape.\n    // @generated\n    char *label;\n"))
        let library = try #require(try await allFiles("library")["library/library.h"])
        #expect(library.contains("/// @brief Returns the value of the pages attribute.\n///\n/// @param self The object to read.\n/// @return The value.\n// @generated\nint32_t Book_get_pages(const Book *self);\n"))
        #expect(library.contains("/// @brief Creates a Book object with all features at their defaults.\n///\n"))
        #expect(library.contains("/// @param index The position of the value, counted from zero.\n"))
    }

    @Test("Data types become type definitions for the C type of their instance class")
    @MainActor
    func dataTypes() async throws {
        let all = try await allFiles("datatypes")
        let header = try #require(all["datatypes/datatypes.h"])
        #expect(header.contains("typedef int32_t Count;\n"))
        #expect(header.contains("typedef int64_t Stamp;\n"))
        #expect(header.contains("typedef char *Hidden;\n"))
        #expect(header.contains("typedef void *Anything;\n"))
        let library = try #require(try await allFiles("library")["library/library.h"])
        #expect(library.contains("typedef char *ISBN;\n"))
        #expect(library.contains("const char *Book_get_isbn(const Book *self);\n"), "the accessors use the type of the instance class")
    }

    @Test("The package description lists its classes, and the factory creates objects of them")
    @MainActor
    func packageDescription() async throws {
        let all = try await allFiles("library")
        let source = try #require(all["library/library.c"])
        #expect(source.contains("static const EClassInfo *const LibraryPackage_classes[] = {\n    &Named_class,\n"))
        #expect(source.contains("    .name = \"library\",\n    .nsURI = \"http://swift-modelling.org/test/library/1.0\",\n    .nsPrefix = \"lib\",\n"))
        #expect(source.contains("    .classes = LibraryPackage_classes,\n    .classCount = 5\n"))
        #expect(source.contains("EObject *LibraryFactory_create(const EClassInfo *eClass) {\n"))
        #expect(source.contains("            return eClass->create == NULL ? NULL : eClass->create();\n"))
        #expect(source.contains("    { .name = \"author\", .kind = EFeatureKind_Reference, .isMany = false, .typeName = \"Writer\" },\n"))
        #expect(source.contains("    { .name = \"books\", .kind = EFeatureKind_Containment, .isMany = true, .typeName = \"Book\" },\n"))
        #expect(source.contains("static EObject *Book_create_object(void) {\n    Book *object = Book_create();\n    return object == NULL ? NULL : &object->eObject;\n}\n"))
        #expect(source.contains("static void Book_destroy_object(EObject *object) {\n    Book_destroy((Book *)object);\n}\n"))
    }

    @Test("Classes of other packages are declared where the structures refer to them, and their headers included for supertypes")
    @MainActor
    func otherPackages() async throws {
        let all = try await allFiles("nested")
        let projects = try #require(all["company/projects/projects.h"])
        #expect(projects.contains("typedef struct Employee Employee;\n"))
        let source = try #require(all["company/projects/projects.c"])
        #expect(source.contains("#include \"company/projects/projects.h\"\n"))
        let people = try #require(all["company/people/people.c"])
        #expect(people.contains("#include \"company/people/people.h\"\n"))
    }

    @Test("Operations of the model are not part of the generated code")
    @MainActor
    func operationsAreNotGenerated() async throws {
        let all = try await allFiles("library")
        #expect(all.values.allSatisfy { !$0.contains("findBooks") })
    }
}
