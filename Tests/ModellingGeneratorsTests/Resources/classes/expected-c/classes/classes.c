//
//  classes.c
//

#include "classes/classes.h"
#include <stdlib.h>
#include <string.h>

// @generated
const char *Colour_literal(Colour value) {
    switch (value) {
    case Colour_Red:
        return "Red";
    case Colour_Green:
        return "Green";
    case Colour_Blue:
        return "Blue";
    default:
        return NULL;
    }
}

// @generated
bool Colour_from_literal(const char *literal, Colour *value) {
    if (literal == NULL || value == NULL) {
        return false;
    }
    if (strcmp(literal, "Red") == 0) {
        *value = Colour_Red;
        return true;
    }
    if (strcmp(literal, "Green") == 0) {
        *value = Colour_Green;
        return true;
    }
    if (strcmp(literal, "Blue") == 0) {
        *value = Colour_Blue;
        return true;
    }
    return false;
}

// @generated
Canvas *Canvas_create(void) {
    Canvas *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Canvas_class;
    self->shapes.items = NULL;
    self->shapes.count = 0;
    self->shapes.capacity = 0;
    self->background = NULL;
    self->favourites.items = NULL;
    self->favourites.count = 0;
    self->favourites.capacity = 0;
    self->selected = NULL;
    self->primary = NULL;
    return self;
}

// @generated
void Canvas_destroy(Canvas *self) {
    if (self == NULL) {
        return;
    }
    Canvas_clear_shapes(self);
    EObject_destroy((EObject *)self->background);
    Canvas_clear_favourites(self);
    free(self);
}

// @generated
size_t Canvas_count_shapes(const Canvas *self) {
    return self->shapes.count;
}

// @generated
EObject *Canvas_item_shapes(const Canvas *self, size_t index) {
    if (index >= self->shapes.count) {
        return NULL;
    }
    return self->shapes.items[index];
}

// @generated
bool Canvas_add_shapes(Canvas *self, EObject *value) {
    if (self->shapes.count == self->shapes.capacity) {
        void *items = EObject_grown(self->shapes.items, &self->shapes.capacity, sizeof *self->shapes.items);
        if (items == NULL) {
            return false;
        }
        self->shapes.items = items;
    }
    self->shapes.items[self->shapes.count++] = value;
    return true;
}

// @generated
bool Canvas_remove_shapes(Canvas *self, size_t index) {
    if (index >= self->shapes.count) {
        return false;
    }
    EObject_destroy((EObject *)self->shapes.items[index]);
    memmove(&self->shapes.items[index], &self->shapes.items[index + 1], (self->shapes.count - index - 1) * sizeof *self->shapes.items);
    self->shapes.count--;
    return true;
}

// @generated
void Canvas_clear_shapes(Canvas *self) {
    for (size_t position = 0; position < self->shapes.count; position++) {
        EObject_destroy((EObject *)self->shapes.items[position]);
    }
    free(self->shapes.items);
    self->shapes.items = NULL;
    self->shapes.count = 0;
    self->shapes.capacity = 0;
}

// @generated
EObject *Canvas_get_background(const Canvas *self) {
    return self->background;
}

// @generated
void Canvas_set_background(Canvas *self, EObject *value) {
    if (self->background != value) {
        EObject_destroy((EObject *)self->background);
        self->background = value;
    }
}

// @generated
size_t Canvas_count_favourites(const Canvas *self) {
    return self->favourites.count;
}

// @generated
EObject *Canvas_item_favourites(const Canvas *self, size_t index) {
    if (index >= self->favourites.count) {
        return NULL;
    }
    return self->favourites.items[index];
}

// @generated
bool Canvas_add_favourites(Canvas *self, EObject *value) {
    if (self->favourites.count == self->favourites.capacity) {
        void *items = EObject_grown(self->favourites.items, &self->favourites.capacity, sizeof *self->favourites.items);
        if (items == NULL) {
            return false;
        }
        self->favourites.items = items;
    }
    self->favourites.items[self->favourites.count++] = value;
    return true;
}

// @generated
bool Canvas_remove_favourites(Canvas *self, size_t index) {
    if (index >= self->favourites.count) {
        return false;
    }
    memmove(&self->favourites.items[index], &self->favourites.items[index + 1], (self->favourites.count - index - 1) * sizeof *self->favourites.items);
    self->favourites.count--;
    return true;
}

// @generated
void Canvas_clear_favourites(Canvas *self) {
    free(self->favourites.items);
    self->favourites.items = NULL;
    self->favourites.count = 0;
    self->favourites.capacity = 0;
}

// @generated
EObject *Canvas_get_selected(const Canvas *self) {
    return self->selected;
}

// @generated
void Canvas_set_selected(Canvas *self, EObject *value) {
    self->selected = value;
}

// @generated
EObject *Canvas_get_primary(const Canvas *self) {
    return self->primary;
}

// @generated
void Canvas_set_primary(Canvas *self, EObject *value) {
    self->primary = value;
}

/// @brief Creates an object of the Canvas class for its description.
// @generated
static EObject *Canvas_create_object(void) {
    Canvas *object = Canvas_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Canvas class for its description.
// @generated
static void Canvas_destroy_object(EObject *object) {
    Canvas_destroy((Canvas *)object);
}

// @generated
Circle *Circle_create(void) {
    Circle *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Circle_class;
    self->label = NULL;
    self->visible = true;
    self->weight = 1.5;
    self->tags.items = NULL;
    self->tags.count = 0;
    self->tags.capacity = 0;
    self->levels.items = NULL;
    self->levels.count = 0;
    self->levels.capacity = 0;
    self->colour = Colour_Green;
    self->description = NULL;
    self->canvas = NULL;
    self->name = NULL;
    self->radius = 0.0;
    self->filled = false;
    return self;
}

// @generated
void Circle_destroy(Circle *self) {
    if (self == NULL) {
        return;
    }
    free(self->label);
    Circle_clear_tags(self);
    Circle_clear_levels(self);
    free(self->description);
    free(self->name);
    free(self);
}

// @generated
const char *Circle_get_label(const Circle *self) {
    return self->label;
}

// @generated
bool Circle_set_label(Circle *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->label);
    self->label = copy;
    return true;
}

// @generated
bool Circle_get_visible(const Circle *self) {
    return self->visible;
}

// @generated
void Circle_set_visible(Circle *self, bool value) {
    self->visible = value;
}

// @generated
double Circle_get_weight(const Circle *self) {
    return self->weight;
}

// @generated
void Circle_set_weight(Circle *self, double value) {
    self->weight = value;
}

// @generated
size_t Circle_count_tags(const Circle *self) {
    return self->tags.count;
}

// @generated
const char *Circle_item_tags(const Circle *self, size_t index) {
    if (index >= self->tags.count) {
        return NULL;
    }
    return self->tags.items[index];
}

// @generated
bool Circle_add_tags(Circle *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    if (self->tags.count == self->tags.capacity) {
        void *items = EObject_grown(self->tags.items, &self->tags.capacity, sizeof *self->tags.items);
        if (items == NULL) {
            free(copy);
            return false;
        }
        self->tags.items = items;
    }
    self->tags.items[self->tags.count++] = copy;
    return true;
}

// @generated
bool Circle_remove_tags(Circle *self, size_t index) {
    if (index >= self->tags.count) {
        return false;
    }
    free(self->tags.items[index]);
    memmove(&self->tags.items[index], &self->tags.items[index + 1], (self->tags.count - index - 1) * sizeof *self->tags.items);
    self->tags.count--;
    return true;
}

// @generated
void Circle_clear_tags(Circle *self) {
    for (size_t position = 0; position < self->tags.count; position++) {
        free(self->tags.items[position]);
    }
    free(self->tags.items);
    self->tags.items = NULL;
    self->tags.count = 0;
    self->tags.capacity = 0;
}

// @generated
size_t Circle_count_levels(const Circle *self) {
    return self->levels.count;
}

// @generated
int32_t Circle_item_levels(const Circle *self, size_t index) {
    if (index >= self->levels.count) {
        return 0;
    }
    return self->levels.items[index];
}

// @generated
bool Circle_add_levels(Circle *self, int32_t value) {
    if (self->levels.count == self->levels.capacity) {
        void *items = EObject_grown(self->levels.items, &self->levels.capacity, sizeof *self->levels.items);
        if (items == NULL) {
            return false;
        }
        self->levels.items = items;
    }
    self->levels.items[self->levels.count++] = value;
    return true;
}

// @generated
bool Circle_remove_levels(Circle *self, size_t index) {
    if (index >= self->levels.count) {
        return false;
    }
    memmove(&self->levels.items[index], &self->levels.items[index + 1], (self->levels.count - index - 1) * sizeof *self->levels.items);
    self->levels.count--;
    return true;
}

// @generated
void Circle_clear_levels(Circle *self) {
    free(self->levels.items);
    self->levels.items = NULL;
    self->levels.count = 0;
    self->levels.capacity = 0;
}

// @generated
Colour Circle_get_colour(const Circle *self) {
    return self->colour;
}

// @generated
void Circle_set_colour(Circle *self, Colour value) {
    self->colour = value;
}

// @generated
const char *Circle_get_description(const Circle *self) {
    return self->description;
}

// @generated
bool Circle_set_description(Circle *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->description);
    self->description = copy;
    return true;
}

// @generated
Canvas *Circle_get_canvas(const Circle *self) {
    return self->canvas;
}

// @generated
void Circle_set_canvas(Circle *self, Canvas *value) {
    self->canvas = value;
}

// @generated
const char *Circle_get_name(const Circle *self) {
    return self->name;
}

// @generated
bool Circle_set_name(Circle *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->name);
    self->name = copy;
    return true;
}

// @generated
double Circle_get_radius(const Circle *self) {
    return self->radius;
}

// @generated
void Circle_set_radius(Circle *self, double value) {
    self->radius = value;
}

// @generated
bool Circle_get_filled(const Circle *self) {
    return self->filled;
}

// @generated
void Circle_set_filled(Circle *self, bool value) {
    self->filled = value;
}

/// @brief Creates an object of the Circle class for its description.
// @generated
static EObject *Circle_create_object(void) {
    Circle *object = Circle_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Circle class for its description.
// @generated
static void Circle_destroy_object(EObject *object) {
    Circle_destroy((Circle *)object);
}

/// @brief The features of the Shape class.
// @generated
static const EFeatureInfo Shape_features[] = {
    { .name = "label", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "visible", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EBoolean" },
    { .name = "weight", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EDouble" },
    { .name = "tags", .kind = EFeatureKind_Attribute, .isMany = true, .typeName = "EString" },
    { .name = "levels", .kind = EFeatureKind_Attribute, .isMany = true, .typeName = "EInt" },
    { .name = "colour", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "Colour" },
    { .name = "description", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "canvas", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Canvas" },
};

/// @brief The description of the Shape class.
// @generated
const EClassInfo Shape_class = {
    .name = "Shape",
    .isAbstract = true,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Shape_features,
    .featureCount = 8,
    .create = NULL,
    .destroy = NULL
};

/// @brief The features of the Canvas class.
// @generated
static const EFeatureInfo Canvas_features[] = {
    { .name = "shapes", .kind = EFeatureKind_Containment, .isMany = true, .typeName = "Shape" },
    { .name = "background", .kind = EFeatureKind_Containment, .isMany = false, .typeName = "Shape" },
    { .name = "favourites", .kind = EFeatureKind_Reference, .isMany = true, .typeName = "Shape" },
    { .name = "selected", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Shape" },
    { .name = "primary", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Shape" },
};

/// @brief The description of the Canvas class.
// @generated
const EClassInfo Canvas_class = {
    .name = "Canvas",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Canvas_features,
    .featureCount = 5,
    .create = Canvas_create_object,
    .destroy = Canvas_destroy_object
};

/// @brief The features of the Named class.
// @generated
static const EFeatureInfo Named_features[] = {
    { .name = "name", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
};

/// @brief The description of the Named class.
// @generated
const EClassInfo Named_class = {
    .name = "Named",
    .isAbstract = true,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Named_features,
    .featureCount = 1,
    .create = NULL,
    .destroy = NULL
};

/// @brief The features of the Circle class.
// @generated
static const EFeatureInfo Circle_features[] = {
    { .name = "label", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "visible", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EBoolean" },
    { .name = "weight", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EDouble" },
    { .name = "tags", .kind = EFeatureKind_Attribute, .isMany = true, .typeName = "EString" },
    { .name = "levels", .kind = EFeatureKind_Attribute, .isMany = true, .typeName = "EInt" },
    { .name = "colour", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "Colour" },
    { .name = "description", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "canvas", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Canvas" },
    { .name = "name", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "radius", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EDouble" },
    { .name = "filled", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EBoolean" },
};

/// @brief The supertypes of the Circle class.
// @generated
static const EClassInfo *const Circle_superTypes[] = { &Shape_class, &Named_class };

/// @brief The description of the Circle class.
// @generated
const EClassInfo Circle_class = {
    .name = "Circle",
    .isAbstract = false,
    .superTypes = Circle_superTypes,
    .superTypeCount = 2,
    .features = Circle_features,
    .featureCount = 11,
    .create = Circle_create_object,
    .destroy = Circle_destroy_object
};

/// @brief The descriptions of the classes of the classes package.
// @generated
static const EClassInfo *const ClassesPackage_classes[] = {
    &Shape_class,
    &Canvas_class,
    &Named_class,
    &Circle_class,
};

/// @brief The description of the classes package and its classes.
// @generated
const EPackageInfo ClassesPackage = {
    .name = "classes",
    .nsURI = "http://swift-modelling.org/test/classes",
    .nsPrefix = "cls",
    .classes = ClassesPackage_classes,
    .classCount = 4
};

// @generated
EObject *ClassesFactory_create(const EClassInfo *eClass) {
    for (size_t position = 0; position < ClassesPackage.classCount; position++) {
        if (ClassesPackage.classes[position] == eClass) {
            return eClass->create == NULL ? NULL : eClass->create();
        }
    }
    return NULL;
}
