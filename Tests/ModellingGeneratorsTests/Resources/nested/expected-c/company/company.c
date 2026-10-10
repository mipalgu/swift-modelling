//
//  company.c
//

#include "company/company.h"
#include <stdlib.h>
#include <string.h>

// @generated
Company *Company_create(void) {
    Company *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Company_class;
    self->name = NULL;
    self->staff.items = NULL;
    self->staff.count = 0;
    self->staff.capacity = 0;
    self->projects.items = NULL;
    self->projects.count = 0;
    self->projects.capacity = 0;
    return self;
}

// @generated
void Company_destroy(Company *self) {
    if (self == NULL) {
        return;
    }
    free(self->name);
    Company_clear_staff(self);
    Company_clear_projects(self);
    free(self);
}

// @generated
const char *Company_get_name(const Company *self) {
    return self->name;
}

// @generated
bool Company_set_name(Company *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->name);
    self->name = copy;
    return true;
}

// @generated
size_t Company_count_staff(const Company *self) {
    return self->staff.count;
}

// @generated
Employee *Company_item_staff(const Company *self, size_t index) {
    if (index >= self->staff.count) {
        return NULL;
    }
    return self->staff.items[index];
}

// @generated
bool Company_add_staff(Company *self, Employee *value) {
    if (self->staff.count == self->staff.capacity) {
        void *items = EObject_grown(self->staff.items, &self->staff.capacity, sizeof *self->staff.items);
        if (items == NULL) {
            return false;
        }
        self->staff.items = items;
    }
    self->staff.items[self->staff.count++] = value;
    return true;
}

// @generated
bool Company_remove_staff(Company *self, size_t index) {
    if (index >= self->staff.count) {
        return false;
    }
    EObject_destroy((EObject *)self->staff.items[index]);
    memmove(&self->staff.items[index], &self->staff.items[index + 1], (self->staff.count - index - 1) * sizeof *self->staff.items);
    self->staff.count--;
    return true;
}

// @generated
void Company_clear_staff(Company *self) {
    for (size_t position = 0; position < self->staff.count; position++) {
        EObject_destroy((EObject *)self->staff.items[position]);
    }
    free(self->staff.items);
    self->staff.items = NULL;
    self->staff.count = 0;
    self->staff.capacity = 0;
}

// @generated
size_t Company_count_projects(const Company *self) {
    return self->projects.count;
}

// @generated
Project *Company_item_projects(const Company *self, size_t index) {
    if (index >= self->projects.count) {
        return NULL;
    }
    return self->projects.items[index];
}

// @generated
bool Company_add_projects(Company *self, Project *value) {
    if (self->projects.count == self->projects.capacity) {
        void *items = EObject_grown(self->projects.items, &self->projects.capacity, sizeof *self->projects.items);
        if (items == NULL) {
            return false;
        }
        self->projects.items = items;
    }
    self->projects.items[self->projects.count++] = value;
    return true;
}

// @generated
bool Company_remove_projects(Company *self, size_t index) {
    if (index >= self->projects.count) {
        return false;
    }
    EObject_destroy((EObject *)self->projects.items[index]);
    memmove(&self->projects.items[index], &self->projects.items[index + 1], (self->projects.count - index - 1) * sizeof *self->projects.items);
    self->projects.count--;
    return true;
}

// @generated
void Company_clear_projects(Company *self) {
    for (size_t position = 0; position < self->projects.count; position++) {
        EObject_destroy((EObject *)self->projects.items[position]);
    }
    free(self->projects.items);
    self->projects.items = NULL;
    self->projects.count = 0;
    self->projects.capacity = 0;
}

/// @brief Creates an object of the Company class for its description.
// @generated
static EObject *Company_create_object(void) {
    Company *object = Company_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Company class for its description.
// @generated
static void Company_destroy_object(EObject *object) {
    Company_destroy((Company *)object);
}

/// @brief The features of the Company class.
// @generated
static const EFeatureInfo Company_features[] = {
    { .name = "name", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "staff", .kind = EFeatureKind_Containment, .isMany = true, .typeName = "Employee" },
    { .name = "projects", .kind = EFeatureKind_Containment, .isMany = true, .typeName = "Project" },
};

/// @brief The description of the Company class.
// @generated
const EClassInfo Company_class = {
    .name = "Company",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Company_features,
    .featureCount = 3,
    .create = Company_create_object,
    .destroy = Company_destroy_object
};

/// @brief The descriptions of the classes of the company package.
// @generated
static const EClassInfo *const CompanyPackage_classes[] = {
    &Company_class,
};

/// @brief The description of the company package and its classes.
// @generated
const EPackageInfo CompanyPackage = {
    .name = "company",
    .nsURI = "http://swift-modelling.org/test/company",
    .nsPrefix = "company",
    .classes = CompanyPackage_classes,
    .classCount = 1
};

// @generated
EObject *CompanyFactory_create(const EClassInfo *eClass) {
    for (size_t position = 0; position < CompanyPackage.classCount; position++) {
        if (CompanyPackage.classes[position] == eClass) {
            return eClass->create == NULL ? NULL : eClass->create();
        }
    }
    return NULL;
}
