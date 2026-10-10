#pragma once

//
//  EObject_.hpp
//

#include "EObject.hpp"
#include "cnames/CnamesPackage.hpp"
#include <string>

// @generated
namespace cnames {

/// @brief The EObject class.
///
/// Part of the cnames package.
// @generated
class EObject_ final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the EObject class.
    // @generated
    const ClassInfo &eClass() const override { return CnamesPackage::instance().eObjectClass(); }

    /// @brief The eClass attribute.
    /// @return The current value of the eClass attribute.
    // @generated
    const std::string &getEClass() const { return m_eClass; }

    /// @brief Changes the eClass attribute.
    /// @param value The new value.
    // @generated
    void setEClass(const std::string &value) { m_eClass = value; }

private:
    /// @brief The storage of the eClass attribute.
    // @generated
    std::string m_eClass;
};

}
