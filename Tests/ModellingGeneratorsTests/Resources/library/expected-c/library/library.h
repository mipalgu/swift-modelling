//
//  library.h
//
//  Copyright 2026 Example Pty Ltd
//

#ifndef LIBRARY_LIBRARY_H
#define LIBRARY_LIBRARY_H

#include "EObject.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
// @generated
extern "C" {
#endif

/// @brief The Book class.
// @generated
typedef struct Book Book;

/// @brief The Writer class.
// @generated
typedef struct Writer Writer;

/// @brief The Library class.
// @generated
typedef struct Library Library;

/// @brief The BookCategory enumeration.
// @generated
enum BookCategory {
    /// @brief The Mystery literal.
    // @generated
    BookCategory_Mystery = 0,

    /// @brief The ScienceFiction literal.
    // @generated
    BookCategory_ScienceFiction = 1,

    /// @brief The Biography literal.
    // @generated
    BookCategory_Biography = 2,
};

/// @brief The BookCategory enumeration.
// @generated
typedef enum BookCategory BookCategory;

/// @brief Returns the text that stands for a literal of the BookCategory enumeration in a serialised model.
///
/// @param value The value to look up.
/// @return The text of the first literal that has the value; the null pointer if no literal has it.
// @generated
const char *BookCategory_literal(BookCategory value);

/// @brief Finds the literal of the BookCategory enumeration that a text stands for.
///
/// @param literal The text of the literal in a serialised model.
/// @param value Receives the literal if the text stands for one; left alone otherwise.
/// @return `true` if the text stands for a literal; `false` otherwise.
// @generated
bool BookCategory_from_literal(const char *literal, BookCategory *value);

/// @brief The ISBN data type.
// @generated
typedef char *ISBN;

/// @brief The Named class.
///
/// Part of the library package.
/// The class has no instances, so references to it hold plain objects.
// @generated
extern const EClassInfo Named_class;

/// @brief The Lendable class.
///
/// Part of the library package.
/// The class has no instances, so references to it hold plain objects.
// @generated
extern const EClassInfo Lendable_class;

/// @brief The description of the Book class.
// @generated
extern const EClassInfo Book_class;

/// @brief The Book class.
///
/// Part of the library package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Book {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The name attribute.
    // @generated
    char *name;

    /// @brief The loanDays attribute.
    // @generated
    int32_t loanDays;

    /// @brief The onLoan attribute.
    // @generated
    bool onLoan;

    /// @brief The pages attribute.
    // @generated
    int32_t pages;

    /// @brief The category attribute.
    // @generated
    BookCategory category;

    /// @brief The isbn attribute.
    // @generated
    ISBN isbn;

    /// @brief The author reference.
    // @generated
    Writer *author;

    /// @brief The library reference.
    // @generated
    Library *library;
};

/// @brief Creates a Book object with all features at their defaults.
///
/// The caller owns the object and releases it with Book_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Book *Book_create(void);

/// @brief Destroys a Book object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Book_destroy(Book *self);

/// @brief Returns the value of the name attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Book_get_name(const Book *self);

/// @brief Sets the value of the name attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Book_set_name(Book *self, const char *value);

/// @brief Returns the value of the loanDays attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
int32_t Book_get_loanDays(const Book *self);

/// @brief Sets the value of the loanDays attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Book_set_loanDays(Book *self, int32_t value);

/// @brief Returns the value of the onLoan attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
bool Book_get_onLoan(const Book *self);

/// @brief Sets the value of the onLoan attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Book_set_onLoan(Book *self, bool value);

/// @brief Returns the value of the pages attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
int32_t Book_get_pages(const Book *self);

/// @brief Sets the value of the pages attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Book_set_pages(Book *self, int32_t value);

/// @brief Returns the value of the category attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
BookCategory Book_get_category(const Book *self);

/// @brief Sets the value of the category attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Book_set_category(Book *self, BookCategory value);

/// @brief Returns the value of the isbn attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Book_get_isbn(const Book *self);

/// @brief Sets the value of the isbn attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Book_set_isbn(Book *self, const char *value);

/// @brief Returns the value of the author reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
Writer *Book_get_author(const Book *self);

/// @brief Sets the value of the author reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Book_set_author(Book *self, Writer *value);

/// @brief Returns the value of the library reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
Library *Book_get_library(const Book *self);

/// @brief Sets the value of the library reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Book_set_library(Book *self, Library *value);

/// @brief The description of the Writer class.
// @generated
extern const EClassInfo Writer_class;

/// @brief The Writer class.
///
/// Part of the library package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Writer {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The name attribute.
    // @generated
    char *name;

    /// @brief The aliases attribute.
    // @generated
    EList(char *) aliases;

    /// @brief The books reference.
    // @generated
    EList(Book *) books;
};

/// @brief Creates a Writer object with all features at their defaults.
///
/// The caller owns the object and releases it with Writer_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Writer *Writer_create(void);

/// @brief Destroys a Writer object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Writer_destroy(Writer *self);

/// @brief Returns the value of the name attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Writer_get_name(const Writer *self);

/// @brief Sets the value of the name attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Writer_set_name(Writer *self, const char *value);

/// @brief Returns the number of values of the aliases attribute.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Writer_count_aliases(const Writer *self);

/// @brief Returns a value of the aliases attribute.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
const char *Writer_item_aliases(const Writer *self, size_t index);

/// @brief Appends a value to the aliases attribute.
///
/// The object keeps a copy of the value.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Writer_add_aliases(Writer *self, const char *value);

/// @brief Removes a value from the aliases attribute.
///
/// The object releases the value that it owns.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Writer_remove_aliases(Writer *self, size_t index);

/// @brief Removes all values from the aliases attribute.
///
/// The object releases the values that it owns.
///
/// @param self The object to change.
// @generated
void Writer_clear_aliases(Writer *self);

/// @brief Returns the number of values of the books reference.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Writer_count_books(const Writer *self);

/// @brief Returns a value of the books reference.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
Book *Writer_item_books(const Writer *self, size_t index);

/// @brief Appends a value to the books reference.
///
/// The object does not take ownership of the value.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Writer_add_books(Writer *self, Book *value);

/// @brief Removes a value from the books reference.
///
/// The value that was removed stays alive.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Writer_remove_books(Writer *self, size_t index);

/// @brief Removes all values from the books reference.
///
/// The values that were removed stay alive.
///
/// @param self The object to change.
// @generated
void Writer_clear_books(Writer *self);

/// @brief The description of the Library class.
// @generated
extern const EClassInfo Library_class;

/// @brief The Library class.
///
/// Part of the library package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Library {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The name attribute.
    // @generated
    char *name;

    /// @brief The books reference.
    // @generated
    EList(Book *) books;

    /// @brief The writers reference.
    // @generated
    EList(Writer *) writers;
};

/// @brief Creates a Library object with all features at their defaults.
///
/// The caller owns the object and releases it with Library_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Library *Library_create(void);

/// @brief Destroys a Library object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Library_destroy(Library *self);

/// @brief Returns the value of the name attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Library_get_name(const Library *self);

/// @brief Sets the value of the name attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Library_set_name(Library *self, const char *value);

/// @brief Returns the number of values of the books reference.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Library_count_books(const Library *self);

/// @brief Returns a value of the books reference.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
Book *Library_item_books(const Library *self, size_t index);

/// @brief Appends a value to the books reference.
///
/// The object takes ownership of the value when this succeeds, and destroys it with the object.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Library_add_books(Library *self, Book *value);

/// @brief Removes a value from the books reference.
///
/// The object releases the value that it owns.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Library_remove_books(Library *self, size_t index);

/// @brief Removes all values from the books reference.
///
/// The object releases the values that it owns.
///
/// @param self The object to change.
// @generated
void Library_clear_books(Library *self);

/// @brief Returns the number of values of the writers reference.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Library_count_writers(const Library *self);

/// @brief Returns a value of the writers reference.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
Writer *Library_item_writers(const Library *self, size_t index);

/// @brief Appends a value to the writers reference.
///
/// The object takes ownership of the value when this succeeds, and destroys it with the object.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Library_add_writers(Library *self, Writer *value);

/// @brief Removes a value from the writers reference.
///
/// The object releases the value that it owns.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Library_remove_writers(Library *self, size_t index);

/// @brief Removes all values from the writers reference.
///
/// The object releases the values that it owns.
///
/// @param self The object to change.
// @generated
void Library_clear_writers(Library *self);

/// @brief The description of the library package and its classes.
// @generated
extern const EPackageInfo LibraryPackage;

/// @brief Creates an object for a class of the library package.
///
/// @param eClass The description of the class to create an object of.
/// @return The new object, which the caller releases with EObject_destroy; the null pointer if the class does not
///         belong to the package, has no instances, or the memory could not be allocated.
// @generated
EObject *LibraryFactory_create(const EClassInfo *eClass);

#ifdef __cplusplus
}
#endif

#endif
