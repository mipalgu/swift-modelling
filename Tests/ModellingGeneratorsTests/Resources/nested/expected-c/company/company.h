//
//  company.h
//

#ifndef COMPANY_COMPANY_H
#define COMPANY_COMPANY_H

#include "EObject.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
// @generated
extern "C" {
#endif

/// @brief The Company class.
// @generated
typedef struct Company Company;

/// @brief The Employee class.
// @generated
typedef struct Employee Employee;

/// @brief The Project class.
// @generated
typedef struct Project Project;

/// @brief The description of the Company class.
// @generated
extern const EClassInfo Company_class;

/// @brief The Company class.
///
/// Part of the company package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Company {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The name attribute.
    // @generated
    char *name;

    /// @brief The staff reference.
    // @generated
    EList(Employee *) staff;

    /// @brief The projects reference.
    // @generated
    EList(Project *) projects;
};

/// @brief Creates a Company object with all features at their defaults.
///
/// The caller owns the object and releases it with Company_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Company *Company_create(void);

/// @brief Destroys a Company object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Company_destroy(Company *self);

/// @brief Returns the value of the name attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Company_get_name(const Company *self);

/// @brief Sets the value of the name attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Company_set_name(Company *self, const char *value);

/// @brief Returns the number of values of the staff reference.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Company_count_staff(const Company *self);

/// @brief Returns a value of the staff reference.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
Employee *Company_item_staff(const Company *self, size_t index);

/// @brief Appends a value to the staff reference.
///
/// The object takes ownership of the value when this succeeds, and destroys it with the object.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Company_add_staff(Company *self, Employee *value);

/// @brief Removes a value from the staff reference.
///
/// The object releases the value that it owns.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Company_remove_staff(Company *self, size_t index);

/// @brief Removes all values from the staff reference.
///
/// The object releases the values that it owns.
///
/// @param self The object to change.
// @generated
void Company_clear_staff(Company *self);

/// @brief Returns the number of values of the projects reference.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Company_count_projects(const Company *self);

/// @brief Returns a value of the projects reference.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
Project *Company_item_projects(const Company *self, size_t index);

/// @brief Appends a value to the projects reference.
///
/// The object takes ownership of the value when this succeeds, and destroys it with the object.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Company_add_projects(Company *self, Project *value);

/// @brief Removes a value from the projects reference.
///
/// The object releases the value that it owns.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Company_remove_projects(Company *self, size_t index);

/// @brief Removes all values from the projects reference.
///
/// The object releases the values that it owns.
///
/// @param self The object to change.
// @generated
void Company_clear_projects(Company *self);

/// @brief The description of the company package and its classes.
// @generated
extern const EPackageInfo CompanyPackage;

/// @brief Creates an object for a class of the company package.
///
/// @param eClass The description of the class to create an object of.
/// @return The new object, which the caller releases with EObject_destroy; the null pointer if the class does not
///         belong to the package, has no instances, or the memory could not be allocated.
// @generated
EObject *CompanyFactory_create(const EClassInfo *eClass);

#ifdef __cplusplus
}
#endif

#endif
