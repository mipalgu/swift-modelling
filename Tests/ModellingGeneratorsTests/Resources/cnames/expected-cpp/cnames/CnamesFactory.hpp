#pragma once

//
//  CnamesFactory.hpp
//

#include "EObject.hpp"
#include "cnames/Driver.hpp"
#include "cnames/EObject_.hpp"
#include "cnames/FILE_.hpp"
#include "cnames/Truck.hpp"
#include "cnames/Vehicle.hpp"
#include "cnames/static_.hpp"
#include <memory>
#include <string_view>

// @generated
namespace cnames {

/// @brief The factory of the cnames package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
class CnamesFactory final {
public:
    /// @brief The shared factory of the package.
    /// @return The only instance.
    // @generated
    static const CnamesFactory &instance() {
        static const CnamesFactory factory;
        return factory;
    }

    /// @brief Creates a new Vehicle object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<VehicleImpl> createVehicle() const { return std::make_shared<VehicleImpl>(); }

    /// @brief Creates a new Truck object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Truck> createTruck() const { return std::make_shared<Truck>(); }

    /// @brief Creates a new Driver object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Driver> createDriver() const { return std::make_shared<Driver>(); }

    /// @brief Creates a new static object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<static_> createStatic() const { return std::make_shared<static_>(); }

    /// @brief Creates a new FILE object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<FILE_> createFILE() const { return std::make_shared<FILE_>(); }

    /// @brief Creates a new EObject object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<EObject_> createEObject() const { return std::make_shared<EObject_>(); }

    /// @brief Creates an object for the name of a class of the package.
    /// @param className The name of the class in the model.
    /// @return A new object, or a null pointer if the package has no class with instances of that name.
    // @generated
    std::shared_ptr<EObject> create([[maybe_unused]] std::string_view className) const {
        if (className == "Vehicle") return createVehicle();
        if (className == "Truck") return createTruck();
        if (className == "Driver") return createDriver();
        if (className == "static") return createStatic();
        if (className == "FILE") return createFILE();
        if (className == "EObject") return createEObject();
        return nullptr;
    }
};

}
