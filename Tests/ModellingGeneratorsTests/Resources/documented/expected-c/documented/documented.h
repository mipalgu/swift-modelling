//
//  documented.h
//

#ifndef DOCUMENTED_DOCUMENTED_H
#define DOCUMENTED_DOCUMENTED_H

#include "EObject.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
// @generated
extern "C" {
#endif

/// @brief The levels of an alarm.
/// Higher levels need quicker action.
// @generated
enum Level {
    /// @brief The Low literal.
    // @generated
    Level_Low = 0,

    /// @brief Immediate action.
    /// Wake somebody.
    // @generated
    Level_High = 1,

    /// @deprecated use High
    // @generated
    Level_Old = 2,
};

/// @brief The Level enumeration.
// @generated
typedef enum Level Level;

/// @brief Returns the text that stands for a literal of the Level enumeration in a serialised model.
///
/// @param value The value to look up.
/// @return The text of the first literal that has the value; the null pointer if no literal has it.
// @generated
const char *Level_literal(Level value);

/// @brief Finds the literal of the Level enumeration that a text stands for.
///
/// @param literal The text of the literal in a serialised model.
/// @param value Receives the literal if the text stands for one; left alone otherwise.
/// @return `true` if the text stands for a literal; `false` otherwise.
// @generated
bool Level_from_literal(const char *literal, Level *value);

/// @brief The description of the documented package and its classes.
// @generated
extern const EPackageInfo DocumentedPackage;

/// @brief Creates an object for a class of the documented package.
///
/// @param eClass The description of the class to create an object of.
/// @return The new object, which the caller releases with EObject_destroy; the null pointer if the class does not
///         belong to the package, has no instances, or the memory could not be allocated.
// @generated
EObject *DocumentedFactory_create(const EClassInfo *eClass);

#ifdef __cplusplus
}
#endif

#endif
