#pragma once

//
//  EObject.hpp
//

#include <cstdint>
#include <string_view>
#include <vector>

/// @brief How a feature holds its values.
// @generated
enum class FeatureKind : std::int32_t {
    /// @brief The feature holds values of a data type.
    // @generated
    attribute,
    /// @brief The feature refers to objects that it does not contain.
    // @generated
    reference,
    /// @brief The feature contains the objects it refers to.
    // @generated
    containment,
};

/// @brief The description of a feature of a class.
// @generated
struct FeatureInfo {
    /// @brief The name of the feature in the model.
    // @generated
    std::string_view name;

    /// @brief Whether the feature holds data or objects, and whether it contains them.
    // @generated
    FeatureKind kind = FeatureKind::attribute;

    /// @brief Whether the feature can hold several values.
    // @generated
    bool many = false;

    /// @brief The name in the model of the type of the values.
    // @generated
    std::string_view typeName;
};

/// @brief The description of a class of a model.
// @generated
struct ClassInfo {
    /// @brief The name of the class in the model.
    // @generated
    std::string_view name;

    /// @brief Whether the class has no instances of its own.
    // @generated
    bool isAbstract = false;

    /// @brief The names of all generated supertypes of the class, the direct ones and those they inherit.
    // @generated
    std::vector<std::string_view> superTypes;

    /// @brief All features of the class, those it declares and those it inherits.
    // @generated
    std::vector<FeatureInfo> features;
};

/// @brief The description of a package of a model.
// @generated
struct PackageInfo {
    /// @brief The name of the package in the model.
    // @generated
    std::string_view name;

    /// @brief The namespace URI of the package.
    // @generated
    std::string_view nsURI;

    /// @brief The namespace prefix of the package.
    // @generated
    std::string_view nsPrefix;

    /// @brief The classes of the package.
    // @generated
    std::vector<ClassInfo> classes;
};

/// @brief The root of all generated classes.
///
/// Objects are owned through shared pointers and cannot be copied, because a copy would share the objects it
/// contains. Every object can describe its class.
// @generated
class EObject {
public:
    /// @brief Destroys the object.
    // @generated
    virtual ~EObject() = default;

    /// @brief Describes the class of the object.
    /// @return The description of the class, which lives as long as the program.
    // @generated
    virtual const ClassInfo &eClass() const = 0;

    /// @brief Objects cannot be copied.
    // @generated
    EObject(const EObject &) = delete;

    /// @brief Objects cannot be assigned.
    // @generated
    EObject &operator=(const EObject &) = delete;

protected:
    /// @brief Creates the root part of an object.
    // @generated
    EObject() = default;
};

/// @brief Whether an object is an instance of a class or of one of its subclasses.
/// @param object The object to test.
/// @param className The name of the class in the model.
/// @return True if the class of the object is the class or inherits from it.
// @generated
inline bool isKindOf(const EObject &object, std::string_view className) {
    const ClassInfo &info = object.eClass();
    if (info.name == className) return true;
    for (std::string_view superType : info.superTypes) {
        if (superType == className) return true;
    }
    return false;
}
