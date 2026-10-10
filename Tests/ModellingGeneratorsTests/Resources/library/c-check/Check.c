//
//  Check.c
//
//  Exercises the generated C code of the library model: defaults, setters and getters, text, many-valued
//  features, containment and ownership, enumeration conversions, the descriptions and the factory.
//

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "library/library.h"

/// The number of checks that failed.
static int failures = 0;

/// Records a failed check with the line it stands on.
#define CHECK(condition)                                                                       \
    do {                                                                                       \
        if (!(condition)) {                                                                    \
            fprintf(stderr, "check failed at line %d: %s\n", __LINE__, #condition);            \
            failures++;                                                                        \
        }                                                                                      \
    } while (0)

/// Checks the values that a new book has.
static void checkDefaults(void) {
    Book *book = Book_create();
    CHECK(book != NULL);
    if (book == NULL) {
        return;
    }
    CHECK(book->eObject.eClass == &Book_class);
    CHECK(Book_get_pages(book) == 100);
    CHECK(Book_get_loanDays(book) == 14);
    CHECK(!Book_get_onLoan(book));
    CHECK(Book_get_category(book) == BookCategory_Mystery);
    CHECK(Book_get_name(book) == NULL);
    CHECK(Book_get_isbn(book) == NULL);
    CHECK(Book_get_author(book) == NULL);
    CHECK(Book_get_library(book) == NULL);
    Book_destroy(book);
    Book_destroy(NULL);
}

/// Checks that text is copied, replaced and cleared.
static void checkText(void) {
    Book *book = Book_create();
    CHECK(book != NULL);
    if (book == NULL) {
        return;
    }
    char title[] = "Dune";
    CHECK(Book_set_name(book, title));
    title[0] = 'X';
    CHECK(Book_get_name(book) != NULL && strcmp(Book_get_name(book), "Dune") == 0);
    CHECK(Book_get_name(book) != title);
    CHECK(Book_set_name(book, Book_get_name(book)));
    CHECK(strcmp(Book_get_name(book), "Dune") == 0);
    CHECK(Book_set_isbn(book, "978-0-441-17271-9"));
    CHECK(strcmp(Book_get_isbn(book), "978-0-441-17271-9") == 0);
    CHECK(Book_set_name(book, NULL));
    CHECK(Book_get_name(book) == NULL);
    Book_set_pages(book, 412);
    Book_set_loanDays(book, 7);
    Book_set_onLoan(book, true);
    Book_set_category(book, BookCategory_Biography);
    CHECK(Book_get_pages(book) == 412 && Book_get_loanDays(book) == 7);
    CHECK(Book_get_onLoan(book) && Book_get_category(book) == BookCategory_Biography);
    Book_destroy(book);
}

/// Checks the conversion between enumeration literals and their text.
static void checkEnumeration(void) {
    CHECK(strcmp(BookCategory_literal(BookCategory_ScienceFiction), "ScienceFiction") == 0);
    CHECK(BookCategory_literal((BookCategory)99) == NULL);
    BookCategory category = BookCategory_Mystery;
    CHECK(BookCategory_from_literal("Biography", &category));
    CHECK(category == BookCategory_Biography);
    CHECK(!BookCategory_from_literal("Poetry", &category));
    CHECK(category == BookCategory_Biography);
    CHECK(!BookCategory_from_literal(NULL, &category));
    CHECK(!BookCategory_from_literal("Mystery", NULL));
}

/// Checks a many-valued attribute: growth, access, removal and clearing.
static void checkList(void) {
    Writer *writer = Writer_create();
    CHECK(writer != NULL);
    if (writer == NULL) {
        return;
    }
    CHECK(Writer_count_aliases(writer) == 0);
    CHECK(Writer_item_aliases(writer, 0) == NULL);
    for (int number = 0; number < 40; number++) {
        char alias[16];
        snprintf(alias, sizeof alias, "alias %d", number);
        CHECK(Writer_add_aliases(writer, alias));
    }
    CHECK(Writer_count_aliases(writer) == 40);
    CHECK(strcmp(Writer_item_aliases(writer, 0), "alias 0") == 0);
    CHECK(strcmp(Writer_item_aliases(writer, 39), "alias 39") == 0);
    CHECK(Writer_item_aliases(writer, 40) == NULL);
    CHECK(Writer_remove_aliases(writer, 1));
    CHECK(Writer_count_aliases(writer) == 39);
    CHECK(strcmp(Writer_item_aliases(writer, 1), "alias 2") == 0);
    CHECK(!Writer_remove_aliases(writer, 39));
    CHECK(Writer_remove_aliases(writer, 38));
    Writer_clear_aliases(writer);
    CHECK(Writer_count_aliases(writer) == 0);
    CHECK(Writer_add_aliases(writer, "again"));
    CHECK(strcmp(Writer_item_aliases(writer, 0), "again") == 0);
    Writer_destroy(writer);
}

/// Checks that containment owns its objects and a plain reference does not.
static void checkOwnership(void) {
    Library *library = Library_create();
    Writer *writer = Writer_create();
    Book *first = Book_create();
    Book *second = Book_create();
    Book *third = Book_create();
    CHECK(library != NULL && writer != NULL && first != NULL && second != NULL && third != NULL);
    if (library == NULL || writer == NULL || first == NULL || second == NULL || third == NULL) {
        return;
    }
    CHECK(Library_add_books(library, first));
    CHECK(Library_add_books(library, second));
    CHECK(Library_add_books(library, third));
    CHECK(Library_count_books(library) == 3);
    CHECK(Library_item_books(library, 1) == second);
    CHECK(Library_item_books(library, 3) == NULL);

    CHECK(Writer_add_books(writer, first));
    CHECK(Writer_add_books(writer, second));
    Book_set_author(first, writer);
    Book_set_library(first, library);
    CHECK(Book_get_author(first) == writer && Book_get_library(first) == library);
    CHECK(Writer_count_books(writer) == 2);
    CHECK(Writer_remove_books(writer, 0));
    CHECK(Writer_count_books(writer) == 1);
    CHECK(Writer_item_books(writer, 0) == second);
    CHECK(Library_count_books(library) == 3);
    Writer_clear_books(writer);

    CHECK(Library_remove_books(library, 1));
    CHECK(Library_count_books(library) == 2);
    CHECK(Library_item_books(library, 1) == third);
    CHECK(!Library_remove_books(library, 2));

    Writer_destroy(writer);
    Library_destroy(library);
}

/// Checks the descriptions of the classes and of the package.
static void checkDescriptions(void) {
    CHECK(strcmp(LibraryPackage.name, "library") == 0);
    CHECK(strcmp(LibraryPackage.nsURI, "http://swift-modelling.org/test/library/1.0") == 0);
    CHECK(strcmp(LibraryPackage.nsPrefix, "lib") == 0);
    CHECK(LibraryPackage.classCount == 5);
    CHECK(strcmp(Book_class.name, "Book") == 0);
    CHECK(!Book_class.isAbstract && Named_class.isAbstract && Lendable_class.isAbstract);
    CHECK(Book_class.superTypeCount == 2 && Book_class.superTypes[0] == &Named_class);
    CHECK(Named_class.superTypeCount == 0 && Named_class.superTypes == NULL);
    CHECK(Book_class.featureCount == 8);
    CHECK(strcmp(Book_class.features[0].name, "name") == 0);
    CHECK(strcmp(Book_class.features[3].name, "pages") == 0);
    CHECK(Book_class.features[3].kind == EFeatureKind_Attribute && !Book_class.features[3].isMany);
    CHECK(strcmp(Book_class.features[3].typeName, "EInt") == 0);
    CHECK(Book_class.features[6].kind == EFeatureKind_Reference);
    CHECK(Library_class.features[1].kind == EFeatureKind_Containment && Library_class.features[1].isMany);
    CHECK(Named_class.create == NULL && Named_class.destroy == NULL);
    CHECK(Book_class.create != NULL && Book_class.destroy != NULL);
}

/// Checks the factory, the common destruction and the test for the class of an object.
static void checkFactory(void) {
    EObject *object = LibraryFactory_create(&Book_class);
    CHECK(object != NULL);
    if (object == NULL) {
        return;
    }
    CHECK(object->eClass == &Book_class);
    CHECK(EObject_isKindOf(object, &Book_class));
    CHECK(EObject_isKindOf(object, &Named_class));
    CHECK(EObject_isKindOf(object, &Lendable_class));
    CHECK(!EObject_isKindOf(object, &Writer_class));
    CHECK(!EObject_isKindOf(NULL, &Book_class));
    CHECK(!EObject_isKindOf(object, NULL));
    CHECK(Book_get_pages((Book *)object) == 100);
    EObject_destroy(object);
    EObject_destroy(NULL);

    CHECK(LibraryFactory_create(&Named_class) == NULL);
    CHECK(LibraryFactory_create(NULL) == NULL);
    const EClassInfo foreign = {.name = "Foreign"};
    CHECK(LibraryFactory_create(&foreign) == NULL);
    for (size_t position = 0; position < LibraryPackage.classCount; position++) {
        const EClassInfo *eClass = LibraryPackage.classes[position];
        EObject *created = LibraryFactory_create(eClass);
        CHECK((created != NULL) == (eClass->create != NULL));
        EObject_destroy(created);
    }
}

/// Checks the helper functions of the support header.
static void checkHelpers(void) {
    CHECK(EObject_duplicateString(NULL) == NULL);
    char *copy = EObject_duplicateString("text");
    CHECK(copy != NULL && strcmp(copy, "text") == 0);
    free(copy);

    EByteArray none;
    CHECK(EObject_duplicateBytes((EByteArray){NULL, 0}, &none) && none.bytes == NULL && none.length == 0);
    uint8_t source[3] = {1, 2, 3};
    EByteArray bytes;
    CHECK(EObject_duplicateBytes((EByteArray){source, 3}, &bytes));
    CHECK(bytes.length == 3 && bytes.bytes != source && memcmp(bytes.bytes, source, 3) == 0);
    free(bytes.bytes);

    size_t capacity = 0;
    void *items = EObject_grown(NULL, &capacity, sizeof(int));
    CHECK(items != NULL && capacity == 4);
    items = EObject_grown(items, &capacity, sizeof(int));
    CHECK(items != NULL && capacity == 8);
    free(items);
    size_t huge = SIZE_MAX / 2 + 1;
    CHECK(EObject_grown(NULL, &huge, sizeof(int)) == NULL && huge == SIZE_MAX / 2 + 1);
    size_t small = 4;
    CHECK(EObject_grown(NULL, &small, SIZE_MAX) == NULL && small == 4);
    CHECK(EObject_grown(NULL, &small, 0) == NULL);
}

int main(void) {
    checkDefaults();
    checkText();
    checkEnumeration();
    checkList();
    checkOwnership();
    checkDescriptions();
    checkFactory();
    checkHelpers();
    if (failures != 0) {
        fprintf(stderr, "%d checks failed\n", failures);
        return EXIT_FAILURE;
    }
    printf("checks passed\n");
    return EXIT_SUCCESS;
}
