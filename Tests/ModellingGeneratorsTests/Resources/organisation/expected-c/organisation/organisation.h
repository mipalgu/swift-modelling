//
//  organisation.h
//

#ifndef ORGANISATION_ORGANISATION_H
#define ORGANISATION_ORGANISATION_H

#include "EObject.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
// @generated
extern "C" {
#endif

/// @brief The Person class.
// @generated
typedef struct Person Person;

/// @brief The Team class.
// @generated
typedef struct Team Team;

/// @brief The Organisation class.
// @generated
typedef struct Organisation Organisation;

/// @brief The description of the Person class.
// @generated
extern const EClassInfo Person_class;

/// @brief The Person class.
///
/// Part of the organisation package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Person {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The name attribute.
    // @generated
    char *name;

    /// @brief The age attribute.
    // @generated
    int32_t age;
};

/// @brief Creates a Person object with all features at their defaults.
///
/// The caller owns the object and releases it with Person_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Person *Person_create(void);

/// @brief Destroys a Person object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Person_destroy(Person *self);

/// @brief Returns the value of the name attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Person_get_name(const Person *self);

/// @brief Sets the value of the name attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Person_set_name(Person *self, const char *value);

/// @brief Returns the value of the age attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
int32_t Person_get_age(const Person *self);

/// @brief Sets the value of the age attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Person_set_age(Person *self, int32_t value);

/// @brief The description of the Team class.
// @generated
extern const EClassInfo Team_class;

/// @brief The Team class.
///
/// Part of the organisation package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Team {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The name attribute.
    // @generated
    char *name;

    /// @brief The members reference.
    // @generated
    EList(Person *) members;

    /// @brief The leader reference.
    // @generated
    Person *leader;
};

/// @brief Creates a Team object with all features at their defaults.
///
/// The caller owns the object and releases it with Team_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Team *Team_create(void);

/// @brief Destroys a Team object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Team_destroy(Team *self);

/// @brief Returns the value of the name attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Team_get_name(const Team *self);

/// @brief Sets the value of the name attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Team_set_name(Team *self, const char *value);

/// @brief Returns the number of values of the members reference.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Team_count_members(const Team *self);

/// @brief Returns a value of the members reference.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
Person *Team_item_members(const Team *self, size_t index);

/// @brief Appends a value to the members reference.
///
/// The object takes ownership of the value when this succeeds, and destroys it with the object.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Team_add_members(Team *self, Person *value);

/// @brief Removes a value from the members reference.
///
/// The object releases the value that it owns.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Team_remove_members(Team *self, size_t index);

/// @brief Removes all values from the members reference.
///
/// The object releases the values that it owns.
///
/// @param self The object to change.
// @generated
void Team_clear_members(Team *self);

/// @brief Returns the value of the leader reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
Person *Team_get_leader(const Team *self);

/// @brief Sets the value of the leader reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Team_set_leader(Team *self, Person *value);

/// @brief The description of the Organisation class.
// @generated
extern const EClassInfo Organisation_class;

/// @brief The Organisation class.
///
/// Part of the organisation package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Organisation {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The name attribute.
    // @generated
    char *name;

    /// @brief The teams reference.
    // @generated
    EList(Team *) teams;
};

/// @brief Creates a Organisation object with all features at their defaults.
///
/// The caller owns the object and releases it with Organisation_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Organisation *Organisation_create(void);

/// @brief Destroys a Organisation object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Organisation_destroy(Organisation *self);

/// @brief Returns the value of the name attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Organisation_get_name(const Organisation *self);

/// @brief Sets the value of the name attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Organisation_set_name(Organisation *self, const char *value);

/// @brief Returns the number of values of the teams reference.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Organisation_count_teams(const Organisation *self);

/// @brief Returns a value of the teams reference.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
Team *Organisation_item_teams(const Organisation *self, size_t index);

/// @brief Appends a value to the teams reference.
///
/// The object takes ownership of the value when this succeeds, and destroys it with the object.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Organisation_add_teams(Organisation *self, Team *value);

/// @brief Removes a value from the teams reference.
///
/// The object releases the value that it owns.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Organisation_remove_teams(Organisation *self, size_t index);

/// @brief Removes all values from the teams reference.
///
/// The object releases the values that it owns.
///
/// @param self The object to change.
// @generated
void Organisation_clear_teams(Organisation *self);

/// @brief The description of the organisation package and its classes.
// @generated
extern const EPackageInfo OrgPackage;

/// @brief Creates an object for a class of the organisation package.
///
/// @param eClass The description of the class to create an object of.
/// @return The new object, which the caller releases with EObject_destroy; the null pointer if the class does not
///         belong to the package, has no instances, or the memory could not be allocated.
// @generated
EObject *OrgFactory_create(const EClassInfo *eClass);

#ifdef __cplusplus
}
#endif

#endif
