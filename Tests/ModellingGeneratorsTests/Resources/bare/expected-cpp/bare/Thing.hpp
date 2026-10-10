#pragma once

//
//  Thing.hpp
//

#include "EObject.hpp"
#include "bare/BarePackage.hpp"

// @generated
namespace bare {

/// @brief The Thing class.
///
/// Part of the bare package.
// @generated
class Thing final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Thing class.
    // @generated
    const ClassInfo &eClass() const override { return BarePackage::instance().thingClass(); }
};

}
