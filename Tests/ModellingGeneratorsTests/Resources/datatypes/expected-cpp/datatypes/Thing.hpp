#pragma once

//
//  Thing.hpp
//

#include "EObject.hpp"
#include "datatypes/DatatypesPackage.hpp"

// @generated
namespace datatypes {

/// @brief The Thing class.
///
/// Part of the datatypes package.
// @generated
class Thing final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Thing class.
    // @generated
    const ClassInfo &eClass() const override { return DatatypesPackage::instance().thingClass(); }
};

}
