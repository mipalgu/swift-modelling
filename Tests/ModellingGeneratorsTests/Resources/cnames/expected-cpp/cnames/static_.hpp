#pragma once

//
//  static_.hpp
//

#include "EObject.hpp"
#include "cnames/CnamesPackage.hpp"

// @generated
namespace cnames {

/// @brief A class whose name is a keyword.
// @generated
class static_ final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the static class.
    // @generated
    const ClassInfo &eClass() const override { return CnamesPackage::instance().staticClass(); }

    /// @brief The volatile attribute.
    /// @return The current value of the volatile attribute.
    // @generated
    bool getVolatile() const { return m_volatile; }

    /// @brief Changes the volatile attribute.
    /// @param value The new value.
    // @generated
    void setVolatile(bool value) { m_volatile = value; }

private:
    /// @brief The storage of the volatile attribute.
    // @generated
    bool m_volatile = false;
};

}
