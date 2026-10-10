#pragma once

//
//  Named.hpp
//
//  Copyright 2026 Example Pty Ltd
//

#include "EObject.hpp"
#include <string>

// @generated
namespace library {

/// @brief The Named class.
///
/// Part of the library package.
// @generated
class Named : public virtual EObject {
public:
    /// @brief Destroys the object.
    // @generated
    virtual ~Named() = default;

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
    Named() = default;
};

}
