//
//  people.h
//

#ifndef COMPANY_PEOPLE_PEOPLE_H
#define COMPANY_PEOPLE_PEOPLE_H

#include "EObject.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
// @generated
extern "C" {
#endif

/// @brief The Employee class.
// @generated
typedef struct Employee Employee;

/// @brief The Person class.
///
/// Part of the people package.
/// The class has no instances, so references to it hold plain objects.
// @generated
extern const EClassInfo Person_class;

/// @brief The description of the Employee class.
// @generated
extern const EClassInfo Employee_class;

/// @brief The Employee class.
///
/// Part of the people package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Employee {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The name attribute.
    // @generated
    char *name;

    /// @brief The salary attribute.
    // @generated
    double salary;
};

/// @brief Creates a Employee object with all features at their defaults.
///
/// The caller owns the object and releases it with Employee_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Employee *Employee_create(void);

/// @brief Destroys a Employee object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Employee_destroy(Employee *self);

/// @brief Returns the value of the name attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Employee_get_name(const Employee *self);

/// @brief Sets the value of the name attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Employee_set_name(Employee *self, const char *value);

/// @brief Returns the value of the salary attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
double Employee_get_salary(const Employee *self);

/// @brief Sets the value of the salary attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Employee_set_salary(Employee *self, double value);

/// @brief The description of the people package and its classes.
// @generated
extern const EPackageInfo PeoplePackage;

/// @brief Creates an object for a class of the people package.
///
/// @param eClass The description of the class to create an object of.
/// @return The new object, which the caller releases with EObject_destroy; the null pointer if the class does not
///         belong to the package, has no instances, or the memory could not be allocated.
// @generated
EObject *PeopleFactory_create(const EClassInfo *eClass);

#ifdef __cplusplus
}
#endif

#endif
