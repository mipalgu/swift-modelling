#pragma once

//
//  Class.hpp
//

#include "EObject.hpp"
#include "datatypes/DatatypesPackage.hpp"

// @generated
namespace datatypes {

/// @brief The Class class.
///
/// Part of the datatypes package.
// @generated
class Class final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Class class.
    // @generated
    const ClassInfo &eClass() const override { return DatatypesPackage::instance().classClass(); }
};

}
