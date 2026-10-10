//
//  Families.c
//

#include "Families/Families.h"
#include <stdlib.h>
#include <string.h>

// @generated
Family *Family_create(void) {
    Family *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Family_class;
    self->lastName = NULL;
    self->father = NULL;
    self->mother = NULL;
    self->sons.items = NULL;
    self->sons.count = 0;
    self->sons.capacity = 0;
    self->daughters.items = NULL;
    self->daughters.count = 0;
    self->daughters.capacity = 0;
    return self;
}

// @generated
void Family_destroy(Family *self) {
    if (self == NULL) {
        return;
    }
    free(self->lastName);
    EObject_destroy((EObject *)self->father);
    EObject_destroy((EObject *)self->mother);
    Family_clear_sons(self);
    Family_clear_daughters(self);
    free(self);
}

// @generated
const char *Family_get_lastName(const Family *self) {
    return self->lastName;
}

// @generated
bool Family_set_lastName(Family *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->lastName);
    self->lastName = copy;
    return true;
}

// @generated
Member *Family_get_father(const Family *self) {
    return self->father;
}

// @generated
void Family_set_father(Family *self, Member *value) {
    if (self->father != value) {
        EObject_destroy((EObject *)self->father);
        self->father = value;
    }
}

// @generated
Member *Family_get_mother(const Family *self) {
    return self->mother;
}

// @generated
void Family_set_mother(Family *self, Member *value) {
    if (self->mother != value) {
        EObject_destroy((EObject *)self->mother);
        self->mother = value;
    }
}

// @generated
size_t Family_count_sons(const Family *self) {
    return self->sons.count;
}

// @generated
Member *Family_item_sons(const Family *self, size_t index) {
    if (index >= self->sons.count) {
        return NULL;
    }
    return self->sons.items[index];
}

// @generated
bool Family_add_sons(Family *self, Member *value) {
    if (self->sons.count == self->sons.capacity) {
        void *items = EObject_grown(self->sons.items, &self->sons.capacity, sizeof *self->sons.items);
        if (items == NULL) {
            return false;
        }
        self->sons.items = items;
    }
    self->sons.items[self->sons.count++] = value;
    return true;
}

// @generated
bool Family_remove_sons(Family *self, size_t index) {
    if (index >= self->sons.count) {
        return false;
    }
    EObject_destroy((EObject *)self->sons.items[index]);
    memmove(&self->sons.items[index], &self->sons.items[index + 1], (self->sons.count - index - 1) * sizeof *self->sons.items);
    self->sons.count--;
    return true;
}

// @generated
void Family_clear_sons(Family *self) {
    for (size_t position = 0; position < self->sons.count; position++) {
        EObject_destroy((EObject *)self->sons.items[position]);
    }
    free(self->sons.items);
    self->sons.items = NULL;
    self->sons.count = 0;
    self->sons.capacity = 0;
}

// @generated
size_t Family_count_daughters(const Family *self) {
    return self->daughters.count;
}

// @generated
Member *Family_item_daughters(const Family *self, size_t index) {
    if (index >= self->daughters.count) {
        return NULL;
    }
    return self->daughters.items[index];
}

// @generated
bool Family_add_daughters(Family *self, Member *value) {
    if (self->daughters.count == self->daughters.capacity) {
        void *items = EObject_grown(self->daughters.items, &self->daughters.capacity, sizeof *self->daughters.items);
        if (items == NULL) {
            return false;
        }
        self->daughters.items = items;
    }
    self->daughters.items[self->daughters.count++] = value;
    return true;
}

// @generated
bool Family_remove_daughters(Family *self, size_t index) {
    if (index >= self->daughters.count) {
        return false;
    }
    EObject_destroy((EObject *)self->daughters.items[index]);
    memmove(&self->daughters.items[index], &self->daughters.items[index + 1], (self->daughters.count - index - 1) * sizeof *self->daughters.items);
    self->daughters.count--;
    return true;
}

// @generated
void Family_clear_daughters(Family *self) {
    for (size_t position = 0; position < self->daughters.count; position++) {
        EObject_destroy((EObject *)self->daughters.items[position]);
    }
    free(self->daughters.items);
    self->daughters.items = NULL;
    self->daughters.count = 0;
    self->daughters.capacity = 0;
}

/// @brief Creates an object of the Family class for its description.
// @generated
static EObject *Family_create_object(void) {
    Family *object = Family_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Family class for its description.
// @generated
static void Family_destroy_object(EObject *object) {
    Family_destroy((Family *)object);
}

// @generated
Member *Member_create(void) {
    Member *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Member_class;
    self->firstName = NULL;
    self->familyFather = NULL;
    self->familyMother = NULL;
    self->familySon = NULL;
    self->familyDaughter = NULL;
    return self;
}

// @generated
void Member_destroy(Member *self) {
    if (self == NULL) {
        return;
    }
    free(self->firstName);
    free(self);
}

// @generated
const char *Member_get_firstName(const Member *self) {
    return self->firstName;
}

// @generated
bool Member_set_firstName(Member *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->firstName);
    self->firstName = copy;
    return true;
}

// @generated
Family *Member_get_familyFather(const Member *self) {
    return self->familyFather;
}

// @generated
void Member_set_familyFather(Member *self, Family *value) {
    self->familyFather = value;
}

// @generated
Family *Member_get_familyMother(const Member *self) {
    return self->familyMother;
}

// @generated
void Member_set_familyMother(Member *self, Family *value) {
    self->familyMother = value;
}

// @generated
Family *Member_get_familySon(const Member *self) {
    return self->familySon;
}

// @generated
void Member_set_familySon(Member *self, Family *value) {
    self->familySon = value;
}

// @generated
Family *Member_get_familyDaughter(const Member *self) {
    return self->familyDaughter;
}

// @generated
void Member_set_familyDaughter(Member *self, Family *value) {
    self->familyDaughter = value;
}

/// @brief Creates an object of the Member class for its description.
// @generated
static EObject *Member_create_object(void) {
    Member *object = Member_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Member class for its description.
// @generated
static void Member_destroy_object(EObject *object) {
    Member_destroy((Member *)object);
}

/// @brief The features of the Family class.
// @generated
static const EFeatureInfo Family_features[] = {
    { .name = "lastName", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "father", .kind = EFeatureKind_Containment, .isMany = false, .typeName = "Member" },
    { .name = "mother", .kind = EFeatureKind_Containment, .isMany = false, .typeName = "Member" },
    { .name = "sons", .kind = EFeatureKind_Containment, .isMany = true, .typeName = "Member" },
    { .name = "daughters", .kind = EFeatureKind_Containment, .isMany = true, .typeName = "Member" },
};

/// @brief The description of the Family class.
// @generated
const EClassInfo Family_class = {
    .name = "Family",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Family_features,
    .featureCount = 5,
    .create = Family_create_object,
    .destroy = Family_destroy_object
};

/// @brief The features of the Member class.
// @generated
static const EFeatureInfo Member_features[] = {
    { .name = "firstName", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "familyFather", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Family" },
    { .name = "familyMother", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Family" },
    { .name = "familySon", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Family" },
    { .name = "familyDaughter", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Family" },
};

/// @brief The description of the Member class.
// @generated
const EClassInfo Member_class = {
    .name = "Member",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Member_features,
    .featureCount = 5,
    .create = Member_create_object,
    .destroy = Member_destroy_object
};

/// @brief The descriptions of the classes of the Families package.
// @generated
static const EClassInfo *const FamiliesPackage_classes[] = {
    &Family_class,
    &Member_class,
};

/// @brief The description of the Families package and its classes.
// @generated
const EPackageInfo FamiliesPackage = {
    .name = "Families",
    .nsURI = "http://www.example.org/families",
    .nsPrefix = "families",
    .classes = FamiliesPackage_classes,
    .classCount = 2
};

// @generated
EObject *FamiliesFactory_create(const EClassInfo *eClass) {
    for (size_t position = 0; position < FamiliesPackage.classCount; position++) {
        if (FamiliesPackage.classes[position] == eClass) {
            return eClass->create == NULL ? NULL : eClass->create();
        }
    }
    return NULL;
}
