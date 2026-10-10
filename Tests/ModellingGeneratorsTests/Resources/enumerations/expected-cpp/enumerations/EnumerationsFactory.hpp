#pragma once

//
//  EnumerationsFactory.hpp
//

#include "EObject.hpp"
#include "enumerations/Light.hpp"
#include <memory>
#include <string_view>

// @generated
namespace enumerations {

/// @brief The factory of the enumerations package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
class EnumerationsFactory final {
public:
    /// @brief The shared factory of the package.
    /// @return The only instance.
    // @generated
    static const EnumerationsFactory &instance() {
        static const EnumerationsFactory factory;
        return factory;
    }

    /// @brief Creates a new Light object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Light> createLight() const { return std::make_shared<Light>(); }

    /// @brief Creates an object for the name of a class of the package.
    /// @param className The name of the class in the model.
    /// @return A new object, or a null pointer if the package has no class with instances of that name.
    // @generated
    std::shared_ptr<EObject> create([[maybe_unused]] std::string_view className) const {
        if (className == "Light") return createLight();
        return nullptr;
    }
};

}
