//
//  cnames.h
//

#ifndef CNAMES_CNAMES_H
#define CNAMES_CNAMES_H

#include "EObject.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
// @generated
extern "C" {
#endif

/// @brief The Vehicle class.
// @generated
typedef struct Vehicle Vehicle;

/// @brief The Truck class.
// @generated
typedef struct Truck Truck;

/// @brief The Driver class.
// @generated
typedef struct Driver Driver;

/// @brief The static class.
// @generated
typedef struct static_ static_;

/// @brief The FILE class.
// @generated
typedef struct FILE_ FILE_;

/// @brief The EObject class.
// @generated
typedef struct EObject_ EObject_;

/// @brief The Wheel class.
// @generated
typedef struct Wheel Wheel;

/// @brief The Mode enumeration.
// @generated
enum Mode {
    /// @brief The and literal.
    // @generated
    Mode_and = 0,

    /// @brief The default literal.
    // @generated
    Mode_default = 1,

    /// @brief The int literal.
    // @generated
    Mode_int = 2,

    /// @brief The NULL literal.
    // @generated
    Mode_NULL = 3,

    /// @brief The new literal.
    // @generated
    Mode_new = 4,

    /// @brief The true literal.
    // @generated
    Mode_true = 5,
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

/// @brief The size_t data type.
// @generated
typedef int64_t size_t_;

/// @brief The description of the Vehicle class.
// @generated
extern const EClassInfo Vehicle_class;

/// @brief A vehicle, which other classes extend.
///
/// Its features are named with words that C and C++ reserve.
// @generated
struct Vehicle {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The int attribute.
    // @generated
    int32_t int_;

    /// @brief The register attribute.
    // @generated
    char *register_;

    /// @brief The union attribute.
    // @generated
    bool union_;

    /// @brief The class attribute.
    // @generated
    char *class_;

    /// @brief The namespace attribute.
    // @generated
    char *namespace_;

    /// @brief The new attribute.
    // @generated
    int32_t new_;

    /// @brief The delete attribute.
    // @generated
    bool delete_;

    /// @brief The template attribute.
    // @generated
    char *template_;

    /// @brief The this attribute.
    // @generated
    char *this_;

    /// @brief The signed attribute.
    // @generated
    double signed_;

    /// @brief The NULL attribute.
    // @generated
    char *NULL_;

    /// @brief The eObject attribute.
    // @generated
    char *eObject_;

    /// @brief The bool attribute.
    // @generated
    bool bool_;

    /// @brief The default attribute.
    // @generated
    char *default_;

    /// @brief The size_t attribute.
    // @generated
    int64_t size_t_;

    /// @brief The mode attribute.
    // @generated
    Mode mode;

    /// @brief The modes attribute.
    // @generated
    EList(Mode) modes;

    /// @brief The keywords attribute.
    // @generated
    EList(char *) keywords;

    /// @brief The driver reference.
    // @generated
    Driver *driver;

    /// @brief The wheels reference.
    // @generated
    EList(Wheel *) wheels;

    /// @brief The static reference.
    // @generated
    static_ *static__;
};

/// @brief Creates a Vehicle object with all features at their defaults.
///
/// The caller owns the object and releases it with Vehicle_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Vehicle *Vehicle_create(void);

/// @brief Destroys a Vehicle object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Vehicle_destroy(Vehicle *self);

/// @brief Returns the value of the int attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
int32_t Vehicle_get_int(const Vehicle *self);

/// @brief Sets the value of the int attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Vehicle_set_int(Vehicle *self, int32_t value);

/// @brief Returns the value of the register attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Vehicle_get_register(const Vehicle *self);

/// @brief Sets the value of the register attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Vehicle_set_register(Vehicle *self, const char *value);

/// @brief Returns the value of the union attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
bool Vehicle_get_union(const Vehicle *self);

/// @brief Sets the value of the union attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Vehicle_set_union(Vehicle *self, bool value);

/// @brief Returns the value of the class attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Vehicle_get_class(const Vehicle *self);

/// @brief Sets the value of the class attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Vehicle_set_class(Vehicle *self, const char *value);

/// @brief Returns the value of the namespace attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Vehicle_get_namespace(const Vehicle *self);

/// @brief Sets the value of the namespace attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Vehicle_set_namespace(Vehicle *self, const char *value);

/// @brief Returns the value of the new attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
int32_t Vehicle_get_new(const Vehicle *self);

/// @brief Sets the value of the new attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Vehicle_set_new(Vehicle *self, int32_t value);

/// @brief Returns the value of the delete attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
bool Vehicle_get_delete(const Vehicle *self);

/// @brief Sets the value of the delete attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Vehicle_set_delete(Vehicle *self, bool value);

/// @brief Returns the value of the template attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Vehicle_get_template(const Vehicle *self);

/// @brief Sets the value of the template attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Vehicle_set_template(Vehicle *self, const char *value);

/// @brief Returns the value of the this attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Vehicle_get_this(const Vehicle *self);

/// @brief Sets the value of the this attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Vehicle_set_this(Vehicle *self, const char *value);

/// @brief Returns the value of the signed attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
double Vehicle_get_signed(const Vehicle *self);

/// @brief Sets the value of the signed attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Vehicle_set_signed(Vehicle *self, double value);

/// @brief Returns the value of the NULL attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Vehicle_get_NULL(const Vehicle *self);

/// @brief Sets the value of the NULL attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Vehicle_set_NULL(Vehicle *self, const char *value);

/// @brief Returns the value of the eObject attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Vehicle_get_eObject(const Vehicle *self);

/// @brief Sets the value of the eObject attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Vehicle_set_eObject(Vehicle *self, const char *value);

/// @brief Returns the value of the bool attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
bool Vehicle_get_bool(const Vehicle *self);

/// @brief Sets the value of the bool attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Vehicle_set_bool(Vehicle *self, bool value);

/// @brief Returns the value of the default attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Vehicle_get_default(const Vehicle *self);

/// @brief Sets the value of the default attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Vehicle_set_default(Vehicle *self, const char *value);

/// @brief Returns the value of the size_t attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
int64_t Vehicle_get_size_t(const Vehicle *self);

/// @brief Sets the value of the size_t attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Vehicle_set_size_t(Vehicle *self, int64_t value);

/// @brief Returns the value of the mode attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
Mode Vehicle_get_mode(const Vehicle *self);

/// @brief Sets the value of the mode attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Vehicle_set_mode(Vehicle *self, Mode value);

/// @brief Returns the number of values of the modes attribute.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Vehicle_count_modes(const Vehicle *self);

/// @brief Returns a value of the modes attribute.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
Mode Vehicle_item_modes(const Vehicle *self, size_t index);

/// @brief Appends a value to the modes attribute.
///
/// The object does not take ownership of the value.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Vehicle_add_modes(Vehicle *self, Mode value);

/// @brief Removes a value from the modes attribute.
///
/// The value that was removed stays alive.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Vehicle_remove_modes(Vehicle *self, size_t index);

/// @brief Removes all values from the modes attribute.
///
/// The values that were removed stay alive.
///
/// @param self The object to change.
// @generated
void Vehicle_clear_modes(Vehicle *self);

/// @brief Returns the number of values of the keywords attribute.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Vehicle_count_keywords(const Vehicle *self);

/// @brief Returns a value of the keywords attribute.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
const char *Vehicle_item_keywords(const Vehicle *self, size_t index);

/// @brief Appends a value to the keywords attribute.
///
/// The object keeps a copy of the value.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Vehicle_add_keywords(Vehicle *self, const char *value);

/// @brief Removes a value from the keywords attribute.
///
/// The object releases the value that it owns.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Vehicle_remove_keywords(Vehicle *self, size_t index);

/// @brief Removes all values from the keywords attribute.
///
/// The object releases the values that it owns.
///
/// @param self The object to change.
// @generated
void Vehicle_clear_keywords(Vehicle *self);

/// @brief Returns the value of the driver reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
Driver *Vehicle_get_driver(const Vehicle *self);

/// @brief Sets the value of the driver reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Vehicle_set_driver(Vehicle *self, Driver *value);

/// @brief Returns the number of values of the wheels reference.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Vehicle_count_wheels(const Vehicle *self);

/// @brief Returns a value of the wheels reference.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
Wheel *Vehicle_item_wheels(const Vehicle *self, size_t index);

/// @brief Appends a value to the wheels reference.
///
/// The object takes ownership of the value when this succeeds, and destroys it with the object.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Vehicle_add_wheels(Vehicle *self, Wheel *value);

/// @brief Removes a value from the wheels reference.
///
/// The object releases the value that it owns.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Vehicle_remove_wheels(Vehicle *self, size_t index);

/// @brief Removes all values from the wheels reference.
///
/// The object releases the values that it owns.
///
/// @param self The object to change.
// @generated
void Vehicle_clear_wheels(Vehicle *self);

/// @brief Returns the value of the static reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
static_ *Vehicle_get_static(const Vehicle *self);

/// @brief Sets the value of the static reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Vehicle_set_static(Vehicle *self, static_ *value);

/// @brief The description of the Truck class.
// @generated
extern const EClassInfo Truck_class;

/// @brief The Truck class.
///
/// Part of the cnames package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Truck {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The int attribute.
    // @generated
    int32_t int_;

    /// @brief The register attribute.
    // @generated
    char *register_;

    /// @brief The union attribute.
    // @generated
    bool union_;

    /// @brief The class attribute.
    // @generated
    char *class_;

    /// @brief The namespace attribute.
    // @generated
    char *namespace_;

    /// @brief The new attribute.
    // @generated
    int32_t new_;

    /// @brief The delete attribute.
    // @generated
    bool delete_;

    /// @brief The template attribute.
    // @generated
    char *template_;

    /// @brief The this attribute.
    // @generated
    char *this_;

    /// @brief The signed attribute.
    // @generated
    double signed_;

    /// @brief The NULL attribute.
    // @generated
    char *NULL_;

    /// @brief The eObject attribute.
    // @generated
    char *eObject_;

    /// @brief The bool attribute.
    // @generated
    bool bool_;

    /// @brief The default attribute.
    // @generated
    char *default_;

    /// @brief The size_t attribute.
    // @generated
    int64_t size_t_;

    /// @brief The mode attribute.
    // @generated
    Mode mode;

    /// @brief The modes attribute.
    // @generated
    EList(Mode) modes;

    /// @brief The keywords attribute.
    // @generated
    EList(char *) keywords;

    /// @brief The driver reference.
    // @generated
    Driver *driver;

    /// @brief The wheels reference.
    // @generated
    EList(Wheel *) wheels;

    /// @brief The static reference.
    // @generated
    static_ *static__;

    /// @brief The operator attribute.
    // @generated
    int32_t operator_;

    /// @brief The goto attribute.
    // @generated
    char *goto_;

    /// @brief The trailer reference.
    // @generated
    Truck *trailer;

    /// @brief The towedBy reference.
    // @generated
    Truck *towedBy;
};

/// @brief Creates a Truck object with all features at their defaults.
///
/// The caller owns the object and releases it with Truck_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Truck *Truck_create(void);

/// @brief Destroys a Truck object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Truck_destroy(Truck *self);

/// @brief Returns the value of the int attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
int32_t Truck_get_int(const Truck *self);

/// @brief Sets the value of the int attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Truck_set_int(Truck *self, int32_t value);

/// @brief Returns the value of the register attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Truck_get_register(const Truck *self);

/// @brief Sets the value of the register attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Truck_set_register(Truck *self, const char *value);

/// @brief Returns the value of the union attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
bool Truck_get_union(const Truck *self);

/// @brief Sets the value of the union attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Truck_set_union(Truck *self, bool value);

/// @brief Returns the value of the class attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Truck_get_class(const Truck *self);

/// @brief Sets the value of the class attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Truck_set_class(Truck *self, const char *value);

/// @brief Returns the value of the namespace attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Truck_get_namespace(const Truck *self);

/// @brief Sets the value of the namespace attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Truck_set_namespace(Truck *self, const char *value);

/// @brief Returns the value of the new attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
int32_t Truck_get_new(const Truck *self);

/// @brief Sets the value of the new attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Truck_set_new(Truck *self, int32_t value);

/// @brief Returns the value of the delete attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
bool Truck_get_delete(const Truck *self);

/// @brief Sets the value of the delete attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Truck_set_delete(Truck *self, bool value);

/// @brief Returns the value of the template attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Truck_get_template(const Truck *self);

/// @brief Sets the value of the template attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Truck_set_template(Truck *self, const char *value);

/// @brief Returns the value of the this attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Truck_get_this(const Truck *self);

/// @brief Sets the value of the this attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Truck_set_this(Truck *self, const char *value);

/// @brief Returns the value of the signed attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
double Truck_get_signed(const Truck *self);

/// @brief Sets the value of the signed attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Truck_set_signed(Truck *self, double value);

/// @brief Returns the value of the NULL attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Truck_get_NULL(const Truck *self);

/// @brief Sets the value of the NULL attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Truck_set_NULL(Truck *self, const char *value);

/// @brief Returns the value of the eObject attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Truck_get_eObject(const Truck *self);

/// @brief Sets the value of the eObject attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Truck_set_eObject(Truck *self, const char *value);

/// @brief Returns the value of the bool attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
bool Truck_get_bool(const Truck *self);

/// @brief Sets the value of the bool attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Truck_set_bool(Truck *self, bool value);

/// @brief Returns the value of the default attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Truck_get_default(const Truck *self);

/// @brief Sets the value of the default attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Truck_set_default(Truck *self, const char *value);

/// @brief Returns the value of the size_t attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
int64_t Truck_get_size_t(const Truck *self);

/// @brief Sets the value of the size_t attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Truck_set_size_t(Truck *self, int64_t value);

/// @brief Returns the value of the mode attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
Mode Truck_get_mode(const Truck *self);

/// @brief Sets the value of the mode attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Truck_set_mode(Truck *self, Mode value);

/// @brief Returns the number of values of the modes attribute.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Truck_count_modes(const Truck *self);

/// @brief Returns a value of the modes attribute.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
Mode Truck_item_modes(const Truck *self, size_t index);

/// @brief Appends a value to the modes attribute.
///
/// The object does not take ownership of the value.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Truck_add_modes(Truck *self, Mode value);

/// @brief Removes a value from the modes attribute.
///
/// The value that was removed stays alive.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Truck_remove_modes(Truck *self, size_t index);

/// @brief Removes all values from the modes attribute.
///
/// The values that were removed stay alive.
///
/// @param self The object to change.
// @generated
void Truck_clear_modes(Truck *self);

/// @brief Returns the number of values of the keywords attribute.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Truck_count_keywords(const Truck *self);

/// @brief Returns a value of the keywords attribute.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
const char *Truck_item_keywords(const Truck *self, size_t index);

/// @brief Appends a value to the keywords attribute.
///
/// The object keeps a copy of the value.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Truck_add_keywords(Truck *self, const char *value);

/// @brief Removes a value from the keywords attribute.
///
/// The object releases the value that it owns.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Truck_remove_keywords(Truck *self, size_t index);

/// @brief Removes all values from the keywords attribute.
///
/// The object releases the values that it owns.
///
/// @param self The object to change.
// @generated
void Truck_clear_keywords(Truck *self);

/// @brief Returns the value of the driver reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
Driver *Truck_get_driver(const Truck *self);

/// @brief Sets the value of the driver reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Truck_set_driver(Truck *self, Driver *value);

/// @brief Returns the number of values of the wheels reference.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Truck_count_wheels(const Truck *self);

/// @brief Returns a value of the wheels reference.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
Wheel *Truck_item_wheels(const Truck *self, size_t index);

/// @brief Appends a value to the wheels reference.
///
/// The object takes ownership of the value when this succeeds, and destroys it with the object.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Truck_add_wheels(Truck *self, Wheel *value);

/// @brief Removes a value from the wheels reference.
///
/// The object releases the value that it owns.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Truck_remove_wheels(Truck *self, size_t index);

/// @brief Removes all values from the wheels reference.
///
/// The object releases the values that it owns.
///
/// @param self The object to change.
// @generated
void Truck_clear_wheels(Truck *self);

/// @brief Returns the value of the static reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
static_ *Truck_get_static(const Truck *self);

/// @brief Sets the value of the static reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Truck_set_static(Truck *self, static_ *value);

/// @brief Returns the value of the operator attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
int32_t Truck_get_operator(const Truck *self);

/// @brief Sets the value of the operator attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Truck_set_operator(Truck *self, int32_t value);

/// @brief Returns the value of the goto attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Truck_get_goto(const Truck *self);

/// @brief Sets the value of the goto attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Truck_set_goto(Truck *self, const char *value);

/// @brief Returns the value of the trailer reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
Truck *Truck_get_trailer(const Truck *self);

/// @brief Sets the value of the trailer reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Truck_set_trailer(Truck *self, Truck *value);

/// @brief Returns the value of the towedBy reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
Truck *Truck_get_towedBy(const Truck *self);

/// @brief Sets the value of the towedBy reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Truck_set_towedBy(Truck *self, Truck *value);

/// @brief The description of the Driver class.
// @generated
extern const EClassInfo Driver_class;

/// @brief The Driver class.
///
/// Part of the cnames package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Driver {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The vehicle reference.
    // @generated
    EObject *vehicle;
};

/// @brief Creates a Driver object with all features at their defaults.
///
/// The caller owns the object and releases it with Driver_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Driver *Driver_create(void);

/// @brief Destroys a Driver object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Driver_destroy(Driver *self);

/// @brief Returns the value of the vehicle reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
EObject *Driver_get_vehicle(const Driver *self);

/// @brief Sets the value of the vehicle reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Driver_set_vehicle(Driver *self, EObject *value);

/// @brief The description of the static class.
// @generated
extern const EClassInfo static__class;

/// @brief A class whose name is a keyword.
// @generated
struct static_ {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The volatile attribute.
    // @generated
    bool volatile_;
};

/// @brief Creates a static object with all features at their defaults.
///
/// The caller owns the object and releases it with static__destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
static_ *static__create(void);

/// @brief Destroys a static object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void static__destroy(static_ *self);

/// @brief Returns the value of the volatile attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
bool static__get_volatile(const static_ *self);

/// @brief Sets the value of the volatile attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void static__set_volatile(static_ *self, bool value);

/// @brief The description of the FILE class.
// @generated
extern const EClassInfo FILE__class;

/// @brief The FILE class.
///
/// Part of the cnames package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct FILE_ {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;
};

/// @brief Creates a FILE object with all features at their defaults.
///
/// The caller owns the object and releases it with FILE__destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
FILE_ *FILE__create(void);

/// @brief Destroys a FILE object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void FILE__destroy(FILE_ *self);

/// @brief The description of the EObject class.
// @generated
extern const EClassInfo EObject__class;

/// @brief The EObject class.
///
/// Part of the cnames package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct EObject_ {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The eClass attribute.
    // @generated
    char *eClass_;
};

/// @brief Creates a EObject object with all features at their defaults.
///
/// The caller owns the object and releases it with EObject__destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
EObject_ *EObject__create(void);

/// @brief Destroys a EObject object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void EObject__destroy(EObject_ *self);

/// @brief Returns the value of the eClass attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *EObject__get_eClass(const EObject_ *self);

/// @brief Sets the value of the eClass attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool EObject__set_eClass(EObject_ *self, const char *value);

/// @brief The Shape class.
///
/// Part of the cnames package.
/// The class has no instances, so references to it hold plain objects.
// @generated
extern const EClassInfo Shape_class;

/// @brief The description of the cnames package and its classes.
// @generated
extern const EPackageInfo CnamesPackage;

/// @brief Creates an object for a class of the cnames package.
///
/// @param eClass The description of the class to create an object of.
/// @return The new object, which the caller releases with EObject_destroy; the null pointer if the class does not
///         belong to the package, has no instances, or the memory could not be allocated.
// @generated
EObject *CnamesFactory_create(const EClassInfo *eClass);

#ifdef __cplusplus
}
#endif

#endif
