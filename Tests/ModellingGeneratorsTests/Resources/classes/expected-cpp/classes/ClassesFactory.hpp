#pragma once

//
//  ClassesFactory.hpp
//

#include "EObject.hpp"
#include "classes/Canvas.hpp"
#include "classes/Circle.hpp"
#include <memory>
#include <string_view>

// @generated
namespace classes {

/// @brief The factory of the classes package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
class ClassesFactory final {
public:
    /// @brief The shared factory of the package.
    /// @return The only instance.
    // @generated
    static const ClassesFactory &instance() {
        static const ClassesFactory factory;
        return factory;
    }

    /// @brief Creates a new Canvas object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Canvas> createCanvas() const { return std::make_shared<Canvas>(); }

    /// @brief Creates a new Circle object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Circle> createCircle() const { return std::make_shared<Circle>(); }

    /// @brief Creates an object for the name of a class of the package.
    /// @param className The name of the class in the model.
    /// @return A new object, or a null pointer if the package has no class with instances of that name.
    // @generated
    std::shared_ptr<EObject> create([[maybe_unused]] std::string_view className) const {
        if (className == "Canvas") return createCanvas();
        if (className == "Circle") return createCircle();
        return nullptr;
    }
};

}
