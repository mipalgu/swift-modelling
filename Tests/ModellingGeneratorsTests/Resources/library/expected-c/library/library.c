//
//  library.c
//
//  Copyright 2026 Example Pty Ltd
//

#include "library/library.h"
#include <stdlib.h>
#include <string.h>

// @generated
const char *BookCategory_literal(BookCategory value) {
    switch (value) {
    case BookCategory_Mystery:
        return "Mystery";
    case BookCategory_ScienceFiction:
        return "ScienceFiction";
    case BookCategory_Biography:
        return "Biography";
    default:
        return NULL;
    }
}

// @generated
bool BookCategory_from_literal(const char *literal, BookCategory *value) {
    if (literal == NULL || value == NULL) {
        return false;
    }
    if (strcmp(literal, "Mystery") == 0) {
        *value = BookCategory_Mystery;
        return true;
    }
    if (strcmp(literal, "ScienceFiction") == 0) {
        *value = BookCategory_ScienceFiction;
        return true;
    }
    if (strcmp(literal, "Biography") == 0) {
        *value = BookCategory_Biography;
        return true;
    }
    return false;
}

// @generated
Book *Book_create(void) {
    Book *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Book_class;
    self->name = NULL;
    self->loanDays = 14;
    self->onLoan = false;
    self->pages = 100;
    self->category = BookCategory_Mystery;
    self->isbn = NULL;
    self->author = NULL;
    self->library = NULL;
    return self;
}

// @generated
void Book_destroy(Book *self) {
    if (self == NULL) {
        return;
    }
    free(self->name);
    free(self->isbn);
    free(self);
}

// @generated
const char *Book_get_name(const Book *self) {
    return self->name;
}

// @generated
bool Book_set_name(Book *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->name);
    self->name = copy;
    return true;
}

// @generated
int32_t Book_get_loanDays(const Book *self) {
    return self->loanDays;
}

// @generated
void Book_set_loanDays(Book *self, int32_t value) {
    self->loanDays = value;
}

// @generated
bool Book_get_onLoan(const Book *self) {
    return self->onLoan;
}

// @generated
void Book_set_onLoan(Book *self, bool value) {
    self->onLoan = value;
}

// @generated
int32_t Book_get_pages(const Book *self) {
    return self->pages;
}

// @generated
void Book_set_pages(Book *self, int32_t value) {
    self->pages = value;
}

// @generated
BookCategory Book_get_category(const Book *self) {
    return self->category;
}

// @generated
void Book_set_category(Book *self, BookCategory value) {
    self->category = value;
}

// @generated
const char *Book_get_isbn(const Book *self) {
    return self->isbn;
}

// @generated
bool Book_set_isbn(Book *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->isbn);
    self->isbn = copy;
    return true;
}

// @generated
Writer *Book_get_author(const Book *self) {
    return self->author;
}

// @generated
void Book_set_author(Book *self, Writer *value) {
    self->author = value;
}

// @generated
Library *Book_get_library(const Book *self) {
    return self->library;
}

// @generated
void Book_set_library(Book *self, Library *value) {
    self->library = value;
}

/// @brief Creates an object of the Book class for its description.
// @generated
static EObject *Book_create_object(void) {
    Book *object = Book_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Book class for its description.
// @generated
static void Book_destroy_object(EObject *object) {
    Book_destroy((Book *)object);
}

// @generated
Writer *Writer_create(void) {
    Writer *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Writer_class;
    self->name = NULL;
    self->aliases.items = NULL;
    self->aliases.count = 0;
    self->aliases.capacity = 0;
    self->books.items = NULL;
    self->books.count = 0;
    self->books.capacity = 0;
    return self;
}

// @generated
void Writer_destroy(Writer *self) {
    if (self == NULL) {
        return;
    }
    free(self->name);
    Writer_clear_aliases(self);
    Writer_clear_books(self);
    free(self);
}

// @generated
const char *Writer_get_name(const Writer *self) {
    return self->name;
}

// @generated
bool Writer_set_name(Writer *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->name);
    self->name = copy;
    return true;
}

// @generated
size_t Writer_count_aliases(const Writer *self) {
    return self->aliases.count;
}

// @generated
const char *Writer_item_aliases(const Writer *self, size_t index) {
    if (index >= self->aliases.count) {
        return NULL;
    }
    return self->aliases.items[index];
}

// @generated
bool Writer_add_aliases(Writer *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    if (self->aliases.count == self->aliases.capacity) {
        void *items = EObject_grown(self->aliases.items, &self->aliases.capacity, sizeof *self->aliases.items);
        if (items == NULL) {
            free(copy);
            return false;
        }
        self->aliases.items = items;
    }
    self->aliases.items[self->aliases.count++] = copy;
    return true;
}

// @generated
bool Writer_remove_aliases(Writer *self, size_t index) {
    if (index >= self->aliases.count) {
        return false;
    }
    free(self->aliases.items[index]);
    memmove(&self->aliases.items[index], &self->aliases.items[index + 1], (self->aliases.count - index - 1) * sizeof *self->aliases.items);
    self->aliases.count--;
    return true;
}

// @generated
void Writer_clear_aliases(Writer *self) {
    for (size_t position = 0; position < self->aliases.count; position++) {
        free(self->aliases.items[position]);
    }
    free(self->aliases.items);
    self->aliases.items = NULL;
    self->aliases.count = 0;
    self->aliases.capacity = 0;
}

// @generated
size_t Writer_count_books(const Writer *self) {
    return self->books.count;
}

// @generated
Book *Writer_item_books(const Writer *self, size_t index) {
    if (index >= self->books.count) {
        return NULL;
    }
    return self->books.items[index];
}

// @generated
bool Writer_add_books(Writer *self, Book *value) {
    if (self->books.count == self->books.capacity) {
        void *items = EObject_grown(self->books.items, &self->books.capacity, sizeof *self->books.items);
        if (items == NULL) {
            return false;
        }
        self->books.items = items;
    }
    self->books.items[self->books.count++] = value;
    return true;
}

// @generated
bool Writer_remove_books(Writer *self, size_t index) {
    if (index >= self->books.count) {
        return false;
    }
    memmove(&self->books.items[index], &self->books.items[index + 1], (self->books.count - index - 1) * sizeof *self->books.items);
    self->books.count--;
    return true;
}

// @generated
void Writer_clear_books(Writer *self) {
    free(self->books.items);
    self->books.items = NULL;
    self->books.count = 0;
    self->books.capacity = 0;
}

/// @brief Creates an object of the Writer class for its description.
// @generated
static EObject *Writer_create_object(void) {
    Writer *object = Writer_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Writer class for its description.
// @generated
static void Writer_destroy_object(EObject *object) {
    Writer_destroy((Writer *)object);
}

// @generated
Library *Library_create(void) {
    Library *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Library_class;
    self->name = NULL;
    self->books.items = NULL;
    self->books.count = 0;
    self->books.capacity = 0;
    self->writers.items = NULL;
    self->writers.count = 0;
    self->writers.capacity = 0;
    return self;
}

// @generated
void Library_destroy(Library *self) {
    if (self == NULL) {
        return;
    }
    free(self->name);
    Library_clear_books(self);
    Library_clear_writers(self);
    free(self);
}

// @generated
const char *Library_get_name(const Library *self) {
    return self->name;
}

// @generated
bool Library_set_name(Library *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->name);
    self->name = copy;
    return true;
}

// @generated
size_t Library_count_books(const Library *self) {
    return self->books.count;
}

// @generated
Book *Library_item_books(const Library *self, size_t index) {
    if (index >= self->books.count) {
        return NULL;
    }
    return self->books.items[index];
}

// @generated
bool Library_add_books(Library *self, Book *value) {
    if (self->books.count == self->books.capacity) {
        void *items = EObject_grown(self->books.items, &self->books.capacity, sizeof *self->books.items);
        if (items == NULL) {
            return false;
        }
        self->books.items = items;
    }
    self->books.items[self->books.count++] = value;
    return true;
}

// @generated
bool Library_remove_books(Library *self, size_t index) {
    if (index >= self->books.count) {
        return false;
    }
    EObject_destroy((EObject *)self->books.items[index]);
    memmove(&self->books.items[index], &self->books.items[index + 1], (self->books.count - index - 1) * sizeof *self->books.items);
    self->books.count--;
    return true;
}

// @generated
void Library_clear_books(Library *self) {
    for (size_t position = 0; position < self->books.count; position++) {
        EObject_destroy((EObject *)self->books.items[position]);
    }
    free(self->books.items);
    self->books.items = NULL;
    self->books.count = 0;
    self->books.capacity = 0;
}

// @generated
size_t Library_count_writers(const Library *self) {
    return self->writers.count;
}

// @generated
Writer *Library_item_writers(const Library *self, size_t index) {
    if (index >= self->writers.count) {
        return NULL;
    }
    return self->writers.items[index];
}

// @generated
bool Library_add_writers(Library *self, Writer *value) {
    if (self->writers.count == self->writers.capacity) {
        void *items = EObject_grown(self->writers.items, &self->writers.capacity, sizeof *self->writers.items);
        if (items == NULL) {
            return false;
        }
        self->writers.items = items;
    }
    self->writers.items[self->writers.count++] = value;
    return true;
}

// @generated
bool Library_remove_writers(Library *self, size_t index) {
    if (index >= self->writers.count) {
        return false;
    }
    EObject_destroy((EObject *)self->writers.items[index]);
    memmove(&self->writers.items[index], &self->writers.items[index + 1], (self->writers.count - index - 1) * sizeof *self->writers.items);
    self->writers.count--;
    return true;
}

// @generated
void Library_clear_writers(Library *self) {
    for (size_t position = 0; position < self->writers.count; position++) {
        EObject_destroy((EObject *)self->writers.items[position]);
    }
    free(self->writers.items);
    self->writers.items = NULL;
    self->writers.count = 0;
    self->writers.capacity = 0;
}

/// @brief Creates an object of the Library class for its description.
// @generated
static EObject *Library_create_object(void) {
    Library *object = Library_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Library class for its description.
// @generated
static void Library_destroy_object(EObject *object) {
    Library_destroy((Library *)object);
}

/// @brief The features of the Named class.
// @generated
static const EFeatureInfo Named_features[] = {
    { .name = "name", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
};

/// @brief The description of the Named class.
// @generated
const EClassInfo Named_class = {
    .name = "Named",
    .isAbstract = true,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Named_features,
    .featureCount = 1,
    .create = NULL,
    .destroy = NULL
};

/// @brief The features of the Lendable class.
// @generated
static const EFeatureInfo Lendable_features[] = {
    { .name = "loanDays", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EInt" },
    { .name = "onLoan", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EBoolean" },
};

/// @brief The description of the Lendable class.
// @generated
const EClassInfo Lendable_class = {
    .name = "Lendable",
    .isAbstract = true,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Lendable_features,
    .featureCount = 2,
    .create = NULL,
    .destroy = NULL
};

/// @brief The features of the Book class.
// @generated
static const EFeatureInfo Book_features[] = {
    { .name = "name", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "loanDays", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EInt" },
    { .name = "onLoan", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EBoolean" },
    { .name = "pages", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EInt" },
    { .name = "category", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "BookCategory" },
    { .name = "isbn", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "ISBN" },
    { .name = "author", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Writer" },
    { .name = "library", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Library" },
};

/// @brief The supertypes of the Book class.
// @generated
static const EClassInfo *const Book_superTypes[] = { &Named_class, &Lendable_class };

/// @brief The description of the Book class.
// @generated
const EClassInfo Book_class = {
    .name = "Book",
    .isAbstract = false,
    .superTypes = Book_superTypes,
    .superTypeCount = 2,
    .features = Book_features,
    .featureCount = 8,
    .create = Book_create_object,
    .destroy = Book_destroy_object
};

/// @brief The features of the Writer class.
// @generated
static const EFeatureInfo Writer_features[] = {
    { .name = "name", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "aliases", .kind = EFeatureKind_Attribute, .isMany = true, .typeName = "EString" },
    { .name = "books", .kind = EFeatureKind_Reference, .isMany = true, .typeName = "Book" },
};

/// @brief The supertypes of the Writer class.
// @generated
static const EClassInfo *const Writer_superTypes[] = { &Named_class };

/// @brief The description of the Writer class.
// @generated
const EClassInfo Writer_class = {
    .name = "Writer",
    .isAbstract = false,
    .superTypes = Writer_superTypes,
    .superTypeCount = 1,
    .features = Writer_features,
    .featureCount = 3,
    .create = Writer_create_object,
    .destroy = Writer_destroy_object
};

/// @brief The features of the Library class.
// @generated
static const EFeatureInfo Library_features[] = {
    { .name = "name", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "books", .kind = EFeatureKind_Containment, .isMany = true, .typeName = "Book" },
    { .name = "writers", .kind = EFeatureKind_Containment, .isMany = true, .typeName = "Writer" },
};

/// @brief The supertypes of the Library class.
// @generated
static const EClassInfo *const Library_superTypes[] = { &Named_class };

/// @brief The description of the Library class.
// @generated
const EClassInfo Library_class = {
    .name = "Library",
    .isAbstract = false,
    .superTypes = Library_superTypes,
    .superTypeCount = 1,
    .features = Library_features,
    .featureCount = 3,
    .create = Library_create_object,
    .destroy = Library_destroy_object
};

/// @brief The descriptions of the classes of the library package.
// @generated
static const EClassInfo *const LibraryPackage_classes[] = {
    &Named_class,
    &Lendable_class,
    &Book_class,
    &Writer_class,
    &Library_class,
};

/// @brief The description of the library package and its classes.
// @generated
const EPackageInfo LibraryPackage = {
    .name = "library",
    .nsURI = "http://swift-modelling.org/test/library/1.0",
    .nsPrefix = "lib",
    .classes = LibraryPackage_classes,
    .classCount = 5
};

// @generated
EObject *LibraryFactory_create(const EClassInfo *eClass) {
    for (size_t position = 0; position < LibraryPackage.classCount; position++) {
        if (LibraryPackage.classes[position] == eClass) {
            return eClass->create == NULL ? NULL : eClass->create();
        }
    }
    return NULL;
}
