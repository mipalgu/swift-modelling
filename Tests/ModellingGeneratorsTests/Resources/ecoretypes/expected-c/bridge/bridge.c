//
//  bridge.c
//

#include "bridge/bridge.h"
#include <stdlib.h>
#include <string.h>

// @generated
Span *Span_create(void) {
    Span *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Span_class;
    self->label = NULL;
    self->length = 0.0;
    self->payload = NULL;
    self->supports.items = NULL;
    self->supports.count = 0;
    self->supports.capacity = 0;
    self->next = NULL;
    return self;
}

// @generated
void Span_destroy(Span *self) {
    if (self == NULL) {
        return;
    }
    free(self->label);
    Span_clear_supports(self);
    free(self);
}

// @generated
const char *Span_get_label(const Span *self) {
    return self->label;
}

// @generated
bool Span_set_label(Span *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->label);
    self->label = copy;
    return true;
}

// @generated
double Span_get_length(const Span *self) {
    return self->length;
}

// @generated
void Span_set_length(Span *self, double value) {
    self->length = value;
}

// @generated
void *Span_get_payload(const Span *self) {
    return self->payload;
}

// @generated
void Span_set_payload(Span *self, void *value) {
    self->payload = value;
}

// @generated
size_t Span_count_supports(const Span *self) {
    return self->supports.count;
}

// @generated
EObject *Span_item_supports(const Span *self, size_t index) {
    if (index >= self->supports.count) {
        return NULL;
    }
    return self->supports.items[index];
}

// @generated
bool Span_add_supports(Span *self, EObject *value) {
    if (self->supports.count == self->supports.capacity) {
        void *items = EObject_grown(self->supports.items, &self->supports.capacity, sizeof *self->supports.items);
        if (items == NULL) {
            return false;
        }
        self->supports.items = items;
    }
    self->supports.items[self->supports.count++] = value;
    return true;
}

// @generated
bool Span_remove_supports(Span *self, size_t index) {
    if (index >= self->supports.count) {
        return false;
    }
    memmove(&self->supports.items[index], &self->supports.items[index + 1], (self->supports.count - index - 1) * sizeof *self->supports.items);
    self->supports.count--;
    return true;
}

// @generated
void Span_clear_supports(Span *self) {
    free(self->supports.items);
    self->supports.items = NULL;
    self->supports.count = 0;
    self->supports.capacity = 0;
}

// @generated
Span *Span_get_next(const Span *self) {
    return self->next;
}

// @generated
void Span_set_next(Span *self, Span *value) {
    self->next = value;
}

/// @brief Creates an object of the Span class for its description.
// @generated
static EObject *Span_create_object(void) {
    Span *object = Span_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Span class for its description.
// @generated
static void Span_destroy_object(EObject *object) {
    Span_destroy((Span *)object);
}

/// @brief The features of the Span class.
// @generated
static const EFeatureInfo Span_features[] = {
    { .name = "label", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "length", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EDouble" },
    { .name = "payload", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EJavaObject" },
    { .name = "supports", .kind = EFeatureKind_Reference, .isMany = true, .typeName = "EObject" },
    { .name = "next", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Span" },
};

/// @brief The description of the Span class.
// @generated
const EClassInfo Span_class = {
    .name = "Span",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Span_features,
    .featureCount = 5,
    .create = Span_create_object,
    .destroy = Span_destroy_object
};

/// @brief The descriptions of the classes of the bridge package.
// @generated
static const EClassInfo *const BridgePackage_classes[] = {
    &Span_class,
};

/// @brief The description of the bridge package and its classes.
// @generated
const EPackageInfo BridgePackage = {
    .name = "bridge",
    .nsURI = "http://swift-modelling.org/test/bridge",
    .nsPrefix = "bridge",
    .classes = BridgePackage_classes,
    .classCount = 1
};

// @generated
EObject *BridgeFactory_create(const EClassInfo *eClass) {
    for (size_t position = 0; position < BridgePackage.classCount; position++) {
        if (BridgePackage.classes[position] == eClass) {
            return eClass->create == NULL ? NULL : eClass->create();
        }
    }
    return NULL;
}
