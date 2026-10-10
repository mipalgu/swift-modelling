#pragma once

//
//  Gizmo.hpp
//

#include "EObject.hpp"
#include "datatypes/DatatypesPackage.hpp"

// @generated
namespace datatypes {

/// @brief Old.
/// @deprecated Use Thing
/// @since 2.0
// @generated
class Gizmo final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Gizmo class.
    // @generated
    const ClassInfo &eClass() const override { return DatatypesPackage::instance().gizmoClass(); }
};

}
