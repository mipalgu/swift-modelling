//
//  delete.h
//

#ifndef CNAMES_DELETE_DELETE_H
#define CNAMES_DELETE_DELETE_H

#include "EObject.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
// @generated
extern "C" {
#endif

/// @brief The Wheel class.
// @generated
typedef struct Wheel Wheel;

/// @brief The description of the Wheel class.
// @generated
extern const EClassInfo Wheel_class;

/// @brief The Wheel class.
///
/// Part of the delete package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Wheel {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The auto attribute.
    // @generated
    char *auto_;

    /// @brief The virtual reference.
    // @generated
    EObject *virtual_;
};

/// @brief Creates a Wheel object with all features at their defaults.
///
/// The caller owns the object and releases it with Wheel_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Wheel *Wheel_create(void);

/// @brief Destroys a Wheel object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Wheel_destroy(Wheel *self);

/// @brief Returns the value of the auto attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Wheel_get_auto(const Wheel *self);

/// @brief Sets the value of the auto attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Wheel_set_auto(Wheel *self, const char *value);

/// @brief Returns the value of the virtual reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
EObject *Wheel_get_virtual(const Wheel *self);

/// @brief Sets the value of the virtual reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Wheel_set_virtual(Wheel *self, EObject *value);

/// @brief The description of the delete package and its classes.
// @generated
extern const EPackageInfo DeletePackage;

/// @brief Creates an object for a class of the delete package.
///
/// @param eClass The description of the class to create an object of.
/// @return The new object, which the caller releases with EObject_destroy; the null pointer if the class does not
///         belong to the package, has no instances, or the memory could not be allocated.
// @generated
EObject *DeleteFactory_create(const EClassInfo *eClass);

#ifdef __cplusplus
}
#endif

#endif
