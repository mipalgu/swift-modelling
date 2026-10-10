//
//  datatypes.c
//

#include "datatypes/datatypes.h"
#include <stdlib.h>
#include <string.h>

// @generated
const char *Colour_literal(Colour value) {
    switch (value) {
    case Colour_Red:
        return "Red";
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
    return false;
}

// @generated
Thing *Thing_create(void) {
    Thing *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Thing_class;
    return self;
}

// @generated
void Thing_destroy(Thing *self) {
    if (self == NULL) {
        return;
    }
    free(self);
}

/// @brief Creates an object of the Thing class for its description.
// @generated
static EObject *Thing_create_object(void) {
    Thing *object = Thing_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Thing class for its description.
// @generated
static void Thing_destroy_object(EObject *object) {
    Thing_destroy((Thing *)object);
}

// @generated
Class *Class_create(void) {
    Class *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Class_class;
    return self;
}

// @generated
void Class_destroy(Class *self) {
    if (self == NULL) {
        return;
    }
    free(self);
}

/// @brief Creates an object of the Class class for its description.
// @generated
static EObject *Class_create_object(void) {
    Class *object = Class_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Class class for its description.
// @generated
static void Class_destroy_object(EObject *object) {
    Class_destroy((Class *)object);
}

// @generated
Gizmo *Gizmo_create(void) {
    Gizmo *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Gizmo_class;
    return self;
}

// @generated
void Gizmo_destroy(Gizmo *self) {
    if (self == NULL) {
        return;
    }
    free(self);
}

/// @brief Creates an object of the Gizmo class for its description.
// @generated
static EObject *Gizmo_create_object(void) {
    Gizmo *object = Gizmo_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Gizmo class for its description.
// @generated
static void Gizmo_destroy_object(EObject *object) {
    Gizmo_destroy((Gizmo *)object);
}

/// @brief The description of the Thing class.
// @generated
const EClassInfo Thing_class = {
    .name = "Thing",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = NULL,
    .featureCount = 0,
    .create = Thing_create_object,
    .destroy = Thing_destroy_object
};

/// @brief The description of the Class class.
// @generated
const EClassInfo Class_class = {
    .name = "Class",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = NULL,
    .featureCount = 0,
    .create = Class_create_object,
    .destroy = Class_destroy_object
};

/// @brief The description of the Gizmo class.
// @generated
const EClassInfo Gizmo_class = {
    .name = "Gizmo",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = NULL,
    .featureCount = 0,
    .create = Gizmo_create_object,
    .destroy = Gizmo_destroy_object
};

/// @brief The descriptions of the classes of the datatypes package.
// @generated
static const EClassInfo *const DatatypesPackage_classes[] = {
    &Thing_class,
    &Class_class,
    &Gizmo_class,
};

/// @brief The description of the datatypes package and its classes.
// @generated
const EPackageInfo DatatypesPackage = {
    .name = "datatypes",
    .nsURI = "http://swift-modelling.org/test/datatypes",
    .nsPrefix = "dt",
    .classes = DatatypesPackage_classes,
    .classCount = 3
};

// @generated
EObject *DatatypesFactory_create(const EClassInfo *eClass) {
    for (size_t position = 0; position < DatatypesPackage.classCount; position++) {
        if (DatatypesPackage.classes[position] == eClass) {
            return eClass->create == NULL ? NULL : eClass->create();
        }
    }
    return NULL;
}
