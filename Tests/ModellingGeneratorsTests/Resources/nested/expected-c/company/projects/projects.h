//
//  projects.h
//

#ifndef COMPANY_PROJECTS_PROJECTS_H
#define COMPANY_PROJECTS_PROJECTS_H

#include "EObject.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
// @generated
extern "C" {
#endif

/// @brief The Project class.
// @generated
typedef struct Project Project;

/// @brief The Employee class.
// @generated
typedef struct Employee Employee;

/// @brief The Status enumeration.
// @generated
enum Status {
    /// @brief The Proposed literal.
    // @generated
    Status_Proposed = 0,

    /// @brief The Active literal.
    // @generated
    Status_Active = 1,

    /// @brief The Finished literal.
    // @generated
    Status_Finished = 2,
};

/// @brief The Status enumeration.
// @generated
typedef enum Status Status;

/// @brief Returns the text that stands for a literal of the Status enumeration in a serialised model.
///
/// @param value The value to look up.
/// @return The text of the first literal that has the value; the null pointer if no literal has it.
// @generated
const char *Status_literal(Status value);

/// @brief Finds the literal of the Status enumeration that a text stands for.
///
/// @param literal The text of the literal in a serialised model.
/// @param value Receives the literal if the text stands for one; left alone otherwise.
/// @return `true` if the text stands for a literal; `false` otherwise.
// @generated
bool Status_from_literal(const char *literal, Status *value);

/// @brief The description of the Project class.
// @generated
extern const EClassInfo Project_class;

/// @brief The Project class.
///
/// Part of the projects package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Project {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The title attribute.
    // @generated
    char *title;

    /// @brief The status attribute.
    // @generated
    Status status;

    /// @brief The members reference.
    // @generated
    EList(Employee *) members;
};

/// @brief Creates a Project object with all features at their defaults.
///
/// The caller owns the object and releases it with Project_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Project *Project_create(void);

/// @brief Destroys a Project object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Project_destroy(Project *self);

/// @brief Returns the value of the title attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Project_get_title(const Project *self);

/// @brief Sets the value of the title attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Project_set_title(Project *self, const char *value);

/// @brief Returns the value of the status attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
Status Project_get_status(const Project *self);

/// @brief Sets the value of the status attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Project_set_status(Project *self, Status value);

/// @brief Returns the number of values of the members reference.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Project_count_members(const Project *self);

/// @brief Returns a value of the members reference.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
Employee *Project_item_members(const Project *self, size_t index);

/// @brief Appends a value to the members reference.
///
/// The object does not take ownership of the value.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Project_add_members(Project *self, Employee *value);

/// @brief Removes a value from the members reference.
///
/// The value that was removed stays alive.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Project_remove_members(Project *self, size_t index);

/// @brief Removes all values from the members reference.
///
/// The values that were removed stay alive.
///
/// @param self The object to change.
// @generated
void Project_clear_members(Project *self);

/// @brief The description of the projects package and its classes.
// @generated
extern const EPackageInfo ProjPackage;

/// @brief Creates an object for a class of the projects package.
///
/// @param eClass The description of the class to create an object of.
/// @return The new object, which the caller releases with EObject_destroy; the null pointer if the class does not
///         belong to the package, has no instances, or the memory could not be allocated.
// @generated
EObject *ProjFactory_create(const EClassInfo *eClass);

#ifdef __cplusplus
}
#endif

#endif
