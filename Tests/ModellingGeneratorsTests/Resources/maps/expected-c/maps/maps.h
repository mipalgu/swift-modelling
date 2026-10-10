//
//  maps.h
//

#ifndef MAPS_MAPS_H
#define MAPS_MAPS_H

#include "EObject.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
// @generated
extern "C" {
#endif

/// @brief The Dictionary class.
// @generated
typedef struct Dictionary Dictionary;

/// @brief The StringToIntEntry class.
// @generated
typedef struct StringToIntEntry StringToIntEntry;

/// @brief The description of the Dictionary class.
// @generated
extern const EClassInfo Dictionary_class;

/// @brief The Dictionary class.
///
/// Part of the maps package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Dictionary {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The entries reference.
    // @generated
    EList(StringToIntEntry *) entries;
};

/// @brief Creates a Dictionary object with all features at their defaults.
///
/// The caller owns the object and releases it with Dictionary_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Dictionary *Dictionary_create(void);

/// @brief Destroys a Dictionary object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Dictionary_destroy(Dictionary *self);

/// @brief Returns the number of values of the entries reference.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Dictionary_count_entries(const Dictionary *self);

/// @brief Returns a value of the entries reference.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
StringToIntEntry *Dictionary_item_entries(const Dictionary *self, size_t index);

/// @brief Appends a value to the entries reference.
///
/// The object takes ownership of the value when this succeeds, and destroys it with the object.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Dictionary_add_entries(Dictionary *self, StringToIntEntry *value);

/// @brief Removes a value from the entries reference.
///
/// The object releases the value that it owns.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Dictionary_remove_entries(Dictionary *self, size_t index);

/// @brief Removes all values from the entries reference.
///
/// The object releases the values that it owns.
///
/// @param self The object to change.
// @generated
void Dictionary_clear_entries(Dictionary *self);

/// @brief The description of the StringToIntEntry class.
// @generated
extern const EClassInfo StringToIntEntry_class;

/// @brief The StringToIntEntry class.
///
/// Part of the maps package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct StringToIntEntry {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The key attribute.
    // @generated
    char *key;

    /// @brief The value attribute.
    // @generated
    int32_t value_;
};

/// @brief Creates a StringToIntEntry object with all features at their defaults.
///
/// The caller owns the object and releases it with StringToIntEntry_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
StringToIntEntry *StringToIntEntry_create(void);

/// @brief Destroys a StringToIntEntry object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void StringToIntEntry_destroy(StringToIntEntry *self);

/// @brief Returns the value of the key attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *StringToIntEntry_get_key(const StringToIntEntry *self);

/// @brief Sets the value of the key attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool StringToIntEntry_set_key(StringToIntEntry *self, const char *value);

/// @brief Returns the value of the value attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
int32_t StringToIntEntry_get_value(const StringToIntEntry *self);

/// @brief Sets the value of the value attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void StringToIntEntry_set_value(StringToIntEntry *self, int32_t value);

/// @brief The description of the maps package and its classes.
// @generated
extern const EPackageInfo MapsPackage;

/// @brief Creates an object for a class of the maps package.
///
/// @param eClass The description of the class to create an object of.
/// @return The new object, which the caller releases with EObject_destroy; the null pointer if the class does not
///         belong to the package, has no instances, or the memory could not be allocated.
// @generated
EObject *MapsFactory_create(const EClassInfo *eClass);

#ifdef __cplusplus
}
#endif

#endif
