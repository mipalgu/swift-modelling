#pragma once

//
//  Organisation.hpp
//

#include "EObject.hpp"
#include "organisation/OrgPackage.hpp"
#include <memory>
#include <string>
#include <vector>

// @generated
namespace organisation { class Team; }

// @generated
namespace organisation {

/// @brief The Organisation class.
///
/// Part of the organisation package.
// @generated
class Organisation final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Organisation class.
    // @generated
    const ClassInfo &eClass() const override { return OrgPackage::instance().organisationClass(); }

    /// @brief The name attribute.
    /// @return The current value of the name attribute.
    // @generated
    const std::string &getName() const { return m_name; }

    /// @brief Changes the name attribute.
    /// @param value The new value.
    // @generated
    void setName(const std::string &value) { m_name = value; }

    /// @brief The teams reference.
    /// @return The values of the teams reference, which the caller can change.
    // @generated
    std::vector<std::shared_ptr<Team>> &getTeams() { return m_teams; }

    /// @brief The teams reference.
    /// @return The values of the teams reference.
    // @generated
    const std::vector<std::shared_ptr<Team>> &getTeams() const { return m_teams; }

private:
    /// @brief The storage of the name attribute.
    // @generated
    std::string m_name;

    /// @brief The storage of the teams reference.
    // @generated
    std::vector<std::shared_ptr<Team>> m_teams;
};

}
