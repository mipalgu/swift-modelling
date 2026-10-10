#pragma once

//
//  Wheel.hpp
//

#include "EObject.hpp"
#include "cnames/delete/DeletePackage.hpp"
#include <memory>
#include <string>

// @generated
namespace cnames { class Vehicle; }

// @generated
namespace cnames::delete_ {

/// @brief The Wheel class.
///
/// Part of the delete package.
// @generated
class Wheel final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Wheel class.
    // @generated
    const ClassInfo &eClass() const override { return DeletePackage::instance().wheelClass(); }

    /// @brief The auto attribute.
    /// @return The current value of the auto attribute.
    // @generated
    const std::string &getAuto() const { return m_auto; }

    /// @brief Changes the auto attribute.
    /// @param value The new value.
    // @generated
    void setAuto(const std::string &value) { m_auto = value; }

    /// @brief The virtual reference.
    /// @return The current value of the virtual reference.
    // @generated
    std::shared_ptr<::cnames::Vehicle> getVirtual() const { return m_virtual.lock(); }

    /// @brief Changes the virtual reference.
    /// @param value The new value.
    // @generated
    void setVirtual(const std::shared_ptr<::cnames::Vehicle> &value) { m_virtual = value; }

private:
    /// @brief The storage of the auto attribute.
    // @generated
    std::string m_auto;

    /// @brief The storage of the virtual reference.
    // @generated
    std::weak_ptr<::cnames::Vehicle> m_virtual;
};

}
