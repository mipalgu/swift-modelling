//
//  bridge.h
//

#ifndef BRIDGE_BRIDGE_H
#define BRIDGE_BRIDGE_H

#include "EObject.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
// @generated
extern "C" {
#endif

/// @brief The Span class.
// @generated
typedef struct Span Span;

/// @brief The description of the Span class.
// @generated
extern const EClassInfo Span_class;

/// @brief The Span class.
///
/// Part of the bridge package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Span {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The label attribute.
    // @generated
    char *label;

    /// @brief The length attribute.
    // @generated
    double length;

    /// @brief The payload attribute.
    // @generated
    void *payload;

    /// @brief The supports reference.
    // @generated
    EList(EObject *) supports;

    /// @brief The next reference.
    // @generated
    Span *next;
};

/// @brief Creates a Span object with all features at their defaults.
///
/// The caller owns the object and releases it with Span_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Span *Span_create(void);

/// @brief Destroys a Span object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Span_destroy(Span *self);

/// @brief Returns the value of the label attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Span_get_label(const Span *self);

/// @brief Sets the value of the label attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Span_set_label(Span *self, const char *value);

/// @brief Returns the value of the length attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
double Span_get_length(const Span *self);

/// @brief Sets the value of the length attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Span_set_length(Span *self, double value);

/// @brief Returns the value of the payload attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
void *Span_get_payload(const Span *self);

/// @brief Sets the value of the payload attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Span_set_payload(Span *self, void *value);

/// @brief Returns the number of values of the supports reference.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Span_count_supports(const Span *self);

/// @brief Returns a value of the supports reference.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
EObject *Span_item_supports(const Span *self, size_t index);

/// @brief Appends a value to the supports reference.
///
/// The object does not take ownership of the value.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Span_add_supports(Span *self, EObject *value);

/// @brief Removes a value from the supports reference.
///
/// The value that was removed stays alive.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Span_remove_supports(Span *self, size_t index);

/// @brief Removes all values from the supports reference.
///
/// The values that were removed stay alive.
///
/// @param self The object to change.
// @generated
void Span_clear_supports(Span *self);

/// @brief Returns the value of the next reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
Span *Span_get_next(const Span *self);

/// @brief Sets the value of the next reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Span_set_next(Span *self, Span *value);

/// @brief The description of the bridge package and its classes.
// @generated
extern const EPackageInfo BridgePackage;

/// @brief Creates an object for a class of the bridge package.
///
/// @param eClass The description of the class to create an object of.
/// @return The new object, which the caller releases with EObject_destroy; the null pointer if the class does not
///         belong to the package, has no instances, or the memory could not be allocated.
// @generated
EObject *BridgeFactory_create(const EClassInfo *eClass);

#ifdef __cplusplus
}
#endif

#endif
