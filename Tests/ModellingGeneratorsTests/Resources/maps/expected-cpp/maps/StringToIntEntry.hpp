#pragma once

//
//  StringToIntEntry.hpp
//

#include "EObject.hpp"
#include "maps/MapsPackage.hpp"
#include <cstdint>
#include <string>

// @generated
namespace maps {

/// @brief The StringToIntEntry class.
///
/// Part of the maps package.
// @generated
class StringToIntEntry final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the StringToIntEntry class.
    // @generated
    const ClassInfo &eClass() const override { return MapsPackage::instance().stringToIntEntryClass(); }

    /// @brief The key attribute.
    /// @return The current value of the key attribute.
    // @generated
    const std::string &getKey() const { return m_key; }

    /// @brief Changes the key attribute.
    /// @param value The new value.
    // @generated
    void setKey(const std::string &value) { m_key = value; }

    /// @brief The value attribute.
    /// @return The current value of the value attribute.
    // @generated
    std::int32_t getValue() const { return m_value; }

    /// @brief Changes the value attribute.
    /// @param value The new value.
    // @generated
    void setValue(std::int32_t value) { m_value = value; }

private:
    /// @brief The storage of the key attribute.
    // @generated
    std::string m_key;

    /// @brief The storage of the value attribute.
    // @generated
    std::int32_t m_value = 0;
};

}
