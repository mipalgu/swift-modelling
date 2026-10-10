#pragma once

//
//  BridgeFactory.hpp
//

#include "EObject.hpp"
#include "bridge/Span.hpp"
#include <memory>
#include <string_view>

// @generated
namespace bridge {

/// @brief The factory of the bridge package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
class BridgeFactory final {
public:
    /// @brief The shared factory of the package.
    /// @return The only instance.
    // @generated
    static const BridgeFactory &instance() {
        static const BridgeFactory factory;
        return factory;
    }

    /// @brief Creates a new Span object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Span> createSpan() const { return std::make_shared<Span>(); }

    /// @brief Creates an object for the name of a class of the package.
    /// @param className The name of the class in the model.
    /// @return A new object, or a null pointer if the package has no class with instances of that name.
    // @generated
    std::shared_ptr<EObject> create([[maybe_unused]] std::string_view className) const {
        if (className == "Span") return createSpan();
        return nullptr;
    }
};

}
