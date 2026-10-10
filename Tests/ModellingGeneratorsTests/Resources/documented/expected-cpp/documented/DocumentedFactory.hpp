#pragma once

//
//  DocumentedFactory.hpp
//

#include "EObject.hpp"
#include <memory>
#include <string_view>

// @generated
namespace documented {

/// @brief The factory of the documented package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
class DocumentedFactory final {
public:
    /// @brief The shared factory of the package.
    /// @return The only instance.
    // @generated
    static const DocumentedFactory &instance() {
        static const DocumentedFactory factory;
        return factory;
    }

    /// @brief Creates an object for the name of a class of the package.
    /// @param className The name of the class in the model.
    /// @return A new object, or a null pointer if the package has no class with instances of that name.
    // @generated
    std::shared_ptr<EObject> create([[maybe_unused]] std::string_view className) const {
        return nullptr;
    }
};

}
