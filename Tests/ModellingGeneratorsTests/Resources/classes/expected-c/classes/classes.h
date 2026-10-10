//
//  classes.h
//

#ifndef CLASSES_CLASSES_H
#define CLASSES_CLASSES_H

#include "EObject.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
// @generated
extern "C" {
#endif

/// @brief The Canvas class.
// @generated
typedef struct Canvas Canvas;

/// @brief The Circle class.
// @generated
typedef struct Circle Circle;

/// @brief The Colour enumeration.
// @generated
enum Colour {
    /// @brief The Red literal.
    // @generated
    Colour_Red = 0,

    /// @brief The Green literal.
    // @generated
    Colour_Green = 1,

    /// @brief The Blue literal.
    // @generated
    Colour_Blue = 2,
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

/// @brief A shape on a canvas.
/// Shapes know their bounds.
/// @since 1.2
// @generated
extern const EClassInfo Shape_class;

/// @brief The description of the Canvas class.
// @generated
extern const EClassInfo Canvas_class;

/// @brief The Canvas class.
///
/// Part of the classes package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Canvas {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The shapes reference.
    // @generated
    EList(EObject *) shapes;

    /// @brief The background reference.
    // @generated
    EObject *background;

    /// @brief The favourites reference.
    // @generated
    EList(EObject *) favourites;

    /// @brief The selected reference.
    // @generated
    EObject *selected;

    /// @brief The primary reference.
    // @generated
    EObject *primary;
};

/// @brief Creates a Canvas object with all features at their defaults.
///
/// The caller owns the object and releases it with Canvas_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Canvas *Canvas_create(void);

/// @brief Destroys a Canvas object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Canvas_destroy(Canvas *self);

/// @brief Returns the number of values of the shapes reference.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Canvas_count_shapes(const Canvas *self);

/// @brief Returns a value of the shapes reference.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
EObject *Canvas_item_shapes(const Canvas *self, size_t index);

/// @brief Appends a value to the shapes reference.
///
/// The object takes ownership of the value when this succeeds, and destroys it with the object.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Canvas_add_shapes(Canvas *self, EObject *value);

/// @brief Removes a value from the shapes reference.
///
/// The object releases the value that it owns.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Canvas_remove_shapes(Canvas *self, size_t index);

/// @brief Removes all values from the shapes reference.
///
/// The object releases the values that it owns.
///
/// @param self The object to change.
// @generated
void Canvas_clear_shapes(Canvas *self);

/// @brief Returns the value of the background reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
EObject *Canvas_get_background(const Canvas *self);

/// @brief Sets the value of the background reference.
///
/// The object takes ownership of the value and destroys the previous one, unless it is the same object.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Canvas_set_background(Canvas *self, EObject *value);

/// @brief Returns the number of values of the favourites reference.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Canvas_count_favourites(const Canvas *self);

/// @brief Returns a value of the favourites reference.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
EObject *Canvas_item_favourites(const Canvas *self, size_t index);

/// @brief Appends a value to the favourites reference.
///
/// The object does not take ownership of the value.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Canvas_add_favourites(Canvas *self, EObject *value);

/// @brief Removes a value from the favourites reference.
///
/// The value that was removed stays alive.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Canvas_remove_favourites(Canvas *self, size_t index);

/// @brief Removes all values from the favourites reference.
///
/// The values that were removed stay alive.
///
/// @param self The object to change.
// @generated
void Canvas_clear_favourites(Canvas *self);

/// @brief Returns the value of the selected reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
EObject *Canvas_get_selected(const Canvas *self);

/// @brief Sets the value of the selected reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Canvas_set_selected(Canvas *self, EObject *value);

/// @brief Returns the value of the primary reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
EObject *Canvas_get_primary(const Canvas *self);

/// @brief Sets the value of the primary reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Canvas_set_primary(Canvas *self, EObject *value);

/// @brief The Named class.
///
/// Part of the classes package.
/// The class has no instances, so references to it hold plain objects.
// @generated
extern const EClassInfo Named_class;

/// @brief The description of the Circle class.
// @generated
extern const EClassInfo Circle_class;

/// @brief The Circle class.
///
/// Part of the classes package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Circle {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The label of the shape.
    // @generated
    char *label;

    /// @brief The visible attribute.
    // @generated
    bool visible;

    /// @brief The weight attribute.
    // @generated
    double weight;

    /// @brief The tags attribute.
    // @generated
    EList(char *) tags;

    /// @brief The levels attribute.
    // @generated
    EList(int32_t) levels;

    /// @brief The colour attribute.
    // @generated
    Colour colour;

    /// @brief The description attribute.
    // @generated
    char *description;

    /// @brief The canvas reference.
    // @generated
    Canvas *canvas;

    /// @brief The name attribute.
    // @generated
    char *name;

    /// @brief The radius attribute.
    // @generated
    double radius;

    /// @brief The filled attribute.
    // @generated
    bool filled;
};

/// @brief Creates a Circle object with all features at their defaults.
///
/// The caller owns the object and releases it with Circle_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Circle *Circle_create(void);

/// @brief Destroys a Circle object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Circle_destroy(Circle *self);

/// @brief Returns the value of the label attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Circle_get_label(const Circle *self);

/// @brief Sets the value of the label attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Circle_set_label(Circle *self, const char *value);

/// @brief Returns the value of the visible attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
bool Circle_get_visible(const Circle *self);

/// @brief Sets the value of the visible attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Circle_set_visible(Circle *self, bool value);

/// @brief Returns the value of the weight attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
double Circle_get_weight(const Circle *self);

/// @brief Sets the value of the weight attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Circle_set_weight(Circle *self, double value);

/// @brief Returns the number of values of the tags attribute.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Circle_count_tags(const Circle *self);

/// @brief Returns a value of the tags attribute.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
const char *Circle_item_tags(const Circle *self, size_t index);

/// @brief Appends a value to the tags attribute.
///
/// The object keeps a copy of the value.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Circle_add_tags(Circle *self, const char *value);

/// @brief Removes a value from the tags attribute.
///
/// The object releases the value that it owns.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Circle_remove_tags(Circle *self, size_t index);

/// @brief Removes all values from the tags attribute.
///
/// The object releases the values that it owns.
///
/// @param self The object to change.
// @generated
void Circle_clear_tags(Circle *self);

/// @brief Returns the number of values of the levels attribute.
///
/// @param self The object to read.
/// @return The number of values.
// @generated
size_t Circle_count_levels(const Circle *self);

/// @brief Returns a value of the levels attribute.
///
/// @param self The object to read.
/// @param index The position of the value, counted from zero.
/// @return The value; the zero value if there is none at the position.
// @generated
int32_t Circle_item_levels(const Circle *self, size_t index);

/// @brief Appends a value to the levels attribute.
///
/// The object does not take ownership of the value.
///
/// @param self The object to change.
/// @param value The value to append.
/// @return `false` if the memory could not be allocated or the list cannot grow; `true` otherwise.
// @generated
bool Circle_add_levels(Circle *self, int32_t value);

/// @brief Removes a value from the levels attribute.
///
/// The value that was removed stays alive.
///
/// @param self The object to change.
/// @param index The position of the value, counted from zero.
/// @return `false` if there is no value at the position; `true` otherwise.
// @generated
bool Circle_remove_levels(Circle *self, size_t index);

/// @brief Removes all values from the levels attribute.
///
/// The values that were removed stay alive.
///
/// @param self The object to change.
// @generated
void Circle_clear_levels(Circle *self);

/// @brief Returns the value of the colour attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
Colour Circle_get_colour(const Circle *self);

/// @brief Sets the value of the colour attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Circle_set_colour(Circle *self, Colour value);

/// @brief Returns the value of the description attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Circle_get_description(const Circle *self);

/// @brief Sets the value of the description attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Circle_set_description(Circle *self, const char *value);

/// @brief Returns the value of the canvas reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
Canvas *Circle_get_canvas(const Circle *self);

/// @brief Sets the value of the canvas reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Circle_set_canvas(Circle *self, Canvas *value);

/// @brief Returns the value of the name attribute.
///
/// @param self The object to read.
/// @return The value; it belongs to the object and stays valid until the feature changes or the object is destroyed.
// @generated
const char *Circle_get_name(const Circle *self);

/// @brief Sets the value of the name attribute.
///
/// The object keeps a copy of the value and releases the previous one.
///
/// @param self The object to change.
/// @param value The new value.
/// @return `false` if the memory could not be allocated, leaving the previous value; `true` otherwise.
// @generated
bool Circle_set_name(Circle *self, const char *value);

/// @brief Returns the value of the radius attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
double Circle_get_radius(const Circle *self);

/// @brief Sets the value of the radius attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Circle_set_radius(Circle *self, double value);

/// @brief Returns the value of the filled attribute.
///
/// @param self The object to read.
/// @return The value.
// @generated
bool Circle_get_filled(const Circle *self);

/// @brief Sets the value of the filled attribute.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Circle_set_filled(Circle *self, bool value);

/// @brief The description of the classes package and its classes.
// @generated
extern const EPackageInfo ClassesPackage;

/// @brief Creates an object for a class of the classes package.
///
/// @param eClass The description of the class to create an object of.
/// @return The new object, which the caller releases with EObject_destroy; the null pointer if the class does not
///         belong to the package, has no instances, or the memory could not be allocated.
// @generated
EObject *ClassesFactory_create(const EClassInfo *eClass);

#ifdef __cplusplus
}
#endif

#endif
