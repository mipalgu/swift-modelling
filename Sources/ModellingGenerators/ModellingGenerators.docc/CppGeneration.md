# C++ Generation

Generate header-only C++20 model code from a generator model.

## Overview

The bundled `cpp` template set writes C++ headers that need nothing but the standard library. Every class of the model becomes a class that derives from the root class `EObject`, which one generated header declares, so the objects of a model share a base that describes their class at run time.

```swift
let result = try await GenerationPipeline.generate(
    inputURL: URL(fileURLWithPath: "model/library.ecore"),
    language: "cpp",
    outputDirectory: URL(fileURLWithPath: "include"))
```

From the command line, `swift-ecore generate model/library.ecore --language cpp --output include` and `swift-atl generate model/library.ecore --language cpp --output include` do the same. A generator model works as the input as well; an Ecore model is imported into a temporary generator model first. Add `--model-directory` to write below the model directory of the generator model.

Compile with the output directory on the include path, for example `c++ -std=c++20 -I include main.cpp`. Headers include each other with paths relative to that directory, such as `#include "library/Book.hpp"`.

### What is generated

At the root of the output directory the set writes `EObject.hpp`, the only file that does not belong to a package. Its text is the same for every model, so several models can share one output directory. It declares the root class `EObject` and the structures `FeatureInfo`, `ClassInfo` and `PackageInfo` that describe features, classes and packages, and the function `isKindOf` that tells whether an object is an instance of a class.

For every package the set writes, below a directory named after the package (nested packages get nested directories and nested namespaces, written `namespace company::people`):

- one header for each class. A class that is abstract, an interface or extended by other classes has an abstract base class in its header, and a class that has instances also has a concrete `final` class there. A class that has both gets a concrete class named with the suffix `Impl`.
- one header for each enumeration, a scoped `enum class` with a sized integer type, the function `literalOf` that converts a value to the text of its literal, and the function `parse<Name>` that converts the text of a literal to a value.
- one header for each data type of the model, an alias (`using`) of the C++ type that its instance class maps to.
- the package description (`LibraryPackage.hpp`), a class with one shared instance that describes the package and each of its classes, and the factory (`LibraryFactory.hpp`) with a creation function for every class that has instances and `create(className)` to create an object by the name of its class.

The names of the description and the factory come from the package prefix of the generator model, as in Java. Every header starts with `#pragma once`, then the header comment with the file name and the copyright text, then its includes, sorted and without repetitions, with the headers of the model before the headers of the standard library. Everything is defined in the header, so no source file or library is needed, and a header can be included in any number of translation units.

### Classes

An abstract base class has a protected default constructor, a virtual destructor and a pure virtual getter and setter for each feature that the class itself declares. It derives virtually from the abstract base classes of its supertypes, or from `EObject` if it has none: `class Book` derives from `Named` and `Lendable`, which both derive virtually from `EObject`, so a book has one copy of the root and of any shared base.

A class that has instances is a concrete `final` class. It owns the storage of all its features, declared or inherited, in private data members named `m_<feature>`, implements their accessors, and implements `eClass()`, which returns the description of the class from the package. Concrete classes never derive from each other: a class that other classes extend is split into an abstract base class with its own name and a concrete class named `<Name>Impl`, and a subclass derives from the abstract base class. Every object therefore has exactly one set of storage and one final overrider for each accessor. A class that nothing extends has no abstract part, and its own accessors are plain member functions without `override`.

Objects are created with the factory and owned through `std::shared_ptr`. They cannot be copied, because a copy would share the objects it contains. Objects are not synchronised: use one object from one thread at a time.

```cpp
auto library = library::LibraryFactory::instance().createLibrary();
auto book = library::LibraryFactory::instance().createBook();
book->setName("Dune");
library->getBooks().push_back(book);
std::shared_ptr<library::Named> named = book;
```

### Features

Accessors are named `get<Name>` and `set<Name>`, so a feature named `class`, `new` or `delete` needs no renaming, and no feature clashes with the name of its class.

| Model | C++ |
| --- | --- |
| Single-valued attribute of a small type (numbers, `bool`, `char16_t`, enumerations, dates) | The value, passed by value and zero, `false`, the first literal or the default of the model at first. |
| Single-valued attribute of another type (`std::string`, byte arrays, `std::any`) | A constant reference from the getter and from the setter. A string is empty rather than absent. |
| Attribute of a boxed type (`EIntegerObject`, `EBooleanObject` and the like) | A `std::optional`, empty unless the model gives a default. |
| Many-valued attribute | A `std::vector`, empty at first, returned by reference (`getAliases()` and a constant overload); there is no setter. |
| Single containment reference | A `std::shared_ptr` that owns the target. |
| Single reference that does not contain | A `std::weak_ptr` in the storage. The getter returns a `std::shared_ptr` made by `lock()`, which is null when the target is gone. |
| Many-valued reference | A `std::vector` of `std::shared_ptr` for a containment and of `std::weak_ptr` otherwise. |
| Opposite references | Not kept in step. Setting one end leaves the other as it is; model code that wants both ends updates both. |

A reference points to the abstract base class when the target class has one, otherwise to the concrete class. Classes that a header refers to are declared ahead of use in their own namespace instead of being included, so the headers of two classes that refer to each other do not include each other. Include the header of a class before calling a member of an object of it. References to classes of the Ecore package are `std::shared_ptr<EObject>`.

Derived, volatile, transient and unsettable features are stored like all other features, and operations are not generated. The model data types come from the type table of the set: `EString` is `std::string`, `EInt` is `std::int32_t`, `ELong` is `std::int64_t`, `EChar` is `char16_t`, `EDate` is `std::chrono::system_clock::time_point`, `EBigInteger` and `EBigDecimal` are the text of the number in a `std::string`, and a data type that the table does not know is a `std::any`. A character default is written as the number of its code.

### The description of the model

`EObject::eClass()` returns a `ClassInfo`: the name of the class, whether it is abstract, the names of all its generated supertypes (the direct ones and those they inherit), and all its features with their kind (`attribute`, `reference` or `containment`), whether they are many-valued, and the name of their type in the model. The package class `LibraryPackage::instance()` offers `name()`, `nsURI()`, `nsPrefix()`, `info()` for the whole `PackageInfo`, and one accessor for each class, such as `bookClass()`. `isKindOf(object, "Named")` uses the supertypes to test the kind of an object without a cast. The factory's `create("Book")` creates an object by the name of its class, and returns a null pointer for an abstract class or an unknown name.

### Names

C++ keywords, including the alternative tokens (`and`, `not`, `xor`), and the words in the table of reserved names, such as `NULL`, `FILE`, `size_t`, `std` and the names that `EObject.hpp` declares, are written with a trailing underscore wherever they name a class, an enumeration, a data type, an enumeration literal or a namespace: `static_`, `EObject_`, `Mode::default_`, `namespace cnames::delete_`. The file of such a type carries the underscore too (`static_.hpp`), while the directory of a package keeps the plain name of the package. Both lists are data in `cpp-types.xmi`. The prefix `get`, `set` and `m_` keeps feature names clear of keywords, macros and each other, so they are never renamed.

Within its own package a class is written with its plain name. A class of another package is written with its namespace, starting at the global namespace: `std::shared_ptr<::company::projects::Project>`. All classes of a model share the namespace of their package, so classes with the same name need different packages.

### Existing files

A header that exists is merged with the generated text. A member whose comment is followed by a `// @generated` line is regenerated, a member marked `// @generated NOT` is kept, and members without the tag are kept, so a hand-written member of a class or a function in the namespace stays. Every generated declaration, definition, data member, enumerator and namespace carries the tag, and documentation comments (`///`, with `@brief`, `@param` and `@return`) stand above it. Includes that you add to a header stay. ``GenerationOptions/forceOverwrite`` replaces the file; ``GenerationOptions/diff`` writes the generated text beside it as `.<name>.new`. The set offers one layout and so no code styles.

### Modules of the set

- `generate.mtl` is the main module. It declares the merge and writes the support header and the files of each package.
- `SupportHeader.mtl` writes `EObject.hpp`.
- `Class.mtl` writes the header of a class, with `ClassQueries.mtl` (base classes, implemented features, declarations ahead of use) and `ClassFeature.mtl` (accessors and storage).
- `EnumClass.mtl` and `DataTypeFile.mtl` write the headers of enumerations and data types.
- `PackageClass.mtl` writes the package description and `FactoryClass.mtl` the factory.
- `CppNames.mtl`, `CppTypes.mtl`, `CppIncludes.mtl` and `CppDocumentation.mtl` hold the naming rules, the mapping of types and default values, the include directives, and documentation comments with string literals. `Header.mtl` writes the comment that opens a file, with the copyright text.
- `TypeMapping.ecore` and `cpp-types.xmi` are the data model with the type table and the reserved words.

### Checking the output

The tests compile every generated header of every fixture on its own, in a translation unit that does nothing but include it, with `-std=c++20 -Wall -Wextra -Werror -pedantic`. They link a program that includes all the headers of a fixture and uses its factories with a second translation unit that includes the same headers, and they build and run a program that exercises the generated library model, also under the address and undefined behaviour sanitizers. They run when a compiler named `c++` is on the search path.
