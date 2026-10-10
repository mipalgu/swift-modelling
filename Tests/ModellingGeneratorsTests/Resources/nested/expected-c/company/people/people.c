//
//  people.c
//

#include "company/people/people.h"
#include <stdlib.h>
#include <string.h>

// @generated
Employee *Employee_create(void) {
    Employee *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Employee_class;
    self->name = NULL;
    self->salary = 0.0;
    return self;
}

// @generated
void Employee_destroy(Employee *self) {
    if (self == NULL) {
        return;
    }
    free(self->name);
    free(self);
}

// @generated
const char *Employee_get_name(const Employee *self) {
    return self->name;
}

// @generated
bool Employee_set_name(Employee *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->name);
    self->name = copy;
    return true;
}

// @generated
double Employee_get_salary(const Employee *self) {
    return self->salary;
}

// @generated
void Employee_set_salary(Employee *self, double value) {
    self->salary = value;
}

/// @brief Creates an object of the Employee class for its description.
// @generated
static EObject *Employee_create_object(void) {
    Employee *object = Employee_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Employee class for its description.
// @generated
static void Employee_destroy_object(EObject *object) {
    Employee_destroy((Employee *)object);
}

/// @brief The features of the Person class.
// @generated
static const EFeatureInfo Person_features[] = {
    { .name = "name", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
};

/// @brief The description of the Person class.
// @generated
const EClassInfo Person_class = {
    .name = "Person",
    .isAbstract = true,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Person_features,
    .featureCount = 1,
    .create = NULL,
    .destroy = NULL
};

/// @brief The features of the Employee class.
// @generated
static const EFeatureInfo Employee_features[] = {
    { .name = "name", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "salary", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EDouble" },
};

/// @brief The supertypes of the Employee class.
// @generated
static const EClassInfo *const Employee_superTypes[] = { &Person_class };

/// @brief The description of the Employee class.
// @generated
const EClassInfo Employee_class = {
    .name = "Employee",
    .isAbstract = false,
    .superTypes = Employee_superTypes,
    .superTypeCount = 1,
    .features = Employee_features,
    .featureCount = 2,
    .create = Employee_create_object,
    .destroy = Employee_destroy_object
};

/// @brief The descriptions of the classes of the people package.
// @generated
static const EClassInfo *const PeoplePackage_classes[] = {
    &Person_class,
    &Employee_class,
};

/// @brief The description of the people package and its classes.
// @generated
const EPackageInfo PeoplePackage = {
    .name = "people",
    .nsURI = "http://swift-modelling.org/test/company/people",
    .nsPrefix = "people",
    .classes = PeoplePackage_classes,
    .classCount = 2
};

// @generated
EObject *PeopleFactory_create(const EClassInfo *eClass) {
    for (size_t position = 0; position < PeoplePackage.classCount; position++) {
        if (PeoplePackage.classes[position] == eClass) {
            return eClass->create == NULL ? NULL : eClass->create();
        }
    }
    return NULL;
}
