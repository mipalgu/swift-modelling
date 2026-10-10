//
//  documented.c
//

#include "documented/documented.h"
#include <stdlib.h>
#include <string.h>

// @generated
const char *Level_literal(Level value) {
    switch (value) {
    case Level_Low:
        return "Low";
    case Level_High:
        return "High";
    case Level_Old:
        return "Old";
    default:
        return NULL;
    }
}

// @generated
bool Level_from_literal(const char *literal, Level *value) {
    if (literal == NULL || value == NULL) {
        return false;
    }
    if (strcmp(literal, "Low") == 0) {
        *value = Level_Low;
        return true;
    }
    if (strcmp(literal, "High") == 0) {
        *value = Level_High;
        return true;
    }
    if (strcmp(literal, "Old") == 0) {
        *value = Level_Old;
        return true;
    }
    return false;
}

/// @brief The description of the documented package and its classes.
// @generated
const EPackageInfo DocumentedPackage = {
    .name = "documented",
    .nsURI = "http://swift-modelling.org/test/documented",
    .nsPrefix = "doc",
    .classes = NULL,
    .classCount = 0
};

// @generated
EObject *DocumentedFactory_create(const EClassInfo *eClass) {
    for (size_t position = 0; position < DocumentedPackage.classCount; position++) {
        if (DocumentedPackage.classes[position] == eClass) {
            return eClass->create == NULL ? NULL : eClass->create();
        }
    }
    return NULL;
}
