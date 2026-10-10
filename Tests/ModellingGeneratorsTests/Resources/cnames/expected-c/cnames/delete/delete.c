//
//  delete.c
//

#include "cnames/delete/delete.h"
#include <stdlib.h>
#include <string.h>

// @generated
Wheel *Wheel_create(void) {
    Wheel *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Wheel_class;
    self->auto_ = NULL;
    self->virtual_ = NULL;
    return self;
}

// @generated
void Wheel_destroy(Wheel *self) {
    if (self == NULL) {
        return;
    }
    free(self->auto_);
    free(self);
}

// @generated
const char *Wheel_get_auto(const Wheel *self) {
    return self->auto_;
}

// @generated
bool Wheel_set_auto(Wheel *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->auto_);
    self->auto_ = copy;
    return true;
}

// @generated
EObject *Wheel_get_virtual(const Wheel *self) {
    return self->virtual_;
}

// @generated
void Wheel_set_virtual(Wheel *self, EObject *value) {
    self->virtual_ = value;
}

/// @brief Creates an object of the Wheel class for its description.
// @generated
static EObject *Wheel_create_object(void) {
    Wheel *object = Wheel_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Wheel class for its description.
// @generated
static void Wheel_destroy_object(EObject *object) {
    Wheel_destroy((Wheel *)object);
}

/// @brief The features of the Wheel class.
// @generated
static const EFeatureInfo Wheel_features[] = {
    { .name = "auto", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "virtual", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Vehicle" },
};

/// @brief The description of the Wheel class.
// @generated
const EClassInfo Wheel_class = {
    .name = "Wheel",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Wheel_features,
    .featureCount = 2,
    .create = Wheel_create_object,
    .destroy = Wheel_destroy_object
};

/// @brief The descriptions of the classes of the delete package.
// @generated
static const EClassInfo *const DeletePackage_classes[] = {
    &Wheel_class,
};

/// @brief The description of the delete package and its classes.
// @generated
const EPackageInfo DeletePackage = {
    .name = "delete",
    .nsURI = "http://swift-modelling.org/test/cnames/delete",
    .nsPrefix = "del",
    .classes = DeletePackage_classes,
    .classCount = 1
};

// @generated
EObject *DeleteFactory_create(const EClassInfo *eClass) {
    for (size_t position = 0; position < DeletePackage.classCount; position++) {
        if (DeletePackage.classes[position] == eClass) {
            return eClass->create == NULL ? NULL : eClass->create();
        }
    }
    return NULL;
}
