#pragma once

//
//  DatatypesPackage.hpp
//

#include "EObject.hpp"
#include <string_view>

// @generated
namespace datatypes {

/// @brief The description of the datatypes package.
///
/// The shared instance holds the description of the package and of each of its classes, which the objects of the
/// package return as their class.
// @generated
class DatatypesPackage final {
public:
    /// @brief The shared description of the package.
    /// @return The only instance.
    // @generated
    static const DatatypesPackage &instance() {
        static const DatatypesPackage description;
        return description;
    }

    /// @brief The name of the package.
    /// @return The name in the model.
    // @generated
    std::string_view name() const { return m_info.name; }

    /// @brief The namespace URI of the package.
    /// @return The namespace URI in the model.
    // @generated
    std::string_view nsURI() const { return m_info.nsURI; }

    /// @brief The namespace prefix of the package.
    /// @return The namespace prefix in the model.
    // @generated
    std::string_view nsPrefix() const { return m_info.nsPrefix; }

    /// @brief The description of the package and its classes.
    /// @return The description, which lives as long as the program.
    // @generated
    const PackageInfo &info() const { return m_info; }

    /// @brief The description of the Thing class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &thingClass() const { return m_info.classes[0]; }

    /// @brief The description of the Class class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &classClass() const { return m_info.classes[1]; }

    /// @brief The description of the Gizmo class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &gizmoClass() const { return m_info.classes[2]; }

private:
    /// @brief Builds the description of the package.
    // @generated
    DatatypesPackage() {
        m_info.name = "datatypes";
        m_info.nsURI = "http://swift-modelling.org/test/datatypes";
        m_info.nsPrefix = "dt";
        m_info.classes = {
            ClassInfo{"Thing", false, {}, {
            }},
            ClassInfo{"Class", false, {}, {
            }},
            ClassInfo{"Gizmo", false, {}, {
            }},
        };
    }

    /// @brief The description of the package and its classes.
    // @generated
    PackageInfo m_info;
};

}
