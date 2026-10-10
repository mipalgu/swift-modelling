# C Generation

Generate C11 model code from a generator model.

## Overview

The bundled `c` template set writes plain C11 that needs nothing but the standard library. Every class of the model becomes a structure, every enumeration an `enum` with conversion functions, and every package a description that makes the objects reflective: a program can ask an object for its class, its supertypes and its features, create objects through a factory function, and destroy them with everything they own.

```swift
let result = try await GenerationPipeline.generate(
    inputURL: URL(fileURLWithPath: "model/library.ecore"),
    language: "c",
    outputDirectory: URL(fileURLWithPath: "src"))
```

From the command line, `swift-ecore generate model/library.ecore --language c --output src` and `swift-atl generate model/library.ecore --language c --output src` do the same. A generator model works as the input as well; an Ecore model is imported into a temporary generator model first. Add `--model-directory` to write below the model directory of the generator model.

The generated headers can be included from C++ as well: the declarations stand in a block with C linkage, so a C++ program links against the C code.

### What is generated

The set writes one header and one source file for each package, not one for each classifier. A package has many small classifiers, and C has no namespaces, so a single header per package gives a program one include and keeps the declarations that refer to each other together. The files live in a directory named after the package, nested packages in nested directories, and are named after the package as well: `library/library.h` and `library/library.c`, `company/people/people.h` and `company/people/people.c`. Includes use paths relative to the output directory, so a compiler is given that directory with `-I`.

One more file is shared by all packages and written once: `EObject.h` at the root of the output directory. It does not depend on the model, so generating several models into one directory is harmless.

- `EObject.h` declares the header that starts every object (`EObject`), the descriptions of classes (`EClassInfo`), features (`EFeatureInfo`) and packages (`EPackageInfo`), the list type `EList(T)`, a byte array (`EByteArray`), and the helper functions `EObject_destroy`, `EObject_isKindOf`, `EObject_duplicateString`, `EObject_duplicateBytes` and `EObject_grown`.
- The header of a package declares a structure and its functions for every class that has instances, an `enum` for every enumeration, a type definition for every data type, the description of every class (`Book_class`), the description of the package (`LibraryPackage`) and the factory function (`LibraryFactory_create`).
- The source file of a package defines the functions, the descriptions and the factory function.

The names of the package description and the factory come from the package prefix of the generator model, as in Java and Swift.

### Classes

A class that has instances becomes a structure that starts with the object header and holds the values of all its features, those it inherits first:

```c
struct Book {
    EObject eObject;
    char *name;
    int32_t loanDays;
    ...
    Writer *author;
};
```

`Book *Book_create(void)` allocates an object with the defaults of the model and returns the null pointer if the memory runs out. `void Book_destroy(Book *self)` frees an object together with everything it owns and ignores the null pointer.

C has no inheritance, so a class keeps a copy of the features of its supertypes and gets the accessors of them under its own name: `Book_get_name` exists although `name` is a feature of `Named`. Because the object header is the first member of every structure, a pointer to any object converts to an `EObject *` and back, `EObject_isKindOf(object, &Named_class)` tells whether an object conforms to a class through its supertypes, and `EObject_destroy(object)` destroys an object of any class.

An abstract class, an interface, and a class that other classes extend are treated alike when other classes refer to them: a reference to such a class is an `EObject *`, because the structure of a subclass does not contain the structure of its superclass. A class that is abstract or an interface has no structure and no functions at all, only its description. A class that other classes extend keeps its structure and functions.

Every class, whether it has instances or not, has a description, `extern const EClassInfo Book_class`, with its name, its supertypes, its features and the functions that create and destroy its objects. A table that would be empty is left out, because C has no empty arrays: the description holds the null pointer and a count of zero.

### Features

| Model | C |
| -- | -- |
| Attribute of a primitive or boxed type | A field of the C scalar: `bool`, `int32_t`, `double` and so on. A boxed type (`EIntegerObject`) maps to the same scalar as its primitive. |
| `EString`, `EBigInteger`, `EBigDecimal` | A `char *` that the object owns, a copy of the text. |
| `EByteArray` | An `EByteArray` that the object owns, a copy of the bytes. |
| `EDate` | An `int64_t` with the milliseconds since the epoch. |
| `EChar` | A `uint16_t` with the code of the character. |
| `EJavaObject` and a data type that the table does not know | A `void *` that the object does not own. |
| Enumeration | A field of the `enum` type, `Colour` or the first literal when the model gives no default. |
| Reference | A pointer to the structure of the target class, or an `EObject *` if the target is an abstract class, an interface, a class that others extend, or a class of Ecore. |
| Many-valued feature | An `EList(T)` field: `T *items; size_t count; size_t capacity;`. |

The defaults of the model become the initial values: a string default is copied by `Book_create`, a number or boolean is a literal, a character is its numeric code and an enumeration default is its constant. An attribute without a default starts at zero, `false`, the null pointer, or the first literal of its enumeration.

The functions of a feature use the plain names of the model, because they are made of several words:

| Feature | Functions |
| -- | -- |
| Single-valued | `T Book_get_pages(const Book *self)` and `void Book_set_pages(Book *self, T value)` |
| Single-valued text or bytes | The getter returns `const char *` (or an `EByteArray` view of the bytes) that stays valid until the feature changes. The setter returns `bool`: it copies the value, and returns `false` and keeps the old value if the memory runs out. |
| Many-valued | `Writer_count_aliases`, `Writer_item_aliases(self, index)` (the zero value when out of range), `Writer_add_aliases(self, value)`, `Writer_remove_aliases(self, index)` and `Writer_clear_aliases(self)` |

Adding to a list returns `false` if the memory runs out or the size would overflow; the list keeps growing geometrically otherwise.

### Ownership

An object owns the strings and byte arrays that its fields hold, and the objects that its containment references refer to. It does not own the objects of other references.

- Setting a single containment reference destroys the previous object, unless it is the object that is set again, and takes ownership of the new one.
- Adding to a many-valued containment reference takes ownership of the object when the call succeeds; if it returns `false`, the caller still owns the object. Removing an object destroys it, and so does clearing the list.
- Setting, adding or removing the objects of other references only links and unlinks: nothing is destroyed.
- Destroying an object destroys everything that its containment references own, recursively.

An object must have at most one owner. Opposite references are plain pointers: the generated code does not keep the two ends in step, so a program that sets one end sets the other end as well. Derived, volatile and transient features are stored like all other features, and operations of the model are not generated.

### Names

A model name that C or C++ reserves, or that the generated code claims, is written with a trailing underscore wherever it names a type, a field or a parameter: the class `static` is `static_`, a feature named `int` is the field `int_`, a class `FILE` is `FILE_`, and `eObject`, `NULL`, `bool`, `size_t` and the names of the support header are escaped too. The names of functions, descriptions and enumeration constants are made of several words and use the name of the type: `static__create`, `Mode_default`, `Mode__` for a literal named `_`. A field also gets a trailing underscore if the structure uses a type of the same name, because C++ does not allow a member to change the meaning of a type name. The words are data in `c-types.xmi`, in three lists that give the reason: keywords of C and C++, types, macros and functions of the standard library and the support header, and the member names that the generated code uses.

The fixed parameter names are `self`, `value`, `index` and `literal`, and the local names `copy`, `items`, `position` and `object`; they are reserved in the same table. Classes with the same name in different packages of one model need different names, because C has one name space for them. A model name that is not a valid C identifier is not translated.

### Existing files

A file that exists is merged with the generated text. A member whose comment is followed by a `// @generated` line is regenerated, a member marked `// @generated NOT` is kept, and members without the tag are kept, so functions and declarations written by hand stay, at the top of a header, inside the `extern "C"` block, or at the end of a source file. Fields written by hand stay inside a structure. A member that the model no longer produces is removed; one that is new is added after the member it follows.

Members are matched by their signature. Mark a member as not generated to change its body, its documentation or its position, but do not change its signature: a changed signature is a new member, and the generated one is added again. The preprocessor lines of a file, the include guard and the includes, are not tagged and so are kept; the includes of the new text are added to those that are there. ``GenerationOptions/forceOverwrite`` replaces the file; ``GenerationOptions/diff`` writes the generated text beside it as `.<name>.new`. The set offers one layout and so no code styles.

### Documentation

Documentation comments come from the `documentation` annotation of the model, with a generated summary if there is none. They are Doxygen comments written with `///`: the first paragraph follows `@brief`, further paragraphs follow after an empty `///` line, and functions document `@param` and `@return`. The tag that marks a generated member stands on a line of its own below the comment, so it never becomes part of the documentation.

### Modules of the set

- `generate.mtl` is the main module. It declares the merge and writes the support header and the two files of each package.
- `EObjectHeader.mtl` writes `EObject.h`; `PackageHeader.mtl` and `PackageSource.mtl` write the header and the source file of a package.
- `ClassHeader.mtl`, `ClassSource.mtl` and `ClassDescriptor.mtl` write the declarations, the functions and the descriptions of a class, with `ClassQueries.mtl` for the features, the names of their functions and the classes and headers a package refers to.
- `EnumDeclaration.mtl` and `DataTypeDeclaration.mtl` write enumerations and data types.
- `CNames.mtl`, `CTypes.mtl`, `CIncludes.mtl` and `CDocumentation.mtl` hold the naming rules, the mapping of types and default values, the include directives, and documentation comments with string literals. `Header.mtl` writes the comment that opens a file, with the copyright text.
- `TypeMapping.ecore` and `c-types.xmi` are the data model with the type table and the reserved words. A mapping names the model type or the instance class, the C type, the type of accessor parameters when it differs, how the object keeps the value (`scalar`, `string`, `bytes` or `pointer`), its zero value, the header it needs and how a default is written.

### Checking the output

The tests compile every `.c` file of every fixture with `cc -std=c11 -Wall -Wextra -Werror`, compile every header on its own as C and as C++ (`-std=c++20`), and link and run a small program that exercises the generated library model. They run when `cc` is on the search path, and the C++ checks when `c++` is as well. The same program can be built with `-fsanitize=address,undefined` to check the allocation and ownership rules; on macOS, `leaks --atExit` reports leaks where the address sanitizer does not.
