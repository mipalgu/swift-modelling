//
//  organisation.c
//

#include "organisation/organisation.h"
#include <stdlib.h>
#include <string.h>

// @generated
Person *Person_create(void) {
    Person *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Person_class;
    self->name = NULL;
    self->age = 0;
    return self;
}

// @generated
void Person_destroy(Person *self) {
    if (self == NULL) {
        return;
    }
    free(self->name);
    free(self);
}

// @generated
const char *Person_get_name(const Person *self) {
    return self->name;
}

// @generated
bool Person_set_name(Person *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->name);
    self->name = copy;
    return true;
}

// @generated
int32_t Person_get_age(const Person *self) {
    return self->age;
}

// @generated
void Person_set_age(Person *self, int32_t value) {
    self->age = value;
}

/// @brief Creates an object of the Person class for its description.
// @generated
static EObject *Person_create_object(void) {
    Person *object = Person_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Person class for its description.
// @generated
static void Person_destroy_object(EObject *object) {
    Person_destroy((Person *)object);
}

// @generated
Team *Team_create(void) {
    Team *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Team_class;
    self->name = NULL;
    self->members.items = NULL;
    self->members.count = 0;
    self->members.capacity = 0;
    self->leader = NULL;
    return self;
}

// @generated
void Team_destroy(Team *self) {
    if (self == NULL) {
        return;
    }
    free(self->name);
    Team_clear_members(self);
    free(self);
}

// @generated
const char *Team_get_name(const Team *self) {
    return self->name;
}

// @generated
bool Team_set_name(Team *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->name);
    self->name = copy;
    return true;
}

// @generated
size_t Team_count_members(const Team *self) {
    return self->members.count;
}

// @generated
Person *Team_item_members(const Team *self, size_t index) {
    if (index >= self->members.count) {
        return NULL;
    }
    return self->members.items[index];
}

// @generated
bool Team_add_members(Team *self, Person *value) {
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
bool Team_remove_members(Team *self, size_t index) {
    if (index >= self->members.count) {
        return false;
    }
    EObject_destroy((EObject *)self->members.items[index]);
    memmove(&self->members.items[index], &self->members.items[index + 1], (self->members.count - index - 1) * sizeof *self->members.items);
    self->members.count--;
    return true;
}

// @generated
void Team_clear_members(Team *self) {
    for (size_t position = 0; position < self->members.count; position++) {
        EObject_destroy((EObject *)self->members.items[position]);
    }
    free(self->members.items);
    self->members.items = NULL;
    self->members.count = 0;
    self->members.capacity = 0;
}

// @generated
Person *Team_get_leader(const Team *self) {
    return self->leader;
}

// @generated
void Team_set_leader(Team *self, Person *value) {
    self->leader = value;
}

/// @brief Creates an object of the Team class for its description.
// @generated
static EObject *Team_create_object(void) {
    Team *object = Team_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Team class for its description.
// @generated
static void Team_destroy_object(EObject *object) {
    Team_destroy((Team *)object);
}

// @generated
Organisation *Organisation_create(void) {
    Organisation *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Organisation_class;
    self->name = NULL;
    self->teams.items = NULL;
    self->teams.count = 0;
    self->teams.capacity = 0;
    return self;
}

// @generated
void Organisation_destroy(Organisation *self) {
    if (self == NULL) {
        return;
    }
    free(self->name);
    Organisation_clear_teams(self);
    free(self);
}

// @generated
const char *Organisation_get_name(const Organisation *self) {
    return self->name;
}

// @generated
bool Organisation_set_name(Organisation *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->name);
    self->name = copy;
    return true;
}

// @generated
size_t Organisation_count_teams(const Organisation *self) {
    return self->teams.count;
}

// @generated
Team *Organisation_item_teams(const Organisation *self, size_t index) {
    if (index >= self->teams.count) {
        return NULL;
    }
    return self->teams.items[index];
}

// @generated
bool Organisation_add_teams(Organisation *self, Team *value) {
    if (self->teams.count == self->teams.capacity) {
        void *items = EObject_grown(self->teams.items, &self->teams.capacity, sizeof *self->teams.items);
        if (items == NULL) {
            return false;
        }
        self->teams.items = items;
    }
    self->teams.items[self->teams.count++] = value;
    return true;
}

// @generated
bool Organisation_remove_teams(Organisation *self, size_t index) {
    if (index >= self->teams.count) {
        return false;
    }
    EObject_destroy((EObject *)self->teams.items[index]);
    memmove(&self->teams.items[index], &self->teams.items[index + 1], (self->teams.count - index - 1) * sizeof *self->teams.items);
    self->teams.count--;
    return true;
}

// @generated
void Organisation_clear_teams(Organisation *self) {
    for (size_t position = 0; position < self->teams.count; position++) {
        EObject_destroy((EObject *)self->teams.items[position]);
    }
    free(self->teams.items);
    self->teams.items = NULL;
    self->teams.count = 0;
    self->teams.capacity = 0;
}

/// @brief Creates an object of the Organisation class for its description.
// @generated
static EObject *Organisation_create_object(void) {
    Organisation *object = Organisation_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Organisation class for its description.
// @generated
static void Organisation_destroy_object(EObject *object) {
    Organisation_destroy((Organisation *)object);
}

/// @brief The features of the Person class.
// @generated
static const EFeatureInfo Person_features[] = {
    { .name = "name", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "age", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EInt" },
};

/// @brief The description of the Person class.
// @generated
const EClassInfo Person_class = {
    .name = "Person",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Person_features,
    .featureCount = 2,
    .create = Person_create_object,
    .destroy = Person_destroy_object
};

/// @brief The features of the Team class.
// @generated
static const EFeatureInfo Team_features[] = {
    { .name = "name", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "members", .kind = EFeatureKind_Containment, .isMany = true, .typeName = "Person" },
    { .name = "leader", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Person" },
};

/// @brief The description of the Team class.
// @generated
const EClassInfo Team_class = {
    .name = "Team",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Team_features,
    .featureCount = 3,
    .create = Team_create_object,
    .destroy = Team_destroy_object
};

/// @brief The features of the Organisation class.
// @generated
static const EFeatureInfo Organisation_features[] = {
    { .name = "name", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "teams", .kind = EFeatureKind_Containment, .isMany = true, .typeName = "Team" },
};

/// @brief The description of the Organisation class.
// @generated
const EClassInfo Organisation_class = {
    .name = "Organisation",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Organisation_features,
    .featureCount = 2,
    .create = Organisation_create_object,
    .destroy = Organisation_destroy_object
};

/// @brief The descriptions of the classes of the organisation package.
// @generated
static const EClassInfo *const OrgPackage_classes[] = {
    &Person_class,
    &Team_class,
    &Organisation_class,
};

/// @brief The description of the organisation package and its classes.
// @generated
const EPackageInfo OrgPackage = {
    .name = "organisation",
    .nsURI = "http://swift-modelling.org/test/organisation",
    .nsPrefix = "org",
    .classes = OrgPackage_classes,
    .classCount = 3
};

// @generated
EObject *OrgFactory_create(const EClassInfo *eClass) {
    for (size_t position = 0; position < OrgPackage.classCount; position++) {
        if (OrgPackage.classes[position] == eClass) {
            return eClass->create == NULL ? NULL : eClass->create();
        }
    }
    return NULL;
}
