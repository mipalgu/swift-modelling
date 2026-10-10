#pragma once

//
//  Person.hpp
//

#include "EObject.hpp"
#include "organisation/OrgPackage.hpp"
#include <cstdint>
#include <string>

// @generated
namespace organisation {

/// @brief The Person class.
///
/// Part of the organisation package.
// @generated
class Person final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Person class.
    // @generated
    const ClassInfo &eClass() const override { return OrgPackage::instance().personClass(); }

    /// @brief The name attribute.
    /// @return The current value of the name attribute.
    // @generated
    const std::string &getName() const { return m_name; }

    /// @brief Changes the name attribute.
    /// @param value The new value.
    // @generated
    void setName(const std::string &value) { m_name = value; }

    /// @brief The age attribute.
    /// @return The current value of the age attribute.
    // @generated
    std::int32_t getAge() const { return m_age; }

    /// @brief Changes the age attribute.
    /// @param value The new value.
    // @generated
    void setAge(std::int32_t value) { m_age = value; }

private:
    /// @brief The storage of the name attribute.
    // @generated
    std::string m_name;

    /// @brief The storage of the age attribute.
    // @generated
    std::int32_t m_age = 0;
};

}
