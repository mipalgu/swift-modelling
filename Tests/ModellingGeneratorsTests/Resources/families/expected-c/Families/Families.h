//
//  Families.h
//

#ifndef FAMILIES_FAMILIES_H
#define FAMILIES_FAMILIES_H

#include "EObject.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
// @generated
extern "C" {
#endif

/// @brief The Family class.
// @generated
typedef struct Family Family;

/// @brief The Member class.
// @generated
typedef struct Member Member;

/// @brief The description of the Family class.
// @generated
extern const EClassInfo Family_class;

/// @brief The Family class.
///
/// Part of the Families package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Family {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The lastName attribute.
    // @generated
    char *lastName;

    /// @brief The father reference.
    // @generated
    Member *father;

    /// @brief The mother reference.
    // @generated
    Member *mother;

    /// @brief The sons reference.
    // @generated
    EList(Member *) sons;

    /// @brief The daughters reference.
    // @generated
    EList(Member *) daughters;
};

/// @brief Creates a Family object with all features at their defaults.
///
/// The caller owns the object and releases it with Family_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Family *Family_create(void);

/// @brief Destroys a Family object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Family_destroy(Family *self);

/// @brief Returns the value of the lastName attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Family_get_lastName(const Family *self);

/// @brief Sets the value of the lastName attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Family_set_lastName(Family *self, const char *value);

/// @brief Returns the value of the father reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
Member *Family_get_father(const Family *self);

/// @brief Sets the value of the father reference.
///
/// The object takes ownership of the value and destroys the previous one, unless it is the same object.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Family_set_father(Family *self, Member *value);

/// @brief Returns the value of the mother reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
Member *Family_get_mother(const Family *self);

/// @brief Sets the value of the mother reference.
///
/// The object takes ownership of the value and destroys the previous one, unless it is the same object.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Family_set_mother(Family *self, Member *value);

/// @brief Returns the number of values of the sons reference.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Family_count_sons(const Family *self);

/// @brief Returns a value of the sons reference.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
Member *Family_item_sons(const Family *self, size_t index);

/// @brief Appends a value to the sons reference.
///
/// The object takes ownership of the value when this succeeds, and destroys it with the object.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Family_add_sons(Family *self, Member *value);

/// @brief Removes a value from the sons reference.
///
/// The object releases the value that it owns.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Family_remove_sons(Family *self, size_t index);

/// @brief Removes all values from the sons reference.
///
/// The object releases the values that it owns.
///
/// @param self The object to change.
// @generated
void Family_clear_sons(Family *self);

/// @brief Returns the number of values of the daughters reference.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Family_count_daughters(const Family *self);

/// @brief Returns a value of the daughters reference.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
Member *Family_item_daughters(const Family *self, size_t index);

/// @brief Appends a value to the daughters reference.
///
/// The object takes ownership of the value when this succeeds, and destroys it with the object.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Family_add_daughters(Family *self, Member *value);

/// @brief Removes a value from the daughters reference.
///
/// The object releases the value that it owns.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Family_remove_daughters(Family *self, size_t index);

/// @brief Removes all values from the daughters reference.
///
/// The object releases the values that it owns.
///
/// @param self The object to change.
// @generated
void Family_clear_daughters(Family *self);

/// @brief The description of the Member class.
// @generated
extern const EClassInfo Member_class;

/// @brief The Member class.
///
/// Part of the Families package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Member {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The firstName attribute.
    // @generated
    char *firstName;

    /// @brief The familyFather reference.
    // @generated
    Family *familyFather;

    /// @brief The familyMother reference.
    // @generated
    Family *familyMother;

    /// @brief The familySon reference.
    // @generated
    Family *familySon;

    /// @brief The familyDaughter reference.
    // @generated
    Family *familyDaughter;
};

/// @brief Creates a Member object with all features at their defaults.
///
/// The caller owns the object and releases it with Member_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Member *Member_create(void);

/// @brief Destroys a Member object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Member_destroy(Member *self);

/// @brief Returns the value of the firstName attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Member_get_firstName(const Member *self);

/// @brief Sets the value of the firstName attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Member_set_firstName(Member *self, const char *value);

/// @brief Returns the value of the familyFather reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
Family *Member_get_familyFather(const Member *self);

/// @brief Sets the value of the familyFather reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Member_set_familyFather(Member *self, Family *value);

/// @brief Returns the value of the familyMother reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
Family *Member_get_familyMother(const Member *self);

/// @brief Sets the value of the familyMother reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Member_set_familyMother(Member *self, Family *value);

/// @brief Returns the value of the familySon reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
Family *Member_get_familySon(const Member *self);

/// @brief Sets the value of the familySon reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Member_set_familySon(Member *self, Family *value);

/// @brief Returns the value of the familyDaughter reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
Family *Member_get_familyDaughter(const Member *self);

/// @brief Sets the value of the familyDaughter reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Member_set_familyDaughter(Member *self, Family *value);

/// @brief The description of the Families package and its classes.
// @generated
extern const EPackageInfo FamiliesPackage;

/// @brief Creates an object for a class of the Families package.
///
/// @param eClass The description of the class to create an object of.
/// @return The new object, which the caller releases with EObject_destroy; the null pointer if the class does not
///         belong to the package, has no instances, or the memory could not be allocated.
// @generated
EObject *FamiliesFactory_create(const EClassInfo *eClass);

#ifdef __cplusplus
}
#endif

#endif
