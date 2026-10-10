//
//  enumerations.h
//

#ifndef ENUMERATIONS_ENUMERATIONS_H
#define ENUMERATIONS_ENUMERATIONS_H

#include "EObject.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
// @generated
extern "C" {
#endif

/// @brief The Light class.
// @generated
typedef struct Light Light;

/// @brief The Colour enumeration.
// @generated
enum Colour {
    /// @brief The Red literal.
    // @generated
    Colour_Red = 0,

    /// @brief The Amber literal.
    // @generated
    Colour_Amber = 1,

    /// @brief The Yellow literal, which has the value of Amber.
    // @generated
    Colour_Yellow = 1,

    /// @brief The Green literal.
    // @generated
    Colour_Green = 5,
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

/// @brief The Mode enumeration.
// @generated
enum Mode {
    /// @brief The default literal.
    // @generated
    Mode_default = 0,

    /// @brief The fastForward literal.
    // @generated
    Mode_fastForward = 1,

    /// @brief The HTTPServer literal.
    // @generated
    Mode_HTTPServer = 2,

    /// @brief The _ literal.
    // @generated
    Mode__ = 3,

    /// @brief The quote literal.
    // @generated
    Mode_quote = 4,
};

/// @brief The Mode enumeration.
// @generated
typedef enum Mode Mode;

/// @brief Returns the text that stands for a literal of the Mode enumeration in a serialised model.
///
/// @param value The value to look up.
/// @return The text of the first literal that has the value; the null pointer if no literal has it.
// @generated
const char *Mode_literal(Mode value);

/// @brief Finds the literal of the Mode enumeration that a text stands for.
///
/// @param literal The text of the literal in a serialised model.
/// @param value Receives the literal if the text stands for one; left alone otherwise.
/// @return `true` if the text stands for a literal; `false` otherwise.
// @generated
bool Mode_from_literal(const char *literal, Mode *value);

/// @brief The Empty enumeration.
///
/// It has no literals, so any integer is a value.
// @generated
typedef int Empty;

/// @brief Returns the text that stands for a literal of the Empty enumeration in a serialised model.
///
/// @param value The value to look up.
/// @return The text of the first literal that has the value; the null pointer if no literal has it.
// @generated
const char *Empty_literal(Empty value);

/// @brief Finds the literal of the Empty enumeration that a text stands for.
///
/// @param literal The text of the literal in a serialised model.
/// @param value Receives the literal if the text stands for one; left alone otherwise.
/// @return `true` if the text stands for a literal; `false` otherwise.
// @generated
bool Empty_from_literal(const char *literal, Empty *value);

/// @brief The description of the Light class.
// @generated
extern const EClassInfo Light_class;

/// @brief The Light class.
///
/// Part of the enumerations package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Light {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The colour attribute.
    // @generated
    Colour colour;

    /// @brief The mode attribute.
    // @generated
    Mode mode;
};

/// @brief Creates a Light object with all features at their defaults.
///
/// The caller owns the object and releases it with Light_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Light *Light_create(void);

/// @brief Destroys a Light object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Light_destroy(Light *self);

/// @brief Returns the value of the colour attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
Colour Light_get_colour(const Light *self);

/// @brief Sets the value of the colour attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Light_set_colour(Light *self, Colour value);

/// @brief Returns the value of the mode attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
Mode Light_get_mode(const Light *self);

/// @brief Sets the value of the mode attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Light_set_mode(Light *self, Mode value);

/// @brief The description of the enumerations package and its classes.
// @generated
extern const EPackageInfo EnumerationsPackage;

/// @brief Creates an object for a class of the enumerations package.
///
/// @param eClass The description of the class to create an object of.
/// @return The new object, which the caller releases with EObject_destroy; the null pointer if the class does not
///         belong to the package, has no instances, or the memory could not be allocated.
// @generated
EObject *EnumerationsFactory_create(const EClassInfo *eClass);

#ifdef __cplusplus
}
#endif

#endif
