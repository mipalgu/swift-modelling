//
//  archive.c
//

#include "company/projects/archive/archive.h"
#include <stdlib.h>
#include <string.h>

// @generated
Record *Record_create(void) {
    Record *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Record_class;
    self->project = NULL;
    return self;
}

// @generated
void Record_destroy(Record *self) {
    if (self == NULL) {
        return;
    }
    free(self);
}

// @generated
Project *Record_get_project(const Record *self) {
    return self->project;
}

// @generated
void Record_set_project(Record *self, Project *value) {
    self->project = value;
}

/// @brief Creates an object of the Record class for its description.
// @generated
static EObject *Record_create_object(void) {
    Record *object = Record_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Record class for its description.
// @generated
static void Record_destroy_object(EObject *object) {
    Record_destroy((Record *)object);
}

/// @brief The features of the Record class.
// @generated
static const EFeatureInfo Record_features[] = {
    { .name = "project", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Project" },
};

/// @brief The description of the Record class.
// @generated
const EClassInfo Record_class = {
    .name = "Record",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Record_features,
    .featureCount = 1,
    .create = Record_create_object,
    .destroy = Record_destroy_object
};

/// @brief The descriptions of the classes of the archive package.
// @generated
static const EClassInfo *const ArchivePackage_classes[] = {
    &Record_class,
};

/// @brief The description of the archive package and its classes.
// @generated
const EPackageInfo ArchivePackage = {
    .name = "archive",
    .nsURI = "http://swift-modelling.org/test/company/projects/archive",
    .nsPrefix = "archive",
    .classes = ArchivePackage_classes,
    .classCount = 1
};

// @generated
EObject *ArchiveFactory_create(const EClassInfo *eClass) {
    for (size_t position = 0; position < ArchivePackage.classCount; position++) {
        if (ArchivePackage.classes[position] == eClass) {
            return eClass->create == NULL ? NULL : eClass->create();
        }
    }
    return NULL;
}
