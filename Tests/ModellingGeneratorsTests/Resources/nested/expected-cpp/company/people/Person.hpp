#pragma once

//
//  Person.hpp
//

#include "EObject.hpp"
#include <string>

// @generated
namespace company::people {

/// @brief The Person class.
///
/// Part of the people package.
// @generated
class Person : public virtual EObject {
public:
    /// @brief Destroys the object.
    // @generated
    virtual ~Person() = default;

    /// @brief The name attribute.
    /// @return The current value of the name attribute.
    // @generated
    virtual const std::string &getName() const = 0;

    /// @brief Changes the name attribute.
    /// @param value The new value.
    // @generated
    virtual void setName(const std::string &value) = 0;

protected:
    /// @brief Creates the part of an object that this class describes.
    // @generated
    Person() = default;
};

}
