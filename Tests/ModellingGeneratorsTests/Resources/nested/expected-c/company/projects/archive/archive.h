//
//  archive.h
//

#ifndef COMPANY_PROJECTS_ARCHIVE_ARCHIVE_H
#define COMPANY_PROJECTS_ARCHIVE_ARCHIVE_H

#include "EObject.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
// @generated
extern "C" {
#endif

/// @brief The Record class.
// @generated
typedef struct Record Record;

/// @brief The Project class.
// @generated
typedef struct Project Project;

/// @brief The description of the Record class.
// @generated
extern const EClassInfo Record_class;

/// @brief The Record class.
///
/// Part of the archive package.
/// The object owns the text, the bytes and the contained objects that its fields refer to.
// @generated
struct Record {
    /// @brief The header that every model object starts with, which refers to the description of the class.
    // @generated
    EObject eObject;

    /// @brief The project reference.
    // @generated
    Project *project;
};

/// @brief Creates a Record object with all features at their defaults.
///
/// The caller owns the object and releases it with Record_destroy.
///
/// @return The new object; the null pointer if the memory could not be allocated.
// @generated
Record *Record_create(void);

/// @brief Destroys a Record object together with the strings, byte arrays and contained objects that it owns.
///
/// @param self The object to destroy; may be the null pointer, which is ignored.
// @generated
void Record_destroy(Record *self);

/// @brief Returns the value of the project reference.
///
/// @param self The object to read.
/// @return The value.
// @generated
Project *Record_get_project(const Record *self);

/// @brief Sets the value of the project reference.
///
/// @param self The object to change.
/// @param value The new value.
// @generated
void Record_set_project(Record *self, Project *value);

/// @brief The description of the archive package and its classes.
// @generated
extern const EPackageInfo ArchivePackage;

/// @brief Creates an object for a class of the archive package.
///
/// @param eClass The description of the class to create an object of.
/// @return The new object, which the caller releases with EObject_destroy; the null pointer if the class does not
///         belong to the package, has no instances, or the memory could not be allocated.
// @generated
EObject *ArchiveFactory_create(const EClassInfo *eClass);

#ifdef __cplusplus
}
#endif

#endif
