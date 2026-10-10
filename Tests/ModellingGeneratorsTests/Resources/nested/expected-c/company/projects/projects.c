//
//  projects.c
//

#include "company/projects/projects.h"
#include <stdlib.h>
#include <string.h>

// @generated
const char *Status_literal(Status value) {
    switch (value) {
    case Status_Proposed:
        return "Proposed";
    case Status_Active:
        return "Active";
    case Status_Finished:
        return "Finished";
    default:
        return NULL;
    }
}

// @generated
bool Status_from_literal(const char *literal, Status *value) {
    if (literal == NULL || value == NULL) {
        return false;
    }
    if (strcmp(literal, "Proposed") == 0) {
        *value = Status_Proposed;
        return true;
    }
    if (strcmp(literal, "Active") == 0) {
        *value = Status_Active;
        return true;
    }
    if (strcmp(literal, "Finished") == 0) {
        *value = Status_Finished;
        return true;
    }
    return false;
}

// @generated
Project *Project_create(void) {
    Project *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Project_class;
    self->title = NULL;
    self->status = Status_Proposed;
    self->members.items = NULL;
    self->members.count = 0;
    self->members.capacity = 0;
    return self;
}

// @generated
void Project_destroy(Project *self) {
    if (self == NULL) {
        return;
    }
    free(self->title);
    Project_clear_members(self);
    free(self);
}

// @generated
const char *Project_get_title(const Project *self) {
    return self->title;
}

// @generated
bool Project_set_title(Project *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->title);
    self->title = copy;
    return true;
}

// @generated
Status Project_get_status(const Project *self) {
    return self->status;
}

// @generated
void Project_set_status(Project *self, Status value) {
    self->status = value;
}

// @generated
size_t Project_count_members(const Project *self) {
    return self->members.count;
}

// @generated
Employee *Project_item_members(const Project *self, size_t index) {
    if (index >= self->members.count) {
        return NULL;
    }
    return self->members.items[index];
}

// @generated
bool Project_add_members(Project *self, Employee *value) {
    if (self->members.count == self->members.capacity) {
        void *items = EObject_grown(self->members.items, &self->members.capacity, sizeof *self->members.items);
        if (items == NULL) {
            return false;
        }
        self->members.items = items;
    }
    self->members.items[self->members.count++] = value;
    return true;
}

// @generated
bool Project_remove_members(Project *self, size_t index) {
    if (index >= self->members.count) {
        return false;
    }
    memmove(&self->members.items[index], &self->members.items[index + 1], (self->members.count - index - 1) * sizeof *self->members.items);
    self->members.count--;
    return true;
}

// @generated
void Project_clear_members(Project *self) {
    free(self->members.items);
    self->members.items = NULL;
    self->members.count = 0;
    self->members.capacity = 0;
}

/// @brief Creates an object of the Project class for its description.
// @generated
static EObject *Project_create_object(void) {
    Project *object = Project_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Project class for its description.
// @generated
static void Project_destroy_object(EObject *object) {
    Project_destroy((Project *)object);
}

/// @brief The features of the Project class.
// @generated
static const EFeatureInfo Project_features[] = {
    { .name = "title", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "status", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "Status" },
    { .name = "members", .kind = EFeatureKind_Reference, .isMany = true, .typeName = "Employee" },
};

/// @brief The description of the Project class.
// @generated
const EClassInfo Project_class = {
    .name = "Project",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Project_features,
    .featureCount = 3,
    .create = Project_create_object,
    .destroy = Project_destroy_object
};

/// @brief The descriptions of the classes of the projects package.
// @generated
static const EClassInfo *const ProjPackage_classes[] = {
    &Project_class,
};

/// @brief The description of the projects package and its classes.
// @generated
const EPackageInfo ProjPackage = {
    .name = "projects",
    .nsURI = "http://swift-modelling.org/test/company/projects",
    .nsPrefix = "projects",
    .classes = ProjPackage_classes,
    .classCount = 1
};

// @generated
EObject *ProjFactory_create(const EClassInfo *eClass) {
    for (size_t position = 0; position < ProjPackage.classCount; position++) {
        if (ProjPackage.classes[position] == eClass) {
            return eClass->create == NULL ? NULL : eClass->create();
        }
    }
    return NULL;
}
