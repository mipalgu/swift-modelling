#pragma once

//
//  Driver.hpp
//

#include "EObject.hpp"
#include "cnames/CnamesPackage.hpp"
#include <memory>

// @generated
namespace cnames { class Vehicle; }

// @generated
namespace cnames {

/// @brief The Driver class.
///
/// Part of the cnames package.
// @generated
class Driver final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Driver class.
    // @generated
    const ClassInfo &eClass() const override { return CnamesPackage::instance().driverClass(); }

    /// @brief The vehicle reference.
    /// @return The current value of the vehicle reference.
    // @generated
    std::shared_ptr<Vehicle> getVehicle() const { return m_vehicle.lock(); }

    /// @brief Changes the vehicle reference.
    /// @param value The new value.
    // @generated
    void setVehicle(const std::shared_ptr<Vehicle> &value) { m_vehicle = value; }

private:
    /// @brief The storage of the vehicle reference.
    // @generated
    std::weak_ptr<Vehicle> m_vehicle;
};

}
