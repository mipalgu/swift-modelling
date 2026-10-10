#pragma once

//
//  Light.hpp
//

#include "EObject.hpp"
#include "enumerations/Colour.hpp"
#include "enumerations/EnumerationsPackage.hpp"
#include "enumerations/Mode.hpp"

// @generated
namespace enumerations {

/// @brief The Light class.
///
/// Part of the enumerations package.
// @generated
class Light final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Light class.
    // @generated
    const ClassInfo &eClass() const override { return EnumerationsPackage::instance().lightClass(); }

    /// @brief The colour attribute.
    /// @return The current value of the colour attribute.
    // @generated
    Colour getColour() const { return m_colour; }

    /// @brief Changes the colour attribute.
    /// @param value The new value.
    // @generated
    void setColour(Colour value) { m_colour = value; }

    /// @brief The mode attribute.
    /// @return The current value of the mode attribute.
    // @generated
    Mode getMode() const { return m_mode; }

    /// @brief Changes the mode attribute.
    /// @param value The new value.
    // @generated
    void setMode(Mode value) { m_mode = value; }

private:
    /// @brief The storage of the colour attribute.
    // @generated
    Colour m_colour = Colour::Red;

    /// @brief The storage of the mode attribute.
    // @generated
    Mode m_mode = Mode::default_;
};

}
