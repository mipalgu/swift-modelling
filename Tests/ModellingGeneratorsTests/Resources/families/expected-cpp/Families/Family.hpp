#pragma once

//
//  Family.hpp
//

#include "EObject.hpp"
#include "Families/FamiliesPackage.hpp"
#include <memory>
#include <string>
#include <vector>

// @generated
namespace Families { class Member; }

// @generated
namespace Families {

/// @brief The Family class.
///
/// Part of the Families package.
// @generated
class Family final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Family class.
    // @generated
    const ClassInfo &eClass() const override { return FamiliesPackage::instance().familyClass(); }

    /// @brief The lastName attribute.
    /// @return The current value of the lastName attribute.
    // @generated
    const std::string &getLastName() const { return m_lastName; }

    /// @brief Changes the lastName attribute.
    /// @param value The new value.
    // @generated
    void setLastName(const std::string &value) { m_lastName = value; }

    /// @brief The father reference.
    /// @return The current value of the father reference.
    // @generated
    std::shared_ptr<Member> getFather() const { return m_father; }

    /// @brief Changes the father reference.
    /// @param value The new value.
    // @generated
    void setFather(const std::shared_ptr<Member> &value) { m_father = value; }

    /// @brief The mother reference.
    /// @return The current value of the mother reference.
    // @generated
    std::shared_ptr<Member> getMother() const { return m_mother; }

    /// @brief Changes the mother reference.
    /// @param value The new value.
    // @generated
    void setMother(const std::shared_ptr<Member> &value) { m_mother = value; }

    /// @brief The sons reference.
    /// @return The values of the sons reference, which the caller can change.
    // @generated
    std::vector<std::shared_ptr<Member>> &getSons() { return m_sons; }

    /// @brief The sons reference.
    /// @return The values of the sons reference.
    // @generated
    const std::vector<std::shared_ptr<Member>> &getSons() const { return m_sons; }

    /// @brief The daughters reference.
    /// @return The values of the daughters reference, which the caller can change.
    // @generated
    std::vector<std::shared_ptr<Member>> &getDaughters() { return m_daughters; }

    /// @brief The daughters reference.
    /// @return The values of the daughters reference.
    // @generated
    const std::vector<std::shared_ptr<Member>> &getDaughters() const { return m_daughters; }

private:
    /// @brief The storage of the lastName attribute.
    // @generated
    std::string m_lastName;

    /// @brief The storage of the father reference.
    // @generated
    std::shared_ptr<Member> m_father;

    /// @brief The storage of the mother reference.
    // @generated
    std::shared_ptr<Member> m_mother;

    /// @brief The storage of the sons reference.
    // @generated
    std::vector<std::shared_ptr<Member>> m_sons;

    /// @brief The storage of the daughters reference.
    // @generated
    std::vector<std::shared_ptr<Member>> m_daughters;
};

}
