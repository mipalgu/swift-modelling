#pragma once

//
//  DatatypesFactory.hpp
//

#include "EObject.hpp"
#include "datatypes/Class.hpp"
#include "datatypes/Gizmo.hpp"
#include "datatypes/Thing.hpp"
#include <memory>
#include <string_view>

// @generated
namespace datatypes {

/// @brief The factory of the datatypes package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
class DatatypesFactory final {
public:
    /// @brief The shared factory of the package.
    /// @return The only instance.
    // @generated
    static const DatatypesFactory &instance() {
        static const DatatypesFactory factory;
        return factory;
    }

    /// @brief Creates a new Thing object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Thing> createThing() const { return std::make_shared<Thing>(); }

    /// @brief Creates a new Class object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Class> createClass() const { return std::make_shared<Class>(); }

    /// @brief Creates a new Gizmo object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Gizmo> createGizmo() const { return std::make_shared<Gizmo>(); }

    /// @brief Creates an object for the name of a class of the package.
    /// @param className The name of the class in the model.
    /// @return A new object, or a null pointer if the package has no class with instances of that name.
    // @generated
    std::shared_ptr<EObject> create([[maybe_unused]] std::string_view className) const {
        if (className == "Thing") return createThing();
        if (className == "Class") return createClass();
        if (className == "Gizmo") return createGizmo();
        return nullptr;
    }
};

}
