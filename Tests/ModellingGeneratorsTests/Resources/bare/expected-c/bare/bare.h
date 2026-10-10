//
//  bare.h
//

#ifndef BARE_BARE_H
#define BARE_BARE_H

#include "EObject.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
// @generated
extern "C" {
#endif

/// @brief The Thing class.
// @generated
typedef struct Thing Thing;

/// @brief The description of the Thing class.
// @generated
extern const EClassInfo Thing_class;

/// @brief The Thing class.
///
/// Part of the bare package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Thing {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;
};

/// @brief Creates a Thing object with all features at their defaults.
///
/// The caller owns the object and releases it with Thing_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Thing *Thing_create(void);

/// @brief Destroys a Thing object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Thing_destroy(Thing *self);

/// @brief The description of the bare package and its classes.
// @generated
extern const EPackageInfo BarePackage;

/// @brief Creates an object for a class of the bare package.
///
/// @param eClass The description of the class to create an object of.
/// @return The new object, which the caller releases with EObject_destroy; the null pointer if the class does not
///         belong to the package, has no instances, or the memory could not be allocated.
// @generated
EObject *BareFactory_create(const EClassInfo *eClass);

#ifdef __cplusplus
}
#endif

#endif
