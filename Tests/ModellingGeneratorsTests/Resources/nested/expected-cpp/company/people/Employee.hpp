#pragma once

//
//  Employee.hpp
//

#include "EObject.hpp"
#include "company/people/PeoplePackage.hpp"
#include "company/people/Person.hpp"
#include <string>

// @generated
namespace company::people {

/// @brief The Employee class.
///
/// Part of the people package.
// @generated
class Employee final : public virtual Person {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Employee class.
    // @generated
    const ClassInfo &eClass() const override { return PeoplePackage::instance().employeeClass(); }

    /// @brief The name attribute.
    /// @return The current value of the name attribute.
    // @generated
    const std::string &getName() const override { return m_name; }

    /// @brief Changes the name attribute.
    /// @param value The new value.
    // @generated
    void setName(const std::string &value) override { m_name = value; }

    /// @brief The salary attribute.
    /// @return The current value of the salary attribute.
    // @generated
    double getSalary() const { return m_salary; }

    /// @brief Changes the salary attribute.
    /// @param value The new value.
    // @generated
    void setSalary(double value) { m_salary = value; }

private:
    /// @brief The storage of the name attribute.
    // @generated
    std::string m_name;

    /// @brief The storage of the salary attribute.
    // @generated
    double m_salary = 0.0;
};

}
