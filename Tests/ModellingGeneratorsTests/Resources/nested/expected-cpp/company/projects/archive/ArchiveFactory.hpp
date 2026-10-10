#pragma once

//
//  ArchiveFactory.hpp
//

#include "EObject.hpp"
#include "company/projects/archive/Record.hpp"
#include <memory>
#include <string_view>

// @generated
namespace company::projects::archive {

/// @brief The factory of the archive package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
class ArchiveFactory final {
public:
    /// @brief The shared factory of the package.
    /// @return The only instance.
    // @generated
    static const ArchiveFactory &instance() {
        static const ArchiveFactory factory;
        return factory;
    }

    /// @brief Creates a new Record object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Record> createRecord() const { return std::make_shared<Record>(); }

    /// @brief Creates an object for the name of a class of the package.
    /// @param className The name of the class in the model.
    /// @return A new object, or a null pointer if the package has no class with instances of that name.
    // @generated
    std::shared_ptr<EObject> create([[maybe_unused]] std::string_view className) const {
        if (className == "Record") return createRecord();
        return nullptr;
    }
};

}
