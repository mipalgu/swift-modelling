//
//  datatypes.h
//

#ifndef DATATYPES_DATATYPES_H
#define DATATYPES_DATATYPES_H

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

/// @brief The Class class.
// @generated
typedef struct Class Class;

/// @brief The Gizmo class.
// @generated
typedef struct Gizmo Gizmo;

/// @brief The Colour enumeration.
// @generated
enum Colour {
    /// @brief The Red literal.
    // @generated
    Colour_Red = 0,
};

/// @brief The Colour enumeration.
// @generated
typedef enum Colour Colour;

/// @brief Returns the text that stands for a literal of the Colour enumeration in a serialised model.
///
/// @param value The value to look up.
/// @return The text of the first literal that has the value; the null pointer if no literal has it.
// @generated
const char *Colour_literal(Colour value);

/// @brief Finds the literal of the Colour enumeration that a text stands for.
///
/// @param literal The text of the literal in a serialised model.
/// @param value Receives the literal if the text stands for one; left alone otherwise.
/// @return `true` if the text stands for a literal; `false` otherwise.
// @generated
bool Colour_from_literal(const char *literal, Colour *value);

/// @brief The Count data type.
// @generated
typedef int32_t Count;

/// @brief The Anything data type.
// @generated
typedef void *Anything;

/// @brief The Stamp data type.
// @generated
typedef int64_t Stamp;

/// @brief The Hidden data type.
// @generated
typedef char *Hidden;

/// @brief The description of the Thing class.
// @generated
extern const EClassInfo Thing_class;

/// @brief The Thing class.
///
/// Part of the datatypes package.
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

/// @brief The description of the Class class.
// @generated
extern const EClassInfo Class_class;

/// @brief The Class class.
///
/// Part of the datatypes package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Class {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;
};

/// @brief Creates a Class object with all features at their defaults.
///
/// The caller owns the object and releases it with Class_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Class *Class_create(void);

/// @brief Destroys a Class object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Class_destroy(Class *self);

/// @brief The description of the Gizmo class.
// @generated
extern const EClassInfo Gizmo_class;

/// @brief Old.
/// @deprecated Use Thing
/// @since 2.0
// @generated
struct Gizmo {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;
};

/// @brief Creates a Gizmo object with all features at their defaults.
///
/// The caller owns the object and releases it with Gizmo_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Gizmo *Gizmo_create(void);

/// @brief Destroys a Gizmo object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Gizmo_destroy(Gizmo *self);

/// @brief The description of the datatypes package and its classes.
// @generated
extern const EPackageInfo DatatypesPackage;

/// @brief Creates an object for a class of the datatypes package.
///
/// @param eClass The description of the class to create an object of.
/// @return The new object, which the caller releases with EObject_destroy; the null pointer if the class does not
///         belong to the package, has no instances, or the memory could not be allocated.
// @generated
EObject *DatatypesFactory_create(const EClassInfo *eClass);

#ifdef __cplusplus
}
#endif

#endif
