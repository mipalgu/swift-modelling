#pragma once

//
//  Project.hpp
//

#include "EObject.hpp"
#include "company/projects/ProjPackage.hpp"
#include "company/projects/Status.hpp"
#include <memory>
#include <string>
#include <vector>

// @generated
namespace company::people { class Employee; }

// @generated
namespace company::projects {

/// @brief The Project class.
///
/// Part of the projects package.
// @generated
class Project final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Project class.
    // @generated
    const ClassInfo &eClass() const override { return ProjPackage::instance().projectClass(); }

    /// @brief The title attribute.
    /// @return The current value of the title attribute.
    // @generated
    const std::string &getTitle() const { return m_title; }

    /// @brief Changes the title attribute.
    /// @param value The new value.
    // @generated
    void setTitle(const std::string &value) { m_title = value; }

    /// @brief The status attribute.
    /// @return The current value of the status attribute.
    // @generated
    Status getStatus() const { return m_status; }

    /// @brief Changes the status attribute.
    /// @param value The new value.
    // @generated
    void setStatus(Status value) { m_status = value; }

    /// @brief The members reference.
    /// @return The values of the members reference, which the caller can change.
    // @generated
    std::vector<std::weak_ptr<::company::people::Employee>> &getMembers() { return m_members; }

    /// @brief The members reference.
    /// @return The values of the members reference.
    // @generated
    const std::vector<std::weak_ptr<::company::people::Employee>> &getMembers() const { return m_members; }

private:
    /// @brief The storage of the title attribute.
    // @generated
    std::string m_title;

    /// @brief The storage of the status attribute.
    // @generated
    Status m_status = Status::Proposed;

    /// @brief The storage of the members reference.
    // @generated
    std::vector<std::weak_ptr<::company::people::Employee>> m_members;
};

}
