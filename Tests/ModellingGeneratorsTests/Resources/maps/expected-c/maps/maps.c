//
//  maps.c
//

#include "maps/maps.h"
#include <stdlib.h>
#include <string.h>

// @generated
Dictionary *Dictionary_create(void) {
    Dictionary *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Dictionary_class;
    self->entries.items = NULL;
    self->entries.count = 0;
    self->entries.capacity = 0;
    return self;
}

// @generated
void Dictionary_destroy(Dictionary *self) {
    if (self == NULL) {
        return;
    }
    Dictionary_clear_entries(self);
    free(self);
}

// @generated
size_t Dictionary_count_entries(const Dictionary *self) {
    return self->entries.count;
}

// @generated
StringToIntEntry *Dictionary_item_entries(const Dictionary *self, size_t index) {
    if (index >= self->entries.count) {
        return NULL;
    }
    return self->entries.items[index];
}

// @generated
bool Dictionary_add_entries(Dictionary *self, StringToIntEntry *value) {
    if (self->entries.count == self->entries.capacity) {
        void *items = EObject_grown(self->entries.items, &self->entries.capacity, sizeof *self->entries.items);
        if (items == NULL) {
            return false;
        }
        self->entries.items = items;
    }
    self->entries.items[self->entries.count++] = value;
    return true;
}

// @generated
bool Dictionary_remove_entries(Dictionary *self, size_t index) {
    if (index >= self->entries.count) {
        return false;
    }
    EObject_destroy((EObject *)self->entries.items[index]);
    memmove(&self->entries.items[index], &self->entries.items[index + 1], (self->entries.count - index - 1) * sizeof *self->entries.items);
    self->entries.count--;
    return true;
}

// @generated
void Dictionary_clear_entries(Dictionary *self) {
    for (size_t position = 0; position < self->entries.count; position++) {
        EObject_destroy((EObject *)self->entries.items[position]);
    }
    free(self->entries.items);
    self->entries.items = NULL;
    self->entries.count = 0;
    self->entries.capacity = 0;
}

/// @brief Creates an object of the Dictionary class for its description.
// @generated
static EObject *Dictionary_create_object(void) {
    Dictionary *object = Dictionary_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Dictionary class for its description.
// @generated
static void Dictionary_destroy_object(EObject *object) {
    Dictionary_destroy((Dictionary *)object);
}

// @generated
StringToIntEntry *StringToIntEntry_create(void) {
    StringToIntEntry *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &StringToIntEntry_class;
    self->key = NULL;
    self->value_ = 0;
    return self;
}

// @generated
void StringToIntEntry_destroy(StringToIntEntry *self) {
    if (self == NULL) {
        return;
    }
    free(self->key);
    free(self);
}

// @generated
const char *StringToIntEntry_get_key(const StringToIntEntry *self) {
    return self->key;
}

// @generated
bool StringToIntEntry_set_key(StringToIntEntry *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->key);
    self->key = copy;
    return true;
}

// @generated
int32_t StringToIntEntry_get_value(const StringToIntEntry *self) {
    return self->value_;
}

// @generated
void StringToIntEntry_set_value(StringToIntEntry *self, int32_t value) {
    self->value_ = value;
}

/// @brief Creates an object of the StringToIntEntry class for its description.
// @generated
static EObject *StringToIntEntry_create_object(void) {
    StringToIntEntry *object = StringToIntEntry_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the StringToIntEntry class for its description.
// @generated
static void StringToIntEntry_destroy_object(EObject *object) {
    StringToIntEntry_destroy((StringToIntEntry *)object);
}

/// @brief The features of the Dictionary class.
// @generated
static const EFeatureInfo Dictionary_features[] = {
    { .name = "entries", .kind = EFeatureKind_Containment, .isMany = true, .typeName = "StringToIntEntry" },
};

/// @brief The description of the Dictionary class.
// @generated
const EClassInfo Dictionary_class = {
    .name = "Dictionary",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Dictionary_features,
    .featureCount = 1,
    .create = Dictionary_create_object,
    .destroy = Dictionary_destroy_object
};

/// @brief The features of the StringToIntEntry class.
// @generated
static const EFeatureInfo StringToIntEntry_features[] = {
    { .name = "key", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "value", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EInt" },
};

/// @brief The description of the StringToIntEntry class.
// @generated
const EClassInfo StringToIntEntry_class = {
    .name = "StringToIntEntry",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = StringToIntEntry_features,
    .featureCount = 2,
    .create = StringToIntEntry_create_object,
    .destroy = StringToIntEntry_destroy_object
};

/// @brief The descriptions of the classes of the maps package.
// @generated
static const EClassInfo *const MapsPackage_classes[] = {
    &Dictionary_class,
    &StringToIntEntry_class,
};

/// @brief The description of the maps package and its classes.
// @generated
const EPackageInfo MapsPackage = {
    .name = "maps",
    .nsURI = "http://swift-modelling.org/test/maps",
    .nsPrefix = "maps",
    .classes = MapsPackage_classes,
    .classCount = 2
};

// @generated
EObject *MapsFactory_create(const EClassInfo *eClass) {
    for (size_t position = 0; position < MapsPackage.classCount; position++) {
        if (MapsPackage.classes[position] == eClass) {
            return eClass->create == NULL ? NULL : eClass->create();
        }
    }
    return NULL;
}
