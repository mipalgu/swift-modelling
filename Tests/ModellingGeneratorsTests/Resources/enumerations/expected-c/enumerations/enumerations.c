//
//  enumerations.c
//

#include "enumerations/enumerations.h"
#include <stdlib.h>
#include <string.h>

// @generated
const char *Colour_literal(Colour value) {
    switch (value) {
    case Colour_Red:
        return "red";
    case Colour_Amber:
        return "amber";
    case Colour_Green:
        return "Green";
    default:
        return NULL;
    }
}

// @generated
bool Colour_from_literal(const char *literal, Colour *value) {
    if (literal == NULL || value == NULL) {
        return false;
    }
    if (strcmp(literal, "red") == 0) {
        *value = Colour_Red;
        return true;
    }
    if (strcmp(literal, "amber") == 0) {
        *value = Colour_Amber;
        return true;
    }
    if (strcmp(literal, "yellow") == 0) {
        *value = Colour_Yellow;
        return true;
    }
    if (strcmp(literal, "Green") == 0) {
        *value = Colour_Green;
        return true;
    }
    return false;
}

// @generated
const char *Mode_literal(Mode value) {
    switch (value) {
    case Mode_default:
        return "default";
    case Mode_fastForward:
        return "fastForward";
    case Mode_HTTPServer:
        return "HTTPServer";
    case Mode__:
        return "_";
    case Mode_quote:
        return "say \"hi\"";
    default:
        return NULL;
    }
}

// @generated
bool Mode_from_literal(const char *literal, Mode *value) {
    if (literal == NULL || value == NULL) {
        return false;
    }
    if (strcmp(literal, "default") == 0) {
        *value = Mode_default;
        return true;
    }
    if (strcmp(literal, "fastForward") == 0) {
        *value = Mode_fastForward;
        return true;
    }
    if (strcmp(literal, "HTTPServer") == 0) {
        *value = Mode_HTTPServer;
        return true;
    }
    if (strcmp(literal, "_") == 0) {
        *value = Mode__;
        return true;
    }
    if (strcmp(literal, "say \"hi\"") == 0) {
        *value = Mode_quote;
        return true;
    }
    return false;
}

// @generated
const char *Empty_literal(Empty value) {
    (void)value;
    return NULL;
}

// @generated
bool Empty_from_literal(const char *literal, Empty *value) {
    if (literal == NULL || value == NULL) {
        return false;
    }
    return false;
}

// @generated
Light *Light_create(void) {
    Light *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Light_class;
    self->colour = Colour_Red;
    self->mode = Mode_default;
    return self;
}

// @generated
void Light_destroy(Light *self) {
    if (self == NULL) {
        return;
    }
    free(self);
}

// @generated
Colour Light_get_colour(const Light *self) {
    return self->colour;
}

// @generated
void Light_set_colour(Light *self, Colour value) {
    self->colour = value;
}

// @generated
Mode Light_get_mode(const Light *self) {
    return self->mode;
}

// @generated
void Light_set_mode(Light *self, Mode value) {
    self->mode = value;
}

/// @brief Creates an object of the Light class for its description.
// @generated
static EObject *Light_create_object(void) {
    Light *object = Light_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Light class for its description.
// @generated
static void Light_destroy_object(EObject *object) {
    Light_destroy((Light *)object);
}

/// @brief The features of the Light class.
// @generated
static const EFeatureInfo Light_features[] = {
    { .name = "colour", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "Colour" },
    { .name = "mode", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "Mode" },
};

/// @brief The description of the Light class.
// @generated
const EClassInfo Light_class = {
    .name = "Light",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Light_features,
    .featureCount = 2,
    .create = Light_create_object,
    .destroy = Light_destroy_object
};

/// @brief The descriptions of the classes of the enumerations package.
// @generated
static const EClassInfo *const EnumerationsPackage_classes[] = {
    &Light_class,
};

/// @brief The description of the enumerations package and its classes.
// @generated
const EPackageInfo EnumerationsPackage = {
    .name = "enumerations",
    .nsURI = "http://swift-modelling.org/test/enumerations",
    .nsPrefix = "enums",
    .classes = EnumerationsPackage_classes,
    .classCount = 1
};

// @generated
EObject *EnumerationsFactory_create(const EClassInfo *eClass) {
    for (size_t position = 0; position < EnumerationsPackage.classCount; position++) {
        if (EnumerationsPackage.classes[position] == eClass) {
            return eClass->create == NULL ? NULL : eClass->create();
        }
    }
    return NULL;
}
