#pragma once

//
//  Company.hpp
//

#include "EObject.hpp"
#include "company/CompanyPackage.hpp"
#include <memory>
#include <string>
#include <vector>

// @generated
namespace company::people { class Employee; }

// @generated
namespace company::projects { class Project; }

// @generated
namespace company {

/// @brief The Company class.
///
/// Part of the company package.
// @generated
class Company final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Company class.
    // @generated
    const ClassInfo &eClass() const override { return CompanyPackage::instance().companyClass(); }

    /// @brief The name attribute.
    /// @return The current value of the name attribute.
    // @generated
    const std::string &getName() const { return m_name; }

    /// @brief Changes the name attribute.
    /// @param value The new value.
    // @generated
    void setName(const std::string &value) { m_name = value; }

    /// @brief The staff reference.
    /// @return The values of the staff reference, which the caller can change.
    // @generated
    std::vector<std::shared_ptr<::company::people::Employee>> &getStaff() { return m_staff; }

    /// @brief The staff reference.
    /// @return The values of the staff reference.
    // @generated
    const std::vector<std::shared_ptr<::company::people::Employee>> &getStaff() const { return m_staff; }

    /// @brief The projects reference.
    /// @return The values of the projects reference, which the caller can change.
    // @generated
    std::vector<std::shared_ptr<::company::projects::Project>> &getProjects() { return m_projects; }

    /// @brief The projects reference.
    /// @return The values of the projects reference.
    // @generated
    const std::vector<std::shared_ptr<::company::projects::Project>> &getProjects() const { return m_projects; }

private:
    /// @brief The storage of the name attribute.
    // @generated
    std::string m_name;

    /// @brief The storage of the staff reference.
    // @generated
    std::vector<std::shared_ptr<::company::people::Employee>> m_staff;

    /// @brief The storage of the projects reference.
    // @generated
    std::vector<std::shared_ptr<::company::projects::Project>> m_projects;
};

}
