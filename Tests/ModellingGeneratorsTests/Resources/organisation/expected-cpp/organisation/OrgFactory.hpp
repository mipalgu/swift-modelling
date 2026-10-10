#pragma once

//
//  OrgFactory.hpp
//

#include "EObject.hpp"
#include "organisation/Organisation.hpp"
#include "organisation/Person.hpp"
#include "organisation/Team.hpp"
#include <memory>
#include <string_view>

// @generated
namespace organisation {

/// @brief The factory of the organisation package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
class OrgFactory final {
public:
    /// @brief The shared factory of the package.
    /// @return The only instance.
    // @generated
    static const OrgFactory &instance() {
        static const OrgFactory factory;
        return factory;
    }

    /// @brief Creates a new Person object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Person> createPerson() const { return std::make_shared<Person>(); }

    /// @brief Creates a new Team object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Team> createTeam() const { return std::make_shared<Team>(); }

    /// @brief Creates a new Organisation object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Organisation> createOrganisation() const { return std::make_shared<Organisation>(); }

    /// @brief Creates an object for the name of a class of the package.
    /// @param className The name of the class in the model.
    /// @return A new object, or a null pointer if the package has no class with instances of that name.
    // @generated
    std::shared_ptr<EObject> create([[maybe_unused]] std::string_view className) const {
        if (className == "Person") return createPerson();
        if (className == "Team") return createTeam();
        if (className == "Organisation") return createOrganisation();
        return nullptr;
    }
};

}
