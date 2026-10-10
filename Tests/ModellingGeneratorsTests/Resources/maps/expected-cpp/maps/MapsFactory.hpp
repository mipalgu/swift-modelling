#pragma once

//
//  MapsFactory.hpp
//

#include "EObject.hpp"
#include "maps/Dictionary.hpp"
#include "maps/StringToIntEntry.hpp"
#include <memory>
#include <string_view>

// @generated
namespace maps {

/// @brief The factory of the maps package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
class MapsFactory final {
public:
    /// @brief The shared factory of the package.
    /// @return The only instance.
    // @generated
    static const MapsFactory &instance() {
        static const MapsFactory factory;
        return factory;
    }

    /// @brief Creates a new Dictionary object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Dictionary> createDictionary() const { return std::make_shared<Dictionary>(); }

    /// @brief Creates a new StringToIntEntry object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<StringToIntEntry> createStringToIntEntry() const { return std::make_shared<StringToIntEntry>(); }

    /// @brief Creates an object for the name of a class of the package.
    /// @param className The name of the class in the model.
    /// @return A new object, or a null pointer if the package has no class with instances of that name.
    // @generated
    std::shared_ptr<EObject> create([[maybe_unused]] std::string_view className) const {
        if (className == "Dictionary") return createDictionary();
        if (className == "StringToIntEntry") return createStringToIntEntry();
        return nullptr;
    }
};

}
