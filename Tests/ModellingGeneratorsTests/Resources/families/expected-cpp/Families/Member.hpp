#pragma once

//
//  Member.hpp
//

#include "EObject.hpp"
#include "Families/FamiliesPackage.hpp"
#include <memory>
#include <string>

// @generated
namespace Families { class Family; }

// @generated
namespace Families {

/// @brief The Member class.
///
/// Part of the Families package.
// @generated
class Member final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Member class.
    // @generated
    const ClassInfo &eClass() const override { return FamiliesPackage::instance().memberClass(); }

    /// @brief The firstName attribute.
    /// @return The current value of the firstName attribute.
    // @generated
    const std::string &getFirstName() const { return m_firstName; }

    /// @brief Changes the firstName attribute.
    /// @param value The new value.
    // @generated
    void setFirstName(const std::string &value) { m_firstName = value; }

    /// @brief The familyFather reference.
    /// @return The current value of the familyFather reference.
    // @generated
    std::shared_ptr<Family> getFamilyFather() const { return m_familyFather.lock(); }

    /// @brief Changes the familyFather reference.
    /// @param value The new value.
    // @generated
    void setFamilyFather(const std::shared_ptr<Family> &value) { m_familyFather = value; }

    /// @brief The familyMother reference.
    /// @return The current value of the familyMother reference.
    // @generated
    std::shared_ptr<Family> getFamilyMother() const { return m_familyMother.lock(); }

    /// @brief Changes the familyMother reference.
    /// @param value The new value.
    // @generated
    void setFamilyMother(const std::shared_ptr<Family> &value) { m_familyMother = value; }

    /// @brief The familySon reference.
    /// @return The current value of the familySon reference.
    // @generated
    std::shared_ptr<Family> getFamilySon() const { return m_familySon.lock(); }

    /// @brief Changes the familySon reference.
    /// @param value The new value.
    // @generated
    void setFamilySon(const std::shared_ptr<Family> &value) { m_familySon = value; }

    /// @brief The familyDaughter reference.
    /// @return The current value of the familyDaughter reference.
    // @generated
    std::shared_ptr<Family> getFamilyDaughter() const { return m_familyDaughter.lock(); }

    /// @brief Changes the familyDaughter reference.
    /// @param value The new value.
    // @generated
    void setFamilyDaughter(const std::shared_ptr<Family> &value) { m_familyDaughter = value; }

private:
    /// @brief The storage of the firstName attribute.
    // @generated
    std::string m_firstName;

    /// @brief The storage of the familyFather reference.
    // @generated
    std::weak_ptr<Family> m_familyFather;

    /// @brief The storage of the familyMother reference.
    // @generated
    std::weak_ptr<Family> m_familyMother;

    /// @brief The storage of the familySon reference.
    // @generated
    std::weak_ptr<Family> m_familySon;

    /// @brief The storage of the familyDaughter reference.
    // @generated
    std::weak_ptr<Family> m_familyDaughter;
};

}
