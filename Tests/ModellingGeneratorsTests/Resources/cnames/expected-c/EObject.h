//
//  EObject.h
//

#ifndef EOBJECT_H
#define EOBJECT_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#ifdef __cplusplus
// @generated
extern "C" {
#endif

/// @brief The description of a class of a model, shared by all objects of the class.
// @generated
typedef struct EClassInfo EClassInfo;

/// @brief The header that every model object starts with.
///
/// Because the header is the first member of the structure of every class, a pointer to an object of any class
/// converts to a pointer to its header and back.
// @generated
typedef struct EObject EObject;

/// @brief The header that every model object starts with.
// @generated
struct EObject {
    /// @brief The description of the class of the object.
    // @generated
    const EClassInfo *eClass;
};

/// @brief The kinds of features that a class description lists.
// @generated
enum EFeatureKind {
    /// @brief A feature that holds values of a data type or an enumeration.
    // @generated
    EFeatureKind_Attribute,

    /// @brief A feature that refers to objects without owning them.
    // @generated
    EFeatureKind_Reference,

    /// @brief A feature that refers to objects that the object owns.
    // @generated
    EFeatureKind_Containment
};

/// @brief The kinds of features that a class description lists.
// @generated
typedef enum EFeatureKind EFeatureKind;

/// @brief The description of a feature of a class.
// @generated
typedef struct EFeatureInfo EFeatureInfo;

/// @brief The description of a feature of a class.
// @generated
struct EFeatureInfo {
    /// @brief The name of the feature in the model.
    // @generated
    const char *name;

    /// @brief Whether the feature is an attribute, a reference or a containment.
    // @generated
    EFeatureKind kind;

    /// @brief Whether the feature holds any number of values.
    // @generated
    bool isMany;

    /// @brief The name in the model of the type of the values of the feature.
    // @generated
    const char *typeName;
};

/// @brief The description of a class of a model, shared by all objects of the class.
///
/// A class that cannot have instances has no functions that create and destroy objects.
// @generated
struct EClassInfo {
    /// @brief The name of the class in the model.
    // @generated
    const char *name;

    /// @brief Whether the class cannot have instances of its own.
    // @generated
    bool isAbstract;

    /// @brief The descriptions of the direct supertypes of the class.
    // @generated
    const EClassInfo *const *superTypes;

    /// @brief The number of direct supertypes.
    // @generated
    size_t superTypeCount;

    /// @brief The descriptions of all features of the class, inherited ones first.
    // @generated
    const EFeatureInfo *features;

    /// @brief The number of features.
    // @generated
    size_t featureCount;

    /// @brief Creates an object of the class, or is the null pointer if the class has no instances.
    // @generated
    EObject *(*create)(void);

    /// @brief Destroys an object of the class, or is the null pointer if the class has no instances.
    // @generated
    void (*destroy)(EObject *);
};

/// @brief The description of a package of a model.
// @generated
typedef struct EPackageInfo EPackageInfo;

/// @brief The description of a package of a model.
// @generated
struct EPackageInfo {
    /// @brief The name of the package.
    // @generated
    const char *name;

    /// @brief The namespace URI that identifies the package.
    // @generated
    const char *nsURI;

    /// @brief The prefix of the namespace of the package.
    // @generated
    const char *nsPrefix;

    /// @brief The descriptions of the classes of the package.
    // @generated
    const EClassInfo *const *classes;

    /// @brief The number of classes.
    // @generated
    size_t classCount;
};

/// @brief A byte array that an object owns.
// @generated
typedef struct EByteArray EByteArray;

/// @brief A byte array that an object owns.
// @generated
struct EByteArray {
    /// @brief The bytes, or the null pointer if there are none.
    // @generated
    uint8_t *bytes;

    /// @brief The number of bytes.
    // @generated
    size_t length;
};

/// @brief Declares the type of a list of values.
///
/// The list holds the values, their number and the number of values that fit into the room reserved for them.
// @generated
#define EList(ItemType) struct { ItemType *items; size_t count; size_t capacity; }

/// @brief Tells whether a class is a given class or has it among its supertypes, directly or not.
///
/// @param candidate The description of the class to look at.
/// @param eClass The description of the class to look for.
/// @return `true` if the class conforms; `false` if it does not, or if a description is missing.
// @generated
static inline bool EClassInfo_conformsTo(const EClassInfo *candidate, const EClassInfo *eClass) {
    if (candidate == NULL || eClass == NULL) {
        return false;
    }
    if (candidate == eClass) {
        return true;
    }
    for (size_t position = 0; position < candidate->superTypeCount; position++) {
        if (EClassInfo_conformsTo(candidate->superTypes[position], eClass)) {
            return true;
        }
    }
    return false;
}

/// @brief Tells whether an object belongs to a class or to one of its subclasses.
///
/// @param object The object to look at; may be the null pointer.
/// @param eClass The description of the class to look for.
/// @return `true` if the object conforms to the class; `false` if it does not, or if the object is the null pointer.
// @generated
static inline bool EObject_isKindOf(const EObject *object, const EClassInfo *eClass) {
    return object != NULL && EClassInfo_conformsTo(object->eClass, eClass);
}

/// @brief Destroys an object together with the objects that it owns.
///
/// @param object The object to destroy; may be the null pointer, which is ignored.
// @generated
static inline void EObject_destroy(EObject *object) {
    if (object != NULL && object->eClass != NULL && object->eClass->destroy != NULL) {
        object->eClass->destroy(object);
    }
}

/// @brief Copies a text into memory that the caller owns.
///
/// @param text The text to copy; may be the null pointer.
/// @return The copy, which the caller releases with `free`; the null pointer if the text is the null pointer or the
///         memory could not be allocated.
// @generated
static inline char *EObject_duplicateString(const char *text) {
    if (text == NULL) {
        return NULL;
    }
    size_t size = strlen(text) + 1;
    char *copy = (char *)malloc(size);
    if (copy != NULL) {
        memcpy(copy, text, size);
    }
    return copy;
}

/// @brief Copies bytes into memory that the caller owns.
///
/// @param value The bytes to copy.
/// @param copy Receives the copy, which holds no bytes if there are none to copy.
/// @return `false` if the memory could not be allocated; `true` otherwise.
// @generated
static inline bool EObject_duplicateBytes(EByteArray value, EByteArray *copy) {
    copy->bytes = NULL;
    copy->length = 0;
    if (value.bytes == NULL || value.length == 0) {
        return true;
    }
    uint8_t *bytes = (uint8_t *)malloc(value.length);
    if (bytes == NULL) {
        return false;
    }
    memcpy(bytes, value.bytes, value.length);
    copy->bytes = bytes;
    copy->length = value.length;
    return true;
}

/// @brief Makes room for more values in a list by doubling its capacity.
///
/// @param items The memory of the list, or the null pointer for a list without room.
/// @param capacity The number of values that fit into the memory; increased if the memory could be grown.
/// @param itemSize The size of one value in bytes.
/// @return The grown memory, which holds the values of the list; the null pointer if the size would overflow or the
///         memory could not be allocated, in which case the list and its capacity remain as they were.
// @generated
static inline void *EObject_grown(void *items, size_t *capacity, size_t itemSize) {
    size_t grown = 4;
    if (*capacity > 0) {
        if (*capacity > SIZE_MAX / 2) {
            return NULL;
        }
        grown = *capacity * 2;
    }
    if (itemSize == 0 || grown > SIZE_MAX / itemSize) {
        return NULL;
    }
    void *resized = realloc(items, grown * itemSize);
    if (resized != NULL) {
        *capacity = grown;
    }
    return resized;
}

#ifdef __cplusplus
}
#endif

#endif
