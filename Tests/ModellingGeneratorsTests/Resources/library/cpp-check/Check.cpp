// Exercises the generated library model: defaults, accessors, many-valued features, shared and weak ownership,
// abstract bases and the diamond they form, the factory, the enumeration helpers and the package description.
// It is linked with Other.cpp, which includes the same headers, to show that the headers can be included in
// several translation units.

#include <cstdint>
#include <iostream>
#include <memory>
#include <string>
#include <string_view>
#include <type_traits>

#include "EObject.hpp"
#include "library/Book.hpp"
#include "library/BookCategory.hpp"
#include "library/ISBN.hpp"
#include "library/Lendable.hpp"
#include "library/Library.hpp"
#include "library/LibraryFactory.hpp"
#include "library/LibraryPackage.hpp"
#include "library/Named.hpp"
#include "library/Writer.hpp"

/// Defined in Other.cpp: the address of the package description as that translation unit sees it.
const void *otherUnitPackage();

static_assert(std::is_same_v<library::ISBN, std::string>, "a data type is an alias of the mapped type");
static_assert(std::is_abstract_v<library::Named> && std::is_abstract_v<library::Lendable>,
              "abstract classes and interfaces are abstract");
static_assert(!std::is_abstract_v<library::Book> && std::is_final_v<library::Book>,
              "a class with instances is a concrete final class");
static_assert(!std::is_copy_constructible_v<library::Book>, "objects cannot be copied");
static_assert(std::is_base_of_v<EObject, library::Book> && std::is_base_of_v<library::Named, library::Book>,
              "a class derives from the classes it extends");

namespace {

/// The number of checks that failed.
int failures = 0;

/// Records a failed check.
///
/// @param condition What must be true.
/// @param message What the check is about.
void check(bool condition, const char *message) {
    if (!condition) {
        std::cerr << "FAILED: " << message << "\n";
        ++failures;
    }
}

void checkDefaults() {
    auto book = library::LibraryFactory::instance().createBook();
    check(book->getName().empty(), "a string starts empty");
    check(book->getPages() == 100, "the model default of pages");
    check(book->getLoanDays() == 14, "the model default of an inherited attribute");
    check(!book->getOnLoan(), "a boolean starts false");
    check(book->getCategory() == library::BookCategory::Mystery, "an enumeration starts at its first literal");
    check(book->getIsbn().empty(), "a data type starts empty");
    check(book->getAuthor() == nullptr, "a reference starts null");
    check(book->getLibrary() == nullptr, "a container reference starts null");
}

void checkAccessors() {
    auto book = library::LibraryFactory::instance().createBook();
    book->setName("Dune");
    book->setPages(412);
    book->setOnLoan(true);
    book->setCategory(library::BookCategory::ScienceFiction);
    book->setIsbn("9780441172719");
    book->setLoanDays(7);
    check(book->getName() == "Dune", "string accessor");
    check(book->getPages() == 412, "integer accessor");
    check(book->getOnLoan(), "boolean accessor");
    check(book->getCategory() == library::BookCategory::ScienceFiction, "enumeration accessor");
    check(book->getIsbn() == "9780441172719", "data type accessor");
    check(book->getLoanDays() == 7, "inherited accessor");
}

void checkManyValuedFeatures() {
    auto writer = library::LibraryFactory::instance().createWriter();
    writer->getAliases().push_back("Frank");
    writer->getAliases().push_back("Herbert");
    const library::Writer &constant = *writer;
    check(constant.getAliases().size() == 2, "a many-valued attribute is a vector");
    check(constant.getAliases().at(1) == "Herbert", "the elements keep their order");

    auto lib = library::LibraryFactory::instance().createLibrary();
    auto first = library::LibraryFactory::instance().createBook();
    auto second = library::LibraryFactory::instance().createBook();
    lib->getBooks().push_back(first);
    lib->getBooks().push_back(second);
    lib->getWriters().push_back(writer);
    check(lib->getBooks().size() == 2 && lib->getWriters().size() == 1, "a containment holds its objects");
    check(lib->getBooks().front() == first, "the contained object is the one added");
}

void checkOwnership() {
    auto lib = library::LibraryFactory::instance().createLibrary();
    std::weak_ptr<library::Book> observed;
    {
        auto book = library::LibraryFactory::instance().createBook();
        observed = book;
        lib->getBooks().push_back(book);
    }
    check(!observed.expired(), "a containment keeps its objects alive");
    lib->getBooks().clear();
    check(observed.expired(), "an object that nothing owns is destroyed");

    auto book = library::LibraryFactory::instance().createBook();
    {
        auto writer = library::LibraryFactory::instance().createWriter();
        book->setAuthor(writer);
        check(book->getAuthor() == writer, "a reference reads back the object it was given");
        writer->getBooks().push_back(book);
        check(writer->getBooks().front().lock() == book, "a many-valued reference holds weak pointers");
    }
    check(book->getAuthor() == nullptr, "a reference to a destroyed object reads as null");
    check(book.use_count() == 1, "a reference does not keep its target alive");

    book->setLibrary(lib);
    check(book->getLibrary() == lib, "a single reference reads back");
    book->setLibrary(nullptr);
    check(book->getLibrary() == nullptr, "a reference can be cleared");
}

void checkAbstractBases() {
    auto book = library::LibraryFactory::instance().createBook();
    std::shared_ptr<library::Named> named = book;
    std::shared_ptr<library::Lendable> lendable = book;
    named->setName("Emma");
    lendable->setLoanDays(21);
    check(book->getName() == "Emma", "an abstract base writes through to the object");
    check(book->getLoanDays() == 21, "a second base writes through to the same storage");
    const EObject *fromNamed = named.get();
    const EObject *fromLendable = lendable.get();
    check(fromNamed == fromLendable, "the root class is shared by both bases");
    check(dynamic_cast<library::Lendable *>(named.get()) == lendable.get(), "bases can be crossed");
    std::shared_ptr<EObject> root = book;
    check(dynamic_cast<library::Book *>(root.get()) == book.get(), "the root class can be cast back");
}

void checkFactory() {
    const library::LibraryFactory &factory = library::LibraryFactory::instance();
    auto created = factory.create("Book");
    check(created != nullptr, "the factory creates a class by name");
    check(isKindOf(*created, "Book") && isKindOf(*created, "Named") && isKindOf(*created, "Lendable"),
          "an object is a kind of its class and its supertypes");
    check(!isKindOf(*created, "Writer"), "an object is not a kind of an unrelated class");
    check(factory.create("Named") == nullptr, "an abstract class has no instances");
    check(factory.create("Lendable") == nullptr, "an interface has no instances");
    check(factory.create("Missing") == nullptr, "an unknown class has no instances");
    check(factory.create("Library")->eClass().name == "Library", "the class of a created object");
    check(&factory == &library::LibraryFactory::instance(), "the factory is shared");
}

void checkEnumeration() {
    using library::BookCategory;
    check(library::literalOf(BookCategory::Mystery) == "Mystery", "literal of the first value");
    check(library::literalOf(BookCategory::Biography) == "Biography", "literal of the last value");
    check(library::literalOf(static_cast<BookCategory>(99)).empty(), "a value without a literal has no text");
    check(library::parseBookCategory("ScienceFiction") == BookCategory::ScienceFiction, "parsing a literal");
    check(!library::parseBookCategory("Poetry").has_value(), "parsing an unknown literal");
    check(static_cast<std::int32_t>(BookCategory::Biography) == 2, "the value of a literal");
}

void checkDescription() {
    const library::LibraryPackage &package = library::LibraryPackage::instance();
    check(package.name() == "library", "package name");
    check(package.nsURI() == "http://swift-modelling.org/test/library/1.0", "package URI");
    check(package.nsPrefix() == "lib", "package prefix");
    check(package.info().classes.size() == 5, "every class is described");
    check(package.namedClass().isAbstract && package.lendableClass().isAbstract, "abstract classes are marked");
    check(!package.bookClass().isAbstract, "a concrete class is not marked");
    check(package.bookClass().name == "Book", "class name");
    check(package.bookClass().superTypes.size() == 2, "the supertypes of a class");
    check(package.bookClass().features.size() == 8, "all features of a class, inherited ones included");

    const FeatureInfo *author = nullptr;
    for (const FeatureInfo &feature : package.bookClass().features) {
        if (feature.name == "author") author = &feature;
    }
    check(author != nullptr && author->kind == FeatureKind::reference && !author->many &&
              author->typeName == "Writer",
          "a reference is described with its target");
    const auto &books = package.libraryClass().features.at(1);
    check(books.name == "books" && books.kind == FeatureKind::containment && books.many, "a containment");

    auto book = library::LibraryFactory::instance().createBook();
    check(&book->eClass() == &package.bookClass(), "an object returns the description of its class");
    check(&library::LibraryPackage::instance() == &package, "the description is shared");
    check(otherUnitPackage() == &package, "the description is one object across translation units");
}

}  // namespace

int main() {
    checkDefaults();
    checkAccessors();
    checkManyValuedFeatures();
    checkOwnership();
    checkAbstractBases();
    checkFactory();
    checkEnumeration();
    checkDescription();
    if (failures != 0) {
        std::cerr << failures << " checks failed\n";
        return 1;
    }
    std::cout << "checks passed\n";
    return 0;
}
