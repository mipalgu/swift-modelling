#pragma once

//
//  BareFactory.hpp
//

#include "EObject.hpp"
#include "bare/Thing.hpp"
#include <memory>
#include <string_view>

// @generated
namespace bare {

/// @brief The factory of the bare package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
class BareFactory final {
public:
    /// @brief The shared factory of the package.
    /// @return The only instance.
    // @generated
    static const BareFactory &instance() {
        static const BareFactory factory;
        return factory;
    }

    /// @brief Creates a new Thing object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Thing> createThing() const { return std::make_shared<Thing>(); }

    /// @brief Creates an object for the name of a class of the package.
    /// @param className The name of the class in the model.
    /// @return A new object, or a null pointer if the package has no class with instances of that name.
    // @generated
    std::shared_ptr<EObject> create([[maybe_unused]] std::string_view className) const {
        if (className == "Thing") return createThing();
        return nullptr;
    }
};

}
