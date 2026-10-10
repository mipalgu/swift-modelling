#pragma once

//
//  PeopleFactory.hpp
//

#include "EObject.hpp"
#include "company/people/Employee.hpp"
#include <memory>
#include <string_view>

// @generated
namespace company::people {

/// @brief The factory of the people package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
class PeopleFactory final {
public:
    /// @brief The shared factory of the package.
    /// @return The only instance.
    // @generated
    static const PeopleFactory &instance() {
        static const PeopleFactory factory;
        return factory;
    }

    /// @brief Creates a new Employee object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Employee> createEmployee() const { return std::make_shared<Employee>(); }

    /// @brief Creates an object for the name of a class of the package.
    /// @param className The name of the class in the model.
    /// @return A new object, or a null pointer if the package has no class with instances of that name.
    // @generated
    std::shared_ptr<EObject> create([[maybe_unused]] std::string_view className) const {
        if (className == "Employee") return createEmployee();
        return nullptr;
    }
};

}
