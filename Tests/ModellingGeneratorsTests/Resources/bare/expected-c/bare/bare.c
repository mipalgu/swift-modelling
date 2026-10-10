//
//  bare.c
//

#include "bare/bare.h"
#include <stdlib.h>
#include <string.h>

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

/// @brief The descriptions of the classes of the bare package.
// @generated
static const EClassInfo *const BarePackage_classes[] = {
    &Thing_class,
};

/// @brief The description of the bare package and its classes.
// @generated
const EPackageInfo BarePackage = {
    .name = "bare",
    .nsURI = "http://swift-modelling.org/test/bare",
    .nsPrefix = "bare",
    .classes = BarePackage_classes,
    .classCount = 1
};

// @generated
EObject *BareFactory_create(const EClassInfo *eClass) {
    for (size_t position = 0; position < BarePackage.classCount; position++) {
        if (BarePackage.classes[position] == eClass) {
            return eClass->create == NULL ? NULL : eClass->create();
        }
    }
    return NULL;
}
