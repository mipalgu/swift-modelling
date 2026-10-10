#pragma once

//
//  FamiliesFactory.hpp
//

#include "EObject.hpp"
#include "Families/Family.hpp"
#include "Families/Member.hpp"
#include <memory>
#include <string_view>

// @generated
namespace Families {

/// @brief The factory of the Families package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
class FamiliesFactory final {
public:
    /// @brief The shared factory of the package.
    /// @return The only instance.
    // @generated
    static const FamiliesFactory &instance() {
        static const FamiliesFactory factory;
        return factory;
    }

    /// @brief Creates a new Family object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Family> createFamily() const { return std::make_shared<Family>(); }

    /// @brief Creates a new Member object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Member> createMember() const { return std::make_shared<Member>(); }

    /// @brief Creates an object for the name of a class of the package.
    /// @param className The name of the class in the model.
    /// @return A new object, or a null pointer if the package has no class with instances of that name.
    // @generated
    std::shared_ptr<EObject> create([[maybe_unused]] std::string_view className) const {
        if (className == "Family") return createFamily();
        if (className == "Member") return createMember();
        return nullptr;
    }
};

}
