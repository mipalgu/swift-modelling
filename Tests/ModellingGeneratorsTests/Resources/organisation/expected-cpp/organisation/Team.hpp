#pragma once

//
//  Team.hpp
//

#include "EObject.hpp"
#include "organisation/OrgPackage.hpp"
#include <memory>
#include <string>
#include <vector>

// @generated
namespace organisation { class Person; }

// @generated
namespace organisation {

/// @brief The Team class.
///
/// Part of the organisation package.
// @generated
class Team final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Team class.
    // @generated
    const ClassInfo &eClass() const override { return OrgPackage::instance().teamClass(); }

    /// @brief The name attribute.
    /// @return The current value of the name attribute.
    // @generated
    const std::string &getName() const { return m_name; }

    /// @brief Changes the name attribute.
    /// @param value The new value.
    // @generated
    void setName(const std::string &value) { m_name = value; }

    /// @brief The members reference.
    /// @return The values of the members reference, which the caller can change.
    // @generated
    std::vector<std::shared_ptr<Person>> &getMembers() { return m_members; }

    /// @brief The members reference.
    /// @return The values of the members reference.
    // @generated
    const std::vector<std::shared_ptr<Person>> &getMembers() const { return m_members; }

    /// @brief The leader reference.
    /// @return The current value of the leader reference.
    // @generated
    std::shared_ptr<Person> getLeader() const { return m_leader.lock(); }

    /// @brief Changes the leader reference.
    /// @param value The new value.
    // @generated
    void setLeader(const std::shared_ptr<Person> &value) { m_leader = value; }

private:
    /// @brief The storage of the name attribute.
    // @generated
    std::string m_name;

    /// @brief The storage of the members reference.
    // @generated
    std::vector<std::shared_ptr<Person>> m_members;

    /// @brief The storage of the leader reference.
    // @generated
    std::weak_ptr<Person> m_leader;
};

}
